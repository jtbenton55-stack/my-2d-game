# 0M-D5-02B-FIX3 — HUD / debug snapshot non-regression

## Checks (static)

1. `get_sprint_runtime_debug()` / stamina chain still exposes `current_stamina`, `max_stamina` via `get_stamina_snapshot` merge — unchanged.
2. After Ctrl release, `is_sprint_active` in debug reflects `_sprinting` from controller — unchanged wiring.
3. `HUD.gd` still calls `MissionHudDataProvider.get_hud_payload`, updates `SprintStaminaBar`, `PoopBagLabel`, objective label path unchanged.
4. No edits to `HUD.gd` or `MissionHudDataProvider.gd` in this pass.

## Assertions

| Assertion | Value |
|-----------|--------|
| hud_stamina_read_path_preserved | true |
| objective_ticker_preserved | true |
| poop_count_preserved | true |
| f10_f1_f11_pause_not_intentionally_changed | true |
