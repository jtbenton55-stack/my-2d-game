# Phase 5A-5C-Lite Inventory / Heist Kit Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; static validation passed; focused GdUnit passed

## Goal

Start Phase 5 with a reversible mission-local inventory packet: item data Resources, lightweight mission inventory state, and requirement/effect integration through the existing plug-and-play authoring stack.

## Files Changed

- `src/inventory/items/ItemData.gd`
- `src/inventory/items/InventoryEntry.gd`
- `src/inventory/MissionInventory.gd`
- `src/missions/iso/authoring/core/MissionFactBridge.gd`
- `src/missions/iso/authoring/core/MissionEffect.gd`
- `src/missions/iso/authoring/core/MissionEffectApplier.gd`
- `src/autoload/GameState.gd`
- `addons/mission_dock/MissionDock.gd`
- `tests/mission_authoring/MissionInventoryTest.gd`
- `src/tools/editor/phase5_inventory_heist_kit/phase5_inventory_validator.py`
- `docs/reports/phase5_inventory_heist_kit/phase5_inventory_validator_run.json`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `reports/ai/2026-06-20_phase5a_5c_lite_inventory_heist_kit_report.md`

## Implementation Summary

- Phase 5A-lite: added `ItemData` with the roadmap category vocabulary, stack policy, mission-only flag, suspicious/heat fields, icon, description, validity helper, and designer summary.
- Phase 5B-lite: added `InventoryEntry` and `MissionInventory` as a lightweight mission-runtime adapter. It supports add/remove/has/count/category/snapshot and clear mission-only entries without introducing an autoload or save schema.
- Phase 5C-lite: added `inventory_has_item`, `inventory_item_count`, and `inventory_has_category` facts through `MissionFactBridge`.
- Added `GRANT_ITEM`, `REMOVE_ITEM`, and `CLEAR_MISSION_ITEMS` to `MissionEffect` and `MissionEffectApplier`, appending enum values to avoid shifting existing effect IDs.
- Added mission lifecycle cleanup in `GameState.reset_for_new_game()`, `start_mission()`, `complete_mission()`, and `fail_mission()` while keeping mission inventory out of `to_dict()` and `from_dict()`.
- Updated Mission Dock's vocabulary so authored requirements/effects can expose the new inventory paths.
- Validation follow-up: changed new inventory references in parse-critical scripts to explicit preloads (`MissionInventoryScript`, `ItemDataScript`, `InventoryEntryScript`) so headless GdUnit/autoload compilation does not depend on Godot's global class-name cache being refreshed for newly added scripts.

## Protected Scope

- No production Taco scene changes.
- No grid inventory UI, crafting, merchant economy, or equipment plugin.
- No persistent item save data or save-version/schema change.
- No duplicate global inventory manager/autoload; the first slice is a static mission-local adapter.
- No pickup mechanic yet; item grants currently flow through authored effects.

## Validation

- PASS: `git diff --check`.
- PASS: `python src/tools/editor/phase5_inventory_heist_kit/phase5_inventory_validator.py`.
- PASS: Godot version check with `./Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe --version` returned `4.6.2.stable.official.71f334935`.
- PASS after explicit-preload fix: focused GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/MissionInventoryTest.gd"` passed `5/5`, `0 errors`, `0 failures`; report generated at `reports/report_43/`.
- PASS: full GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `190/190`, `0 errors`, `0 failures`; report generated at `reports/report_44/`.
- PASS with known MCP bind warning: headless dev-scene smoke `Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded the scene, autoloads, mission-authoring mechanics, and card harness scripts. Godot still reported the existing `McpInteractionServer: Failed to listen on port 9090` warning when another MCP listener is active; no fatal scene/script error occurred.

## Risks / Follow-Ups

- Phase 5D should provide the first item pickup/dev-scene proof; Phase 5A-5C-lite only validates the shared inventory contract and existing dev-scene load safety.
- Phase 5D should add a reusable pickup node or `RewardNode` item-grant integration plus a dev-scene proof.
- Phase 5E should add a simple debug list, not a full inventory UI.
- Phase 5F should formalize persistent-vs-mission-only policy only after a real mission proves persistent items are needed.
