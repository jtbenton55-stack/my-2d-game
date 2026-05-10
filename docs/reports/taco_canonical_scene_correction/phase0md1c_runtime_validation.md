# 0M-D1C — Runtime / GRB validation (Phase 5)

## Session

Used **Godot Runtime Bridge** (`grb_reset` tier **2**) with programmatic calls (no manual clicks).

## Steps

1. Load **HideoutHub** via `SceneManager.change_scene`.
2. Open **MissionBoard** station via `HideoutManager.open_station("mission_board")`.
3. Call **`HideoutMissionBoardController.launch_taco_bell()`** (same code path as panel action).

## Result

`grb_runtime_info`:

- **`current_scene`:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` (**expanded**)
- **Not** `…TacoBellIso_Editable.tscn` (legacy smaller file)

## Player

`grb_find_nodes` located **`Player`** under `/root/TacoBellIso_Editable/EntityRoot/Player` (root node name matches both scenes; path string confirms **RedesignTest** file).

## Out of scope

Movement, pause menu, and full regression playtest were **not** repeated here (emergency routing only).
