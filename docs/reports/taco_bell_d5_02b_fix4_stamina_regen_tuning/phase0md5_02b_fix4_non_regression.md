# 0M-D5-02B-FIX4 — HUD / input non-regression (static)

- `get_sprint_runtime_debug()` / stamina snapshot fields unchanged in contract.
- `HUD.gd`, `MissionHudDataProvider.gd`, `Player.gd`, `project.godot`, Taco scenes, `player.tscn`, `assets/**` — **not modified** this pass.
- Ctrl sprint and Space dash wiring unchanged (no `Player.gd` edits).

## Assertions

| Assertion | Value |
|-----------|--------|
| hud_stamina_path_preserved | true |
| objective_ticker_preserved | true |
| poop_bag_count_preserved | true |
| ctrl_sprint_space_dash_preserved_static | true |
