# D6-05C — Door Zone Trigger Fix + Rotatable Test Door — Implementation Report

**Date:** 2026-05-17  
**Status:** PASS

## Root cause (zone triggers)

`SecurityAuthoringRoot.collect_area_trigger_authors()` only scanned **direct children**. Lock/unlock zones live under `TestDoorLockProof/`, so **no runtime `Area2D` was created** and `body_entered` never fired.

## Fixes

### Part A — Zone triggers

- `SecurityAuthoringRoot`: deep recursive collection for any node with `setup_runtime_trigger` + `on_enter_event`.
- `AreaTriggerAuthor`: hardened runtime `Area2D` setup (shape always present/enabled, `collision_mask = 1` for player layer, `body_entered` always connected, sync global transform).
- `zone_display_name` export for clear labels (`LOCK ZONE` / `UNLOCK ZONE`).
- `IsoMissionBase.record_d6_05c_zone_trigger()` for F10 last-zone fields.
- Taco scene: larger zones (128×96), walk-in labels.

### Part B — Rotatable door

- `D6_05A_TestDoorLockTarget.gd`: `snap_rotation_to_15_degrees`, `rotation_snap_degrees`, `orientation_degrees` export; editor `_process` snaps gizmo rotation; parent rotation rotates collision + visual children; label counter-rotated for readability.

### Part C — F10

- D6-05C section: rotation degrees, last zone id/event, updated instructions.

## Unchanged

- Camera alarm locks door.
- AMBUSH does not unlock door.
- Real `GATE_garage_code` untouched.
