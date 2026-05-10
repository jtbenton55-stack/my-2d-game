# 0M-D1B-RT2 — Hideout + MissionBoard (Phase 4)

## GRB session (tier 2)

1. Fresh launch showed `MainMenu.tscn` in `grb_runtime_info`.
2. `SceneManager.change_scene("res://scenes/hideout/HideoutHub.tscn")` — **HideoutHub** active (`HideoutHubRoot`).
3. `HideoutManager.open_station("mission_board")` — station panel flow.
4. `MissionBoardPanel.visible` — **true** (`/root/HideoutHubRoot/UI/MissionBoardPanel`).

## Taco entry path (documented)

Canonical Taco was loaded via **direct** calls (not MissionBoard button clicks):

- `GameState.start_mission("taco_bell_drop")`
- `SceneManager.change_scene("res://scenes/missions_iso/TacoBellIso_Editable.tscn")`

This avoids GRB UI automation limits while still proving **canonical** scene reachability.

## Code alignment (this pass)

`HideoutMissionBoardController` and `HideoutStationCatalog` now set `TACO_BELL_SCENE` to **`TacoBellIso_Editable.tscn`**, matching D1B canonical documentation and `SceneManager` routing.
