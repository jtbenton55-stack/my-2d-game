# 2026-07-04 - Phase 18 Taco Player-Facing Garage Route Actions

## Goal

Implement the next grouped packet after Jake's Phase 17 manual QA signoff: normal player-facing Taco garage-manager deniability route activation, route locking/gating, result/rating-lite readability, Mission Dock audit support, tests, validators, docs, and a manual QA checklist while preserving Phase0J/Phase0K authority.

## Mode

Stayed in accelerated grouped-milestone mode. The packet combined a reusable authored mechanic, Taco production scene wiring, MissionResult readability, Mission Dock audit support, focused GdUnit, static validators, scene smoke, roadmap/blueprint/changelog updates, and this report.

## Files Changed

- `src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd`
- `src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd`
- `src/ui/MissionResult.gd`
- `addons/mission_dock/MissionDock.gd`
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `tests/mission_authoring/Phase18TacoPlayerRouteActionTest.gd`
- `src/tools/editor/phase18_taco_player_routes/phase18_taco_player_routes_validator.py`
- `docs/reports/phase18_taco_player_routes/phase18_taco_player_routes_validation.json`
- `docs/CHANGELOG.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-07-04_phase18_taco_player_route_actions_report.md`

## Implementation Notes

- Added `EncounterRouteActionNode`, a reusable `MechanicAreaBase` subclass for authored player-facing encounter route choices.
- The route node allowlists Phase 16 route methods, checks normal mechanic requirements, gates on an optional completed objective or mission flag, calls the encounter controller, applies success/failure EffectSets, and records route choice/style mission flags.
- Placed four normal Taco route actions under `GameplayRoot/PlugAndPlayPilot/Phase18GarageRouteActions`: Clean Social, Bentley Distraction, Evidence Chain, and Messy Authority Report.
- All Taco route actions gate on completed objective `open_garage_code_gate` and lock competing choices through `phase18_garage_route_selected`.
- Reused the existing `MissionInteractionBridge` plug-and-play scan path. `include_legacy_candidates = false` remains unchanged, so Phase0J/Phase0K legacy candidates are not pulled into the plug-and-play bridge.
- Extended `Phase16GarageManagerDeniabilityController` route summaries with `last_route_style_label` and per-route `route_style_label` values.
- Extended `MissionResult` encounter output with a `Style:` line when route style data exists.
- Added Mission Dock awareness for `EncounterRouteActionNode`, including read-only audit warnings for missing route ids/methods/controller paths and an info item for Phase 18 route actions.

## Post-Manual-QA Interaction Fix

- Manual QA showed that pressing `E` near the Phase 18 route lane appeared to do nothing and Phase0J scent-marker interaction could still receive the input.
- Root cause: Taco's code gate updates `Phase0KMissionCompletionController.code_gate_unlocked`, while the initial Phase 18 scene wiring gated routes on `QuestManager` objective completion through `MissionFactBridge.objective_completed`.
- `EncounterRouteActionNode` now supports an optional exported controller bool gate for scene-authored state such as `code_gate_unlocked`, while preserving completed-objective and mission-flag gates for reusable missions.
- Taco route actions now gate on `GameplayRoot/RuntimeHelpers/Phase0KMissionCompletionController.code_gate_unlocked`, add explicit route method/id/label wiring, and fix the Messy Authority controller path.
- `MissionInteractionBridge` now surfaces locked/unavailable candidate prompt text instead of silently clearing the prompt when no available candidate is found.
- `Phase0JInteractionBridge` now defers `E` input while the player is standing near a `phase18_garage_route_action`, preventing nearby Phase0J debug/scent markers from stealing route input.
- Added `Phase18GarageRoutePrompt` and wired it through `MissionInteractionBridge.prompt_target_path` for visible locked/selected route feedback.

## Validation

- PASS: `python src/tools/editor/phase18_taco_player_routes/phase18_taco_player_routes_validator.py` (`40 checks`).
- PASS: `python src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py` (`53 checks`).
- PASS: `python src/tools/editor/phase16_taco_garage_deniability/phase16_taco_garage_deniability_validator.py` (`43 checks`).
- PASS: `addons\gdUnit4\runtest.cmd --godot_binary "$env:GODOT_BIN" -a "res://tests/mission_authoring/Phase18TacoPlayerRouteActionTest.gd"` (`5/5`, report `reports/report_50/`).
- PASS: focused Phase 16 GdUnit regression (`5/5`).
- PASS: focused Phase 17 GdUnit regression (`5/5`).
- PASS with known noise: Taco headless smoke loaded `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`, started `taco_bell_drop`, and loaded `EncounterRouteActionNode.gd` plus the Phase 16 route scripts. Known noise remains controller mapping `misc2`, MCP port binding when concurrent, and forced-quit leak/orphan warnings consistent with prior Taco headless smokes.
- PASS: `git diff --check`.

## Post-Fix Validation

- PASS: `python src/tools/editor/phase18_taco_player_routes/phase18_taco_player_routes_validator.py` (`44 checks`).
- PASS: `python src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py` (`53 checks`).
- PASS: `python src/tools/editor/phase16_taco_garage_deniability/phase16_taco_garage_deniability_validator.py` (`43 checks`).
- PASS: `git diff --check`.
- BLOCKED: focused GdUnit and Taco headless scene smoke could not be rerun in this OpenCode environment because `GODOT_BIN` is not set and no Godot executable was found under the repo or approved `tools` path. Prior pre-fix Phase 18 focused GdUnit was `5/5`, but Jake should rerun GdUnit/runtime QA after this interaction fix.

## Manual QA Checklist

1. Launch `taco_bell_drop` through the normal hideout mission flow.
2. Confirm canonical bag pickup, code/manifest clue, garage gate, Louis return, and mission completion still work.
3. Before opening the garage code gate, walk to the Phase 18 route-choice lane and confirm route prompts are locked with the garage-code message.
4. Open the garage code gate, then confirm the Clean Social, Bentley Distraction, Evidence Chain, and Messy Authority route prompts are player-facing interactables.
5. Choose one route and confirm the other route choices report that a garage route was already selected.
6. Complete or fail the mission and confirm Mission Result shows Encounter Challenge `Route:` and `Style:` lines.
7. Repeat on a fresh Taco attempt for each route and confirm paper trail, social stealth, encounter, and reactive NPC summaries match the selected route.
8. In Mission Dock Assist Browser, audit the Taco scene and confirm `EncounterRouteActionNode` is reported while `MissionInteractionBridge.include_legacy_candidates=false` remains safe.

## Risks / Follow-Ups

- Manual playable QA is still required because headless smoke proves scene/script loading, not route prompt feel or player positioning.
- The route actions are currently placed in the plug-and-play pilot lane for safe validation. Final level layout may want route markers moved closer to the garage code area once Jake confirms interaction flow.
- The route model remains bounded to Phase 16 consequences; it is not a full NPC belief/faction simulation.
- GdUnit generated untracked `reports/report_48` through `reports/report_51`; tracked historical report folders pruned by GdUnit were restored.
