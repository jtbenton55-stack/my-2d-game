# Objective ownership (0M-D1B)

## Model

| Concern | Owner |
|--------|--------|
| HUD / pause primary text | `QuestManager` via `MissionObjectiveBridge.publish_primary_objective` |
| Exit gating / required IDs | `IsoMissionBase` internal dictionaries |

`MissionObjectiveBridge.get_objective_snapshot()` documents the split for future missions.

Pause menu continues to read `QuestManager.get_active_objectives(GameState.current_mission_id)` — unchanged.
