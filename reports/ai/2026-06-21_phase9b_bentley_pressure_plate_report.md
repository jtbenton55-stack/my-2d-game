# Phase 9B Bentley Pressure Plate Support Report

**Date:** 2026-06-21
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented and validated

## Goal

Allow Bentley to hold a Phase 9B pressure plate by staying on it, so the player can move to the linked power circuit and complete the dev-room proof without temporarily disabling `clear_flag_on_exit`.

## Implementation Summary

- Added `accepted_actor_groups` to `PressurePlateNode`, defaulting to `player` and `bentley`.
- Pressure plates now accept bodies in those groups before falling back to the existing `available_actor_group` check.
- Added a small `CollisionShape2D` to Bentley in `MechanicAuthoringTestRoom.tscn` so plate `body_entered` / `body_exited` signals can detect him.
- Set the dev-room player and Bentley collision masks to `0` while keeping their collision layer on `1`, so pressure plates can detect both bodies but the player and Bentley do not physically stick/push each other.
- Extended the focused Phase 9B test to verify Bentley-group actors can press/release a pressure plate and that the dev-room Bentley has collision.

## Files Changed

- `src/missions/iso/authoring/mechanics/PressurePlateNode.gd`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd`
- `reports/ai/2026-06-21_phase9b_bentley_pressure_plate_report.md`

## Validation

- `python src/tools/editor/phase9_puzzle_side_job_kit/phase9_puzzle_side_job_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/Phase9BPowerPuzzleNodeTest.gd"` passed `6/6` after the Bentley collision-mask fix.
- `.\\Godot_v4.6.2-stable_win64.exe\\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded and exited cleanly with the known MCP port bind warning.

## Cleanup

- Removed GdUnit-generated `reports/report_50` from this run.
- Restored tracked report folders `reports/report_26` through `reports/report_30` after GdUnit pruned them.
- Left pre-existing unrelated dirty files and pre-existing `reports/report_23` through `reports/report_25` deletions untouched.

## Manual QA

- Reload `MechanicAuthoringTestRoom.tscn`.
- Lead Bentley onto `9B: Pressure plate`.
- Press `4` while Bentley is on the plate to make him stay.
- Expected: Bentley stays in place and the pressure plate remains `PRESSED` while the player walks away.
- Trigger the timed switch, then press `E` at the power circuit.
- Expected: circuit becomes `POWERED` while Bentley is holding the plate and the switch is still active.
