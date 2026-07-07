# Mission Dock Autopopulate Report

## Goal

Continue the Milestone A follow-up by making Mission Dock mechanic selection auto-fill useful authoring defaults instead of leaving level builders with generic `dev_mechanic`/`Press E: Interact` placeholders.

This stayed in a narrow follow-up slice, not a new grouped milestone. The broader Milestone A grouped packet remains documented in `reports/ai/2026-07-06_milestone_a_level_builder_parity_report.md`.

## Files Changed

- `addons/mission_dock/MissionDock.gd`
- `src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`
- `reports/ai/2026-07-06_mission_dock_autopopulate_report.md`

## Implementation

- Added `_apply_authoring_preset()` and helper methods so changing the mechanic type updates the ID, display name, parent path, prompt, interaction mode, one-shot flag, starter requirement, and starter success effect.
- Added starter chain defaults for common proof-authoring flow: `SearchZone -> search_done`, `RewardNode` requires `search_done` and sets `reward_done`, `RouteUnlockNode` requires `reward_done` and sets `route_open`, `TeleportZone`/`ExtractionZone` require `route_open`.
- Added safer defaults for marker/runtime helpers: player start and teleport target are `SCRIPT_ONLY`; music trigger is automatic and repeatable; hide spots are repeatable; extraction completes mission on success.
- Added security/collectible author defaults for beam/camera/guard route authoring, including `ambush_beam_tripped`, `camera_alarm`, and route id suggestion.
- Fixed sticky placement ID progression by setting `_mechanic_id_base.text = _suggest_next_id(mechanic_type)` after each successful placement.
- Sanitized planned node names by replacing dots in generated IDs with underscores.
- Replaced the Mission Dock audit's hard `GameState` global reference with `_mission_catalog_snapshot()` so the tool script does not depend on direct autoload identifier resolution.
- Extended the Phase 2K static validator to require the new preset/helper coverage and Milestone A template coverage.

## Validation

- `git diff --check -- "addons/mission_dock/MissionDock.gd" "src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py"`: PASS.
- `python src\tools\editor\phase2k_mission_dock\phase2k_mission_dock_static_validator.py`: PASS.
- `addons\gdUnit4\runtest.cmd -a res://tests/mission_authoring/Phase17LevelBuilderReadinessTest.gd`: PASS `5/5`, report `reports/report_68`.
- `Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: scene loaded and started `milestone_a_proof`; shutdown leak noise remains consistent with forced quit-after smokes.
- `Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 1 res://scenes/dev/mission_authoring/MilestoneASecuritySmoke.tscn`: scene loaded and started `milestone_a_security_smoke`; one run showed MCP port-bind noise from the local MCP server.

## Blocked Or Noisy Validation

- Full `--headless --editor --path . --quit` did not reach a clean exit within 10 minutes because editor startup/import was still loading a large number of tile assets. No Mission Dock parse error was observed before timeout, but this is not a clean editor-parse PASS.
- Direct `--check-only --script res://addons/mission_dock/MissionDock.gd` is not a valid standalone proof for this project because existing mission-authoring dependencies compile against project autoload globals such as `CardManager` and `EventBus` that are not available in isolated script mode. It did catch and confirm removal of the new hard `GameState` reference risk before hitting those existing dependency constraints.

## Risks And Manual QA

- Live editor dock interaction still needs Jake or an agent with Godot editor/MCP control to confirm the actual UI values after changing each mechanic type.
- Manual check: open `MilestoneAProofMission.tscn`, select `SearchZone`, `RewardNode`, `RouteUnlockNode`, `TeleportZone`, `ExtractionZone`, `PlayerStartMarker`, `MusicTriggerZone`, and security author types in Mission Dock, then confirm the preset fields match the intended chain and sticky placement increments IDs.
- The current worktree already contains many unrelated/generated changes from Milestone A and GdUnit report runs; no staging, commit, branch, or history operation was performed.
