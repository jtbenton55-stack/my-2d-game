# Phase 0I — Taco Bell Runtime Truth Audit and Minimal Playability Fix

**Status:** PASS
**Timestamp:** 2026-05-05T22:36:08

## Source-scene protection

- **Path:** `res://scenes/missions_iso/TacoBellIso_Editable.tscn`
- **MD5 before:** `6e4e9a790d257126b6f8a17587bacaf6`
- **MD5 after:** `6e4e9a790d257126b6f8a17587bacaf6`
- **Unchanged:** true

## Target duplicate scene

- **Path:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- **Existed before:** true
- **Backup created:** true
- **Backup path:** `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0i_backup.20260505_223607.tscn`
- **MD5 before:** `57ecefb018e8c189a17724356e0caf38`
- **MD5 after:** `d9cf0b39636b717d450020109fa5f995`

## Builder Phase 0I cleanup summary

### Wall layer (B)

- **collision_enabled before:** false
- **collision_enabled after:** true
- **TileSet physics_layer_0 collision_layer bits:** 4 (4 = Walls)

### Authoring hide-at-runtime (A)

- **MarkerTileLayer hider attached:** true
- **EditorOnlyPlaceholders hider attached:** true
- **Authoring marker root subnodes hidden:** 9 / 17

### Generated runtime collision (C)

- **Path:** `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`
- **abs_cell:** [130, 3]
- **world_position:** [7074.0, 233.0]
- **collision_layer:** 4 (4 = Walls)
- **future_unlockable:** true

### Promoted core collectibles (D)

| Manifest ID | Implementation | Cell | Node path |
|---|---|---|---|
| `OBJ_bag_recovery` | MissionCollectiblePickupPlaceholder | [240, 20] | `EntityRoot/Interactables/Phase0IGeneratedCollectibles/OBJ_bag_recovery` |
| `poop_bag_garage_pet_bin` | MissionCollectiblePickupPlaceholder | [179, 30] | `EntityRoot/Interactables/Phase0IGeneratedCollectibles/poop_bag_garage_pet_bin` |
| `BAG_louis_service_corridor` | MissionCollectiblePickupPlaceholder | [130, 40] | `EntityRoot/Interactables/Phase0IGeneratedCollectibles/BAG_louis_service_corridor` |
| `PHOTO_optional_market_nook` | MissionCollectiblePickupPlaceholder | [-19, 24] | `EntityRoot/Interactables/Phase0IGeneratedCollectibles/PHOTO_optional_market_nook` |
| `CLUE_security_memo` | MissionCluePickupPlaceholder | [198, -24] | `EntityRoot/Interactables/Phase0IGeneratedCollectibles/CLUE_security_memo` |

### Route safeguard (E)

- **Attached:** true
- **Node path:** `GameplayRoot/Phase0IRouteSafeguard`
- **Targets:**
  - `GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_vent_return`
  - `GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_louis_return`
- **Legacy blockers disabled:**
  - `GameplayRoot/RuntimeSystems/TransitionTriggers/CodeGateBarrier_garage_office_code`

## Hard assertions

**Validator pass:** true

| Assertion | Value |
|---|---|
| `CONTROL_alarm_panel_uses_SWITCH` | true |
| `CONTROL_camera_terminal_uses_SWITCH` | true |
| `CONTROL_door_controls_uses_SWITCH` | true |
| `CollisionBarrierLayer_exists` | true |
| `CoverLayer_exists` | true |
| `DOOR_marker_tile_has_no_collision` | true |
| `FloorLayer_exists` | true |
| `FloorLayer_not_empty` | true |
| `MarkerRoot_exists` | true |
| `MarkerTileLayer_exists` | true |
| `MarkerTileLayer_hidden_at_runtime` | true |
| `MarkerTileLayer_not_empty` | true |
| `MarkerTileLayer_visible_in_editor` | true |
| `ROUTE_IN_louis_service_door_uses_DOOR` | true |
| `ROUTE_RET_louis_return_trigger_uses_DOOR` | true |
| `SWITCH_marker_tile_has_no_collision` | true |
| `VENT_IN_bentley_routes_are_not_player_teleport_triggers` | true |
| `WallLayer_exists` | true |
| `WallLayer_not_empty` | true |
| `WallLayer_or_GeneratedRuntimeCollision_blocks_player` | true |
| `all_BENTLEY_SWITCH_use_SWITCH` | true |
| `all_required_main_routes_reachable` | true |
| `at_least_one_clue_interactable_or_missing_system_reported` | true |
| `at_least_one_photo_interactable_or_missing_system_reported` | true |
| `at_least_one_poophag_or_bag_pickup_interactable_or_missing_system_reported` | true |
| `authoring_tiles_do_not_render_above_player_at_runtime` | true |
| `bentley_route_A_exists` | true |
| `bentley_route_B_exists` | true |
| `bentley_route_C_exists` | true |
| `bentley_route_D_exists` | true |
| `boundary_colliders_disabled` | true |
| `boundary_colliders_zero_collision_layers` | true |
| `cache_safe_load_mode_used` | true |
| `camera_floodlight_spacing_meets_min` | true |
| `camera_limits_cover_floor_used_rect` | true |
| `code_gate_blocker_future_unlockable` | true |
| `code_gate_blocker_not_just_visual_marker` | true |
| `code_gate_blocker_ready_for_future_unlock` | true |
| `code_gate_blocker_runtime_blocks_player` | true |
| `code_gate_has_associated_block_marker` | true |
| `code_gate_has_collision_barrier` | true |
| `code_gate_to_beam_cell_distance_meets_min` | true |
| `collectible_authoring_tiles_hidden_at_runtime` | true |
| `core_delivery_bag_interactable_or_existing_system_missing_reported` | true |
| `dry_run_validator_used_in_memory_root` | true |
| `editor_only_placeholders_do_not_render_as_gameplay_pickups` | true |
| `editor_only_placeholders_have_no_gameplay_groups` | true |
| `editor_only_placeholders_have_no_iso_mission_marker_script` | true |
| `editor_only_placeholders_have_no_marker_type_field` | true |
| `equivalence_collisions_count_zero` | 0 |
| `exactly_one_gate_tile` | true |
| `far_route_points_inside_camera_bounds` | true |
| `floor_cell_count_meets_min` | true |
| `gate_marker_tile_count_equals_one` | true |
| `generated_wall_collision_uses_walls_layer` | true |
| `key_marker_ids_inside_camera_bounds` | true |
| `level_bounds_zone_present_in_mission_definition` | true |
| `louis_route_bypasses_code_gate_challenge` | true |
| `louis_route_does_not_skip_bag_objective` | true |
| `louis_route_does_not_skip_exit` | true |
| `louis_route_return_before_security_beam` | true |
| `louis_route_trigger_not_accidentally_on_bentley_vent` | true |
| `marker_labels_no_at_label_siblings` | true |
| `marker_labels_show_editor_label_false` | true |
| `marker_vocabulary_includes_DOOR` | true |
| `marker_vocabulary_includes_SWITCH` | true |
| `missing_required_runtime_markers_count_zero` | 0 |
| `no_BENTLEY_SWITCH_uses_GATE` | true |
| `no_CONTROL_uses_GATE` | true |
| `no_unexpected_tilemap_layers_with_used_cells` | true |
| `old_boundary_colliders_not_required_for_wall_collision` | true |
| `old_collision_boundary_artifacts_not_visible` | true |
| `old_prototype_floor_tiles_not_visible` | true |
| `old_prototype_wall_tiles_not_visible` | true |
| `only_GATE_garage_code_uses_GATE` | true |
| `optional_visual_reference_NOT_used_for_coordinates` | true |
| `phase_0i_helper_scripts_attached` | true |
| `placeholder_children_have_owner` | true |
| `placeholder_nodes_have_owner` | true |
| `player_collision_mask_includes_walls` | true |
| `player_crossing_vent_area_does_not_teleport_to_spawn` | true |
| `player_flood_fill_does_not_require_bentley_routes` | true |
| `poop_bag_garage_pet_bin_not_in_blocking_collision` | true |
| `random_old_marker_tiles_removed` | true |
| `root_transform_audit_recorded` | true |
| `route_triggers_have_correct_linked_destinations` | true |
| `safe_code_input_not_inside_beam_zone` | true |
| `source_scene_unchanged` | true |
| `target_scene_exists` | true |
| `target_scene_loads` | true |
| `unaccounted_marker_tile_count_zero` | 0 |
| `used_rect_height_meets_min` | true |
| `used_rect_width_meets_min` | true |
| `validator_loaded_target_file` | true |
| `vent_in_marker_cells_not_blocked` | true |
| `vent_interactable_stand_cells_available` | true |
| `wall_collision_runtime_active` | true |
| `wall_layer_collision_runtime_active` | true |

## Runtime smoke (live SceneTree instantiate)

- **Pass:** true
- **WallLayer.collision_enabled at runtime:** true
- **MarkerTileLayer.visible after Phase0IAuthoringHider._ready:** false
- **EditorOnlyPlaceholders.visible after Phase0IAuthoringHider._ready:** false
- **GateBlockers/BLOCK_code_gate present:** true
- **GateBlockers/BLOCK_code_gate uses Walls layer (bit 4):** true
- **Phase0IRouteSafeguard present:** true
- **Promoted collectibles count:** 5

## Files changed

- `assets/missions/layouts/taco_bell_expanded_layout_v6.json` — added `phase_0i` validation + `phase_0i_cleanup` config and `mission_id_hint`.
- `src/tools/editor/TacoBellExpandedLayoutBuilder.gd` — added Phase 13c `_phase_0i_cleanup` (wall collision, hider attach, gate blocker, promoted collectibles, route safeguard).
- `src/tools/editor/TacoBellExpandedLayoutValidator.gd` — added `_phase_0i_audit` and Phase 0I hard assertions.
- `src/tools/editor/TacoBellPhase0ICleanup.gd` — new headless driver.
- `src/missions/iso/runtime/Phase0IAuthoringHider.gd` — new editor-only authoring visual hider.
- `src/missions/iso/runtime/Phase0IRouteSafeguard.gd` — new runtime player-teleport safeguard.
- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — overwritten by deterministic builder.
- `docs/reports/taco_bell_phase_0i_runtime_truth_audit.{md,json}` — this report.
- `docs/reports/taco_bell_generated_map_room_guide.md` — human-readable map room guide.

## Remaining limitations / deferred items

- The 11 `real_if_safe` SWITCH/DOOR mechanics remain editor-only. No behavioral claims.
- Code-gate keypad UI is not implemented. The blocker is real and removable; future work wires the keypad to remove the StaticBody2D's collision_layer.
- Bentley vent routes are inert for the player. A future pass implementing real Bentley/Louis route mechanics will connect specific Area2D triggers to the right characters via a cleaner runtime check (instead of `auto_trigger_on_enter` for any `transition_id` starting with `route_`).
- Promoted collectibles other than the 5 core ones remain editor-only `Node2D` placeholders. A separate pass can promote the rest using the same builder pattern.
- `IsoMissionBase._spawn_code_gate_blockers` still creates a legacy blocker at obsolete cell `(21,-3)`. Phase0IRouteSafeguard disables it at runtime. The proper fix lives in `IsoMissionBase.gd`, which is not modified per the Phase 0I rules.