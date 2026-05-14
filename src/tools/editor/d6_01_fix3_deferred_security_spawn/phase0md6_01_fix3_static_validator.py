#!/usr/bin/env python3
"""0M-D6-01-FIX3 — Static validator."""
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
REPORTS = REPO / "docs" / "reports" / "d6_01_fix3_deferred_security_spawn"
FINAL = REPORTS / "phase0md6_01_fix3_final_report.json"
RUN = REPORTS / "phase0md6_01_fix3_static_validator_run.json"
VALIDATION = REPORTS / "phase0md6_01_fix3_validation.json"
VALIDATION_MD = REPORTS / "phase0md6_01_fix3_validation.md"

REQUIRED = [
    "phase0md6_01_fix3_safety_baseline.md",
    "phase0md6_01_fix3_safety_baseline.json",
    "phase0md6_01_fix3_spawn_error_audit.md",
    "phase0md6_01_fix3_spawn_error_audit.json",
    "phase0md6_01_fix3_camera_wrong_code_spawn_path_audit.md",
    "phase0md6_01_fix3_camera_wrong_code_spawn_path_audit.json",
    "phase0md6_01_fix3_kimi_review.md",
    "phase0md6_01_fix3_kimi_review.json",
    "phase0md6_01_fix3_deferred_spawn_fix.md",
    "phase0md6_01_fix3_deferred_spawn_fix.json",
    "phase0md6_01_fix3_garage_test_warp.md",
    "phase0md6_01_fix3_garage_test_warp.json",
    "phase0md6_01_fix3_beam_visual_f10_cleanup.md",
    "phase0md6_01_fix3_beam_visual_f10_cleanup.json",
    "phase0md6_01_fix3_heat_restart_audit.md",
    "phase0md6_01_fix3_heat_restart_audit.json",
    "phase0md6_01_fix3_f10_readability_cleanup.md",
    "phase0md6_01_fix3_f10_readability_cleanup.json",
    "phase0md6_01_fix3_non_regression.md",
    "phase0md6_01_fix3_non_regression.json",
    "phase0md6_01_fix3_runtime_validation.md",
    "phase0md6_01_fix3_runtime_validation.json",
    "phase0md6_01_fix3_final_report.md",
    "phase0md6_01_fix3_final_report.json",
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
            "flushing_query_error_addressed",
            "camera_guard_spawn_status",
            "wrong_code_guard_spawn_status",
            "garage_test_warp_status",
            "beam_red_line_status",
            "f10_readability_status",
            "heat_restart_audit_status",
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
    VALIDATION_MD.write_text("# FIX3 validation\n\n**PASS**" if ok else "# FAIL\n\n" + "\n".join(failures), encoding="utf-8")
    RUN.write_text(
        json.dumps({"pass_id": "0M-D6-01-FIX3", "static_validator_passed": ok, "failures": failures}, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
