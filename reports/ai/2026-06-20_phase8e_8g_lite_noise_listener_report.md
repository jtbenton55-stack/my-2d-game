# Phase 8E-8G-lite Noise Listener Report

**Date:** 2026-06-20
**Branch:** `new-feature-roadmap-branch`
**Status:** Implemented and validated

## Goal

Extend the Phase 8A-8D-lite noise/distraction foundation (`NoiseEvent`, `NoiseEmitterNode`, and `DistractionObject`) with a mission-local listener component, simple guard/NPC/debug reaction metadata, and a bridge from the existing poop-bag decoy point into the shared `NoiseEvent` path without adding a global noise manager or changing production Taco placement.

## Files Changed

- `src/missions/iso/runtime/noise/NoiseListenerComponent.gd`
- `src/missions/iso/runtime/noise/NoiseListenerComponent.gd.uid`
- `src/missions/iso/runtime/MissionPoopBagDecoyPoint.gd`
- `scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn`
- `tests/mission_authoring/NoiseDistractionTest.gd`
- `src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py`
- `docs/PLUG_AND_PLAY_MISSION_SYSTEM_ROADMAP.md`
- `docs/PLUG_AND_PLAY_IMPLEMENTATION_BLUEPRINT.md`
- `docs/MECHANIC_AUTHORING_FOUNDATION_GUIDE.md`
- `reports/ai/2026-06-20_phase8e_8g_lite_noise_listener_report.md`

## Implementation Summary

- Phase 8E-lite: added `NoiseListenerComponent`, a mission-local component that subscribes to `EventBus.mission_noise_emitted`, filters events by radius/kind/team, records heard noise, sets lightweight debug metadata on its parent, emits `noise_heard`, and optionally calls parent `on_noise_heard(noise_event, listener)`.
- Phase 8F-lite: extended the dev authoring room with a `Phase8E_NoiseListenerGuard` proof node and focused GdUnit coverage for in-range and out-of-range listener behavior.
- Phase 8G-lite: bridged `MissionPoopBagDecoyPoint` into the same `NoiseEvent` path after successful poop-bag consumption, routing to `EventBus`, `MissionAlertController`, and active listeners.

## Protected Scope

- No production Taco scene changes.
- No new global noise manager or autoload.
- No full guard pathing, investigation movement, or behavior-tree rewrite.
- Existing poop-bag inventory remains authoritative in `GameState`; no duplicate inventory state was added.

## Validation

- `python src/tools/editor/phase8_noise_distraction/phase8_noise_distraction_validator.py` passed.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring/NoiseDistractionTest.gd"` passed `8/8`.
- `addons/gdUnit4/runtest.cmd --godot_binary ".\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe" -a "res://tests/mission_authoring"` passed `217/217` in `16min 26s`.
- `.\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe --headless --path "." --quit-after 1 "res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn"` loaded the dev proof scene and exited cleanly. Existing MCP port warning appeared.
- `git diff --check` passed with only the existing CRLF warning for `docs/reports/phase8_noise_distraction/phase8_noise_distraction_validator_run.json`.

## Risks / Follow-Ups

- `NoiseListenerComponent` intentionally records and exposes reactions but does not move guards toward noise yet.
- Parent `on_noise_heard()` callbacks are optional and not required by the current guard scripts.
- Production mission placement remains deferred until a designed stealth/noise encounter needs it.
