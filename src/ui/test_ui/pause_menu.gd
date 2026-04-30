extends CanvasLayer

@onready var resume_button: Button = $Overlay/CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $Overlay/CenterContainer/VBoxContainer/ExitButton

var controls_button: Button = null
var controls_panel: Panel = null
var controls_label: Label = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	_setup_controls_menu()
	resume_button.pressed.connect(_resume_game)
	exit_button.pressed.connect(_exit_to_hideout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	get_tree().paused = true
	show()
	resume_button.grab_focus()

func _resume_game() -> void:
	get_tree().paused = false
	if controls_panel:
		controls_panel.hide()
	hide()

func _exit_to_hideout() -> void:
	get_tree().paused = false
	SceneManager.return_to_hideout()

func _setup_controls_menu() -> void:
	var menu := $Overlay/CenterContainer/VBoxContainer
	controls_button = Button.new()
	controls_button.custom_minimum_size = Vector2(240, 52)
	controls_button.text = "Controls"
	menu.add_child(controls_button)
	menu.move_child(controls_button, exit_button.get_index())
	controls_button.pressed.connect(_toggle_controls_panel)
	
	controls_panel = Panel.new()
	controls_panel.custom_minimum_size = Vector2(520, 260)
	controls_panel.hide()
	menu.add_child(controls_panel)
	menu.move_child(controls_panel, controls_button.get_index() + 1)
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	controls_panel.add_child(margin)
	
	controls_label = Label.new()
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.add_theme_font_size_override("font_size", 16)
	controls_label.text = _controls_text()
	margin.add_child(controls_label)

func _toggle_controls_panel() -> void:
	if controls_panel == null:
		return
	controls_panel.visible = not controls_panel.visible

func _controls_text() -> String:
	var lines: Array[String] = [
		"Movement",
		"  Move: %s / %s / %s / %s" % [_bindings("move_up", "W"), _bindings("move_left", "A"), _bindings("move_down", "S"), _bindings("move_right", "D")],
		"  Interact / advance dialogue: %s" % _bindings("interact", "E"),
		"",
		"Combat",
		"  Attack / strike: %s" % _bindings("attack", "Left Mouse"),
		"  Dodge / roll: %s" % _bindings("dodge", "Space"),
		"  Stealth / sneak: %s" % _bindings("stealth", "Shift"),
		"  Bentley ability / sniff: %s" % _bindings("bentley_ability", "F"),
		"",
		"Menus",
		"  Pause / resume: %s" % _bindings("pause", "Esc"),
		"  Toggle old controls overlay: F1 (hidden by default)"
	]
	return "\n".join(lines)

func _bindings(action_name: String, fallback: String) -> String:
	if not InputMap.has_action(action_name):
		return fallback
	var events := InputMap.action_get_events(action_name)
	var names: PackedStringArray = []
	for ev in events:
		if ev is InputEventKey:
			names.append(OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode))
		elif ev is InputEventMouseButton:
			names.append("Mouse %d" % ev.button_index)
		elif ev is InputEventJoypadButton:
			names.append("Gamepad Button %d" % ev.button_index)
	return ", ".join(names) if not names.is_empty() else fallback
