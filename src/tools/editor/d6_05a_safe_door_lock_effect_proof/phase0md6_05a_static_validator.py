#!/usr/bin/env python3
"""PHASE 0M-D6-05A safe door lock effect proof static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_05a_safe_door_lock_effect_proof"
FORBIDDEN = (
    "project.godot",
    "src/player/Player.gd",
    "scenes/characters/player.tscn",
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    root = repo_root()
    rd = root / "docs" / "reports" / REPORT_DIR
    errors: list[str] = []

    door = root / "src/missions/iso/authoring/DoorLockEffectAuthor.gd"
    target = root / "src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

    if door.is_file():
        dt = door.read_text(encoding="utf-8")
        for needle in ("lock_state", "set_locked", "GATE_garage_code", "rejected_protected_gate"):
            if needle not in dt:
                errors.append(f"DoorLockEffectAuthor missing {needle}")
    else:
        errors.append("missing DoorLockEffectAuthor.gd")

    if not target.is_file():
        errors.append("missing D6_05A_TestDoorLockTarget.gd")
    else:
        tt = target.read_text(encoding="utf-8")
        if "set_locked" not in tt:
            errors.append("test door missing set_locked")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "Door Lock Test (D6-05A)" not in pt:
            errors.append("F10 missing D6-05A door section")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        for needle in (
            "D6_05A_TestDoorLock_Target",
            "DoorLock_Lock_Author",
            "DoorLock_Unlock_Author",
            "d6_05a_lock_test_door",
            "d6_05a_unlock_test_door",
        ):
            if needle not in tt:
                errors.append(f"Taco scene missing {needle}")
        if "GATE_garage_code" in tt and 'target_gate_id = &"GATE_garage_code"' in tt:
            errors.append("Taco scene must not target GATE_garage_code on door authors")
    else:
        errors.append("missing Taco scene")

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_05a_static_validator_run.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
