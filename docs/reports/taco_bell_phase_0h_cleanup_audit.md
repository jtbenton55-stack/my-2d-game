# Phase 0H — Taco Bell Duplicate-Scene Cleanup, Marker Verification, Camera Bounds, Editor Artifact Audit

**Status:** PASS
**Timestamp:** 20260505_202008

## Source-scene protection

- **Path:** `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- **MD5 before:** `6e4e9a790d257126b6f8a17587bacaf6`
- **MD5 after:** `6e4e9a790d257126b6f8a17587bacaf6`
- **Unchanged:** true

## Target duplicate scene

- **Path:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- **Existed before:** true
- **Backup created:** true
- **Backup path:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0h_backup.20260505_202007.tscn`
- **MD5 before:** `6b8a1c45be16f86497c3d01926b705a2`
- **MD5 after:** `354f9c453492fa4281077b8d42c99d4c`

## Mission-definition update (level_bounds_max)

- **Path:** `res://assets/missions/taco_bell_iso_blockout_definition.tres`
- **Zone id:** `level_bounds_max`
- **Created:** false
- **Updated:** false
- **Origin:** [-18, -63]
- **Size:** [298, 141]
- **Reason:** already_at_target_state_idempotent_noop

## Builder Phase 0H cleanup summary

- **Saved duplicate:** true
- **floor_cell_count:** 18269
- **wall_cell_count:** 2283
- **collision_cell_count:** 35
- **cover_cell_count:** 37
- **marker_tile_count:** 128
- **editor_only_placeholders_created:** 96
- **runtime_markers_moved:** 38
- **missing_required_runtime_markers:** 0
- **equivalence_collisions:** 0
- **used_rect_x:** -30
- **used_rect_y:** -55
- **used_rect_width:** 283
- **used_rect_height:** 126

### Old TileMapLayer cleanup

| Path | Found | Class | Cells before | Cells after | Visible | Enabled | Collision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `GameplayRoot/GameplayFloorLayer` | true | TileMapLayer | 1103 | 0 | false | false | false |
| `GameplayRoot/GameplayCollisionLayer` | true | TileMapLayer | 289 | 0 | false | false | false |
| `GameplayRoot/GameplayMarkersLayer` | true | TileMapLayer | 37 | 0 | false | false | false |
| `GameplayRoot/LayoutRoot/DebugLabelLayer` | true | TileMapLayer | 0 | 0 | false | false | false |

### Boundary collider cleanup

- **Path:** `GameplayRoot/BoundaryColliders`
- **Found:** true
- **Disabled:** true
- **Static body count:** 233
- **Static bodies disabled:** 233
- **Collision shapes disabled:** 233

### Camera2D bake

- **Path:** `Camera2D`
- **Found:** true
- **Applied:** true
- **Margin px:** 384
- **Limits before:** { "left": -1696, "top": -400, "right": 2560, "bottom": 512 }
- **Limits after:** { "left": -3550, "top": -1079, "right": 15330, "bottom": 1705 }

### Marker label dedup + suppression

- **Markers processed:** 56
- **show_editor_label set false:** 56
- **EditorLabel kept invisible:** 56
- **@Label@ siblings removed:** 168
- **Total labels removed:** 168

### Root transform audit

- **Position before:** [-1310.0, 169.0]
- **Rotation before:** 0.0
- **Scale before:** [1.0, 1.0]
- **Is identity:** false
- **Left unchanged reason:** source_scene_has_same_non_identity_transform_resetting_would_shift_world_positions

## Validator (Phase H + 0H assertions)

**Pass:** true

### Phase 0H-specific hard assertions

| Assertion | Value |
| --- | --- |
| `code_gate_to_beam_cell_distance_meets_min` | true |
| `no_unexpected_tilemap_layers_with_used_cells` | true |
| `old_prototype_floor_tiles_not_visible` | true |
| `old_prototype_wall_tiles_not_visible` | true |
| `boundary_colliders_disabled` | true |
| `boundary_colliders_zero_collision_layers` | true |
| `camera_limits_cover_floor_used_rect` | true |
| `far_route_points_inside_camera_bounds` | true |
| `key_marker_ids_inside_camera_bounds` | true |
| `root_transform_audit_recorded` | true |
| `marker_labels_no_at_label_siblings` | true |
| `marker_labels_show_editor_label_false` | true |
| `exactly_one_gate_tile` | true |
| `code_gate_has_associated_block_marker` | true |
| `code_gate_has_collision_barrier` | true |
| `code_gate_blocker_ready_for_future_unlock` | true |
| `level_bounds_zone_present_in_mission_definition` | true |

### Phase 0G v6 carry-forward hard assertions

| Assertion | Value |
| --- | --- |
| `source_scene_unchanged` | true |
| `target_scene_exists` | true |
| `target_scene_loads` | true |
| `FloorLayer_exists` | true |
| `WallLayer_exists` | true |
| `CoverLayer_exists` | true |
| `CollisionBarrierLayer_exists` | true |
| `MarkerTileLayer_exists` | true |
| `MarkerRoot_exists` | true |
| `floor_cell_count_meets_min` | true |
| `used_rect_width_meets_min` | true |
| `used_rect_height_meets_min` | true |
| `FloorLayer_not_empty` | true |
| `WallLayer_not_empty` | true |
| `MarkerTileLayer_not_empty` | true |
| `random_old_marker_tiles_removed` | true |
| `unaccounted_marker_tile_count_zero` | 0 |
| `gate_marker_tile_count_equals_one` | true |
| `only_GATE_garage_code_uses_GATE` | true |
| `no_CONTROL_uses_GATE` | true |
| `no_BENTLEY_SWITCH_uses_GATE` | true |
| `all_BENTLEY_SWITCH_use_SWITCH` | true |
| `CONTROL_alarm_panel_uses_SWITCH` | true |
| `CONTROL_camera_terminal_uses_SWITCH` | true |
| `CONTROL_door_controls_uses_SWITCH` | true |
| `ROUTE_IN_louis_service_door_uses_DOOR` | true |
| `ROUTE_RET_louis_return_trigger_uses_DOOR` | true |
| `marker_vocabulary_includes_DOOR` | true |
| `marker_vocabulary_includes_SWITCH` | true |
| `DOOR_marker_tile_has_no_collision` | true |
| `SWITCH_marker_tile_has_no_collision` | true |
| `player_flood_fill_does_not_require_bentley_routes` | true |
| `poop_bag_garage_pet_bin_not_in_blocking_collision` | true |
| `editor_only_placeholders_have_no_iso_mission_marker_script` | true |
| `editor_only_placeholders_have_no_marker_type_field` | true |
| `editor_only_placeholders_have_no_gameplay_groups` | true |
| `placeholder_nodes_have_owner` | true |
| `placeholder_children_have_owner` | true |
| `dry_run_validator_used_in_memory_root` | true |
| `validator_loaded_target_file` | true |
| `cache_safe_load_mode_used` | true |
| `optional_visual_reference_NOT_used_for_coordinates` | true |
| `safe_code_input_not_inside_beam_zone` | true |
| `all_required_main_routes_reachable` | true |
| `bentley_route_A_exists` | true |
| `bentley_route_B_exists` | true |
| `bentley_route_C_exists` | true |
| `bentley_route_D_exists` | true |
| `vent_in_marker_cells_not_blocked` | true |
| `vent_interactable_stand_cells_available` | true |
| `camera_floodlight_spacing_meets_min` | true |
| `missing_required_runtime_markers_count_zero` | 0 |
| `equivalence_collisions_count_zero` | 0 |
| `old_collision_boundary_artifacts_not_visible` | true |

### Phase 0H raw audit

**TileMapLayer inventory** (every TileMapLayer in the scene tree):

| Path | Used cells | Visible | Enabled | Collision |
| --- | --- | --- | --- | --- |
| `GameplayRoot/GameplayFloorLayer` | 0 | false | false | false |
| `GameplayRoot/GameplayCollisionLayer` | 0 | false | false | false |
| `GameplayRoot/GameplayMarkersLayer` | 0 | false | false | false |
| `GameplayRoot/LayoutRoot/FloorLayer` | 18269 | true | true | false |
| `GameplayRoot/LayoutRoot/WallLayer` | 2283 | true | true | false |
| `GameplayRoot/LayoutRoot/CoverLayer` | 37 | true | true | false |
| `GameplayRoot/LayoutRoot/CollisionBarrierLayer` | 35 | true | true | false |
| `GameplayRoot/LayoutRoot/MarkerTileLayer` | 128 | true | true | false |
| `GameplayRoot/LayoutRoot/DebugLabelLayer` | 0 | false | false | false |
| `ArtRoot/GroundArtLayer` | 0 | true | true | false |
| `ArtRoot/WallArtLayer` | 0 | true | true | false |
| `ArtRoot/PropArtLayer` | 0 | true | true | false |
| `ArtRoot/DecorBelowLayer` | 0 | true | true | false |
| `ArtRoot/DecorAboveLayer` | 0 | true | true | false |
| `ArtRoot/LightingLayer` | 0 | true | true | false |
| `ArtRoot/LightingArtLayer` | 0 | true | true | false |

**Camera world floor rect:** { "min": [-3166, -695], "max": [14946, 1321] }

**Camera limits:** { "left": -3550, "top": -1079, "right": 15330, "bottom": 1705 }

**Key markers in camera bounds:**

| Manifest id | Abs cell | World position | Inside camera bounds |
| --- | --- | --- | --- |
| `player_spawn_main` | [-18, 1] | [-2398, 201] | true |
| `SCENT_PATH_hub_center` | [70, 7] | [3234, 297] | true |
| `SAFE_CODE_INPUT_ZONE` | [116, 3] | [6178, 233] | true |
| `GATE_garage_code` | [129, 3] | [7010, 233] | true |
| `AMBUSH_security_beam` | [161, 14] | [9026, 409] | true |
| `OBJ_bag_recovery` | [240, 20] | [14082, 505] | true |
| `EXIT_mission_return_to_louis` | [-8, 52] | [-1790, 1017] | true |

**Boundary colliders audit:**

- **Path:** `GameplayRoot/BoundaryColliders`
- **Found:** true
- **Visible:** false
- **Process mode:** 4 (4 = PROCESS_MODE_DISABLED)
- **Static body count:** 233
- **Static bodies with nonzero collision:** 0

**Marker label audit:**

- **Markers total:** 56
- **Markers with show_editor_label = true:** 0
- **EditorLabel children:** 56
- **`@Label@xxxxx` siblings remaining:** 0

**Marker spam clusters (radius 5 manhattan, threshold 4):**

- **Largest cluster size:** 0
- **Cluster count:** 0

**Code gate verification:**

- **BLOCK_code_gate manifest row present:** true
- **CollisionBarrierLayer cell at gate blocker:** true
- **Blocker ready for future unlock (linked + collidable + GATE/BLOCK rows valid):** true

**Level bounds zone in mission definition:**

- **Present:** true
- **Zone id:** `level_bounds_max`
- **Origin:** [-18, -63]
- **Size:** [298, 141]

**Runtime marker position audit (first 30 rows):**

| manifest_id | category | abbr | expected cell | actual cell | matched | runtime name | status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `player_spawn_main` | SPAWN |  | [-18, 1] | [-18, 1] | true | `player_spawn_main` | real_existing_position_ok |
| `bentley_spawn_main` | SPAWN |  | [-15, 2] | [-15, 2] | true | `bentley_spawn_main` | real_existing_position_ok |
| `default_spawn_if_required` | SPAWN |  | [-18, 1] | [-18, 1] | true | `default` | real_existing_position_ok |
| `OBJ_start_briefing` | OBJ | OBJ | [-13, 2] | [-13, 2] | true | `objective_talk_to_louis` | real_existing_position_ok |
| `OBJ_market_investigation` | OBJ | OBJ | [18, 1] | [18, 1] | true | `objective_inspect_sauce_packets_or_receipt` | real_existing_position_ok |
| `OBJ_scent_decision` | OBJ | OBJ | [71, 7] | [71, 7] | true | `OBJ_scent_decision` | real_existing_position_ok |
| `OBJ_code_gate` | OBJ | OBJ | [121, 3] | [121, 3] | true | `objective_enter_parking_garage` | real_existing_position_ok |
| `OBJ_security_beam` | OBJ | OBJ | [161, 14] | [161, 14] | true | `objective_complete_without_triggering_garage_alarm` | real_existing_position_ok |
| `OBJ_bag_recovery` | OBJ | OBJ | [240, 20] | [240, 20] | true | `objective_retrieve_delivery_bag` | real_existing_position_ok |
| `OBJ_return_to_louis` | OBJ | OBJ | [-8, 52] | [-8, 52] | true | `objective_escape_and_return_to_louis` | real_existing_position_ok |
| `HELP_start_controls` | HELP | HELP | [-12, 6] | [-12, 6] | true | `HELP_start_controls` | real_existing_position_ok |
| `HELP_scent_tutorial` | HELP | HELP | [68, 4] | [68, 4] | true | `HELP_scent_tutorial` | real_existing_position_ok |
| `HELP_code_gate` | HELP | HELP | [113, 1] | [113, 1] | true | `HELP_code_gate` | real_existing_position_ok |
| `HELP_bentley_utility` | HELP | HELP | [27, 17] | [27, 17] | true | `HELP_bentley_utility` | real_existing_position_ok |
| `HELP_poop_bag_throw` | HELP | HELP | [41, 37] | [41, 37] | true | `HELP_poop_bag_throw` | real_existing_position_ok |
| `SCENT_PATH_hub_center` | SCENT_PATH | SCENT_PATH | [70, 7] | [70, 7] | true | `SCENT_PATH_hub_center` | real_existing_position_ok |
| `SCENT_FAKE_dog_station` | SCENT_FAKE | SCENT_FAKE | [17, -35] | [17, -35] | true | `SCENT_FAKE_dog_station` | real_existing_position_ok |
| `SCENT_FAKE_trash_alley` | SCENT_FAKE | SCENT_FAKE | [52, -27] | [52, -27] | true | `scent_fake_trash_area` | real_existing_position_ok |
| `SCENT_FAKE_loading_dock` | SCENT_FAKE | SCENT_FAKE | [46, 26] | [46, 26] | true | `scent_fake_loading_dock` | real_existing_position_ok |
| `SCENT_REAL_garage_approach` | SCENT_REAL | SCENT_REAL | [84, 6] | [84, 6] | true | `scent_real_parking_garage` | real_existing_position_ok |
| `scent_fake_loading_dock` | SCENT_FAKE | SCENT_FAKE | [46, 26] | [46, 26] | true | `scent_fake_loading_dock` | real_existing_position_ok |
| `scent_fake_trash_area` | SCENT_FAKE | SCENT_FAKE | [52, -27] | [52, -27] | true | `scent_fake_trash_area` | real_existing_position_ok |
| `scent_fake_trash_area_02` | SCENT_FAKE | SCENT_FAKE | [56, -38] | [56, -38] | true | `scent_fake_trash_area_02` | real_existing_position_ok |
| `scent_fake_trash_area_03` | SCENT_FAKE | SCENT_FAKE | [44, 37] | [44, 37] | true | `scent_fake_trash_area_03` | real_existing_position_ok |
| `scent_real_parking_garage` | SCENT_REAL | SCENT_REAL | [84, 6] | [84, 6] | true | `scent_real_parking_garage` | real_existing_position_ok |
| `scent_real_parking_garage_02` | SCENT_PATH | SCENT_PATH | [93, 6] | [93, 6] | true | `scent_real_parking_garage_02` | real_existing_position_ok |
| `scent_real_parking_garage_03` | SCENT_PATH | SCENT_PATH | [101, 5] | [101, 5] | true | `scent_real_parking_garage_03` | real_existing_position_ok |
| `CLUE_route_manifest_half` | CLUE | CLUE | [44, 38] | [44, 38] | true | `clue_route_manifest_half` | real_existing_position_ok |
| `CLUE_sterling_delivery_token` | CLUE | CLUE | [57, -39] | [57, -39] | true | `clue_sterling_delivery_token` | real_existing_position_ok |
| `CLUE_velvet_paw_stamp` | CLUE | CLUE | [117, 24] | [117, 24] | true | `clue_velvet_paw_stamp` | real_existing_position_ok |

(showing first 30 of 138 rows)

## Structural smoke

- **Pass:** true
- **Required nodes present:** true
- **Floor cell count:** 18269
- **Camera2D limits:** { "left": -3550, "right": 15330, "top": -1079, "bottom": 1705 }
- **Old layer status:**
  - { "path": "GameplayRoot/GameplayFloorLayer", "used_cells": 0, "visible": false }
  - { "path": "GameplayRoot/GameplayCollisionLayer", "used_cells": 0, "visible": false }
  - { "path": "GameplayRoot/GameplayMarkersLayer", "used_cells": 0, "visible": false }
  - { "path": "GameplayRoot/LayoutRoot/DebugLabelLayer", "used_cells": 0, "visible": false }
- **Boundary colliders:** { "visible": false, "process_mode": 4, "static_body_count": 233, "static_body_with_nonzero_collision_count": 0 }

## Repo diff vs source diff

- The source scene file `res://scenes/missions_iso/TacoBellIso_Editable.tscn` is byte-for-byte unchanged.
- The mission-definition resource `res://assets/missions/taco_bell_iso_blockout_definition.tres` was modified to add the `level_bounds_max` zone (which expands runtime camera bounds by enlarging the rect produced by `IsoMissionBase._mission_rect()`). This is a per-mission resource (not the catalog) and was modified in a controlled, reversible way (it adds one zone with a specific zone_id; removing it restores the prior behavior).
- The duplicate scene was overwritten by the deterministic builder. A timestamped backup of the prior duplicate state is retained.
- No save/load systems, mission catalog, `IsoMissionBase.gd`, `IsoMissionMarker.gd`, unrelated missions, or global runtime systems were modified.

## Remaining limitations / deferred items

- The 11 `real_if_safe` rows (9 SWITCH + 2 DOOR) remain editor-only `Node2D` placeholders. No behavioral claims. Future passes will convert each into a real mechanic in isolation.
- The duplicate root transform is non-identity. The source scene root has the same transform, and resetting in the duplicate would shift world positions (ArtRoot/EntityRoot/Camera2D/Player/etc. are all expressed in the root-relative coordinate frame). The audit records the value but does NOT modify it. A separate isolated pass can compensate child transforms and reset the root if you want the warning gone.
- The label readability fix relies on `show_editor_label = false` and dedup of `@Label@xxxxx`. Each Godot editor open of an `IsoMissionMarker` re-creates one new `Label` named `EditorLabel` (and may rename the saved one to `@Label@xxxxx` due to a known `IsoMissionMarker._ensure_label` accumulation pattern). Re-running the Phase 0H driver collapses them again. A real fix lives in `IsoMissionMarker.gd`, which is intentionally not modified per Phase 0H rules.
- IsoMissionBase.gd currently reads the OLD layer paths (`GameplayRoot/GameplayFloorLayer`, etc.) for some helper functions. We have NOT renamed or moved those nodes; we only emptied them and disabled their collision/visibility. The runtime helpers continue to find the (now empty) layers at their original paths, and the new layout lives at `GameplayRoot/LayoutRoot/...` as expected. No changes to `IsoMissionBase.gd` were required or made.
