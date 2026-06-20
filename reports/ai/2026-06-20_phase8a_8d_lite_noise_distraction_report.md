# Phase 8A-8D-lite Noise And Distraction Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented and validated

## Goal

Create the first reusable noise/distraction packet after Bentley command points: structured noise events, placed noise emitters, Bentley bark noise emission, and a lightweight distraction object without creating a global noise manager or production Taco dependency.

## Files Changed

- `src/missions/iso/runtime/noise/NoiseEvent.gd`
- `src/missions/iso/runtime/noise/NoiseEmitterNode.gd`
- `src/missions/iso/authoring/mechanics/DistractionObject.gd`
- `src/utils/EventBus.gd`
- `src/missions/iso/runtime/MissionAlertController.gd`
- `src/player/DogCompanion.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `addons/mission_dock/MissionDock.gd`
- `scenes/missions/iso/authoring/NoiseEmitterNodeTemplate.tscn`
- `scenes/missions/iso/authoring/DistractionObjectTemplate.tscn`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/NoiseDistractionTest.gd`
- `tests/mission_authoring/NoiseDistractionTest.gd.uid`
- `src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py`
- `docs/reports/phase8_noise_distraction/phase8_noise_distraction_validator_run.json`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase8a_8d_lite_noise_distraction_report.md`

## Implementation Summary

- Phase 8A-lite: added `NoiseEvent` as the shared dictionary schema/helper for mission-local noise events.
- Phase 8B-lite: added `NoiseEmitterNode`, a `MechanicAreaBase`-based placed emitter that applies normal requirements/effects and then emits/routes a noise event.
- Phase 8C-lite: connected Bentley bark to the same noise event path via `DogCompanion` and `EventBus.mission_noise_emitted`.
- Phase 8D-lite: added `DistractionObject` as a player-team decoy/noise emitter subclass with Mission Dock defaults and an authoring template.
- Extended `MissionAlertController` with recent-noise recording and a lightweight suspicious-state response for player-team noise; no global noise manager was added.
- Added compact F10 debug output through `IsoMissionDebugPanel`, dev-room proof nodes, focused tests, static validator coverage, and docs.

## Protected Scope

- No production Taco scene changes.
- No full guard listener/pathing AI.
- No new global noise autoload or broad stealth rewrite.
- No persisted noise state or mission-result scoring yet.

## Validation

- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/NoiseDistractionTest.gd"` passed `6/6`.
- `python src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `215/215`.
- `.\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded the dev proof scene and exited cleanly.
- `git diff --check` passed.
- Jake manual QA passed: Mission Dock placement exposed `NoiseEmitterNode` and `DistractionObject`, `NoiseEmitterNode` placement worked, the exported `Noise` foldout in the Inspector showed the expected noise fields, and `DistractionObject` placement worked.

## Risks / Follow-Ups

- The Phase 8-lite listener response is intentionally simple: `MissionAlertController` records noise and can mark player-team noise suspicious, but guards do not path toward noise yet.
- Production mission placement remains deferred until a mission needs authored distraction/noise content.
- Later Phase 8 work should add a guard/NPC listener component or security-router adapter only after this event contract is stable.
