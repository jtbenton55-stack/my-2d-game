# D6-04B Implementation Report

## Summary

Fixed authored camera parity with `CAM_market_01` / Phase0K cameras and repaired authored guard infinite chase + screen-sized debug cone.

## Camera parity

**Parity target:** `CAM_market_01` at `GameplayRoot/MarkerRoot/EditorOnlyPlaceholders/CAM_market_01` (marker). Runtime cameras are spawned by `Phase0KCameraSpawner` into `EntityRoot/Cameras` using `MissionSecurityCamera.gd`.

**Root cause:** `SecurityCameraAuthor` created `MissionSecurityCamera` under `AuthoredSecurityCameras`, set world pose before parenting, and used `script.new()` instead of the Phase0K `Area2D + set_script` pattern.

**Fix:**
- Parent authored runtime cameras under `EntityRoot/Cameras` (same as Phase0K).
- `Area2D` + `set_script(MissionSecurityCamera)` + `add_child` then `global_position` / `global_rotation`.
- Shared `MissionSecurityCamera.apply_authoring_config()` + `_sync_initial_overlaps()` for detection shape and player overlap.

## Guard chase / perception

**Root cause:** D6-04 set `authoring_force_chase` with unconditional chase in `_update_ai` and `aggro_range = maxf(aggro_range, 2400.0)`, inflating debug vision cone via `EnemyBase._draw`.

**Fix:**
- Removed 2400 aggro bump; debug cone capped at 140px via `authoring_debug_cone_range` meta.
- Limited chase: 480px max distance, 14s timeout, then `_enter_authoring_fallback()`.
- `IsoMissionBase` builds `search_net` payload when fallback is `security_net`.
- `AmbushGuardSpawn_Author` explicitly uses `fallback_behavior = security_net`.

## Files changed

- `src/missions/iso/runtime/MissionSecurityCamera.gd`
- `src/missions/iso/authoring/SecurityCameraAuthor.gd`
- `src/enemies/Guard.gd`
- `src/enemies/EnemyBase.gd` (debug draw only)
- `src/levels/IsoMissionBase.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/tools/editor/d6_04b_camera_parity_guard_chase_fix/phase0md6_04b_static_validator.py`

## Kimi

Not used (audit + MCP validation sufficient).
