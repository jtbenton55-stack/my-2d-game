#!/usr/bin/env python3
"""PHASE 0M-D6-05D door lock physics parity static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_05d_door_lock_physics_parity"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    door = root / "src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd"
    author = root / "src/missions/iso/authoring/DoorLockEffectAuthor.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if door.is_file():
        dt = door.read_text(encoding="utf-8")
        for needle in ("apply_locked_state", "set_locked", "collision_enabled", "_apply_physics_locked"):
            if needle not in dt:
                errors.append(f"test door missing {needle}")
    else:
        errors.append("missing D6_05A_TestDoorLockTarget.gd")

    if author.is_file():
        at = author.read_text(encoding="utf-8")
        for needle in ("apply_locked_state", "set_locked", "collision_enabled", "rejected_collision_not_applied"):
            if needle not in at:
                errors.append(f"DoorLockEffectAuthor missing {needle}")
    else:
        errors.append("missing DoorLockEffectAuthor.gd")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "WARNING: visual locked but collision disabled" not in pt:
            errors.append("F10 missing visual/physics mismatch warning")
        if "D6-05D" not in pt:
            errors.append("F10 missing D6-05D section")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        if tt.count("D6_05A_TestDoorLock_Target") < 3:
            errors.append("Taco scene missing proof door references on authors")
        lock_chunk = tt.split("DoorLock_Lock_Author", 1)
        unlock_chunk = tt.split("DoorLock_Unlock_Author", 1)
        if len(lock_chunk) < 2 or 'lock_action = &"lock"' not in lock_chunk[1][:400]:
            errors.append("DoorLock_Lock_Author missing lock action")
        if len(unlock_chunk) < 2 or 'lock_action = &"unlock"' not in unlock_chunk[1][:400]:
            errors.append("DoorLock_Unlock_Author missing unlock action")
        if 'target_gate_id = &"GATE_garage_code"' in tt:
            errors.append("door authors must not target GATE_garage_code")
    else:
        errors.append("missing Taco scene")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_05d_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
