# GdUnit4 tests for Phase 11A-11F paper trail and deniability authoring.
extends GdUnitTestSuite

const PaperTrailTraceEventScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailTraceEvent.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const AuditTrailCleanupNodeScript := preload("res://src/missions/iso/authoring/mechanics/AuditTrailCleanupNode.gd")
const HeatSinkObjectScript := preload("res://src/missions/iso/authoring/mechanics/HeatSinkObject.gd")
const DoorStateMemoryNodeScript := preload("res://src/missions/iso/authoring/mechanics/DoorStateMemoryNode.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")


func test_trace_event_schema_is_inspectable() -> void:
	var event := PaperTrailTraceEventScript.make_event("trace_a", "test_mission", "door_01", "door_memory", 2, true, "wipe_down", {"note": "test"})
	assert_str(String(event.get("trace_id", ""))).is_equal("trace_a")
	assert_str(String(event.get("mission_id", ""))).is_equal("test_mission")
	assert_str(String(event.get("source_id", ""))).is_equal("door_01")
	assert_str(String(event.get("trace_type", ""))).is_equal("door_memory")
	assert_int(int(event.get("severity", 0))).is_equal(2)
	assert_bool(bool(event.get("can_cleanup", false))).is_true()
	assert_str(String(event.get("cleanup_requirement", ""))).is_equal("wipe_down")
	assert_str(String(event.get("status", ""))).is_equal("active")


func test_adapter_records_cleans_redirects_and_summarizes() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "unit_test"}
	var record_result: Dictionary = PaperTrailAdapterScript.record_trace("trace_cleanup", "door_01", "door_memory", 3, true, "wipe_down", context)
	assert_bool(record_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "trace_cleanup")).is_true()
	assert_int(PaperTrailAdapterScript.count_active_traces_by_type("test_mission", "door_memory")).is_equal(1)

	var clean_result: Dictionary = PaperTrailAdapterScript.cleanup_traces({"trace_id": "trace_cleanup", "cleanup_requirement": "wipe_down"}, context)
	assert_bool(clean_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "trace_cleanup")).is_false()

	PaperTrailAdapterScript.record_trace("trace_redirect", "camera_01", "camera_seen", 2, false, "", context)
	var redirect_result: Dictionary = PaperTrailAdapterScript.redirect_traces({"trace_id": "trace_redirect", "severity_reduction": 1}, "delivery_note", context)
	assert_bool(redirect_result.get("ok", false)).is_true()
	var summary: Dictionary = PaperTrailAdapterScript.get_summary("test_mission")
	assert_int(int(summary.get("total_events", 0))).is_equal(2)
	assert_int(int(summary.get("cleaned_events", 0))).is_equal(1)
	assert_int(int(summary.get("redirected_events", 0))).is_equal(1)
	assert_str(String(summary.get("result_state", ""))).is_equal("seen")
	_restore_game_state(snapshot)


func test_effect_applier_routes_paper_trail_effects() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "effect_test"}
	var record := MissionEffectScript.new()
	record.effect_type = MissionEffectScript.EffectType.RECORD_PAPER_TRACE
	record.key = "effect_trace"
	record.payload = {"trace_type": "audit_log", "severity": 2, "can_cleanup": true, "cleanup_requirement": "wipe_down"}
	var record_result: Dictionary = record.apply(context)
	assert_bool(record_result.get("ok", false)).is_true()

	var cleanup := MissionEffectScript.new()
	cleanup.effect_type = MissionEffectScript.EffectType.CLEANUP_PAPER_TRACE
	cleanup.key = "effect_trace"
	cleanup.payload = {"cleanup_requirement": "wipe_down"}
	var cleanup_result: Dictionary = cleanup.apply(context)
	assert_bool(cleanup_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "effect_trace")).is_false()
	_restore_game_state(snapshot)


func test_mechanic_nodes_extend_base_and_change_trace_state() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var door := DoorStateMemoryNodeScript.new()
	door.mission_id_override = "test_mission"
	door.door_id = &"server_door"
	door.trace_id = &"server_door_trace"
	door.opened_flag = &"server_door_opened"
	add_child(door)
	assert_object(door).is_instanceof(MechanicAreaBaseScript)
	var door_result: Dictionary = door.activate(null, "test")
	assert_bool(door_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "server_door_trace")).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:server_door_opened", false)).is_true()

	var heat_sink := HeatSinkObjectScript.new()
	heat_sink.mission_id_override = "test_mission"
	heat_sink.target_trace_id = &"server_door_trace"
	heat_sink.explanation_id = &"delivery_check"
	add_child(heat_sink)
	var redirect_result: Dictionary = heat_sink.redirect_trace(null, "test")
	assert_bool(redirect_result.get("ok", false)).is_true()

	var cleanup := AuditTrailCleanupNodeScript.new()
	cleanup.mission_id_override = "test_mission"
	cleanup.target_trace_id = &"server_door_trace"
	cleanup.cleanup_requirement = &"wipe_down"
	add_child(cleanup)
	var cleanup_result: Dictionary = cleanup.cleanup_trace(null, "test")
	assert_bool(cleanup_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "server_door_trace")).is_false()

	_restore_game_state(snapshot)
	_free_node(door)
	_free_node(heat_sink)
	_free_node(cleanup)


func test_mission_result_receives_paper_trail_summary() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	GameState.start_mission("test_mission")
	PaperTrailAdapterScript.record_trace("result_trace", "camera_01", "camera_seen", 2, false, "", {"mission_id": "test_mission"})
	var result: Dictionary = GameState.complete_mission("test_mission")
	assert_bool(result.has("paper_trail")).is_true()
	assert_str(String(result.get("paper_trail_state", ""))).is_equal("seen")
	var summary: Dictionary = result.get("paper_trail", {})
	assert_int(int(summary.get("active_events", 0))).is_equal(1)
	_restore_game_state(snapshot)


func test_templates_and_dev_scene_contain_phase11_nodes() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/AuditTrailCleanupNodeTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/HeatSinkObjectTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/DoorStateMemoryNodeTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase11PaperTrailProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/DoorStateMemoryNode_phase11e_door_memory")).is_instanceof(DoorStateMemoryNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/AuditTrailCleanupNode_phase11c_cleanup")).is_instanceof(AuditTrailCleanupNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/HeatSinkObject_phase11d_misdirection")).is_instanceof(HeatSinkObjectScript)
	root.queue_free()


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


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
