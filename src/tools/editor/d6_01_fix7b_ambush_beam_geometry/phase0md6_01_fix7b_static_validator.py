#!/usr/bin/env python3
"""
D6-01-FIX7B static validator: required reports, JSON assertions, forbidden file edits.
Run from repo root: python src/tools/editor/d6_01_fix7b_ambush_beam_geometry/phase0md6_01_fix7b_static_validator.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR_NAME = "d6_01_fix7b_ambush_beam_geometry"
REQUIRED_JSON = [
    "phase0md6_01_fix7b_safety_baseline.json",
    "phase0md6_01_fix7b_current_beam_geometry_audit.json",
    "phase0md6_01_fix7b_hallway_placement_strategy.json",
    "phase0md6_01_fix7b_kimi_review.json",
    "phase0md6_01_fix7b_vertical_beam_implementation.json",
    "phase0md6_01_fix7b_f10_beam_geometry_proof.json",
    "phase0md6_01_fix7b_non_regression.json",
    "phase0md6_01_fix7b_static_self_review.json",
    "phase0md6_01_fix7b_runtime_validation.json",
    "phase0md6_01_fix7b_validation.json",
    "phase0md6_01_fix7b_final_report.json",
]
REQUIRED_MD = [j.replace(".json", ".md") for j in REQUIRED_JSON]

FORBIDDEN_PATH_SNIPPETS = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
]


def repo_root() -> Path:
    here = Path(__file__).resolve()
    # .../games/my-2d-game/src/tools/editor/... -> parents[4]
    return here.parents[4]


def main() -> int:
    root = repo_root()
    report_dir = root / "docs" / "reports" / REPORT_DIR_NAME
    errors: list[str] = []

    for name in REQUIRED_JSON + REQUIRED_MD:
        p = report_dir / name
        if not p.is_file():
            errors.append(f"missing report file: {p.relative_to(root)}")

    for jname in REQUIRED_JSON:
        p = report_dir / jname
        if not p.is_file():
            continue
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"invalid JSON {p.name}: {e}")
            continue
        asserts = data.get("hard_assertions")
        if isinstance(asserts, dict):
            for k, v in asserts.items():
                if v is not True:
                    errors.append(f"{p.name} hard_assertions.{k} != true (got {v!r})")

    final_path = report_dir / "phase0md6_01_fix7b_final_report.json"
    if final_path.is_file():
        try:
            fr = json.loads(final_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"final_report JSON: {e}")
        else:
            for key in (
                "beam_orientation_after_pass",
                "wall_to_wall_coverage_status",
                "visual_trigger_mismatch_status",
                "beam_trip_status",
                "single_guard_response_status",
                "four_guard_ambush_implemented",
                "runtime_validation_status",
                "static_validator_result",
                "kimi_status",
            ):
                if key not in fr:
                    errors.append(f"final_report.json missing key: {key}")
            if fr.get("four_guard_ambush_implemented") is not False:
                errors.append("final_report must state four_guard_ambush_implemented: false")
            if fr.get("beam_orientation_after_pass") != "vertical":
                errors.append("final_report beam_orientation_after_pass must be 'vertical'")

    # Uncommitted changes (working tree + index)
    changed: list[str] = []
    try:
        for args in (["git", "diff", "--name-only"], ["git", "diff", "--cached", "--name-only"]):
            out = subprocess.run(
                args,
                cwd=str(root),
                capture_output=True,
                text=True,
                check=False,
            )
            for ln in out.stdout.splitlines():
                s = ln.strip().replace("\\", "/")
                if s:
                    changed.append(s)
        changed = list(dict.fromkeys(changed))
    except OSError as e:
        errors.append(f"git diff failed: {e}")

    for bad in FORBIDDEN_PATH_SNIPPETS:
        for c in changed:
            if bad in c.replace("\\", "/"):
                errors.append(f"forbidden file modified: {c}")

    run_out = {
        "validator": "phase0md6_01_fix7b_static_validator.py",
        "repo_root": str(root),
        "errors": errors,
        "passed": len(errors) == 0,
    }
    run_path = report_dir / "phase0md6_01_fix7b_static_validator_run.json"
    run_path.parent.mkdir(parents=True, exist_ok=True)
    run_path.write_text(json.dumps(run_out, indent=2), encoding="utf-8")

    if errors:
        print("VALIDATOR FAIL:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("VALIDATOR PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
