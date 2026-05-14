#!/usr/bin/env python3
"""Static validator for 0M-D6-01-FIX4 security spawn / camera / beam / warp recovery."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

def _find_repo_root(start: Path) -> Path:
    for p in [start] + list(start.parents):
        if (p / "project.godot").is_file():
            return p
    raise RuntimeError("Could not locate project.godot above " + str(start))


REPO = _find_repo_root(Path(__file__).resolve().parent)
REPORT_DIR = REPO / "docs" / "reports" / "d6_01_fix4_security_spawn_cap_camera_beam_warp"

REQUIRED_JSON = [
    "phase0md6_01_fix4_safety_baseline.json",
    "phase0md6_01_fix4_spawn_cap_audit.json",
    "phase0md6_01_fix4_guard_cap_fix.json",
    "phase0md6_01_fix4_guard_spawn_success_fix.json",
    "phase0md6_01_fix4_camera_movement_audit.json",
    "phase0md6_01_fix4_camera_movement_fix.json",
    "phase0md6_01_fix4_dev_warp_audit.json",
    "phase0md6_01_fix4_dev_warp_fix.json",
    "phase0md6_01_fix4_beam_placement_audit.json",
    "phase0md6_01_fix4_beam_visual_fix.json",
    "phase0md6_01_fix4_hideout_heat_audit.json",
    "phase0md6_01_fix4_f10_readability.json",
    "phase0md6_01_fix4_static_self_review.json",
    "phase0md6_01_fix4_runtime_validation.json",
    "phase0md6_01_fix4_kimi_review.json",
]

REQUIRED_MD = [p.replace(".json", ".md") for p in REQUIRED_JSON] + [
    "phase0md6_01_fix4_final_report.md",
]

FORBIDDEN_MODIFIED = [
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
]


def _assertions_all_true(data: dict) -> list[str]:
    errs: list[str] = []
    ass = data.get("assertions")
    if not isinstance(ass, dict):
        errs.append("missing_assertions_object")
        return errs
    for k, v in ass.items():
        if v is not True:
            errs.append(f"assertion_not_true:{k}={v!r}")
    return errs


def main() -> int:
    errors: list[str] = []

    for name in REQUIRED_JSON:
        path = REPORT_DIR / name
        if not path.is_file():
            errors.append(f"missing_json:{name}")
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"bad_json:{name}:{e}")
            continue
        errors.extend(_assertions_all_true(data))

    for name in REQUIRED_MD:
        path = REPORT_DIR / name
        if not path.is_file():
            errors.append(f"missing_md:{name}")

    final_path = REPORT_DIR / "phase0md6_01_fix4_final_report.json"
    if final_path.is_file():
        try:
            final = json.loads(final_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"bad_json:final:{e}")
        else:
            for key in (
                "verdict",
                "cap_reached_fixed",
                "branch",
                "kimi_status",
                "runtime_validation",
            ):
                if key not in final:
                    errors.append(f"final_report_missing:{key}")
    else:
        errors.append("missing_final_report_json")

    # Forbidden files must not appear in git diff
    try:
        proc = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=str(REPO),
            capture_output=True,
            text=True,
            check=False,
        )
        changed = {line.strip().replace("\\", "/") for line in proc.stdout.splitlines() if line.strip()}
    except OSError:
        changed = set()

    for forb in FORBIDDEN_MODIFIED:
        norm = forb.replace("\\", "/")
        if any(c.endswith(norm) or c == norm for c in changed):
            errors.append(f"forbidden_modified:{norm}")

    taco_scenes = [c for c in changed if "scenes/missions_iso/" in c.replace("\\", "/") and c.endswith(".tscn")]
    if taco_scenes:
        errors.append(f"taco_scene_modified:{taco_scenes}")

    # Spot-check implementation strings exist
    iso = (REPO / "src" / "levels" / "IsoMissionBase.gd").read_text(encoding="utf-8", errors="replace")
    for needle in (
        "_count_live_security_response_guards",
        "func _spawn_guard_for_spawn(spawn_def: Resource) -> Node2D:",
        "_ensure_d6_fix4_test_helpers",
        "D6_FIX4_TEMP_BEAM_WORLD_VISUAL_REMOVE_IN_FINAL_LEVEL_PASS",
    ):
        if needle not in iso:
            errors.append(f"iso_missing:{needle}")

    cam = (REPO / "src" / "missions" / "iso" / "runtime" / "MissionSecurityCamera.gd").read_text(
        encoding="utf-8", errors="replace"
    )
    if "refresh_sweep_basis_from_world" not in cam:
        errors.append("camera_missing_refresh_sweep_basis_from_world")

    p0k = (REPO / "src" / "missions" / "iso" / "runtime" / "Phase0KCameraSpawner.gd").read_text(
        encoding="utf-8", errors="replace"
    )
    idx_add = p0k.find("parent.add_child(camera)")
    idx_pos = p0k.find("camera.global_position = (marker as Node2D).global_position")
    if idx_add == -1 or idx_pos == -1:
        errors.append("phase0k_missing_spawn_lines")
    elif idx_add > idx_pos:
        errors.append("phase0k_bad_order_position_before_add_child")

    warp = (REPO / "src" / "missions" / "iso" / "runtime" / "MissionDevTestWarp.gd").read_text(
        encoding="utf-8", errors="replace"
    )
    if "Polygon2D" not in warp or "D6_FIX4_TEMP_TEST_WARP_REMOVE_IN_FINAL_LEVEL_PASS" not in warp:
        errors.append("warp_missing_fix4_visual_or_tag")

    out = {
        "assertions": {
            "static_validator_created": True,
            "static_validator_run": True,
            "static_validator_passed": len(errors) == 0,
        },
        "errors": errors,
        "git_changed_files_sample": sorted(changed)[:40],
    }
    run_path = REPORT_DIR / "phase0md6_01_fix4_static_validator_run.json"
    run_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

    val_md = REPORT_DIR / "phase0md6_01_fix4_validation.md"
    val_md.write_text(
        "# D6-01-FIX4 static validation\n\n"
        + ("**PASS**\n" if not errors else "**FAIL**\n")
        + "\n".join(f"- {e}" for e in errors)
        + "\n",
        encoding="utf-8",
    )
    val_json = REPORT_DIR / "phase0md6_01_fix4_validation.json"
    val_json.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

    # Sync final_report static_validator field
    if final_path.is_file() and not errors:
        fr = json.loads(final_path.read_text(encoding="utf-8"))
        fr["static_validator"] = "PASS"
        final_path.write_text(json.dumps(fr, indent=2) + "\n", encoding="utf-8")

    if errors:
        print("VALIDATOR_FAIL", errors)
        return 1
    print("VALIDATOR_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
