# 0M-D5-00 — Phase 1: Launch verification

## Tools

- **GRB** `grb_launch` / `grb_reset` (tier 2), `grb_runtime_info`, `grb_press_button`, `grb_call_method`, `grb_get_errors`.

## Results

| # | Item | Evidence level | Result |
|---|------|----------------|--------|
| 1 | Project launches | VERIFIED_RUNTIME | Godot 4.6.2; `grb_runtime_info` returned FPS, engine version. |
| 2 | MainMenu | VERIFIED_RUNTIME | `current_scene` = `res://scenes/MainMenu.tscn`; scene tree shows `NewGameButton`. |
| 3 | HideoutHub after New Game | VERIFIED_RUNTIME | After `NewGameButton`, `current_scene` = `res://scenes/hideout/HideoutHub.tscn`. |
| 4 | MissionBoard path | PARTIAL_RUNTIME | **Primary path:** teleported player near `MissionBoard` Area2D (tier-2 `grb_set_property`), sent `interact` — `ScrollableStationPanel` and `MissionBoardPanel` became **visible** (tier-2 `grb_get_property`). **Launch:** `HideoutMissionBoardController.launch_taco_bell()` via `grb_call_method` (same code path as panel button `launch_taco_bell` in `HideoutMissionBoardController.gd`). |
| 5 | Taco scene path | VERIFIED_RUNTIME | `grb_runtime_info.current_scene` = `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`. |
| 6 | Not legacy Editable | VERIFIED_RUNTIME | Path does **not** equal `TacoBellIso_Editable.tscn` (no `RedesignTest` suffix missing). |
| 7 | Player node | VERIFIED_RUNTIME | `grb_find_nodes` → `/root/TacoBellIso_Editable/EntityRoot/Player` (`CharacterBody2D`). |
| 8 | Bentley / dog companion | VERIFIED_RUNTIME | `DogCompanion` at `/root/TacoBellIso_Editable/EntityRoot/DogCompanion` (`CharacterBody2D`, group `bentley`). |
| 9 | Debugger errors on launch | PARTIAL_RUNTIME | After entering HideoutHub, `grb_get_errors` reported **11** engine errors (tileset / empty image / deferred `add_child`) — **not** GRB-specific; logged from game. |

## Notes

- Runtime root node name is `TacoBellIso_Editable` while **file** is `TacoBellIso_Editable_RedesignTest.tscn` — `scene_file_path` on root confirmed RedesignTest resource (`grb_get_property` … `scene_file_path`).
