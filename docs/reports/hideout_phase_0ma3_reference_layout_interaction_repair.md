# Hideout Phase 0M-A3 Reference Layout, Layering, And Interaction Repair

Status: PARTIAL

This pass repaired the Phase 0M-A HideoutHub scaffold without touching Taco Bell. The graybox layout now follows the provided reference image topology more closely, the player/character layer is explicitly above floor and prop layers, and station origins now act as interaction proxies placed at reachable standing spots within `Player.gd`'s 72 px interaction range.

Status remains PARTIAL until a manual Godot playtest confirms every station can be reached by walking and pressing E. Runtime validation confirmed scene load, no HideoutHub parse/script errors, 18 hideout interactables, player z-index above the floor, station group/method contract, panel open/close, and Louis hidden/unlocked behavior.

## 1. Reference Image

- Found: yes
- Path: `res://docs/reference/hideout_hub_layout_reference.png`
- Runtime dependency: no
- Scene texture use: no
- `.gdignore`: created at `res://docs/reference/.gdignore` so the reference folder does not become imported runtime art.

## 2. Backup

- Backup path: `res://scenes/hideout/HideoutHub.phase0ma3_backup.20260506_232103.tscn`
- `hideout_scene_backed_up`: true

## 3. Baseline Summary

- Baseline git status recorded before changes.
- Taco Bell scene status before this pass: not listed in scoped git status.
- Current HideoutHub was untracked from the previous 0M-A scaffold.
- Baseline player path: `HideoutHubRoot/GameplayRoot/Characters/Player`
- Baseline structure had `GameplayRoot`, `ArtRoot/World`, and `UI`.
- Baseline interactable count from runtime: 18.
- Baseline required station entries: 18 including retained `test_interactable`.

## 4. Files Created

- `res://scenes/hideout/HideoutHub.phase0ma3_backup.20260506_232103.tscn`
- `res://docs/reference/.gdignore`
- `res://src/tools/editor/HideoutPhase0MA3Validator.gd`
- `res://docs/reports/hideout_phase_0ma3_reference_layout_interaction_repair.md`
- `res://docs/reports/hideout_phase_0ma3_reference_layout_interaction_repair.json`

## 5. Files Modified

- `res://scenes/hideout/HideoutHub.tscn`
- `res://src/hideout/HideoutStationCatalog.gd`
- `res://src/hideout/HideoutManager.gd`
- `res://src/hideout/HideoutInteractable.gd`

Shared scripts modified: none.

Taco Bell scenes modified: no.

## 6. Layout Changes Made

- Replaced the prior simple floor polygon with the requested 17-point irregular rooftop garage / greenhouse polygon.
- Repositioned all station catalog entries to reference-image topology.
- Split visual station positions from interaction proxy positions through `position` and `proxy_position` catalog fields.
- Rebuilt graybox visual layers deterministically at runtime under `ArtRoot/World`.
- Added greenhouse glass band, cozy lounge rug/bed placeholders, central scheme-card slot placeholder, open-decor outline, and circulation path.
- Rebuilt collision and walkable polygon around the new silhouette.

## 7. Floor Shape Summary

The floor is now an irregular polygon using these points:

`(-960,-250)`, `(-820,-430)`, `(-470,-430)`, `(-390,-610)`, `(390,-610)`, `(470,-430)`, `(790,-430)`, `(960,-260)`, `(960,340)`, `(800,500)`, `(470,500)`, `(330,420)`, `(-360,420)`, `(-500,520)`, `(-900,520)`, `(-1040,360)`, `(-1040,-120)`.

Assertions: floor_shape_is_irregular=true; floor_shape_matches_reference_topology=true; greenhouse_alcove_north_exists=true; southwest_cozy_nook_exists=true; southeast_entry_care_corner_exists=true; center_open_floor_exists=true; floor_shape_not_plain_rectangle=true.

## 8. Station Coordinate Table

| Station | Visual Position | Interaction Proxy Position | Topology |
|---|---:|---:|---|
| EntryExitDoor | `(760, 430)` | `(720, 390)` | southeast corner |
| BentleyCareStation | `(520, 330)` | `(505, 285)` | beside entry |
| LootCrateDropZone | `(210, 350)` | `(210, 285)` | south center |
| Bentley | `(-760, 350)` | `(-710, 345)` | southwest lounge |
| Jake | `(-560, 300)` | `(-525, 265)` | southwest lounge |
| Mere | `(-420, 300)` | `(-455, 265)` | southwest lounge |
| Louis | `(820, 130)` | `(780, 120)` | east/southeast store nook |
| MissionBoard | `(520, -410)` | `(520, -330)` | northeast |
| EvidenceBoard_TheBigCase | `(0, -455)` | `(0, -370)` | north center |
| PlanningTable | `(0, 20)` | `(0, 120)` | center |
| PolaroidWall | `(-850, -230)` | `(-780, -215)` | west stack |
| GlowGuyShelf | `(-880, -40)` | `(-805, -40)` | west stack |
| TinyIconShelf | `(-880, 110)` | `(-805, 110)` | west stack |
| PoopBagCareDisplay | `(-840, 250)` | `(-765, 250)` | west/southwest stack |
| StoreTerminal | `(790, -80)` | `(720, -70)` | east |
| OpenDecorZone | `(470, 120)` | `(380, 120)` | center/east |
| HeatScanner | `(650, -260)` | `(610, -215)` | near MissionBoard |
| TestInteractable | `(320, 255)` | `(320, 205)` | generic interaction test |

Assertions: evidence_board_center_north=true; mission_board_northeast=true; planning_table_center=true; west_collectibles_vertical_stack=true; cozy_lounge_southwest=true; store_terminal_east=true; Louis_near_store_when_unlocked=true; entry_exit_southeast=true; Bentley_care_station_adjacent_to_entry=true; loot_crate_south_center=true; open_decor_area_center_east=true; all_required_stations_inside_floor=true.

## 9. Zone Topology Validation

- North greenhouse alcove: present via `GreenhouseAlcoveGlass` and top floor notch.
- Big Case north center: `EvidenceBoard_TheBigCase` at `(0, -455)`.
- Mission board northeast: `MissionBoard` at `(520, -410)`.
- Planning table center: `PlanningTable` at `(0, 20)`.
- West collectible stack: Polaroid, Glow Guy, Tiny Icon, and Poop Bag displays arranged vertically on west wall.
- Cozy lounge southwest: Bentley bed, Bentley, Jake, and Mere grouped in southwest nook.
- Store east: `StoreTerminal` at `(790, -80)`, Louis at `(820, 130)` when unlocked.
- Entry/care southeast: `EntryExitDoor` and `BentleyCareStation` grouped in southeast.
- Open decor center/east: `OpenDecorZone` at `(470, 120)`.

## 10. Player Z-Order Table

| Node / Layer | Baseline | Final |
|---|---:|---:|
| `ArtRoot` | unset | `-250` |
| `ArtRoot/World/FloorLayer` | unset | `-300` |
| `ArtRoot/World/WallLayer` | unset | `-200` |
| `ArtRoot/World/PropLayer` | unset | `-100` |
| `ArtRoot/World/DecorationLayer` | unset | `-80` |
| `ArtRoot/World/CollectibleLayer` | unset | `-60` |
| `ArtRoot/World/CharacterVisualLayer` | unset | `10` |
| `ArtRoot/World/ForegroundLayer` | unset | `150` |
| `ArtRoot/World/LightingLayer` | unset | `200` |
| `GameplayRoot/Characters` | unset | `20` |
| `GameplayRoot/Stations` | unset | `25` |
| `GameplayRoot/Characters/Player` | unset | `30` |
| `UI` | `CanvasLayer` | `CanvasLayer` |

Runtime proof: player z-index `30`; floor z-index `-300`.

Assertions: player_node_found=true; player_visible_above_floor=manual_check_required; floor_layer_z_below_player=true; no_full_map_layer_covers_player=true; UI_renders_above_world=true; z_order_table_written_to_report=true.

## 11. Interaction Contract

`Player.gd` contract:

- searches `get_tree().get_nodes_in_group("interactable")`
- requires `node is Node2D`
- requires `node.has_method("interact")`
- calls optional `is_interaction_available(player)`
- calls optional `should_show_interaction_prompt()`
- sorts with optional `get_interaction_priority(player)`
- checks optional `is_completed()`
- requires distance `< 72.0` from `player.global_position` to `node.global_position`
- skips world interaction while `blocking_ui` exists

Hideout repair:

- `HideoutInteractable` remains `Area2D`.
- Every station is in `interactable` and `hideout_interactable`.
- Every station implements `interact(player)`.
- Every station now uses reachable `proxy_position` as its actual node position.
- Visual identity stays in `ArtRoot/World/PropLayer`.
- Station identity stays in catalog/script metadata, not visual tiles.
- `interaction_radius` reduced to 72 to match player behavior.
- Optional prompt/priority/completed methods were added.

Assertions: HideoutInteractable_matches_Player_contract=true; every_required_station_has_interaction_proxy=true; every_required_station_proxy_in_global_interactable_group=true; every_required_station_proxy_has_interact_method=true; every_required_station_proxy_reachable=manual_check_required; every_required_station_opens_panel_or_dialogue=manual_check_required; interaction_does_not_depend_on_visual_tile_identity=true.

## 12. Interaction Repair Table

Each station node is the interaction proxy. The separate graybox visible node lives under `ArtRoot/World/PropLayer/Visual_*`.

| station_id | visible node path | interaction proxy path | station position | proxy position | inside floor | reachable | interactable group | hideout group | has interact | opens panel |
|---|---|---|---:|---:|---|---|---|---|---|---|
| entry_exit_door | `ArtRoot/World/PropLayer/Visual_EntryExitDoor` | `GameplayRoot/Stations/EntryExitDoor` | `(760,430)` | `(720,390)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| bentley_care_station | `ArtRoot/World/PropLayer/Visual_BentleyCareStation` | `GameplayRoot/Stations/BentleyCareStation` | `(520,330)` | `(505,285)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| loot_crate_drop_zone | `ArtRoot/World/PropLayer/Visual_LootCrateDropZone` | `GameplayRoot/Stations/LootCrateDropZone` | `(210,350)` | `(210,285)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| bentley | `ArtRoot/World/PropLayer/Visual_Bentley` | `GameplayRoot/Stations/Bentley` | `(-760,350)` | `(-710,345)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| jake | `ArtRoot/World/PropLayer/Visual_Jake` | `GameplayRoot/Stations/Jake` | `(-560,300)` | `(-525,265)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| mere | `ArtRoot/World/PropLayer/Visual_Mere` | `GameplayRoot/Stations/Mere` | `(-420,300)` | `(-455,265)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| mission_board | `ArtRoot/World/PropLayer/Visual_MissionBoard` | `GameplayRoot/Stations/MissionBoard` | `(520,-410)` | `(520,-330)` | yes | manual_check_required | yes | yes | yes | yes-runtime |
| evidence_board_big_case | `ArtRoot/World/PropLayer/Visual_EvidenceBoard_TheBigCase` | `GameplayRoot/Stations/EvidenceBoard_TheBigCase` | `(0,-455)` | `(0,-370)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| planning_table | `ArtRoot/World/PropLayer/Visual_PlanningTable` | `GameplayRoot/Stations/PlanningTable` | `(0,20)` | `(0,120)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| polaroid_wall | `ArtRoot/World/PropLayer/Visual_PolaroidWall` | `GameplayRoot/Stations/PolaroidWall` | `(-850,-230)` | `(-780,-215)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| glow_guy_shelf | `ArtRoot/World/PropLayer/Visual_GlowGuyShelf` | `GameplayRoot/Stations/GlowGuyShelf` | `(-880,-40)` | `(-805,-40)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| tiny_icon_shelf | `ArtRoot/World/PropLayer/Visual_TinyIconShelf` | `GameplayRoot/Stations/TinyIconShelf` | `(-880,110)` | `(-805,110)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| poop_bag_care_display | `ArtRoot/World/PropLayer/Visual_PoopBagCareDisplay` | `GameplayRoot/Stations/PoopBagCareDisplay` | `(-840,250)` | `(-765,250)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| store_terminal | `ArtRoot/World/PropLayer/Visual_StoreTerminal` | `GameplayRoot/Stations/StoreTerminal` | `(790,-80)` | `(720,-70)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| open_decor_zone | `ArtRoot/World/PropLayer/Visual_OpenDecorZone` | `GameplayRoot/Stations/OpenDecorZone` | `(470,120)` | `(380,120)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| heat_scanner | `ArtRoot/World/PropLayer/Visual_HeatScanner` | `GameplayRoot/Stations/HeatScanner` | `(650,-260)` | `(610,-215)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| louis | `ArtRoot/World/PropLayer/Visual_Louis` | `GameplayRoot/Stations/Louis` | `(820,130)` | `(780,120)` | yes | manual_check_required | yes | yes | yes | manual_check_required |
| test_interactable | `ArtRoot/World/PropLayer/Visual_TestInteractable` | `GameplayRoot/Stations/TestInteractable` | `(320,255)` | `(320,205)` | yes | manual_check_required | yes | yes | yes | manual_check_required |

## 13. Scrollable Panel Validation

- Exists: yes.
- Uses `ScrollContainer`: yes.
- Opens from station manager: yes-runtime.
- Closes: yes-runtime.
- Uses `blocking_ui` while visible and releases when hidden: yes.
- Does not overflow off-screen: manual_check_required.

## 14. Mission Board / Taco Bell Launch

- MissionBoard position: northeast.
- 11 mission slots preserved.
- Taco Bell launch path preserved: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Taco Bell scenes modified: no.
- Route selection: absent.
- Assist selection: absent.
- Fresh heat/difficulty controls: absent.
- Forbidden progression labels: absent.

## 15. Debug State Validation

- Fresh Hideout: Bentley/Jake/Mere present; Louis hidden.
- Taco Bell Completed: visual tint/text updates preserved.
- Taco Bell Completed Missing Items: missing/silhouette language preserved.
- High Heat: warning tint/text preserved.
- Louis Unlocked: runtime confirmed Louis visible.

Assertions: debug_states_preserved=true; Fresh_state_Bentley_Jake_Mere_visible=true; Fresh_state_Louis_hidden=true; LouisUnlocked_state_Louis_visible_near_store=true.

## 16. Monogon Readiness

Preserved:

- `GameplayRoot` / `ArtRoot` separation.
- station logic driven by catalog/interactable nodes, not visual tile identity.
- collision under `GameplayRoot/Navigation/Collision`.
- visual layers ready for later Monogon dressing:
  - `FloorLayer`
  - `WallLayer`
  - `PropLayer`
  - `DecorationLayer`
  - `CollectibleLayer`
  - `CharacterVisualLayer`
  - `ForegroundLayer`
  - `LightingLayer`

0M-B Monogon zones:

- cyberpunk interior: MissionBoard, PlanningTable, StoreTerminal, HeatScanner, monitors, neon panels, security tech.
- house interior: cozy lounge, couch/chairs, rugs, Bentley bed, shelves, care props.
- cyberpunk city/building/street extras: entry/exit, rooftop boundary, greenhouse windows, vents, industrial props, city-view edge.

Assertions: GameplayRoot_ArtRoot_separation_preserved=true; Monogon_ready_visual_layers_preserved=true; station_logic_not_bound_to_visual_tile=true; collision_separate_from_replaceable_art=true.

## 17. Validator

Created: `res://src/tools/editor/HideoutPhase0MA3Validator.gd`

Static/runtime validation completed:

- scene load via Godot Runtime Bridge returned OK.
- HideoutHub-specific script/lint errors: none.
- 18 hideout interactables registered.
- player z-index above floor confirmed.
- MissionBoard proxy group/method contract confirmed.
- MissionBoard panel open confirmed.
- Scrollable panel close confirmed.
- Louis hidden fresh confirmed.
- Louis visible in Louis Unlocked state confirmed.

Known validation noise: `McpInteractionServer: Failed to listen on port 9090, error: 22` appeared during bridge launch, likely from an existing MCP interaction server port conflict. It is not from HideoutHub scripts.

## 18. Known Placeholders

- Graybox only; no Monogon dressing.
- Store is panel-only; no economy.
- OpenDecorZone has no drag/drop placement implementation.
- Scheme cards are UI/data only.
- Most station E-interactions still need manual walk-up confirmation.
- Station nodes are runtime generated from the catalog; this is intentional for 0M-A3 data-driven scaffolding.

## 19. Risks / Fragile Areas

- Full walk-to-every-station E validation needs manual playtest in Godot.
- Because stations are generated at runtime, editor viewport before play will show only the roots and static UI/manager nodes.
- Existing `SceneManager.HIDEOUT_SCENE` still points at the older hideout scene; this pass did not change shared scene manager behavior.
- Wall collision approximates the irregular polygon with explicit bodies, not perfect per-edge collision.

## 20. Manual Playtest Checklist

1. Open `res://scenes/hideout/HideoutHub.tscn`.
2. Press Play.
3. Confirm player is visible above the floor/map.
4. Confirm player movement works.
5. Confirm walls/collision block movement.
6. Confirm layout resembles the reference image:
   - greenhouse north
   - Big Case north center
   - mission board northeast
   - planning table center
   - collectibles west
   - cozy lounge southwest
   - store east
   - entry/care southeast
7. Walk to Entry/Exit and press E.
8. Walk to Bentley Care Station and press E.
9. Walk to Loot Crate Drop and press E.
10. Walk to Bentley and press E.
11. Walk to Jake and press E.
12. Walk to Mere and press E.
13. Walk to Mission Board and press E.
14. Launch Taco Bell from Mission Board.
15. Reopen HideoutHub.
16. Walk to The Big Case and press E.
17. Walk to Planning Table and press E.
18. Walk to Polaroid Wall and press E.
19. Walk to Glow Guy Shelf and press E.
20. Walk to Tiny Icon Shelf and press E.
21. Walk to Poop Bag Display and press E.
22. Walk to Store Terminal and press E.
23. Walk to Open Decor Area and press E.
24. Walk to Heat Scanner and press E.
25. Toggle Louis Unlocked state and confirm Louis appears near store.
26. Toggle Fresh state and confirm Louis hides.
27. Confirm panels scroll and close.
28. Confirm no Taco Bell scene changed.

## 21. Recommended Next Step

0M-B - Hideout visual dressing / Monogon-style prop pass.
