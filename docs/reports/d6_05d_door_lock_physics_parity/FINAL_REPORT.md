# D6-05D — Final Report

## 1. Goal — **PASS**

Cyan zone lock, lime zone unlock, and camera alarm now share the same physical lock API. Zone lock enables collision (layer 4 + shape enabled), not color-only.

## 2. Files changed

- `src/missions/iso/authoring/D6_05A_TestDoorLockTarget.gd`
- `src/missions/iso/authoring/DoorLockEffectAuthor.gd`
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/tools/editor/d6_05d_door_lock_physics_parity/phase0md6_05d_static_validator.py`
- `docs/reports/d6_05d_door_lock_physics_parity/*`

**Protected:** `project.godot`, `Player.gd`, `player.tscn`, real garage gate.

## 3. Root cause

Zone events reached `DoorLockEffectAuthor` and updated visuals (`_locked`, red `ColorRect`/`_draw`), but physics parity was not enforced. Success was reported without confirming `CollisionShape2D` enabled + walls layer on. Camera alarm often appeared to work due to timing; zone entry exposed visual-only updates.

## 4. Fix

- **`apply_locked_state(locked)`** on proof door — one path for visual + collision.
- **DoorLockEffectAuthor** verifies `collision_enabled` matches requested lock; rejects on mismatch.
- **Group resolve** `d6_05a_test_door_lock` for proof targeting.
- **F10** visual vs physics + mismatch warnings.

## 5. Manual test

1. Taco scene → proof door ~**(7974, 271)** (may be rotated, e.g. 270°).
2. **Cyan LOCK ZONE:** door **red**, **cannot pass**, F10 `Collision: enabled=YES layer=4`.
3. **Lime UNLOCK ZONE:** door **green**, **can pass**, F10 `enabled=NO layer=0`.
4. **Camera alarm:** same as cyan lock (red + blocks).
5. **Rotation:** rotate door in editor (15° snap); repeat lock/unlock — collision should still toggle.

## 6. Validation

- Static validator: PASS
- MCP: zone/camera lock `collision_enabled: true`; unlock clears; rotation lock OK
- LSP: clean

## 7. Safety

- Repo-only; no git history ops; garage gate untouched.

## 8. Next step

**D6-06 collectible authoring** (after Jake confirms one manual playtest).
