# 0M-D2 — Mission scene resolver

- **`MissionSceneResolver.gd`:** `class_name MissionSceneResolver`, not autoload. Implements required API; `taco_bell_drop` playable path → **RedesignTest**; roles include legacy iso + classic story room constants.
- **Call sites updated:** `HideoutMissionBoardController`, `HideoutStationCatalog` missions catalog slot 0, `SceneManager.start_mission` + pending-mission path equality, `IsoMissionDebugPanel._on_restart`.
- **GameState:** `mission_catalog` unchanged (classic `TacoBellMission.tscn` remains catalog data for taco where applicable).

See `phase0md2_mission_scene_resolver.json` for assertion flags.
