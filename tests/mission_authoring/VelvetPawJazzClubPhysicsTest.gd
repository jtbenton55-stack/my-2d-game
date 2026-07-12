extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const PLAYER_SIZE := Vector2(24, 24)
const WALL_MASK := 4
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

const BLOCKING_MOTIONS := {
	"bar_counter": [Vector2(576, 1136), Vector2(576, 1424)],
	"dj_rig": [Vector2(1792, 432), Vector2(1792, 720)],
	"grand_piano": [Vector2(864, 688), Vector2(864, 976)],
	"green_room_couch": [Vector2(2432, 560), Vector2(2432, 816)],
	"vip_booth_north": [Vector2(2848, 1600), Vector2(2848, 1952)],
	"vip_booth_south": [Vector2(2848, 1984), Vector2(2848, 2336)],
	"owner_desk": [Vector2(3968, 352), Vector2(3968, 672)],
	"server_rack": [Vector2(3872, 1760), Vector2(3872, 2048)],
	"storage_shelf": [Vector2(3968, 2208), Vector2(3968, 2496)],
	"subwoofer_solid_cover": [Vector2(1376, 1984), Vector2(1376, 2304)],
	"costume_rack_solid_cover": [Vector2(2752, 736), Vector2(3008, 736)],
	"dumpster_solid_cover": [Vector2(2816, 2784), Vector2(3136, 2784)],
	"basement_crates_solid_cover": [Vector2(3904, 2720), Vector2(4224, 2720)],
}

const FIXED_OPENING_MOTIONS := {
	"staff_side_club_entrance": [Vector2(2976, 2400), Vector2(2976, 2656)],
	"stage_row_bathroom_access": [Vector2(320, 928), Vector2(320, 1120)],
	"bathroom_divider_south_end": [Vector2(480, 928), Vector2(704, 928)],
}

const DYNAMIC_CASES := [
	{
		"name": "staff_gate",
		"mechanic": "LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_01",
		"method": "unlock",
		"flags": ["vpj_staff_badge_collected"],
		"shape": "GameplayRoot/RouteBlockers/StaffGateBlocker/StageRowShape",
		"motion": [Vector2(2048, 928), Vector2(2048, 1184)],
	},
	{
		"name": "backstage_hatch",
		"mechanic": "RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_01",
		"method": "unlock_route",
		"flags": ["vpj_setlist_solved"],
		"shape": "GameplayRoot/RouteBlockers/BackstageHatchBlocker/HatchShape",
		"motion": [Vector2(1024, 928), Vector2(1024, 1184)],
	},
	{
		"name": "server_vault",
		"mechanic": "LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_02",
		"method": "unlock",
		"flags": ["vpj_vault_power_rerouted"],
		"shape": "GameplayRoot/RouteBlockers/ServerVaultBlocker/VaultShape",
		"motion": [Vector2(3936, 2016), Vector2(3936, 2272)],
	},
	{
		"name": "escape_hatch",
		"mechanic": "RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_02",
		"method": "unlock_route",
		"flags": ["vpj_briefcase_collected"],
		"shape": "GameplayRoot/RouteBlockers/EscapeHatchBlocker/HatchLidShape",
		"motion": [Vector2(4224, 2560), Vector2(4224, 2816)],
	},
]


func before() -> void:
	_reset_runtime_state()


func after() -> void:
	_reset_runtime_state()


func test_wall_proxy_is_deterministic_transform_aware_and_bounded() -> void:
	var root := await _add_mission()
	var body := root.get_node("GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody") as StaticBody2D
	assert_int(body.collision_layer).is_equal(WALL_MASK)
	assert_int(body.collision_mask).is_equal(0)
	assert_int(int(body.get("generated_shape_count"))).is_equal(1418)
	assert_int(body.get_child_count()).is_equal(1418)
	assert_int(int(body.get_meta("wall_cell_count", 0))).is_equal(1418)
	assert_int(int(body.get_meta("shape_count", 0))).is_equal(1418)
	assert_vector(body.get_meta("tile_center_delta_x", Vector2.ZERO)).is_equal(Vector2(64, 0))
	assert_vector(body.get_meta("tile_center_delta_y", Vector2.ZERO)).is_equal(Vector2(32, 16))
	var generation_usec := int(body.get_meta("generation_usec", 1000000))
	print("PHASE5_PROXY generation_usec=%d shapes=%d" % [generation_usec, body.get_child_count()])
	assert_int(generation_usec).is_less(500000)
	var first_name := String(body.get_child(0).name)
	var last_name := String(body.get_child(body.get_child_count() - 1).name)
	body.call("regenerate")
	assert_int(body.get_child_count()).is_equal(1418)
	assert_str(String(body.get_child(0).name)).is_equal(first_name)
	assert_str(String(body.get_child(body.get_child_count() - 1).name)).is_equal(last_name)
	await _remove_mission(root)


func test_exterior_and_island_walls_block_from_both_sides() -> void:
	var root := await _add_mission()
	for named_motion: Array in [
		["exterior_north", Vector2(1600, 368), Vector2(1600, 528)],
		["owner_island_north", Vector2(3904, 112), Vector2(3904, 272)],
		["basement_island_north", Vector2(3904, 1648), Vector2(3904, 1808)],
	]:
		_assert_blocked_motion(named_motion[0], named_motion[1], named_motion[2])
		_assert_blocked_motion(named_motion[0] + "_reverse", named_motion[2], named_motion[1])
	await _remove_mission(root)


func test_furniture_and_solid_cover_physically_block() -> void:
	var root := await _add_mission()
	for motion_name: String in BLOCKING_MOTIONS:
		var motion: Array = BLOCKING_MOTIONS[motion_name]
		_assert_blocked_motion(motion_name, motion[0], motion[1])
	await _remove_mission(root)


func test_fixed_openings_connect_and_non_solid_cover_is_walkable() -> void:
	var root := await _add_mission()
	for motion_name: String in FIXED_OPENING_MOTIONS:
		var motion: Array = FIXED_OPENING_MOTIONS[motion_name]
		_assert_clear_motion(motion_name, motion[0], motion[1])
		_assert_clear_motion(motion_name + "_reverse", motion[1], motion[0])
	_assert_clear_grid("bar_corner", Vector2(1088, 1472), 16.0)
	_assert_clear_grid("dance_floor_silhouette", Vector2(1696, 1952), 16.0)
	await _remove_mission(root)


func test_vip_left_entrance_blocks_until_bentley_is_parked() -> void:
	var root := await _add_mission()
	var motion := [Vector2(2528, 1696), Vector2(2784, 1696)]
	_assert_blocked_motion("vip_left_gate_closed", motion[0], motion[1])
	var player := root.get_node("EntityRoot/Player")
	var wait_marker := root.get_node("GameplayRoot/MissionMechanics/BentleyWaitMarker_velvet_paw_jazz_club_bentley_wait_marker_01")
	var wait_result: Dictionary = wait_marker.call("run_command", player, "physics_test")
	assert_bool(bool(wait_result.get("ok", false))).is_true()
	root.get_node("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController").call("_sync_vip_gate")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_assert_clear_motion("vip_left_gate_open", motion[0], motion[1])
	_assert_clear_motion("vip_left_gate_open_reverse", motion[1], motion[0])
	await _remove_mission(root)


func test_four_dynamic_blockers_block_then_existing_unlock_opens() -> void:
	for dynamic_case: Dictionary in DYNAMIC_CASES:
		_reset_runtime_state()
		var root := await _add_mission()
		var motion: Array = dynamic_case.motion
		_assert_blocked_motion(String(dynamic_case.name) + "_closed", motion[0], motion[1])
		for flag_id: String in dynamic_case.flags:
			_set_flag(flag_id)
		var mechanic := root.get_node("GameplayRoot/MissionMechanics/%s" % dynamic_case.mechanic)
		var result := mechanic.call(String(dynamic_case.method), null, "phase5_retry_physics") as Dictionary
		assert_bool(result.get("ok", false)).override_failure_message(String(dynamic_case.name)).is_true()
		var collision := root.get_node(String(dynamic_case.shape)) as CollisionShape2D
		assert_bool(collision.disabled).override_failure_message(String(dynamic_case.name)).is_true()
		await get_tree().physics_frame
		await get_tree().process_frame
		_assert_clear_motion(String(dynamic_case.name) + "_open", motion[0], motion[1])
		await _remove_mission(root)


func test_owner_stairs_uses_valid_south_route_and_teleport_grid() -> void:
	var root := await _add_mission()
	for diagnostic_point: Vector2 in [Vector2(3008, 1056), Vector2(3008, 1080)]:
		print("PHASE5_NON_ROUTE_DIAGNOSTIC point=%s %s" % [diagnostic_point, _query_diagnostic(diagnostic_point)])
	_assert_blocked_motion("owner_stairs_closed_south", Vector2(3008, 1312), Vector2(3008, 1128))
	_set_flag("vpj_shard_collected")
	MissionInventoryScript.add_item("velvet_paw_basement_keycard", 1, {"category": "credential"})
	var mechanic := root.get_node("GameplayRoot/MissionMechanics/LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_03")
	var result := mechanic.call("unlock", null, "phase5_retry_physics") as Dictionary
	assert_bool(result.get("ok", false)).is_true()
	var portal_shape := root.get_node("GameplayRoot/RouteBlockers/OwnerStairsBlocker/PortalPadShape") as CollisionShape2D
	assert_bool(portal_shape.disabled).is_true()
	await get_tree().physics_frame
	await get_tree().process_frame
	_assert_clear_motion("owner_stairs_open_south", Vector2(3008, 1312), Vector2(3008, 1120))
	_assert_clear_motion("owner_stairs_open_reverse", Vector2(3008, 1120), Vector2(3008, 1312))
	_assert_clear_points("owner_stairs_route_points", [Vector2(3008, 1120), Vector2(3008, 1216), Vector2(3008, 1312)])
	var teleport_grid: Array[Vector2] = []
	for y: float in [1108.0, 1120.0, 1132.0]:
		for x: float in [2996.0, 3008.0, 3020.0]:
			teleport_grid.append(Vector2(x, y))
	_assert_clear_points("owner_stairs_teleport_grid", teleport_grid)
	await _remove_mission(root)


func test_spawn_and_all_teleport_landings_have_usable_clearance() -> void:
	var root := await _add_mission()
	_assert_clear_grid("spawn", Vector2(256, 2880), 24.0)
	_assert_clear_grid("basement_target", Vector2(3616, 2944), 24.0)
	_assert_clear_grid("suite_target", Vector2(3616, 1216), 24.0)
	_set_flag("vpj_setlist_solved")
	var hatch := root.get_node("GameplayRoot/MissionMechanics/RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_01")
	assert_bool((hatch.call("unlock_route", null, "phase5_retry_landing") as Dictionary).get("ok", false)).is_true()
	await get_tree().physics_frame
	await get_tree().process_frame
	_assert_clear_grid("return_target_after_hatch_unlock", Vector2(1024, 1120), 24.0)
	await _remove_mission(root)


func test_owner_suite_and_basement_perimeters_prevent_void_leaks() -> void:
	var root := await _add_mission()
	for named_motion: Array in [
		["owner_north", Vector2(3904, 320), Vector2(3904, 64)],
		["owner_south", Vector2(3904, 1280), Vector2(3904, 1536)],
		["owner_west", Vector2(3648, 800), Vector2(3392, 800)],
		["owner_east", Vector2(4288, 800), Vector2(4544, 800)],
		["basement_north", Vector2(3904, 1856), Vector2(3904, 1600)],
		["basement_south", Vector2(3904, 3008), Vector2(3904, 3264)],
		["basement_west", Vector2(3648, 2432), Vector2(3392, 2432)],
		["basement_east", Vector2(4288, 2432), Vector2(4544, 2432)],
	]:
		_assert_blocked_motion(named_motion[0], named_motion[1], named_motion[2])
	await _remove_mission(root)


func test_cardinal_and_diagonal_adjacent_wall_seams_are_sealed() -> void:
	var root := await _add_mission()
	_assert_blocked_motion("seam_cardinal_cells_54_10_54_11", Vector2(3504, 232), Vector2(3504, 136))
	_assert_blocked_motion("seam_diagonal_cells_54_10_54_11", Vector2(3482.534, 226.9325), Vector2(3525.466, 141.0675))
	await _remove_mission(root)


func test_teardown_leaves_zero_new_orphans() -> void:
	var orphan_ids_before: Array[int] = get_tree().root.get_orphan_node_ids()
	var root := await _add_mission()
	await _remove_mission(root)
	await get_tree().process_frame
	assert_array(_new_orphan_ids(orphan_ids_before)).is_empty()


func _add_mission() -> Node:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().physics_frame
	return root


func _remove_mission(root: Node) -> void:
	root.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _player_shape() -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = PLAYER_SIZE
	return shape


func _shape_query(point: Vector2) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _player_shape()
	query.transform = Transform2D(0.0, point)
	query.collision_mask = WALL_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return query


func _query_hits(point: Vector2) -> Array[Dictionary]:
	var raw := get_viewport().world_2d.direct_space_state.intersect_shape(_shape_query(point), 32)
	var hits: Array[Dictionary] = []
	for entry: Dictionary in raw:
		hits.append(entry)
	return hits


func _overlaps_wall(point: Vector2) -> bool:
	return not _query_hits(point).is_empty()


func _cast_wall(from: Vector2, to: Vector2) -> PackedFloat32Array:
	var query := _shape_query(from)
	query.motion = to - from
	return get_viewport().world_2d.direct_space_state.cast_motion(query)


func _assert_blocked_motion(label: String, from: Vector2, to: Vector2) -> void:
	var cast := _cast_wall(from, to)
	print("PHASE5_MOTION %s from=%s to=%s safe_fraction=%.6f expected=blocked" % [label, from, to, cast[0]])
	assert_float(cast[0]).override_failure_message("%s %s -> %s" % [label, from, to]).is_less(0.999)


func _assert_clear_motion(label: String, from: Vector2, to: Vector2) -> void:
	var cast := _cast_wall(from, to)
	print("PHASE5_MOTION %s from=%s to=%s safe_fraction=%.6f expected=clear" % [label, from, to, cast[0]])
	assert_bool(_overlaps_wall(from)).override_failure_message("%s start: %s" % [label, _query_diagnostic(from)]).is_false()
	assert_bool(_overlaps_wall(to)).override_failure_message("%s end: %s" % [label, _query_diagnostic(to)]).is_false()
	assert_float(cast[0]).override_failure_message("%s %s -> %s" % [label, from, to]).is_equal(1.0)


func _assert_clear_grid(label: String, center: Vector2, spacing: float) -> void:
	var points: Array[Vector2] = []
	for y: float in [-spacing, 0.0, spacing]:
		for x: float in [-spacing, 0.0, spacing]:
			points.append(center + Vector2(x, y))
	_assert_clear_points(label, points)


func _assert_clear_points(label: String, points: Array[Vector2]) -> void:
	var blocked: Array[String] = []
	for point: Vector2 in points:
		if _overlaps_wall(point):
			blocked.append(_query_diagnostic(point))
	print("PHASE5_CLEARANCE %s points=%s blocked=%s" % [label, points, blocked])
	assert_array(blocked).override_failure_message(label).is_empty()


func _query_diagnostic(point: Vector2) -> String:
	var rows: Array[String] = []
	for hit: Dictionary in _query_hits(point):
		var collider: Object = hit.get("collider") as Object
		var shape_index := int(hit.get("shape", -1))
		var row := "collider_rid=%s shape_index=%d" % [hit.get("rid", RID()), shape_index]
		if collider != null:
			row += " collider_class=%s" % collider.get_class()
			if collider is Node:
				row += " collider_path=%s" % (collider as Node).get_path()
		if collider is CollisionObject2D and shape_index >= 0:
			var collision_object := collider as CollisionObject2D
			var owner_id := collision_object.shape_find_owner(shape_index)
			var owner: Object = collision_object.shape_owner_get_owner(owner_id) if owner_id != 0 else null
			if owner is Node:
				var owner_node := owner as Node
				row += " owner_path=%s owner_class=%s" % [owner_node.get_path(), owner_node.get_class()]
				if owner_node.has_meta("source_cell"):
					row += " source_cell=%s" % owner_node.get_meta("source_cell")
				if owner_node is CollisionPolygon2D:
					row += " polygon=%s" % (owner_node as CollisionPolygon2D).polygon
				elif owner_node is CollisionShape2D:
					row += " shape=%s" % (owner_node as CollisionShape2D).shape
		rows.append(row)
	return "query_shape=%s transform=%s hits=[%s]" % [PLAYER_SIZE, Transform2D(0.0, point), "; ".join(rows)]


func _set_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": MISSION_ID})


func _reset_runtime_state() -> void:
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	for key: Variant in GameState.dialogue_flags.keys():
		if String(key).begins_with("mission_flag:%s:" % MISSION_ID):
			GameState.dialogue_flags.erase(key)
	MissionInventoryScript.clear_mission_items()
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()


func _new_orphan_ids(ids_before: Array[int]) -> Array[int]:
	var ids: Array[int] = []
	for id: int in get_tree().root.get_orphan_node_ids():
		if not ids_before.has(id):
			ids.append(id)
	ids.sort()
	return ids
