#!/usr/bin/env python3
"""PHASE 0M-D5-02A — Static validator for UI/debug hygiene reports and forbidden diffs."""
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
REPORTS = REPO_ROOT / "docs" / "reports" / "taco_bell_d5_02a_ui_debug_hygiene"
FINAL_MD = REPORTS / "phase0md5_02a_ui_debug_hygiene_final_report.md"
FINAL_JSON = REPORTS / "phase0md5_02a_ui_debug_hygiene_final_report.json"

REQUIRED_JSON = [
    "phase0md5_02a_safety_baseline.json",
    "phase0md5_02a_ui_debug_inventory.json",
    "phase0md5_02a_taco_runtime_clutter_audit.json",
    "phase0md5_02a_ui_ownership_consolidation_plan.json",
    "phase0md5_02a_hygiene_changes.json",
    "phase0md5_02a_scrollable_text_validation.json",
    "phase0md5_02a_d5_02b_hud_readiness_plan.json",
    "phase0md5_02a_runtime_validation.json",
    "phase0md5_02a_validation.json",
    "phase0md5_02a_ui_debug_hygiene_final_report.json",
]

FORBIDDEN_DIFF_PREFIXES = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "src/levels/IsoMissionBase.gd",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/missions/TacoBellMission.tscn",
    "scenes/hideout/HideoutHub.tscn",
    "scenes/characters/player.tscn",
    "assets/",
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
        for pref in FORBIDDEN_DIFF_PREFIXES:
            if ln == pref or ln.startswith(pref):
                failures.append(f"forbidden diff path: {ln}")

    if FINAL_JSON.is_file():
        fj = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        for key in (
            "remaining_clutter_risks",
            "remaining_text_overflow_risks",
            "cleaned_hidden_standardized_deferred",
        ):
            if key not in fj:
                failures.append(f"final json missing {key}")
        if fj.get("final_gameplay_hud_added_unjustified"):
            failures.append("final_gameplay_hud_added_unjustified must be false or absent")
    else:
        failures.append("missing final report json")

    out = REPORTS / "phase0md5_02a_static_validator_run.json"
    ok = len(failures) == 0
    out.write_text(
        json.dumps(
            {
                "ok": ok,
                "fail_count": len(failures),
                "failures": failures,
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
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
