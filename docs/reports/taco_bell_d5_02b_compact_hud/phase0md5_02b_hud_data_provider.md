# Phase 3 — MissionHudDataProvider

Created `res://src/missions/ui/MissionHudDataProvider.gd`:

- Read-only static helpers; no mutations.
- `sanitize_objective_line` caps length and empty-state copy.
- `get_hud_payload` reads `QuestManager`, `GameState`, and `player` group + `get_sprint_runtime_debug()`.
- `warnings` reserved for future internal diagnostics (not shown on HUD).
