# Phase 3 — Stamina fix

## Code

- **`MissionHudDataProvider.get_hud_payload`**: Treat sprint data as valid when `dbg.ok` **or** both `current_stamina` and `max_stamina` exist (fixes missing `ok` after Player merges dict). In-mission **placeholder** `100/100` when player or snapshot unavailable; `stamina_fallback` flag + warning strings.
- **`HUD.gd`**: When `stamina_fallback`, set a short **tooltip** on the bar (no raw debug dump).
- **`hud.tscn`**: `StyleBoxFlat` background + fill on `SprintStaminaBar`, `custom_minimum_size` **160×12**.

## Non-goals

No `Player.gd`, `PlayerStaminaController.gd`, `project.godot`, Taco scenes.

## Assertions

See `phase0md5_02b_fix2_stamina_fix.json`.
