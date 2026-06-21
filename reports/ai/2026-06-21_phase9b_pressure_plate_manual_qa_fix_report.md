# Phase 9B Pressure Plate Manual QA Fix Report

**Date:** 2026-06-21
**Branch:** `new-feature-roadmap-branch`
**Status:** Fixed and validated

## Issue

Manual QA found that the Phase 9B pressure plate in `MechanicAuthoringTestRoom.tscn` could not be pressed. Pressing `E` near the plate also triggered the timed switch from too far away, which blocked practical testing of the linked power circuit proof.

## Root Cause

- The dev-room `Player` was a plain `Node2D`, so the `PressurePlateNode` could not receive `body_entered` / `body_exited` events.
- The dev-room `MissionInteractionBridge.interaction_radius` was broad enough for nearby Phase 9B nodes to steal `E` interactions across the vertical proof-node stack.
- The timed switch proof position was corrected to the documented QA position near `Vector2(520, -112)`.

## Fix

- Changed the dev-room `Player` to a `CharacterBody2D` and added a small `CollisionShape2D` so pressure plates can detect player occupancy.
- Reduced `MissionInteractionBridge.interaction_radius` in the dev room from `220.0` to `96.0` so nearby proof nodes do not steal interactions.
- Added focused Phase 9B test assertions that the dev-room player has collision, the bridge radius is below the node spacing, and the timed switch is at the expected QA position.

## Files Changed

- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd`
- `reports/ai/2026-06-21_phase9b_pressure_plate_manual_qa_fix_report.md`

## Validation

- `python src/tools/editor/phase9_puzzle_side_job_kit/phase9_puzzle_side_job_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd"` passed `5/5`.
- `.\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded and exited cleanly.

## Cleanup

- Removed GdUnit-generated `reports/report_50` from this run.
- Restored tracked report folders `reports/report_26` through `reports/report_30` after GdUnit pruned them.
- Left pre-existing unrelated dirty files and pre-existing `reports/report_23` through `reports/report_25` deletions untouched.

## Manual QA Retry

- Reopen or reload `MechanicAuthoringTestRoom.tscn` before retesting.
- Step onto `9B: Pressure plate`; expected label: `PLATE` -> `PRESSED`.
- Step off; expected label: `PRESSED` -> `PLATE`.
- Pressing `E` at the plate should no longer trigger the timed switch from across the proof stack.
- Use the temporary `clear_flag_on_exit = false` workaround to test the full circuit proof as before.
