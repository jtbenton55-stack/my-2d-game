# Phase 7A-7D-lite Bentley Command Points Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; validation passed

## Goal

Add the first reusable Bentley command-point packet so missions can place bark/sniff/fetch prompts that use `RequirementSet` and `EffectSet` instead of mission-specific scripts.

## Files Changed

- `src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd`
- `src/player/DogCompanion.gd`
- `addons/mission_dock/MissionDock.gd`
- `scenes/missions/iso/authoring/CompanionCommandPointTemplate.tscn`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/CompanionCommandPointTest.gd`
- `src/tools/editor/phase7_bentley_command/phase7_bentley_command_validator.py`
- `docs/reports/phase7_bentley_command/phase7_bentley_command_validator_run.json`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase7a_7d_lite_bentley_command_points_report.md`

## Implementation Summary

- Phase 7A-lite: added `CompanionCommandPoint`, extending `MechanicAreaBase`, with `bark`, `sniff`, and `fetch` command types, companion lookup by path or `bentley` group, clean result dictionaries, requirement evaluation, and success/failure effects.
- Phase 7B-lite / 7C-lite / 7D-lite: added public `DogCompanion.command_sniff()`, `command_fetch()`, and `command_bark()` wrappers so placed command points and direct input reuse one behavior path.
- Expanded Bentley fetch target detection so item/reward nodes such as `InventoryPickupNode` can be fetched in the dev proof.
- Added Mission Dock placement defaults/audit support and `CompanionCommandPointTemplate.tscn`.
- Added dev-room bark/sniff/fetch command points plus a nearby fetchable inventory token.

## Protected Scope

- No production Taco scene changes.
- No new companion manager or duplicate global Bentley command system.
- No full noise/distraction listener AI; bark command points only prove the command/effect hook for now.
- No crawlspace connector, wait marker, or card-specific command tuning in this lite packet.

## Validation

- PASS: `python src/tools/editor/phase7_bentley_command/phase7_bentley_command_validator.py`.
- PASS: focused GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/CompanionCommandPointTest.gd"` passed `8/8`, `0 errors`, `0 failures`; report generated at `reports/report_50/` and removed as validation output.
- PASS: full GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `205/205`, `0 errors`, `0 failures`; report generated at `reports/report_51/` and removed as validation output.
- PASS: `git diff --check`.
- PASS with known MCP bind warning: headless dev-scene smoke `.\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded `CompanionCommandPoint.gd`, `DogCompanion.gd`, and `MechanicAuthoringTestRoom.tscn`; Godot still reported the existing MCP port `9090` bind warning when another listener is active.
- Cleanup note: GdUnit pruned tracked generated folders `reports/report_26/` through `reports/report_31/`; they were restored. Pre-existing tracked deletions under `reports/report_23/` through `reports/report_25/` were left untouched.

## Risks / Follow-Ups

- Manual Godot editor restart may be needed before Mission Dock lists a newly added script from the class-name cache.
- Phase 7E-7G remain deferred: crawlspace connectors, wait markers, card-specific command modifiers, and production mission placement.
- Bark/noise integration should connect to the later noise/distraction system instead of growing command-point-specific guard AI.
