# Taco Bell Phase 0J-C Interactables

## Executive Summary

Status: PASS. 0J-C traced the real interaction input path, added a hybrid scene-local interaction strategy, generated 49 runtime interactables, and verified direct methods plus code gate unlock. Wall collision, source scene, global systems, and map tile layers were not changed.

## Interaction Trace

- Q binding: `case_the_joint` on Q.
- Interact action: `interact` on E / joypad button 3.
- Player path: `res://src/player/Player.gd`.
- Player methods: `_physics_process`, `_try_interact`, `_try_click_interact`, `_try_case_the_joint`.
- Contract: group `interactable`, method `interact(player)`, Node2D within 72 px.
- 0J-C strategy: hybrid. Generated nodes conform to Player for E, and `Phase0JInteractionBridge` lets Q activate only nearby `phase0j_interactable` nodes.
- Previous failure cause: marker tiles and editor-only placeholders are not runtime `interactable` nodes with an `interact(player)` method and collision shape.

## Protection And Preservation

- Source hash before: `6E4E9A790D257126B6F8A17587BACAF6`
- Source hash after: `6E4E9A790D257126B6F8A17587BACAF6`
- Duplicate backup: `res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jc_backup.20260506_075937.tscn`
- Map regenerated/repainted: no
- Manual marker positions preserved: yes; matching editor-only placeholder positions were preferred over manifest cells.
- 0J-B2 wall collision preserved: yes, runtime wall shape count remained 2368.

## Generated Interactables Summary

- Parent: `GameplayRoot/GeneratedRuntimeInteractables`
- Total real interactables: 49
- Category counts: `{"intel":1,"evidence_clue":20,"poop_bag":9,"polaroid":6,"glow_guy":6,"tiny_icon":6,"code_input":1}`
- Script: `res://src/missions/iso/runtime/Phase0JInteractablePickup.gd`
- Groups: `interactable`, `phase0j_interactable`
- Collision: layer 4 bitmask 8, mask Player bitmask 1
- Visuals: simple runtime `Polygon2D` icon per item

## Code Gate

- SAFE_CODE_INPUT_ZONE: `GameplayRoot/GeneratedRuntimeInteractables/Interactable_SAFE_CODE_INPUT_ZONE`
- Controller: `GameplayRoot/RuntimeHelpers/Phase0JCodeGateController`
- Blocker: `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`
- Unlock test: PASS; before `collision_layer=4 unlocked=false`, after `collision_layer=0 unlocked=true`.
- Bridge nearby unlock test: PASS; player moved to SAFE_CODE_INPUT_ZONE and `Phase0JInteractionBridge._try_interact()` unlocked the gate.
- Full keypad UI: deferred.

## Candidate Table

| Candidate | Category | Source | Cell | Runtime status |
|---|---|---|---|---|
| OBJ_bag_recovery | OBJ | manifest | 260, 20 | REAL_INTERACTABLE_WORKING |
| CLUE_route_manifest_half | CLUE | manifest | 64, 38 | REAL_INTERACTABLE_WORKING |
| CLUE_sterling_delivery_token | CLUE | manifest | 77, -39 | REAL_INTERACTABLE_WORKING |
| CLUE_velvet_paw_stamp | CLUE | manifest | 137, 24 | REAL_INTERACTABLE_WORKING |
| CLUE_sauce_packet | CLUE | manifest | 137, -24 | REAL_INTERACTABLE_WORKING |
| CLUE_camera_schedule | CLUE | manifest | 132, -29 | REAL_INTERACTABLE_WORKING |
| CLUE_delivery_receipt | CLUE | manifest | 90, 16 | REAL_INTERACTABLE_WORKING |
| CLUE_security_memo | CLUE | manifest | 218, -24 | REAL_INTERACTABLE_WORKING |
| BAG_dog_station | BAG | manifest | 39, -47 | REAL_INTERACTABLE_WORKING |
| BAG_loading_dock | BAG | manifest | 61, 43 | REAL_INTERACTABLE_WORKING |
| poop_bag_garage_pet_bin | BAG | manifest | 199, 30 | REAL_INTERACTABLE_WORKING |
| BAG_south_return | BAG | manifest | 112, 53 | REAL_INTERACTABLE_WORKING |
| PHOTO_optional_market_nook | PHOTO | manifest | 1, 24 | REAL_INTERACTABLE_WORKING |
| PHOTO_dog_station | PHOTO | manifest | 32, -48 | REAL_INTERACTABLE_WORKING |
| PHOTO_upper_platform | PHOTO | manifest | 231, -22 | REAL_INTERACTABLE_WORKING |
| GLOW_market_shop | GLOW | manifest | 45, -16 | REAL_INTERACTABLE_WORKING |
| GLOW_kiosk | GLOW | manifest | 128, -20 | REAL_INTERACTABLE_WORKING |
| GLOW_bag_room | GLOW | manifest | 265, 30 | REAL_INTERACTABLE_WORKING |
| TINY_market_corner | TINY | manifest | 69, 11 | REAL_INTERACTABLE_WORKING |
| TINY_loading_dock | TINY | manifest | 84, 44 | REAL_INTERACTABLE_WORKING |
| TINY_south_corridor | TINY | manifest | 182, 53 | REAL_INTERACTABLE_WORKING |
| SAFE_CODE_INPUT_ZONE | CODE_INPUT | manifest | 136, 3 | REAL_INTERACTABLE_WORKING |
| CLUE_code_gate_nearby | CLUE | manifest | 137, 24 | REAL_INTERACTABLE_WORKING |
| CLUE_louis_route_flavor | CLUE | manifest | 132, 40 | REAL_INTERACTABLE_WORKING |
| BAG_louis_service_corridor | BAG | manifest | 150, 40 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_70_16 | CLUE | manual_marker | 70, 16 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_57_m21 | CLUE | manual_marker | 57, -21 | REAL_INTERACTABLE_WORKING |
| MANUAL_BAG_CELL_19_m25 | BAG | manual_marker | 19, -25 | REAL_INTERACTABLE_WORKING |
| MANUAL_PHOTO_CELL_12_m26 | PHOTO | manual_marker | 12, -26 | REAL_INTERACTABLE_WORKING |
| MANUAL_GLOW_CELL_25_m10 | GLOW | manual_marker | 25, -10 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_14_m4 | CLUE | manual_marker | 14, -4 | REAL_INTERACTABLE_WORKING |
| MANUAL_BAG_CELL_m28_11 | BAG | manual_marker | -28, 11 | REAL_INTERACTABLE_WORKING |
| MANUAL_PHOTO_CELL_19_26 | PHOTO | manual_marker | 19, 26 | REAL_INTERACTABLE_WORKING |
| MANUAL_BAG_CELL_42_22 | BAG | manual_marker | 42, 22 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_45_20 | CLUE | manual_marker | 45, 20 | REAL_INTERACTABLE_WORKING |
| MANUAL_TINY_CELL_50_4 | TINY | manual_marker | 50, 4 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_130_19 | CLUE | manual_marker | 130, 19 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_111_19 | CLUE | manual_marker | 111, 19 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_70_8 | CLUE | manual_marker | 70, 8 | REAL_INTERACTABLE_WORKING |
| MANUAL_TINY_CELL_62_23 | TINY | manual_marker | 62, 23 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_117_11 | CLUE | manual_marker | 117, 11 | REAL_INTERACTABLE_WORKING |
| MANUAL_GLOW_CELL_107_m11 | GLOW | manual_marker | 107, -11 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_112_m15 | CLUE | manual_marker | 112, -15 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_117_m13 | CLUE | manual_marker | 117, -13 | REAL_INTERACTABLE_WORKING |
| MANUAL_TINY_CELL_162_26 | TINY | manual_marker | 162, 26 | REAL_INTERACTABLE_WORKING |
| MANUAL_BAG_CELL_179_15 | BAG | manual_marker | 179, 15 | REAL_INTERACTABLE_WORKING |
| MANUAL_PHOTO_CELL_211_m12 | PHOTO | manual_marker | 211, -12 | REAL_INTERACTABLE_WORKING |
| MANUAL_CLUE_CELL_198_m14 | CLUE | manual_marker | 198, -14 | REAL_INTERACTABLE_WORKING |
| MANUAL_GLOW_CELL_245_15 | GLOW | manual_marker | 245, 15 | REAL_INTERACTABLE_WORKING |

## Skipped Marker Classifications

- Route/vent markers deferred to Bentley/Louis route pass: 24
- Guard/patrol markers deferred to combat/AI pass: 50
- Camera/flood/alarm markers deferred to 0J-D detection pass: 18
- Cover/light/debug/help authoring markers: 21
- Door/switch/control markers deferred except SAFE_CODE_INPUT_ZONE: 13
- Exit marker deferred or existing: 1
- Unknown authoring markers classified non-collectible: 12

## Validation

- Duplicate loads via MCP `read_scene`: yes
- Runtime smoke via `run_project`: yes
- Direct method tests: 49/49
- Repeated interaction safe: 49/49
- Collision shapes: 49/49
- Runtime visuals: 49/49
- Live proximity validation: SAFE_CODE_INPUT_ZONE bridge proximity tested; broad item-by-item movement playtest manual_check_required
- Lints: no linter errors

## Explicitly Not Changed

- wall collision helper
- Player.gd
- CollectibleManager.gd
- IsoMissionBase.gd
- IsoMissionMarker.gd
- guards/combat
- cameras/detection hazards
- Bentley/Louis routes
- save/load
- source scene

## Assertion Ledger

- ASSERT duplicate_scene_exists == PASS
- ASSERT source_scene_exists == PASS
- ASSERT duplicate_backed_up_before_0jc == PASS
- ASSERT source_hash_before_recorded == PASS
- ASSERT duplicate_hash_before_recorded == PASS
- ASSERT phase0jb2_wall_collision_exists == PASS
- ASSERT wall_collision_shape_count_recorded == PASS
- ASSERT wall_collision_not_modified_in_phase_a == PASS
- ASSERT code_gate_blocker_exists == PASS
- ASSERT phase0ja_editor_labels_exist == PASS
- ASSERT q_binding_identified == PASS
- ASSERT interaction_action_identified == PASS
- ASSERT player_interaction_code_path_reported == PASS
- ASSERT expected_group_identified == PASS
- ASSERT expected_method_identified == PASS
- ASSERT expected_collision_layer_mask_identified == PASS
- ASSERT previous_failure_cause_reported == PASS
- ASSERT interaction_strategy_chosen == PASS
- ASSERT no_Player_gd_modification == PASS
- ASSERT strategy_conforms_or_bridge_created == PASS
- ASSERT bridge_scene_local_only_if_used == PASS
- ASSERT all_candidate_sources_scanned == PASS
- ASSERT all_collectible_candidates_enumerated == PASS
- ASSERT manual_collectible_markers_enumerated == PASS
- ASSERT candidate_table_written == PASS
- ASSERT no_collectible_category_skipped_due_to_quantity == PASS
- ASSERT every_skipped_marker_classified == PASS
- ASSERT generated_runtime_interactables_parent_exists == PASS
- ASSERT runtime_helpers_parent_exists_if_needed == PASS
- ASSERT only_phase0jc_generated_children_cleared == PASS
- ASSERT manual_nodes_not_deleted == PASS
- ASSERT phase0j_pickup_script_created_or_existing_valid == PASS
- ASSERT pickup_script_supports_expected_method == PASS
- ASSERT pickup_script_repeated_interaction_safe == PASS
- ASSERT pickup_script_does_not_require_collectible_manager == PASS
- ASSERT every_BAG_item_has_runtime_node == PASS
- ASSERT every_CLUE_intel_item_has_runtime_node == PASS
- ASSERT every_PHOTO_item_has_runtime_node == PASS
- ASSERT every_GLOW_item_has_runtime_node == PASS
- ASSERT every_TINY_item_has_runtime_node == PASS
- ASSERT every_poop_bag_item_has_runtime_node == PASS
- ASSERT every_objective_pickup_has_runtime_node == PASS
- ASSERT every_manual_collectible_marker_has_runtime_node_or_classified == PASS
- ASSERT every_runtime_interactable_has_collision_shape == PASS
- ASSERT every_runtime_interactable_has_visual == PASS
- ASSERT every_runtime_interactable_has_group_and_method == PASS
- ASSERT no_collectible_like_item_left_marker_only == PASS
- ASSERT safe_code_input_zone_runtime_node_exists == PASS
- ASSERT safe_code_input_zone_real_interactable == PASS
- ASSERT code_gate_controller_exists == PASS
- ASSERT code_gate_controller_references_blocker == PASS
- ASSERT interacting_with_safe_code_input_calls_unlock_gate == PASS
- ASSERT unlock_gate_disables_blocker_collision == PASS
- ASSERT gate_starts_locked_on_scene_reload == PASS
- ASSERT keypad_ui_deferred_reported == PASS
- ASSERT non_collectible_markers_classified == PASS
- ASSERT route_markers_not_accidentally_converted_to_pickups == PASS
- ASSERT camera_hazard_markers_deferred_to_0jd_unless_collectible_clue == PASS
- ASSERT guard_markers_deferred_to_0jd == PASS
- ASSERT validation_ran == PASS
- ASSERT every_real_interactable_method_tested == PASS
- ASSERT every_real_interactable_repeated_interaction_safe == PASS
- ASSERT all_category_counts_validated == PASS
- ASSERT safe_code_input_unlock_tested == PASS
- ASSERT phase0jb2_wall_collision_preserved_after == PASS
- ASSERT source_scene_unchanged_after == PASS
- ASSERT phase0jc_report_md_written == PASS
- ASSERT phase0jc_report_json_written == PASS
- ASSERT full_candidate_table_written == PASS
- ASSERT category_counts_written == PASS
- ASSERT assertion_ledger_written == PASS
- ASSERT manual_playtest_checklist_written == PASS

## Manual Playtest Checklist

- Run TacoBellIso_Editable_RedesignTest.tscn.
- Confirm walls still work.
- Go to Code Gate / Safe Code Input.
- Press Q/interact near SAFE_CODE_INPUT_ZONE.
- Confirm gate unlock message appears.
- Confirm gate becomes passable.
- Test at least one item in each category: BAG, poop bag, CLUE/intel, PHOTO/Polaroid, GLOW/GLOW GUY, TINY, objective/delivery bag.
- Press Q/interact near each.
- Confirm item collects, disappears, marks collected, or logs collection.
- Press Q/interact again and confirm no crash.
- Confirm no collectible-like item is only a fake marker tile.
- Confirm room labels stay hidden during play.
- Confirm wall collision was not broken.

## Recommended Next Pass

0J-D guards/combat + cameras/detection only.

