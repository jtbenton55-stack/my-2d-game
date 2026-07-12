extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const BLUEPRINT_PATH := "res://docs/blueprints/velvet_paw_jazz_club.blueprint.json"
const BlueprintSpec := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")
const LayoutPainter := preload("res://src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd")
const UNPAINTED_SHA := "d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c"
const STAGED_SCENE_PATH := "res://reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_03b_retry4_work/VelvetPawJazzClub_Editable_phase3b_retry4_staged.tscn"
const MissionControllerScript := preload("res://src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const BLOCKER_GEOMETRY := {
	"FrontEntranceCrowdRopeBlocker/RopeShape": [Vector2(1440, 2528), Vector2(192, 64)],
	"VipProtocolGateBlocker/GateShape": [Vector2(2624, 1696), Vector2(64, 192)],
	"StaffGateBlocker/StageRowShape": [Vector2(2048, 1056), Vector2(256, 64)],
	"StaffGateBlocker/StageWingShape": [Vector2(2080, 928), Vector2(64, 192)],
	"BackstageHatchBlocker/HatchShape": [Vector2(1024, 1056), Vector2(256, 64)],
	"ServerVaultBlocker/VaultShape": [Vector2(3936, 2144), Vector2(192, 64)],
	"OwnerStairsBlocker/PortalPadShape": [Vector2(3008, 1152), Vector2(192, 64)],
	"EscapeHatchBlocker/HatchLidShape": [Vector2(4224, 2688), Vector2(96, 128)],
}
const DYNAMIC_MECHANICS := [
	["LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_01", "unlock", "collisions_to_disable_on_unlock", ["StaffGateBlocker/StageRowShape", "StaffGateBlocker/StageWingShape"], ["vpj_staff_badge_collected"], "vpj_staff_gate_open"],
	["RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_01", "unlock_route", "collisions_to_disable", ["BackstageHatchBlocker/HatchShape"], ["vpj_setlist_solved"], "vpj_backstage_hatch_open"],
	["LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_02", "unlock", "collisions_to_disable_on_unlock", ["ServerVaultBlocker/VaultShape"], ["vpj_vault_power_rerouted"], "vpj_server_vault_open"],
	["LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_03", "unlock", "collisions_to_disable_on_unlock", ["OwnerStairsBlocker/PortalPadShape"], ["vpj_shard_collected"], "vpj_owner_stairs_open"],
	["RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_02", "unlock_route", "collisions_to_disable", ["EscapeHatchBlocker/HatchLidShape"], ["vpj_briefcase_collected"], "vpj_escape_hatch_open"],
]


func before() -> void:
	_reset_runtime_state()


func after() -> void:
	_reset_runtime_state()


func test_scene_loads_and_instantiates() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	assert_object(root).is_not_null()
	assert_str(root.name).is_equal("VelvetPawJazzClub_Editable")
	var bridge := root.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionInteractionBridge")
	assert_object(bridge).is_not_null()
	assert_bool(bool(bridge.get("include_legacy_candidates"))).is_false()
	assert_object(root.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionAlertController")).is_not_null()
	assert_object(root.get_node_or_null("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")).is_not_null()
	var blueprint_layer := root.get_node_or_null("GameplayRoot/LayoutRoot/AuthoringBlueprintLayer")
	assert_object(blueprint_layer).is_not_null()
	assert_str(String(blueprint_layer.get("blueprint_path"))).is_equal(BLUEPRINT_PATH)
	root.free()


func test_mission_catalog_resolves_playable_scene() -> void:
	assert_str(MissionSceneResolver.resolve_playable_scene_path(MISSION_ID)).is_equal(SCENE_PATH)
	var report: Dictionary = MissionSceneResolver.get_resolution_report(MISSION_ID)
	assert_bool(report.get("ok", false)).is_true()
	assert_str(String(report.get("chosen_playable_path", ""))).is_equal(SCENE_PATH)


func test_blueprint_coverage_is_complete() -> void:
	var loaded := BlueprintSpec.load_spec(BLUEPRINT_PATH)
	assert_bool(loaded.get("ok", false)).is_true()
	var slots: Array = BlueprintSpec.mechanic_slots(loaded.get("spec", {}))
	assert_int(slots.size()).is_equal(68)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var coverage := BlueprintSpec.coverage(loaded.get("spec", {}), root)
	assert_int(coverage.get("total", 0)).is_equal(68)
	assert_int((coverage.get("placed", []) as Array).size()).is_equal(68)
	assert_array(coverage.get("missing", [])).is_empty()
	assert_array(coverage.get("mismatched", [])).is_empty()
	root.free()


func test_representative_stubs_match_blueprint_contract() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var player_start := root.get_node("GameplayRoot/MarkerRoot/Spawns/PlayerStartMarker_start_main") as Marker2D
	assert_vector(player_start.position).is_equal(Vector2(256, 2880))
	assert_str(String(player_start.get("marker_id"))).is_equal("start_main")
	var terminal := root.get_node("GameplayRoot/MissionMechanics/TerminalHackNode_velvet_paw_jazz_club_terminal_hack_node_01") as Area2D
	assert_vector(terminal.position).is_equal(Vector2(1152, 640))
	assert_str(String(terminal.get("mechanic_id"))).is_equal("velvet_paw_jazz_club.terminal_hack_node.01")
	var queue := root.get_node("GameplayRoot/MissionMechanics/InspectionZone_velvet_paw_jazz_club_inspection_zone_01") as Area2D
	var shape := queue.get_node("CollisionShape2D") as CollisionShape2D
	assert_vector((shape.shape as RectangleShape2D).size).is_equal(Vector2(256, 192))
	var beam := root.get_node("GameplayRoot/SecurityAuthoringRoot/SecurityBeamAuthor_velvet_paw_jazz_club_security_beam_author_01")
	assert_str(String(beam.get("beam_id"))).is_equal("velvet_paw_jazz_club.security_beam_author.01")
	root.free()


func test_persisted_layout_and_contract() -> void:
	var painted_path: String = _painted_scene_path()
	var root := (load(painted_path) as PackedScene).instantiate()
	var expected: Dictionary = {"floor": [9996, Vector2i(0, 0)], "wall": [1420, Vector2i(1, 0)], "collision_barrier": [446, Vector2i(1, 0)], "cover": [132, Vector2i(2, 0)], "marker": [0, Vector2i(-1, -1)]}
	for kind: String in expected:
		var layer := root.get_node(BlueprintSpec.PAINT_LAYER_BY_KIND[kind]) as TileMapLayer
		var cells: Array[Vector2i] = layer.get_used_cells()
		if kind == "floor":
			assert_int(cells.size()).append_failure_message(kind).is_greater_equal(int(expected[kind][0]))
		else:
			assert_int(cells.size()).append_failure_message(kind).is_equal(int(expected[kind][0]))
		for cell: Vector2i in cells:
			assert_int(layer.get_cell_source_id(cell)).is_equal(0)
			assert_vector(layer.get_cell_atlas_coords(cell)).is_equal(expected[kind][1])
	var report: Dictionary = LayoutPainter.run({"scene_path": painted_path, "blueprint_path": BLUEPRINT_PATH})
	assert_array(report.blocking_overlap_analysis.wall_barrier_cells).is_equal([[23, 156], [23, 158]])
	assert_array(report.blocking_overlap_analysis.wall_cover_cells).is_empty()
	assert_array(report.blocking_overlap_analysis.barrier_cover_cells).is_empty()
	assert_array(report.blocking_overlap_analysis.triple_intersection_cells).is_empty()
	assert_int((_derived_blocking_contract(root, false).cells as Array).size()).is_equal(1996)
	assert_int((_derived_blocking_contract(root).cells as Array).size()).is_equal(1984)
	var staff: Dictionary = _row_by_id(report.opening_analysis, "opening_id", "staff_side_club_entrance")
	assert_bool(bool(staff.continuous_clear_candidate_lane)).is_true()
	assert_array(staff.blocked_by_barrier_cells).is_empty()
	assert_array(staff.blocked_by_solid_cover_cells).is_empty()
	assert_bool(bool(_row_by_id(report.opening_analysis, "opening_id", "front_entrance_crowd_rope").blocked_by_current_barrier)).is_true()
	for row: Dictionary in report.cover_analysis.regions:
		if String(row.classification) == "safe_non_solid":
			assert_int(int(_region_by_label(report.per_region, String(row.label)).cell_count)).is_equal(0)
	for island: Dictionary in report.closed_island_analysis:
		assert_bool(bool(island.containment_represented)).is_true()
	_assert_blockout_visuals_hidden(root)
	assert_int(root.get_node("GameplayRoot/RouteBlockers").get_child_count()).is_equal(7)
	var art: Node = root.get_node("ArtRoot")
	assert_array(art.find_children("*", "CollisionObject2D", true, false)).is_empty()
	for child: Node in art.get_children():
		if child is TileMapLayer:
			assert_array((child as TileMapLayer).get_used_cells()).is_empty()
	root.free()


func test_detached_forward_sync_matches_complete_union_and_preserves_sources() -> void:
	var root := (load(_painted_scene_path()) as PackedScene).instantiate()
	var signatures: Dictionary = _layout_signatures(root)
	var contract: Dictionary = _derived_blocking_contract(root)
	var floor: Array[Vector2i] = _sorted_layer_cells(root.get_node("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer)
	root.call("_apply_blockout_tileset")
	root.call("_sync_layout_root_to_gameplay_layers")
	_assert_forward_sync(root, floor, contract)
	assert_dict(_layout_signatures(root)).is_equal(signatures)
	root.free()


func test_mission_controller_rehides_blockout_layers_if_scene_visibility_drifts() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	for path: String in [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayCollisionLayer",
		"GameplayRoot/LayoutRoot/FloorLayer",
		"GameplayRoot/LayoutRoot/WallLayer",
		"GameplayRoot/LayoutRoot/CoverLayer",
		"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	]:
		(root.get_node(path) as CanvasItem).visible = true
	var controller := root.get_node("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")
	controller.call("_hide_blockout_tile_layers")
	_assert_blockout_visuals_hidden(root)
	root.free()


func test_dynamic_blocker_blueprint_contract_is_exact() -> void:
	var json := JSON.parse_string(FileAccess.get_file_as_string(BLUEPRINT_PATH)) as Dictionary
	var blockers := (json.get("collision_contract", {}) as Dictionary).get("dynamic_blockers", []) as Array
	assert_int(blockers.size()).is_equal(7)
	var expected := {
		"FrontEntranceCrowdRopeBlocker": ["queue_inspection", [["RopeShape", [1440.0, 2528.0], [192.0, 64.0]]]],
		"VipProtocolGateBlocker": ["vip_protocol", [["GateShape", [2624.0, 1696.0], [64.0, 192.0]]]],
		"StaffGateBlocker": ["staff_gate", [["StageRowShape", [2048.0, 1056.0], [256.0, 64.0]], ["StageWingShape", [2080.0, 928.0], [64.0, 192.0]]]],
		"BackstageHatchBlocker": ["backstage_hatch", [["HatchShape", [1024.0, 1056.0], [256.0, 64.0]]]],
		"ServerVaultBlocker": ["server_vault", [["VaultShape", [3936.0, 2144.0], [192.0, 64.0]]]],
		"OwnerStairsBlocker": ["owner_stairs", [["PortalPadShape", [3008.0, 1152.0], [192.0, 64.0]]]],
		"EscapeHatchBlocker": ["escape_route", [["HatchLidShape", [4224.0, 2688.0], [96.0, 128.0]]]],
	}
	for blocker: Dictionary in blockers:
		var blocker_id := String(blocker.get("blocker_id", ""))
		assert_bool(expected.has(blocker_id)).is_true()
		assert_array(blocker.get("mechanic_slots", [])).is_equal([expected[blocker_id][0]])
		var actual_shapes: Array = []
		for shape: Dictionary in blocker.get("shapes", []):
			actual_shapes.append([shape.get("shape_id", ""), shape.get("center", []), shape.get("size", [])])
		assert_array(actual_shapes).is_equal(expected[blocker_id][1])
	assert_str(String(_row_by_id(blockers, "blocker_id", "EscapeHatchBlocker").get("note", ""))).contains("not an opening into void")


func test_dynamic_blocker_hierarchy_geometry_and_detached_paths() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var blocker_root := root.get_node("GameplayRoot/RouteBlockers")
	assert_int(blocker_root.get_child_count()).is_equal(7)
	for body: Node in blocker_root.get_children():
		assert_object(body).is_instanceof(StaticBody2D)
		assert_int((body as StaticBody2D).collision_layer).is_equal(4)
		assert_int((body as StaticBody2D).collision_mask).is_equal(0)
	for relative_path: String in BLOCKER_GEOMETRY:
		var shape := blocker_root.get_node(relative_path) as CollisionShape2D
		assert_vector(shape.position).override_failure_message(relative_path).is_equal(BLOCKER_GEOMETRY[relative_path][0])
		assert_vector((shape.shape as RectangleShape2D).size).override_failure_message(relative_path).is_equal(BLOCKER_GEOMETRY[relative_path][1])
		assert_bool(shape.disabled).is_false()
	_assert_blocker_paths_resolve(root)
	root.free()


func test_dynamic_blockers_gate_unlocks_and_fresh_scene_restores() -> void:
	for mechanic_data: Array in DYNAMIC_MECHANICS:
		_reset_runtime_state()
		GameState.start_mission(MISSION_ID)
		var root := (load(SCENE_PATH) as PackedScene).instantiate()
		var mechanic := root.get_node("GameplayRoot/MissionMechanics/%s" % mechanic_data[0])
		var target_paths := mechanic.get(mechanic_data[2]) as Array[NodePath]
		assert_int(target_paths.size()).is_equal((mechanic_data[3] as Array).size())
		var failed := mechanic.call(mechanic_data[1], null, "phase4_test") as Dictionary
		assert_bool(failed.get("ok", true)).override_failure_message(String(mechanic_data[0])).is_false()
		_assert_only_blockers_disabled(root, [])
		for flag_id: String in mechanic_data[4]:
			_set_flag(flag_id)
		if String(mechanic_data[0]).ends_with("locked_interaction_node_03"):
			MissionInventoryScript.add_item("velvet_paw_basement_keycard", 1, {"category": "credential"})
		var succeeded := mechanic.call(mechanic_data[1], null, "phase4_test") as Dictionary
		assert_bool(succeeded.get("ok", false)).override_failure_message(String(mechanic_data[0])).is_true()
		_assert_only_blockers_disabled(root, mechanic_data[3])
		assert_bool(MissionFactBridge.get_fact_value(&"mission_flag", mechanic_data[5], {"mission_id": MISSION_ID})).is_true()
		var repeated := mechanic.call(mechanic_data[1], null, "phase4_repeat") as Dictionary
		assert_bool(repeated.get("ok", false)).is_true()
		assert_str(String(repeated.get("code", ""))).is_equal("already_unlocked")
		_assert_only_blockers_disabled(root, mechanic_data[3])
		root.free()
		var fresh := (load(SCENE_PATH) as PackedScene).instantiate()
		_assert_only_blockers_disabled(fresh, [])
		fresh.free()


func test_full_startup_forward_sync_and_phase3a_teardown_are_clean() -> void:
	var orphan_ids_before: Array[int] = get_tree().root.get_orphan_node_ids()
	var root := (load(_painted_scene_path()) as PackedScene).instantiate()
	var signatures: Dictionary = _layout_signatures(root)
	var contract: Dictionary = _derived_blocking_contract(root)
	var floor: Array[Vector2i] = _sorted_layer_cells(root.get_node("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer)
	add_child(root)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_blocker_paths_resolve(root)
	_assert_forward_sync(root, floor, contract)
	assert_dict(_layout_signatures(root)).is_equal(signatures)
	root.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_array(_new_orphan_ids(orphan_ids_before)).is_empty()


func test_staff_gate_requirement_blocks_then_passes() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var gate := root.get_node("GameplayRoot/MissionMechanics/LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_01")
	assert_bool(gate.call("evaluate_requirements").get("ok", true)).is_false()
	_set_flag("vpj_staff_badge_collected")
	assert_bool(gate.call("evaluate_requirements").get("ok", false)).is_true()
	root.free()


func test_staff_badge_soft_voicemail_dependency_is_authored() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var badge := root.get_node("GameplayRoot/MissionMechanics/InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_01")
	var requirements: Resource = badge.get("requirements")
	assert_object(requirements).is_not_null()
	assert_int(requirements.requirements.size()).is_equal(1)
	assert_str(String(requirements.requirements[0].key)).is_equal("vpj_vip_voicemail_found")
	assert_bool(requirements.requirements[0].enabled).is_false()
	assert_bool(badge.call("evaluate_requirements").get("ok", false)).is_true()
	root.free()


func test_extraction_requires_flags_and_objectives() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var extraction := root.get_node("GameplayRoot/MissionMechanics/ExtractionZone_velvet_paw_jazz_club_extraction_zone_01")
	assert_bool(extraction.call("can_extract").get("ok", true)).is_false()
	_set_flag("vpj_escape_hatch_open")
	_set_flag("vpj_briefcase_collected")
	for objective_id in ["solve_setlist", "recover_shard", "defeat_owner", "recover_briefcase", "open_escape"]:
		ObjectiveStepController.complete_objective(objective_id, "", MISSION_ID)
	assert_bool(extraction.call("can_extract").get("ok", false)).is_true()
	root.free()


func test_teleport_and_patrol_links_resolve() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	for zone_name in [
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_01",
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_02",
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_03",
	]:
		var zone := root.get_node("GameplayRoot/MissionMechanics/%s" % zone_name)
		assert_object(zone.get_node_or_null(zone.get("target_marker_path"))).is_not_null()
	assert_bool(root.get_node("GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_01").call("evaluate_requirements").get("ok", true)).is_false()
	assert_bool(root.get_node("GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_03").call("evaluate_requirements").get("ok", true)).is_false()
	_set_flag("vpj_backstage_hatch_open")
	_set_flag("vpj_owner_stairs_open")
	assert_bool(root.get_node("GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_01").call("evaluate_requirements").get("ok", false)).is_true()
	assert_bool(root.get_node("GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_03").call("evaluate_requirements").get("ok", false)).is_true()
	var security_root := root.get_node("GameplayRoot/SecurityAuthoringRoot")
	for spawn_name in [
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_01",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_02",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_04",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_05",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_06",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_07",
	]:
		var spawn := security_root.get_node(spawn_name)
		assert_object(security_root.call("find_patrol_route", spawn.get("patrol_route_id"))).is_not_null()
	var routes := security_root.call("get_enabled_patrol_route_authors") as Array
	assert_int(routes.size()).is_equal(6)
	for route in routes:
		assert_int((route as Node).get_child_count()).is_greater_equal(2)
	root.free()


func test_setlist_requirement_and_effect_resources_are_live() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var terminal := root.get_node("GameplayRoot/MissionMechanics/TerminalHackNode_velvet_paw_jazz_club_terminal_hack_node_01")
	assert_bool(terminal.call("evaluate_requirements").get("ok", true)).is_false()
	_set_flag("vpj_clue_setlist_read")
	_set_flag("vpj_clue_manager_read")
	assert_bool(terminal.call("evaluate_requirements").get("ok", false)).is_true()
	var applied: Dictionary = terminal.get("success_effects").call("apply_all", {"mission_id": MISSION_ID, "mechanic": terminal})
	assert_bool(applied.get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"mission_flag", "vpj_setlist_solved", {"mission_id": MISSION_ID})).is_true()
	var alarm_effect_found := false
	for effect: Resource in terminal.get("failure_effects").effects:
		if String(effect.effect_id) == "emit_wrong_note_alarm":
			alarm_effect_found = true
			assert_str(String(effect.method_name)).is_equal("trigger_wrong_note_alarm")
	assert_bool(alarm_effect_found).is_true()
	root.free()


func test_dialogue_zones_have_fallback_text_or_key() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var missing: Array[String] = []
	for node in root.find_children("*", "", true, false):
		if node is DialogueTriggerZone:
			var fallback_text := String(node.get("fallback_text")).strip_edges()
			var dialogue_key := String(node.get("dialogue_key")).strip_edges()
			if fallback_text == "" and dialogue_key == "":
				missing.append(str(node.get_path()))
	assert_array(missing).is_empty()
	root.free()


func test_required_dialogue_content_is_authored() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	for required_line in [
		"There are too many colognes. And none of them smell as good as my expression.",
		"the staff side door stays propped open between sets.",
		"Shred before midnight. The badge is in the green room.",
		"Album arc tonight - start where we started hungry",
		"Setlist policy: five songs only",
		"House lights love you. Don't waste the downbeat.",
		"Tuck behind the bar - the rails swallow the bass spikes.",
		"That hum is the vault handshake.",
		"Bentley respects the grout lines.",
		"Grab it and don't admire the view.",
		"The club has turned hostile",
		"Bass drop. Release the escape hatch and move.",
		"Sterling's crew planted a prop ledger.",
	]:
		assert_bool(scene_text.contains(required_line)).is_true()


func test_controller_syncs_canonical_flags_and_game_state_side_effects() -> void:
	GameState.start_mission(MISSION_ID)
	var controller := MissionControllerScript.new()
	add_child(controller)
	controller.reset_attempt_state()
	_set_flag("vpj_entered_club")
	_set_flag("vpj_staff_badge_collected")
	_set_flag("vpj_setlist_solved")
	_set_flag("vpj_shard_collected")
	MissionInventoryScript.add_item("velvet_paw_basement_keycard", 1, {"category": "credential"})
	controller.sync_from_mission_facts()
	assert_bool(controller.entered_club).is_true()
	assert_bool(controller.staff_badge_collected).is_true()
	assert_bool(controller.setlist_solved).is_true()
	assert_bool(controller.shard_collected).is_true()
	assert_bool(controller.basement_keycard_collected).is_true()
	assert_bool(GameState.velvet_paw_basement_shard_collected).is_true()
	assert_bool(GameState.velvet_paw_basement_keycard_collected).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_false()
	controller.mark_returned_upstairs()
	assert_bool(controller.returned_upstairs_with_shard).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_true()
	controller.queue_free()


func _set_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": MISSION_ID})


func _assert_blocker_paths_resolve(root: Node) -> void:
	for mechanic_data: Array in DYNAMIC_MECHANICS:
		var mechanic := root.get_node("GameplayRoot/MissionMechanics/%s" % mechanic_data[0])
		var target_paths := mechanic.get(mechanic_data[2]) as Array[NodePath]
		for target_path: NodePath in target_paths:
			assert_object(mechanic.get_node_or_null(target_path)).override_failure_message("%s -> %s" % [mechanic_data[0], target_path]).is_not_null()


func _assert_only_blockers_disabled(root: Node, disabled_paths: Array) -> void:
	var blocker_root := root.get_node("GameplayRoot/RouteBlockers")
	for relative_path: String in BLOCKER_GEOMETRY:
		var shape := blocker_root.get_node(relative_path) as CollisionShape2D
		assert_bool(shape.disabled).override_failure_message(relative_path).is_equal(disabled_paths.has(relative_path))


func _reset_runtime_state() -> void:
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	GameState.velvet_paw_club_hostile = false
	GameState.velvet_paw_basement_shard_collected = false
	GameState.velvet_paw_basement_keycard_collected = false
	for key: Variant in GameState.dialogue_flags.keys():
		if String(key).begins_with("mission_flag:%s:" % MISSION_ID):
			GameState.dialogue_flags.erase(key)
	MissionInventoryScript.clear_mission_items()
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()


func _derived_blocking_contract(root: Node, exclude_runtime_cells: bool = true) -> Dictionary:
	var atlas_by_cell: Dictionary = {}
	for path_and_atlas: Array in [["GameplayRoot/LayoutRoot/WallLayer", Vector2i(1, 0)], ["GameplayRoot/LayoutRoot/CoverLayer", Vector2i(2, 0)], ["GameplayRoot/LayoutRoot/CollisionBarrierLayer", Vector2i(1, 0)]]:
		var layer := root.get_node(String(path_and_atlas[0])) as TileMapLayer
		for cell: Vector2i in layer.get_used_cells():
			atlas_by_cell[cell] = path_and_atlas[1]
	if exclude_runtime_cells:
		for cell: Vector2i in root.get("layout_collision_excluded_cells"):
			atlas_by_cell.erase(cell)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in atlas_by_cell:
		cells.append(cell)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return {"cells": cells, "atlas_by_cell": atlas_by_cell}


func _assert_forward_sync(root: Node, expected_floor: Array[Vector2i], contract: Dictionary) -> void:
	var floor := root.get_node("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision := root.get_node("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	_assert_blockout_visuals_hidden(root)
	assert_bool(floor.enabled).is_true()
	assert_bool(collision.enabled).is_true()
	assert_bool(floor.collision_enabled).is_false()
	assert_bool(collision.collision_enabled).is_true()
	assert_array(_sorted_layer_cells(floor)).is_equal(expected_floor)
	assert_array(_sorted_layer_cells(collision)).is_equal(contract.cells)
	for cell: Vector2i in contract.cells:
		assert_int(collision.get_cell_source_id(cell)).is_equal(0)
		assert_vector(collision.get_cell_atlas_coords(cell)).is_equal(contract.atlas_by_cell[cell])


func _assert_blockout_visuals_hidden(root: Node) -> void:
	for path: String in [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayCollisionLayer",
		"GameplayRoot/LayoutRoot/FloorLayer",
		"GameplayRoot/LayoutRoot/WallLayer",
		"GameplayRoot/LayoutRoot/CoverLayer",
		"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	]:
		assert_bool((root.get_node(path) as CanvasItem).visible).override_failure_message(path).is_false()


func _layout_signatures(root: Node) -> Dictionary:
	var signatures: Dictionary = {}
	for kind: String in BlueprintSpec.REGION_KINDS:
		var layer := root.get_node(BlueprintSpec.PAINT_LAYER_BY_KIND[kind]) as TileMapLayer
		var rows: Array[String] = []
		for cell: Vector2i in _sorted_layer_cells(layer):
			var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
			rows.append("%d,%d:%d:%d,%d" % [cell.x, cell.y, layer.get_cell_source_id(cell), atlas.x, atlas.y])
		signatures[kind] = rows
	return signatures


func _sorted_layer_cells(layer: TileMapLayer) -> Array[Vector2i]:
	var cells: Array[Vector2i] = layer.get_used_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return cells


func _row_by_id(rows: Array, key: String, wanted: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get(key, "")) == wanted:
			return row
	return {}


func _region_by_label(rows: Array, wanted: String) -> Dictionary:
	for row: Dictionary in rows:
		var label := String(row.get("label", ""))
		if label == wanted or label.begins_with(wanted + " -"):
			return row
	return {}


func _new_orphan_ids(ids_before: Array[int]) -> Array[int]:
	var ids: Array[int] = []
	for id: int in get_tree().root.get_orphan_node_ids():
		if not ids_before.has(id):
			ids.append(id)
	ids.sort()
	return ids


func _painted_scene_path() -> String:
	return STAGED_SCENE_PATH if FileAccess.get_sha256(SCENE_PATH) == UNPAINTED_SHA else SCENE_PATH
