extends GdUnitTestSuite

const TeleportZoneScript := preload("res://src/missions/iso/authoring/mechanics/TeleportZone.gd")
const TeleportTargetMarkerScript := preload("res://src/missions/iso/authoring/mechanics/TeleportTargetMarker.gd")
const MusicTriggerZoneScript := preload("res://src/missions/iso/authoring/mechanics/MusicTriggerZone.gd")
const PlayerStartMarkerScript := preload("res://src/missions/iso/authoring/mechanics/PlayerStartMarker.gd")
const HideSpotNodeScript := preload("res://src/missions/iso/authoring/mechanics/HideSpotNode.gd")
const IsoMissionBaseScript := preload("res://src/levels/IsoMissionBase.gd")
const MissionDefinitionScript := preload("res://src/missions/definitions/MissionDefinition.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const PlayerScript := preload("res://src/player/Player.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const MissionPauseDataProviderScript := preload("res://src/missions/ui/MissionPauseDataProvider.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const MILESTONE_A_PROOF_SCENE := "res://scenes/dev/mission_authoring/MilestoneAProofMission.tscn"


func test_player_start_marker_matches_existing_spawn_authoring_convention() -> void:
	var marker := PlayerStartMarkerScript.new()
	assert_str(String(marker.marker_type)).is_equal("PLAYER_SPAWN")
	assert_str(String(marker.marker_id)).is_equal("start_main")
	assert_str(String(marker.group_id)).is_equal("spawns")
	marker.free()


func test_player_start_marker_creates_default_and_start_main_spawn_points() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "MilestoneAStartTest"
	var definition := MissionDefinitionScript.new()
	definition.mission_id = "milestone_a_start_test"
	mission.set("mission_definition", definition)
	mission.set("auto_generate_from_definition", false)
	mission.call("_ensure_iso_structure")
	var marker_root := mission.get_node("GameplayRoot/MarkerRoot/Spawns")
	var start := PlayerStartMarkerScript.new()
	start.name = "PlayerStartMarker_Test"
	start.global_position = Vector2(123.0, -45.0)
	marker_root.add_child(start)

	mission.call("_reset_marker_index")
	mission.call("_create_spawn_points")

	var default_spawn := mission.get_node_or_null("GameplayRoot/SpawnPoints/default") as Node2D
	var start_main_spawn := mission.get_node_or_null("GameplayRoot/SpawnPoints/start_main") as Node2D
	assert_object(default_spawn).is_not_null()
	assert_object(start_main_spawn).is_not_null()
	assert_vector(default_spawn.global_position).is_equal(start.global_position)
	assert_vector(start_main_spawn.global_position).is_equal(start.global_position)

	mission.free()


func test_milestone_a_proof_scene_has_bridge_and_valid_teleport_targets() -> void:
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	assert_object(root.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionInteractionBridge")).is_not_null()
	var bridge := root.get_node("GameplayRoot/RuntimeHelpers/MissionInteractionBridge")
	assert_bool(bool(bridge.get("include_legacy_candidates"))).is_false()
	var sec_root := root.get_node_or_null("GameplayRoot/SecurityAuthoringRoot")
	assert_object(sec_root).is_not_null()
	assert_bool(bool(sec_root.get("runtime_enabled"))).is_true()
	var camera_author := root.get_node_or_null("GameplayRoot/SecurityAuthoringRoot/SecurityCameraAuthor_milestone_a_proof_security_camera_author_01")
	assert_object(camera_author).is_not_null()
	assert_bool(bool(camera_author.get("sweep_enabled"))).is_true()
	for index in range(1, 8):
		var zone_name := "MissionMechanics/TeleportZone_milestone_a_proof_teleport_zone_%02d" % index
		var zone := root.get_node_or_null(zone_name)
		assert_object(zone).is_not_null()
		var target_path: NodePath = zone.get("target_marker_path")
		assert_str(str(target_path)).is_not_equal(".")
		assert_object(zone.get_node_or_null(target_path)).is_not_null()
	_free_node(root)


func test_milestone_a_proof_camera_bounds_cover_authored_teleport_targets() -> void:
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	root.call("_apply_camera_bounds")
	var camera := root.get_node_or_null("Camera2D") as Camera2D
	assert_object(camera).is_not_null()
	for index in range(1, 8):
		var marker_name := "MissionMechanics/TeleportTargetMarker_milestone_a_proof_teleport_target_marker_%02d" % index
		var marker := root.get_node_or_null(marker_name) as Node2D
		assert_object(marker).is_not_null()
		assert_bool(marker.global_position.x >= float(camera.limit_left)).is_true()
		assert_bool(marker.global_position.x <= float(camera.limit_right)).is_true()
		assert_bool(marker.global_position.y >= float(camera.limit_top)).is_true()
		assert_bool(marker.global_position.y <= float(camera.limit_bottom)).is_true()
	_free_node(root)


func test_milestone_a_proof_inventory_chain_is_self_contained() -> void:
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	var pickup := root.get_node_or_null("MissionMechanics/InventoryPickupNode_milestone_a_proof_inventory_pickup_node_01")
	var swap := root.get_node_or_null("MissionMechanics/ObjectSwapNode_milestone_a_proof_object_swap_node_01")
	var bug := root.get_node_or_null("MissionMechanics/BugPlantNode_milestone_a_proof_bug_plant_node_01")
	var drop := root.get_node_or_null("MissionMechanics/DeadDropNode_milestone_a_proof_dead_drop_node_01")
	assert_object(pickup).is_not_null()
	assert_object(swap).is_not_null()
	assert_object(bug).is_not_null()
	assert_object(drop).is_not_null()
	assert_str(String(pickup.get("item_id"))).is_equal(String(swap.get("required_item_id")))
	assert_str(String(swap.get("replacement_item_id"))).is_equal(String(bug.get("bug_item_id")))
	assert_str(String(drop.get("drop_mode"))).is_equal("retrieve")
	_free_node(root)


func test_milestone_a_proof_teleports_bypass_prior_interaction_requirements() -> void:
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	for index in range(1, 8):
		var zone_name := "MissionMechanics/TeleportZone_milestone_a_proof_teleport_zone_%02d" % index
		var zone := root.get_node_or_null(zone_name)
		assert_object(zone).is_not_null()
		assert_bool(bool(zone.get("require_prior_interaction"))).is_false()
	_free_node(root)


func test_milestone_a_proof_extraction_is_configured_for_visible_result_screen() -> void:
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	var extract := root.get_node_or_null("MissionMechanics/ExtractionZone_milestone_a_proof_core_extract_01")
	assert_object(extract).is_not_null()
	assert_bool(extract.get("show_result_screen_on_success") == true).is_true()
	assert_bool(extract.get("complete_mission_on_success") == true).is_true()
	assert_str(String(extract.get("missing_objective_message"))).contains("Side Obj")
	_free_node(root)


func test_milestone_a_proof_teleports_are_reusable_and_work_after_route_unlock() -> void:
	var snapshot := _snapshot_game_state()
	GameState.current_mission_id = "milestone_a_proof"
	GameState.dialogue_flags["mission_flag:milestone_a_proof:route_open"] = true
	var packed := load(MILESTONE_A_PROOF_SCENE) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	for index in range(1, 8):
		var zone_name := "MissionMechanics/TeleportZone_milestone_a_proof_teleport_zone_%02d" % index
		var marker_name := "MissionMechanics/TeleportTargetMarker_milestone_a_proof_teleport_target_marker_%02d" % index
		var zone := root.get_node_or_null(zone_name)
		var marker := root.get_node_or_null(marker_name) as Node2D
		assert_object(zone).is_not_null()
		assert_object(marker).is_not_null()
		assert_bool(bool(zone.get("one_shot"))).is_false()
		var result: Dictionary = zone.call("activate", player, "test")
		assert_bool(bool(result.get("ok", false))).is_true()
		assert_vector(player.global_position).is_equal(marker.global_position)
	_restore_game_state(snapshot)
	_free_node(root)


func test_authored_poop_bag_updates_canonical_counts_immediately() -> void:
	var snapshot := _snapshot_game_state()
	GameState.poop_bag_count = 0
	GameState.poop_bags_this_mission_attempt = 0
	GameState.poop_bag_inventory = {"count": 0, "collected_this_mission": 0, "used_this_mission": 0}
	GameState.is_in_mission = true
	var mission: Node = IsoMissionBaseScript.new()
	var result: Dictionary = mission.call("record_authored_collectible_attempt", "proof_poop", "poop_bag", {"poop_count": 1}, null)
	assert_bool(bool(result.get("success", false))).is_true()
	assert_bool(bool(result.get("real_system_updated", false))).is_true()
	assert_int(GameState.get_poop_bag_count()).is_equal(1)
	assert_int(GameState.poop_bags_this_mission_attempt).is_equal(1)
	assert_int(mission.call("get_attempt_counter", "poop_bags_collected")).is_equal(1)
	_restore_game_state(snapshot)
	mission.free()


func test_authored_clue_is_visible_to_pause_snapshot_during_attempt() -> void:
	var snapshot := _snapshot_game_state()
	GameState.current_mission_id = "milestone_a_proof"
	var mission: Node = IsoMissionBaseScript.new()
	var definition := MissionDefinitionScript.new()
	definition.mission_id = "milestone_a_proof"
	mission.set("mission_definition", definition)
	var result: Dictionary = mission.call(
		"record_authored_collectible_attempt",
		"proof_clue",
		"evidence_clue",
		{
			"clue_id": "proof_clue",
			"clue_title": "Proof Clue",
			"clue_text": "Visible before mission completion.",
		},
		null
	)
	assert_bool(bool(result.get("success", false))).is_true()
	var snap: Dictionary = MissionPauseDataProviderScript.get_clue_snapshot("milestone_a_proof", mission)
	assert_int((snap.get("items", []) as Array).size()).is_equal(1)
	var row: Dictionary = (snap.get("items", []) as Array)[0] as Dictionary
	assert_str(String(row.get("id", ""))).is_equal("proof_clue")
	assert_str(String(row.get("title", ""))).is_equal("Proof Clue")
	_restore_game_state(snapshot)
	mission.free()


func test_pause_inventory_snapshot_lists_mission_inventory_items() -> void:
	MissionInventoryScript.clear_all()
	MissionInventoryScript.add_item("proof_badge", 2, {"item_id": "proof_badge", "display_name": "Proof Badge", "category": "qa"})
	var snap: Dictionary = MissionPauseDataProviderScript.get_inventory_snapshot()
	assert_int(int(snap.get("count", 0))).is_equal(1)
	var row: Dictionary = (snap.get("items", []) as Array)[0] as Dictionary
	assert_str(String(row.get("item_id", ""))).is_equal("proof_badge")
	assert_int(int(row.get("count", 0))).is_equal(2)
	MissionInventoryScript.clear_all()


func test_hide_spot_marks_hidden_and_player_damage_respects_hidden_state() -> void:
	var snapshot := _snapshot_game_state()
	var root := Node2D.new()
	add_child(root)
	var alert := MissionAlertControllerScript.new()
	root.add_child(alert)
	var hide_spot := HideSpotNodeScript.new()
	root.add_child(hide_spot)
	var actor := Node2D.new()
	actor.add_to_group("player")
	root.add_child(actor)
	var result: Dictionary = hide_spot.call("activate", actor, "test")
	assert_bool(bool(result.get("ok", false))).is_true()
	assert_bool(actor.is_in_group("mission_hidden")).is_true()
	hide_spot.call("exit_hide", actor)
	assert_bool(actor.is_in_group("mission_hidden")).is_false()

	var player := PlayerScript.new()
	player.current_health = 50
	player.max_health = 100
	player.add_to_group("mission_hidden")
	player.take_damage(10)
	assert_int(player.current_health).is_equal(50)
	player.free()
	_restore_game_state(snapshot)
	_free_node(root)


func test_teleport_zone_moves_player_and_applies_effect_after_requirements() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var root := Node2D.new()
	add_child(root)
	var target := TeleportTargetMarkerScript.new()
	target.name = "Target"
	target.position = Vector2(320, 96)
	root.add_child(target)
	var zone := TeleportZoneScript.new()
	zone.name = "TeleportZone"
	zone.mission_id_override = "teleport_test"
	zone.target_marker_path = NodePath("../Target")
	zone.success_effects = _set_mission_flag_effect_set("teleport_used")
	root.add_child(zone)
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	player.position = Vector2.ZERO
	root.add_child(player)

	var result: Dictionary = zone.activate(player, "interact")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("teleported")
	assert_vector(player.global_position).is_equal(target.global_position)
	assert_bool(GameState.dialogue_flags.get("mission_flag:teleport_test:teleport_used", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(root)


func test_teleport_zone_blocks_when_requirements_fail() -> void:
	var root := Node2D.new()
	add_child(root)
	var target := TeleportTargetMarkerScript.new()
	target.name = "Target"
	target.position = Vector2(100, 100)
	root.add_child(target)
	var zone := TeleportZoneScript.new()
	zone.name = "TeleportZone"
	zone.target_marker_path = NodePath("../Target")
	zone.requirements = _failing_requirement_set()
	root.add_child(zone)
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)

	var result: Dictionary = zone.activate(player, "interact")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_vector(player.global_position).is_equal(Vector2.ZERO)

	_free_node(root)


func test_teleport_zone_can_bypass_prior_interaction_requirements() -> void:
	var root := Node2D.new()
	add_child(root)
	var target := TeleportTargetMarkerScript.new()
	target.name = "Target"
	target.position = Vector2(100, 100)
	root.add_child(target)
	var zone := TeleportZoneScript.new()
	zone.name = "TeleportZone"
	zone.target_marker_path = NodePath("../Target")
	zone.require_prior_interaction = false
	zone.requirements = _failing_requirement_set()
	root.add_child(zone)
	var player := Node2D.new()
	player.add_to_group("player")
	root.add_child(player)

	var result: Dictionary = zone.activate(player, "interact")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("teleported")
	assert_vector(player.global_position).is_equal(target.global_position)

	_free_node(root)


func test_teleport_zone_missing_target_is_safe() -> void:
	var zone := TeleportZoneScript.new()
	add_child(zone)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	var result: Dictionary = zone.activate(player, "interact")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("missing_target_marker")
	assert_vector(player.global_position).is_equal(Vector2.ZERO)

	_free_node(zone)
	_free_node(player)


func test_music_trigger_zone_requests_audio_manager_and_restores_on_exit() -> void:
	var previous_music := AudioManager.current_music
	AudioManager.current_music = "previous_track"
	var zone := MusicTriggerZoneScript.new()
	zone.music_key = &"milestone_a_track"
	zone.restore_music_key = &"previous_track"
	zone.on_exit_restore = true
	add_child(zone)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	var result: Dictionary = zone.activate(player, "body_entered")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(AudioManager.current_music).is_equal("milestone_a_track")
	zone.handle_body_exited(player)
	assert_str(AudioManager.current_music).is_equal("previous_track")

	AudioManager.current_music = previous_music
	_free_node(zone)
	_free_node(player)


func _failing_requirement_set() -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "missing_flag"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"
	var set := RequirementSetScript.new()
	set.requirements = [req]
	return set


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var set := EffectSetScript.new()
	set.effects = [effect]
	return set


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"poop_bag_count": GameState.poop_bag_count,
		"poop_bags_this_mission_attempt": GameState.poop_bags_this_mission_attempt,
		"poop_bag_inventory": GameState.poop_bag_inventory.duplicate(true),
		"sterling_clues": GameState.sterling_clues.duplicate(true),
		"evidence_clues": GameState.evidence_clues.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.poop_bag_count = int(snapshot.get("poop_bag_count", 0))
	GameState.poop_bags_this_mission_attempt = int(snapshot.get("poop_bags_this_mission_attempt", 0))
	GameState.poop_bag_inventory = (snapshot.get("poop_bag_inventory", {"count": 0, "collected_this_mission": 0, "used_this_mission": 0}) as Dictionary).duplicate(true)
	GameState.sterling_clues = (snapshot.get("sterling_clues", {}) as Dictionary).duplicate(true)
	GameState.evidence_clues = (snapshot.get("evidence_clues", {}) as Dictionary).duplicate(true)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		if node.is_inside_tree():
			node.queue_free()
			await get_tree().process_frame
		else:
			node.free()
