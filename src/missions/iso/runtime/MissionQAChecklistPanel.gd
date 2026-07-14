class_name MissionQAChecklistPanel
extends Panel

const MODE_OVERVIEW := 0
const MODE_PHASE4E := 1
const MODE_PHASE4G := 2
const MODE_PHASE4F := 3
const MODE_TACO_SECURITY := 4
const MODE_D5_01 := 5
const MODE_D5_02 := 6
const MODE_D5_03 := 7
const MODE_PHASE17 := 8
const MODE_VELVET_SECURITY := 9

const PHASE4G_MISSION_ID := "taco_bell_drop"
const PHASE4G_FLAG_ID := "phase4g_camera_alarm_seen"
const PHASE4G_FLAG_KEY := "mission_flag:taco_bell_drop:phase4g_camera_alarm_seen"
const PHASE4G_CAMERA_AUTHOR_PATH := "GameplayRoot/SecurityAuthoringRoot/TestCamera_Author"
const PHASE4G_RUNTIME_CAMERA_PATH := "EntityRoot/Cameras/AuthoredCamera_test_camera_01"
const PHASE4G_EFFECT_AUTHOR_PATH := "GameplayRoot/SecurityAuthoringRoot/Phase4G_CameraAlarmEffectSet_Author"
const PHASE4G_CAMERA_TEST_POSITION := Vector2(8500.0, 135.0)
const VELVET_PAW_MISSION_ID := "velvet_paw_jazz_club"
const VELVET_PAW_VIP_COVER_ID := "velvet_paw_vip_guest"
const VELVET_PAW_VIP_CREDENTIAL_ID := "velvet_paw_vip_wristband"
const VIP_ACCESS_NORMAL := 0
const VIP_ACCESS_GUEST := 1

var _mission: Node = null
var _selector: OptionButton = null
var _vip_access_selector: OptionButton = null
var _map_overlay_toggle: CheckButton = null
var _body: RichTextLabel = null
var _actions_box: GridContainer = null
var _action_buttons: Array[Button] = []
var _last_action_label: Label = null
var _mode := MODE_OVERVIEW
var _vip_access_synced_mission_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process(true)
	visible = false


func set_mission(mission: Node) -> void:
	_mission = mission
	_sync_vip_access_selector(true)
	_sync_map_overlay_toggle()


func toggle_panel() -> void:
	visible = not visible
	if visible:
		_sync_vip_access_selector(true)
		_refresh()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	name = "MissionQAReviewPanel"
	position = Vector2(364.0, 18.0)
	size = Vector2(520.0, 520.0)
	_apply_panel_style()

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(12.0, 8.0)
	title.size = Vector2(496.0, 24.0)
	title.text = "Mission QA Review (F12)"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	_selector = OptionButton.new()
	_selector.name = "ChecklistSelector"
	_selector.position = Vector2(12.0, 38.0)
	_selector.size = Vector2(300.0, 30.0)
	_selector.add_item("Overview", MODE_OVERVIEW)
	_selector.add_item("Phase 4E - Camera Readability", MODE_PHASE4E)
	_selector.add_item("Phase 4G - Camera Alarm EffectSet", MODE_PHASE4G)
	_selector.add_item("Phase 4F - Hide Spot", MODE_PHASE4F)
	_selector.add_item("Taco Security Regression", MODE_TACO_SECURITY)
	_selector.add_item("D5-01 - Attempt Reset", MODE_D5_01)
	_selector.add_item("D5-02 - Pause Context", MODE_D5_02)
	_selector.add_item("D5-03 - Louis Beam Bypass", MODE_D5_03)
	_selector.add_item("Phase 17 - Garage Routes", MODE_PHASE17)
	_selector.add_item("Velvet Paw - Security/Fight", MODE_VELVET_SECURITY)
	_selector.item_selected.connect(_on_mode_selected)
	add_child(_selector)

	_vip_access_selector = OptionButton.new()
	_vip_access_selector.name = "VelvetVipAccessSelector"
	_vip_access_selector.position = Vector2(320.0, 38.0)
	_vip_access_selector.size = Vector2(188.0, 30.0)
	_vip_access_selector.add_item("Normal access", VIP_ACCESS_NORMAL)
	_vip_access_selector.add_item("VIP guest + wristband", VIP_ACCESS_GUEST)
	_vip_access_selector.item_selected.connect(_on_vip_access_selected)
	add_child(_vip_access_selector)
	_sync_vip_access_selector(true)

	_map_overlay_toggle = CheckButton.new()
	_map_overlay_toggle.name = "VelvetRedMapOverlayToggle"
	_map_overlay_toggle.position = Vector2(320.0, 6.0)
	_map_overlay_toggle.size = Vector2(188.0, 28.0)
	_map_overlay_toggle.text = "Red Map Overlay"
	_map_overlay_toggle.tooltip_text = "Outline and label walls, barriers, cover, interactables, zones, guards, cameras, and actors."
	_map_overlay_toggle.toggled.connect(_on_map_overlay_toggled)
	add_child(_map_overlay_toggle)
	_sync_map_overlay_toggle()

	_actions_box = GridContainer.new()
	_actions_box.name = "ActionButtons"
	_actions_box.position = Vector2(12.0, 72.0)
	_actions_box.size = Vector2(496.0, 66.0)
	_actions_box.columns = 3
	_actions_box.add_theme_constant_override("h_separation", 6)
	_actions_box.add_theme_constant_override("v_separation", 4)
	add_child(_actions_box)

	_last_action_label = Label.new()
	_last_action_label.name = "LastAction"
	_last_action_label.position = Vector2(12.0, 142.0)
	_last_action_label.size = Vector2(496.0, 22.0)
	_last_action_label.text = "F12 dashboard: select a checklist, then use the nearby action buttons."
	_last_action_label.add_theme_font_size_override("font_size", 11)
	add_child(_last_action_label)

	_body = RichTextLabel.new()
	_body.name = "ChecklistBody"
	_body.position = Vector2(12.0, 168.0)
	_body.size = Vector2(496.0, 340.0)
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.add_theme_font_size_override("normal_font_size", 12)
	add_child(_body)
	_rebuild_action_buttons()


func _on_mode_selected(index: int) -> void:
	_mode = _selector.get_item_id(index)
	_rebuild_action_buttons()
	_refresh()


func _on_vip_access_selected(index: int) -> void:
	if _current_mission_id() != VELVET_PAW_MISSION_ID:
		return
	var context := {"mission_id": VELVET_PAW_MISSION_ID, "source_id": "f12_qa_vip_access"}
	if _vip_access_selector.get_item_id(index) == VIP_ACCESS_GUEST:
		SocialStealthAdapter.set_cover_story(VELVET_PAW_VIP_COVER_ID, {"source": "f12_qa"}, context)
		SocialStealthAdapter.grant_credential(VELVET_PAW_VIP_CREDENTIAL_ID, {"source": "f12_qa"}, context)
		_set_last_action("Applied Velvet Paw VIP guest cover and wristband.")
	else:
		SocialStealthAdapter.clear_cover_story(VELVET_PAW_VIP_COVER_ID, context)
		SocialStealthAdapter.revoke_credential(VELVET_PAW_VIP_CREDENTIAL_ID, context)
		_set_last_action("Removed Velvet Paw VIP guest cover and wristband.")


func _sync_vip_access_selector(force: bool = false) -> void:
	if _vip_access_selector == null:
		return
	var mission_id := _current_mission_id()
	_vip_access_selector.visible = mission_id == VELVET_PAW_MISSION_ID
	if not _vip_access_selector.visible:
		_vip_access_synced_mission_id = ""
		return
	if not force and _vip_access_synced_mission_id == mission_id:
		return
	var context := {"mission_id": mission_id}
	var has_cover := bool(SocialStealthAdapter.get_fact_value(SocialStealthAdapter.FACT_COVER_STORY_ACTIVE, VELVET_PAW_VIP_COVER_ID, context))
	var has_credential := bool(SocialStealthAdapter.get_fact_value(SocialStealthAdapter.FACT_CREDENTIAL_ACTIVE, VELVET_PAW_VIP_CREDENTIAL_ID, context))
	_vip_access_selector.select(_vip_access_selector.get_item_index(VIP_ACCESS_GUEST if has_cover and has_credential else VIP_ACCESS_NORMAL))
	_vip_access_synced_mission_id = mission_id


func _on_map_overlay_toggled(enabled: bool) -> void:
	var overlay := _find_velvet_map_overlay()
	if overlay == null:
		_set_last_action("Velvet red map overlay is unavailable.")
		return
	overlay.call("set_overlay_enabled", enabled)
	_set_last_action("Red map overlay %s." % ["enabled" if enabled else "disabled"])


func _sync_map_overlay_toggle() -> void:
	if _map_overlay_toggle == null:
		return
	_map_overlay_toggle.visible = _current_mission_id() == VELVET_PAW_MISSION_ID
	if not _map_overlay_toggle.visible:
		return
	var overlay := _find_velvet_map_overlay()
	var enabled := overlay != null and bool(overlay.call("is_overlay_enabled"))
	_map_overlay_toggle.set_pressed_no_signal(enabled)


func _find_velvet_map_overlay() -> Node:
	if _mission == null:
		return null
	return _mission.get_node_or_null("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController/CollisionDebugOverlay")


func _rebuild_action_buttons() -> void:
	if _actions_box == null:
		return
	for button in _action_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_action_buttons.clear()
	for action in _actions_for_mode():
		var button := Button.new()
		button.custom_minimum_size = Vector2(154.0, 28.0)
		button.text = String(action.get("label", "Action"))
		button.tooltip_text = String(action.get("hint", ""))
		button.pressed.connect(_on_action_pressed.bind(action))
		_actions_box.add_child(button)
		_action_buttons.append(button)
	_actions_box.visible = not _action_buttons.is_empty()


func _actions_for_mode() -> Array[Dictionary]:
	match _mode:
		MODE_PHASE4G:
			return [
				{"label": "Go Camera", "kind": "teleport_position", "position": PHASE4G_CAMERA_TEST_POSITION, "hint": "Teleport to the authored camera alarm test."},
				{"label": "Reset Flag", "kind": "reset_phase4g_flag", "hint": "Clear the Phase 4G camera alarm mission flag."},
			]
		MODE_D5_01:
			return [
				{"label": "Go Code Gate", "kind": "teleport_marker", "marker_id": "code_gate_garage_office", "hint": "Jump to the actual garage code gate scene marker."},
				{"label": "Go Bag", "kind": "teleport_marker", "marker_id": "objective_retrieve_delivery_bag", "hint": "Jump to the actual delivery bag objective marker."},
				{"label": "Go Exit", "kind": "teleport_marker", "marker_id": "objective_escape_and_return_to_louis", "hint": "Jump to the actual Louis return objective marker."},
				{"label": "Reset Attempt", "kind": "reset_attempt", "hint": "Call the D5-01 attempt reset hook without reloading the scene."},
				{"label": "Restart Scene", "kind": "restart_mission", "hint": "Restart Taco through the canonical mission start path."},
			]
		MODE_D5_02:
			return [
				{"label": "Go Start", "kind": "teleport_marker", "marker_id": "player_spawn_main", "hint": "Jump to the actual player start marker before checking pause context."},
				{"label": "Go Code Gate", "kind": "teleport_marker", "marker_id": "code_gate_garage_office", "hint": "Jump to a real objective, then open pause."},
				{"label": "Go Bag", "kind": "teleport_marker", "marker_id": "objective_retrieve_delivery_bag", "hint": "Jump to delivery bag recovery before checking pause."},
			]
		MODE_D5_03:
			return [
				{"label": "Go Main Beam", "kind": "teleport_node", "node_path": "GameplayRoot/RuntimeSystems/AlarmZones/AlarmZone_garage_entry_beam", "fallback_node_path": "GameplayRoot/SecurityAuthoringRoot/AMBUSH_security_beam", "offset": Vector2(-96.0, 0.0), "hint": "Jump just before the actual garage beam runtime node."},
				{"label": "Go Louis Route", "kind": "teleport_marker", "marker_id": "spawn_route_louis_entry", "hint": "Jump to the actual Louis route entry marker."},
				{"label": "Grant Louis Card", "kind": "grant_louis_route", "hint": "Unlock/select Louis Delivery Route for QA."},
				{"label": "Remove Louis Card", "kind": "remove_louis_route", "hint": "Remove the Louis route card from active state."},
				{"label": "Reset Attempt", "kind": "reset_attempt", "hint": "Reset the attempt before retesting beam behavior."},
			]
		MODE_PHASE17:
			return [
				{"label": "Clean Social", "kind": "phase16_route", "method": "run_clean_social_route", "hint": "QA-only: call the Phase 16 clean social route."},
				{"label": "Bentley", "kind": "phase16_route", "method": "run_bentley_distraction_route", "hint": "QA-only: call the Phase 16 Bentley distraction route."},
				{"label": "Evidence", "kind": "phase16_route", "method": "run_evidence_route", "hint": "QA-only: call the Phase 16 evidence route."},
				{"label": "Messy", "kind": "phase16_route", "method": "run_messy_authority_route", "hint": "QA-only: call the Phase 16 messy authority route."},
				{"label": "Cleanup", "kind": "phase16_route", "method": "run_cleanup_redirect_trace", "hint": "QA-only: call the Phase 16 cleanup/redirect route."},
			]
		MODE_TACO_SECURITY:
			return [
				{"label": "Go Camera", "kind": "teleport_position", "position": PHASE4G_CAMERA_TEST_POSITION, "hint": "Jump to authored camera test."},
				{"label": "Trigger Alarm", "kind": "trigger_alarm", "hint": "Call the mission debug alarm hook."},
				{"label": "Spawn Guard", "kind": "spawn_guard", "hint": "Call the mission debug guard spawn hook."},
			]
		MODE_VELVET_SECURITY:
			return [
				{"label": "Increase Heat", "kind": "velvet_increase_heat", "hint": "Raise Velvet Paw heat by one and refresh the live camera posture."},
				{"label": "Suspicion", "kind": "velvet_suspicion", "hint": "Trigger a non-alarm suspicious state."},
				{"label": "Alert", "kind": "velvet_alert", "hint": "Trigger a real alert event and downstream response."},
				{"label": "Resolve", "kind": "velvet_resolve", "hint": "Clear exposure and enter the resolved state."},
				{"label": "Hostile/Fight", "kind": "velvet_hostile", "hint": "Make the club and all existing guards hostile."},
			]
	return []


func _on_action_pressed(action: Dictionary) -> void:
	var kind := String(action.get("kind", ""))
	match kind:
		"teleport_spawn":
			_teleport_to_spawn(String(action.get("spawn_id", "")))
		"teleport_marker":
			_teleport_to_marker(String(action.get("marker_id", "")), _action_offset(action))
		"teleport_node":
			_teleport_to_node_path(String(action.get("node_path", "")), String(action.get("fallback_node_path", "")), _action_offset(action))
		"teleport_position":
			_teleport_to_position(action.get("position", Vector2.ZERO))
		"reset_phase4g_flag":
			GameState.dialogue_flags.erase(PHASE4G_FLAG_KEY)
			_set_last_action("Reset %s." % PHASE4G_FLAG_KEY)
		"reset_attempt":
			_reset_current_attempt_runtime()
		"restart_mission":
			_restart_current_mission()
		"grant_louis_route":
			GameState.unlock_scheme_card("louis_delivery_route", {"source": "qa_dashboard"})
			_set_last_action("Granted Louis Delivery Route for QA.")
		"remove_louis_route":
			GameState.unlocked_scheme_cards.erase("louis_delivery_route")
			GameState.unlocked_cards.erase("louis_delivery_route")
			_set_last_action("Removed Louis Delivery Route from active QA state.")
		"trigger_alarm":
			if _mission != null and _mission.has_method("trigger_alarm_test"):
				_mission.call("trigger_alarm_test")
				_set_last_action("Triggered mission debug alarm.")
			else:
				_set_last_action("Alarm test unavailable on this mission.")
		"spawn_guard":
			if _mission != null and _mission.has_method("spawn_extra_guard_test"):
				_mission.call("spawn_extra_guard_test")
				_set_last_action("Spawned extra debug guard.")
			else:
				_set_last_action("Guard spawn test unavailable on this mission.")
		"phase16_route":
			_run_phase16_route(String(action.get("method", "")))
		"velvet_increase_heat":
			_velvet_increase_heat()
		"velvet_suspicion":
			_velvet_trigger_suspicion()
		"velvet_alert":
			_velvet_trigger_alert()
		"velvet_resolve":
			_velvet_resolve_alert()
		"velvet_hostile":
			_velvet_trigger_hostile()
		_:
			_set_last_action("Unknown QA action: %s" % kind)
	_refresh()


func _refresh() -> void:
	if _body == null:
		return
	_sync_vip_access_selector()
	_sync_map_overlay_toggle()
	var rsum := _get_runtime_summary()
	var flags := _get_dialogue_flags()
	match _mode:
		MODE_PHASE4E:
			_body.text = _render_phase4e(rsum)
		MODE_PHASE4G:
			_body.text = render_phase4g_model(build_phase4g_model(rsum, flags))
		MODE_PHASE4F:
			_body.text = _render_phase4f()
		MODE_TACO_SECURITY:
			_body.text = _render_taco_security(rsum)
		MODE_D5_01:
			_body.text = _render_d5_01(rsum)
		MODE_D5_02:
			_body.text = _render_d5_02(rsum)
		MODE_D5_03:
			_body.text = _render_d5_03(rsum)
		MODE_PHASE17:
			_body.text = _render_phase17()
		MODE_VELVET_SECURITY:
			_body.text = _render_velvet_security()
		_:
			_body.text = _render_overview(rsum, flags)


func _get_runtime_summary() -> Dictionary:
	if _mission != null and is_instance_valid(_mission) and _mission.has_method("get_runtime_debug_summary"):
		var data: Variant = _mission.call("get_runtime_debug_summary")
		if data is Dictionary:
			return data as Dictionary
	return {}


func _get_dialogue_flags() -> Dictionary:
	return GameState.dialogue_flags.duplicate(true)


func _current_mission_id() -> String:
	if _mission != null and is_instance_valid(_mission) and _mission.has_method("get_mission_id"):
		var mid := String(_mission.call("get_mission_id"))
		if mid != "":
			return mid
	return String(GameState.current_mission_id)


func _velvet_alert_controller() -> Node:
	if _mission == null or not is_instance_valid(_mission):
		return null
	return _mission.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionAlertController")


func _velvet_mission_controller() -> Node:
	if _mission == null or not is_instance_valid(_mission):
		return null
	return _mission.get_node_or_null("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")


func _velvet_increase_heat() -> void:
	if _current_mission_id() != VELVET_PAW_MISSION_ID:
		_set_last_action("Velvet Paw heat controls are unavailable in this mission.")
		return
	var heat := GameState.increase_venue_heat(VELVET_PAW_MISSION_ID, 1)
	var alert := _velvet_alert_controller()
	if alert != null and alert.has_method("configure_camera_detection_policy"):
		alert.call("configure_camera_detection_policy", true, heat)
	_set_last_action("Velvet Paw heat increased to %d/5; live camera posture refreshed." % heat)


func _velvet_trigger_suspicion() -> void:
	var alert := _velvet_alert_controller()
	if _current_mission_id() != VELVET_PAW_MISSION_ID or alert == null:
		_set_last_action("Velvet Paw alert controller is unavailable.")
		return
	alert.call("resolve_alert")
	alert.call("set_alert_state", "normal")
	alert.call("register_detection_event", "f12_qa_suspicion", 0.35, "qa_suspicion")
	_set_last_action("Triggered suspicion without committing an alarm.")


func _velvet_trigger_alert() -> void:
	var alert := _velvet_alert_controller()
	if _current_mission_id() != VELVET_PAW_MISSION_ID or alert == null:
		_set_last_action("Velvet Paw alert controller is unavailable.")
		return
	alert.call("register_detection_event", "f12_qa_alert", 1.0, "camera_detected")
	_set_last_action("Triggered an alerted security event with downstream response.")


func _velvet_resolve_alert() -> void:
	var alert := _velvet_alert_controller()
	if _current_mission_id() != VELVET_PAW_MISSION_ID or alert == null:
		_set_last_action("Velvet Paw alert controller is unavailable.")
		return
	alert.call("resolve_alert")
	_set_last_action("Cleared exposure and resolved the alert.")


func _velvet_trigger_hostile() -> void:
	var controller := _velvet_mission_controller()
	if _current_mission_id() != VELVET_PAW_MISSION_ID or controller == null:
		_set_last_action("Velvet Paw mission controller is unavailable.")
		return
	controller.call("trigger_hostile_state", "f12_qa")
	_set_last_action("Triggered the club-wide hostile/fight state.")


func _render_velvet_security() -> String:
	if _current_mission_id() != VELVET_PAW_MISSION_ID:
		return "[b]Velvet Paw Security/Fight[/b]\nLaunch Velvet Paw to use these controls."
	var alert := _velvet_alert_controller()
	var state := String(alert.get("alert_state")) if alert != null else "unavailable"
	var score := float(alert.get("alert_score")) if alert != null else 0.0
	var audio: Dictionary = AudioManager.get_music_debug_state()
	return "[b]Velvet Paw Security/Fight[/b]\nHeat: %d/5\nAlert: %s (exposure %.2f)\nHostile/fight: %s\nMusic: %s playing=%s at %.1fs\nMusic bus: %.1f dB muted=%s | Master: %.1f dB muted=%s\n\nIncrease Heat refreshes the current camera posture immediately. Suspicion is temporary and does not commit an alarm. Alert runs real alarm routing. Resolve clears exposure. Hostile/Fight makes all current guards hostile and stops house music." % [GameState.get_mission_heat(VELVET_PAW_MISSION_ID), state, score, "yes" if GameState.velvet_paw_club_hostile else "no", String(audio.get("current_music", "none")), str(audio.get("playing", false)), float(audio.get("playback_position", 0.0)), float(audio.get("music_bus_volume_db", -80.0)), str(audio.get("music_bus_muted", true)), float(audio.get("master_bus_volume_db", -80.0)), str(audio.get("master_bus_muted", true))]


func _get_phase0k_controller() -> Node:
	if _mission == null or not is_instance_valid(_mission):
		return null
	return _mission.get_node_or_null("GameplayRoot/RuntimeHelpers/Phase0KMissionCompletionController")


func _controller_bool(controller: Node, property_name: String) -> bool:
	if controller == null:
		return false
	var value = controller.get(property_name)
	return bool(value) if value != null else false


func _objective_exists(objective_id: String, mission_id: String) -> bool:
	return QuestManager.has_objective(objective_id, mission_id)


func _objective_completed(objective_id: String, mission_id: String) -> bool:
	return QuestManager.is_objective_completed(objective_id, mission_id)


func _render_d5_01(rsum: Dictionary) -> String:
	var mid := _current_mission_id()
	var phase0k := _get_phase0k_controller()
	var bag_done := _controller_bool(phase0k, "delivery_bag_collected") or _objective_completed("recover_delivery_bag", mid)
	var gate_open := _controller_bool(phase0k, "code_gate_unlocked") or _objective_completed("open_garage_code_gate", mid)
	var exit_ready := _controller_bool(phase0k, "exit_unlocked")
	var beam_armed := bool(rsum.get("garage_beam_armed", true))
	var beam_triggered := bool(rsum.get("garage_beam_triggered", false))
	var reset_meta := _mission != null and _mission.has_meta("d5_01_attempt_reset")
	var seeded := _objective_exists("open_garage_code_gate", mid) and _objective_exists("recover_delivery_bag", mid) and _objective_exists("return_to_louis", mid)
	var active := QuestManager.get_active_objectives(mid)
	var completed := QuestManager.get_completed_objectives(mid)
	var lines: Array[String] = []
	lines.append(_title_bb("D5-01 Attempt Reset"))
	lines.append("Goal: prove a restart/retry clears stale Taco objective + Phase0K state.")
	lines.append("")
	lines.append(_bb_status_line("Mission context", "PASS" if mid == PHASE4G_MISSION_ID else "FAIL", mid))
	lines.append(_bb_status_line("Phase0K controller", "PASS" if phase0k != null else "FAIL", _node_path_or_dash(phase0k)))
	lines.append(_bb_status_line("Initial objective rows", "PASS" if seeded else "WAIT", "open gate / recover bag / return to Louis"))
	lines.append(_bb_status_line("Bag objective", "DONE" if bag_done else "WAIT", "recover_delivery_bag"))
	lines.append(_bb_status_line("Code gate", "OPEN" if gate_open else "LOCKED", "open_garage_code_gate"))
	lines.append(_bb_status_line("Louis exit", "READY" if exit_ready else "LOCKED", "return_to_louis"))
	lines.append(_bb_status_line("Garage beam", "TRIPPED" if beam_triggered else ("READY" if beam_armed else "WAIT"), "should be READY after a fresh attempt"))
	lines.append(_bb_status_line("D5 reset hook ran", "PASS" if reset_meta else "WAIT", "press Reset Attempt or Restart Scene"))
	lines.append("")
	lines.append(_section_bb("Live Objective Lists"))
	lines.append("Active: %s" % _join_or_dash(active))
	lines.append("Completed: %s" % _join_or_dash(completed))
	lines.append("")
	lines.append(_section_bb("Next Action"))
	if not seeded:
		lines.append("Press Reset Attempt or Restart Scene. The three Taco objective rows should appear.")
	elif reset_meta and not bag_done and not gate_open and beam_armed:
		lines.append("D5-01 looks reset-clean. Repeat once more or move on to D5-02/D5-03 testing.")
	elif not bag_done and not gate_open:
		lines.append("Use Go Code Gate or Go Bag, progress one objective, then restart and watch it return to WAIT/LOCKED.")
	else:
		lines.append("Press Reset Attempt or Restart Scene. Bag/Gate should clear and Beam should show READY.")
	return "\n".join(lines)


func _render_d5_02(_rsum: Dictionary) -> String:
	var mid := _current_mission_id()
	var payload := MissionPauseDataProvider.get_pause_payload(mid, _mission)
	var payload_mid := String(payload.get("mission_id", ""))
	var objectives := payload.get("objectives", []) as Array
	var attempt_context := payload.get("attempt_context", []) as Array
	var warnings := payload.get("warnings", []) as Array
	var heat_line := String(payload.get("heat_security_line", ""))
	var lines: Array[String] = []
	lines.append(_title_bb("D5-02 Pause Context"))
	lines.append("Goal: pause/objective tabs should describe this Taco attempt, not stale or empty mission state.")
	lines.append("")
	lines.append(_bb_status_line("Current mission id", "PASS" if mid == PHASE4G_MISSION_ID else "FAIL", mid))
	lines.append(_bb_status_line("Pause payload id", "PASS" if payload_mid == PHASE4G_MISSION_ID else "FAIL", payload_mid))
	lines.append(_bb_status_line("Pause objective rows", "PASS" if objectives.size() > 0 else "WAIT", "%d rows" % objectives.size()))
	lines.append(_bb_status_line("Attempt context rows", "PASS" if attempt_context.size() > 0 else "WAIT", "%d rows" % attempt_context.size()))
	lines.append(_bb_status_line("Pause warnings", "PASS" if warnings.is_empty() else "WARN", _join_or_dash(warnings)))
	lines.append(_bb_status_line("Heat line", "PASS" if heat_line != "" else "WAIT", heat_line))
	lines.append("")
	lines.append(_section_bb("Next Action"))
	lines.append("Press Esc and compare the pause Objectives tab to these rows. Use Go Code Gate or Go Bag to change state, then check pause again.")
	return "\n".join(lines)


func _render_d5_03(rsum: Dictionary) -> String:
	var mid := _current_mission_id()
	var route_active := bool(rsum.get("louis_route_beam_bypass_active", false)) or GameState.has_scheme_card("louis_delivery_route") or GameState.has_selected_card("louis_delivery_route")
	var beam_armed := bool(rsum.get("garage_beam_armed", true))
	var beam_triggered := bool(rsum.get("garage_beam_triggered", false))
	var beam_bypassed := bool(rsum.get("garage_beam_bypassed", false))
	var lines: Array[String] = []
	lines.append(_title_bb("D5-03 Louis Beam Bypass"))
	lines.append("Goal: main path trips the garage beam; Louis route bypasses or neutralizes it.")
	lines.append("")
	lines.append(_bb_status_line("Mission context", "PASS" if mid == PHASE4G_MISSION_ID else "FAIL", mid))
	lines.append(_bb_status_line("Louis route card", "READY" if route_active else "WAIT", "Grant/Remove buttons are QA-only"))
	lines.append(_bb_status_line("Garage beam", "USED" if beam_bypassed else ("TRIPPED" if beam_triggered else ("READY" if beam_armed else "WAIT")), "main path should still trip once without Louis route"))
	lines.append(_bb_status_line("Bypass outcome", "PASS" if beam_bypassed else ("READY" if route_active else "WAIT"), "cross beam with Louis route active"))
	lines.append("")
	lines.append(_section_bb("How To Use"))
	lines.append("1. Press Reset Attempt, then Go Main Beam and verify Beam changes READY -> TRIPPED.")
	lines.append("2. Press Reset Attempt, Grant Louis Card, then Go Louis Route.")
	lines.append("3. Cross the beam with Louis route active and confirm Bypass outcome shows PASS/USED with no new guard wave.")
	return "\n".join(lines)


func _render_phase17() -> String:
	var trigger := _get_phase16_trigger()
	var summary: Dictionary = {}
	if trigger != null and trigger.has_method("get_phase16_summary"):
		summary = trigger.call("get_phase16_summary") as Dictionary
	var route_log: Array = summary.get("route_log", []) as Array
	var last_route := String(summary.get("last_route_label", summary.get("last_route_id", "")))
	var lines: Array[String] = []
	lines.append(_title_bb("Phase 17 Garage Routes"))
	lines.append("Goal: safely activate the Phase 16 Taco garage-manager routes through QA/debug controls only.")
	lines.append("")
	lines.append(_bb_status_line("Mission context", "PASS" if _current_mission_id() == PHASE4G_MISSION_ID else "FAIL", _current_mission_id()))
	lines.append(_bb_status_line("Dev trigger", "PASS" if trigger != null else "FAIL", _node_path_or_dash(trigger)))
	lines.append(_bb_status_line("Last route", "READY" if last_route.strip_edges() != "" and last_route != "-" else "WAIT", _dash(last_route)))
	lines.append(_bb_status_line("Route log", "READY" if route_log.size() > 0 else "WAIT", "%d route call(s)" % route_log.size()))
	lines.append("")
	lines.append(_section_bb("Route Buttons"))
	lines.append("Clean Social / Bentley / Evidence / Messy / Cleanup call the dev trigger directly. They do not add an Area2D, legacy candidate, or normal interaction scanner.")
	if not route_log.is_empty():
		lines.append("")
		lines.append(_section_bb("Recent Route Calls"))
		var start := maxi(0, route_log.size() - 5)
		for i in range(start, route_log.size()):
			var record: Dictionary = route_log[i]
			lines.append("- %s -> %s (%s)" % [String(record.get("route_label", record.get("route_id", ""))), "OK" if bool(record.get("ok", false)) else "ESCALATED", String(record.get("paper_trail_state", "-"))])
	lines.append("")
	lines.append(_section_bb("Manual QA Gate"))
	lines.append("Normal player-facing route activation remains deferred until Taco bag/code/Louis manual QA confirms the base mission flow is still clean.")
	return "\n".join(lines)


static func build_phase4g_model(rsum: Dictionary, dialogue_flags: Dictionary) -> Dictionary:
	var listener_counts: Dictionary = rsum.get("d6_03_router_listener_counts", {}) as Dictionary
	var listener_count := int(listener_counts.get("test_camera_alarm", 0))
	var flag_set := bool(dialogue_flags.get(PHASE4G_FLAG_KEY, false))
	var last_alarm := String(rsum.get("d6_04_last_camera_alarm_event", ""))
	var last_router_event := String(rsum.get("d6_03_last_dispatched_event", ""))
	var effect_set_id := String(rsum.get("d6_05_last_effect_set_id", ""))
	var effect_applied := int(rsum.get("d6_05_last_effect_set_applied_count", 0))
	var guard_result := String(rsum.get("d6_03_last_guard_spawn_result", ""))
	var spawned_count := int(rsum.get("d6_03_last_spawned_guard_count", 0))
	var active_guards := int(rsum.get("security_response_spawn_count", 0))
	var checks: Array[Dictionary] = []
	checks.append(_check("SecurityAuthoringRoot found", bool(rsum.get("d6_02_security_authoring_root_found", false))))
	checks.append(_check("Runtime camera spawned", int(rsum.get("d6_04_runtime_authored_camera_count", 0)) > 0))
	checks.append(_check("Event router active", bool(rsum.get("d6_03_security_router_active", false))))
	checks.append(_check("test_camera_alarm has listeners", listener_count > 0, "WAIT", "count=%d" % listener_count))
	checks.append(_check("Player is inside camera cone", bool(rsum.get("d6_04_authored_camera_player_in_cone", false))))
	checks.append(_check("Camera alarm fired", last_alarm == "test_camera_alarm" or last_router_event == "test_camera_alarm"))
	checks.append(_check("Router handled the alarm", bool(rsum.get("d6_04_last_camera_alarm_handled", false)) or bool(rsum.get("d6_04_last_event_handled", false))))
	checks.append(_check("Guard listener reacted", guard_result in ["spawned", "handled"] or spawned_count > 0 or active_guards > 0, "WAIT", guard_result))
	checks.append(_check("EffectSet listener applied", effect_set_id == "effectset_phase4g_camera_alarm_seen" and effect_applied > 0 or flag_set, "WAIT", effect_set_id))
	checks.append(_check("Phase 4G mission flag set", flag_set, "WAIT", PHASE4G_FLAG_KEY))
	return {
		"title": "Phase 4G - Camera Alarm EffectSet",
		"goal": "Trigger test_camera_alarm from the authored camera and confirm the EffectSet sets phase4g_camera_alarm_seen.",
		"next_action": _phase4g_next_action(checks),
		"checks": checks,
		"observed": {
			"player_in_cone": bool(rsum.get("d6_04_authored_camera_player_in_cone", false)),
			"detection": float(rsum.get("d6_04_authored_camera_detection_value", 0.0)),
			"last_camera": String(rsum.get("d6_04_last_camera_id", "")),
			"last_alarm": last_alarm,
			"last_router_event": last_router_event,
			"listeners_called": int(rsum.get("d6_04_last_event_listeners_called", 0)),
			"listeners_handled": int(rsum.get("d6_04_last_event_listeners_handled", 0)),
			"guard_result": guard_result,
			"effect_set_id": effect_set_id,
			"effect_applied": effect_applied,
			"effect_failed": int(rsum.get("d6_05_last_effect_set_failed_count", 0)),
			"flag_set": flag_set,
		},
	}


static func render_phase4g_model(model: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(String(model.get("title", "Phase 4G")))
	lines.append("")
	lines.append("Goal:")
	lines.append(String(model.get("goal", "")))
	lines.append("")
	lines.append("Where:")
	lines.append("Author: %s" % PHASE4G_CAMERA_AUTHOR_PATH)
	lines.append("Runtime: %s" % PHASE4G_RUNTIME_CAMERA_PATH)
	lines.append("Effect listener: %s" % PHASE4G_EFFECT_AUTHOR_PATH)
	lines.append("")
	lines.append("Next Action:")
	lines.append(String(model.get("next_action", "")))
	lines.append("")
	lines.append("Live Checks:")
	for check in (model.get("checks", []) as Array):
		lines.append("[%s] %s%s" % [String(check.get("status", "WAIT")), String(check.get("label", "")), _detail_suffix(String(check.get("detail", "")))])
	var observed: Dictionary = model.get("observed", {}) as Dictionary
	lines.append("")
	lines.append("Observed:")
	lines.append("Player in cone: %s" % _yes_no(observed.get("player_in_cone", false)))
	lines.append("Detection: %.2f" % float(observed.get("detection", 0.0)))
	lines.append("Last camera: %s" % _dash(String(observed.get("last_camera", ""))))
	lines.append("Last alarm: %s" % _dash(String(observed.get("last_alarm", ""))))
	lines.append("Last router event: %s" % _dash(String(observed.get("last_router_event", ""))))
	lines.append("Listeners called/handled: %d/%d" % [int(observed.get("listeners_called", 0)), int(observed.get("listeners_handled", 0))])
	lines.append("Guard result: %s" % _dash(String(observed.get("guard_result", ""))))
	lines.append("EffectSet: %s applied %d failed %d" % [_dash(String(observed.get("effect_set_id", ""))), int(observed.get("effect_applied", 0)), int(observed.get("effect_failed", 0))])
	lines.append("Flag set: %s" % _yes_no(observed.get("flag_set", false)))
	return "\n".join(lines)


func _render_overview(rsum: Dictionary, flags: Dictionary) -> String:
	var phase4g := build_phase4g_model(rsum, flags)
	var pass_count := 0
	var total := 0
	for check in (phase4g.get("checks", []) as Array):
		total += 1
		if String(check.get("status", "")) == "PASS":
			pass_count += 1
	return "\n".join([
		"Overview",
		"",
		"Use this panel when a manual QA step has too many raw F10 fields.",
		"Select a checklist above. F12 toggles this panel.",
		"",
		"Current supported checklists:",
		"- Phase 4E - Camera Readability",
		"- Phase 4G - Camera Alarm EffectSet",
		"- Phase 4F - Hide Spot",
		"- Taco Security Regression",
		"- D5-01 - Attempt Reset",
		"- D5-02 - Pause Context",
		"- D5-03 - Louis Beam Bypass",
		"",
		"Phase 4G quick score: %d/%d checks passing." % [pass_count, total],
		"D5 dashboards use colored status badges and teleport/action buttons above this text.",
	])


func _render_phase4e(rsum: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Phase 4E - Camera Readability")
	lines.append("")
	lines.append("Goal:")
	lines.append("Confirm the authored camera has readable sweep/runtime debug state.")
	lines.append("")
	lines.append("Where:")
	lines.append("Author: %s" % PHASE4G_CAMERA_AUTHOR_PATH)
	lines.append("Runtime: %s" % PHASE4G_RUNTIME_CAMERA_PATH)
	lines.append("")
	lines.append("Live Checks:")
	lines.append(_status_line("Runtime camera spawned", int(rsum.get("d6_04_runtime_authored_camera_count", 0)) > 0))
	lines.append(_status_line("Camera enabled", bool(rsum.get("d6_04_authored_camera_enabled", false))))
	lines.append(_status_line("Detection shape exists", bool(rsum.get("d6_04_authored_camera_has_shape", false))))
	lines.append(_status_line("Camera can report player cone state", rsum.has("d6_04_authored_camera_player_in_cone")))
	lines.append("")
	lines.append("Observed:")
	lines.append("Runtime path: %s" % _dash(String(rsum.get("d6_04_authored_camera_runtime_path", ""))))
	lines.append("Runtime class: %s" % _dash(String(rsum.get("d6_04_authored_camera_runtime_class", ""))))
	lines.append("Player in cone: %s" % _yes_no(rsum.get("d6_04_authored_camera_player_in_cone", false)))
	lines.append("Detection: %.2f" % float(rsum.get("d6_04_authored_camera_detection_value", 0.0)))
	lines.append("")
	lines.append("Manual pass: select TestCamera_Author in Local scene, confirm sweep fields and label are visible.")
	return "\n".join(lines)


func _render_phase4f() -> String:
	return "\n".join([
		"Phase 4F - Hide Spot",
		"",
		"Status:",
		"Template/proof only. No HideSpotNode is placed in Taco production yet.",
		"",
		"Template:",
		"res://scenes/missions/iso/authoring/HideSpotNodeTemplate.tscn",
		"",
		"Expected template tree:",
		"HideSpotNodeTemplate",
		"- CollisionShape2D",
		"- DebugLabel",
		"",
		"Expected root exports:",
		"mechanic_id = CHANGE_ME_HIDE_SPOT_ID",
		"hidden_detection_modifier = 0.35",
		"exposure_decay_on_enter = 0.25",
		"",
		"Automated proof:",
		"SecurityReadabilityLiteTest.gd -> test_hide_spot_reduces_and_resets_detection_modifier",
	])


func _render_taco_security(rsum: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Taco Security Regression")
	lines.append("")
	lines.append("Goal:")
	lines.append("Make sure the Phase 4 QA additions did not break Taco security startup.")
	lines.append("")
	lines.append("Checklist:")
	lines.append(_status_line("SecurityAuthoringRoot found", bool(rsum.get("d6_02_security_authoring_root_found", false))))
	lines.append(_status_line("Event router active", bool(rsum.get("d6_03_security_router_active", false))))
	lines.append(_status_line("Runtime authored camera spawned", int(rsum.get("d6_04_runtime_authored_camera_count", 0)) > 0))
	lines.append(_status_line("Guard spawn authors present", int(rsum.get("d6_02_authored_guard_spawn_count", 0)) > 0))
	lines.append(_status_line("EffectSet listener present", int(rsum.get("d6_05_effect_set_count", 0)) > 0))
	lines.append("")
	lines.append("Manual pass criteria:")
	lines.append("- Player can move.")
	lines.append("- F10 and F12 panels open.")
	lines.append("- Camera alarm can trigger without red errors.")
	lines.append("- Existing guard/alarm response still works.")
	return "\n".join(lines)


func _teleport_to_spawn(spawn_id: String) -> void:
	if spawn_id == "":
		_set_last_action("Teleport failed: empty spawn id.")
		return
	if _mission != null and _mission.has_method("teleport_player_to_spawn_id"):
		_mission.call("teleport_player_to_spawn_id", spawn_id)
		_set_last_action("Teleported to %s." % spawn_id)
		return
	_set_last_action("Teleport failed: mission has no teleport_player_to_spawn_id().")


func _teleport_to_marker(marker_id: String, offset: Vector2 = Vector2.ZERO) -> void:
	if marker_id == "":
		_set_last_action("Teleport failed: empty marker id.")
		return
	var marker := _find_marker_node(marker_id)
	if marker == null:
		_set_last_action("Teleport failed: marker not found: %s." % marker_id)
		return
	_teleport_to_node(marker, offset, "marker %s" % marker_id)


func _teleport_to_node_path(node_path: String, fallback_node_path: String = "", offset: Vector2 = Vector2.ZERO) -> void:
	var target := _get_mission_node_or_null(node_path)
	var used_path := node_path
	if target == null and fallback_node_path != "":
		target = _get_mission_node_or_null(fallback_node_path)
		used_path = fallback_node_path
	if target == null:
		_set_last_action("Teleport failed: node not found: %s." % node_path)
		return
	_teleport_to_node(target, offset, used_path)


func _teleport_to_node(target: Node, offset: Vector2, label: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var target_2d := target as Node2D
	if player == null:
		_set_last_action("Teleport failed: no player node in group 'player'.")
		return
	if target_2d == null:
		_set_last_action("Teleport failed: target is not Node2D: %s." % label)
		return
	player.global_position = target_2d.global_position + offset
	_set_last_action("Teleported to %s." % label)


func _find_marker_node(marker_id: String) -> Node2D:
	if _mission == null or not is_instance_valid(_mission):
		return null
	return _find_marker_node_recursive(_mission, marker_id)


func _find_marker_node_recursive(node: Node, marker_id: String) -> Node2D:
	if node == null:
		return null
	var direct_id := _node_string_property(node, "marker_id")
	var group_id := _node_string_property(node, "group_id")
	var linked_objective_id := _node_string_property(node, "linked_objective_id")
	if direct_id == marker_id or group_id == marker_id or linked_objective_id == marker_id:
		return node as Node2D
	for child in node.get_children():
		var found := _find_marker_node_recursive(child, marker_id)
		if found != null:
			return found
	return null


func _get_phase16_trigger() -> Node:
	if _mission != null and is_instance_valid(_mission):
		var direct := _mission.get_node_or_null("GameplayRoot/PlugAndPlayPilot/Phase16GarageDeniabilityDevTrigger")
		if direct != null:
			return direct
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("phase16_garage_deniability_dev_trigger")


func _run_phase16_route(method_name: String) -> void:
	if method_name.strip_edges() == "":
		_set_last_action("Phase 17 route failed: empty method.")
		return
	var trigger := _get_phase16_trigger()
	if trigger == null:
		_set_last_action("Phase 17 route failed: dev trigger missing.")
		return
	if not trigger.has_method(method_name):
		_set_last_action("Phase 17 route failed: missing %s." % method_name)
		return
	var result: Dictionary = trigger.call(method_name, {"triggered_by": "phase17_qa_panel", "qa_panel": true}) as Dictionary
	_set_last_action("Phase 17 %s -> %s (%s)." % [method_name, "OK" if bool(result.get("ok", false)) else "ESCALATED", String(result.get("code", ""))])


func _node_string_property(node: Node, property_name: String) -> String:
	for property in node.get_property_list():
		if str(property.get("name", "")) != property_name:
			continue
		var value: Variant = node.get(property_name)
		if value == null:
			return ""
		return str(value)
	return ""


func _get_mission_node_or_null(path: String) -> Node:
	if path == "" or _mission == null or not is_instance_valid(_mission):
		return null
	return _mission.get_node_or_null(path)


func _action_offset(action: Dictionary) -> Vector2:
	var offset_value: Variant = action.get("offset", Vector2.ZERO)
	return offset_value if offset_value is Vector2 else Vector2.ZERO


func _teleport_to_position(position_value: Variant) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_set_last_action("Teleport failed: no player node in group 'player'.")
		return
	var target := Vector2.ZERO
	if position_value is Vector2:
		target = position_value
	else:
		target = PHASE4G_CAMERA_TEST_POSITION
	player.global_position = target
	_set_last_action("Teleported player to %s." % str(target))


func _reset_current_attempt_runtime() -> void:
	if _mission != null and _mission.has_method("reset_mission_runtime_for_new_attempt"):
		_mission.call("reset_mission_runtime_for_new_attempt")
		_set_last_action("Reset attempt runtime state.")
		return
	_set_last_action("Reset failed: mission has no reset_mission_runtime_for_new_attempt().")


func _restart_current_mission() -> void:
	var mid := _current_mission_id()
	if mid == "":
		mid = PHASE4G_MISSION_ID
	GameState.start_mission(mid)
	SceneManager.change_scene(MissionSceneResolver.resolve_playable_scene_path(mid))
	_set_last_action("Restarting %s through canonical mission start." % mid)


func _set_last_action(text: String) -> void:
	if _last_action_label != null:
		_last_action_label.text = text


func _title_bb(text: String) -> String:
	return "[b][color=#7fd7ff]%s[/color][/b]" % text


func _section_bb(text: String) -> String:
	return "[b][color=#d8e8ff]%s[/color][/b]" % text


func _bb_status_line(label: String, status: String, detail: String = "") -> String:
	var suffix := "" if detail.strip_edges() == "" else " - %s" % detail
	return "%s %s%s" % [_status_badge(status), label, suffix]


func _status_badge(status: String) -> String:
	var normalized := status.strip_edges().to_upper()
	return "[color=%s][%s][/color]" % [_status_color(normalized), normalized]


func _status_color(status: String) -> String:
	match status:
		"PASS", "DONE", "OPEN", "READY":
			return "#5af27a"
		"WAIT", "LOCKED":
			return "#ffd45a"
		"TRIPPED", "USED", "WARN":
			return "#ff9f43"
		"FAIL":
			return "#ff5d5d"
		_:
			return "#c8d0dc"


func _join_or_dash(items: Array) -> String:
	if items.is_empty():
		return "-"
	var out: Array[String] = []
	for item in items:
		out.append(String(item))
	return ", ".join(out)


func _node_path_or_dash(node: Node) -> String:
	if node == null:
		return "-"
	return str(node.get_path())


static func _check(label: String, passed: bool, waiting_status: String = "WAIT", detail: String = "") -> Dictionary:
	return {
		"label": label,
		"status": "PASS" if passed else waiting_status,
		"detail": detail,
	}


static func _phase4g_next_action(checks: Array[Dictionary]) -> String:
	for check in checks:
		if String(check.get("status", "")) != "PASS":
			var label := String(check.get("label", ""))
			match label:
				"Runtime camera spawned":
					return "Wait for Taco scene startup or confirm AuthoredCamera_test_camera_01 exists in Remote."
				"Player is inside camera cone":
					return "Press Teleport, then wait in the camera sweep near Vector2(8500, 135)."
				"Camera alarm fired":
					return "Stay in the cone until the camera fills detection and fires test_camera_alarm."
				"Phase 4G mission flag set":
					return "Confirm the camera alarm fired; then check GameState dialogue flag if this stays waiting."
				_:
					return "Resolve: %s." % label
	return "All Phase 4G camera alarm checks passed."


static func _status_line(label: String, passed: bool, detail: String = "") -> String:
	return "[%s] %s%s" % ["PASS" if passed else "WAIT", label, _detail_suffix(detail)]


static func _detail_suffix(detail: String) -> String:
	return "" if detail.strip_edges() == "" else " (%s)" % detail


static func _yes_no(value: Variant) -> String:
	return "yes" if bool(value) else "no"


static func _dash(value: String) -> String:
	return "-" if value.strip_edges() == "" else value


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 0.92)
	style.border_color = Color(0.45, 0.85, 1.0, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", style)
