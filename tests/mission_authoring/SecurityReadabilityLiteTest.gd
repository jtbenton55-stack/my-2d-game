# GdUnit4 tests for Phase 4E-4G-lite security readability helpers.
extends GdUnitTestSuite

const MissionSecurityCameraScript := preload("res://src/missions/iso/runtime/MissionSecurityCamera.gd")
const SecurityCameraAuthorScript := preload("res://src/missions/iso/authoring/SecurityCameraAuthor.gd")
const HideSpotNodeScript := preload("res://src/missions/iso/authoring/mechanics/HideSpotNode.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const MissionQAChecklistPanelScript := preload("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")


func test_camera_sweep_debug_state_is_predictable() -> void:
	var camera := MissionSecurityCameraScript.new()
	camera.name = "CameraUnderTest"
	add_child(camera)
	camera.apply_authoring_config({
		"camera_id": "phase4e_camera",
		"sweep_enabled": true,
		"sweep_arc_degrees": 60.0,
		"sweep_speed_degrees": 30.0,
		"sweep_readability_label": "Phase 4E Camera",
	})
	var sweep: Dictionary = camera.get_sweep_debug_state()

	assert_bool(sweep.get("enabled", false)).is_true()
	assert_float(float(sweep.get("span_degrees", 0.0))).is_equal(60.0)
	assert_bool(float(sweep.get("loop_seconds", 0.0)) > 0.0).is_true()
	assert_str(camera.get_sweep_readability_line()).contains("Phase 4E Camera")

	_free_node(camera)


func test_camera_author_exports_readability_config() -> void:
	var author := SecurityCameraAuthorScript.new()
	author.camera_id = &"phase4e_author_camera"
	author.sweep_enabled = true
	author.sweep_arc_degrees = 75.0
	author.sweep_speed_degrees = 25.0
	author.sweep_readability_label = "Author Camera Loop"
	var cfg: Dictionary = author.build_runtime_config()

	assert_str(String(cfg.get("sweep_readability_label", ""))).is_equal("Author Camera Loop")
	assert_str(author.get_camera_readability_summary()).contains("sweeps")

	author.free()


func test_hide_spot_reduces_and_resets_detection_modifier() -> void:
	var controller := MissionAlertControllerScript.new()
	controller.name = "MissionAlertController"
	controller.add_to_group("iso_alert_controller")
	add_child(controller)
	controller.alert_score = 0.8

	var hide := HideSpotNodeScript.new()
	hide.name = "HideSpotUnderTest"
	hide.mechanic_id = &"phase4f_hide_spot"
	hide.hidden_detection_modifier = 0.25
	hide.exposure_decay_on_enter = 0.3
	add_child(hide)

	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	var entered: Dictionary = hide.enter_hide(player)
	assert_bool(entered.get("ok", false)).is_true()
	assert_bool(hide.is_actor_hidden(player)).is_true()
	assert_float(controller.player_detection_modifier).is_equal(0.25)
	assert_bool(controller.alert_score < 0.8).is_true()

	var exited: Dictionary = hide.exit_hide(player)
	assert_bool(exited.get("ok", false)).is_true()
	assert_bool(hide.is_actor_hidden(player)).is_false()
	assert_float(controller.player_detection_modifier).is_equal(1.0)

	_free_node(player)
	_free_node(hide)
	_free_node(controller)


func test_taco_phase4g_camera_alarm_effect_set_slice_exists() -> void:
	var text := FileAccess.get_file_as_string("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")
	assert_str(text).contains("Phase4G_CameraAlarmEffectSet_Author")
	assert_str(text).contains("phase4g_camera_alarm_seen")
	assert_str(text).contains("test_camera_alarm")


func test_phase4g_qa_model_reports_waiting_before_alarm() -> void:
	var model: Dictionary = MissionQAChecklistPanelScript.build_phase4g_model({}, {})
	var rendered := MissionQAChecklistPanelScript.render_phase4g_model(model)

	assert_str(String(model.get("next_action", ""))).contains("SecurityAuthoringRoot")
	assert_str(rendered).contains("[WAIT] Runtime camera spawned")
	assert_str(rendered).contains("[WAIT] Phase 4G mission flag set")
	assert_str(rendered).contains("Flag set: no")


func test_phase4g_qa_model_reports_passed_alarm_chain() -> void:
	var rsum := {
		"d6_02_security_authoring_root_found": true,
		"d6_04_runtime_authored_camera_count": 1,
		"d6_03_security_router_active": true,
		"d6_03_router_listener_counts": {"test_camera_alarm": 2},
		"d6_04_authored_camera_player_in_cone": true,
		"d6_04_authored_camera_detection_value": 1.0,
		"d6_04_last_camera_id": "test_camera_01",
		"d6_04_last_camera_alarm_event": "test_camera_alarm",
		"d6_03_last_dispatched_event": "test_camera_alarm",
		"d6_04_last_camera_alarm_handled": true,
		"d6_04_last_event_handled": true,
		"d6_04_last_event_listeners_called": 2,
		"d6_04_last_event_listeners_handled": 2,
		"d6_03_last_guard_spawn_result": "spawned",
		"d6_03_last_spawned_guard_count": 1,
		"d6_05_last_effect_set_id": "effectset_phase4g_camera_alarm_seen",
		"d6_05_last_effect_set_applied_count": 1,
		"d6_05_last_effect_set_failed_count": 0,
	}
	var flags := {"mission_flag:taco_bell_drop:phase4g_camera_alarm_seen": true}
	var model: Dictionary = MissionQAChecklistPanelScript.build_phase4g_model(rsum, flags)
	var rendered := MissionQAChecklistPanelScript.render_phase4g_model(model)

	assert_str(String(model.get("next_action", ""))).contains("All Phase 4G")
	assert_int(_count_status(model, "PASS")).is_equal(10)
	assert_str(rendered).contains("EffectSet: effectset_phase4g_camera_alarm_seen applied 1 failed 0")
	assert_str(rendered).contains("Flag set: yes")


func test_qa_review_hotkey_avoids_godot_editor_stop_key() -> void:
	var debug_panel_text := FileAccess.get_file_as_string("res://src/missions/iso/runtime/IsoMissionDebugPanel.gd")
	var qa_panel_text := FileAccess.get_file_as_string("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")

	assert_str(debug_panel_text).contains("QA_PANEL_TOGGLE_KEY := KEY_F12")
	assert_bool(debug_panel_text.contains("KEY_F8")).is_false()
	assert_str(qa_panel_text).contains("Mission QA Review (F12)")
	assert_bool(qa_panel_text.contains("Mission QA Review (F8)")).is_false()


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame


func _count_status(model: Dictionary, status: String) -> int:
	var count := 0
	for check in (model.get("checks", []) as Array):
		if String(check.get("status", "")) == status:
			count += 1
	return count
