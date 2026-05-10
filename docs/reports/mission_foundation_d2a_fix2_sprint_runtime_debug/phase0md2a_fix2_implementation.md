# 0M-D2A-FIX2 — Implementation summary

## Runtime fix (smallest link)

1. **`project.godot`** (after backup): `sprint` Ctrl event now sets **`keycode` 4194326** alongside `physical_keycode` 4194326; second **`C`** key (`physical_keycode` 67) documented fallback on same action.
2. **`PlayerStaminaController.gd`**: `is_sprint_requested()` now treats `get_action_strength("sprint") > 0.01` and `Input.is_key_pressed(KEY_CTRL)` as sprint. `get_sprint_signal_chain_debug()` merges stamina + chain for HUD.
3. **`Player.gd`**: Per-frame `_sprint_physics_debug_last` (base/final move speed, mult, wants_sprint, suppression reason, velocity pre/post slide); `get_sprint_runtime_debug()` merges controller + combat + dodge timer + stealth; debug overlay spawned in `_ready` for debug/editor builds.
4. **Space dodge:** unchanged logic and `dodge` map still Space-only for keyboard.

## Not done

- No `player.tscn`, Taco scenes, or HideoutHub edits.
- No run animation requirement.

See `phase0md2a_fix2_implementation.json`.
