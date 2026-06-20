# Phase 5D-5F-Lite Inventory Pickup / Debug Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; validation passed

## Goal

Continue Phase 5 after the committed 5A-5C inventory foundation by adding the first reusable mission item pickup, a dev-scene proof, simple debug visibility, and an explicit persistence boundary without creating a grid UI or persistent save schema.

## Files Changed

- `src/missions/iso/authoring/mechanics/InventoryPickupNode.gd`
- `scenes/missions/iso/authoring/InventoryPickupNodeTemplate.tscn`
- `tests/mission_authoring/InventoryPickupNodeTest.gd`
- `addons/mission_dock/MissionDock.gd`
- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `src/tools/editor/phase5_inventory_heist_kit/phase5_inventory_validator.py`
- `docs/reports/phase5_inventory_heist_kit/phase5_inventory_validator_run.json`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase5d_5f_lite_inventory_pickup_debug_report.md`

## Implementation Summary

- Phase 5D-lite: added `InventoryPickupNode`, extending `RewardNode` so item pickups preserve requirement checks, collected flags, one-shot behavior, and target visual toggles.
- Item grants are generated as `MissionEffect.GRANT_ITEM` and applied through `MissionEffectApplier`; the pickup does not write directly to mission scripts or bypass the effect pipeline.
- Added fallback exported item fields plus optional `ItemData` support, and prevented missing-`item_id` pickups from collecting.
- Added `InventoryPickupNodeTemplate.tscn` and Mission Dock support for placement defaults, prompt text, safe `item_id`/`reward_id`/`collected_flag` setup, and missing-item audit warnings.
- Added dev-scene proof chain: `InventoryPickupNode_phase5d_delivery_badge` grants `delivery_badge`, and `RouteUnlockNode_phase5d_badge_route` requires `inventory_has_item:delivery_badge`.
- Phase 5E-lite: added F10 compact HUD `mission_inv ...` snapshot output through `IsoMissionDebugPanel`.
- Phase 5F-lite: retained the mission-only cleanup policy from 5A-5C; persistent save schema and production mission item placement remain deferred.

## Protected Scope

- No production Taco scene changes.
- No grid inventory UI, crafting system, merchant economy, or equipment plugin.
- No persistent item save schema or save-version change.
- No new global inventory autoload or duplicate manager.

## Validation

- PASS: focused GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/InventoryPickupNodeTest.gd"` passed `7/7`, `0 errors`, `0 failures`; report generated at `reports/report_46/`.
- PASS: `python src/tools/editor/phase5_inventory_heist_kit/phase5_inventory_validator.py` before the validator expansion.
- PASS: expanded Phase 5 validator rerun `python src/tools/editor/phase5_inventory_heist_kit/phase5_inventory_validator.py`.
- PASS: `git diff --check`; PowerShell reported only the expected line-ending notice for regenerated `docs/reports/phase5_inventory_heist_kit/phase5_inventory_validator_run.json`.
- PASS: full GdUnit `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `197/197`, `0 errors`, `0 failures`; report generated at `reports/report_47/`.
- PASS with known MCP bind warning: headless dev-scene smoke `.\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded `InventoryPickupNode.gd` and the dev room. Godot still reported the existing `McpInteractionServer: Failed to listen on port 9090` warning when another listener is active; no fatal scene/script error occurred.
- PASS manual QA: Jake restarted Godot so Mission Dock showed `InventoryPickupNode`, confirmed Mission Dock placement wrote expected Inspector values, then ran the dev room and confirmed pressing `E` on `5D: Pick up delivery badge` followed by `E` on `5D: Badge-gated route` turns the route green. Remote Inspector showed `RewardNode.gd -> Collected = On` for the pickup.
- Cleanup note: the full GdUnit run pruned tracked generated folders `reports/report_26/` and `reports/report_27/`; they were restored. Pre-existing tracked deletions under `reports/report_23/` through `reports/report_25/` were left untouched.

## Risks / Follow-Ups

- Persistent item support remains intentionally deferred until a production mission needs it.
- Production Taco item placement remains deferred; this packet only proves the reusable node and dev-room route gate.
- F10 inventory debug is not visible in `MechanicAuthoringTestRoom.tscn` because that dev scene does not include `IsoMissionDebugPanel`; validate the F10 `mission_inv` line in a mission scene that has the debug panel.
