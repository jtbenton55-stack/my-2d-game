# D6-05B — Final Report

## 1. Goal — **PASSED**

Test door is visible, has a real collision shape, blocks when locked, passes when unlocked, and event wiring matches intuitive manual testing.

## 2. Files changed

**Modified**

- `src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/levels/IsoMissionBase.gd` (collision F10 fields)

**Added**

- `src/tools/editor/d6_05b_door_lock_proof_visual_collision/phase0md6_05b_static_validator.py`
- `docs/reports/d6_05b_door_lock_proof_visual_collision/*`

**Protected:** `project.godot`, `Player.gd`, `player.tscn`, real garage gate.

## 3. Test door location

- **Path:** `GameplayRoot/SecurityAuthoringRoot/TestDoorLockProof/D6_05A_TestDoorLock_Target`
- **World:** ~**(7970, 369)** (east of spawn; security proof cluster)
- **Visual:** Red + thick red border = locked; green + green border = unlocked; label `D6-05A TEST LOCK DOOR [LOCKED/UNLOCKED]`

## 4. Collision / visual proof

| State | Visual | Collision |
|-------|--------|-------------|
| Locked | Red `ColorRect` + `_draw()` border | `CollisionShape2D` **enabled**, layer **4**, 140×32 |
| Unlocked | Green | Shape **disabled**, layer **0** |

Player `collision_mask` includes layer 4 (walls), so enabled shape blocks movement.

## 5. Manual test instructions

1. Run Taco redesign test scene; go **right** to ~9280, 200 area.
2. Find **D6-05A TEST LOCK DOOR** (colored bar) between cyan **LOCK ZONE** (west) and lime **UNLOCK ZONE** (south).
3. **Lock:** enter cyan zone **or** trigger test camera alarm.
4. **Unlock:** walk into lime zone south of door (no need to pass through door).
5. **F10:** Door Lock Test (D6-05B) — state, collision enabled/layer, last action/result.

## 6. Event wiring

| Event | Effect |
|-------|--------|
| `test_camera_alarm` | Lock |
| `d6_05a_lock_test_door` (cyan zone) | Lock |
| `d6_05a_unlock_test_door` (lime zone) | Unlock |
| `ambush_beam_tripped` | **Does not unlock** test door (guard spawn unchanged) |

Real `GATE_garage_code`: not targeted.

## 7. Godot validation

- MCP play + event emits: PASS
- LSP: no issues on changed scripts
- GdUnit4: N/A
- DAP: N/A

## 8. Safety

- Repo-only; no secrets; no git history operations.

## 9. Limitations

- Proof-only; not persisted to save.
- MCP did not walk player through zones; collision verified via shape enable/layer state.
- Camera may lock door before Jake reaches zones (by design for camera-lock test).

## 10. Next step

Proceed to **D6-06 collectible authoring**.
