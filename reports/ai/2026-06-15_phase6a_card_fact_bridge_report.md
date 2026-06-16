# Phase 6A Card Fact Bridge Report

**Date:** 2026-06-15
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; static whitespace validation passed; Godot/GdUnit unavailable from OpenCode PATH

## Goal

Complete Phase 6A so selected, unlocked, and effect-bearing scheme card facts flow through the existing mission-authoring requirement stack:

`Placed mechanic node -> RequirementSet -> MissionRequirement -> MissionFactBridge -> GameState / CardManager / MissionSchemeBridge`

No new manager, save format, or hardcoded Taco card script was added.

## Files Changed

- `src/missions/schemes/MissionSchemeBridge.gd`
- `src/missions/schemes/MissionSchemeCardFormatter.gd`
- `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd`
- `src/missions/iso/dev/Phase6ACardTestHarness.gd`
- `src/missions/iso/dev/Phase6ACardTestHarness.gd.uid`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/RequirementSetTest.gd`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `reports/ai/2026-06-15_phase6a_card_fact_bridge_report.md`

## Implementation Summary

- Kept `MissionFactBridge` as the single fact adapter for `selected_card`, `unlocked_card`, and `scheme_effect`.
- Updated `MissionSchemeBridge.has_scheme_effect()` to inspect `get_active_scheme_cards()` instead of only `CardManager.get_selected_cards()`.
- This means authored `scheme_effect` requirements can now see:
  - legacy selected mission cards from `GameState.selected_cards`
  - current planning loadout cards from `GameState.current_scheme_loadout`
- Left `CardEffects.gd` unchanged, so this does not globally activate planning-table effects in old runtime card hooks.
- Added GdUnit coverage in `RequirementSetTest.gd` for:
  - `unlocked_card` reading typed `GameState.unlocked_scheme_cards`
  - `scheme_effect` reading a selected card's `effect_key`
  - `scheme_effect` reading the current loadout card's `effect_key`
- Added a dev-only Phase 6A Card Test Harness to `MechanicAuthoringTestRoom.tscn`.
- The harness lists cards from `resources/cards/*.tres`, writes the selected card to `GameState.current_scheme_loadout.plan`, clears legacy `selected_cards` for deterministic dev testing, and shows the exact `MissionRequirement` fields to use for the selected card's `effect_key`.
- Updated `MechanicAuthoringTestRoomController.gd` to snapshot/restore `GameState.selected_cards` and `GameState.current_scheme_loadout` so harness changes do not leak after leaving the dev scene.
- Fixed `SchemeCard` resource property reads in `MissionSchemeBridge.gd` and `MissionSchemeCardFormatter.gd` to avoid two-argument `Resource.get()` calls; Godot Resources expect a single property name argument.
- Tuned `RewardNode_qa_reward_node_02` for manual Phase 6A testing: it now uses its own IDs/collected flag, reads its own collision shape, routes debug text to `HintLabel`, and hides its red `GateVisual` when collection succeeds.
- Updated the Phase 6A harness to refresh all `mission_mechanic` debug labels immediately after dropdown changes, so labels reflect `LOCKED` / `READY` without requiring an interaction attempt first.

## Validation

- `git diff --check` passed before this report was added.
- Final `git diff --check` passed after this report was added.
- Final `git diff --check` also passed after adding the dev-only Phase 6A Card Test Harness.
- Final `git diff --check` passed after the Resource `get()` crash fix; Git printed a line-ending warning for `MissionSchemeCardFormatter.gd` after the targeted patch touched that file.
- Final `git diff --check` passed after the `RewardNode_qa_reward_node_02` manual feedback update; Git still printed the same line-ending warning for `MissionSchemeCardFormatter.gd`.
- Final `git diff --check` passed after the harness debug-label refresh fix; Git still printed the same line-ending warning for `MissionSchemeCardFormatter.gd`.
- `where.exe godot` did not find Godot on PATH, so OpenCode could not run Godot editor checks or GdUnit4 from this shell.

## Protected Scope

- No Taco production scene files were modified.
- No Phase0J/Phase0K runtime scripts were modified.
- No `CardEffects.gd` behavior was changed.
- No new global mission/card manager was introduced.
- No save/load schema was changed.

## Unrelated Local Files Not Touched

- `resources/character_animation_maps/character_01_parmida_reference_variant_sheet_candidate_ranges_v1.json`
- `addons/gdUnit4/GdUnitRunner.cfg`
- `reports/report_1/`

These remain pre-existing local/generated leftovers and should stay excluded unless Jake explicitly asks to review/include them.

## Remaining Risks / Follow-Ups

- Run the updated `tests/mission_authoring/RequirementSetTest.gd` in GdUnit4 when Godot is available.
- Phase 6B should add inspectable mission modifier data only after Phase 6A tests pass in Godot.
- A future production slice should prove one real card changes one placed mission node without hardcoded scene logic.
