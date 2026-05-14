class_name MissionCodeGatePlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

const TacoBellDialogue := preload("res://src/missions/iso/runtime/TacoBellDialogue.gd")

@export var gate_id: String = ""
@export var objective_id: String = ""
@export var correct_code: String = "2174"
@export var required_clue_id: String = ""
@export var bypass_item_id: String = ""
@export_multiline var wrong_code_text: String = "Wrong code. The keypad chirps, but the garage stays locked."
@export_multiline var solved_text: String = "Correct code. Garage office route open."

var solved := false
var _prompt: Window = null
var _input: LineEdit = null


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	interaction_text = "Click to enter code."
	super._ready()


func _complete(_player: Node = null) -> void:
	if solved:
		_show_feedback(solved_text)
		return
	_show_prompt()


func _has_required_clue() -> bool:
	if required_clue_id == "":
		return true
	return GameState.sterling_clues.has(required_clue_id)


func _has_bypass_item() -> bool:
	return bypass_item_id != "" and GameState.dialogue_flags.get("mission_access_item:" + bypass_item_id, false) == true


func _show_feedback(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": String(display_name), "text": text }])


func _show_prompt() -> void:
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.popup_centered()
		if _input != null:
			_input.grab_focus()
		return
	_prompt = Window.new()
	_prompt.title = "Garage Office Keypad"
	_prompt.size = Vector2i(340, 170)
	_prompt.unresizable = true
	var body := VBoxContainer.new()
	body.anchors_preset = Control.PRESET_FULL_RECT
	body.offset_left = 12
	body.offset_top = 12
	body.offset_right = -12
	body.offset_bottom = -12
	body.add_theme_constant_override("separation", 8)
	_prompt.add_child(body)
	var hint := Label.new()
	var clue_hint := "Hint available from clue." if _has_required_clue() else "Find the clue to learn the code."
	hint.text = clue_hint
	body.add_child(hint)
	_input = LineEdit.new()
	_input.placeholder_text = "Enter 4-digit code"
	_input.max_length = 8
	body.add_child(_input)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	body.add_child(row)
	var submit := Button.new()
	submit.text = "Submit"
	submit.pressed.connect(func(): _submit_code(_input.text))
	row.add_child(submit)
	var wrong := Button.new()
	wrong.text = "Enter Wrong (Test)"
	wrong.pressed.connect(func(): _submit_code("0000"))
	row.add_child(wrong)
	var correct := Button.new()
	correct.text = "Enter Correct (Test)"
	correct.pressed.connect(func(): _submit_code(correct_code))
	row.add_child(correct)
	get_tree().current_scene.add_child(_prompt)
	_prompt.close_requested.connect(func(): _prompt.hide())
	_prompt.popup_centered()
	_input.grab_focus()


func _submit_code(value: String) -> void:
	if value.strip_edges() == correct_code or (_has_bypass_item() and value.strip_edges() == ""):
		_unlock_gate()
	else:
		_on_wrong_code()
	if _prompt != null:
		_prompt.hide()


func _unlock_gate() -> void:
	solved = true
	GameState.dialogue_flags["mission_gate:" + gate_id] = true
	if objective_id != "":
		placeholder_completed.emit(objective_id)
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("set_iso_access_item"):
		mission.set_iso_access_item(gate_id)
	if mission != null and mission.has_method("set_code_gate_open"):
		mission.set_code_gate_open(gate_id, true)
	var success_line := TacoBellDialogue.line("code_success_001", solved_text + " Code accepted: " + correct_code + ".", display_name)
	_show_feedback(String(success_line.get("text", solved_text)))
	remove_from_group("interactable")
	set_deferred("monitoring", false)


func _on_wrong_code() -> void:
	var attempts := 0
	var threshold := 2
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("get_wrong_code_alarm_threshold"):
		threshold = int(mission.call("get_wrong_code_alarm_threshold"))
	if mission_id != "":
		GameState.record_mission_performance_event(mission_id, "wrong_code_attempts", 1)
		attempts = int(GameState.mission_performance.get(mission_id, {}).get("wrong_code_attempts", 0))
	if mission != null and mission.has_method("increment_attempt_counter"):
		mission.call("increment_attempt_counter", "wrong_code", 1)
		if attempts >= 2:
			GameState.set_mission_alert_state(mission_id, "suspicious")
	_report_security_adapter_wrong_code(gate_id, attempts)
	EventBus.screen_shake.emit(2.8, 0.12)
	EventBus.debug("Code gate warning flash RED: " + gate_id)
	var warning_line := TacoBellDialogue.line("code_wrong_001", wrong_code_text, display_name)
	if attempts >= threshold:
		var controller := get_tree().get_first_node_in_group("iso_alert_controller")
		if controller != null:
			controller.call("register_detection_event", gate_id, 1.0, "wrong_code_alarm")
		if mission != null and mission.has_method("spawn_attack_guard_near_player"):
			mission.call("spawn_attack_guard_near_player", gate_id)
		var alarm_line := TacoBellDialogue.line("alarm_triggered_001", "Alarm tripped.", "Security")
		_show_feedback(String(warning_line.get("text")) + " Wrong attempts: " + str(attempts) + ". " + String(alarm_line.get("text")))
		return
	_show_feedback(String(warning_line.get("text")) + " Wrong attempts: " + str(attempts) + ".")


func _report_security_adapter_wrong_code(gate_id: String, attempts: int) -> void:
	var ctrl := get_tree().get_first_node_in_group("iso_alert_controller")
	if ctrl == null or not ctrl.has_method("get_security_event_adapter"):
		return
	var adapter: Variant = ctrl.call("get_security_event_adapter")
	if adapter != null and adapter.has_method("report_security_event"):
		adapter.call("report_security_event", "wrong_code", gate_id, 1, {"attempts": attempts})
