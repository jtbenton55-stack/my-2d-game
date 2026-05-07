extends CanvasLayer

@onready var resume_button: Button = $Overlay/CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $Overlay/CenterContainer/VBoxContainer/ExitButton

var objectives_button: Button = null
var scheme_cards_button: Button = null
var clues_button: Button = null
var controls_button: Button = null
var info_panel: Panel = null
var info_label: Label = null

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
	if info_panel:
		info_panel.hide()
	hide()

func _exit_to_hideout() -> void:
	get_tree().paused = false
	SceneManager.return_to_hideout()

func _setup_controls_menu() -> void:
	var menu := $Overlay/CenterContainer/VBoxContainer
	objectives_button = _add_menu_button(menu, "Objectives", exit_button.get_index())
	scheme_cards_button = _add_menu_button(menu, "Scheme Cards", exit_button.get_index() + 1)
	clues_button = _add_menu_button(menu, "Clues", exit_button.get_index() + 2)
	controls_button = _add_menu_button(menu, "Controls", exit_button.get_index() + 3)
	objectives_button.pressed.connect(func(): _toggle_info_panel("objectives"))
	scheme_cards_button.pressed.connect(func(): _toggle_info_panel("scheme_cards"))
	clues_button.pressed.connect(func(): _toggle_info_panel("clues"))
	controls_button.pressed.connect(func(): _toggle_info_panel("controls"))

	info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(560, 420)
	info_panel.hide()
	menu.add_child(info_panel)
	menu.move_child(info_panel, controls_button.get_index() + 1)
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	info_panel.add_child(margin)
	
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 16)
	margin.add_child(info_label)

func _add_menu_button(menu: VBoxContainer, text: String, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(240, 52)
	button.text = text
	menu.add_child(button)
	menu.move_child(button, index)
	return button

func _toggle_info_panel(kind: String) -> void:
	if info_panel == null or info_label == null:
		return
	if info_panel.visible and String(info_panel.get_meta("kind", "")) == kind:
		info_panel.hide()
		return
	info_panel.set_meta("kind", kind)
	match kind:
		"objectives":
			info_label.text = _objectives_text()
		"scheme_cards":
			info_label.text = _scheme_cards_text()
		"clues":
			info_label.text = _clues_text()
		_:
			info_label.text = _controls_text()
	info_panel.show()

func _controls_text() -> String:
	var lines: Array[String] = [
		"Movement",
		"  Move: %s / %s / %s / %s" % [_bindings("move_up", "W"), _bindings("move_left", "A"), _bindings("move_down", "S"), _bindings("move_right", "D")],
		"  Interact / advance dialogue: %s" % _bindings("interact", "E"),
		"",
		"Combat (hitbox melee)",
		"  Light attack / combo: %s (J = keyboard jab; mouse / gamepad also work)" % _bindings("attack", "J / Mouse"),
		"  Case the Joint pulse: %s" % _bindings("case_the_joint", "Q"),
		"  Dash (invulnerable frames): %s (hold a move direction or dash won't start)" % _bindings("dodge", "Space"),
		"  Style finisher (STYLE bar full in HUD): %s" % _bindings("finisher", "R"),
		"  Stealth walk: hold %s and use WASD together (slower, quieter movement)" % _bindings("stealth", "Shift"),
		"  Stealth takedown: stealth + behind unaware enemy + %s" % _bindings("attack", "J / light attack"),
		"  Bentley Bark / Sniff / Fetch / Stay-Heel: %s / %s / %s / %s" % [_bindings("bentley_bark", "1"), _bindings("bentley_sniff", "2"), _bindings("bentley_fetch", "3"), _bindings("bentley_toggle_stay", "4")],
		"  Bentley fallback bark: %s" % _bindings("bentley_ability", "F"),
		"  Poop bag throw targeting: %s (left click throw, right click or Esc cancel)" % _bindings("poop_bag_targeting", "T"),
		"",
		"Menus",
		"  Pause / resume: %s" % _bindings("pause", "Esc"),
		"  Toggle controls overlay: F1 (hidden by default)"
	]
	return "\n".join(lines)


func _objectives_text() -> String:
	var mission_id := String(GameState.current_mission_id)
	var active: Array = QuestManager.get_active_objectives(mission_id) if QuestManager.has_method("get_active_objectives") else []
	var done: Array = QuestManager.get_completed_objectives(mission_id) if QuestManager.has_method("get_completed_objectives") else []
	var lines: Array[String] = ["Active Objectives"]
	if active.is_empty():
		lines.append("  No active objectives.")
	else:
		for entry in active:
			lines.append("  - " + String(entry))
	lines.append("")
	lines.append("Completed Objectives")
	if done.is_empty():
		lines.append("  No completed objectives yet.")
	else:
		for entry in done:
			lines.append("  - " + String(entry))
	return "\n".join(lines)


func _scheme_cards_text() -> String:
	var lines: Array[String] = ["Active / Unlocked Scheme Cards"]
	if GameState.selected_cards.is_empty():
		lines.append("  Equipped: none")
	else:
		lines.append("  Equipped: " + ", ".join(GameState.selected_cards))
	lines.append("")
	lines.append("Unlocked")
	if GameState.unlocked_cards.is_empty():
		lines.append("  none")
	else:
		for card_id in GameState.unlocked_cards:
			lines.append("  - " + String(card_id))
	return "\n".join(lines)


func _clues_text() -> String:
	var lines: Array[String] = ["Found Clues"]
	var found := 0
	for clue_id in GameState.sterling_clues.keys():
		var clue: Dictionary = GameState.sterling_clues.get(clue_id, {})
		if clue.get("discovered", false) != true:
			continue
		found += 1
		lines.append("  - %s: %s" % [String(clue.get("title", clue_id)), String(clue.get("description", ""))])
	if found == 0:
		lines.append("  none")
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
