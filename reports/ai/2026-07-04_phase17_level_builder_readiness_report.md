# 2026-07-04 - Phase 17 + Level-Builder Readiness

## Goal

Implement Phase 17 in grouped-milestone mode: safely activate Phase 16 Taco garage-manager routes through QA/debug controls, improve route/result readability, add Mission Dock/audit support, create a reusable new-mission starter/template proof, and add one small non-Taco mission skeleton using multiple reusable systems.

## Mode

Stayed in accelerated grouped-milestone mode. The packet combined Taco QA route activation, debug/result summaries, Mission Dock audit support, reusable starter template, non-Taco integrated proof scene, focused tests, static validator, docs, report, and validation.

## Files Changed

- `src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd`
- `src/missions/iso/runtime/MissionQAChecklistPanel.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/ui/MissionResult.gd`
- `addons/mission_dock/MissionDock.gd`
- `src/missions/iso/dev/Phase17LevelBuilderProofHarness.gd`
- `scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn`
- `scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn`
- `tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd`
- `src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py`
- `docs/reports/phase17_level_builder_readiness/phase17_level_builder_readiness_validation.json`
- `docs/CHANGELOG.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `reports/ai/2026-07-04_phase17_level_builder_readiness_report.md`

## Implementation Notes

- Added F12 checklist mode `Phase 17 - Garage Routes` with QA-only buttons for clean social, Bentley distraction, evidence, messy authority, and cleanup/redirect routes.
- F12 calls the existing `Phase16GarageDeniabilityDevTrigger` methods directly. No Area2D, player interaction scanner, input listener, or legacy candidate path was added.
- Extended `Phase16GarageManagerDeniabilityController.get_summary()` with `phase16`, `last_route_id`, `last_route_label`, and `route_log` so result/debug adapters can display the selected route.
- Added `phase17_route` to F10 compact/details debug output and a route line to `MissionResult` encounter summaries.
- Added Mission Dock read-only readiness audit coverage for Phase 16/17 helper scripts, `MissionInteractionBridge.include_legacy_candidates`, and key reusable mechanic mixes.
- Added `NewMissionStarterTemplate.tscn` with `RuntimeHelpers`, a scoped `MissionInteractionBridge`, `MissionMechanics`, sample search/reward/route mechanics, and a dormant encounter controller.
- Added `Phase17LevelBuilderReadinessProofRoom.tscn` and `Phase17LevelBuilderProofHarness.gd`, proving one non-Taco skeleton that uses social stealth, paper trail, reactive NPC, encounter, and noise systems together.

## Validation

- PASS: `python src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py` (`53 checks`).
- PASS: `python src/tools/editor/phase16_taco_garage_deniability/phase16_taco_garage_deniability_validator.py` (`43 checks`).
- PASS with known noise: focused GdUnit `res://tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd` (`5/5`, report `reports/report_45/`). Known noise: remote debugger port `127.0.0.1:0`, controller mapping warnings, MCP port `9090` already bound.
- PASS with known noise: focused GdUnit `res://tests/mission_authoring/Phase16TacoGarageDeniabilityTest.gd` (`5/5`, report `reports/report_46/`). Known noise: same Godot/MCP startup warnings.
- PASS with known noise: headless smoke loaded `res://scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn`. Known noise: controller mapping warnings and MCP port `9090` already bound.
- PASS with known noise: headless smoke loaded `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`, started `taco_bell_drop`, and loaded Phase 16/17-relevant scripts. Known noise: controller mapping warnings, MCP port `9090` already bound, and forced-quit leak/orphan warnings consistent with prior Taco headless smoke.
- PASS with known noise: full GdUnit `res://tests/mission_authoring` (`300/300`, report `reports/report_47/`). Known noise: remote debugger port `127.0.0.1:0`, controller mapping warnings, MCP port `9090` already bound.

## Manual QA Checklist

1. Launch `taco_bell_drop` through the normal hideout mission flow.
2. Confirm canonical bag pickup, code/manifest clue, garage gate, Louis return, and mission completion still work.
3. Open F12, choose `Phase 17 - Garage Routes`, and press each route button: Clean Social, Bentley, Evidence, Messy, Cleanup.
4. Confirm F12 route log updates and F10 shows `phase17_route=<route>` with call count.
5. Complete/fail the mission after a route call and confirm the Mission Result encounter section shows the selected route label.
6. In the editor, open Mission Dock Assist Browser on Taco and confirm the bridge remains `include_legacy_candidates=false` and the Phase 16/17 readiness info is read-only.
7. Open `Phase17LevelBuilderReadinessProofRoom.tscn`, run `Run Integrated Proof`, and confirm the status label reports social/paper/reactive/encounter/noise summaries.

## Manual QA Signoff

- 2026-07-04 Jake confirmed the canonical Taco bag/code/Louis flow passed after Phase 16/17.
- Jake confirmed each Phase 17 route label mapped correctly in the mission result screen after the scrollbar follow-up.
- Paper trail, social stealth, encounter challenge, and reactive NPC summaries changed per route as expected.
- Outcome: player-facing Taco garage route activation is cleared for the next grouped packet, while Phase 17 itself remains QA/debug-only.

## Risks / Follow-Ups

- Normal player-facing Taco route activation remains intentionally outside Phase 17 and should be implemented in the next grouped packet now that Jake manually QA-confirmed canonical Taco bag/code/Louis flow after Phase 16/17.
- The non-Taco proof scene is a skeleton/readiness proof, not a full story mission or final level template.
- Mission Dock readiness audit is read-only; it does not yet auto-place a full mission skeleton or generate Resources.
- The broader visual authoring palette/editor UX and full next-level assembly pass remain future packets.
