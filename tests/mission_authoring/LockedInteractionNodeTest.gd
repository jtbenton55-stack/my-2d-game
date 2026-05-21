# GdUnit4 tests for Packet 2B-4A LockedInteractionNode.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const LockedInteractionNodeScript := preload("res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_locked_interaction_node_extends_mechanic_area_base() -> void:
	var node := LockedInteractionNodeScript.new()
	assert_object(node).is_instanceof(MechanicAreaBaseScript)
	node.free()


func test_ready_groups_and_starts_unlocked() -> void:
	var node := _spawn_lock()
	assert_bool(node.is_in_group("interactable")).is_true()
	assert_bool(node.is_in_group("mission_mechanic")).is_true()
	assert_bool(node.is_in_group("phase0j_interactable")).is_false()
	assert_bool(node.unlocked).is_false()
	_free_lock(node)

	var unlocked_node := LockedInteractionNodeScript.new()
	unlocked_node.name = "TestLockedInteractionUnlocked"
	unlocked_node.starts_unlocked = true
	add_child(unlocked_node)
	assert_bool(unlocked_node.unlocked).is_true()
	_free_lock(unlocked_node)


func test_successful_unlock_without_requirements() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.mission_id_override = "test_mission"
	node.one_shot = true
	node.success_effects = _set_mission_flag_effect_set("unlock_success_flag")

	var result: Dictionary = node.unlock(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("activation_succeeded")
	assert_bool(node.unlocked).is_true()
	assert_bool(node.last_unlock_result.is_empty()).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:unlock_success_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_lock(node)


func test_unlocked_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.mission_id_override = "test_mission"
	node.unlocked_flag = &"dev_gate_open"
	node.one_shot = false

	var result: Dictionary = node.unlock(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_gate_open", false)).is_true()

	_restore_game_state(snapshot)
	_free_lock(node)


func test_requirement_failure_prevents_unlock_and_can_apply_failure_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.mission_id_override = "test_mission"
	node.one_shot = true
	node.requirements = _failing_requirement_set()
	node.success_effects = _set_mission_flag_effect_set("should_not_fire")
	node.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = node.unlock(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(node.unlocked).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_lock(node)


func test_already_unlocked_does_not_reapply_effects_when_not_staying_available() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.stay_available_after_unlock = false
	node.success_effects = _set_mission_flag_effect_set("gate_flag")

	var first: Dictionary = node.unlock(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:gate_flag")

	var second: Dictionary = node.unlock(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_unlocked")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:gate_flag")).is_false()
	assert_bool(node.is_interaction_available()).is_false()

	_restore_game_state(snapshot)
	_free_lock(node)


func test_prompt_behavior_for_locked_and_unlocked_states() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.prompt_text = "Press E: Unlock gate"
	node.locked_prompt_text = "Need clearance"
	node.requirements = _failing_requirement_set("Need keycard")
	assert_str(node.get_interaction_text()).is_equal("Need keycard")

	node.requirements = null
	assert_str(node.get_interaction_text()).is_equal("Press E: Unlock gate")

	node.unlock(null, "script")
	node.stay_available_after_unlock = false
	assert_str(node.get_interaction_text()).is_equal("")

	node.stay_available_after_unlock = true
	node.unlocked_prompt_text = "Gate is open"
	assert_str(node.get_interaction_text()).is_equal("Gate is open")

	_restore_game_state(snapshot)
	_free_lock(node)


func test_target_toggling_show_hide_and_collision() -> void:
	var node := _spawn_lock()
	var visual := ColorRect.new()
	visual.name = "DoorVisual"
	visual.visible = true
	node.add_child(visual)

	var blocker := CollisionShape2D.new()
	blocker.name = "DoorBlocker"
	blocker.disabled = false
	node.add_child(blocker)

	var hide_paths: Array[NodePath] = [NodePath("DoorVisual")]
	var disable_paths: Array[NodePath] = [NodePath("DoorBlocker")]
	node.nodes_to_hide_on_unlock = hide_paths
	node.collisions_to_disable_on_unlock = disable_paths

	var result: Dictionary = node.apply_unlock_targets()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(visual.visible).is_false()
	assert_bool(blocker.disabled).is_true()

	_free_lock(node)


func test_missing_target_path_returns_warnings_without_crash() -> void:
	var node := _spawn_lock()
	var missing_paths: Array[NodePath] = [NodePath("MissingNode")]
	node.nodes_to_show_on_unlock = missing_paths
	var result: Dictionary = node.apply_unlock_targets()
	var warnings: Array = result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)
	_free_lock(node)


func test_interface_methods_route_to_unlock() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var node := _spawn_lock()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(node.interact()).is_true()
	assert_bool(node.unlocked).is_true()

	node.lock()
	node.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(node.on_interact()).is_true()
	assert_bool(node.use()).is_true()

	node.lock()
	assert_bool(node.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_lock(node)


func _spawn_lock() -> Node:
	var node: Node = LockedInteractionNodeScript.new()
	node.name = "TestLockedInteraction"
	node.interaction_mode = MechanicAreaBaseScript.InteractionMode.INTERACT_REQUIRED
	add_child(node)
	return node


func _free_lock(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _failing_requirement_set(locked_message: String = "") -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "missing_flag"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [req]
	if locked_message != "":
		req_set.locked_message = locked_message
	return req_set


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
