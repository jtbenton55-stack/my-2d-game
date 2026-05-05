extends CanvasLayer

## Simple overlay that shows the main controls.
## Can be toggled with a hotkey (F1) or left always visible.

@export var hotkey: Key = KEY_F1
@export var always_visible: bool = false

@onready var info_label: Label = $PanelRoot/MarginContainer/Panel/InfoLabel
@onready var minimize_button: Button = $PanelRoot/MarginContainer/Panel/MinimizeButton

var is_minimized: bool = false
var full_text: String = ""

func _ready() -> void:
	# Set process mode so it works even when the game is paused
	process_mode = PROCESS_MODE_ALWAYS
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
	var text := "[F1] Toggle | [ESC] Pause\n\n"
	text += _action_bindings("move_left", "Move left")
	text += _action_bindings("move_right", "Move right")
	text += _action_bindings("move_up", "Move up")
	text += _action_bindings("move_down", "Move down")
	text += _action_bindings("interact", "Interact / dialogue")
	text += _action_bindings("attack", "Light attack / combo")
	text += _action_bindings("case_the_joint", "Case the Joint")
	text += _action_bindings("dodge", "Dash")
	text += _action_bindings("finisher", "Finisher (style full)")
	text += _action_bindings("stealth", "Stealth walk (hold + WASD)")
	text += "Stealth takedown: stealth + behind unaware + light attack\n"
	text += _action_bindings("bentley_bark", "Bentley Bark")
	text += _action_bindings("bentley_sniff", "Bentley Sniff")
	text += _action_bindings("bentley_fetch", "Bentley Fetch")
	text += _action_bindings("bentley_toggle_stay", "Bentley Stay/Heel")
	text += _action_bindings("poop_bag_targeting", "Poop bag throw mode")
	text += _action_bindings("bentley_ability", "Bentley bark (fallback)")

	info_label.text = text

func _action_bindings(action_name: String, label: String) -> String:
	if not InputMap.has_action(action_name):
		return ""
	var keys: Array[InputEvent] = InputMap.action_get_events(action_name)
	var key_strs: PackedStringArray = []
	for ev in keys:
		if ev is InputEventKey:
			var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			key_strs.append(OS.get_keycode_string(kc))
		elif ev is InputEventJoypadButton:
			key_strs.append("Btn %d" % ev.button_index)
		elif ev is InputEventMouseButton:
			key_strs.append("M%d" % ev.button_index)
	if key_strs.is_empty():
		return "%s: %s\n" % [label, action_name]
	return "%s: %s\n" % [label, ", ".join(key_strs)]
