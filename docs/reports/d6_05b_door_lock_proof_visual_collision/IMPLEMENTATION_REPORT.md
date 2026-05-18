# D6-05B — Door Lock Proof Visual / Collision Polish — Implementation Report

**Date:** 2026-05-17  
**Branch:** `c2a-full-character-animation-20260509-172230`  
**Status:** PASS

## Changes

### `D6_05A_TestDoorLockTarget.gd` (@tool)

- Added `@tool` with `_draw()` red/green fill + border (editor + runtime).
- Collision: child `CollisionShape2D` with `RectangleShape2D` (140×32).
- **Locked:** shape enabled + `collision_layer = 4` (walls; player mask includes bit 4).
- **Unlocked:** shape **disabled** + `collision_layer = 0` (passable).
- Brighter `ColorRect` + label; `z_index` raised for visibility.

### Taco scene

- Saved scene children: `CollisionShape2D`, `DoorVisual`, `DoorLabel` (removes editor “no shape” warning).
- Door repositioned to local `(0, -200)` under `TestDoorLockProof` (9280, 400).
- **Cyan LOCK ZONE** west (`-180, -200`).
- **Lime UNLOCK ZONE** south `(0, -120)` — reachable without crossing the door barrier.
- `DoorLock_Unlock_Author`: removed `ambush_beam_tripped` listener (lime zone / `d6_05a_unlock_test_door` only).

### F10 / mission debug

- `IsoMissionDebugPanel`: D6-05B section, collision enabled/layer, updated instructions.
- `IsoMissionBase`: `d6_05a_test_door_collision_enabled` / `collision_layer` in summary.

### Validator

- `src/tools/editor/d6_05b_door_lock_proof_visual_collision/phase0md6_05b_static_validator.py` — PASS

## Protected / untouched

- `project.godot`, `Player.gd`, `player.tscn`, garage `GATE_garage_code`, AMBUSH guard-spawn wiring.
