# 0M-D2 — Mission pause data shell

- **`MissionPauseDataProvider.gd`:** builds `get_pause_payload` with keys `ok`, `mission_id`, `objectives`, `scheme_cards`, `clues`, `warnings`. Delegates to `MissionObjectiveBridge`, `MissionSchemeBridge`, `MissionClueBridge`.
- **`pause_menu.gd`:** objectives/clues text sourced via provider; scheme tab uses provider equipped rows + `MissionSchemeBridge.get_scheme_snapshot` for unlocked id list (no duplicate pause menu scene).

See `phase0md2_mission_pause_data_shell.json`.
