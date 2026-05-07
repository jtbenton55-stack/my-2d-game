@tool
class_name Phase0JCodeInputUI
extends CanvasLayer

@export var correct_code := "0420"
@export var debug_enabled := false
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")
@export var code_options: PackedStringArray = PackedStringArray(["2174", "0420", "9021"])

var _controller: Node
var _panel: PanelContainer
var _input: LineEdit
var _feedback: Label
var _current_input_label: Label
var _options_box: HBoxContainer


func _ready() -> void:
	layer = 100
	visible = false
	set_meta("generated_by", "Phase0J-C2")
	set_meta("scene_local_only", true)
	_build_ui()


func open_for_controller(controller: Node) -> void:
	_controller = controller
	visible = true
	add_to_group("blocking_ui")
	if _input != null:
		_input.text = ""
		_input.grab_focus()
	if _feedback != null:
		_feedback.text = "Choose or type a code."
	if _current_input_label != null:
		_current_input_label.text = "Current input: "
	_hud_message("Code gate: enter code")


func close_ui() -> void:
	visible = false
	remove_from_group("blocking_ui")
	if _input != null:
		_input.release_focus()


func is_open() -> bool:
	return visible


func submit_code(value: String) -> bool:
	var normalized := value.strip_edges()
	if normalized == correct_code:
		if _controller != null and _controller.has_method("unlock_gate"):
			_controller.call("unlock_gate")
		if _feedback != null:
			_feedback.text = "Code accepted - gate unlocked"
		_hud_message("Code accepted - gate unlocked")
		close_ui()
		return true
	if _feedback != null:
		_feedback.text = "Wrong code"
	if _controller != null and _controller.has_method("register_wrong_code_attempt"):
		_controller.call("register_wrong_code_attempt")
	_hud_message("Wrong code")
	return false


func submit_debug_code(value: String) -> bool:
	return submit_code(value)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_ui()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	if _panel != null:
		return
	_panel = PanelContainer.new()
	_panel.name = "GarageCodePanel"
	_panel.offset_left = 420
	_panel.offset_top = 180
	_panel.offset_right = 840
	_panel.offset_bottom = 430
	add_child(_panel)
	var box := VBoxContainer.new()
	box.name = "VBox"
	_panel.add_child(box)
	var title := Label.new()
	title.text = "Garage Code"
	box.add_child(title)
	var instructions := Label.new()
	instructions.text = "Choose one code option or type a code. Enter = Submit. Backspace = Delete. Escape = Cancel."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(instructions)
	var options_label := Label.new()
	options_label.text = "Options found:"
	box.add_child(options_label)
	_options_box = HBoxContainer.new()
	_options_box.name = "CodeOptions"
	box.add_child(_options_box)
	_build_option_buttons()
	_input = LineEdit.new()
	_input.name = "CodeInput"
	_input.placeholder_text = "Code"
	_input.max_length = 8
	_input.text_submitted.connect(func(value: String): submit_code(value))
	_input.text_changed.connect(func(value: String): _set_current_input(value))
	box.add_child(_input)
	_current_input_label = Label.new()
	_current_input_label.name = "CurrentInput"
	_current_input_label.text = "Current input: "
	box.add_child(_current_input_label)
	_feedback = Label.new()
	_feedback.name = "Feedback"
	box.add_child(_feedback)
	var row := HBoxContainer.new()
	box.add_child(row)
	var submit := Button.new()
	submit.text = "Submit"
	submit.pressed.connect(func(): submit_code(_input.text))
	row.add_child(submit)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(close_ui)
	row.add_child(cancel)


func _build_option_buttons() -> void:
	if _options_box == null:
		return
	for child in _options_box.get_children():
		child.queue_free()
	for option in code_options:
		var button := Button.new()
		button.text = String(option)
		button.pressed.connect(func(value := String(option)): submit_code(value))
		_options_box.add_child(button)


func _hud_message(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 3.0)


func _set_current_input(value: String) -> void:
	if _current_input_label != null:
		_current_input_label.text = "Current input: %s" % value
