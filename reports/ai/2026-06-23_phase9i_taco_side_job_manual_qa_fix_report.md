# Phase 9I Taco Side-Job Manual QA Fix Report

**Date:** 2026-06-23
**Status:** Implemented, automated-validation passed, and live Taco QA confirmed by Jake

## Goal

Fix the player-facing Phase 9I Taco production pilot blocker where `Search Scrap` did not provide clear green completion feedback and `Side Job Signoff` could be hard to target because nearby broad interactables could win selection.

## Implementation Summary

- Raised the production pilot lane interaction priorities above nearby generic authoring/readability candidates:
  - `PpTacoSouthSearchDrop`: `760`
  - `PpTacoSouthRewardScrap`: `750`
  - `PpTacoSouthRoutePeek`: `740`
  - `PpTacoSouthSideJobSignoff`: `730`
- Added a hidden green `SearchFoundVisual` to `PpTacoSouthSearchDrop` and wired `SearchZone` visual toggling so `Search Scrap` turns from yellow to green after search.
- Added reusable `SideObjectiveNode` handled-target visibility toggles so side objectives can show completion feedback.
- Wired `PpTacoSouthSideJobSignoff` to hide its cyan visual and show a green `SignoffCompleteVisual` on successful signoff.
- Set the Taco signoff node to `one_shot = false` so it relies on its own `handled` state instead of the base mechanic `used` flag.
- Added a focused off-tree regression that loads the Taco production scene, verifies node types/priorities, runs search -> reward -> route -> signoff, and checks mission flags plus search visual toggles.
- Added an isolated bridge-path regression that uses the scene-authored signoff node and verifies `MissionInteractionBridge.try_interact_at_position()` selects it after `pp_taco_south_route_open` is set.
- Hardened `MechanicAreaBase.build_context()` for off-tree test instancing by leaving `source_path` blank when the node is not inside the scene tree.

## Files Changed

- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `src/missions/iso/authoring/mechanics/SideObjectiveNode.gd`
- `src/missions/iso/authoring/mechanics/MechanicAreaBase.gd`
- `tests/mission_authoring/Phase9GTo9ISideJobCompletionTest.gd`
- `reports/ai/2026-06-23_phase9i_taco_side_job_manual_qa_fix_report.md`

## Validation

- `git diff --check -- src/missions/iso/authoring/mechanics/SideObjectiveNode.gd src/missions/iso/authoring/mechanics/MechanicAreaBase.gd scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn tests/mission_authoring/Phase9GTo9ISideJobCompletionTest.gd reports/ai/2026-06-23_phase9i_taco_side_job_manual_qa_fix_report.md` passed.
- `python src/tools/editor/phase9_puzzle_side_job_kit/phase9_puzzle_side_job_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/Phase9GTo9ISideJobCompletionTest.gd"` passed `6/6`, `0` errors, `0` failures, `0` orphans.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/SearchZoneTest.gd" -a "res://tests/mission_authoring/RewardNodeTest.gd" -a "res://tests/mission_authoring/RouteUnlockNodeTest.gd" -a "res://tests/mission_authoring/SideObjectiveNodeTest.gd"` passed `46/46`, `0` errors, `0` failures, `0` orphans.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/SideObjectiveNodeTest.gd" -a "res://tests/mission_authoring/MissionInteractionBridgeTest.gd"` passed `27/27`, `0` errors, `0` failures, `0` orphans.
- `.\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"` loaded the Taco scene and reached mission startup.
- Jake live-QA confirmed in Taco that `Search Scrap`, `Collect Scrap`, `Open Route Peek`, and `Side Job Signoff` all turned green in succession. Jake also confirmed the bag objective, Louis exit, Ithik code clue, and Phase0K completion were unaffected.

## Observed Validation Noise

- GdUnit/Godot runs can log `McpInteractionServer: Failed to listen on port 9090` when another Godot/MCP process owns the debug port. The tests still exited `0`.
- Taco headless quit still reports existing shutdown leak/orphan warnings, matching earlier Phase 9 Taco smoke notes and not blocking scene load.
- GdUnit generated `reports/report_75/` during validation.

## Manual QA Checklist

- In Taco, approach the pilot lane and confirm `Search Scrap` is the selected interaction when overlapping nearby broad candidates.
- Interact with `Search Scrap` and confirm its box turns green.
- Continue `Collect Scrap` -> `Open Route Peek` -> `Side Job Signoff`.
- Confirm `Side Job Signoff` is targetable after route peek and turns green.
- Confirm Louis exit, bag objective, code clue, and Phase0K completion still work normally.

## Grouped-Milestone Mode

This pass stayed in a narrow QA-fix slice rather than accelerated grouped-milestone mode because it addressed a specific player-facing manual QA blocker inside an already-completed Phase 9I milestone.

## Risks / Follow-Ups

- Phase 9I Taco side-job manual QA is confirmed complete.
- Existing unrelated dirty/untracked worktree files remain outside this slice.
