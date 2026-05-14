#!/usr/bin/env python3
"""0M-D6-01-FIX1 — Static validator for security runtime fix pass."""
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
REPORTS = REPO / "docs" / "reports" / "d6_01_fix1_security_runtime_behavior"
FINAL = REPORTS / "phase0md6_01_fix1_final_report.json"
RUN = REPORTS / "phase0md6_01_fix1_static_validator_run.json"
VALIDATION = REPORTS / "phase0md6_01_fix1_validation.json"
VALIDATION_MD = REPORTS / "phase0md6_01_fix1_validation.md"
PROJECT = REPO / "project.godot"

REQUIRED = [
    "phase0md6_01_fix1_safety_baseline.md",
    "phase0md6_01_fix1_safety_baseline.json",
    "phase0md6_01_fix1_guard_template_audit.md",
    "phase0md6_01_fix1_guard_template_audit.json",
    "phase0md6_01_fix1_camera_response_audit.md",
    "phase0md6_01_fix1_camera_response_audit.json",
    "phase0md6_01_fix1_beam_truth_audit.md",
    "phase0md6_01_fix1_beam_truth_audit.json",
    "phase0md6_01_fix1_heat_effect_audit.md",
    "phase0md6_01_fix1_heat_effect_audit.json",
    "phase0md6_01_fix1_kimi_review.md",
    "phase0md6_01_fix1_kimi_review.json",
    "phase0md6_01_fix1_guard_spawn_fix.md",
    "phase0md6_01_fix1_guard_spawn_fix.json",
    "phase0md6_01_fix1_spawned_guard_behavior_fix.md",
    "phase0md6_01_fix1_spawned_guard_behavior_fix.json",
    "phase0md6_01_fix1_camera_unification_fix.md",
    "phase0md6_01_fix1_camera_unification_fix.json",
    "phase0md6_01_fix1_beam_fix.md",
    "phase0md6_01_fix1_beam_fix.json",
    "phase0md6_01_fix1_heat_effect_fix.md",
    "phase0md6_01_fix1_heat_effect_fix.json",
    "phase0md6_01_fix1_ui_debug_non_regression.md",
    "phase0md6_01_fix1_ui_debug_non_regression.json",
    "phase0md6_01_fix1_static_self_review.md",
    "phase0md6_01_fix1_static_self_review.json",
    "phase0md6_01_fix1_runtime_validation.md",
    "phase0md6_01_fix1_runtime_validation.json",
    "phase0md6_01_fix1_final_report.md",
    "phase0md6_01_fix1_final_report.json",
    "phase0md6_01_fix1_validation.md",
    "phase0md6_01_fix1_validation.json",
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

    adapter = REPO / "src" / "missions" / "iso" / "runtime" / "MissionSecurityEventAdapter.gd"
    if not adapter.is_file():
        failures.append("MissionSecurityEventAdapter.gd missing")

    if FINAL.is_file():
        fr = json.loads(FINAL.read_text(encoding="utf-8"))
        for k in (
            "verdict",
            "good_guard_template",
            "bad_guard_template",
            "bad_guard_used_for_security_spawns",
            "camera_unification_summary",
            "beam_truth_summary",
            "heat_effect_summary",
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
            failures.append("project.godot appears in git diff (must not be modified)")
    except OSError:
        pass

    bad: list[str] = []
    for p in _git_changed():
        for sub in FORBIDDEN:
            if sub in p:
                bad.append(p)
    if bad:
        failures.append(f"forbidden paths in git diff: {bad}")

    ok = not failures
    VALIDATION.write_text(json.dumps({"static_validator_passed": ok, "failures": failures}, indent=2) + "\n", encoding="utf-8")
    VALIDATION_MD.write_text(
        "# 0M-D6-01-FIX1 validation\n\n**PASS**" if ok else "# FAIL\n\n" + "\n".join(failures),
        encoding="utf-8",
    )
    RUN.write_text(
        json.dumps({"pass_id": "0M-D6-01-FIX1", "static_validator_passed": ok, "failures": failures}, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
