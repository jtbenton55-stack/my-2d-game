# Hideout Phase 0M-A4 Interaction, Collision, And Greenhouse Repair

Status: PARTIAL

0M-A4 focused on the reported playability failures after 0M-A3. It fixes the dead interaction root cause, adds a hideout-local E-interaction bridge, repairs MissionBoard launch to the frozen Taco Bell scene, replaces loose boundary strips with edge-following outer collision, enlarges the north greenhouse, moves The Big Case inward/south, and preserves the data-driven Monogon-ready scaffold.

Status remains PARTIAL until manual playtest confirms the new boundary collision blocks every outer edge during real movement. Runtime validation confirmed E interaction opens MissionBoard, MissionBoard launches the frozen Taco Bell scene, Louis can open a panel when unlocked and nearby, hidden panel no longer blocks input, and BoundaryWalls has 17 edge shapes.

## 1. Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0ma4_backup.20260506_235451.tscn`
- `hideout_scene_backed_up`: true

## 2. Files Created

- `res://scenes/hideout/HideoutHub.phase0ma4_backup.20260506_235451.tscn`
- `res://src/hideout/HideoutInteractionBridge.gd`
- `res://src/tools/editor/HideoutPhase0MA4Validator.gd`
- `res://docs/reports/hideout_phase_0ma4_interaction_collision_greenhouse_repair.md`
- `res://docs/reports/hideout_phase_0ma4_interaction_collision_greenhouse_repair.json`

## 3. Files Modified

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/hideout/ScrollableStationPanel.gd`
- `res://src/hideout/HideoutInteractable.gd`
- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutMissionBoardController.gd`

Shared scripts modified: none.

Taco Bell scenes modified: no.

## 4. Baseline Audit

Baseline git status was recorded before changes. The scoped status did not list either Taco Bell scene:

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://scenes/missions_iso/TacoBellIso_Editable.tscn`

Scene paths inspected:

- `HideoutHubRoot`
- `GameplayRoot`
- `ArtRoot`
- `GameplayRoot/Characters/Player`
- `UI/ScrollableStationPanel`
- `UI/InteractionPrompt`
- `GameplayRoot/Stations/MissionBoard`
- `GameplayRoot/Managers/HideoutManager`
- `GameplayRoot/Managers/HideoutMissionBoardController`
- `GameplayRoot/Navigation/Collision`
- `GameplayRoot/Stations/EvidenceBoard_TheBigCase`
- greenhouse visuals under generated `ArtRoot/World/WallLayer/GreenhouseAlcoveGlass`

Assertions: hideout_scene_backed_up=true; Taco_Bell_scenes_not_modified_before=true; Player_interaction_contract_recorded=true; hideout_interactable_inventory_recorded=true; collision_baseline_recorded=true.

## 5. Interaction Root Cause Findings

Primary failure mode: `ScrollableStationPanel.gd` added itself to the `blocking_ui` group in `_ready()` and then hid itself. `Player.gd` checks `get_tree().get_nodes_in_group("blocking_ui").size() > 0` before trying world interaction, so the hidden panel permanently caused `Player.gd` to skip `_try_interact()`. That explains why pressing E opened nothing even though station nodes existed.

Secondary risks:

- Player native interaction radius is hard-coded at 72 px.
- Wall-mounted visual station origins can be too far from reachable standing positions.
- MissionBoard button text did not expose a clear "Start The Taco Bell Drop" action.

Fixes:

- `ScrollableStationPanel` now only joins `blocking_ui` while visible/open, and removes itself when closed.
- `HideoutInteractable` now supports station IDs, safe optional methods, fallback panel routing, and 144 px availability for the bridge.
- `HideoutInteractionBridge` provides a hideout-local 144 px fallback for E.
- Station proxy positions were adjusted to user-provided 0M-A4 targets.

Assertions: interaction_root_cause_audited=true; interaction_failure_mode_reported=true.

## 6. Player.gd Interaction Contract

`Player.gd`:

- uses action `interact`
- calls `_try_interact()` from `_physics_process` when not in dialogue and when world interaction is not skipped
- skips interaction if any node is in group `blocking_ui`
- scans `get_tree().get_nodes_in_group("interactable")`
- requires candidate to be `Node2D`
- requires candidate to have `interact`
- calls optional `is_interaction_available(player)`
- calls optional `should_show_interaction_prompt()`
- filters by `global_position.distance_to(node.global_position) < 72.0`
- sorts using optional `get_interaction_priority(player)`
- checks optional `is_completed()`
- does not require Area2D overlap for E interaction; distance-to-node is sufficient

## 7. HideoutInteractable Repair Summary

`HideoutInteractable.gd` now:

- adds itself to `interactable`
- adds itself to `hideout_interactable`
- implements `interact(player)`
- exports `station_id`, `interactable_id`, display/panel fields, `interaction_priority`, state flags, and `disabled`
- returns false when hidden or disabled
- routes through `HideoutManager.open_station(station_id)`
- falls back to `UI/ScrollableStationPanel.open_panel()` if no manager is found
- warns clearly rather than crashing if no route exists

Assertions: HideoutInteractable_in_global_interactable_group=true; HideoutInteractable_in_hideout_interactable_group=true; HideoutInteractable_has_interact_method=true; HideoutInteractable_routes_to_HideoutManager=true; HideoutInteractable_has_safe_fallback=true; HideoutInteractable_does_not_crash_if_manager_missing=true.

## 8. HideoutInteractionBridge Summary

Created: `res://src/hideout/HideoutInteractionBridge.gd`

Attached at: `HideoutHubRoot/GameplayRoot/Managers/HideoutInteractionBridge`

Behavior:

- hideout-only node in `HideoutHub.tscn`
- listens for `interact`
- ignores input while station panel is open
- finds player via exported path, group `player`, or `GameplayRoot/Characters/Player`
- scans only `hideout_interactable`
- uses 144 px radius
- calls nearest `interact(player)`
- prints `[HideoutInteractionBridge] Interacting with <station_id> at distance <d>`

Assertions: HideoutInteractionBridge_script_created=true; HideoutInteractionBridge_node_attached=true; HideoutInteractionBridge_limited_to_HideoutHub=true; HideoutInteractionBridge_uses_hideout_interactable_group=true; HideoutInteractionBridge_calls_interact=true.

## 9. Station Proxy Repair Table

Each station node is the interaction proxy. Visual graybox props remain separate under `ArtRoot/World/PropLayer/Visual_*`.

| station_id | station node path | proxy path | station position | proxy position | interactable | hideout_interactable | has interact | Fresh | Louis Unlocked | panel route | validation | manual |
|---|---|---|---:|---:|---|---|---|---|---|---|---|---|
| entry_exit_door | `GameplayRoot/Stations/EntryExitDoor` | same | `(760,430)` | `(700,390)` | yes | yes | yes | yes | yes | generic panel | static | yes |
| bentley_care_station | `GameplayRoot/Stations/BentleyCareStation` | same | `(520,330)` | `(500,390)` | yes | yes | yes | yes | yes | care controller | static | yes |
| loot_crate_drop_zone | `GameplayRoot/Stations/LootCrateDropZone` | same | `(210,350)` | `(210,300)` | yes | yes | yes | yes | yes | generic panel | static | yes |
| bentley | `GameplayRoot/Stations/Bentley` | same | `(-760,350)` | `(-720,350)` | yes | yes | yes | yes | yes | character controller | static | yes |
| jake | `GameplayRoot/Stations/Jake` | same | `(-560,300)` | `(-520,300)` | yes | yes | yes | yes | yes | character controller | static | yes |
| mere | `GameplayRoot/Stations/Mere` | same | `(-420,300)` | `(-380,300)` | yes | yes | yes | yes | yes | character controller | static | yes |
| mission_board | `GameplayRoot/Stations/MissionBoard` | same | `(520,-410)` | `(500,-340)` | yes | yes | yes | yes | yes | mission controller | runtime open confirmed | no |
| evidence_board_big_case | `GameplayRoot/Stations/EvidenceBoard_TheBigCase` | same | `(0,-405)` | `(0,-330)` | yes | yes | yes | yes | yes | evidence controller | static | yes |
| planning_table | `GameplayRoot/Stations/PlanningTable` | same | `(0,20)` | `(0,120)` | yes | yes | yes | yes | yes | scheme controller | static | yes |
| polaroid_wall | `GameplayRoot/Stations/PolaroidWall` | same | `(-850,-230)` | `(-760,-230)` | yes | yes | yes | yes | yes | collectible controller | static | yes |
| glow_guy_shelf | `GameplayRoot/Stations/GlowGuyShelf` | same | `(-880,-40)` | `(-780,-40)` | yes | yes | yes | yes | yes | collectible controller | static | yes |
| tiny_icon_shelf | `GameplayRoot/Stations/TinyIconShelf` | same | `(-880,110)` | `(-780,110)` | yes | yes | yes | yes | yes | collectible controller | static | yes |
| poop_bag_care_display | `GameplayRoot/Stations/PoopBagCareDisplay` | same | `(-840,250)` | `(-750,250)` | yes | yes | yes | yes | yes | collectible controller | static | yes |
| store_terminal | `GameplayRoot/Stations/StoreTerminal` | same | `(790,-80)` | `(710,-80)` | yes | yes | yes | yes | yes | store controller | static | yes |
| open_decor_zone | `GameplayRoot/Stations/OpenDecorZone` | same | `(470,120)` | `(470,120)` | yes | yes | yes | yes | yes | generic panel | static | yes |
| heat_scanner | `GameplayRoot/Stations/HeatScanner` | same | `(650,-260)` | `(620,-220)` | yes | yes | yes | yes | yes | generic panel | static | yes |
| louis | `GameplayRoot/Stations/Louis` | same | `(820,130)` | `(760,130)` | yes | yes | yes | no | yes | character controller | runtime unlocked open confirmed | no |
| test_interactable | `GameplayRoot/Stations/TestInteractable` | same | `(320,255)` | `(320,205)` | yes | yes | yes | yes | yes | generic panel | static | yes |

Assertions: all_required_station_proxies_exist=true; all_required_station_proxies_have_station_id=true; all_required_station_proxies_in_global_interactable_group=true; all_required_station_proxies_in_hideout_interactable_group=true; all_required_station_proxies_have_interact_method=true; all_required_station_proxies_have_panel_title_body=true.

## 10. Scrollable Panel Repair Summary

- `blocking_ui` is now added only on open.
- `blocking_ui` is removed on close.
- `close_panel()` alias was added.
- `open_panel(title, body, buttons)` remains.
- Runtime confirmed `open_station("mission_board")` opens the panel.
- Runtime confirmed closing the panel removes `blocking_ui`.

Assertions: HideoutManager_open_station_exists=true; HideoutManager_can_open_generic_station=true; ScrollableStationPanel_open_method_exists=true; ScrollableStationPanel_close_method_exists=true; ScrollableStationPanel_visible_when_opened=true; ScrollableStationPanel_hidden_when_closed=true.

## 11. MissionBoard Launch Repair Summary

- Button label is now `Start The Taco Bell Drop`.
- Action key is handled as `start_the_taco_bell_drop`.
- Launch path remains exactly `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Launch uses `SceneManager.change_scene()` when available, falling back to `get_tree().change_scene_to_file()`.
- Runtime confirmed the start action changed `current_scene.scene_file_path` to the frozen Taco Bell scene.

Assertions: MissionBoard_interactable_opens_panel=true; MissionBoard_has_11_missions=true; Taco_Bell_StartMission_action_exists=true; Taco_Bell_launch_function_exists=true; Taco_Bell_launch_path_exact=true; Taco_Bell_scenes_not_modified=true.

## 12. Collision Repair Summary

- Boundary path: `HideoutHubRoot/GameplayRoot/Navigation/Collision/BoundaryWalls`
- Method: generated `StaticBody2D` with one rotated `RectangleShape2D` per floor polygon edge.
- Shape count: 17.
- Thickness: 64 px.
- Corner overlap margin: 48 px.

Polygon points used:

`(-960,-250)`, `(-820,-430)`, `(-500,-430)`, `(-430,-690)`, `(430,-690)`, `(500,-430)`, `(790,-430)`, `(960,-260)`, `(960,340)`, `(800,500)`, `(470,500)`, `(330,420)`, `(-360,420)`, `(-500,520)`, `(-900,520)`, `(-1040,360)`, `(-1040,-120)`.

Assertions: BoundaryWalls_exists=true; BoundaryWalls_shape_count_reasonable=true; collision_follows_outer_floor_edges=true; collision_has_corner_overlap=true; no_collision_strip_cuts_across_walkable_interior=true; player_spawn_not_inside_collision=manual_check_required; station_proxies_not_inside_collision=manual_check_required.

## 13. Greenhouse Adjustment Summary

- Old greenhouse top y: approximately `-610`.
- New greenhouse top y: approximately `-690`.
- Greenhouse glass band moved north to `(0, -635)`.
- The Big Case old position: `(0, -455)`.
- The Big Case new position: `(0, -405)`.
- The Big Case proxy new position: `(0, -330)`.
- MissionBoard remains northeast.

Assertions: greenhouse_alcove_expanded_north=true; greenhouse_walkable_area_created=true; BigCase_moved_south_inward=true; BigCase_still_center_north=true; greenhouse_not_blocked_by_collision=manual_check_required.

## 14. Louis Interaction Debug State Summary

- Fresh: Louis proxy and visual hidden by `apply_debug_state("fresh")`.
- Fresh interaction: disabled by hidden node availability.
- Louis Unlocked: Louis proxy and visual visible.
- Runtime confirmed E near Louis opens the station panel after `louis_unlocked`.

Assertions: Louis_hidden_fresh=true; Louis_interaction_disabled_fresh=true; Louis_visible_unlocked=true; Louis_proxy_enabled_unlocked=true; Louis_interactable_unlocked=true.

## 15. Validator Results

Created: `res://src/tools/editor/HideoutPhase0MA4Validator.gd`

Runtime/static validation:

- HideoutHub scene change returned OK.
- Hidden panel `blocking_ui` count after load: 0.
- Hideout interactables: 18.
- `HideoutInteractionBridge` exists: true.
- `BoundaryWalls` shape count: 17.
- MissionBoard is in `interactable`: true.
- MissionBoard has `interact`: true.
- MissionBoard panel opens through `HideoutManager`: true.
- Panel close removes `blocking_ui`: true.
- MissionBoard start action launches frozen Taco Bell: true.
- Louis unlocked interaction opens panel: true.
- Lints: clean for edited hideout files and validator.

Known runtime noise: the Godot Runtime Bridge logs `McpInteractionServer: Failed to listen on port 9090, error: 22` when another bridge/server instance already owns that port. HideoutHub-specific validation still proceeded.

## 16. Known Placeholders

- Graybox visuals only.
- No Monogon art.
- No store economy.
- No drag/drop decoration.
- No real scheme-card gameplay effects.
- Boundary collision still needs manual edge-walk playtest.

## 17. Risks / Fragile Areas

- Native `Player.gd` still has a hard 72 px filter; the bridge covers a wider 144 px radius for hideout-only E interactions.
- Boundary walls follow edges with thick rectangles; manual playtest should confirm there are no corner snags or interior clipping.
- Runtime-generated station nodes are not serialized as child nodes in the editor before play.
- `SceneManager.HIDEOUT_SCENE` still points to the older hideout scene; this pass did not modify shared scene management.

## 18. Manual Playtest Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Press Play.
3. Confirm player is visible above floor.
4. Confirm player movement works.
5. Try to walk through every outer wall/edge.
6. Confirm player cannot slip through the sides.
7. Walk into greenhouse alcove.
8. Confirm greenhouse is larger and walkable.
9. Confirm The Big Case wall is still north/center but moved inward enough to walk around.
10. Walk to Entry/Exit and press E.
11. Walk to Bentley Care Station and press E.
12. Walk to Loot Crate Drop and press E.
13. Walk to Bentley and press E.
14. Walk to Jake and press E.
15. Walk to Mere and press E.
16. Walk to MissionBoard and press E.
17. Press Start The Taco Bell Drop.
18. Confirm `TacoBellIso_Editable_RedesignTest.tscn` launches.
19. Reopen HideoutHub.
20. Walk to The Big Case and press E.
21. Walk to Planning Table and press E.
22. Walk to Polaroid Wall and press E.
23. Walk to Glow Guy Shelf and press E.
24. Walk to Tiny Icon Shelf and press E.
25. Walk to Poop Bag Display and press E.
26. Walk to Store Terminal and press E.
27. Walk to Open Decor Area and press E.
28. Walk to Heat Scanner and press E.
29. Toggle Louis Unlocked.
30. Confirm Louis appears near store.
31. Press E near Louis.
32. Toggle Fresh.
33. Confirm Louis hides.
34. Confirm panels scroll and close.
35. Confirm no Taco Bell scene was modified.

## 19. Recommended Next Step

If manual playtest passes: 0M-B - Hideout visual dressing / Monogon-style prop pass.

If manual playtest fails: 0M-A5 - focused fix for the specific failed interaction/collision issue.
