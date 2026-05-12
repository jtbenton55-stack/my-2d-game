#!/usr/bin/env python3
"""
PHASE 0M-D5-00 — Static consistency validator for runtime-truth reports.
Run from repo root: python src/tools/editor/taco_bell_d5_00_runtime_truth/phase0md5_00_static_validator.py
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def _find_repo_root() -> Path:
    p = Path(__file__).resolve()
    for anc in [p.parent, *p.parents]:
        if (anc / "project.godot").is_file():
            return anc
    raise RuntimeError("Could not locate project.godot above validator script")


REPO_ROOT = _find_repo_root()
REPORTS = REPO_ROOT / "docs" / "reports" / "taco_bell_d5_00_runtime_truth"
FINAL_MD = REPORTS / "phase0md5_00_runtime_truth_final_report.md"
FINAL_JSON = REPORTS / "phase0md5_00_runtime_truth_final_report.json"
RESOLVER = REPO_ROOT / "src" / "missions" / "MissionSceneResolver.gd"
REDESIGN = REPO_ROOT / "scenes" / "missions_iso" / "TacoBellIso_Editable_RedesignTest.tscn"

REQUIRED_JSON = [
    "phase0md5_00_safety_baseline.json",
    "phase0md5_00_launch_verification.json",
    "phase0md5_00_player_control_verification.json",
    "phase0md5_00_pause_payload_verification.json",
    "phase0md5_00_beam_alarm_truth.json",
    "phase0md5_00_counter_attempt_reset_truth.json",
    "phase0md5_00_louis_bypass_truth.json",
    "phase0md5_00_poop_tool_truth.json",
    "phase0md5_00_completion_return_truth.json",
    "phase0md5_00_player_facing_quality_assessment.json",
    "phase0md5_00_validation.json",
    "phase0md5_00_runtime_truth_final_report.json",
]

PROTECTED = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/missions_iso/TacoBellIso_Editable.tscn",
    "scenes/hideout/HideoutHub.tscn",
]


def _run_git(args: list[str]) -> str:
    r = subprocess.run(
        ["git", "-C", str(REPO_ROOT), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return (r.stdout or "") + (r.stderr or "")


def main() -> int:
    failures: list[str] = []

    for name in REQUIRED_JSON:
        p = REPORTS / name
        if not p.is_file():
            failures.append(f"missing report: {p.relative_to(REPO_ROOT)}")
            continue
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            failures.append(f"invalid JSON {name}: {e}")
            continue
        for k, v in data.get("assertions", {}).items():
            if v is not True:
                failures.append(f"{name} assertion {k!r} is not true ({v!r})")

    if not REDESIGN.is_file():
        failures.append("RedesignTest scene missing")
    if not RESOLVER.is_file():
        failures.append("MissionSceneResolver.gd missing")
    else:
        txt = RESOLVER.read_text(encoding="utf-8", errors="replace")
        if "taco_bell_drop" not in txt or "TacoBellIso_Editable_RedesignTest.tscn" not in txt:
            failures.append("MissionSceneResolver does not route taco_bell_drop to RedesignTest")

    status = _run_git(["status", "--porcelain"]).strip().splitlines()
    diff_names = _run_git(["diff", "--name-only"]).strip().splitlines()
    for line in status + diff_names:
        norm = line[3:].strip() if len(line) > 3 and line[1:3] == " " else line.strip()
        for pref in PROTECTED:
            if norm.replace("\\", "/") == pref or norm.replace("\\", "/").endswith("/" + pref):
                failures.append(f"protected file touched in git: {norm}")
        if norm.startswith("assets/"):
            failures.append(f"assets touched: {norm}")

    if FINAL_MD.is_file():
        md = FINAL_MD.read_text(encoding="utf-8", errors="replace")
        for phrase in (
            "d5_01",
            "evidence",
            "runtime limitation",
            "VERIFIED_RUNTIME",
        ):
            if phrase.lower() not in md.lower():
                failures.append(f"final report md missing expected phrase (case-insensitive): {phrase}")
        if not re.search(r"PARTIAL|PASS|FAIL", md):
            failures.append("final report md missing PASS/FAIL/PARTIAL verdict")
    else:
        failures.append("missing final report md")

    if FINAL_JSON.is_file():
        fj = json.loads(FINAL_JSON.read_text(encoding="utf-8"))
        if "d5_01_recommendation" not in fj:
            failures.append("final json missing d5_01_recommendation")
        if "evidence_level_summary" not in fj:
            failures.append("final json missing evidence_level_summary")
        if "runtime_limitations" not in fj:
            failures.append("final json missing runtime_limitations")
    else:
        failures.append("missing final report json")

    out_path = REPORTS / "phase0md5_00_static_validator_run.json"
    payload = {
        "ok": len(failures) == 0,
        "fail_count": len(failures),
        "failures": failures,
        "assertions": {
            "static_validator_created": True,
            "static_validator_run": True,
            "static_validator_passed": len(failures) == 0,
        },
    }
    out_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": payload["ok"], "out": str(out_path), "fail_count": len(failures)}, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
