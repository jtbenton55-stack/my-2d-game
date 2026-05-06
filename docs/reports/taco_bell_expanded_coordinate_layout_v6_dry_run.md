# Taco Bell Expanded Coordinate Layout v6 - Phase E Dry-Run Validation

**Status:** PASS
**Entrypoint:** validate_scene_root
**Scene root in memory:** true

## Hard assertions

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
| `cache_safe_load_mode_used` | true |
| `optional_visual_reference_NOT_used_for_coordinates` | true |
| `code_gate_to_beam_cell_distance_meets_min` | true |
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

## Counts

- **floor_cell_count:** 18269
- **wall_cell_count:** 2283
- **collision_cell_count:** 35
- **cover_cell_count:** 37
- **marker_tile_count:** 128
- **used_rect_x:** -30
- **used_rect_y:** -55
- **used_rect_width:** 283
- **used_rect_height:** 126
- **reachable_cell_count:** 16681

**Anchor cell:** [-20, 0]

## Reachability

### Required main routes
- [OK] Delivery Alley Hub center @ [71, 8]
- [OK] Safe Code Input Pocket @ [116, 4]
- [OK] Code Gate @ [128, 4]
- [OK] Post-Gate Buffer @ [145, 4]
- [OK] Security Beam @ [160, 14]
- [OK] Garage Floor 1 center @ [177, 16]
- [OK] Bag Recovery Room @ [239, 20]
- [OK] South Return Corridor @ [123, 53]
- [OK] Mission Exit @ [-8, 52]

### Optional routes
- [OK] zone_optional_market_nook @ [-19, 22]
- [OK] zone_dog_station_alley @ [18, -47]
- [OK] zone_trash_alley @ [54, -38]
- [OK] zone_loading_dock_lane @ [52, 39]
- [OK] zone_security_guard_kiosk_control @ [114, -25]
- [OK] zone_garage_office_code_clue @ [117, 24]
- [OK] zone_garage_floor_2_upper_platform @ [194, -26]
- [OK] zone_upper_platform_control_alcove @ [220, -24]

## Vent interface audit

| ID | VENT_IN | Vent on floor | Vent blocked | Stand cell | Stand on floor | Stand blocked |
| --- | --- | --- | --- | --- | --- | --- |
| vent_interface_A | VENT_IN_bentley_A_market_grate | true | false | [28, 13] | true | false |
| vent_interface_B | VENT_IN_bentley_B_loading_dock_sewer | true | false | [64, 40] | true | false |
| vent_interface_C | VENT_IN_bentley_C_post_gate_duct | true | false | [146, -3] | true | false |
| vent_interface_D | VENT_IN_bentley_D_south_corridor | true | false | [152, 57] | true | false |

## MarkerTileLayer audit

- **GATE tile count:** 1
- **Unaccounted cells:** 0

### Per-abbreviation tile counts
- ALARM: 2
- AMBUSH: 1
- BAG: 5
- SWITCH: 9
- BLOCK: 1
- CAM: 6
- CLUE: 8
- EXIT: 1
- FLOOD: 4
- GATE: 1
- GLOW: 3
- GUARD: 8
- HELP: 5
- LIGHT: 6
- OBJ: 5
- PATROL: 32
- PHOTO: 3
- ROUTE_DEST: 1
- DOOR: 2
- ROUTE_SPAWN: 1
- SCENT_FAKE: 5
- SCENT_PATH: 3
- STAIRS_DN: 2
- STAIRS_UP: 2
- TINY: 3
- VENT_IN: 4
- VENT_OUT: 4
- SCENT_REAL: 1

## Editor-only placeholder audit

- **parent_exists:** true
- **placeholder_count:** 96
- **placeholders_with_script:** 0
- **placeholders_with_marker_type:** 0
- **placeholders_in_groups:** 0
- **placeholders_without_owner:** 0
- **label_children_without_owner:** 0
