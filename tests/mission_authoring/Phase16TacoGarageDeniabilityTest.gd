# GdUnit4 tests for Phase 16 Taco garage-manager deniability production adoption.
extends GdUnitTestSuite

const ControllerScript := preload("res://src/missions/iso/runtime/Phase16GarageManagerDeniabilityController.gd")
const DevTriggerScript := preload("res://src/missions/iso/dev/Phase16GarageDeniabilityDevTrigger.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")


func test_clean_social_route_uses_social_and_encounter_adapters() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	var result: Dictionary = controller.run_clean_social_route()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("clean_social_route", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_cover_story_active", "garage_vendor_checkin", {"mission_id": "test_mission"})).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_inspection_passed", "garage_manager_checkin", {"mission_id": "test_mission"})).is_true()
	assert_bool(controller.success).is_true()
	_restore_game_state(snapshot)
	_free_node(controller)


func test_bentley_and_evidence_routes_record_deniability_state() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	var bentley_result: Dictionary = controller.run_bentley_distraction_route()
	assert_bool(bentley_result.get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("bentley_distraction_route", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_signal_recorded", "phase16_bentley_distraction_seen", {"mission_id": "test_mission"})).is_true()

	var evidence_result: Dictionary = controller.run_evidence_route()
	assert_bool(evidence_result.get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("evidence_route", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "phase16_garage_invoice_touch")).is_true()
	var cleanup_result: Dictionary = controller.run_cleanup_redirect_trace()
	assert_bool(cleanup_result.get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("cleanup_redirect_trace", false)).is_true()
	assert_int(int(controller.meter_values.get("evidence_strength", 0))).is_equal(5)
	_restore_game_state(snapshot)
	_free_node(controller)


func test_messy_route_reports_authority_without_global_manager() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	var result: Dictionary = controller.run_messy_authority_route()
	assert_bool(result.get("ok", true)).is_false()
	assert_bool(controller.result_tags.get("messy_authority_route", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_authority_reported", "taco_shift_authority", {"mission_id": "test_mission"})).is_true()
	assert_int(int(controller.meter_values.get("suspicion", 0))).is_equal(7)
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "phase16_manager_witness_report")).is_true()
	_restore_game_state(snapshot)
	_free_node(controller)


func test_taco_scene_contains_phase16_controller_and_preserves_bridge_scope() -> void:
	var scene_text := FileAccess.get_file_as_string("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")
	assert_bool(scene_text.contains("Phase16GarageManagerDeniabilityController.gd")).is_true()
	assert_bool(scene_text.contains("Phase16GarageManagerDeniabilityController" )).is_true()
	assert_bool(scene_text.contains("Phase16GarageDeniabilityDevTrigger.gd")).is_true()
	assert_bool(scene_text.contains("Phase16GarageDeniabilityDevTrigger" )).is_true()
	assert_bool(scene_text.contains("parent=\"GameplayRoot/PlugAndPlayPilot\"")).is_true()
	assert_bool(scene_text.contains("mission_id_override = \"taco_bell_drop\"")).is_true()
	assert_bool(scene_text.contains("include_legacy_candidates = false")).is_true()
	assert_bool(scene_text.contains("metadata/dev_only = true")).is_true()


func test_dev_trigger_calls_controller_without_interaction_scanning() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var root := Node.new()
	add_child(root)
	var controller := _make_controller()
	controller.name = "Phase16GarageManagerDeniabilityController"
	root.add_child(controller)
	var trigger := DevTriggerScript.new()
	trigger.name = "Phase16GarageDeniabilityDevTrigger"
	trigger.controller_path = NodePath("../Phase16GarageManagerDeniabilityController")
	root.add_child(trigger)
	var result: Dictionary = trigger.run_clean_social_route()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("clean_social_route", false)).is_true()
	assert_bool(trigger.has_method("interact")).is_false()
	assert_bool(trigger.has_method("is_interaction_available")).is_false()
	assert_bool(trigger.is_in_group("phase16_garage_deniability_dev_trigger")).is_true()
	_restore_game_state(snapshot)
	_free_node(root)


func _make_controller() -> Node:
	var controller := ControllerScript.new()
	controller.start_on_ready = false
	controller.mission_id_override = "test_mission"
	controller.auto_configure_default_data = true
	return controller


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


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission("test_mission")
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
