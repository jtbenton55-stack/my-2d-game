# Runtime validation (D6-01)

**Result:** **PARTIAL** — Godot headless / GRB not executed in this Cursor session.

**Static confidence:** GDScript edits lint-clean; wiring follows existing call graphs.

**Manual follow-up:** Launch editor, Taco from MissionBoard, trip beam / wrong code / camera, open F10, verify adapter counters and no spam; fail mission once and confirm `mission_failure_heat` increments while mid-run alarms do not bump `failed_attempts` alone.
