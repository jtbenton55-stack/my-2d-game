#!/usr/bin/env python3
"""0M-D6-01 — Static validator: adapter + wiring + reports; forbidden files unchanged."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def _repo() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("project.godot not found")


REPO = _repo()
REPORTS = REPO / "docs" / "reports" / "d6_01_taco_security_heat_mvp"
FINAL = REPORTS / "phase0md6_01_final_report.json"
RUN = REPORTS / "phase0md6_01_static_validator_run.json"
VALIDATION = REPORTS / "phase0md6_01_validation.json"
VALIDATION_MD = REPORTS / "phase0md6_01_validation.md"
ADAPTER = REPO / "src" / "missions" / "iso" / "runtime" / "MissionSecurityEventAdapter.gd"
PROJECT = REPO / "project.godot"
PAUSE_PROVIDER = REPO / "src" / "missions" / "ui" / "MissionPauseDataProvider.gd"
DEBUG_PANEL = REPO / "src" / "missions" / "iso" / "runtime" / "IsoMissionDebugPanel.gd"

REQUIRED = [
    "phase0md6_01_safety_baseline.md",
    "phase0md6_01_safety_baseline.json",
    "phase0md6_01_security_heat_wiring_audit.md",
    "phase0md6_01_security_heat_wiring_audit.json",
    "phase0md6_01_kimi_review.md",
    "phase0md6_01_kimi_review.json",
    "phase0md6_01_adapter_implementation.md",
    "phase0md6_01_adapter_implementation.json",
    "phase0md6_01_security_source_wiring.md",
    "phase0md6_01_security_source_wiring.json",
    "phase0md6_01_heat_policy.md",
    "phase0md6_01_heat_policy.json",
    "phase0md6_01_f10_debug_visibility.md",
    "phase0md6_01_f10_debug_visibility.json",
    "phase0md6_01_pause_heat_summary.md",
    "phase0md6_01_pause_heat_summary.json",
    "phase0md6_01_static_self_review.md",
    "phase0md6_01_static_self_review.json",
    "phase0md6_01_runtime_validation.md",
    "phase0md6_01_runtime_validation.json",
    "phase0md6_01_final_report.md",
    "phase0md6_01_final_report.json",
]

FORBIDDEN_GIT_PATH_SUBSTR = (
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "project.godot",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)


def _git_changed_files() -> list[str]:
    try:
        cp = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=REPO,
            capture_output=True,
            text=True,
            check=False,
        )
        if cp.returncode != 0:
            return []
        return [ln.strip().replace("\\", "/") for ln in cp.stdout.splitlines() if ln.strip()]
    except OSError:
        return []


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
                failures.append(f"bad json {name}: {e}")

    if not ADAPTER.is_file():
        failures.append("MissionSecurityEventAdapter.gd missing")
    else:
        at = ADAPTER.read_text(encoding="utf-8")
        if "class_name MissionSecurityEventAdapter" not in at:
            failures.append("adapter missing class_name")
        if "func report_security_event" not in at:
            failures.append("adapter missing report_security_event")
        if "func get_security_debug_snapshot" not in at:
            failures.append("adapter missing get_security_debug_snapshot")
        if "dedupe_key" not in at and "_coalesce_keys" not in at:
            failures.append("adapter missing coalesce/dedupe logic")

    if PROJECT.is_file():
        pg = PROJECT.read_text(encoding="utf-8")
        if re.search(r"MissionSecurityEventAdapter", pg):
            failures.append("MissionSecurityEventAdapter must not appear in project.godot")

    if not DEBUG_PANEL.is_file():
        failures.append("IsoMissionDebugPanel.gd missing")
    elif "Security (D6-01)" not in DEBUG_PANEL.read_text(encoding="utf-8"):
        failures.append("F10 panel missing D6-01 security block marker")

    if not PAUSE_PROVIDER.is_file() or "get_heat_security_pause_line" not in PAUSE_PROVIDER.read_text(
        encoding="utf-8"
    ):
        failures.append("MissionPauseDataProvider missing get_heat_security_pause_line")

    if not FINAL.is_file():
        failures.append("missing final report json")
    else:
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in (
            "verdict",
            "current_branch",
            "heat_policy_summary",
            "mid_run_heat_increase",
            "mission_failure_heat_source",
            "f10_security_block",
            "pause_heat_line",
            "kimi_status",
            "runtime_validation_status",
            "static_self_review_status",
            "manual_test_checklist_included",
        ):
            if k not in fr:
                failures.append(f"final report missing key: {k}")

    changed = _git_changed_files()
    bad_git: list[str] = []
    for p in changed:
        for sub in FORBIDDEN_GIT_PATH_SUBSTR:
            if sub in p.replace("\\", "/"):
                bad_git.append(p)
                break
    if bad_git:
        failures.append(f"forbidden paths in git diff: {bad_git}")

    ok = not failures
    VALIDATION.write_text(
        json.dumps({"static_validator_passed": ok, "failures": failures}, indent=2) + "\n",
        encoding="utf-8",
    )
    VALIDATION_MD.write_text(
        "# 0M-D6-01 validation\n\n**PASS**" if ok else "# 0M-D6-01 validation\n\n**FAIL**\n\n" + "\n".join(failures),
        encoding="utf-8",
    )
    RUN.write_text(
        json.dumps(
            {
                "pass_id": "0M-D6-01",
                "static_validator_passed": ok,
                "failures": failures,
                "git_changed_sample": changed[:40],
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
