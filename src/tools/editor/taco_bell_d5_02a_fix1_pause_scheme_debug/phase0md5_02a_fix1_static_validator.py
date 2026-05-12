#!/usr/bin/env python3
"""PHASE 0M-D5-02A-FIX1 — Static validator for pause/scheme/debug reports and forbidden diffs."""
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
REPORTS = REPO_ROOT / "docs" / "reports" / "taco_bell_d5_02a_fix1_pause_scheme_debug"
FINAL_MD = REPORTS / "phase0md5_02a_fix1_final_report.md"
FINAL_JSON = REPORTS / "phase0md5_02a_fix1_final_report.json"

REQUIRED_JSON = [
    "phase0md5_02a_fix1_safety_baseline.json",
    "phase0md5_02a_fix1_pause_data_audit.json",
    "phase0md5_02a_fix1_scheme_card_truth_audit.json",
    "phase0md5_02a_fix1_debug_counter_audit.json",
    "phase0md5_02a_fix1_pause_data_fix.json",
    "phase0md5_02a_fix1_scheme_card_fix.json",
    "phase0md5_02a_fix1_f10_debug_consolidation.json",
    "phase0md5_02a_fix1_runtime_validation.json",
    "phase0md5_02a_fix1_validation.json",
    "phase0md5_02a_fix1_final_report.json",
]

HARD_FORBIDDEN = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "src/levels/IsoMissionBase.gd",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)

# Taco scenes: local dirty tree common; this pass did not edit them. Warn only.
TACO_WARN_PREFIXES = (
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
    soft: list[str] = []

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

    if not FINAL_MD.is_file():
        failures.append("missing final report md")

    diff_lines = [ln.replace("\\", "/") for ln in _git("diff", "--name-only").splitlines() if ln.strip()]
    for ln in diff_lines:
        for pref in HARD_FORBIDDEN:
            if ln == pref or ln.startswith(pref):
                failures.append(f"forbidden diff path: {ln}")
        for pref in TACO_WARN_PREFIXES:
            if ln == pref or ln.startswith(pref):
                soft.append(f"taco scene in working tree diff (verify not introduced by fix1): {ln}")

    if FINAL_JSON.is_file():
        fj = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        for key in (
            "gamestate_warning_status",
            "scheme_card_visibility_status",
            "scheme_card_effect_status",
            "always_visible_counter_panel_status",
            "remaining_clutter_risks",
            "remaining_text_overflow_risks",
            "d5_02b_readiness_recommendation",
        ):
            if key not in fj:
                failures.append(f"final json missing {key}")
    else:
        failures.append("missing final report json")

    out = REPORTS / "phase0md5_02a_fix1_static_validator_run.json"
    ok = len(failures) == 0
    out.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
                "taco_scene_diff_warnings": soft,
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
