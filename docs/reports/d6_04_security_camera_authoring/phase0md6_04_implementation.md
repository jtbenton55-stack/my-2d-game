# PHASE 0M-D6-04 — Implementation Notes

## Part A — Event response hardening
- `SecurityEventRouter.emit_event()` returns structured dispatch result with registered/called/handled/rejected counts, reasons, and successful listener paths.
- `get_last_dispatch_result()` and `get_debug_summary()` expose last dispatch for F10.
- `GuardSpawnAuthor.on_security_event()` returns structured handled/rejected results with explicit rejection reason codes.

## Part B — Guard post-spawn behavior
- `Guard._update_ai()` honors `authoring_force_chase` for `attack_player` spawns so guards pursue beyond default aggro/LOS.
- Expanded aggro range when force-chasing.
- Behavior/fallback metadata stored on guard for F10.

## Part C — SecurityCameraAuthor runtime
- Full authoring fields (range, FOV, sweep, detection, events).
- Editor cone/sweep preview.
- `setup_runtime_camera()` builds `MissionSecurityCamera` under `AuthoredSecurityCameras`.
- `IsoMissionBase._bind_authored_security_camera()` connects `player_detected` to router alarm/detect events.
- Direct camera guard spawn suppressed when alarm event has responding listeners.

## Taco proof nodes
- `TestCamera_Author` → `test_camera_alarm`
- `CameraAlarmGuardSpawn_Author` listens and spawns with `attack_player`
- `AmbushGuardSpawn_Author` fallback set to `security_net`
