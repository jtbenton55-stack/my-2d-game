# Phase 1 — HUD / data audit

- **HUD instantiation:** `LevelBase.gd` (and `Hideout.gd`, `CityHub.gd`) preload `res://scenes/ui/hud.tscn` and `add_child`. Taco iso uses same HUD scene.
- **Existing HUD:** Health/Bentley/Style/Detection bars top-left; `ObjectiveLabel` top-center (was unbounded width); `EventBus.objective_updated` drives objective text from `QuestManager`.
- **Objective source:** `QuestManager.get_current_objective(mission_id)` — player-facing strings when missions call `set_objective` / `add_objective`.
- **Stamina:** `Player` exposes `get_sprint_runtime_debug()` → includes `current_stamina` / `max_stamina` from `PlayerStaminaController` (read-only access, no Player edits).
- **Poop bags:** `GameState.get_poop_bag_count()` / `poop_bag_inventory` — player-facing “bags held.”
- **Health bar overlap:** New `MissionHudStrip` anchored **top-right** (`offset_left -200 … -10`) so it does not sit over left-side health cluster.
