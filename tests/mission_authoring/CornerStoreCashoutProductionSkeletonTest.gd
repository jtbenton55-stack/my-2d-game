# GdUnit4 tests for Corner Store Cashout production skeleton mission.
extends GdUnitTestSuite

const MISSION_ID := "corner_store_cashout"
const SCENE_PATH := "res://scenes/missions_iso/CornerStoreCashout_Editable.tscn"
const MissionControllerScript := preload("res://src/missions/iso/runtime/CornerStoreCashoutMissionController.gd")
const EncounterControllerScript := preload("res://src/missions/iso/runtime/CornerStoreCashoutEncounterController.gd")
const RouteActionScript := preload("res://src/missions/iso/authoring/mechanics/EncounterRouteActionNode.gd")
const LockedInteractionNodeScript := preload("res://src/missions/iso/authoring/mechanics/LockedInteractionNode.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")


func before() -> void:
	_reset_runtime_state()


func after() -> void:
	_reset_runtime_state()


func test_scene_loads_with_expected_structure() -> void:
	var scene := load(SCENE_PATH) as PackedScene
	assert_object(scene).is_not_null()
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	assert_bool(scene_text.contains("CornerStoreCashoutMissionController")).is_true()
	assert_bool(scene_text.contains("MissionInteractionBridge")).is_true()
	assert_bool(scene_text.contains("ExtractionZone_csc_alley_extract")).is_true()
	assert_bool(scene_text.contains("SpawnPoints/default") or scene_text.contains('parent="GameplayRoot/SpawnPoints"')).is_true()


func test_mission_catalog_resolves_playable_scene() -> void:
	var path := MissionSceneResolver.resolve_playable_scene_path(MISSION_ID)
	assert_str(path).is_equal(SCENE_PATH)
	var report: Dictionary = MissionSceneResolver.get_resolution_report(MISSION_ID)
	assert_bool(report.get("ok", false)).is_true()
	assert_str(String(report.get("chosen_playable_path", ""))).is_equal(SCENE_PATH)


func test_bridge_scope_is_safe() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	assert_bool("include_legacy_candidates = false" in scene_text).is_true()
	assert_bool("include_legacy_candidates = true" in scene_text).is_false()


func test_core_objective_flag_chain_updates_controller() -> void:
	var controller := MissionControllerScript.new()
	add_child(controller)
	controller.mission_id = MISSION_ID
	controller.reset_attempt_state()
	_set_flag("csc_entry_clue_found")
	controller.sync_from_mission_facts()
	assert_bool(controller.entry_clue_found).is_true()
	_set_flag("csc_badge_collected")
	controller.sync_from_mission_facts()
	assert_bool(controller.badge_collected).is_true()
	_set_flag("csc_checkpoint_open")
	controller.sync_from_mission_facts()
	assert_bool(controller.back_office_unlocked).is_true()
	_set_flag("csc_evidence_collected")
	controller.sync_from_mission_facts()
	assert_bool(controller.evidence_collected).is_true()
	_free_node(controller)


func test_locked_office_door_blocks_before_badge_requirement() -> void:
	GameState.start_mission(MISSION_ID)
	var door := LockedInteractionNodeScript.new()
	door.mission_id_override = MISSION_ID
	door.unlocked_flag = &"csc_checkpoint_open"
	door.requirements = _badge_requirement_set()
	add_child(door)
	var blocked: Dictionary = door.evaluate_requirements()
	assert_bool(blocked.get("ok", true)).is_false()
	_set_flag("csc_badge_collected")
	var allowed: Dictionary = door.evaluate_requirements()
	assert_bool(allowed.get("ok", false)).is_true()
	_free_node(door)


func test_route_unlock_and_side_objective_nodes_exist() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	assert_bool(scene_text.contains("RouteUnlockNode_csc_alley_route")).is_true()
	assert_bool(scene_text.contains("SideObjectiveNode_csc_coupon_scam")).is_true()
	assert_bool(scene_text.contains("DeadDropNode_csc_alley_drop")).is_true()
	assert_bool(scene_text.contains("CustomSequenceRunner_csc_side_job")).is_true()


func test_extraction_blocks_before_required_objectives() -> void:
	const ExtractionZoneScript := preload("res://src/missions/iso/authoring/mechanics/ExtractionZone.gd")
	var extraction := ExtractionZoneScript.new()
	extraction.mission_id_override = MISSION_ID
	extraction.required_objective_ids = [&"recover_cashout_evidence", &"choose_cleanup_route"]
	add_child(extraction)
	GameState.start_mission(MISSION_ID)
	var blocked: Dictionary = extraction.can_extract()
	assert_bool(blocked.get("ok", true)).is_false()
	ObjectiveStepController.complete_objective("recover_cashout_evidence", "", MISSION_ID)
	ObjectiveStepController.complete_objective("choose_cleanup_route", "", MISSION_ID)
	var allowed: Dictionary = extraction.can_extract()
	assert_bool(allowed.get("ok", false)).is_true()
	_free_node(extraction)


func test_route_choice_locks_competitors() -> void:
	GameState.start_mission(MISSION_ID)
	var root := Node.new()
	add_child(root)
	var mission_controller := MissionControllerScript.new()
	mission_controller.name = "CornerStoreCashoutMissionController"
	mission_controller.mission_id = MISSION_ID
	mission_controller.back_office_unlocked = true
	root.add_child(mission_controller)
	var encounter_controller := EncounterControllerScript.new()
	encounter_controller.name = "CornerStoreCashoutEncounterController"
	encounter_controller.start_on_ready = false
	encounter_controller.mission_id_override = MISSION_ID
	root.add_child(encounter_controller)
	var clean_route := _make_route_action("run_clean_social_route", "clean_social_route", "Clean Social Helper")
	var bentley_route := _make_route_action("run_bentley_distraction_route", "bentley_distraction_route", "Bentley Distraction")
	root.add_child(clean_route)
	root.add_child(bentley_route)
	assert_bool(clean_route.call("is_interaction_available")).is_true()
	var route_result: Dictionary = clean_route.call("activate", null, "test")
	assert_bool(route_result.get("ok", false)).is_true()
	assert_bool(bentley_route.call("is_interaction_available")).is_false()
	_free_node(root)


func test_encounter_route_summary_contains_route_labels() -> void:
	var controller := EncounterControllerScript.new()
	add_child(controller)
	controller.start_on_ready = false
	controller.mission_id_override = MISSION_ID
	var route_result: Dictionary = controller.run_clean_social_route()
	assert_bool(route_result.get("ok", false)).is_true()
	var summary: Dictionary = controller.get_summary()
	assert_str(String(summary.get("last_route_label", ""))).is_equal("Clean Social")
	assert_str(String(summary.get("last_route_style_label", ""))).is_equal("Deniable")
	_free_node(controller)


func test_taco_completion_unlocks_corner_store_in_game_state() -> void:
	var snapshot := GameState.available_missions.duplicate()
	GameState.available_missions.clear()
	GameState._unlock_next_missions("taco_bell_drop")
	assert_bool(GameState.available_missions.has("corner_store_cashout")).is_true()
	GameState.available_missions = snapshot


func test_completion_bridge_finds_runtime_helpers_mission_controller() -> void:
	const MissionCompletionBridgeScript := preload("res://src/missions/iso/authoring/core/MissionCompletionBridge.gd")
	var root := Node.new()
	root.name = "CornerStoreCashout"
	add_child(root)
	var runtime_helpers := Node.new()
	runtime_helpers.name = "RuntimeHelpers"
	root.add_child(runtime_helpers)
	var mission_controller := MissionControllerScript.new()
	mission_controller.name = "CornerStoreCashoutMissionController"
	runtime_helpers.add_child(mission_controller)
	var found: Node = MissionCompletionBridgeScript.find_completion_controller({"mechanic": root})
	assert_object(found).is_same(mission_controller)
	_free_node(root)


func test_scene_includes_debug_proof_harness() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	assert_bool(scene_text.contains("CornerStoreCashoutIntegratedProofHarness")).is_true()
	assert_bool(scene_text.contains("GameplayRoot/DebugProof")).is_true()


func _badge_requirement_set() -> Resource:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = "csc_badge_collected"
	requirement.operator = MissionRequirementScript.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [requirement]
	req_set.locked_message = "Need an employee credential first."
	return req_set


func _make_route_action(method_name: String, route_id: String, route_label: String) -> Node:
	var action := RouteActionScript.new()
	action.name = route_id
	action.controller_path = NodePath("../CornerStoreCashoutEncounterController")
	action.required_controller_bool_path = NodePath("../CornerStoreCashoutMissionController")
	action.required_controller_bool_property = &"back_office_unlocked"
	action.route_method = method_name
	action.route_id = StringName(route_id)
	action.route_label = route_label
	action.route_choice_flag = &"csc_route_selected"
	action.route_specific_flag = StringName("csc_route_%s" % route_id)
	action.mission_id_override = MISSION_ID
	action.one_shot = false
	return action


func _set_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": MISSION_ID})


func _free_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _reset_runtime_state() -> void:
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()
