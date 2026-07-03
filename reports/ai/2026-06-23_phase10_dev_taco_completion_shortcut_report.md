# Phase 10 Dev Taco Completion Shortcut Report

Date: 2026-06-23

## Summary

Added a debug-build-only Mission Board shortcut, `DEV: Mark Taco Bell Complete`, so Phase 10 hideout reward QA can exercise the real `GameState.complete_mission("taco_bell_drop")` completion path without replaying the full Taco mission.

The shortcut is intentionally a QA helper. It does not edit Taco production scenes, does not add save schema, and does not replace the normal mission completion flow.

## Files Changed

- `src/hideout/HideoutMissionBoardController.gd`
- `src/hideout/HideoutManager.gd`
- `tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd`
- `src/tools/editor/phase10_hideout_rewards/phase10_hideout_rewards_validator.py`
- `reports/ai/2026-06-23_phase10_dev_taco_completion_shortcut_report.md`

## Implementation Notes

- `HideoutMissionBoardController.get_buttons()` now adds `DEV: Mark Taco Bell Complete` only when `OS.is_debug_build()` is true and Taco is not already completed.
- `HideoutManager` handles `dev_mark_taco_bell_complete` by calling `GameState.complete_mission("taco_bell_drop")`, then immediately applying `HideoutRewardAdapter.apply_completed_mission_rewards_to_state(_state, "taco_bell_drop")`.
- Hideout visuals are refreshed from actual state fields so Louis/reward visuals can update after adapter-driven reward sync, not only after visual debug states.
- Focused tests now cover the shortcut's `GameState` completion path and debug-only Mission Board button exposure.

## Validation

- `python src/tools/editor/phase10_hideout_rewards/phase10_hideout_rewards_validator.py`: PASS.
- Focused GdUnit `tests/mission_authoring/Phase10HideoutRewardAdapterTest.gd`: PASS, 6/6.
- `git diff --check`: PASS.
- Headless HideoutHub smoke was attempted. The scene loaded far enough to parse the modified scripts but still reports the known pre-existing `HideoutManager._ensure_dialogue_box()` add-child timing error and shutdown leak/orphan warnings in headless mode.

## Manual QA

- Open `res://scenes/hideout/HideoutHub.tscn` in a debug/editor run.
- Interact with the Mission Board.
- On a fresh Taco state, click `DEV: Mark Taco Bell Complete`.
- Confirm the Mission Board refreshes to completed/replayable state.
- Confirm Phase 10 rewards are visible in hideout state: Louis visible/unlocked, `louis_delivery_route` unlocked, Taco store/decor items available, sauce-paw cleanup available, Taco collectible/trophy displays marked, and case cash at least 150.

## Risks / Follow-Ups

- The shortcut is debug-only and should not be treated as player-facing progression.
- Live manual QA is still needed because headless HideoutHub validation is blocked by an existing dialogue-box setup issue.
- Phase 9I Taco side-job signoff remains a separate manual QA target.
