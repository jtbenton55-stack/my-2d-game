# Phase 6C / 6D-lite / 6E-lite Scheme Card Trigger Report

**Date:** 2026-06-17
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; focused and full mission-authoring validation passed

## Goal

Add the first reusable placed mechanic that consumes Phase 6B `MissionModifierSet` data so active scheme cards can change mission setup without hardcoded card behavior in production mission scripts.

## Files Changed

- `src/missions/iso/authoring/mechanics/SchemeCardTriggerNode.gd`
- `src/missions/iso/authoring/mechanics/SchemeCardTriggerNode.gd.uid`
- `tests/mission_authoring/SchemeCardTriggerNodeTest.gd`
- `tests/mission_authoring/SchemeCardTriggerNodeTest.gd.uid`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `src/missions/iso/dev/MechanicAuthoringTestRoomController.gd`
- `src/missions/iso/dev/Phase6ACardTestHarness.gd`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-17_phase6c_6d_lite_6e_lite_scheme_card_trigger_report.md`

## Implementation Summary

- Added `SchemeCardTriggerNode`, an `@tool` `MechanicAreaBase` subclass that reads active cards through `MissionSchemeBridge.get_active_scheme_cards()`.
- The node consumes exported `modifier_sets: Array[Resource]`, casts valid entries to `MissionModifierSet`, evaluates modifier requirements, and applies setup `EffectSet` data.
- Added optional `apply_on_ready` support for starting setup hooks.
- Added interaction-compatible entry points: `trigger_scheme_cards`, `trigger`, `interact`, `on_interact`, `use`, and `inspect_marker`.
- Added focused GdUnit coverage for selected-card setup, missing-card blocking, current-loadout route gating, and ready-time setup.
- Extended `MechanicAuthoringTestRoom.tscn` with a dev-only Phase 6C/6D-lite proof: select `louis_delivery_route` in the Phase 6A card harness, trigger the scheme-card setup node, then unlock a route gated by the resulting mission flag.
- Added dev-room status readouts for `phase6c_scheme_route_ready` and `phase6d_card_route_open` so manual QA can see the card setup and route unlock flags directly.
- Follow-up manual QA fix: the dev-room Phase 6C trigger is one-shot so it stops shadowing the nearby Phase 6D route in `MissionInteractionBridge` candidate selection after card setup succeeds.
- Follow-up dev-room usability fix: `Phase6ACardTestHarness` is now draggable by its header and collapsible with its header button so it can be moved away from nodes during manual QA.

## Protected Scope

- No production Taco scenes were modified.
- No `CardEffects.gd` behavior was changed.
- No global card/modifier manager was added.
- No save/load schema was changed.
- No Phase0J/Phase0K runtime scripts were modified.

## Validation

- `git diff --check` for the touched Phase 6 files passed.
- Dev scene load passed: `res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn` loaded headlessly with Godot 4.6.2.
- Focused GdUnit passed: `res://tests/mission_authoring/SchemeCardTriggerNodeTest.gd` passed `4/4`.
- Full GdUnit passed: `res://tests/mission_authoring/` passed `170/170`.
- Jake manually validated the dev-room flow: selecting `louis_delivery_route` made 6C set `phase6c_scheme_route_ready: true`, 6D then set `phase6d_card_route_open: true`, selecting `None` blocked both, and the harness drag/collapse controls worked.
- GdUnit generated disposable report output under `reports/report_48/` through `reports/report_52/`; these should remain untracked unless Jake explicitly asks to preserve them.

## Remaining Risks / Follow-Ups

- Phase 6F production card slice remains deferred; no production Taco scene behavior has changed yet.
- Starting item grants remain deferred to the Phase 5 inventory/heist-kit work; Phase 6E-lite currently proves route facts/hints/setup effects only.
- Manual editor QA should still confirm `SchemeCardTriggerNode` appears and is comfortable in the Create New Node/resource inspector workflows.
