# GdUnit4 tests for Phase 18 player-facing Taco garage route actions.
extends GdUnitTestSuite

const ControllerScript := preload("res://src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
const CompletionControllerScript := preload("res://src/missions/iso/runtime/Phase0KMissionCompletionController.gd")
const RouteActionScript := preload("res://src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")


func test_route_action_gates_until_code_gate_objective_is_complete() -> void:
	var snapshot := _snapshot_state()
	_reset_runtime_state()
	var root := Node.new()
	add_child(root)
	var controller := _make_controller()
	root.add_child(controller)
	var action := _make_action("run_clean_social_route", "clean_social_route", "Clean Social")
	root.add_child(action)

	assert_bool(action.is_interaction_available()).is_false()
	assert_str(action.get_interaction_text()).contains("Open the garage code gate")
	QuestManager.complete_objective_id("open_garage_code_gate", "Open the garage code gate.", "test_mission")
	assert_bool(action.is_interaction_available()).is_true()

	_restore_state(snapshot)
	_free_node(root)


func test_route_action_can_gate_on_phase0k_controller_bool() -> void:
	var snapshot := _snapshot_state()
	_reset_runtime_state()
	var root := Node.new()
	add_child(root)
	var controller := _make_controller()
	root.add_child(controller)
	var completion_controller := CompletionControllerScript.new()
	completion_controller.name = "Phase0KMissionCompletionController"
	completion_controller.mission_id = "test_mission"
	root.add_child(completion_controller)
	var action := _make_action("run_clean_social_route", "clean_social_route", "Clean Social")
	action.required_completed_objective_id = &""
	action.required_controller_bool_path = NodePath("../Phase0KMissionCompletionController")
	action.required_controller_bool_property = &"code_gate_unlocked"
	root.add_child(action)

	assert_bool(action.is_interaction_available()).is_false()
	completion_controller.set_code_gate_unlocked(true)
	assert_bool(action.is_interaction_available()).is_true()

	_restore_state(snapshot)
	_free_node(root)


func test_route_action_records_choice_and_locks_other_routes() -> void:
	var snapshot := _snapshot_state()
	_reset_runtime_state()
	QuestManager.complete_objective_id("open_garage_code_gate", "Open the garage code gate.", "test_mission")
	var root := Node.new()
	add_child(root)
	var controller := _make_controller()
	root.add_child(controller)
	var clean_action := _make_action("run_clean_social_route", "clean_social_route", "Clean Social")
	var evidence_action := _make_action("run_evidence_route", "evidence_route", "Evidence Chain")
	root.add_child(clean_action)
	root.add_child(evidence_action)

	var result: Dictionary = clean_action.activate(null, "test")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(MissionFactBridge.get_fact_value(&"mission_flag", "phase18_garage_route_selected", {"mission_id": "test_mission"}))).is_equal("clean_social_route")
	assert_bool(bool(MissionFactBridge.get_fact_value(&"mission_flag", "phase18_clean_social_route_selected", {"mission_id": "test_mission"}))).is_true()
	assert_str(String(MissionFactBridge.get_fact_value(&"mission_flag", "phase18_garage_route_style", {"mission_id": "test_mission"}))).is_equal("Deniable")
	assert_bool(evidence_action.is_interaction_available()).is_false()
	assert_str(evidence_action.get_interaction_text()).contains("Garage route already selected")

	_restore_state(snapshot)
	_free_node(root)


func test_route_style_reaches_mission_result_summary() -> void:
	var snapshot := _snapshot_state()
	_reset_runtime_state()
	QuestManager.complete_objective_id("open_garage_code_gate", "Open the garage code gate.", "test_mission")
	var root := Node.new()
	add_child(root)
	var controller := _make_controller()
	root.add_child(controller)
	var action := _make_action("run_evidence_route", "evidence_route", "Evidence Chain")
	root.add_child(action)

	var route_result: Dictionary = action.activate(null, "test")
	assert_bool(route_result.get("ok", false)).is_true()
	var summary: Dictionary = controller.get_summary()
	assert_str(String(summary.get("last_route_label", ""))).is_equal("Evidence Chain")
	assert_str(String(summary.get("last_route_style_label", ""))).is_equal("Evidence-Strong")

	_restore_state(snapshot)
	_free_node(root)


func test_taco_scene_contains_phase18_player_route_actions_and_preserves_bridge_scope() -> void:
	var scene_text := FileAccess.get_file_as_string("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")
	assert_bool(scene_text.contains("EncounterRouteActionNode.gd")).is_true()
	assert_bool(scene_text.contains("Phase18GarageRouteActions")).is_true()
	assert_bool(scene_text.contains("Phase18CleanSocialRouteAction")).is_true()
	assert_bool(scene_text.contains("Phase18BentleyDistractionRouteAction")).is_true()
	assert_bool(scene_text.contains("Phase18EvidenceRouteAction")).is_true()
	assert_bool(scene_text.contains("Phase18MessyAuthorityRouteAction")).is_true()
	assert_bool(scene_text.contains("required_controller_bool_property = &\"code_gate_unlocked\"")).is_true()
	assert_bool(scene_text.contains("prompt_target_path = NodePath(\"../../PlugAndPlayPilot/Phase18GarageRoutePrompt\")")).is_true()
	assert_bool(scene_text.contains("include_legacy_candidates = false")).is_true()
	assert_bool(scene_text.contains("include_legacy_candidates = true")).is_false()


func test_mission_dock_and_static_validator_cover_phase18_routes() -> void:
	var dock_text := FileAccess.get_file_as_string("res://addons/mission_dock/MissionDock.gd")
	assert_bool(dock_text.contains("EncounterRouteActionNode")).is_true()
	assert_bool(dock_text.contains("phase18_player_route_action_found")).is_true()
	assert_bool(FileAccess.file_exists("res://src/tools/editor/phase18_taco_player_routes/phase18_taco_player_routes_validator.py")).is_true()


func _make_controller() -> Node:
	var controller := ControllerScript.new()
	controller.name = "Phase16GarageManagerDeniabilityController"
	controller.start_on_ready = false
	controller.mission_id_override = "test_mission"
	controller.auto_configure_default_data = true
	return controller


func _make_action(method_name: String, route_id: String, route_label: String) -> Node:
	var action := RouteActionScript.new()
	action.name = route_id.capitalize().replace(" ", "")
	action.controller_path = NodePath("../Phase16GarageManagerDeniabilityController")
	action.route_method = method_name
	action.route_id = StringName(route_id)
	action.route_label = route_label
	action.route_specific_flag = StringName("phase18_%s_selected" % route_id)
	action.required_completed_objective_id = &"open_garage_code_gate"
	action.progress_locked_message = "Open the garage code gate before choosing a deniability route."
	action.mechanic_id = StringName("phase18_%s_action" % route_id)
	action.mission_id_override = "test_mission"
	action.one_shot = false
	return action


func _snapshot_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(true),
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
		"quest_active_quest_id": QuestManager.active_quest_id,
		"quest_active_objective": QuestManager.active_objective,
		"quest_objectives": QuestManager.objectives.duplicate(true),
		"quest_objective_records": QuestManager.objective_records.duplicate(true),
		"quest_active_objectives": QuestManager.active_objectives.duplicate(true),
		"quest_completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.completed_missions = (snapshot.get("completed_missions", []) as Array).duplicate(true)
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	QuestManager.active_quest_id = String(snapshot.get("quest_active_quest_id", ""))
	QuestManager.active_objective = String(snapshot.get("quest_active_objective", ""))
	QuestManager.objectives = (snapshot.get("quest_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("quest_objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("quest_active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("quest_completed_objectives", {}) as Dictionary).duplicate(true)
	PaperTrailAdapterScript.clear_all()
	SocialStealthAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.clear_all()


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	QuestManager.active_quest_id = "test_mission"
	QuestManager.active_objective = ""
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()
	QuestManager.add_objective("open_garage_code_gate", "Open the garage code gate.", "active", "test_mission")
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission("test_mission")
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
