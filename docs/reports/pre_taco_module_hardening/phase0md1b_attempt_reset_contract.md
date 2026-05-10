# Attempt reset contract (0M-D1B)

## Current pipeline (verified by code read)

1. **Mission start / relaunch from hideout:** `SceneManager.start_mission` → `change_scene` → new mission scene → `IsoMissionBase._ready` → `_generate_from_definition` → `_setup_runtime_systems` → `_reset_attempt_runtime_state` + cleared runtime buckets.

2. **Death / fail:** `LevelBase._on_player_died` → `fail_level` → mission result scene → hideout → next mission start reloads scene (no long-lived `IsoMissionBase` instance).

3. **Future in-scene retry:** call `reset_mission_runtime_for_new_attempt()` (wraps `_setup_runtime_systems`) — use only when the mission node persists across retries.

## Not done here

Full Godot playtest of beam twice across two attempts (no editor runtime in this environment).
