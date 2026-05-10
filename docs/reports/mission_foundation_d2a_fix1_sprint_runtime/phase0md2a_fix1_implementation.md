# 0M-D2A-FIX1 — Implementation

- **`project.godot`:** `sprint` = **Ctrl only** (`physical_keycode` 4194326). **Space remains on `dodge` only.**
- **`PlayerStaminaController.gd`:** `is_sprint_requested()` also checks `Input.is_physical_key_pressed(KEY_CTRL)`; added `is_sprint_active()`, `get_debug_snapshot()`.
- **`Player.gd`:** `sprint_mult` from `get_speed_multiplier()` only when `is_sprint_active()` after `process_frame`; added `get_sprint_runtime_debug()` for harness.
- **`pause_menu.gd`:** Controls copy updated.
- **Harness:** `PlayerSprintRuntimeTest_0MD2A_FIX1.tscn`
- **Validator:** `phase0md2a_fix1_sprint_runtime_validator.py`
