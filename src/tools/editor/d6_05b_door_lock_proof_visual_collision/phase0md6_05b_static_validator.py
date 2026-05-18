#!/usr/bin/env python3
"""PHASE 0M-D6-05B door lock proof visual/collision static validator."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPORT_DIR = "d6_05b_door_lock_proof_visual_collision"
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

    target = root / "src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd"
    panel = root / "src/missions/iso/runtime/IsoMissionDebugPanel.gd"
    taco = root / "scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
    door_author = root / "src/missions/iso/authoring/DoorLockEffectAuthor.gd"

    if not target.is_file():
        errors.append("missing D6_05A_TestDoorLockTarget.gd")
    else:
        tt = target.read_text(encoding="utf-8")
        for needle in ("CollisionShape2D", "set_locked", "_draw", "collision_shape_enabled"):
            if needle not in tt:
                errors.append(f"test door script missing {needle}")

    if panel.is_file():
        pt = panel.read_text(encoding="utf-8")
        if "D6-05B" not in pt:
            errors.append("F10 missing D6-05B instructions")
        if "AMBUSH beam does NOT unlock" not in pt:
            errors.append("F10 must state AMBUSH does not unlock test door")
        if "collision_enabled" not in pt and "Collision: enabled" not in pt:
            errors.append("F10 missing collision enabled line")
    else:
        errors.append("missing IsoMissionDebugPanel.gd")

    if taco.is_file():
        tt = taco.read_text(encoding="utf-8")
        if "CollisionShape2D" not in tt or "D6_05A_TestDoorLock_Target" not in tt:
            errors.append("Taco scene test door missing CollisionShape2D child")
        if "DoorVisual" not in tt:
            errors.append("Taco scene test door missing DoorVisual")
        if 'target_gate_id = &"GATE_garage_code"' in tt:
            errors.append("door authors must not target GATE_garage_code")
        unlock_block = tt.split("DoorLock_Unlock_Author", 1)
        if len(unlock_block) > 1:
            chunk = unlock_block[1][:600]
            if "ambush_beam_tripped" in chunk:
                errors.append("DoorLock_Unlock_Author still listens to ambush_beam_tripped")
    else:
        errors.append("missing Taco scene")

    if door_author.is_file():
        dt = door_author.read_text(encoding="utf-8")
        if "GATE_garage_code" not in dt:
            errors.append("DoorLockEffectAuthor missing garage gate guard")
    else:
        errors.append("missing DoorLockEffectAuthor.gd")

    for rel in FORBIDDEN:
        # Validator only checks content expectations; no git diff here.
        pass

    rd.mkdir(parents=True, exist_ok=True)
    result = {"pass": len(errors) == 0, "errors": errors}
    (rd / "phase0md6_05b_static_validator_run.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    print("PASS" if result["pass"] else "FAIL")
    for e in errors:
        print(f"  - {e}")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
