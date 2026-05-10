# 0M-D2A — Sprint design decision

| Decision | Choice |
|----------|--------|
| Canonical action | `sprint` |
| Space | Bound on **`sprint`** (same physical key as `dodge`; Godot allows shared keys across actions). |
| Ctrl | Bound on **`sprint`** using **`physical_keycode` 4194326** (`KEY_CTRL`). |
| `dodge` | Unchanged — Space still triggers dash/dodge semantics via `dodge`. |
| Stamina source of truth | `PlayerStaminaController.is_sprint_requested()` + `process_frame` / `get_speed_multiplier()` |
| Combat | Stamina sprint allowed when moving; **suppressed** while `is_dashing()` or legacy `dodge_timer` burst so dash is not multiplied by sprint. |
| Run animation | Not used for sprint. |
