# Phase 4 — Pause data fix

- Added `MissionAutoloadResolver.gd` for `/root` autoload resolution.
- Replaced `Engine.has_singleton("GameState")` in `MissionClueBridge`, `MissionSchemeBridge` (via resolver), and `MissionPauseDataProvider._effective_mission_id`.
- Pause warnings for normal Taco play should clear; residual infrastructure issues surface as `CardManager unavailable` / `GameState unavailable` only if autoloads are genuinely missing.
- Pause UI copy: `(warn)` → `Note:` for non-empty warning strings.
