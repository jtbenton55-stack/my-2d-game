# GdUnit4 tests for Phase 17 Taco route QA activation + level-builder readiness proof.
extends GdUnitTestSuite

const ControllerScript := preload("res://src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
const QAPanelScript := preload("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")
const ProofHarnessScript := preload("res://src/missions/iso/dev/Phase17LevelBuilderProofHarness.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")


func test_f12_phase17_routes_are_qa_only_actions() -> void:
	var panel := QAPanelScript.new()
	add_child(panel)
	panel.set("_mode", 8)
	var actions: Array = panel.call("_actions_for_mode")
	var methods: Array[String] = []
	for action in actions:
		methods.append(String((action as Dictionary).get("method", "")))
	assert_array(methods).contains("run_clean_social_route")
	assert_array(methods).contains("run_bentley_distraction_route")
	assert_array(methods).contains("run_evidence_route")
	assert_array(methods).contains("run_messy_authority_route")
	assert_array(methods).contains("run_cleanup_redirect_trace")
	assert_int(actions.size()).is_equal(5)
	_free_node(panel)


func test_phase16_route_label_reaches_mission_result_summary() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state("test_mission")
	var controller := ControllerScript.new()
	controller.name = "Phase16GarageManagerDeniabilityController"
	controller.start_on_ready = false
	controller.mission_id_override = "test_mission"
	add_child(controller)
	var route_result: Dictionary = controller.run_clean_social_route()
	assert_bool(route_result.get("ok", false)).is_true()
	GameState.start_mission("test_mission")
	var result: Dictionary = GameState.complete_mission("test_mission")
	var encounter: Dictionary = result.get("encounter", {})
	assert_bool(encounter.get("phase16", false)).is_true()
	assert_str(String(encounter.get("last_route_id", ""))).is_equal("clean_social_route")
	assert_str(String(encounter.get("last_route_label", ""))).is_equal("Clean Social")
	_restore_game_state(snapshot)
	_free_node(controller)


func test_level_builder_starter_and_non_taco_proof_scenes_load() -> void:
	assert_object(load("res://scenes/dev/mission_authoring/NewMissionStarterTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("RuntimeHelpers/MissionInteractionBridge")).is_not_null()
	assert_object(root.get_node_or_null("MissionMechanics/SearchZone_level_builder_entry")).is_not_null()
	assert_object(root.get_node_or_null("MissionMechanics/RewardNode_level_builder_badge")).is_not_null()
	assert_object(root.get_node_or_null("MissionMechanics/RouteUnlockNode_level_builder_service_hall")).is_not_null()
	assert_object(root.get_node_or_null("MissionMechanics/CompanionCommandPoint_level_builder_bentley")).is_not_null()
	assert_object(root.get_node_or_null("MissionMechanics/NoiseEmitterNode_level_builder_decoy")).is_not_null()
	assert_object(root.get_node_or_null("CanvasLayer/ProofHarness")).is_instanceof(ProofHarnessScript)
	_free_node(root)


func test_non_taco_level_builder_proof_runs_multiple_systems() -> void:
	var snapshot := _snapshot_game_state()
	var scene := load("res://scenes/dev/mission_authoring/Phase17LevelBuilderReadinessProofRoom.tscn") as PackedScene
	var root := scene.instantiate()
	add_child(root)
	var harness := root.get_node("CanvasLayer/ProofHarness")
	var result: Dictionary = harness.call("run_integrated_proof") as Dictionary
	assert_bool(result.get("ok", false)).is_true()
	var details: Dictionary = result.get("details", {})
	var encounter: Dictionary = details.get("encounter", {})
	var paper: Dictionary = details.get("paper_trail", {})
	var social: Dictionary = details.get("social_stealth", {})
	var reactive: Dictionary = details.get("reactive_npc", {})
	assert_bool(encounter.get("success", false)).is_true()
	assert_bool((encounter.get("result_tags", {}) as Dictionary).get("level_builder_route_ready", false)).is_true()
	assert_int(int(paper.get("total_events", 0))).is_equal(1)
	assert_int(int(social.get("task_count", 0))).is_equal(1)
	assert_int(int(reactive.get("signal_count", 0))).is_equal(1)
	_restore_game_state(snapshot)
	_free_node(root)


func test_mission_dock_and_static_validator_cover_phase17_readiness() -> void:
	var dock_text := FileAccess.get_file_as_string("res://addons/mission_dock/MissionDock.gd")
	assert_bool(dock_text.contains("LEVEL_BUILDER_AUDIT_SCRIPTS")).is_true()
	assert_bool(dock_text.contains("phase16_dev_trigger_found")).is_true()
	assert_bool(dock_text.contains("level_builder_mechanic_mix")).is_true()
	assert_bool(FileAccess.file_exists("res://src/tools/editor/phase17_level_builder_readiness/phase17_level_builder_readiness_validator.py")).is_true()


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(true),
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.completed_missions = (snapshot.get("completed_missions", []) as Array).duplicate(true)
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	PaperTrailAdapterScript.clear_all()
	SocialStealthAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.clear_all()


func _reset_runtime_state(mission_id: String) -> void:
	GameState.current_mission_id = mission_id
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance(mission_id)
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission(mission_id)
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission(mission_id)
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission(mission_id)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
