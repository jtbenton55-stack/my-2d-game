# D6-05A — Safe Door Lock Effect Proof — Final Report

## 1. Goal — **PASSED**

`DoorLockEffectAuthor` is proven on a dedicated test door in Taco. Lock and unlock work via events; F10 reports state; real garage code gate is not used.

## 2. Files changed

**Added**

- `src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd` (+ `.uid`)
- `src/tools/editor/d6_05a_safe_door_lock_effect_proof/phase0md6_05a_static_validator.py`
- `docs/reports/d6_05a_safe_door_lock_effect_proof/*`

**Modified (D6-05A scope)**

- `src/missions/iso/authoring/DoorLockEffectAuthor.gd`
- `src/levels/IsoMissionBase.gd` (narrow door debug + effect recording)
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd` (F10 door section)
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (proof door, zones, authors)

**Protected — untouched**

- `project.godot`, `Player.gd`, `player.tscn`, HUD, pause, F1/F10/F11 handlers, mission launcher, HideoutHub, save/load, heat persistence.

## 3. Test door location

| | |
|--|--|
| **Scene path** | `GameplayRoot/SecurityAuthoringRoot/TestDoorLockProof/D6_05A_TestDoorLock_Target` |
| **Approx. world position** | ~(7970, 569) — east of AMBUSH beam (~8296, 336), near security authoring test cluster |
| **Visual label** | `D6-05A TEST LOCK DOOR` (red = locked, green = unlocked) |
| **How to find** | From player spawn, go **right** past the pink AMBUSH beam corridor; look for the labeled colored door block and cyan **LOCK ZONE** / lime **UNLOCK ZONE** markers |

## 4. Manual test instructions

### Lock the door

1. Walk into the **LOCK ZONE** (west of the test door), **or**
2. Trip the authored test camera alarm (`test_camera_alarm`), **or**
3. Debug: emit `d6_05a_lock_test_door`.

**Expect:** Label shows `[LOCKED]`, door turns red, `collision_layer` blocks layer 4 (player cannot pass through the door body).

### Unlock the door

1. Walk into the **UNLOCK ZONE** (east of the door), **or**
2. Cross the **AMBUSH beam** (`ambush_beam_tripped`), **or**
3. Debug: emit `d6_05a_unlock_test_door`.

**Expect:** Label shows `[UNLOCKED]`, door turns green, collision layer 0 (passable).

### F10 (press F10 in mission)

Look for **Door Lock Test (D6-05A)**:

- Test door path and `lock_state`
- Last door action / result / reason
- Line: use labeled lock/unlock zones near **TEST LOCK DOOR**; camera alarm locks; AMBUSH beam unlocks

## 5. Systems reused

- `SecurityEventRouter` + `MissionAuthoringRuntimeBuilder` effect registration (D6-03/D6-05).
- `SecurityEffectAuthorBase` listener pattern.
- `AreaTriggerAuthor` for dedicated lock/unlock zones.
- No duplicate lock manager; proof uses local `set_locked()` API on test `StaticBody2D`.

## 6. Systems modified

- `DoorLockEffectAuthor` — target resolution, structured results, garage gate guard.
- `IsoMissionBase` — door effect F10 fields.
- `IsoMissionDebugPanel` — D6-05A section.
- Taco scene — proof nodes only.

## 7. Safety confirmation

- Real `GATE_garage_code` / garage progression: **not modified**; door authors target only `D6_05A_TestDoorLock_Target`.
- No secrets or files outside repo accessed.
- No git commit/push/branch/history operations.

## 8. Godot validation

| Tool | Result |
|------|--------|
| Godot MCP Pro | play_scene, event emits, state inspection — PASS |
| LSP diagnostics | scan returned no issues on changed scripts |
| GdUnit4 | No relevant tests — skipped |
| DAP | Not needed |

**Runtime summary**

| Event | Target | Before | After |
|-------|--------|--------|-------|
| `d6_05a_lock_test_door` | D6_05A_TestDoorLock_Target | unlocked / layer 0 | locked / layer 4 |
| `d6_05a_unlock_test_door` | same | locked | unlocked / layer 0 |
| `test_camera_alarm` | same | unlocked | locked |
| `ambush_beam_tripped` | same | locked | unlocked |

## 9. Known limitations

- Proof door is test-only; not wired to real code gates or save state.
- `require_key` / `require_code` actions are reserved for a future pass.
- MCP could not walk the player through trigger zones autonomously; zones are placed for manual playtest.
- `ObjectiveEffectAuthor` colon meta keys may still log on beam trip (separate cleanup).

## 10. Suggested next step

Continue to **D6-06 collectible authoring** with the same event-router + effect-author pattern.
