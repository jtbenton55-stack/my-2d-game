extends Control

## Simple overlay that shows the main controls.
## Can be toggled with a hotkey (F1) or left always visible.

@export var hotkey: Key = KEY_F1
@export var always_visible: bool = true

@onready var info_label: Label = $MarginContainer/Panel/InfoLabel
@onready var minimize_button: Button = $MarginContainer/Panel/MinimizeButton

var is_minimized: bool = false
var full_text: String = ""

func _ready() -> void:
	# Set process mode so it works even when the game is paused
	process_mode = PROCESS_MODE_ALWAYS
	z_index = 100
	_update_label()
	full_text = info_label.text
	
	# Connect minimize button
	if minimize_button:
		minimize_button.pressed.connect(_on_minimize_pressed)
	
	# If not always visible, hide initially
	if not always_visible:
		visible = false
	else:
		visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == hotkey and event.pressed and not event.echo:
		if is_minimized:
			is_minimized = false
			info_label.text = full_text
			if minimize_button:
				minimize_button.text = "-"
		else:
			visible = !visible
		get_viewport().set_input_as_handled()

func _on_minimize_pressed() -> void:
	is_minimized = !is_minimized
	if is_minimized:
		info_label.text = "[F1] Controls"
		if minimize_button:
			minimize_button.text = "+"
	else:
		info_label.text = full_text
		if minimize_button:
			minimize_button.text = "-"

func _update_label() -> void:
	var text := "[F1] Toggle | [ESC] Pause\n"
	text += "\n"
	
	# Read the actual keybindings from the InputMap
	text += _action_bindings("move_left", "A")
	text += _action_bindings("move_right", "D")
	text += _action_bindings("move_up", "W")
	text += _action_bindings("move_down", "S")
	text += _action_bindings("interact", "E")
	text += _action_bindings("attack", "Space")
	text += _action_bindings("dodge", "Shift")
	text += _action_bindings("stealth", "Ctrl")
	text += _action_bindings("bentley_ability", "Q")
	
	info_label.text = text

func _action_bindings(action_name: String, label: String) -> String:
	if not InputMap.has_action(action_name):
		return ""
	var keys: Array[InputEvent] = InputMap.action_get_events(action_name)
	var key_strs: PackedStringArray = []
	for ev in keys:
		if ev is InputEventKey:
			key_strs.append(OS.get_keycode_string(ev.keycode))
		elif ev is InputEventJoypadButton:
			key_strs.append("Btn %d" % ev.button_index)
		elif ev is InputEventMouseButton:
			key_strs.append("M%d" % ev.button_index)
	if key_strs.is_empty():
		return "%s: %s\n" % [label, action_name]
	return "%s: %s\n" % [label, ", ".join(key_strs)]
