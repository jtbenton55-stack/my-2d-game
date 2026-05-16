#!/usr/bin/env python3
"""D6-01-FIX7C static validator — reports, final JSON fields, forbidden edits."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR_NAME = "d6_01_fix7c_ambush_beam_geometry_tune"
REQUIRED = [
    "phase0md6_01_fix7c_safety_baseline.md",
    "phase0md6_01_fix7c_safety_baseline.json",
    "phase0md6_01_fix7c_beam_geometry_audit.md",
    "phase0md6_01_fix7c_beam_geometry_audit.json",
    "phase0md6_01_fix7c_implementation.md",
    "phase0md6_01_fix7c_implementation.json",
    "phase0md6_01_fix7c_f10_update.md",
    "phase0md6_01_fix7c_f10_update.json",
    "phase0md6_01_fix7c_runtime_validation.md",
    "phase0md6_01_fix7c_runtime_validation.json",
    "phase0md6_01_fix7c_validation.md",
    "phase0md6_01_fix7c_validation.json",
    "phase0md6_01_fix7c_final_report.md",
    "phase0md6_01_fix7c_final_report.json",
]

FORBIDDEN = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    report_dir = root / "docs" / "reports" / REPORT_DIR_NAME
    errors: list[str] = []

    for name in REQUIRED:
        p = report_dir / name
        if not p.is_file():
            errors.append(f"missing: {p.relative_to(root)}")

    final_json = report_dir / "phase0md6_01_fix7c_final_report.json"
    if final_json.is_file():
        try:
            fr = json.loads(final_json.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"final_report JSON: {e}")
        else:
            for key in (
                "beam_moved_left",
                "beam_new_height",
                "beam_new_trigger_size",
                "beam_trip_status",
                "beam_guard_spawn_status",
                "camera_guard_spawn_preserved",
                "wrong_code_guard_spawn_preserved",
                "runtime_validation_status",
                "static_validator_result",
            ):
                if key not in fr:
                    errors.append(f"final_report.json missing: {key}")
            if fr.get("beam_moved_left") is not True:
                errors.append("final_report beam_moved_left must be true")
            if fr.get("project_godot_modified") is not False:
                errors.append("final_report project_godot_modified must be false")

    val_json = report_dir / "phase0md6_01_fix7c_validation.json"
    if val_json.is_file():
        try:
            v = json.loads(val_json.read_text(encoding="utf-8"))
            ha = v.get("hard_assertions", {})
            for k, want in ha.items():
                if want is not True:
                    errors.append(f"validation.json hard_assertions.{k} != true")
        except json.JSONDecodeError as e:
            errors.append(f"validation.json: {e}")

    changed: list[str] = []
    try:
        for args in (["git", "diff", "--name-only"], ["git", "diff", "--cached", "--name-only"]):
            out = subprocess.run(args, cwd=str(root), capture_output=True, text=True, check=False)
            for ln in out.stdout.splitlines():
                s = ln.strip().replace("\\", "/")
                if s:
                    changed.append(s)
        changed = list(dict.fromkeys(changed))
    except OSError as e:
        errors.append(f"git: {e}")

    for bad in FORBIDDEN:
        for c in changed:
            if bad in c:
                errors.append(f"forbidden modified: {c}")

    run_path = report_dir / "phase0md6_01_fix7c_static_validator_run.json"
    run_path.parent.mkdir(parents=True, exist_ok=True)
    run_path.write_text(
        json.dumps(
            {"validator": Path(__file__).name, "repo_root": str(root), "errors": errors, "passed": not errors},
            indent=2,
        ),
        encoding="utf-8",
    )

    if errors:
        print("VALIDATOR FAIL:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("VALIDATOR PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
