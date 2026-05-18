# D6-05A — Runtime Validation Report

**Scene:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`  
**Tool:** Godot MCP Pro (play_scene + execute_game_script)  
**Date:** 2026-05-17

## Results

| Step | Result |
|------|--------|
| Proof door exists | PASS — `GameplayRoot/SecurityAuthoringRoot/TestDoorLockProof/D6_05A_TestDoorLock_Target` |
| Initial state | `unlocked`, `collision_layer: 0` |
| `d6_05a_lock_test_door` | PASS — `handled: true`, door `locked`, `collision_layer: 4` |
| `d6_05a_unlock_test_door` | PASS — `handled: true`, door `unlocked`, `collision_layer: 0` |
| `test_camera_alarm` → lock | PASS — door `locked` |
| `ambush_beam_tripped` → unlock | PASS — door `unlocked` |
| F10 fields after unlock | `d6_05_last_door_action: unlock`, `d6_05_last_door_lock_state: unlocked`, target path populated |
| `d6_05_door_effect_count` | 2 |
| AMBUSH beam anchor | Still armed at ~(8296, 336) |
| Authored camera | Present at `EntityRoot/Cameras/AuthoredCamera_test_camera_01` |

## Bug fixed during validation

- **Issue:** `rejected_missing_target` — NodePaths on effect authors are relative to the author node, not `SecurityAuthoringRoot`.
- **Fix:** Scene paths use `../TestDoorLockProof/...`; `DoorLockEffectAuthor._resolve_target_node()` also resolves via parent authoring root and mission paths.

## Prior parse error (fixed)

- `DoorLockEffectAuthor.gd` toggle branch: renamed `open` → `was_open` (type inference).

## Screenshot

- MCP `get_game_screenshot` captured play view (player spawn area; test door is east of AMBUSH beam — navigate right from authoring test region).

## GdUnit4

- No door-lock-specific tests found; not run.

## DAP

- Not required; lock state verified via `get_runtime_debug_state()` on proof target.

## Known unrelated noise

- `ObjectiveEffectAuthor` meta keys with `:` may log errors on beam trip (pre-D6-05); does not block door proof.
