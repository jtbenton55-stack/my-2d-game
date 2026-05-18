#!/usr/bin/env python3
"""PHASE 0M-D6-05C door zone trigger + rotation static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_05c_door_zone_rotation_fix"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    root_gd = root / "src/missions/iso/authoring/SecurityAuthoringRoot.gd"
    area_gd = root / "src/missions/iso/authoring/AreaTriggerAuthor.gd"
    door_gd = root / "src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if root_gd.is_file():
        rt = root_gd.read_text(encoding="utf-8")
        if "_collect_area_trigger_authors_deep" not in rt:
            errors.append("SecurityAuthoringRoot missing deep area trigger collection")
    else:
        errors.append("missing SecurityAuthoringRoot.gd")

    if area_gd.is_file():
        at = area_gd.read_text(encoding="utf-8")
        if "body_entered" not in at or "PLAYER_COLLISION_MASK" not in at:
            errors.append("AreaTriggerAuthor missing body_entered / player mask setup")
    else:
        errors.append("missing AreaTriggerAuthor.gd")

    if door_gd.is_file():
        dt = door_gd.read_text(encoding="utf-8")
        for needle in ("snap_rotation_to_15_degrees", "orientation_degrees", "CollisionShape2D"):
            if needle not in dt:
                errors.append(f"test door script missing {needle}")
    else:
        errors.append("missing D6_05A_TestDoorLockTarget.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "D6-05C" not in pt or "cyan LOCK ZONE" not in pt:
            errors.append("F10 missing D6-05C zone instructions")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        if 'zone_display_name = "LOCK ZONE"' not in tt:
            errors.append("Taco missing LOCK ZONE display name")
        if 'zone_display_name = "UNLOCK ZONE"' not in tt:
            errors.append("Taco missing UNLOCK ZONE display name")
        unlock_chunk = tt.split("DoorLock_Unlock_Author", 1)
        if len(unlock_chunk) > 1 and "ambush_beam_tripped" in unlock_chunk[1][:500]:
            errors.append("DoorLock_Unlock_Author still listens to ambush_beam_tripped")
    else:
        errors.append("missing Taco scene")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_05c_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
