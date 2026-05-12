#!/usr/bin/env python3
"""PHASE 0M-D5-02B — Static validator for compact HUD + reports."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def _find_repo_root() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found above validator")


REPO_ROOT = _find_repo_root()
REPORTS = REPO_ROOT / "docs" / "reports" / "taco_bell_d5_02b_compact_hud"
FINAL_JSON = REPORTS / "phase0md5_02b_compact_hud_final_report.json"
HUD_GD = REPO_ROOT / "src" / "ui" / "HUD.gd"
HUD_TSCN = REPO_ROOT / "scenes" / "ui" / "hud.tscn"
PROVIDER = REPO_ROOT / "src" / "missions" / "ui" / "MissionHudDataProvider.gd"

REQUIRED_JSON = [
    "phase0md5_02b_safety_baseline.json",
    "phase0md5_02b_hud_data_audit.json",
    "phase0md5_02b_hud_design_decision.json",
    "phase0md5_02b_hud_data_provider.json",
    "phase0md5_02b_hud_implementation.json",
    "phase0md5_02b_debug_non_regression.json",
    "phase0md5_02b_runtime_validation.json",
    "phase0md5_02b_validation.json",
    "phase0md5_02b_compact_hud_final_report.json",
]

FORBIDDEN_DIFF = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "src/levels/IsoMissionBase.gd",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)

TACO_WARN = (
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
)


def _git(*args: str) -> str:
    r = subprocess.run(
        ["git", "-C", str(REPO_ROOT), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return (r.stdout or "").strip()


def main() -> int:
    failures: list[str] = []
    taco_warn: list[str] = []

    for name in REQUIRED_JSON:
        p = REPORTS / name
        if not p.is_file():
            failures.append(f"missing {p.relative_to(REPO_ROOT)}")
            continue
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            failures.append(f"bad JSON {name}: {e}")
            continue
        for k, v in data.get("assertions", {}).items():
            if v is not True:
                failures.append(f"{name} assertion {k!r} != true ({v!r})")

    if not HUD_GD.is_file():
        failures.append("missing HUD.gd")
    if not HUD_TSCN.is_file():
        failures.append("missing hud.tscn")
    if not PROVIDER.is_file():
        failures.append("missing MissionHudDataProvider.gd")

    hud_src = HUD_GD.read_text(encoding="utf-8", errors="replace")
    for needle in (
        "MissionHudDataProvider",
        "_refresh_mission_compact_hud",
        "SprintStaminaBar",
        "PoopBagLabel",
        "sanitize_objective_line",
    ):
        if needle not in hud_src:
            failures.append(f"HUD.gd missing {needle!r}")

    tscn = HUD_TSCN.read_text(encoding="utf-8", errors="replace")
    for needle in ("MissionHudStrip", "SprintStaminaBar", "PoopBagLabel", "ObjectiveLabel"):
        if needle not in tscn:
            failures.append(f"hud.tscn missing {needle!r}")

    diff_lines = [ln.replace("\\", "/") for ln in _git("diff", "--name-only").splitlines() if ln.strip()]
    for ln in diff_lines:
        for pref in FORBIDDEN_DIFF:
            if ln == pref or ln.startswith(pref):
                failures.append(f"forbidden diff path: {ln}")
        for pref in TACO_WARN:
            if ln == pref or ln.startswith(pref):
                taco_warn.append(f"taco scene in working tree diff (D5-02B did not require edit): {ln}")

    if FINAL_JSON.is_file():
        fj = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        for key in (
            "hud_placement_summary",
            "healthbar_overlap_status",
            "f10_debug_non_regression_status",
            "runtime_validation_result",
            "remaining_limitations",
        ):
            if key not in fj:
                failures.append(f"final json missing {key}")
    else:
        failures.append("missing final report json")

    out = REPORTS / "phase0md5_02b_static_validator_run.json"
    ok = len(failures) == 0
    out.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
                "taco_scene_diff_warnings": taco_warn,
                "diff_files_checked": diff_lines,
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
    print(json.dumps({"ok": ok, "out": str(out), "fail_count": len(failures)}, indent=2))
    if failures:
        for f in failures:
            print(f, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
