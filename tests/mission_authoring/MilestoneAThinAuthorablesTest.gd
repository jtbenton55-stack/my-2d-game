extends GdUnitTestSuite

const TeleportZoneScript := preload("res://src/missions/iso/authoring/mechanics/TeleportZone.gd")
const TeleportTargetMarkerScript := preload("res://src/missions/iso/authoring/mechanics/TeleportTargetMarker.gd")
const MusicTriggerZoneScript := preload("res://src/missions/iso/authoring/mechanics/MusicTriggerZone.gd")
const PlayerStartMarkerScript := preload("res://src/missions/iso/authoring/mechanics/PlayerStartMarker.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_player_start_marker_matches_existing_spawn_authoring_convention() -> void:
	var marker := PlayerStartMarkerScript.new()
	assert_str(String(marker.marker_type)).is_equal("PLAYER_SPAWN")
	assert_str(String(marker.marker_id)).is_equal("start_main")
	assert_str(String(marker.group_id)).is_equal("spawns")
	marker.free()


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
	return {"dialogue_flags": GameState.dialogue_flags.duplicate(true)}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
