#!/usr/bin/env python3
"""PHASE 0M-D6-04B camera parity + guard chase static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_04b_camera_parity_guard_chase_fix"
FORBIDDEN = (
    "project.godot",
    "src/player/Player.gd",
    "src/player/PlayerStaminaController.gd",
    "scenes/characters/player.tscn",
)
ALLOWED_PREFIXES = (
    "src/missions/iso/authoring/SecurityCameraAuthor.gd",
    "src/missions/iso/runtime/MissionSecurityCamera.gd",
    "src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd",
    "src/missions/iso/runtime/IsoMissionDebugPanel.gd",
    "src/levels/IsoMissionBase.gd",
    "src/enemies/Guard.gd",
    "src/enemies/EnemyBase.gd",
    "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
    "src/tools/editor/d6_04b_camera_parity_guard_chase_fix/",
    "docs/reports/d6_04b_camera_parity_guard_chase_fix/",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    cam_author = root / "src/missions/iso/authoring/SecurityCameraAuthor.gd"
    msc = root / "src/missions/iso/runtime/MissionSecurityCamera.gd"
    guard = root / "src/enemies/Guard.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"

    if cam_author.is_file():
        t = cam_author.read_text(encoding="utf-8")
        for needle in ("EntityRoot/Cameras", "set_script", "parity_target", "CAM_market_01"):
            if needle not in t:
                errors.append(f"SecurityCameraAuthor missing {needle}")
    else:
        errors.append("missing SecurityCameraAuthor.gd")

    if msc.is_file():
        mt = msc.read_text(encoding="utf-8")
        for needle in ("apply_authoring_config", "is_player_in_cone", "_sync_initial_overlaps"):
            if needle not in mt:
                errors.append(f"MissionSecurityCamera missing {needle}")
    else:
        errors.append("missing MissionSecurityCamera.gd")

    if guard.is_file():
        gt = guard.read_text(encoding="utf-8")
        if "aggro_range = maxf(aggro_range, 2400" in gt:
            errors.append("Guard still has screen-sized aggro_range bump")
        for needle in ("AUTHORING_CHASE_MAX_DISTANCE", "_enter_authoring_fallback", "_authoring_chase_should_end"):
            if needle not in gt:
                errors.append(f"Guard missing {needle}")
        if "authoring_force_chase" not in gt:
            errors.append("Guard missing authoring_force_chase gate")
    else:
        errors.append("missing Guard.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "Camera live:" not in pt:
            errors.append("IsoMissionDebugPanel missing camera live F10 line")
        if "Authored chase:" not in pt:
            errors.append("IsoMissionDebugPanel missing guard chase F10 line")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_04b_static_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
