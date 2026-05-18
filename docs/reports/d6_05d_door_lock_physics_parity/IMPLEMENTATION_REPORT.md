# D6-05D — Door Lock Physics Parity — Implementation Report

**Date:** 2026-05-17  
**Status:** PASS

## Root cause

Zone and camera events both called `DoorLockEffectAuthor`, but:

1. **`_door_success` reported `locked` without verifying physics** — hardcoded `lock_state: true` after `set_locked`, so F10 could show locked while collision stayed off.
2. **Physics application was fragile** — cached shape reference; `collision_layer` set only via bitmask assignment without `set_collision_layer_value`.
3. **No post-apply verification** — effect could report success if visuals updated but `CollisionShape2D` remained disabled.

Camera path appeared to work when timing/deferred physics aligned; zone path exposed the gap.

## Fix

### `D6_05A_TestDoorLockTarget.gd`

- `apply_locked_state(locked) -> Dictionary` — single API for visual + physics.
- `_apply_physics_locked()` — always resolves live `CollisionShape2D`, sets `disabled`, `collision_layer`, and `set_collision_layer_value(3, locked)`.
- `get_runtime_debug_state()` includes `collision_enabled`, `physics_matches_visual`.

### `DoorLockEffectAuthor.gd`

- Prefers `apply_locked_state()` then `set_locked()`.
- Resolves proof door via `d6_05a_test_door_lock` group when path targets test door.
- Rejects with `rejected_collision_not_applied` / `rejected_physics_mismatch` if physics does not match requested lock.
- Result dict includes `collision_enabled`, `collision_layer`.

### F10 / mission debug

- D6-05D section with visual vs physics lines.
- Warnings: visual locked + collision disabled (and inverse).

### Scene

- `DoorLock_Unlock_Author.lock_action = unlock` set explicitly.

## Unchanged

- Garage `GATE_garage_code` guard, AMBUSH does not unlock door, zone runtime triggers (D6-05C).
