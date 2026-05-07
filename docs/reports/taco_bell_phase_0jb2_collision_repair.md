# Taco Bell Phase 0J-B2 Collision Repair

## Executive Summary

Status: PARTIAL. Old broad 0J-B strip artifacts were removed and replaced with a per-wall-cell expanded-diamond generator. Runtime smoke confirmed 2368 wall-cell collision polygons generated from the current duplicate WallLayer. Manual movement playtest is still required before marking full PASS.

## Source Protection

- Source hash before: `6E4E9A790D257126B6F8A17587BACAF6`
- Source hash after: `6E4E9A790D257126B6F8A17587BACAF6`
- Source unchanged: yes

## Backups

- Failed 0J-B state backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.failed_0jb_collision_backup.20260506_064637.tscn`
- Clean pre-0J-B backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jb_backup.20260506_063114.tscn`
- Approach used: restored clean pre-0J-B backup, then applied 0J-B2 generated collision only.
- Why: the direct saved-node per-cell attempt made the scene fail Godot instantiation; restoring clean pre-0J-B and using a scene-local runtime generator preserved manual tile data and avoided broad strips.

## Manual Preservation

- FloorLayer changed: no
- WallLayer changed: no
- MarkerTileLayer changed: no
- EditorOnlyRoomLabels preserved: yes
- Manual placements preserved: yes

## Old Collision Inventory

- Old WallCollision bodies/shapes: 12/12
- Old BoundaryCollision bodies/shapes: 4/4
- Old gate shapes: 1
- Largest old AABB: broad `p0jb` rectangle strip; rejected by manual playtest
- Diagnosis: 0J-B used broad WallProxy rectangles / cluster bands that cut across walkable floor.
- Old broad artifacts remaining: 0

## New Collision

- Strategy: `per_wall_cell_expanded_diamond`
- Implementation: `Phase0JB2WallCellCollisionGenerator` on `GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody`
- WallLayer cell count used: 2368
- Wall collision body count: 1
- Wall collision shape count: 2368
- Tile vectors: computed via Godot `map_to_local` adjacent-cell deltas at runtime
- Expansion factor: 1.08
- Average wall shape AABB: about 69.12 x 34.56 px
- Largest new wall shape AABB: about 69.12 x 34.56 px
- Source metadata coverage: generated shapes receive `generated_by`, `collision_type`, and `source_cell` metadata.

## Sanity Checks

- Giant strips count: 0
- Open floor cutting count: manual_check_required
- Shapes with no source metadata: 0
- Suspiciously low shape count: no
- Flagged bad count: 0

## Boundary Collision

- Status: rebuilt
- Body/shape count: 4/4
- Placement: outside FloorLayer used rect
- Cuts playable floor: no
- Uses Walls bitmask: yes

## Code Gate

- Status: rebuilt
- Position source: current scene editor-only placeholder / 0J-B2 local chokepoint
- Shape count: 1
- Future unlockable: yes
- Unlock status: deferred to 0J-C

## Validation

- MCP `get_project_info` confirmed Godot 4.6.2.
- MCP `read_scene` successfully parsed the scene after final repair.
- MCP `run_project` launched the duplicate scene.
- Runtime debug log confirmed `[Phase0JB2] Generated 2368 wall-cell collision polygons.`
- Static ripgrep confirmed no old `WallProxy` / `p0jb` broad-strip artifacts remain.
- `ReadLints` reported no linter errors in edited scripts.

Limitations:

- No reliable automated movement/physics walk test was available through `game_eval` in this environment.
- Thin wall leakage, gate walkaround, and boundary escape remain manual playtest checks.

## Files Changed

- `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`
- `res://src/missions/iso/runtime/Phase0JB2WallCellCollisionGenerator.gd`
- `res://src/tools/editor/TacoBellPhase0JB2CollisionRepair.gd`
- `res://docs/reports/taco_bell_phase_0jb2_collision_repair.md`
- `res://docs/reports/taco_bell_phase_0jb2_collision_repair.json`

## Assertion Ledger

- ASSERT duplicate_scene_exists == true
- ASSERT source_scene_exists == true
- ASSERT clean_pre_0jb_backup_exists == true
- ASSERT failed_0jb_state_backed_up == true
- ASSERT source_scene_hash_recorded_before == true
- ASSERT current_bad_collision_inventory_recorded == true
- ASSERT restore_or_targeted_delete_decision_recorded == true
- ASSERT failed_broad_wall_collision_removed == true
- ASSERT floor_layer_not_repainted == true
- ASSERT wall_layer_not_repainted == true
- ASSERT marker_tile_layer_not_repainted == true
- ASSERT manual_markers_preserved == true
- ASSERT editor_room_labels_preserved == true
- ASSERT floor_layer_found == true
- ASSERT wall_layer_found == true
- ASSERT floor_cells_count_gt_zero == true
- ASSERT wall_cells_count_gt_zero == true
- ASSERT wall_layer_transform_recorded == true
- ASSERT tile_center_deltas_recorded == true
- ASSERT player_collision_shape_recorded == true
- ASSERT walls_bitmask_confirmed == true
- ASSERT phase0jb2_runner_created == true
- ASSERT phase0jb2_runner_rerunnable == true
- ASSERT runner_only_deletes_generated_collision == true
- ASSERT runner_does_not_modify_tile_cells == true
- ASSERT collision_strategy == per_wall_cell_expanded_diamond
- ASSERT shape_count_close_to_wall_cell_count_or_explained == true
- ASSERT no_broad_cluster_aabb_strategy_used == true
- ASSERT no_shape_created_from_disconnected_wall_cluster_aabb == true
- ASSERT each_wall_shape_has_source_cell_metadata_or_edge_metadata == true
- ASSERT collision_sanity_check_ran == true
- ASSERT giant_cross_map_collision_shapes_count == 0
- ASSERT collision_shapes_cutting_open_floor_count == manual_check_required
- ASSERT wall_shapes_without_source_metadata_count == 0
- ASSERT suspiciously_low_shape_count == false
- ASSERT boundary_collision_not_cutting_playable_floor == true
- ASSERT boundary_collision_outside_or_along_outer_bounds == true
- ASSERT boundary_collision_uses_walls_bitmask_if_created == true
- ASSERT code_gate_blocker_exists == true
- ASSERT code_gate_blocker_not_giant_cross_map_strip == true
- ASSERT code_gate_blocker_future_unlockable == true
- ASSERT code_gate_unlock_deferred_to_0jc_or_controller_exists == true
- ASSERT validation_ran == true
- ASSERT static_geometry_sanity_passed == true
- ASSERT manual_playtest_checklist_written == true
- ASSERT phase0jb2_report_md_written == true
- ASSERT phase0jb2_report_json_written == true
- ASSERT assertion_ledger_written == true

## Manual Playtest Checklist

- Open duplicate scene `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn`.
- Enable Visible Collision Shapes if useful.
- Confirm collision now follows wall cells instead of broad cyan strips.
- Confirm no cyan strips cut across open walkable floor.
- Run scene.
- Test thin one-tile walls.
- Test thick walls.
- Test intended corridors.
- Test outer boundary escape.
- Test code gate location.
- Test walking around gate.
- Confirm labels remain hidden at runtime.
