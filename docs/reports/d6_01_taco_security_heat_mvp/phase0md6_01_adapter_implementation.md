# MissionSecurityEventAdapter implementation

- **Path:** `src/missions/iso/runtime/MissionSecurityEventAdapter.gd`
- **Type:** `class_name` + `extends Node` (child of `MissionAlertController`, **not** autoload).
- **API:** `setup`, `report_security_event`, `reset_attempt_security_state`, `get_security_debug_snapshot`, `get_pause_security_summary`, signal `security_event_reported`.
- **Dedupe:** Same `Engine.get_process_frames()` frame + `kind|source_id` coalesces duplicates.
- **Log:** Last 12 events for F10.
- **Heat:** Comments + snapshot note — adapter never writes `failed_attempts`.
