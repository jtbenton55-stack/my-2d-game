# 0M-D2 — Sprint input wiring

- **`project.godot`:** added **`sprint`** action only (keyboard Ctrl, `physical_keycode` **4194324**). **Shift** remains on **`stealth`** — documented to avoid conflict.
- **Backup:** `docs/reports/mission_foundation_d2/backups/project.phase0md2_input_backup.20260509190000.godot`.
- **PlayerStaminaController / Player.gd:** existing D1B wiring uses `sprint_action_name` default `"sprint"` and `Input.is_action_pressed` when the action exists.

See `phase0md2_sprint_input_wiring.json`.
