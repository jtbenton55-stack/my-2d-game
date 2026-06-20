class_name MissionQAChecklistPanel
extends Panel

const MODE_OVERVIEW := 0
const MODE_PHASE4E := 1
const MODE_PHASE4G := 2
const MODE_PHASE4F := 3
const MODE_TACO_SECURITY := 4

const PHASE4G_MISSION_ID := "taco_bell_drop"
const PHASE4G_FLAG_ID := "phase4g_camera_alarm_seen"
const PHASE4G_FLAG_KEY := "mission_flag:taco_bell_drop:phase4g_camera_alarm_seen"
const PHASE4G_CAMERA_AUTHOR_PATH := "GameplayRoot/SecurityAuthoringRoot/TestCamera_Author"
const PHASE4G_RUNTIME_CAMERA_PATH := "EntityRoot/Cameras/AuthoredCamera_test_camera_01"
const PHASE4G_EFFECT_AUTHOR_PATH := "GameplayRoot/SecurityAuthoringRoot/Phase4G_CameraAlarmEffectSet_Author"
const PHASE4G_CAMERA_TEST_POSITION := Vector2(8500.0, 135.0)

var _mission: Node = null
var _selector: OptionButton = null
var _body: RichTextLabel = null
var _teleport_button: Button = null
var _reset_flag_button: Button = null
var _last_action_label: Label = null
var _mode := MODE_OVERVIEW


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process(true)
	visible = false


func set_mission(mission: Node) -> void:
	_mission = mission


func toggle_panel() -> void:
	visible = not visible
	if visible:
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
	_selector.item_selected.connect(_on_mode_selected)
	add_child(_selector)

	_teleport_button = Button.new()
	_teleport_button.name = "TeleportCameraTestButton"
	_teleport_button.position = Vector2(322.0, 38.0)
	_teleport_button.size = Vector2(88.0, 30.0)
	_teleport_button.text = "Teleport"
	_teleport_button.pressed.connect(_on_teleport_pressed)
	add_child(_teleport_button)

	_reset_flag_button = Button.new()
	_reset_flag_button.name = "ResetPhase4GFlagButton"
	_reset_flag_button.position = Vector2(416.0, 38.0)
	_reset_flag_button.size = Vector2(92.0, 30.0)
	_reset_flag_button.text = "Reset Flag"
	_reset_flag_button.pressed.connect(_on_reset_flag_pressed)
	add_child(_reset_flag_button)

	_last_action_label = Label.new()
	_last_action_label.name = "LastAction"
	_last_action_label.position = Vector2(12.0, 72.0)
	_last_action_label.size = Vector2(496.0, 22.0)
	_last_action_label.text = "Select a QA checklist."
	_last_action_label.add_theme_font_size_override("font_size", 11)
	add_child(_last_action_label)

	_body = RichTextLabel.new()
	_body.name = "ChecklistBody"
	_body.position = Vector2(12.0, 98.0)
	_body.size = Vector2(496.0, 410.0)
	_body.bbcode_enabled = false
	_body.fit_content = false
	_body.scroll_active = true
	_body.add_theme_font_size_override("normal_font_size", 12)
	add_child(_body)
	_update_button_visibility()


func _on_mode_selected(index: int) -> void:
	_mode = _selector.get_item_id(index)
	_update_button_visibility()
	_refresh()


func _update_button_visibility() -> void:
	var is_phase4g := _mode == MODE_PHASE4G
	if _teleport_button != null:
		_teleport_button.visible = is_phase4g
	if _reset_flag_button != null:
		_reset_flag_button.visible = is_phase4g


func _refresh() -> void:
	if _body == null:
		return
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
		"",
		"Phase 4G quick score: %d/%d checks passing." % [pass_count, total],
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


func _on_teleport_pressed() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_set_last_action("Teleport failed: no player node in group 'player'.")
		return
	player.global_position = PHASE4G_CAMERA_TEST_POSITION
	_set_last_action("Teleported player to camera test position %s." % str(PHASE4G_CAMERA_TEST_POSITION))


func _on_reset_flag_pressed() -> void:
	GameState.dialogue_flags.erase(PHASE4G_FLAG_KEY)
	_set_last_action("Reset %s." % PHASE4G_FLAG_KEY)


func _set_last_action(text: String) -> void:
	if _last_action_label != null:
		_last_action_label.text = text


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
