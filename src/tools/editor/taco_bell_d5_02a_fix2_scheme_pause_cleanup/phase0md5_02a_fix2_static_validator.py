#!/usr/bin/env python3
"""PHASE 0M-D5-02A-FIX2 — Static validator for scheme pause cleanup."""
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
REPORTS = REPO_ROOT / "docs" / "reports" / "taco_bell_d5_02a_fix2_scheme_pause_cleanup"
FINAL_JSON = REPORTS / "phase0md5_02a_fix2_final_report.json"
PAUSE_MENU = REPO_ROOT / "src" / "ui" / "test_ui" / "pause_menu.gd"
FORMATTER = REPO_ROOT / "src" / "missions" / "schemes" / "MissionSchemeCardFormatter.gd"
ISO_DEBUG = REPO_ROOT / "src" / "missions" / "iso" / "runtime" / "IsoMissionDebugPanel.gd"
FIX1_FINAL = REPORTS.parent / "taco_bell_d5_02a_fix1_pause_scheme_debug" / "phase0md5_02a_fix1_final_report.md"

REQUIRED_JSON = [
    "phase0md5_02a_fix2_safety_baseline.json",
    "phase0md5_02a_fix2_scheme_display_audit.json",
    "phase0md5_02a_fix2_player_facing_scheme_format.json",
    "phase0md5_02a_fix2_pause_scheme_cleanup.json",
    "phase0md5_02a_fix2_f10_scheme_debug.json",
    "phase0md5_02a_fix2_microcopy_cleanup.json",
    "phase0md5_02a_fix2_runtime_validation.json",
    "phase0md5_02a_fix2_validation.json",
    "phase0md5_02a_fix2_final_report.json",
]

FORBIDDEN_DIFF = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)

TACO_SCENE_WARN = (
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
)

BANNED_IN_PAUSE_MENU = (
    "GameState.current_scheme_loadout",
    "legacy selected_cards",
    "CardEffects reads this path",
    "has_scheme_card()",
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

    if not FIX1_FINAL.is_file():
        failures.append("missing prerequisite FIX1 final report: " + str(FIX1_FINAL.relative_to(REPO_ROOT)))

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

    if not FORMATTER.is_file():
        failures.append("missing MissionSchemeCardFormatter.gd")

    pause_src = PAUSE_MENU.read_text(encoding="utf-8", errors="replace")
    for banned in BANNED_IN_PAUSE_MENU:
        if banned in pause_src:
            failures.append(f"pause_menu.gd contains banned substring: {banned!r}")

    if "MissionSchemeCardFormatter" not in pause_src:
        failures.append("pause_menu.gd does not reference MissionSchemeCardFormatter")

    iso_src = ISO_DEBUG.read_text(encoding="utf-8", errors="replace")
    if "format_scheme_snapshot_debug_block" not in iso_src:
        failures.append("IsoMissionDebugPanel.gd missing format_scheme_snapshot_debug_block call")

    diff_lines = [ln.replace("\\", "/") for ln in _git("diff", "--name-only").splitlines() if ln.strip()]
    for ln in diff_lines:
        for pref in FORBIDDEN_DIFF:
            if ln == pref or ln.startswith(pref):
                failures.append(f"forbidden diff path: {ln}")
        for pref in TACO_SCENE_WARN:
            if ln == pref or ln.startswith(pref):
                taco_warn.append(f"taco scene in working tree diff (verify not introduced by FIX2): {ln}")

    if FINAL_JSON.is_file():
        fj = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        for key in ("player_facing_scheme_status", "scheme_effect_honesty_status", "d5_02b_readiness"):
            if key not in fj:
                failures.append(f"final json missing {key}")
    else:
        failures.append("missing final report json")

    out = REPORTS / "phase0md5_02a_fix2_static_validator_run.json"
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
