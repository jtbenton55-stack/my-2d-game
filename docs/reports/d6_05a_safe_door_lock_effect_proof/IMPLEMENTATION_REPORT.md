# D6-05A — Safe Door Lock Effect Proof — Implementation Report

**Date:** 2026-05-17  
**Branch:** `c2a-full-character-animation-20260509-172230`  
**Status:** PASS

## Goal

Prove `DoorLockEffectAuthor` on a safe, non-mission-critical test door in Taco without touching the real garage code gate.

## What was added/changed

### New proof target

- `src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd` — `StaticBody2D` with `set_locked()`, `is_locked()`, `get_lock_state()`, collision layer toggle (4 when locked, 0 when unlocked), red/green visual + label `D6-05A TEST LOCK DOOR [LOCKED/UNLOCKED]`.

### DoorLockEffectAuthor hardening

- Actions: `lock`, `unlock`, `toggle` (optional `require_key` / `require_code` documented as future; rejected if used).
- Structured result: `handled`, `result`, `reason`, `target_path`, `lock_state`, `lock_action`.
- Rejects `target_gate_id == GATE_garage_code`.
- Target resolution: self → parent `SecurityAuthoringRoot` → mission → full authoring path (fixes author-relative NodePath bug).

### Taco scene proof wiring

Under `GameplayRoot/SecurityAuthoringRoot`:

| Node | Purpose |
|------|---------|
| `TestDoorLockProof/D6_05A_TestDoorLock_Target` | Proof door (~7970, 569 world) |
| `D6_05A_LockZone_Author` | Emits `d6_05a_lock_test_door` |
| `D6_05A_UnlockZone_Author` | Emits `d6_05a_unlock_test_door` |
| `DoorLock_Lock_Author` | Locks on `test_camera_alarm` + `d6_05a_lock_test_door` |
| `DoorLock_Unlock_Author` | Unlocks on `ambush_beam_tripped` + `d6_05a_unlock_test_door` |

Target path on authors: `../TestDoorLockProof/D6_05A_TestDoorLock_Target`.

### F10 / mission debug

- `IsoMissionBase.gd`: `d6_05a_test_door_*`, `d6_05_last_door_*` in runtime summary + effect recording.
- `IsoMissionDebugPanel.gd`: "Door Lock Test (D6-05A)" section with manual test lines.

### Validator

- `src/tools/editor/d6_05a_safe_door_lock_effect_proof/phase0md6_05a_static_validator.py` — PASS

## Protected files (not modified)

- `project.godot`, `Player.gd`, `player.tscn`, HUD, pause, F1/F10/F11 input, mission launcher, HideoutHub, save/load, heat persistence.

## Real garage gate

- Not targeted by door lock authors. `GATE_garage_code` explicitly rejected in `DoorLockEffectAuthor`.

## Kimi

- Not used. No secrets or private files sent.
