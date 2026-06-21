# Phase 8H-lite Noise Guard Response Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented and validated

## Goal

Extend the Phase 8A-8D-lite `NoiseEmitterNode` / `DistractionObject` foundation and the Phase 8E-8G-lite `NoiseListenerComponent` bridge with a small guard/debug response proof that records investigation state without adding full pathing AI, a global noise manager, or production Taco placement.

## Files Changed

- `src/missions/iso/runtime/noise/NoiseReactiveGuard.gd`
- `src/missions/iso/runtime/noise/NoiseReactiveGuard.gd.uid`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/NoiseDistractionTest.gd`
- `src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase8h_lite_noise_guard_response_report.md`

## Implementation Summary

- Added `NoiseReactiveGuard`, a lightweight `Node2D` receiver that implements `on_noise_heard(noise_event, listener)`.
- The receiver records `investigating_noise` state, `investigate_position`, reaction expiry time, reaction count, last noise event, and readable metadata.
- The receiver can optionally face the noise source but does not move or path toward it.
- The dev authoring room now attaches `NoiseReactiveGuard` to the Phase 8 listener guard proof.
- Focused tests cover the listener-to-parent callback path and dev-room proof wiring.

## Protected Scope

- No production Taco scene changes.
- No global noise manager or autoload.
- No full pathfinding, patrol interruption, chase behavior, or behavior-tree rewrite.
- Existing alert and poop-bag systems remain authoritative.

## Validation

- `python src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/NoiseDistractionTest.gd"` passed `9/9`.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `218/218` in `16min 54s`.
- `.\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded the dev proof scene and exited cleanly. Existing MCP port warning appeared.
- `git diff --check` passed with only the existing CRLF warning for `docs/reports/phase8_noise_distraction/phase8_noise_distraction_validator_run.json`.

## Risks / Follow-Ups

- Guard response is debug/state-only; it does not move guards toward noise yet.
- Production mission placement remains deferred until a designed stealth/noise encounter needs it.
