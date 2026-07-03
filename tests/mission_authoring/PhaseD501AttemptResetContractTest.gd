extends GdUnitTestSuite

const MissionObjectiveBridgeScript := preload("res://src/missions/objectives/MissionObjectiveBridge.gd")
const Phase0JInteractablePickupScript := preload("res://src/missions/iso/runtime/Phase0JInteractablePickup.gd")
const Phase0JMissionStateAdapterScript := preload("res://src/missions/iso/runtime/Phase0JMissionStateAdapter.gd")
const Phase0JRuntimeMarkerLabelScript := preload("res://src/missions/iso/runtime/Phase0JRuntimeMarkerLabel.gd")
const Phase0KMissionCompletionControllerScript := preload("res://src/missions/iso/runtime/Phase0KMissionCompletionController.gd")
const IsoMissionBaseScript := preload("res://src/levels/IsoMissionBase.gd")
const MissionPauseDataProviderScript := preload("res://src/missions/ui/MissionPauseDataProvider.gd")


func test_objective_bridge_reset_clears_only_target_mission_runtime_objectives() -> void:
	var snapshot := _snapshot_quest_manager()
	QuestManager.active_quest_id = "taco_bell_drop"
	QuestManager.active_objective = "Stale Taco objective"
	QuestManager.objectives = {
		"taco_bell_drop": "Stale Taco objective",
		"other_mission": "Other mission objective",
	}
	QuestManager.objective_records = {
		"taco_bell_drop": {"recover_delivery_bag": {"status": "completed"}},
		"other_mission": {"other_objective": {"status": "active"}},
	}
	QuestManager.active_objectives = {
		"taco_bell_drop": {"return_to_louis": {"status": "active"}},
		"other_mission": {"other_objective": {"status": "active"}},
	}
	QuestManager.completed_objectives = {
		"taco_bell_drop": ["Recover the delivery bag."],
		"other_mission": ["Other objective"],
	}

	var result: Dictionary = MissionObjectiveBridgeScript.reset_runtime_objectives_for_mission("taco_bell_drop")

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(QuestManager.objectives.has("taco_bell_drop")).is_false()
	assert_bool(QuestManager.objective_records.has("taco_bell_drop")).is_false()
	assert_bool(QuestManager.active_objectives.has("taco_bell_drop")).is_false()
	assert_bool(QuestManager.completed_objectives.has("taco_bell_drop")).is_false()
	assert_str(QuestManager.active_quest_id).is_equal("")
	assert_str(QuestManager.active_objective).is_equal("")
	assert_str(String(QuestManager.objectives.get("other_mission", ""))).is_equal("Other mission objective")
	assert_bool(QuestManager.objective_records.has("other_mission")).is_true()
	assert_bool(QuestManager.active_objectives.has("other_mission")).is_true()
	assert_bool(QuestManager.completed_objectives.has("other_mission")).is_true()

	_restore_quest_manager(snapshot)


func test_phase0k_reset_attempt_state_clears_bag_code_exit_and_reseeds_objectives() -> void:
	var snapshot := _snapshot_quest_manager()
	var controller: Node = Phase0KMissionCompletionControllerScript.new()
	controller.set("mission_id", "taco_bell_drop")
	add_child(controller)

	controller.call("set_delivery_bag_collected", true)
	controller.call("set_code_gate_unlocked", true)
	controller.call("unlock_exit")
	controller.set("mission_completed", true)
	(controller.get("completed_objectives") as Dictionary)["return_to_louis"] = true
	QuestManager.complete_objective_id("recover_delivery_bag", "Recover the delivery bag.", "taco_bell_drop")
	assert_bool(bool(controller.get("delivery_bag_collected"))).is_true()
	assert_bool(bool(controller.get("code_gate_unlocked"))).is_true()
	assert_bool(bool(controller.get("exit_unlocked"))).is_true()
	assert_bool(QuestManager.is_objective_completed("recover_delivery_bag", "taco_bell_drop")).is_true()

	var result: Dictionary = controller.call("reset_attempt_state")

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(bool(controller.get("delivery_bag_collected"))).is_false()
	assert_bool(bool(controller.get("code_gate_unlocked"))).is_false()
	assert_bool(bool(controller.get("required_objectives_complete"))).is_false()
	assert_bool(bool(controller.get("exit_unlocked"))).is_false()
	assert_bool(bool(controller.get("mission_completed"))).is_false()
	assert_int((controller.get("completed_objectives") as Dictionary).size()).is_equal(0)
	assert_bool(QuestManager.is_objective_completed("recover_delivery_bag", "taco_bell_drop")).is_false()
	assert_bool(QuestManager.has_objective("open_garage_code_gate", "taco_bell_drop")).is_true()
	assert_bool(QuestManager.has_objective("recover_delivery_bag", "taco_bell_drop")).is_true()
	assert_bool(QuestManager.has_objective("return_to_louis", "taco_bell_drop")).is_true()
	var active_objectives := QuestManager.get_active_objectives("taco_bell_drop")
	assert_array(active_objectives).contains("Open the garage code gate.")
	assert_array(active_objectives).contains("Recover the delivery bag.")

	_free_node(controller)
	await get_tree().process_frame
	_restore_quest_manager(snapshot)


func test_phase0j_bag_interactable_reset_restores_visual_collision_and_label() -> void:
	var label: Node = Phase0JRuntimeMarkerLabelScript.new()
	label.name = "RuntimeLabel"
	label.set("marker_id", "OBJ_bag_recovery")
	label.set("category", "objective_bag")
	add_child(label)

	var pickup: Area2D = Phase0JInteractablePickupScript.new()
	pickup.name = "Interactable_OBJ_bag_recovery"
	pickup.set("candidate_id", "OBJ_bag_recovery")
	pickup.set("runtime_label_path", NodePath("../RuntimeLabel"))
	var visual := Polygon2D.new()
	visual.name = "RuntimeVisual"
	pickup.add_child(visual)
	add_child(pickup)

	pickup.call("_mark_collected")
	assert_bool(bool(pickup.get("collected"))).is_true()
	assert_int(int(pickup.collision_layer)).is_equal(0)
	var marked_text := _label_text(label)
	assert_bool(marked_text.contains("COLLECTED")).is_true()

	var result: Dictionary = pickup.call("reset_attempt_state")

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(bool(pickup.get("collected"))).is_false()
	assert_bool(bool(pickup.get_meta("collected", true))).is_false()
	assert_bool(pickup.monitoring).is_true()
	assert_bool(pickup.monitorable).is_true()
	assert_int(int(pickup.collision_layer)).is_equal(8)
	assert_int(int(pickup.collision_mask)).is_equal(1)
	assert_bool(_label_text(label).contains("COLLECTED")).is_false()

	_free_node(pickup)
	_free_node(label)
	await get_tree().process_frame


func test_phase0j_state_adapter_reset_forgets_collected_delivery_bag() -> void:
	var adapter: Node = Phase0JMissionStateAdapterScript.new()
	adapter.set("mission_id", "taco_bell_drop")
	add_child(adapter)

	var collect_result: Dictionary = adapter.call("collect_item", "OBJ_bag_recovery", "intel", {"mission_id": "taco_bell_drop"})
	assert_bool(collect_result.get("success", false)).is_true()
	assert_bool(adapter.call("has_collected", "OBJ_bag_recovery")).is_true()
	assert_int(int(adapter.call("get_count", "objective_bag"))).is_equal(1)

	var result: Dictionary = adapter.call("reset_attempt_state")

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(adapter.call("has_collected", "OBJ_bag_recovery")).is_false()
	assert_int(int(adapter.call("get_count", "objective_bag"))).is_equal(0)

	_free_node(adapter)
	await get_tree().process_frame


func test_d5_security_reset_rearms_beam_and_removes_response_guards() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D501SecurityResetMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	var gameplay := mission.get_node("GameplayRoot") as Node2D
	var runtime := gameplay.get_node("RuntimeSystems") as Node2D
	var alarm_zones := runtime.get_node("AlarmZones") as Node2D
	var beam := Area2D.new()
	beam.name = "AlarmZone_AMBUSH_security_beam"
	beam.monitoring = false
	beam.monitorable = false
	beam.collision_mask = 0
	alarm_zones.add_child(beam)
	var entity := mission.get_node("EntityRoot") as Node2D
	var enemies := entity.get_node("Enemies") as Node2D
	var response_guard := Node2D.new()
	response_guard.name = "AuthoredBeamResponseGuard"
	response_guard.set_meta("security_response_guard", true)
	enemies.add_child(response_guard)
	var ambient_guard := Node2D.new()
	ambient_guard.name = "AmbientPatrolGuard"
	enemies.add_child(ambient_guard)

	var result: Dictionary = mission.call("_reset_d5_attempt_security_runtime")

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(beam.monitoring).is_true()
	assert_bool(beam.monitorable).is_true()
	assert_int(int(beam.collision_mask)).is_equal(1)
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	mission.add_child(player)
	beam.body_entered.emit(player)
	assert_bool(mission.call("_is_runtime_flag_true", "alarm_triggered:AMBUSH_security_beam")).is_true()
	assert_bool(response_guard.get_parent() == null).is_true()
	assert_bool(response_guard.is_queued_for_deletion()).is_true()
	assert_object(ambient_guard.get_parent()).is_same(enemies)

	_free_node(mission)
	await get_tree().process_frame


func test_d5_reset_preclear_removes_live_cameras_and_attempt_guards() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D501LiveSecurityPreclearMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	var entity := mission.get_node("EntityRoot") as Node2D
	var cameras := entity.get_node("Cameras") as Node2D
	var camera_a := Area2D.new()
	camera_a.name = "SecurityCamera_A"
	cameras.add_child(camera_a)
	var camera_b := Area2D.new()
	camera_b.name = "SecurityCamera_B"
	cameras.add_child(camera_b)
	var enemies := entity.get_node("Enemies") as Node2D
	var runtime_guard := Node2D.new()
	runtime_guard.name = "RuntimeDefinitionGuard"
	runtime_guard.set_meta("d5_attempt_runtime_guard", true)
	enemies.add_child(runtime_guard)
	var response_guard := Node2D.new()
	response_guard.name = "BeamResponseGuard"
	response_guard.set_meta("security_response_spawn", true)
	enemies.add_child(response_guard)
	var ambient_guard := Node2D.new()
	ambient_guard.name = "AmbientGuard"
	enemies.add_child(ambient_guard)
	mission.set("_pending_security_guard_source_ids", ["alarm_AMBUSH_security_beam"])
	mission.set("_security_guard_spawn_flush_scheduled", true)

	var result: Dictionary = mission.call("_clear_d5_attempt_live_security_runtime")

	assert_bool(result.get("ok", false)).is_true()
	assert_int((result.get("removed_cameras", []) as Array).size()).is_equal(2)
	assert_int((result.get("removed_guards", []) as Array).size()).is_equal(2)
	assert_bool(camera_a.get_parent() == null).is_true()
	assert_bool(camera_b.get_parent() == null).is_true()
	assert_bool(runtime_guard.get_parent() == null).is_true()
	assert_bool(response_guard.get_parent() == null).is_true()
	assert_object(ambient_guard.get_parent()).is_same(enemies)
	assert_int((mission.get("_pending_security_guard_source_ids") as Array).size()).is_equal(0)
	assert_bool(bool(mission.get("_security_guard_spawn_flush_scheduled"))).is_false()

	_free_node(mission)
	await get_tree().process_frame


func test_runtime_rebuild_clear_children_removes_queued_nodes_immediately() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D501ClearChildrenMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	var parent := Node2D.new()
	parent.name = "RuntimeBucket"
	mission.add_child(parent)
	var stale_area := Area2D.new()
	stale_area.name = "AlarmZone_AMBUSH_security_beam"
	parent.add_child(stale_area)

	mission.call("_clear_children", parent)

	assert_bool(stale_area.get_parent() == null).is_true()
	assert_bool(stale_area.is_queued_for_deletion()).is_true()
	assert_object(parent.get_node_or_null("AlarmZone_AMBUSH_security_beam")).is_null()

	_free_node(mission)
	await get_tree().process_frame


func test_authoring_beam_trip_marks_same_runtime_flag_as_f12_dashboard() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D501AuthoringBeamMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)

	mission.call("_emit_security_authoring_event", &"ambush_beam_tripped", {
		"source_type": "security_beam_author",
		"source_id": "AMBUSH_security_beam",
	})

	assert_bool(mission.call("_is_runtime_flag_true", "alarm_triggered:AMBUSH_security_beam")).is_true()
	assert_int(int((mission.get("_attempt_runtime_state") as Dictionary).get("beam_trip", 0))).is_equal(1)
	assert_bool(bool((mission.get("_attempt_runtime_state") as Dictionary).get("d5_01_authoring_beam_trip_marked", false))).is_true()

	_free_node(mission)
	await get_tree().process_frame


func test_stale_security_event_router_is_not_reused_after_runtime_rebuild() -> void:
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D501StaleRouterMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	var router := Node.new()
	router.name = "SecurityEventRouter"
	mission.get_node("GameplayRoot/RuntimeSystems").add_child(router)
	mission.call("set_security_event_router", router)
	assert_object(mission.call("get_security_event_router")).is_same(router)

	router.get_parent().remove_child(router)
	router.queue_free()

	assert_object(mission.call("get_security_event_router")).is_null()

	_free_node(mission)
	await get_tree().process_frame


func test_d5_pause_payload_uses_live_taco_mission_context() -> void:
	var quest_snapshot := _snapshot_quest_manager()
	var game_snapshot := _snapshot_game_state()
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D502PauseContextMission"
	mission.set("mission_id", "taco_bell_drop")
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	GameState.current_mission_id = ""
	MissionObjectiveBridgeScript.seed_runtime_objectives_for_mission("taco_bell_drop", [
		{"id": "open_garage_code_gate", "text": "Open the garage code gate.", "status": "active"},
		{"id": "recover_delivery_bag", "text": "Recover the delivery bag.", "status": "active"},
	], true)
	GameState.unlock_scheme_card("louis_delivery_route", {"source": "test"})

	var payload: Dictionary = MissionPauseDataProviderScript.get_pause_payload("", mission)
	var facts: Dictionary = payload.get("attempt_facts", {}) as Dictionary

	assert_str(String(payload.get("mission_id", ""))).is_equal("taco_bell_drop")
	assert_str(String(payload.get("mission_name", ""))).is_equal("The Taco Bell Drop")
	assert_int((payload.get("objectives", []) as Array).size()).is_greater(0)
	assert_int((payload.get("attempt_context", []) as Array).size()).is_greater(0)
	assert_bool(bool(facts.get("louis_route_available", false))).is_true()
	assert_bool(facts.has("garage_beam_armed")).is_true()

	_free_node(mission)
	await get_tree().process_frame
	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)


func test_d5_louis_route_bypasses_beam_without_marking_alarm_trip() -> void:
	var game_snapshot := _snapshot_game_state()
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D503LouisBypassMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	GameState.unlock_scheme_card("louis_delivery_route", {"source": "test"})
	var area := Area2D.new()
	area.name = "AlarmZone_AMBUSH_security_beam"
	mission.add_child(area)
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	mission.add_child(player)

	mission.call("_on_runtime_alarm_zone_entered", player, "AMBUSH_security_beam", area)
	var state: Dictionary = mission.get("_attempt_runtime_state") as Dictionary
	var summary: Dictionary = mission.call("get_runtime_debug_summary") as Dictionary

	assert_bool(mission.call("_is_runtime_flag_true", "alarm_triggered:AMBUSH_security_beam")).is_false()
	assert_bool(bool(state.get("louis_route_beam_bypass_used", false))).is_true()
	assert_int(int(state.get("louis_route_beam_bypass_count", 0))).is_equal(1)
	assert_bool(bool(summary.get("garage_beam_bypassed", false))).is_true()
	assert_bool(bool(summary.get("garage_beam_armed", true))).is_false()

	_free_node(mission)
	await get_tree().process_frame
	_restore_game_state(game_snapshot)


func test_d5_beam_still_trips_without_louis_route() -> void:
	var game_snapshot := _snapshot_game_state()
	var mission: Node = IsoMissionBaseScript.new()
	mission.name = "D503MainBeamMission"
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	GameState.selected_cards.erase("louis_delivery_route")
	GameState.unlocked_scheme_cards.erase("louis_delivery_route")
	GameState.unlocked_cards.erase("louis_delivery_route")
	var area := Area2D.new()
	area.name = "AlarmZone_AMBUSH_security_beam"
	mission.add_child(area)
	var player := Node2D.new()
	player.name = "Player"
	player.add_to_group("player")
	mission.add_child(player)

	mission.call("_on_runtime_alarm_zone_entered", player, "AMBUSH_security_beam", area)
	var state: Dictionary = mission.get("_attempt_runtime_state") as Dictionary

	assert_bool(mission.call("_is_runtime_flag_true", "alarm_triggered:AMBUSH_security_beam")).is_true()
	assert_bool(bool(state.get("louis_route_beam_bypass_used", false))).is_false()

	_free_node(mission)
	await get_tree().process_frame
	_restore_game_state(game_snapshot)


func _snapshot_quest_manager() -> Dictionary:
	return {
		"active_quest_id": QuestManager.active_quest_id,
		"active_objective": QuestManager.active_objective,
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"selected_cards": GameState.selected_cards.duplicate(true),
		"unlocked_cards": GameState.unlocked_cards.duplicate(true),
		"unlocked_scheme_cards": GameState.unlocked_scheme_cards.duplicate(true),
		"current_scheme_loadout": GameState.current_scheme_loadout.duplicate(true),
	}


func _restore_quest_manager(snapshot: Dictionary) -> void:
	QuestManager.active_quest_id = String(snapshot.get("active_quest_id", ""))
	QuestManager.active_objective = String(snapshot.get("active_objective", ""))
	QuestManager.objectives = (snapshot.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("completed_objectives", {}) as Dictionary).duplicate(true)


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.selected_cards = _string_array(snapshot.get("selected_cards", []))
	GameState.unlocked_cards = _string_array(snapshot.get("unlocked_cards", []))
	GameState.unlocked_scheme_cards = (snapshot.get("unlocked_scheme_cards", {}) as Dictionary).duplicate(true)
	GameState.current_scheme_loadout = (snapshot.get("current_scheme_loadout", {}) as Dictionary).duplicate(true)


func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _label_text(node: Node) -> String:
	for child in node.get_children():
		if child is Label:
			return (child as Label).text
	return ""
