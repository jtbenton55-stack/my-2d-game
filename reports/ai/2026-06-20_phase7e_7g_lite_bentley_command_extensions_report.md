# Phase 7E-7G-lite Bentley Command Extensions Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented and validated

## Goal

Finish the lightweight Phase 7 companion packet by adding crawlspace/wait authored command points and centralized card-specific Bentley command tuning without creating a new companion manager or production mission dependency.

## Files Changed

- `src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd`
- `src/missions/iso/authoring/mechanics/BentleyCrawlspaceConnector.gd`
- `src/missions/iso/authoring/mechanics/BentleyWaitMarker.gd`
- `src/player/DogCompanion.gd`
- `src/autoload/CardEffects.gd`
- `addons/mission_dock/MissionDock.gd`
- `scenes/missions/iso/authoring/BentleyCrawlspaceConnectorTemplate.tscn`
- `scenes/missions/iso/authoring/BentleyWaitMarkerTemplate.tscn`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/CompanionCommandPointTest.gd`
- `src/tools/editor/phase7_bentley_command/phase7_bentley_command_validator.py`
- `docs/reports/phase7_bentley_command/phase7_bentley_command_validator_run.json`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase7e_7g_lite_bentley_command_extensions_report.md`

## Implementation Summary

- Phase 7E-lite: added `BentleyCrawlspaceConnector` as a thin `CompanionCommandPoint` subclass that defaults to `command_type = "crawlspace"` and uses normal requirements/effects.
- Phase 7F-lite: added `BentleyWaitMarker` as a thin `CompanionCommandPoint` subclass that defaults to `command_type = "wait"` and uses normal requirements/effects.
- Added `DogCompanion.command_crawlspace()` and `command_wait()` so placed markers can move Bentley to the marker and hold him there.
- Phase 7G-lite: added CardEffects helpers for Bentley sniff cooldown, fetch cooldown, and fetch range. `DogCompanion` consumes those helpers; focused tests prove `fish_treat_focus` changes command behavior.
- Added templates, Mission Dock placement defaults, dev-room proof nodes, focused tests, and static validator coverage.

## Protected Scope

- No production Taco scene changes.
- No new global companion manager.
- No full crawlspace traversal graph or separate Bentley-control mode.
- No guard/noise listener AI; bark/noise integration remains a later noise/distraction packet.

## Validation

- `python src/tools/editor/phase7_bentley_command/phase7_bentley_command_validator.py` passed.
- `git diff --check` passed, with only the pre-existing CRLF/LF warning for `docs/reports/phase7_bentley_command/phase7_bentley_command_validator_run.json`.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/CompanionCommandPointTest.gd"` passed `12/12`.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `209/209`.
- `.\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded the dev proof scene and exited cleanly.

## Risks / Follow-Ups

- Crawlspace behavior is a controlled lite proof: Bentley moves to the marker and effects can unlock/toggle route state, but there is no multi-node crawlspace path graph yet.
- Wait marker holds Bentley at the marker; broader puzzle timing and UI affordances remain future work.
- Production mission placement remains deferred until a mission needs Bentley route content.
