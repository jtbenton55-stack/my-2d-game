# Security source wiring

| Source | Wired | Notes |
|--------|-------|-------|
| `MissionAlertController.record_alarm_event` | Yes | Maps to `camera_detection`, `guard_detection`, `beam_trip`, `wrong_code_alarm`, generic `alarm`. |
| Garage beam (`alarm_zone` + garage id) | Yes | Via existing `register_detection_event` path. |
| Wrong code (placeholder) | Yes | `wrong_code` each attempt; threshold alarm via `register_detection_event`. |
| Phase0J / Phase0KB | Yes | `wrong_code` + `reinforcement_spawned`. |
| Mission failure heat | Yes | `GameState.fail_mission` → `mission_failure_heat` event. |
| IsoMissionBase broad refactor | No | Intentionally avoided per pass rules. |
