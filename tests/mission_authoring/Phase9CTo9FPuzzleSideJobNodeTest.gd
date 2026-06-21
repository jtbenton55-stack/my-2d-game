# GdUnit4 tests for Phase 9C-9F puzzle and side-job kit nodes.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const InteractiveContainerScript := preload("res://src/missions/iso/authoring/mechanics/InteractiveContainer.gd")
const DeadDropNodeScript := preload("res://src/missions/iso/authoring/mechanics/DeadDropNode.gd")
const ObjectSwapNodeScript := preload("res://src/missions/iso/authoring/mechanics/ObjectSwapNode.gd")
const BugPlantNodeScript := preload("res://src/missions/iso/authoring/mechanics/BugPlantNode.gd")
const EavesdropZoneScript := preload("res://src/missions/iso/authoring/mechanics/EavesdropZone.gd")
const CustomSequenceStepScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceStep.gd")
const CustomSequenceResourceScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceResource.gd")
const CustomSequenceRunnerScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceRunner.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")


func test_phase9c_to_9f_nodes_extend_expected_bases() -> void:
	var dead_drop := DeadDropNodeScript.new()
	var object_swap := ObjectSwapNodeScript.new()
	var bug_plant := BugPlantNodeScript.new()
	var eavesdrop := EavesdropZoneScript.new()
	assert_object(dead_drop).is_instanceof(InteractiveContainerScript)
	assert_object(object_swap).is_instanceof(MechanicAreaBaseScript)
	assert_object(bug_plant).is_instanceof(MechanicAreaBaseScript)
	assert_object(eavesdrop).is_instanceof(MechanicAreaBaseScript)
	_free_node(dead_drop)
	_free_node(object_swap)
	_free_node(bug_plant)
	_free_node(eavesdrop)


func test_dead_drop_deposit_removes_item_and_sets_facts() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	MissionInventoryScript.add_item("drop_package", 1, {"item_id": "drop_package"})
	var node := _spawn_dead_drop()
	node.mission_id_override = "test_mission"
	node.drop_id = &"deposit_drop"
	node.drop_mode = "deposit"
	node.item_id = &"drop_package"
	node.completed_flag = &"deposit_done"
	node.success_effects = _set_mission_flag_effect_set("deposit_effect")

	var result: Dictionary = node.use_dead_drop(null, "test")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("dead_drop_completed")
	assert_int(MissionInventoryScript.get_item_count("drop_package")).is_equal(0)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:deposit_done", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:deposit_effect", false)).is_true()

	_restore_game_state(snapshot)
	MissionInventoryScript.clear_all()
	_free_node(node)


func test_dead_drop_retrieve_grants_item() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var node := _spawn_dead_drop()
	node.mission_id_override = "test_mission"
	node.drop_id = &"retrieve_drop"
	node.drop_mode = "retrieve"
	node.item_id = &"retrieved_package"
	node.completed_flag = &"retrieve_done"

	var result: Dictionary = node.use_dead_drop(null, "test")
	assert_bool(result.get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("retrieved_package")).is_equal(1)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:retrieve_done", false)).is_true()

	_restore_game_state(snapshot)
	MissionInventoryScript.clear_all()
	_free_node(node)


func test_object_swap_consumes_required_item_and_grants_replacement() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	MissionInventoryScript.add_item("fake_manifest", 1, {"item_id": "fake_manifest"})
	var node := _spawn_object_swap()
	node.mission_id_override = "test_mission"
	node.swap_id = &"manifest_swap"
	node.required_item_id = &"fake_manifest"
	node.replacement_item_id = &"real_manifest"
	node.swapped_flag = &"manifest_swapped"
	node.success_effects = _set_mission_flag_effect_set("swap_effect")

	var result: Dictionary = node.swap_object(null, "test")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("object_swapped")
	assert_int(MissionInventoryScript.get_item_count("fake_manifest")).is_equal(0)
	assert_int(MissionInventoryScript.get_item_count("real_manifest")).is_equal(1)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:manifest_swapped", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:swap_effect", false)).is_true()

	_restore_game_state(snapshot)
	MissionInventoryScript.clear_all()
	_free_node(node)


func test_bug_plant_and_eavesdrop_set_ordered_side_job_facts() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	MissionInventoryScript.add_item("listening_bug", 1, {"item_id": "listening_bug"})
	var bug := _spawn_bug_plant()
	bug.mission_id_override = "test_mission"
	bug.bug_id = &"office_bug"
	bug.bug_item_id = &"listening_bug"
	bug.planted_flag = &"office_bug_planted"
	bug.success_effects = _set_mission_flag_effect_set("bug_effect")
	var eavesdrop := _spawn_eavesdrop()
	eavesdrop.mission_id_override = "test_mission"
	eavesdrop.eavesdrop_id = &"office_listen"
	eavesdrop.completed_flag = &"office_eavesdrop_complete"
	eavesdrop.listen_seconds = 0.0
	eavesdrop.success_effects = _set_mission_flag_effect_set("eavesdrop_effect")

	var bug_result: Dictionary = bug.plant_bug(null, "test")
	assert_bool(bug_result.get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("listening_bug")).is_equal(0)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:office_bug_planted", false)).is_true()

	var eavesdrop_result: Dictionary = eavesdrop.start_eavesdrop(null, "test")
	assert_bool(eavesdrop_result.get("ok", false)).is_true()
	assert_str(String(eavesdrop_result.get("code", ""))).is_equal("eavesdrop_completed")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:office_eavesdrop_complete", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:eavesdrop_effect", false)).is_true()

	_restore_game_state(snapshot)
	MissionInventoryScript.clear_all()
	_free_node(bug)
	_free_node(eavesdrop)


func test_custom_sequence_runner_enforces_step_dependencies() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var runner: Node = CustomSequenceRunnerScript.new()
	add_child(runner)
	var sequence: Resource = CustomSequenceResourceScript.new()
	sequence.sequence_id = &"two_step_sequence"
	sequence.mission_id_override = "test_mission"
	var step_a: Resource = CustomSequenceStepScript.new()
	step_a.step_id = &"step_a"
	step_a.order_index = 1
	step_a.completion_flag = &"step_a_done"
	step_a.success_effects = _set_mission_flag_effect_set("step_a_effect")
	var step_b: Resource = CustomSequenceStepScript.new()
	step_b.step_id = &"step_b"
	step_b.order_index = 2
	var depends_on_a: Array[StringName] = [&"step_a"]
	step_b.depends_on_step_ids = depends_on_a
	step_b.completion_flag = &"step_b_done"
	var steps: Array[Resource] = [step_b, step_a]
	sequence.steps = steps
	runner.sequence = sequence

	var blocked_result: Dictionary = runner.complete_step("step_b", "test")
	assert_bool(blocked_result.get("ok", true)).is_false()
	assert_str(String(blocked_result.get("code", ""))).is_equal("step_dependencies_missing")
	var step_a_result: Dictionary = runner.complete_step("step_a", "test")
	assert_bool(step_a_result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:step_a_done", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:step_a_effect", false)).is_true()
	var step_b_result: Dictionary = runner.complete_step("step_b", "test")
	assert_bool(step_b_result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:step_b_done", false)).is_true()
	assert_bool(runner.get_sequence_summary().get("all_steps_complete", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(runner)


func test_templates_and_dev_scene_contain_phase9c_to_9f_nodes() -> void:
	var dead_drop_template := load("res://scenes/missions/iso/authoring/DeadDropNodeTemplate.tscn") as PackedScene
	var object_swap_template := load("res://scenes/missions/iso/authoring/ObjectSwapNodeTemplate.tscn") as PackedScene
	var bug_plant_template := load("res://scenes/missions/iso/authoring/BugPlantNodeTemplate.tscn") as PackedScene
	var eavesdrop_template := load("res://scenes/missions/iso/authoring/EavesdropZoneTemplate.tscn") as PackedScene
	assert_object(dead_drop_template).is_not_null()
	assert_object(object_swap_template).is_not_null()
	assert_object(bug_plant_template).is_not_null()
	assert_object(eavesdrop_template).is_not_null()
	var dead_drop_root := dead_drop_template.instantiate()
	var object_swap_root := object_swap_template.instantiate()
	var bug_plant_root := bug_plant_template.instantiate()
	var eavesdrop_root := eavesdrop_template.instantiate()
	assert_object(dead_drop_root).is_instanceof(DeadDropNodeScript)
	assert_object(object_swap_root).is_instanceof(ObjectSwapNodeScript)
	assert_object(bug_plant_root).is_instanceof(BugPlantNodeScript)
	assert_object(eavesdrop_root).is_instanceof(EavesdropZoneScript)
	dead_drop_root.queue_free()
	object_swap_root.queue_free()
	bug_plant_root.queue_free()
	eavesdrop_root.queue_free()

	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/DeadDropNode_phase9c_retrieve")).is_instanceof(DeadDropNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/ObjectSwapNode_phase9d_swap")).is_instanceof(ObjectSwapNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/BugPlantNode_phase9e_plant")).is_instanceof(BugPlantNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/EavesdropZone_phase9f_listen")).is_instanceof(EavesdropZoneScript)
	root.queue_free()


func _spawn_dead_drop() -> Node:
	var node: Node = DeadDropNodeScript.new()
	node.name = "DeadDropUnderTest"
	add_child(node)
	return node


func _spawn_object_swap() -> Node:
	var node: Node = ObjectSwapNodeScript.new()
	node.name = "ObjectSwapUnderTest"
	add_child(node)
	return node


func _spawn_bug_plant() -> Node:
	var node: Node = BugPlantNodeScript.new()
	node.name = "BugPlantUnderTest"
	add_child(node)
	return node


func _spawn_eavesdrop() -> Node:
	var node: Node = EavesdropZoneScript.new()
	node.name = "EavesdropUnderTest"
	add_child(node)
	return node


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _reset_runtime_state() -> void:
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	MissionInventoryScript.clear_all()


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
