#!/usr/bin/env python3
"""D6-01-FIX7D static validator — reports, final JSON, forbidden edits."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPORT_DIR = "d6_01_fix7d_ambush_beam_collision_boundary"
REQUIRED = [
    "phase0md6_01_fix7d_safety_baseline.md",
    "phase0md6_01_fix7d_safety_baseline.json",
    "phase0md6_01_fix7d_collision_geometry_audit.md",
    "phase0md6_01_fix7d_collision_geometry_audit.json",
    "phase0md6_01_fix7d_implementation.md",
    "phase0md6_01_fix7d_implementation.json",
    "phase0md6_01_fix7d_f10_collision_proof.md",
    "phase0md6_01_fix7d_f10_collision_proof.json",
    "phase0md6_01_fix7d_runtime_validation.md",
    "phase0md6_01_fix7d_runtime_validation.json",
    "phase0md6_01_fix7d_validation.md",
    "phase0md6_01_fix7d_validation.json",
    "phase0md6_01_fix7d_final_report.md",
    "phase0md6_01_fix7d_final_report.json",
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
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    for name in REQUIRED:
        p = rd / name
        if not p.is_file():
            errors.append(f"missing {p.relative_to(root)}")

    fj = rd / "phase0md6_01_fix7d_final_report.json"
    if fj.is_file():
        try:
            fr = json.loads(fj.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"final_report json: {e}")
        else:
            for k in (
                "collision_boundary_method",
                "fallback_used",
                "choke_x",
                "top_boundary_y",
                "bottom_boundary_y",
                "beam_center",
                "beam_height",
                "trigger_size",
                "beam_trip_status",
                "beam_guard_spawn_status",
                "camera_guard_spawn_preserved",
                "wrong_code_guard_spawn_preserved",
                "runtime_validation_status",
                "static_validator_result",
            ):
                if k not in fr:
                    errors.append(f"final_report missing {k}")
            if fr.get("project_godot_modified") is not False:
                errors.append("project_godot_modified must be false")

    vj = rd / "phase0md6_01_fix7d_validation.json"
    if vj.is_file():
        try:
            v = json.loads(vj.read_text(encoding="utf-8"))
            for k, val in v.get("hard_assertions", {}).items():
                if val is not True:
                    errors.append(f"validation hard_assertions.{k} != true")
        except json.JSONDecodeError as e:
            errors.append(str(e))

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
        errors.append(str(e))

    for bad in FORBIDDEN:
        for c in changed:
            if bad in c:
                errors.append(f"forbidden modified: {c}")

    (rd / "phase0md6_01_fix7d_static_validator_run.json").write_text(
        json.dumps({"errors": errors, "passed": not errors}, indent=2),
        encoding="utf-8",
    )
    if errors:
        print("VALIDATOR FAIL:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print("VALIDATOR PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
