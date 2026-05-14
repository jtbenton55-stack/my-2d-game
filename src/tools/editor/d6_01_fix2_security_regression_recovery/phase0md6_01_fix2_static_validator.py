#!/usr/bin/env python3
"""0M-D6-01-FIX2 — Static validator for security regression recovery."""
from __future__ import annotations

import json
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
REPORTS = REPO / "docs" / "reports" / "d6_01_fix2_security_regression_recovery"
FINAL = REPORTS / "phase0md6_01_fix2_final_report.json"
RUN = REPORTS / "phase0md6_01_fix2_static_validator_run.json"
VALIDATION = REPORTS / "phase0md6_01_fix2_validation.json"
VALIDATION_MD = REPORTS / "phase0md6_01_fix2_validation.md"

REQUIRED = [
    "phase0md6_01_fix2_safety_baseline.md",
    "phase0md6_01_fix2_safety_baseline.json",
    "phase0md6_01_fix2_regression_root_cause_audit.md",
    "phase0md6_01_fix2_regression_root_cause_audit.json",
    "phase0md6_01_fix2_camera_runtime_path_audit.md",
    "phase0md6_01_fix2_camera_runtime_path_audit.json",
    "phase0md6_01_fix2_wrong_code_audit.md",
    "phase0md6_01_fix2_wrong_code_audit.json",
    "phase0md6_01_fix2_guard_decision_audit.md",
    "phase0md6_01_fix2_guard_decision_audit.json",
    "phase0md6_01_fix2_beam_f10_audit.md",
    "phase0md6_01_fix2_beam_f10_audit.json",
    "phase0md6_01_fix2_kimi_review.md",
    "phase0md6_01_fix2_kimi_review.json",
    "phase0md6_01_fix2_camera_repair.md",
    "phase0md6_01_fix2_camera_repair.json",
    "phase0md6_01_fix2_wrong_code_repair.md",
    "phase0md6_01_fix2_wrong_code_repair.json",
    "phase0md6_01_fix2_guard_policy_fix.md",
    "phase0md6_01_fix2_guard_policy_fix.json",
    "phase0md6_01_fix2_beam_f10_fix.md",
    "phase0md6_01_fix2_beam_f10_fix.json",
    "phase0md6_01_fix2_heat_non_regression.md",
    "phase0md6_01_fix2_heat_non_regression.json",
    "phase0md6_01_fix2_ui_non_regression.md",
    "phase0md6_01_fix2_ui_non_regression.json",
    "phase0md6_01_fix2_static_self_review.md",
    "phase0md6_01_fix2_static_self_review.json",
    "phase0md6_01_fix2_runtime_validation.md",
    "phase0md6_01_fix2_runtime_validation.json",
    "phase0md6_01_fix2_final_report.md",
    "phase0md6_01_fix2_final_report.json",
]

FORBIDDEN = (
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "project.godot",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "scenes/characters/player.tscn",
    "assets/",
)


def _git_changed() -> list[str]:
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

    if FINAL.is_file():
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in (
            "verdict",
            "camera_spawn_regression_root_cause",
            "wrong_code_noop_root_cause",
            "camera_response_status_after_pass",
            "wrong_code_count_status",
            "tiny_fake_guard_decision",
            "beam_location_testability",
            "kimi_status",
            "runtime_validation_status",
            "manual_test_checklist_included",
            "static_validator_status",
        ):
            if k not in fr:
                failures.append(f"final report missing key: {k}")
    else:
        failures.append("missing final report json")

    try:
        cp = subprocess.run(
            ["git", "diff", "--name-only", "HEAD", "--", "project.godot"],
            cwd=REPO,
            capture_output=True,
            text=True,
            check=False,
        )
        if cp.returncode == 0 and cp.stdout.strip():
            failures.append("project.godot in git diff")
    except OSError:
        pass

    bad: list[str] = []
    for p in _git_changed():
        for sub in FORBIDDEN:
            if sub in p:
                bad.append(p)
    if bad:
        failures.append(f"forbidden in git diff: {bad}")

    ok = not failures
    VALIDATION.write_text(json.dumps({"static_validator_passed": ok, "failures": failures}, indent=2) + "\n", encoding="utf-8")
    VALIDATION_MD.write_text(
        "# FIX2 validation\n\n**PASS**" if ok else "# FAIL\n\n" + "\n".join(failures),
        encoding="utf-8",
    )
    RUN.write_text(
        json.dumps({"pass_id": "0M-D6-01-FIX2", "static_validator_passed": ok, "failures": failures}, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
