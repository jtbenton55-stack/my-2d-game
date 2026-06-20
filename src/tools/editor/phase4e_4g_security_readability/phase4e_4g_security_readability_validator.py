#!/usr/bin/env python3
"""Phase 4E-4G-lite security readability validator (read-only)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "phase4e_4g_security_readability"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def require_contains(errors: list[str], text: str, needle: str, label: str) -> None:
    if needle not in text:
        errors.append(f"{label} missing `{needle}`")


def main() -> int:
    root = repo_root()
    errors: list[str] = []
    warnings: list[str] = []

    camera = root / "src/missions/iso/runtime/MissionSecurityCamera.gd"
    camera_author = root / "src/missions/iso/authoring/SecurityCameraAuthor.gd"
    hide_spot = root / "src/missions/iso/authoring/mechanics/HideSpotNode.gd"
    hide_template = root / "scenes/missions/iso/authoring/HideSpotNodeTemplate.tscn"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    tests = root / "tests/mission_authoring/SecurityReadabilityLiteTest.gd"
    roadmap = root / "docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md"
    blueprint = root / "docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md"
    report = root / "reports/ai/2026-06-17_phase4e_4g_security_readability_lite_report.md"

    for path in (camera, camera_author, hide_spot, hide_template, taco, tests, roadmap, blueprint, report):
        if not path.is_file():
            errors.append(f"missing required file: {path.relative_to(root)}")

    require_contains(errors, read_text(camera), "get_sweep_debug_state", "MissionSecurityCamera")
    require_contains(errors, read_text(camera), "get_sweep_readability_line", "MissionSecurityCamera")
    require_contains(errors, read_text(camera_author), "sweep_readability_label", "SecurityCameraAuthor")
    require_contains(errors, read_text(camera_author), "get_camera_readability_summary", "SecurityCameraAuthor")

    hide_text = read_text(hide_spot)
    require_contains(errors, hide_text, "class_name HideSpotNode", "HideSpotNode")
    require_contains(errors, hide_text, "MissionAlertController", "HideSpotNode")
    require_contains(errors, hide_text, "set_detection_modifier", "HideSpotNode")
    require_contains(errors, read_text(hide_template), "CHANGE_ME_HIDE_SPOT_ID", "HideSpotNodeTemplate")

    taco_text = read_text(taco)
    require_contains(errors, taco_text, "Phase4G_CameraAlarmEffectSet_Author", "Taco scene")
    require_contains(errors, taco_text, "phase4g_camera_alarm_seen", "Taco scene")
    require_contains(errors, taco_text, "test_camera_alarm", "Taco scene")
    require_contains(errors, taco_text, "SecurityEffectSetAuthor.gd", "Taco scene")

    test_text = read_text(tests)
    require_contains(errors, test_text, "test_camera_sweep_debug_state_is_predictable", "SecurityReadabilityLiteTest")
    require_contains(errors, test_text, "test_hide_spot_reduces_and_resets_detection_modifier", "SecurityReadabilityLiteTest")
    require_contains(errors, test_text, "test_taco_phase4g_camera_alarm_effect_set_slice_exists", "SecurityReadabilityLiteTest")

    if "Phase 4E-4G-Lite" not in read_text(roadmap):
        warnings.append("roadmap status heading not found exactly")

    result = {
        "pass": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "limitations": [
            "Static validator cannot prove manual Taco playability; use GdUnit/headless smoke/manual QA.",
            "Hide spot art/tutorialization is intentionally out of scope for this lite packet.",
        ],
    }
    out_dir = root / "docs/reports" / REPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "phase4e_4g_security_readability_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )

    if errors:
        print("FAIL")
        for error in errors:
            print(f"  ERROR: {error}")
        for warning in warnings:
            print(f"  WARN: {warning}")
        return 1
    print("PASS")
    for warning in warnings:
        print(f"  WARN: {warning}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
