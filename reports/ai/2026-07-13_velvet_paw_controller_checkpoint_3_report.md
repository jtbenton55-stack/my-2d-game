# Velvet Paw Controller Checkpoint 3

Date: 2026-07-13
Mode: Narrow Stage 2C checkpoint inside the grouped Velvet Paw repair milestone
Status: Automated controller contract complete; superseded by the final GameSir A/interact layout and physical-QA follow-up

## Goal

Close the two controller gaps recorded after checkpoint 2: Start/Menu pause support and controller-only Bentley parking at the VIP wait marker.

## Audit Result

Only the pause gap required gameplay code.

- `project.godot` already maps joypad button 6, Start/Menu, to `pause`.
- The pause menu instantiated by `LevelBase` listened only to `ui_cancel`, so it ignored the existing `pause` action.
- The final Xbox layout maps joypad button 0, A, to generic `interact`; Y is reserved for the style finisher.
- `MissionInteractionBridge` already routes that action to the nearest authored mechanic.
- The production `BentleyWaitMarker` calls `DogCompanion.command_wait()`, which records the exact marker ID and position required by Velvet's VIP predicate.
- The global `bentley_toggle_stay` shortcut is not equivalent: it toggles in place and clears marker identity. D-pad Down therefore remains separate from the authored A interaction.

## Changes

- `src/ui/test_ui/pause_menu.gd`
  - The existing `pause` action now toggles the menu open and closed.
  - `ui_cancel` closes only an already-visible menu and cannot open pause during gameplay.
  - The event is handled once and returns after the transition.
- `tests/mission_authoring/VelvetPawControllerCheckpointTest.gd`
	- Proves Start/Menu and A action-map bindings.
	- Proves Start/Menu toggles the actual mission pause scene, restores the tree, and focuses Resume.
	- Proves hidden cancel/B cannot open pause but can close an open menu.
	- Sends a real joypad A event through the production bridge and proves Bentley ends in stay mode at the exact authored marker ID/position.
	- Proves A is not also mapped to `bentley_toggle_stay`.

No changes were needed in `project.godot`, `Player.gd`, `DogCompanion.gd`, `MissionInteractionBridge.gd`, `BentleyWaitMarker.gd`, the Velvet controller, or the production scene.

## Validation

- Isolated new suite after test-path correction: PASS, 3/3; zero errors, failures, flaky cases, skips, or orphans.
- Expanded focused gate: PASS, 53/53 across 6/6 suites; zero errors, failures, flaky cases, skips, or orphans.
- Suites: `VelvetPawControllerCheckpointTest`, `CaseJointHintProviderTest`, `MissionInteractionBridgeTest`, `CompanionCommandPointTest`, `VelvetPawRouteComponent2Test`, and `VelvetPawJazzClubRuntimeQATest`.
- XML evidence: `reports/velvet_controller_checkpoint3/report_3/results.xml`.
- Production Velvet headless startup: PASS; pause script, mission, cameras, and guards load without script/runtime errors.
- Level blueprint validator: PASS for all three specs and 55 mechanic types; zero failures or warnings.
- `git diff --check`: PASS with only the known generated build-guide CRLF warning.
- The first new-suite run had one test error because the test used the pre-runtime `GameplayRoot/EntityRoot/Player` path. `IsoMissionBase` reparents runtime entities to `EntityRoot/Player`; correcting the test to the established runtime path produced the clean runs above.
- Godot MCP Pro was unavailable in this OpenCode tool session, so physical input and screenshots were not automated.

## Remaining Manual QA

- Confirm a physical controller's Start/Menu button opens and closes pause during production gameplay.
- Confirm Resume receives focus and all pause-menu buttons navigate correctly on controller.
- Confirm B dodges during gameplay, closes dialogue, and backs out of pause subpanels before resuming gameplay.
- Confirm one A press at the production marker parks Bentley without skipping or restarting his two dialogue lines.
- The later GameSir controller packet added combined A/E prompts and recorded the first physical-controller pass.

## Safety And Continuity

- This remained a narrow checkpoint because the audit showed the Bentley path already existed and only pause handling was missing.
- No new input manager, mission-local listener, compatibility layer, or duplicate companion command was added.
- Existing unrelated worktree changes were preserved.
- No commit, stage, push, branch change, reset, or history operation was performed.
