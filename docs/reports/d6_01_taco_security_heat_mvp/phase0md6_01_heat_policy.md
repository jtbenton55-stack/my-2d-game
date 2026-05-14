# Heat policy (D6-01)

- **Persistent heat:** `GameState.get_mission_heat` = `min(5, failed_attempts[mission_id])`.
- **Increment:** Only **`GameState.fail_mission`** bumps `failed_attempts` in audited path (no new save keys).
- **Mid-run alarms:** Camera/guard/beam/wrong-code **do not** increment `failed_attempts` in this pass.
- **Helper:** `GameState.get_mission_heat_summary(mission_id)` read-only dict for UI/debug deduplication.
