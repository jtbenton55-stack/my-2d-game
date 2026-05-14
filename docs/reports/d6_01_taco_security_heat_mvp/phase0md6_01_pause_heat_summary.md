# Pause heat / security summary

- **`MissionPauseDataProvider.get_heat_security_pause_line`** — single plain-English sentence, no internal IDs.
- **`pause_menu.gd`** `_objectives_text` prepends the line above **Active Objectives** when `current_mission_id` resolves.
- **`get_pause_payload`** includes optional `heat_security_line` key for future consumers.
- **Scrollability:** unchanged `ScrollContainer` + `RichTextLabel` pause info path.
