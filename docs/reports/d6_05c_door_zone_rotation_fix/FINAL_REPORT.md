# D6-05C — Final Report

## 1. Goal — **PASSED**

Cyan/lime zones now create runtime triggers and lock/unlock on player entry (no interact). Test door supports 15° rotation authoring with visual/collision following parent transform.

## 2. Files changed

**Modified**

- `src/missions/iso/authoring/SecurityAuthoringRoot.gd`
- `src/missions/iso/authoring/AreaTriggerAuthor.gd`
- `src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd`
- `src/missions/iso/runtime/MissionAuthoringRuntimeBuilder.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`

**Added**

- `src/tools/editor/d6_05c_door_zone_rotation_fix/phase0md6_05c_static_validator.py`
- `docs/reports/d6_05c_door_zone_rotation_fix/*`

**Protected:** `project.godot`, `Player.gd`, `player.tscn`, garage gate.

## 3. Zone trigger fix

| | Before | After |
|--|--------|-------|
| **Problem** | Zones under `TestDoorLockProof` never registered | Deep collection finds nested authors |
| **Runtime** | No `Area2D` | `AreaTrigger_d6_05a_lock_zone` / `_unlock_zone` under `AuthoringAreaTriggers` |
| **Detection** | N/A | `Area2D.monitoring=true`, `collision_mask=1` (player `collision_layer=1`) |
| **Shape** | N/A | `CollisionShape2D` + `RectangleShape2D` 128×96 |
| **Event** | N/A | `body_entered` → router → `d6_05a_lock_test_door` / `d6_05a_unlock_test_door` |

No interact/button required.

## 4. Door rotation

- Rotate `D6_05A_TestDoorLock_Target` in editor (gizmo) or set **Orientation Degrees** in inspector.
- **Snap:** 15° when `snap_rotation_to_15_degrees` is true (default).
- **Collision/visual:** child nodes rotate with parent `StaticBody2D`.
- **Label:** counter-rotated to stay horizontal.

## 5. Manual test

1. Taco scene → security proof ~**(7974, 271)** world.
2. **Lock:** walk into **cyan LOCK ZONE** (west) or trigger camera alarm.
3. **Unlock:** walk into **lime UNLOCK ZONE** (south) — no need to pass through locked door.
4. **Rotate:** select test door in editor, rotate; snaps to 15° steps.
5. **F10:** D6-05C section — zone event, door state, rotation, collision.

## 6. Validation

- Static validator: PASS
- MCP: runtime areas + lock/unlock via zone `body_entered`; camera locks; AMBUSH does not unlock
- LSP: clean on changed scripts

## 7. Safety

- Repo-only; no git history ops; garage gate untouched.

## 8. Next step

**D6-06 collectible authoring**
