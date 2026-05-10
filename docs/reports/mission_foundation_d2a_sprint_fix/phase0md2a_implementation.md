# 0M-D2A — Implementation

1. **`project.godot`:** `sprint` events = Space (`32`) + Ctrl (`4194326`). Removed erroneous PageDown (`4194324`) entry.
2. **`PlayerStaminaController.gd`:** `is_sprint_requested()`, `alternate_sprint_action_names` (default empty), snapshot includes alternates.
3. **`Player.gd`:** `wants_sprint` uses `is_sprint_requested()`, drops `(not combat_on)` gate; adds `dash_active` / `legacy_dodge_burst` guards; still one `move_speed *= sprint_mult`.
4. **`pause_menu.gd`:** Controls blurb updated for sprint vs dash.
5. **Harness:** `PlayerSprintInputTest_0MD2A.tscn` + `.gd`.
6. **Validator:** `src/tools/editor/mission_foundation_d2a_sprint_fix/phase0md2a_sprint_static_validator.py`.
