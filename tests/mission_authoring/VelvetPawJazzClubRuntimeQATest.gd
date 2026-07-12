extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const CONTROLLER_PATH := "GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController"
const RETURN_ZONE_PATH := "GameplayRoot/MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02"
const EXPECTED_RETURN_PATH := NodePath("../../MissionMechanics/TeleportZone_velvet_paw_jazz_club_teleport_zone_02")
const MECHANICS := "GameplayRoot/MissionMechanics/"
const WALL_MASK := 4
const PLAYER_SIZE := Vector2(24, 24)
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

const BLOCKER_PATHS := {
	"front_rope": "GameplayRoot/RouteBlockers/FrontEntranceCrowdRopeBlocker/RopeShape",
	"staff_row": "GameplayRoot/RouteBlockers/StaffGateBlocker/StageRowShape",
	"staff_wing": "GameplayRoot/RouteBlockers/StaffGateBlocker/StageWingShape",
	"backstage": "GameplayRoot/RouteBlockers/BackstageHatchBlocker/HatchShape",
	"vault": "GameplayRoot/RouteBlockers/ServerVaultBlocker/VaultShape",
	"owner": "GameplayRoot/RouteBlockers/OwnerStairsBlocker/PortalPadShape",
	"escape": "GameplayRoot/RouteBlockers/EscapeHatchBlocker/HatchLidShape",
}
const SOURCE_LAYERS := [
	"GameplayRoot/LayoutRoot/FloorLayer",
	"GameplayRoot/LayoutRoot/WallLayer",
	"GameplayRoot/LayoutRoot/CoverLayer",
	"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	"GameplayRoot/LayoutRoot/MarkerTileLayer",
]


func before() -> void:
	_reset_runtime_state()


func after() -> void:
	_reset_runtime_state()


func test_return_teleport_path_resolves_detached_to_exact_zone() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var controller := root.get_node(CONTROLLER_PATH)
	var return_zone := root.get_node(RETURN_ZONE_PATH)
	assert_str(String(controller.get("return_teleport_path"))).is_equal(String(EXPECTED_RETURN_PATH))
	assert_object(controller.get_node_or_null(controller.get("return_teleport_path"))).is_same(return_zone)
	root.free()


func test_return_without_shard_cannot_set_hostile_state() -> void:
	var orphan_ids_before: Array[int] = get_tree().root.get_orphan_node_ids()
	var root := await _add_mission()
	var actor := _add_player_actor(root)
	var controller := root.get_node(CONTROLLER_PATH)
	var return_zone := root.get_node(RETURN_ZONE_PATH)
	var result := return_zone.call("activate", actor, "phase6_retry_negative") as Dictionary
	_assert_failed(result, "return without shard")
	assert_bool(bool(controller.get("returned_upstairs_with_shard"))).is_false()
	assert_bool(GameState.velvet_paw_club_hostile).is_false()
	assert_bool(ObjectiveStepController.is_objective_completed("return_upstairs", MISSION_ID)).is_false()
	assert_bool(ObjectiveStepController.is_objective_active("defeat_owner", MISSION_ID)).is_false()
	await _remove_mission(root)
	assert_array(_new_orphan_ids(orphan_ids_before)).is_empty()


func test_real_shard_pickup_and_return_teleport_set_hostile_and_advance_objective() -> void:
	var orphan_ids_before: Array[int] = get_tree().root.get_orphan_node_ids()
	var root := await _add_mission()
	var actor := _add_player_actor(root)
	_set_flag("vpj_server_vault_open")
	var shard := root.get_node(MECHANICS + "InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_02")
	_assert_succeeded(shard.call("collect", actor, "phase6_retry_regression"), "legitimate shard pickup")
	var controller := root.get_node(CONTROLLER_PATH)
	controller.call("sync_from_mission_facts")
	assert_bool(bool(controller.get("shard_collected"))).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_false()
	assert_bool(bool(controller.get("returned_upstairs_with_shard"))).is_false()
	var return_zone := root.get_node(RETURN_ZONE_PATH)
	var result := return_zone.call("activate", actor, "phase6_retry_regression") as Dictionary
	_assert_succeeded(result, "return teleport")
	assert_vector(actor.global_position).is_equal(Vector2(1024, 1120))
	assert_bool(bool(controller.get("returned_upstairs_with_shard"))).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_true()
	assert_bool(ObjectiveStepController.is_objective_completed("return_upstairs", MISSION_ID)).is_true()
	assert_bool(ObjectiveStepController.is_objective_active("defeat_owner", MISSION_ID)).is_true()
	await _remove_mission(root)
	assert_array(_new_orphan_ids(orphan_ids_before)).is_empty()


func test_three_complete_runtime_cycles_are_fresh_deterministic_and_orphan_free() -> void:
	var orphan_ids_before: Array[int] = get_tree().root.get_orphan_node_ids()
	var expected_signatures: Dictionary = {}
	for cycle: int in range(1, 4):
		_reset_runtime_state()
		var root := await _add_mission()
		var signatures := _source_signatures(root)
		if expected_signatures.is_empty():
			expected_signatures = signatures
		else:
			assert_dict(signatures).override_failure_message("cycle %d source signatures" % cycle).is_equal(expected_signatures)
		_assert_fresh_runtime_contract(root, cycle)
		var floor_count := (root.get_node("GameplayRoot/GameplayFloorLayer") as TileMapLayer).get_used_cells().size()
		await _remove_mission(root)
		assert_array(_new_orphan_ids(orphan_ids_before)).override_failure_message("cycle %d orphan growth" % cycle).is_empty()
		print("ROUTE1_CYCLE cycle=%d floor=%d collision=1984 proxy=1418 dynamic_enabled=7 orphan_growth=0" % [cycle, floor_count])


func test_critical_route_obeys_requirements_and_physical_blockers() -> void:
	var root := await _add_mission()
	var actor := _add_player_actor(root)
	_assert_clear_motion("staff_entrance_initial", Vector2(2976, 2400), Vector2(2976, 2656))
	_assert_blocked_motion("front_entrance_initial", Vector2(1440, 2400), Vector2(1440, 2656))
	_assert_disabled_blockers(root, [])

	var staff_gate := root.get_node(MECHANICS + "LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_01")
	_assert_failed(staff_gate.call("unlock", actor, "phase6_retry_before_badge"), "staff before badge")
	var badge := root.get_node(MECHANICS + "InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_01")
	_assert_succeeded(badge.call("collect", actor, "phase6_retry_route"), "badge")
	_assert_succeeded(staff_gate.call("unlock", actor, "phase6_retry_route"), "staff gate")
	await _flush_physics()
	_assert_clear_motion("staff_gate_open", Vector2(2048, 928), Vector2(2048, 1184))
	_assert_disabled_blockers(root, ["staff_row", "staff_wing"])

	var hatch := root.get_node(MECHANICS + "RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_01")
	_assert_failed(hatch.call("unlock_route", actor, "phase6_retry_before_setlist"), "hatch before setlist")
	_assert_blocked_motion("backstage_hatch_closed", Vector2(1024, 928), Vector2(1024, 1184))
	_set_flag("vpj_clue_setlist_read")
	_set_flag("vpj_clue_manager_read")
	var terminal := root.get_node(MECHANICS + "TerminalHackNode_velvet_paw_jazz_club_terminal_hack_node_01")
	_assert_succeeded(terminal.call("hack", actor, "phase6_retry_route"), "setlist")
	_assert_succeeded(hatch.call("unlock_route", actor, "phase6_retry_route"), "hatch")
	await _flush_physics()
	_assert_clear_motion("backstage_hatch_open", Vector2(1024, 928), Vector2(1024, 1184))
	_assert_disabled_blockers(root, ["staff_row", "staff_wing", "backstage"])
	_assert_teleport(root.get_node(MECHANICS + "TeleportZone_velvet_paw_jazz_club_teleport_zone_01"), actor, Vector2(3616, 2944), "basement")

	var vault := root.get_node(MECHANICS + "LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_02")
	_assert_failed(vault.call("unlock", actor, "phase6_retry_before_power"), "vault before power")
	_assert_blocked_motion("server_vault_closed", Vector2(3936, 2016), Vector2(3936, 2272))
	_set_flag("vpj_yordano_briefed")
	var power := root.get_node(MECHANICS + "PowerCircuitNode_velvet_paw_jazz_club_power_circuit_node_01")
	_assert_succeeded(power.call("check_circuit", actor, "phase6_retry_route"), "power")
	_assert_succeeded(vault.call("unlock", actor, "phase6_retry_route"), "vault")
	await _flush_physics()
	_assert_clear_motion("server_vault_open", Vector2(3936, 2016), Vector2(3936, 2272))
	_assert_disabled_blockers(root, ["staff_row", "staff_wing", "backstage", "vault"])
	var shard := root.get_node(MECHANICS + "InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_02")
	var keycard := root.get_node(MECHANICS + "InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_03")
	_assert_succeeded(shard.call("collect", actor, "phase6_retry_route"), "shard")
	_assert_succeeded(keycard.call("collect", actor, "phase6_retry_route"), "keycard")

	_assert_blocked_motion("owner_stairs_closed", Vector2(3008, 1312), Vector2(3008, 1128))
	_assert_teleport(root.get_node(RETURN_ZONE_PATH), actor, Vector2(1024, 1120), "return")
	var controller := root.get_node(CONTROLLER_PATH)
	assert_bool(bool(controller.get("returned_upstairs_with_shard"))).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_true()
	var owner_stairs := root.get_node(MECHANICS + "LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_03")
	_assert_succeeded(owner_stairs.call("unlock", actor, "phase6_retry_route"), "owner stairs")
	await _flush_physics()
	_assert_clear_motion("owner_stairs_open", Vector2(3008, 1312), Vector2(3008, 1120))
	_assert_disabled_blockers(root, ["staff_row", "staff_wing", "backstage", "vault", "owner"])
	_assert_teleport(root.get_node(MECHANICS + "TeleportZone_velvet_paw_jazz_club_teleport_zone_03"), actor, Vector2(3616, 1216), "suite")

	var escape := root.get_node(MECHANICS + "RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_02")
	_assert_failed(escape.call("unlock_route", actor, "phase6_retry_before_briefcase"), "escape before briefcase")
	_assert_blocked_motion("escape_hatch_closed", Vector2(4224, 2560), Vector2(4224, 2816))
	var owner := root.get_node(MECHANICS + "ChallengeObjectiveNode_velvet_paw_jazz_club_challenge_objective_node_01")
	var briefcase := root.get_node(MECHANICS + "RewardNode_velvet_paw_jazz_club_reward_node_01")
	_assert_succeeded(owner.call("complete_objective", actor, "phase6_retry_route"), "owner")
	_assert_succeeded(briefcase.call("collect", actor, "phase6_retry_route"), "briefcase")
	_assert_succeeded(escape.call("unlock_route", actor, "phase6_retry_route"), "escape")
	await _flush_physics()
	_assert_clear_motion("escape_hatch_open", Vector2(4224, 2560), Vector2(4224, 2816))
	_assert_disabled_blockers(root, ["staff_row", "staff_wing", "backstage", "vault", "owner", "escape"])
	var extraction := root.get_node(MECHANICS + "ExtractionZone_velvet_paw_jazz_club_extraction_zone_01")
	for objective_id: String in ["solve_setlist", "recover_shard", "defeat_owner", "recover_briefcase", "open_escape"]:
		if not ObjectiveStepController.is_objective_completed(objective_id, MISSION_ID):
			ObjectiveStepController.complete_objective(objective_id, "", MISSION_ID)
	var can_extract := extraction.call("can_extract", actor) as Dictionary
	_assert_succeeded(can_extract, "can_extract")
	assert_str(String(can_extract.get("code", ""))).is_equal("can_extract")
	print("PHASE6_RETRY_ROUTE all_requirements=pass all_blockers=pass teleports=pass hostile=pass can_extract=pass")
	await _remove_mission(root)


func test_vip_front_inspection_opens_dynamic_rope_and_front_entry() -> void:
	var root := await _add_mission()
	var actor := _add_player_actor(root)
	_assert_blocked_motion("front_vip_closed", Vector2(1440, 2656), Vector2(1440, 2400))
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapter.set_cover_story("velvet_paw_vip_guest", {}, context)
	SocialStealthAdapter.grant_credential("velvet_paw_vip_wristband", {}, context)
	var inspection := root.get_node(MECHANICS + "InspectionZone_velvet_paw_jazz_club_inspection_zone_01")
	_assert_succeeded(inspection.call("activate", actor, "route_component_1_vip"), "VIP front inspection")
	var rope_shape := root.get_node(BLOCKER_PATHS.front_rope) as CollisionShape2D
	assert_bool(rope_shape.disabled).is_true()
	assert_bool((root.get_node("ArtRoot/FrontEntranceCrowdRope") as CanvasItem).visible).is_false()
	await get_tree().physics_frame
	await get_tree().process_frame
	_assert_clear_motion("front_vip_open", Vector2(1440, 2656), Vector2(1440, 2400))
	var entry := root.get_node(MECHANICS + "TriggerZone_velvet_paw_front_entry")
	_assert_succeeded(entry.call("activate", actor, "route_component_1_front_entry"), "VIP front entry")
	assert_bool(_flag("vpj_entered_club")).is_true()
	await _remove_mission(root)


func test_side_door_entry_starts_floor_music_in_normal_alert_state() -> void:
	var root := await _add_mission()
	GameState.velvet_paw_club_hostile = false
	var actor := _add_player_actor(root)
	var alert := root.get_node("GameplayRoot/RuntimeHelpers/MissionAlertController")
	alert.call("set_alert_state", "normal")
	alert.set("alert_score", 0.0)
	var entry := root.get_node(MECHANICS + "TriggerZone_velvet_paw_jazz_club_trigger_zone_01")
	_assert_succeeded(entry.call("activate", actor, "side_door_music_regression"), "side-door entry")
	assert_bool(_flag("vpj_entered_club")).is_true()
	assert_int(AudioServer.get_bus_index("Music")).is_greater_equal(0)
	assert_str(String(AudioManager.get_node("MusicPlayer").bus)).is_equal("Music")
	assert_bool(AudioManager.is_music_playing("velvet_paw_floor")).is_true()
	await _remove_mission(root)


func test_vip_polaroid_requires_protocol_and_voicemail() -> void:
	var was_collected := CollectibleManager.is_collected("velvet_vip_champagne_polaroid")
	GameState.collected_polaroids.erase("velvet_vip_champagne_polaroid")
	var root := await _add_mission()
	var controller := root.get_node(CONTROLLER_PATH)
	var pickup := root.get_node(MECHANICS + "VipChampagnePolaroid") as Area2D
	_set_flag("vpj_vip_voicemail_found")
	controller.call("_sync_vip_polaroid")
	assert_bool(pickup.visible).is_false()
	assert_int(pickup.collision_layer).is_equal(0)
	_set_flag("vpj_vip_protocol_complete")
	controller.call("_sync_vip_polaroid")
	assert_bool(pickup.visible).is_true()
	assert_int(pickup.collision_layer).is_equal(8)
	await _remove_mission(root)
	if was_collected:
		GameState.collected_polaroids.append("velvet_vip_champagne_polaroid")


func test_room_visibility_only_reveals_the_players_current_area() -> void:
	var root := await _add_mission()
	var controller := root.get_node(CONTROLLER_PATH)
	var player := controller.call("_find_room_visibility_player") as Node2D
	if player == null:
		player = _add_player_actor(root)
	var curtains := controller.get_node("RoomVisibilityCurtains") as Node2D
	assert_int(curtains.get_child_count()).is_equal(7)
	var representative_points := {
		"street": Vector2(256, 2880),
		"club_main": Vector2(2048, 1536),
		"bathroom": Vector2(320, 736),
		"stage": Vector2(1280, 736),
		"backstage": Vector2(2560, 736),
		"owner_suite": Vector2(3904, 800),
		"basement": Vector2(3904, 2432),
	}
	for expected_area: String in representative_points:
		player.global_position = representative_points[expected_area]
		controller.call("_update_room_visibility")
		var summary := controller.call("get_room_visibility_summary") as Dictionary
		assert_str(String(summary.get("active_area_id", ""))).is_equal(expected_area)
		var visibility := summary.get("curtain_visibility", {}) as Dictionary
		for area_id: String in visibility:
			assert_bool(bool(visibility[area_id])).override_failure_message("%s while player is in %s" % [area_id, expected_area]).is_equal(area_id != expected_area)
	for curtain: Node in curtains.get_children():
		assert_bool(curtain is Polygon2D).is_true()
		assert_int(curtain.get_child_count()).is_equal(0)
	player.global_position = representative_points.street
	controller.call("_update_room_visibility")
	player.global_position = Vector2(1440, 2528)
	controller.call("_update_room_visibility")
	assert_str(String((controller.call("get_room_visibility_summary") as Dictionary).get("active_area_id", ""))).is_equal("street")
	await _remove_mission(root)


func test_runtime_camera_patrol_spawn_targets_art_and_overlay_contract() -> void:
	var root := await _add_mission()
	var spawn := root.get_node("GameplayRoot/SpawnPoints/default") as Marker2D
	var authored_spawn := root.get_node("GameplayRoot/MarkerRoot/Spawns/PlayerStartMarker_start_main") as Marker2D
	assert_vector(spawn.global_position).is_equal(Vector2(256, 2880))
	assert_vector(authored_spawn.global_position).is_equal(Vector2(256, 2880))
	_assert_clear_point("spawn", spawn.global_position)
	_set_flag("vpj_setlist_solved")
	var hatch := root.get_node(MECHANICS + "RouteUnlockNode_velvet_paw_jazz_club_route_unlock_node_01")
	_assert_succeeded(hatch.call("unlock_route", null, "phase6_retry_world"), "hatch for return landing")
	await _flush_physics()
	for target_name: String in [
		"TeleportTargetMarker_velvet_paw_jazz_club_teleport_target_marker_01",
		"TeleportTargetMarker_velvet_paw_jazz_club_teleport_target_marker_02",
		"TeleportTargetMarker_velvet_paw_jazz_club_teleport_target_marker_03",
	]:
		var target := root.get_node(MECHANICS + target_name) as Marker2D
		_assert_clear_point(target_name, target.global_position)

	var camera := root.get_node("Camera2D") as Camera2D
	for named_point: Array in [
		["street", Vector2(256, 2880)],
		["club", Vector2(2048, 1536)],
		["suite", Vector2(3616, 1216)],
		["basement", Vector2(3616, 2944)],
	]:
		_assert_camera_contains(camera, String(named_point[0]), named_point[1])
	assert_object(root.get_node_or_null("GameplayRoot/LayoutRoot/AuthoringBlueprintLayer")).is_null()

	var routes := root.get_node("GameplayRoot/SecurityAuthoringRoot").call("get_enabled_patrol_route_authors") as Array
	var waypoint_count := 0
	for route: Node in routes:
		for waypoint: Node in route.get_children():
			if waypoint is Node2D:
				waypoint_count += 1
				_assert_clear_point(str(waypoint.get_path()), (waypoint as Node2D).global_position)
	assert_int(waypoint_count).is_equal(20)
	var art := root.get_node("ArtRoot")
	assert_array(art.find_children("*", "CollisionObject2D", true, false)).is_empty()
	for child: Node in art.get_children():
		if child is TileMapLayer:
			assert_array((child as TileMapLayer).get_used_cells()).is_empty()
	print("PHASE6_RETRY_WORLD camera=street_club_suite_basement patrol=20_clear spawn_targets=4_clear art=clear overlay=absent")
	await _remove_mission(root)


func _assert_fresh_runtime_contract(root: Node, cycle: int) -> void:
	var floor_count := (root.get_node("GameplayRoot/GameplayFloorLayer") as TileMapLayer).get_used_cells().size()
	var source_floor_count := (root.get_node("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer).get_used_cells().size()
	assert_int(floor_count).override_failure_message("cycle %d floor/source mismatch" % cycle).is_equal(source_floor_count)
	assert_int((root.get_node("GameplayRoot/GameplayCollisionLayer") as TileMapLayer).get_used_cells().size()).override_failure_message("cycle %d collision" % cycle).is_equal(1984)
	assert_int(root.find_children("GeneratedRuntimeCollision", "", true, false).size()).is_equal(1)
	assert_int(root.find_children("RouteBlockers", "", true, false).size()).is_equal(1)
	var proxy := root.get_node("GameplayRoot/GeneratedRuntimeCollision/WallCollision/WallCellBody")
	assert_int(proxy.get_child_count()).is_equal(1418)
	assert_int(int(proxy.get("generated_shape_count"))).is_equal(1418)
	assert_int(root.get_node("GameplayRoot/RouteBlockers").get_child_count()).is_equal(7)
	_assert_disabled_blockers(root, [])
	assert_bool(MissionInventoryScript.has_item("velvet_paw_staff_badge")).is_false()
	assert_bool(GameState.velvet_paw_club_hostile).is_false()
	assert_bool(_flag("vpj_staff_gate_open")).is_false()
	assert_bool(_flag("vpj_escape_hatch_open")).is_false()


func _add_player_actor(root: Node) -> Node2D:
	var actor := Node2D.new()
	actor.name = "Phase6RetryPlayer"
	actor.add_to_group("player")
	root.add_child(actor)
	actor.global_position = Vector2(256, 2880)
	return actor


func _assert_teleport(zone: Node, actor: Node2D, expected: Vector2, label: String) -> void:
	var target := zone.get_node_or_null(zone.get("target_marker_path")) as Node2D
	assert_object(target).override_failure_message(label).is_not_null()
	assert_vector(target.global_position).override_failure_message(label).is_equal(expected)
	_assert_clear_point(label + " target", expected)
	_assert_succeeded(zone.call("activate", actor, "phase6_retry_route"), label)
	assert_vector(actor.global_position).override_failure_message(label).is_equal(expected)
	_assert_clear_point(label + " arrival", actor.global_position)


func _assert_disabled_blockers(root: Node, disabled_keys: Array) -> void:
	for key: String in BLOCKER_PATHS:
		var shape := root.get_node(BLOCKER_PATHS[key]) as CollisionShape2D
		assert_bool(shape.disabled).override_failure_message(key).is_equal(disabled_keys.has(key))


func _assert_succeeded(value: Variant, label: String) -> void:
	var result := value as Dictionary
	assert_bool(bool(result.get("ok", false))).override_failure_message("%s: %s" % [label, result]).is_true()


func _assert_failed(value: Variant, label: String) -> void:
	var result := value as Dictionary
	assert_bool(bool(result.get("ok", true))).override_failure_message("%s: %s" % [label, result]).is_false()


func _assert_blocked_motion(label: String, from: Vector2, to: Vector2) -> void:
	assert_float(_cast_wall(from, to)[0]).override_failure_message(label).is_less(0.999)


func _assert_clear_motion(label: String, from: Vector2, to: Vector2) -> void:
	assert_array(_query_hits(from)).override_failure_message(label + " start").is_empty()
	assert_array(_query_hits(to)).override_failure_message(label + " end").is_empty()
	assert_float(_cast_wall(from, to)[0]).override_failure_message(label).is_equal(1.0)


func _assert_clear_point(label: String, point: Vector2) -> void:
	assert_array(_query_hits(point)).override_failure_message("%s at %s" % [label, point]).is_empty()


func _assert_camera_contains(camera: Camera2D, label: String, point: Vector2) -> void:
	var contained := point.x >= camera.limit_left and point.x <= camera.limit_right and point.y >= camera.limit_top and point.y <= camera.limit_bottom
	assert_bool(contained).override_failure_message("%s %s limits=(%d,%d)-(%d,%d)" % [label, point, camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]).is_true()


func _shape_query(point: Vector2) -> PhysicsShapeQueryParameters2D:
	var shape := RectangleShape2D.new()
	shape.size = PLAYER_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = WALL_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return query


func _query_hits(point: Vector2) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for hit: Dictionary in get_viewport().world_2d.direct_space_state.intersect_shape(_shape_query(point), 32):
		hits.append(hit)
	return hits


func _cast_wall(from: Vector2, to: Vector2) -> PackedFloat32Array:
	var query := _shape_query(from)
	query.motion = to - from
	return get_viewport().world_2d.direct_space_state.cast_motion(query)


func _source_signatures(root: Node) -> Dictionary:
	var signatures: Dictionary = {}
	for path: String in SOURCE_LAYERS:
		var layer := root.get_node(path) as TileMapLayer
		var rows: Array[String] = []
		var cells: Array[Vector2i] = layer.get_used_cells()
		cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
		for cell: Vector2i in cells:
			var atlas := layer.get_cell_atlas_coords(cell)
			rows.append("%d,%d:%d:%d,%d" % [cell.x, cell.y, layer.get_cell_source_id(cell), atlas.x, atlas.y])
		signatures[path] = rows
	return signatures


func _add_mission() -> Node:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	add_child(root)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	return root


func _remove_mission(root: Node) -> void:
	root.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _flush_physics() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame


func _set_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": MISSION_ID})


func _flag(flag_id: String) -> bool:
	return bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_id, {"mission_id": MISSION_ID}))


func _reset_runtime_state() -> void:
	AudioManager.stop_music()
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


func _new_orphan_ids(ids_before: Array[int]) -> Array[int]:
	var ids: Array[int] = []
	for id: int in get_tree().root.get_orphan_node_ids():
		if not ids_before.has(id):
			ids.append(id)
	ids.sort()
	return ids
