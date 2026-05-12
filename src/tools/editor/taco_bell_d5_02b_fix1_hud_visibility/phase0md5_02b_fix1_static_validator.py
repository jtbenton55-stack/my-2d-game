#!/usr/bin/env python3
"""0M-D5-02B-FIX1 — Static validator for HUD visibility reports + guardrails."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def _repo_root() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found above validator")


REPO = _repo_root()
REPORTS = REPO / "docs" / "reports" / "taco_bell_d5_02b_fix1_hud_visibility"
FINAL_JSON = REPORTS / "phase0md5_02b_fix1_hud_visibility_final_report.json"
RUN_OUT = REPORTS / "phase0md5_02b_fix1_static_validator_run.json"

REQUIRED = [
    "phase0md5_02b_fix1_safety_baseline.md",
    "phase0md5_02b_fix1_safety_baseline.json",
    "phase0md5_02b_fix1_static_hud_wiring_audit.md",
    "phase0md5_02b_fix1_static_hud_wiring_audit.json",
    "phase0md5_02b_fix1_runtime_hud_truth.md",
    "phase0md5_02b_fix1_runtime_hud_truth.json",
    "phase0md5_02b_fix1_root_cause_decision.md",
    "phase0md5_02b_fix1_root_cause_decision.json",
    "phase0md5_02b_fix1_hud_fix.md",
    "phase0md5_02b_fix1_hud_fix.json",
    "phase0md5_02b_fix1_non_regression.md",
    "phase0md5_02b_fix1_non_regression.json",
    "phase0md5_02b_fix1_runtime_validation.md",
    "phase0md5_02b_fix1_runtime_validation.json",
    "phase0md5_02b_fix1_validation.md",
    "phase0md5_02b_fix1_validation.json",
    "phase0md5_02b_fix1_hud_visibility_final_report.md",
    "phase0md5_02b_fix1_hud_visibility_final_report.json",
]

FORBIDDEN_MODIFIED_SUBSTRINGS = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)

FINAL_REQUIRED_KEYS = (
    "root_cause_classification",
    "hud_visible_before_fix",
    "hud_visible_after_fix",
    "canvas_layer_findings",
    "fix_implemented",
    "healthbar_overlap_status",
    "f10_debug_role_preserved",
    "runtime_validation_result",
    "static_validator_result",
    "files_modified_this_pass",
)


def main() -> int:
    failures: list[str] = []

    for name in REQUIRED:
        p = REPORTS / name
        if not p.is_file():
            failures.append(f"missing {p.relative_to(REPO)}")
        elif name.endswith(".json"):
            try:
                json.loads(p.read_text(encoding="utf-8"))
            except json.JSONDecodeError as e:
                failures.append(f"bad JSON {name}: {e}")

    core = [
        REPO / "src" / "ui" / "HUD.gd",
        REPO / "scenes" / "ui" / "hud.tscn",
        REPO / "src" / "missions" / "ui" / "MissionHudDataProvider.gd",
    ]
    for p in core:
        if not p.is_file():
            failures.append(f"missing core file {p.relative_to(REPO)}")

    hud_gd = (REPO / "src" / "ui" / "HUD.gd").read_text(encoding="utf-8", errors="replace")
    if "var payload := MissionHudDataProvider.get_hud_payload" not in hud_gd:
        failures.append("HUD.gd missing payload-first refresh pattern")
    if "_player_facing_objective_line" not in hud_gd:
        failures.append("HUD.gd missing _player_facing_objective_line")
    i_def = hud_gd.find("func _refresh_mission_compact_hud")
    i_payload = hud_gd.find("var payload := MissionHudDataProvider.get_hud_payload", i_def)
    i_strip_null = hud_gd.find("if _mission_strip == null:", i_def)
    if i_payload == -1:
        failures.append("HUD.gd missing payload assignment in _refresh_mission_compact_hud")
    elif i_strip_null != -1 and i_strip_null < i_payload:
        failures.append("HUD.gd must compute payload before any strip-null early return")

    tscn = (REPO / "scenes" / "ui" / "hud.tscn").read_text(encoding="utf-8", errors="replace")
    if "layer = 50" not in tscn:
        failures.append("hud.tscn expected layer = 50 for player-facing band policy")
    if "MissionHudStrip" not in tscn:
        failures.append("hud.tscn missing MissionHudStrip")

    prov = (REPO / "src" / "missions" / "ui" / "MissionHudDataProvider.gd").read_text(
        encoding="utf-8", errors="replace"
    )
    if "_looks_like_internal_objective" not in prov:
        failures.append("MissionHudDataProvider.gd missing internal objective guard")

    sprint = (REPO / "src" / "player" / "PlayerSprintDebugOverlay.gd").read_text(
        encoding="utf-8", errors="replace"
    )
    if "layer = 110" not in sprint:
        failures.append("PlayerSprintDebugOverlay.gd expected layer = 110 (F11 below pause)")

    dup_candidates = [
        REPO / "scenes" / "ui" / "hud2.tscn",
        REPO / "src" / "ui" / "HUD2.gd",
    ]
    for p in dup_candidates:
        if p.is_file():
            failures.append(f"unexpected duplicate HUD file {p.relative_to(REPO)}")

    if not FINAL_JSON.is_file():
        failures.append("missing final report json")
    else:
        data = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        for k in FINAL_REQUIRED_KEYS:
            if k not in data:
                failures.append(f"final report json missing key {k!r}")
        modified = data.get("files_modified_this_pass", [])
        if not isinstance(modified, list):
            failures.append("files_modified_this_pass must be a list")
        else:
            for path in modified:
                sp = str(path).replace("\\", "/")
                for bad in FORBIDDEN_MODIFIED_SUBSTRINGS:
                    if bad in sp:
                        failures.append(f"forbidden path in files_modified_this_pass: {sp} ({bad})")

    ok = len(failures) == 0
    RUN_OUT.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
                "assertions": {
                    "static_validator_created": True,
                    "static_validator_run": True,
                    "static_validator_passed": ok,
                },
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    # Keep final report machine field in sync for doc readers
    if FINAL_JSON.is_file():
        fr = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        fr["static_validator_result"] = "PASS" if ok else "FAIL"
        FINAL_JSON.write_text(json.dumps(fr, indent=2) + "\n", encoding="utf-8")

    val_json = REPORTS / "phase0md5_02b_fix1_validation.json"
    if val_json.is_file():
        v = json.loads(val_json.read_text(encoding="utf-8"))
        ass = v.setdefault("assertions", {})
        ass["static_validator_run"] = True
        ass["static_validator_passed"] = ok
        val_json.write_text(json.dumps(v, indent=2) + "\n", encoding="utf-8")

    print(json.dumps({"ok": ok, "out": str(RUN_OUT), "fail_count": len(failures)}, indent=2))
    if failures:
        for f in failures:
            print(f, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
