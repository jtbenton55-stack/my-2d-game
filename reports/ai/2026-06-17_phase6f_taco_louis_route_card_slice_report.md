# Phase 6F Taco Louis Route Card Slice Report

**Date:** 2026-06-17
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented; smoke validated; manual positive and negative QA passed

## Goal

Add the first production scheme-card modifier slice: one real card changes one placed production Taco mechanic without hardcoding card behavior into Taco scripts.

## Files Changed

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/autoload/GameState.gd`
- `tests/mission_authoring/SchemeCardTriggerNodeTest.gd`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-17_phase6f_taco_louis_route_card_slice_report.md`

## Implementation Summary

- Added a production `SchemeCardTriggerNode` under `GameplayRoot/PlugAndPlayPilot` named `PpTacoSouthLouisRouteCardSetup`.
- The node uses `apply_on_ready = true`, `mission_id_override = "taco_bell_drop"`, and a `MissionModifierSet` sourced from `louis_delivery_route`.
- When Louis Delivery Route is active, the setup effect writes mission flag `pp_taco_south_louis_route_card_ready`.
- Updated the existing production `PpTacoSouthRoutePeek` requirement set to `ANY` so the route can unlock through either:
  - the existing pilot reward flag `pp_taco_south_reward_collected`
  - the new Louis route card flag `pp_taco_south_louis_route_card_ready`
- Added focused test coverage that instantiates the Taco production scene and verifies the Phase 6F node/resource wiring.
- Added a Planning Table dev-only button, `DEV: Equip Louis Delivery Route`, so Phase 6F can be manually tested before Taco completion unlocks real card availability.
- The dev override writes `louis_delivery_route` into the Plan slot for the next launch but does not add it to `unlocked_scheme_cards`, preserving progression state.
- After manual negative QA found the route could stay open after a previous positive run, added `GameState.clear_mission_flags(mission_id)` and call it from `GameState.start_mission()` so attempt-local `mission_flag:<mission_id>:` entries cannot leak across mission launches.
- Removed the misleading production-scene override `require_matching_modifier = false` from `PpTacoSouthLouisRouteCardSetup`; the node now keeps the `SchemeCardTriggerNode` default and explicitly requires a matching Louis modifier before applying the setup flag.

## Protected Scope

- No Taco script hardcoding was added.
- No `CardEffects.gd` behavior was changed.
- No global modifier manager was added.
- No save/load schema was changed.
- No Phase0J/Phase0K runtime scripts were modified.
- The original Taco south pilot search/reward/route path remains valid when Louis Delivery Route is not active.
- The dev Planning Table override does not permanently unlock `louis_delivery_route`.
- Mission start clearing only erases namespaced `mission_flag:<mission_id>:` keys for the launching mission; other mission flags and plain dialogue flags are preserved.

## Validation

- `git diff --check` for touched Phase 6F files passed.
- Taco production scene load passed headlessly with Godot 4.6.2: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` loaded and started `taco_bell_drop`.
- The headless Taco scene load still reports existing forced-quit leak/orphan warnings after shutdown; the scene and new `SchemeCardTriggerNode` resources loaded successfully.
- Focused GdUnit passed before the dev override: `res://tests/mission_authoring/SchemeCardTriggerNodeTest.gd` passed `5/5`, including the production-scene wiring assertion.
- Full GdUnit passed before the dev override: `res://tests/mission_authoring/` passed `171/171`.
- Dev override validation passed after implementation: `res://tests/mission_authoring/SchemeCardTriggerNodeTest.gd` passed `6/6`, including `test_planning_table_dev_louis_override_does_not_unlock_card`.
- Full GdUnit passed after the dev override: `res://tests/mission_authoring/` passed `172/172`.
- Hideout scene headless load was attempted for `res://scenes/hideout/HideoutHub.tscn`; it starts loading but hits an existing `HideoutManager._ensure_dialogue_box()` `add_child()` timing error during forced headless setup. This appears unrelated to the dev override because the focused controller test exercises the new override directly without scene-tree UI timing.
- GdUnit generated disposable untracked reports `reports/report_53/` through `reports/report_56/`; these should remain untracked unless Jake explicitly asks to preserve them.
- GdUnit pruned tracked generated report folders `reports/report_28/` through `reports/report_36/`; those deletions were restored because they were unrelated to Phase 6F.
- Manual positive path before the stale-flag fix: Jake equipped `DEV: Equip Louis Delivery Route`, launched Taco, pressed `E` on `Open Route Peek`, and the route turned green.
- Manual negative path before the stale-flag fix failed: after clearing/not equipping Louis, the route still turned green. Root cause was likely stale `mission_flag:taco_bell_drop:*` entries persisting in `GameState.dialogue_flags` across mission starts.
- Post-fix `git diff --check` for `src/autoload/GameState.gd`, `tests/mission_authoring/SchemeCardTriggerNodeTest.gd`, and `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` passed.
- Post-fix Godot 4.6.2 smoke validation passed via a temporary scene that was removed after running. It verified `GameState.start_mission("taco_bell_drop")` clears stale Taco mission flags, preserves other mission/dialogue flags, and loads the Taco scene with `PpTacoSouthLouisRouteCardSetup.apply_on_ready = true`, `require_matching_modifier = true`, and `PpTacoSouthRoutePeek` still in `ANY` requirement mode. Output marker: `PHASE6F_VALIDATION_PASS`.
- Post-fix GdUnit was attempted through the local addon CLI runner, but the direct script path hung and the runner scene/TCP path printed help or used the existing config instead of accepting `-a` arguments in this environment. No post-fix GdUnit pass is claimed; use the pre-fix focused/full GdUnit results above plus the post-fix smoke validation until the runner invocation is corrected.
- Post-fix manual positive QA passed: Jake equipped `DEV: Equip Louis Delivery Route`, launched Taco, pressed `E` on `Open Route Peek`, and the route opened without collecting the pilot reward.
- Post-fix manual negative QA passed: Jake cleared/did not equip Louis, relaunched Taco, pressed `E` on `Open Route Peek`, and the route stayed blocked until the original reward-chain condition was met.

## Remaining Risks / Follow-Ups

- GdUnit post-fix runner invocation still needs cleanup if we want a fresh automated `SchemeCardTriggerNodeTest.gd` pass after the stale-flag change.
- Commit should include only intended Phase 6F files; unrelated Mission Dock, animation-map, generated report deletions, and untracked GdUnit/Godot artifacts remain in the worktree.
