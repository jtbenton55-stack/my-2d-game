# Milestone A Proof Interaction Spawn Fix Report

Date: 2026-07-08

## Summary

Fixed the interrupted `MilestoneAProofMission` debug pass where the authored player start could be ignored and most placed interaction mechanics were not bridged into runtime input handling.

The runtime fix is intentionally narrow: authored `PlayerStartMarker` placement now also creates the `default` spawn used by `LevelBase`, while keeping `start_main` for explicit mission spawn references.

## Files Changed

- `src/levels/IsoMissionBase.gd`
- `scenes/dev/mission_authoring/MilestoneAProofMission.tscn`
- `tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`
- `README.md`
- `reports/ai/2026-07-08_milestone_a_proof_interaction_spawn_fix_report.md`

## Implementation Notes

- `IsoMissionBase._create_spawn_points()` now creates both `GameplayRoot/SpawnPoints/default` and `GameplayRoot/SpawnPoints/start_main` from an authored `PlayerStartMarker`.
- `MilestoneAProofMission.tscn` now includes `GameplayRoot/RuntimeHelpers/MissionInteractionBridge` with `include_legacy_candidates = false`.
- `MilestoneAProofMission.tscn` teleport zones 02 through 07 now point to their matching `TeleportTargetMarker` nodes instead of `NodePath(".")`.
- `README.md` now has a separate follow-up reminder to ask Jake about Godot parse-error popups for older validator/Taco scripts.

## Validation

- `git diff --check -- "src/levels/IsoMissionBase.gd" "scenes/dev/mission_authoring/MilestoneAProofMission.tscn" "tests/mission_authoring/MilestoneAThinAuthorablesTest.gd" "README.md"`: PASS.
- Focused GdUnit `res://tests/mission_authoring/MilestoneAThinAuthorablesTest.gd`: PASS, 7/7, 0 failures, 0 errors, 0 orphans.
- `python src/tools/editor/phase2k_mission_dock/phase2k_mission_dock_static_validator.py`: PASS.
- Headless smoke `res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn`: process exit `0`, scene loaded and mission started.

## Runtime Noise

- Headless scene smoke still logs controller mapping warnings and exit-time leaked CanvasItem/ObjectDB warnings.
- MCP interaction server may log normal startup/shutdown messages during headless smoke.
- These warnings did not block the process exit or scene load.

## Worktree Notes

- The scene file already contained a large dirty diff for placed Milestone A authorables before this handoff. This report documents the targeted bridge, teleport target, spawn, test, and README follow-up changes only.
- Existing unrelated dirty files, deleted generated reports under `reports/report_49` through `reports/report_51`, untracked `docs/How to Use/`, and generated `reports/report_69` through `reports/report_71` were left untouched.
- Nowledge Mem wrapper access returned `nmem CLI not found`; the local HTTP fallback at `127.0.0.1:14242` was also unreachable, so the memory handoff could not be saved from this environment.

## Grouped-Milestone Mode

This was a narrow debug follow-up, not a grouped milestone. It supports the Milestone A proof mission by making the already-authored scene interactable and spawn-safe without broad architecture changes.
