# Milestone A Proof Mechanic Clarity + F10 Follow-Up Report

Date: 2026-07-09

## Scope

Follow-up fixes for the Milestone A proof mission after runtime QA showed unclear mechanic ordering, extraction feedback that only appeared as `true`, immediately gated teleports, and F10 debug panel error spam / non-scrollable output.

## Files Changed

- `src/missions/iso/runtime/IsoMissionDebugPanel.gd`
- `src/missions/iso/runtime/authoring/MissionInteractionBridge.gd`
- `src/missions/iso/authoring/mechanics/TeleportZone.gd`
- `src/missions/iso/authoring/mechanics/ExtractionZone.gd`
- `addons/mission_dock/MissionDock.gd`
- `scenes/missions/iso/authoring/TeleportZoneTemplate.tscn`
- `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`
- `tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`

## Changes

- F10 debug panel now wraps the status text in a `ScrollContainer`, preserves scroll position during refresh, and avoids the prior format-string mismatch that could spam errors.
- `MissionInteractionBridge` debug prints now prefer structured mechanic result dictionaries such as `last_extraction_result`, `last_teleport_result`, or `last_activation_result` when a mechanic provides them, instead of only printing a raw boolean.
- `TeleportZone` now has `require_prior_interaction`; when disabled, teleport requirements intentionally bypass prior mission state checks.
- Mission Dock no longer creates new `TeleportZone` instances with the starter `route_open` gate by default.
- Teleport zone template defaults to `require_prior_interaction = false` for immediate proof/authoring use.
- Milestone A proof teleports were configured to work immediately with `E`.
- Milestone A proof Location 1 labels now state the intended sequence clearly: walk into `1A`, then press `E` at `1B` through `1F`.
- Core extraction now shows the mission result screen on success, uses a clearer missing-objective message, and emits EventBus debug for QA visibility.

## Validation

- `git diff --check -- addons/mission_dock/MissionDock.gd scenes/dev/mission_authoring/MilestoneAProofMission.tscn scenes/missions/iso/authoring/TeleportZoneTemplate.tscn src/missions/iso/authoring/mechanics/ExtractionZone.gd src/missions/iso/authoring/mechanics/TeleportZone.gd src/missions/iso/runtime/IsoMissionDebugPanel.gd src/missions/iso/runtime/authoring/MissionInteractionBridge.gd tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS
- `python src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`: PASS
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS, 17/17, `reports/report_82/results.xml`
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/ExtractionZoneTest.gd`: PASS, 14/14, `reports/report_83/results.xml`
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/MissionInteractionBridgeTest.gd`: PASS, 14/14, `reports/report_84/results.xml`
- `$env:GODOT_BIN --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: scene loaded, mission started, and level loaded.

## Validation Notes

- A combined GdUnit command using comma-separated `-a` paths failed because this runner treats the second path as an unknown command. The suites were rerun separately and passed.
- Headless scene smoke still reports known MCP/runtime noise, including port 9090 bind failure when another MCP server is already present and shutdown leak/orphan warnings. No parse errors or scene-load failures were observed.

## Manual QA Checklist

- In Location 1, walk into `1A WALK IN: enables LOCK`.
- Press `E` at `1B E: LOCK -> enables HACK`.
- Press `E` at `1C E: HACK -> enables CRATE`.
- Press `E` at `1D E: CRATE -> enables SIDE OBJ`.
- Press `E` at `1E E: SIDE OBJ -> enables EXIT`.
- Press `E` at `1F E: EXIT -> Mission Result`; this should show the mission result screen after success.
- Try proof-scene teleports before doing prior route/objective interactions; they should work immediately with `E`.
- Toggle F10 and scroll the debug output; it should not spam format-string errors and should keep the scroll position during refresh.

## Risks / Follow-Ups

- Manual in-editor/player QA is still recommended for visual confirmation of the mission result screen transition and the F10 scroll behavior.
- `MissionInteractionBridge` still prints raw `true` for generic interactables that do not expose a structured `last_*_result` dictionary; authored mechanics such as extraction and teleport now provide richer debug output.
- Existing unrelated dirty worktree changes and old generated report deletions were not modified or reverted.

## Mode

This remained a narrow follow-up slice, not a new grouped milestone. The changes were limited to the reported Milestone A proof clarity/debug issues and their direct tests/authoring defaults.
