# GdUnit4 tests for Phase 9G-9I side-job completion proofs.
extends GdUnitTestSuite

const TimedSwitchNodeScript := preload("res://src/missions/iso/authoring/mechanics/TimedSwitchNode.gd")
const PressurePlateNodeScript := preload("res://src/missions/iso/authoring/mechanics/PressurePlateNode.gd")
const PowerCircuitNodeScript := preload("res://src/missions/iso/authoring/mechanics/PowerCircuitNode.gd")
const DeadDropNodeScript := preload("res://src/missions/iso/authoring/mechanics/DeadDropNode.gd")
const ObjectSwapNodeScript := preload("res://src/missions/iso/authoring/mechanics/ObjectSwapNode.gd")
const BugPlantNodeScript := preload("res://src/missions/iso/authoring/mechanics/BugPlantNode.gd")
const EavesdropZoneScript := preload("res://src/missions/iso/authoring/mechanics/EavesdropZone.gd")
const SearchZoneScript := preload("res://src/missions/iso/authoring/mechanics/SearchZone.gd")
const RewardNodeScript := preload("res://src/missions/iso/authoring/mechanics/RewardNode.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const SideObjectiveNodeScript := preload("res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd")
const MissionInteractionBridgeScript := preload("res://src/missions/iso/runtime/authoring/MissionInteractionBridge.gd")
const CustomSequenceStepScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceStep.gd")
const CustomSequenceResourceScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceResource.gd")
const CustomSequenceRunnerScript := preload("res://src/missions/iso/authoring/sequences/CustomSequenceRunner.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")


func test_phase9_side_job_proof_room_contains_two_distinct_side_jobs() -> void:
	var scene := load("res://scenes/dev/mission_authoring/Phase9SideJobProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("Phase9G_PoopBagCalibrationCourse/TimedSwitch_phase9g_start")).is_instanceof(TimedSwitchNodeScript)
	assert_object(root.get_node_or_null("Phase9G_PoopBagCalibrationCourse/PressurePlate_phase9g_hold")).is_instanceof(PressurePlateNodeScript)
	assert_object(root.get_node_or_null("Phase9G_PoopBagCalibrationCourse/PowerCircuit_phase9g_finish")).is_instanceof(PowerCircuitNodeScript)
	assert_object(root.get_node_or_null("Phase9G_PoopBagCalibrationCourse/Phase9GSequenceRunner")).is_instanceof(CustomSequenceRunnerScript)
	assert_object(root.get_node_or_null("Phase9H_BentleySnackTrail/DeadDrop_phase9h_retrieve")).is_instanceof(DeadDropNodeScript)
	assert_object(root.get_node_or_null("Phase9H_BentleySnackTrail/ObjectSwap_phase9h_swap")).is_instanceof(ObjectSwapNodeScript)
	assert_object(root.get_node_or_null("Phase9H_BentleySnackTrail/BugPlant_phase9h_bug")).is_instanceof(BugPlantNodeScript)
	assert_object(root.get_node_or_null("Phase9H_BentleySnackTrail/Eavesdrop_phase9h_listen")).is_instanceof(EavesdropZoneScript)
	assert_object(root.get_node_or_null("Phase9H_BentleySnackTrail/Phase9HSequenceRunner")).is_instanceof(CustomSequenceRunnerScript)
	root.queue_free()


func test_phase9g_poop_bag_calibration_course_flow_uses_reusable_nodes() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var switch := TimedSwitchNodeScript.new()
	var plate := PressurePlateNodeScript.new()
	var circuit := PowerCircuitNodeScript.new()
	add_child(switch)
	add_child(plate)
	add_child(circuit)
	switch.mission_id_override = "phase9_side_job_test"
	switch.switch_flag = &"phase9g_timer_active"
	switch.clear_flag_on_expire = false
	plate.mission_id_override = "phase9_side_job_test"
	plate.pressed_flag = &"phase9g_plate_held"
	plate.clear_flag_on_exit = false
	circuit.mission_id_override = "phase9_side_job_test"
	circuit.circuit_flag = &"phase9g_course_complete"
	var required_power_flags: Array[StringName] = [&"phase9g_timer_active", &"phase9g_plate_held"]
	circuit.required_power_flags = required_power_flags
	circuit.success_effects = _set_mission_flag_effect_set("phase9g_course_effect")
	var runner: Node = _build_sequence_runner("phase9g_sequence", [&"start_course", &"hold_plate", &"power_circuit"])

	assert_bool(switch.trigger_switch(null, "test").get("ok", false)).is_true()
	assert_bool(runner.complete_step("start_course", "test").get("ok", false)).is_true()
	assert_bool(plate.press(null, "test").get("ok", false)).is_true()
	assert_bool(runner.complete_step("hold_plate", "test").get("ok", false)).is_true()
	assert_bool(circuit.check_circuit(null, "test").get("ok", false)).is_true()
	assert_bool(runner.complete_step("power_circuit", "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:phase9_side_job_test:phase9g_course_complete", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:phase9_side_job_test:phase9g_course_effect", false)).is_true()
	assert_bool(runner.get_sequence_summary().get("all_steps_complete", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(switch)
	_free_node(plate)
	_free_node(circuit)
	_free_node(runner)


func test_phase9h_bentley_snack_trail_flow_uses_different_node_combination() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var drop := DeadDropNodeScript.new()
	var swap := ObjectSwapNodeScript.new()
	var bug := BugPlantNodeScript.new()
	var eavesdrop := EavesdropZoneScript.new()
	add_child(drop)
	add_child(swap)
	add_child(bug)
	add_child(eavesdrop)
	drop.mission_id_override = "phase9_side_job_test"
	drop.drop_mode = "retrieve"
	drop.item_id = &"phase9h_snack_bait"
	drop.completed_flag = &"phase9h_snack_retrieved"
	swap.mission_id_override = "phase9_side_job_test"
	swap.required_item_id = &"phase9h_snack_bait"
	swap.replacement_item_id = &"phase9h_listening_bug"
	swap.swapped_flag = &"phase9h_snack_swapped"
	bug.mission_id_override = "phase9_side_job_test"
	bug.bug_item_id = &"phase9h_listening_bug"
	bug.planted_flag = &"phase9h_bug_planted"
	eavesdrop.mission_id_override = "phase9_side_job_test"
	eavesdrop.completed_flag = &"phase9h_eavesdrop_complete"
	eavesdrop.listen_seconds = 0.0
	eavesdrop.success_effects = _set_mission_flag_effect_set("phase9h_snack_trail_effect")
	var runner: Node = _build_sequence_runner("phase9h_sequence", [&"retrieve_snack", &"swap_snack", &"listen_route"])

	assert_bool(drop.use_dead_drop(null, "test").get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("phase9h_snack_bait")).is_equal(1)
	assert_bool(runner.complete_step("retrieve_snack", "test").get("ok", false)).is_true()
	assert_bool(swap.swap_object(null, "test").get("ok", false)).is_true()
	assert_int(MissionInventoryScript.get_item_count("phase9h_listening_bug")).is_equal(1)
	assert_bool(runner.complete_step("swap_snack", "test").get("ok", false)).is_true()
	assert_bool(bug.plant_bug(null, "test").get("ok", false)).is_true()
	assert_bool(eavesdrop.start_eavesdrop(null, "test").get("ok", false)).is_true()
	assert_bool(runner.complete_step("listen_route", "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:phase9_side_job_test:phase9h_eavesdrop_complete", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:phase9_side_job_test:phase9h_snack_trail_effect", false)).is_true()
	assert_bool(runner.get_sequence_summary().get("all_steps_complete", false)).is_true()

	_restore_game_state(snapshot)
	MissionInventoryScript.clear_all()
	_free_node(drop)
	_free_node(swap)
	_free_node(bug)
	_free_node(eavesdrop)
	_free_node(runner)


func test_phase9i_taco_production_gate_is_isolated_and_route_gated() -> void:
	var text := FileAccess.get_file_as_string("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")
	assert_str(text).contains("PpTacoSouthSideJobSignoff")
	assert_str(text).contains("SideObjectiveNode.gd")
	assert_str(text).contains("SearchFoundVisual")
	assert_str(text).contains("target_visual_path = NodePath(\"SearchVisual\")")
	assert_str(text).contains("key = \"pp_taco_south_route_open\"")
	assert_str(text).contains("objective_id = &\"pp_taco_south_side_job_signoff\"")
	assert_str(text).contains("objective_flag = &\"pp_taco_south_side_job_complete\"")
	assert_str(text).contains("SignoffCompleteVisual")
	assert_str(text).contains("nodes_to_show_on_handle = Array[NodePath]([NodePath(\"SignoffCompleteVisual\")])")
	assert_str(text).contains("one_shot = false")
	assert_str(text).contains("interaction_priority = 760")
	assert_str(text).contains("interaction_priority = 730")
	assert_str(text).contains("include_legacy_candidates = false")


func test_phase9i_taco_production_chain_sets_flags_and_visuals() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "taco_bell_drop"
	GameState.pending_mission_id = ""
	var scene := load("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	var search := root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthSearchDrop")
	var reward := root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthRewardScrap")
	var route := root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthRoutePeek")
	var signoff := root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthSideJobSignoff")
	assert_object(search).is_instanceof(SearchZoneScript)
	assert_object(reward).is_instanceof(RewardNodeScript)
	assert_object(route).is_instanceof(RouteUnlockNodeScript)
	assert_object(signoff).is_instanceof(SideObjectiveNodeScript)
	assert_int(search.get("interaction_priority")).is_greater(620)
	assert_int(reward.get("interaction_priority")).is_greater(620)
	assert_int(route.get("interaction_priority")).is_greater(620)
	assert_int(signoff.get("interaction_priority")).is_greater(620)

	var search_visual := search.get_node_or_null("SearchVisual") as CanvasItem
	var found_visual := search.get_node_or_null("SearchFoundVisual") as CanvasItem
	var signoff_visual := signoff.get_node_or_null("SignoffVisual") as CanvasItem
	var signoff_complete_visual := signoff.get_node_or_null("SignoffCompleteVisual") as CanvasItem
	assert_object(search_visual).is_not_null()
	assert_object(found_visual).is_not_null()
	assert_object(signoff_visual).is_not_null()
	assert_object(signoff_complete_visual).is_not_null()
	assert_bool(search_visual.visible).is_true()
	assert_bool(found_visual.visible).is_false()
	assert_bool(signoff_visual.visible).is_true()
	assert_bool(signoff_complete_visual.visible).is_false()

	assert_bool(search.call("search", null, "test").get("ok", false)).is_true()
	assert_bool(search_visual.visible).is_false()
	assert_bool(found_visual.visible).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_found_scrap", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_searched", false)).is_true()

	assert_bool(reward.call("collect", null, "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_reward_collected", false)).is_true()
	assert_bool(route.call("unlock_route", null, "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_route_open", false)).is_true()
	assert_bool(signoff.call("handle_objective", null, "test").get("ok", false)).is_true()
	assert_bool(signoff_visual.visible).is_false()
	assert_bool(signoff_complete_visual.visible).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_side_job_complete", false)).is_true()

	root.free()
	_restore_game_state(game_snapshot)
	_restore_quest_manager(quest_snapshot)


func test_phase9i_taco_bridge_selects_side_job_signoff_after_route_open() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "taco_bell_drop"
	GameState.pending_mission_id = ""
	var scene := load("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	var scene_signoff := root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthSideJobSignoff")
	assert_object(scene_signoff).is_not_null()
	var signoff := scene_signoff.duplicate() as Node2D
	root.free()

	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	var bridge: Node = MissionInteractionBridgeScript.new()
	bridge.name = "MissionInteractionBridge"
	bridge.set("include_legacy_candidates", false)
	bridge.set("debug_enabled", false)
	add_child(player)
	add_child(signoff)
	add_child(bridge)
	player.global_position = Vector2.ZERO
	signoff.global_position = Vector2.ZERO
	await get_tree().process_frame

	assert_object(player).is_not_null()
	assert_object(bridge).is_not_null()
	assert_object(signoff).is_not_null()

	GameState.dialogue_flags["mission_flag:taco_bell_drop:pp_taco_south_route_open"] = true
	assert_bool(signoff.call("is_interaction_available", player)).is_true()

	var signoff_visual := signoff.get_node_or_null("SignoffVisual") as CanvasItem
	var signoff_complete_visual := signoff.get_node_or_null("SignoffCompleteVisual") as CanvasItem
	assert_bool(bridge.call("try_interact_at_position", player.global_position)).is_true()
	assert_object(bridge.get("last_candidate")).is_same(signoff)
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:pp_taco_south_side_job_complete", false)).is_true()
	assert_bool(signoff_visual.visible).is_false()
	assert_bool(signoff_complete_visual.visible).is_true()

	_free_node(bridge)
	_free_node(signoff)
	_free_node(player)
	await get_tree().process_frame
	_restore_game_state(game_snapshot)
	_restore_quest_manager(quest_snapshot)


func _build_sequence_runner(sequence_id: String, step_ids: Array[StringName]) -> Node:
	var runner: Node = CustomSequenceRunnerScript.new()
	add_child(runner)
	var sequence: Resource = CustomSequenceResourceScript.new()
	sequence.sequence_id = StringName(sequence_id)
	sequence.mission_id_override = "phase9_side_job_test"
	var steps: Array[Resource] = []
	var previous := &""
	for index in step_ids.size():
		var step: Resource = CustomSequenceStepScript.new()
		step.step_id = step_ids[index]
		step.order_index = index + 1
		step.completion_flag = StringName("%s_%s_complete" % [sequence_id, String(step_ids[index])])
		if previous != &"":
			var dependencies: Array[StringName] = [previous]
			step.depends_on_step_ids = dependencies
		steps.append(step)
		previous = step_ids[index]
	sequence.steps = steps
	runner.sequence = sequence
	return runner


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
	GameState.current_mission_id = "phase9_side_job_test"
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


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
