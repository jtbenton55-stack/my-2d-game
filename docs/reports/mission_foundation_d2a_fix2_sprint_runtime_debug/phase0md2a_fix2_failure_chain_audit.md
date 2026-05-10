# 0M-D2A-FIX2 — Forensic sprint signal chain audit

## Code paths reviewed

- `project.godot` `sprint` / `dodge` InputMap events.
- `PlayerStaminaController.gd`: `is_sprint_requested`, `process_frame`, `is_sprint_active`, `get_speed_multiplier`, `get_debug_snapshot`, `get_sprint_signal_chain_debug`.
- `Player.gd` `_physics_process`: stealth/dash/dodge gating → `wants_sprint` → `process_frame` → `is_sprint_active` → single `move_speed *= sprint_mult` → velocity assignment → `move_and_slide`.

## Chain table (automated agent run)

| Link | Status | Evidence |
| --- | --- | --- |
| 1. Ctrl physically pressed | NOT TESTED | GRB not connected; runtime overlay exposes values. |
| 2. `sprint` action pressed | NOT TESTED | FIX2 adds keycode on Ctrl + C binding + `get_action_strength` > 0.01. |
| 3. `is_sprint_requested()` true | NOT TESTED | Live dict key in overlay. |
| 4. `is_sprint_active()` true | NOT TESTED | Requires movement + stamina + no stealth/dash/dodge gate. |
| 5. Speed multiplier > 1.0 | NOT TESTED | `get_speed_multiplier` when `_sprinting` and `can_sprint()`. |
| 6. Multiplier applied to final velocity | TRUE | Single `move_speed *= sprint_mult` then `velocity = input_vector * move_speed` (non-dodge). |
| 7. Actual velocity increases | NOT TESTED | Compare `velocity_length_post_slide` with/without sprint in-game. |

## Root cause (FIX2 hypothesis)

FIX1 used `sprint` with `keycode` 0 and Ctrl `physical_keycode` only. On Windows/Godot, modifier-only actions often fail `is_action_pressed` / strength unless `keycode` matches layout or a non-modifier duplicate exists. **Smallest fix:** set Ctrl `keycode` 4194326, add **C** fallback on `sprint`, and poll `Input.is_key_pressed(KEY_CTRL)` plus `get_action_strength("sprint")`.

## Exact failed link (pre-fix)

**Link 2 / 3 (input → request):** sprint action and/or raw Ctrl not registering reliably into `is_sprint_requested()` (supported by user symptom: Ctrl dead, movement OK). Overlay confirms which link fails in your build.
