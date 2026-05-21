# GdUnit4 tests for Packet 2B-9 SideObjectiveNode.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const SideObjectiveNodeScript := preload("res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd")
const ObjectiveStepControllerScript := preload("res://src/missions/iso/authoring/core/ObjectiveStepController.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_side_objective_node_extends_mechanic_area_base() -> void:
	var node := SideObjectiveNodeScript.new()
	assert_object(node).is_instanceof(MechanicAreaBaseScript)
	node.free()


func test_ready_groups_and_starts_handled() -> void:
	var node := _spawn_side_objective()
	assert_bool(node.is_in_group("interactable")).is_true()
	assert_bool(node.is_in_group("mission_mechanic")).is_true()
	assert_bool(node.is_in_group("phase0j_interactable")).is_false()
	assert_bool(node.handled).is_false()
	_free_side_objective(node)

	var handled_node := SideObjectiveNodeScript.new()
	handled_node.name = "TestSideObjectiveHandled"
	handled_node.starts_handled = true
	add_child(handled_node)
	assert_bool(handled_node.handled).is_true()
	_free_side_objective(handled_node)


func test_successful_objective_activation() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_activate_obj"
	node.objective_text = "Activate me"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("side_objective_handled")
	assert_bool(node.handled).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_activate_obj", "test_mission")).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_successful_objective_completion() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	ObjectiveStepControllerScript.activate_objective("dev_complete_obj", "Complete me", "test_mission")

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_complete_obj"
	node.objective_text = "Complete me"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.COMPLETE

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(node.handled).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("dev_complete_obj", "test_mission")).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_objective_fail_behavior() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_fail_obj"
	node.objective_text = "Fail me"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.FAIL

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("details", {}).get("objective_action_result", {}).get("code", ""))).is_equal("objective_failed")
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_fail_obj", "test_mission")).is_false()
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("dev_fail_obj", "test_mission")).is_false()
	var record := ObjectiveStepControllerScript.get_objective_record("dev_fail_obj", "test_mission")
	assert_str(String(record.get("status", ""))).is_equal("failed")

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_requirement_gating_blocks_objective_action() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = true
	node.objective_id = &"dev_gated_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.requirements = _failing_requirement_set()
	node.success_effects = _set_mission_flag_effect_set("should_not_fire")
	node.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(node.handled).is_false()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_gated_obj", "test_mission")).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_success_effects_apply_through_activate() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_effect_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.success_effects = _set_mission_flag_effect_set("dev_side_objective_effect_applied")

	node.handle_objective(null, "script")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_side_objective_effect_applied", false)).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_objective_flag_sets_namespaced_mission_flag() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_flag_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.objective_flag = &"dev_side_objective_handled"

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_side_objective_handled", false)).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_already_handled_availability() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_repeat_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.stay_available_after_handled = false

	node.handle_objective(null, "script")
	var second: Dictionary = node.handle_objective(null, "script")
	assert_str(String(second.get("code", ""))).is_equal("already_handled")
	assert_bool(node.is_interaction_available()).is_false()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_prompt_behavior() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.prompt_text = "Press E: Handle objective"
	node.locked_prompt_text = "Cannot handle yet"
	node.requirements = _failing_requirement_set("Need clearance")
	assert_str(node.get_interaction_text()).is_equal("Need clearance")

	node.requirements = null
	assert_str(node.get_interaction_text()).is_equal("Press E: Handle objective")

	node.objective_id = &"dev_prompt_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.handle_objective(null, "script")
	node.stay_available_after_handled = false
	assert_str(node.get_interaction_text()).is_equal("")

	node.stay_available_after_handled = true
	node.handled_prompt_text = "Objective already handled"
	assert_str(node.get_interaction_text()).is_equal("Objective already handled")

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_missing_objective_id_returns_clean_failure() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &""
	node.requirements = null

	var result: Dictionary = node.handle_objective(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("objective_id_missing")
	assert_bool(node.handled).is_false()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func test_multiple_instance_isolation() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var node_a := SideObjectiveNodeScript.new()
	node_a.name = "TestSideObjectiveA"
	node_a.mission_id_override = "test_mission"
	node_a.one_shot = false
	node_a.objective_id = &"dev_side_a"
	node_a.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node_a.objective_flag = &"dev_side_a_handled"
	add_child(node_a)

	var node_b := SideObjectiveNodeScript.new()
	node_b.name = "TestSideObjectiveB"
	node_b.mission_id_override = "test_mission"
	node_b.one_shot = false
	node_b.objective_id = &"dev_side_b"
	node_b.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node_b.objective_flag = &"dev_side_b_handled"
	add_child(node_b)

	node_a.handle_objective(null, "script")
	assert_bool(node_a.handled).is_true()
	assert_bool(node_b.handled).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_side_a_handled", false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:dev_side_b_handled")).is_false()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_side_a", "test_mission")).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_side_b", "test_mission")).is_false()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node_a)
	_free_side_objective(node_b)


func test_interface_methods_route_to_handle_objective() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var node := _spawn_side_objective()
	node.mission_id_override = "test_mission"
	node.one_shot = false
	node.objective_id = &"dev_interface_obj"
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(node.interact()).is_true()
	assert_bool(node.handled).is_true()

	node.reset_objective_node()
	node.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(node.on_interact()).is_true()

	node.reset_objective_node()
	assert_bool(node.use()).is_true()

	node.reset_objective_node()
	assert_bool(node.inspect_marker()).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_side_objective(node)


func _spawn_side_objective() -> Node:
	var node := SideObjectiveNodeScript.new()
	node.name = "TestSideObjectiveNode"
	add_child(node)
	return node


func _free_side_objective(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


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


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)


func _snapshot_quest_manager() -> Dictionary:
	return {
		"active_quest_id": QuestManager.active_quest_id,
		"active_objective": QuestManager.active_objective,
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_quest_manager(snapshot: Dictionary) -> void:
	QuestManager.active_quest_id = String(snapshot.get("active_quest_id", ""))
	QuestManager.active_objective = String(snapshot.get("active_objective", ""))
	QuestManager.objectives = (snapshot.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("completed_objectives", {}) as Dictionary).duplicate(true)
