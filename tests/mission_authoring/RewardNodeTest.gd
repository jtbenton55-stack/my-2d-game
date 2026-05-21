# GdUnit4 tests for Packet 2B-7 RewardNode.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const RewardNodeScript := preload("res://src/missions/iso/authoring/mechanics/RewardNode.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_reward_node_extends_mechanic_area_base() -> void:
	var reward := RewardNodeScript.new()
	assert_object(reward).is_instanceof(MechanicAreaBaseScript)
	reward.free()


func test_ready_groups_and_starts_collected() -> void:
	var reward := _spawn_reward()
	assert_bool(reward.is_in_group("interactable")).is_true()
	assert_bool(reward.is_in_group("mission_mechanic")).is_true()
	assert_bool(reward.is_in_group("phase0j_interactable")).is_false()
	assert_bool(reward.collected).is_false()
	_free_reward(reward)

	var collected_reward := RewardNodeScript.new()
	collected_reward.name = "TestRewardCollected"
	collected_reward.starts_collected = true
	add_child(collected_reward)
	assert_bool(collected_reward.collected).is_true()
	_free_reward(collected_reward)


func test_successful_collection() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.reward_id = &"dev_reward_pickup"

	var result: Dictionary = reward.collect(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("reward_collected")
	assert_bool(reward.collected).is_true()
	assert_bool(reward.last_collect_result.is_empty()).is_false()
	assert_str(String(result.get("details", {}).get("reward_id", ""))).is_equal("dev_reward_pickup")

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_effect_set_reward_and_no_duplicate_on_repeat() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.stay_available_after_collect = false
	reward.success_effects = _set_mission_flag_effect_set("dev_reward_effect_applied")

	var first: Dictionary = reward.collect(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_reward_effect_applied", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:dev_reward_effect_applied")

	var second: Dictionary = reward.collect(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_collected")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:dev_reward_effect_applied")).is_false()

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_collected_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.collected_flag = &"dev_reward_collected"

	var result: Dictionary = reward.collect(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_reward_collected", false)).is_true()

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_requirement_gating_blocks_collection() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = true
	reward.requirements = _failing_requirement_set()
	reward.success_effects = _set_mission_flag_effect_set("should_not_fire")
	reward.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = reward.collect(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(reward.collected).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_already_collected_availability() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.stay_available_after_collect = false

	reward.collect(null, "script")
	var second: Dictionary = reward.collect(null, "script")
	assert_str(String(second.get("code", ""))).is_equal("already_collected")
	assert_bool(reward.is_interaction_available()).is_false()

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_prompt_behavior() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.prompt_text = "Press E: Collect reward"
	reward.locked_prompt_text = "Cannot collect yet"
	reward.requirements = _failing_requirement_set("Need clearance")
	assert_str(reward.get_interaction_text()).is_equal("Need clearance")

	reward.requirements = null
	assert_str(reward.get_interaction_text()).is_equal("Press E: Collect reward")

	reward.collect(null, "script")
	reward.stay_available_after_collect = false
	assert_str(reward.get_interaction_text()).is_equal("")

	reward.stay_available_after_collect = true
	reward.collected_prompt_text = "Reward already collected"
	assert_str(reward.get_interaction_text()).is_equal("Reward already collected")

	_restore_game_state(snapshot)
	_free_reward(reward)


func test_target_toggling_and_missing_path_warnings() -> void:
	var reward := _spawn_reward()
	var visual := ColorRect.new()
	visual.name = "RewardVisual"
	visual.visible = true
	reward.add_child(visual)

	var collected_visual := ColorRect.new()
	collected_visual.name = "RewardCollectedVisual"
	collected_visual.visible = false
	reward.add_child(collected_visual)

	reward.target_visual_path = NodePath("RewardVisual")
	var show_paths: Array[NodePath] = [NodePath("RewardCollectedVisual")]
	reward.nodes_to_show_on_collect = show_paths

	var result: Dictionary = reward.apply_collect_targets()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(visual.visible).is_false()
	assert_bool(collected_visual.visible).is_true()

	var missing_paths: Array[NodePath] = [NodePath("MissingNode")]
	reward.nodes_to_show_on_collect = missing_paths
	var warning_result: Dictionary = reward.apply_collect_targets()
	var warnings: Array = warning_result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)

	_free_reward(reward)


func test_grant_typed_collectible_through_effect_set() -> void:
	var snapshot := _snapshot_game_state()
	var prev_collectibles := GameState.typed_collectibles.duplicate(true)
	GameState.dialogue_flags.clear()
	GameState.typed_collectibles.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.success_effects = _typed_collectible_effect_set("dev_test_collectible", "clue")

	var result: Dictionary = reward.collect(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.typed_collectibles.has("dev_test_collectible")).is_true()

	_restore_game_state(snapshot)
	GameState.typed_collectibles = prev_collectibles
	_free_reward(reward)


func test_interface_methods_route_to_collect() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var reward := _spawn_reward()
	reward.mission_id_override = "test_mission"
	reward.one_shot = false
	reward.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(reward.interact()).is_true()
	assert_bool(reward.collected).is_true()

	reward.reset_reward()
	reward.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(reward.on_interact()).is_true()

	reward.reset_reward()
	assert_bool(reward.use()).is_true()

	reward.reset_reward()
	assert_bool(reward.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_reward(reward)


func _spawn_reward() -> Node:
	var reward := RewardNodeScript.new()
	reward.name = "TestRewardNode"
	add_child(reward)
	return reward


func _free_reward(reward: Node) -> void:
	if is_instance_valid(reward):
		reward.queue_free()


func _failing_requirement_set(locked_message: String = "") -> RequirementSet:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = "missing_flag"
	requirement.operator = MissionRequirement.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [requirement]
	var message := locked_message.strip_edges()
	if message == "":
		message = "Requirements not met."
	req_set.locked_message = message
	return req_set


func _set_mission_flag_effect_set(flag_id: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffect.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _typed_collectible_effect_set(collectible_id: String, collectible_type: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffect.EffectType.GRANT_TYPED_COLLECTIBLE
	effect.key = collectible_id
	effect.value_type = "dictionary"
	effect.payload = {"type": collectible_type, "collectible_type": collectible_type}
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"typed_collectibles": GameState.typed_collectibles.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.typed_collectibles = (snapshot.get("typed_collectibles", {}) as Dictionary).duplicate(true)
