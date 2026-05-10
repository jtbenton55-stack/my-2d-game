# PHASE 0M-D1B — Pre–Taco Bell module hardening (final)

## Verdict: **PARTIAL**

All requested seams were implemented in code and documented under `docs/reports/pre_taco_module_hardening/`. **Godot editor/runtime playtest was not executed** in the automation environment (Godot not on PATH).

## Summary

| Area | Result |
|------|--------|
| Canonical Taco scene | `TacoBellIso_Editable.tscn` |
| Dialogue boundary | `IsoMissionBase` no longer preloads `TacoBellDialogue`; taco missions use `TacoBellDialogueProvider` |
| Tool surface | `MissionToolSurfaceHelper` + `IsoMissionBase.handle_tool_use` |
| Objectives | `MissionObjectiveBridge` wraps `QuestManager.set_objective` from Iso |
| Stamina | `PlayerStaminaController` + minimal `Player.gd` wiring; `sprint` input optional |
| Attempt reset | Documented + `reset_mission_runtime_for_new_attempt()` |

## Quick revert

Revert `IsoMissionBase.gd`, `Player.gd`, and remove new `src/missions/dialogue`, `taco_bell`, `tools`, `objectives` files and test scene if needed.

## Reports

All paths: `docs/reports/pre_taco_module_hardening/`.
