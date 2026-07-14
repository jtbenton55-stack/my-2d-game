extends CanvasLayer

const InputBindingFormatterScript := preload("res://src/utils/InputBindingFormatter.gd")

@onready var resume_button: Button = $Overlay/CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $Overlay/CenterContainer/VBoxContainer/ExitButton

var objectives_button: Button = null
var scheme_cards_button: Button = null
var clues_button: Button = null
var inventory_button: Button = null
var controls_button: Button = null
var info_panel: Panel = null
var _info_scroll: ScrollContainer = null
var _info_rich: RichTextLabel = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	_setup_controls_menu()
	resume_button.pressed.connect(_resume_game)
	exit_button.pressed.connect(_exit_to_hideout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()
		return
	if visible and event.is_action_pressed("ui_cancel"):
		if info_panel != null and info_panel.visible:
			_close_info_panel()
		else:
			_resume_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	get_tree().paused = true
	show()
	resume_button.grab_focus()

func _resume_game() -> void:
	get_tree().paused = false
	if info_panel != null:
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
	inventory_button = _add_menu_button(menu, "Inventory", exit_button.get_index() + 3)
	controls_button = _add_menu_button(menu, "Controls", exit_button.get_index() + 4)
	objectives_button.pressed.connect(func(): _toggle_info_panel("objectives"))
	scheme_cards_button.pressed.connect(func(): _toggle_info_panel("scheme_cards"))
	clues_button.pressed.connect(func(): _toggle_info_panel("clues"))
	inventory_button.pressed.connect(func(): _toggle_info_panel("inventory"))
	controls_button.pressed.connect(func(): _toggle_info_panel("controls"))

	info_panel = Panel.new()
	info_panel.custom_minimum_size = Vector2(560, 420)
	info_panel.hide()
	menu.add_child(info_panel)
	menu.move_child(info_panel, controls_button.get_index() + 1)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	info_panel.add_child(margin)

	_info_scroll = ScrollContainer.new()
	_info_scroll.name = "PauseInfoScroll"
	_info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_info_scroll.custom_minimum_size = Vector2(520, 360)
	margin.add_child(_info_scroll)

	_info_rich = RichTextLabel.new()
	_info_rich.name = "PauseInfoRichText"
	_info_rich.bbcode_enabled = false
	_info_rich.fit_content = false
	_info_rich.scroll_active = true
	_info_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_rich.add_theme_font_size_override("normal_font_size", 16)
	_info_scroll.add_child(_info_rich)

func _add_menu_button(menu: VBoxContainer, text: String, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(240, 52)
	button.text = text
	menu.add_child(button)
	menu.move_child(button, index)
	return button

func _toggle_info_panel(kind: String) -> void:
	if info_panel == null or _info_rich == null:
		return
	if info_panel.visible and String(info_panel.get_meta("kind", "")) == kind:
		info_panel.hide()
		return
	info_panel.set_meta("kind", kind)
	match kind:
		"objectives":
			_info_rich.text = _objectives_text()
		"scheme_cards":
			_info_rich.text = _scheme_cards_text()
		"clues":
			_info_rich.text = _clues_text()
		"inventory":
			_info_rich.text = _inventory_text()
		_:
			_info_rich.text = _controls_text()
	info_panel.show()
	call_deferred("_fit_pause_info_scroll")


func _close_info_panel() -> void:
	if info_panel == null:
		return
	var kind := String(info_panel.get_meta("kind", ""))
	info_panel.hide()
	var return_button: Button = {
		"objectives": objectives_button,
		"scheme_cards": scheme_cards_button,
		"clues": clues_button,
		"inventory": inventory_button,
		"controls": controls_button,
	}.get(kind)
	if return_button != null:
		return_button.grab_focus()


func _fit_pause_info_scroll() -> void:
	if _info_rich == null or _info_scroll == null:
		return
	var w := maxf(120.0, _info_scroll.size.x - 8.0)
	if w <= 120.0:
		w = 500.0
	_info_rich.custom_minimum_size = Vector2(w, maxf(160.0, _info_rich.get_content_height()))

func _controls_text() -> String:
	var lines: Array[String] = [
		"Movement",
		"  Move: %s / %s / %s / %s" % [_bindings("move_up", "W"), _bindings("move_left", "A"), _bindings("move_down", "S"), _bindings("move_right", "D")],
		"  Interact / advance dialogue: %s" % _bindings("interact", "E"),
		"",
		"Combat (hitbox melee)",
		"  Light attack / combo: %s (J = keyboard jab; mouse / gamepad also work)" % _bindings("attack", "J / Mouse"),
		"  Heavy attack: %s" % _bindings("heavy", "Mouse Right"),
		"  Case the Joint pulse: %s" % _bindings("case_the_joint", "Q"),
		"  Dash (invulnerable frames): %s (hold a move direction or dash won't start)" % _bindings("dodge", "Space"),
		"  Style finisher (STYLE bar full in HUD): %s" % _bindings("finisher", "R"),
		"  Sprint (stamina): hold %s while moving (Ctrl sustained sprint; Space is dash/dodge only)" % _bindings("sprint", "Ctrl"),
		"  Stealth walk: hold %s and use WASD together (slower, quieter movement)" % _bindings("stealth", "Shift"),
		"  Stealth takedown: stealth + behind unaware enemy + %s" % _bindings("attack", "J / light attack"),
		"  Bentley Bark / Sniff / Fetch / Stay-Heel: %s / %s / %s / %s" % [_bindings("bentley_bark", "1"), _bindings("bentley_sniff", "2"), _bindings("bentley_fetch", "3"), _bindings("bentley_toggle_stay", "4")],
		"  Bentley fallback bark: %s" % _bindings("bentley_ability", "F"),
		"  Poop bag targeting: %s; aim Right Stick/mouse, %s throw, %s cancel" % [_bindings("poop_bag_targeting", "T"), _bindings("attack", "Mouse Left"), _bindings("ui_cancel", "Esc")],
		"",
		"Menus",
		"  Pause / resume: %s" % _bindings("pause", "Esc"),
		"  Toggle controls overlay: F1 (hidden by default)"
	]
	return "\n".join(lines)


func _objectives_text() -> String:
	var mission_node := _mission_node()
	var payload := MissionPauseDataProvider.get_pause_payload("", mission_node)
	var mission_id := String(payload.get("mission_id", ""))
	var lines: Array[String] = []
	lines.append(String(payload.get("mission_name", mission_id)))
	if mission_id != "":
		lines.append("Mission ID: %s" % mission_id)
	var next_text := String(payload.get("next_objective_text", "")).strip_edges()
	if next_text != "":
		lines.append("Next: %s" % next_text)
	lines.append("")
	var heat_line := String(payload.get("heat_security_line", ""))
	if heat_line != "":
		lines.append(heat_line)
		lines.append("")
	lines.append("Attempt Context")
	for row in payload.get("attempt_context", []):
		if row is Dictionary:
			lines.append("  - %s: %s" % [String(row.get("label", "")), String(row.get("text", ""))])
	lines.append("")
	lines.append("Active Objectives")
	var saw_active := false
	for row in payload.get("objectives", []):
		if row is Dictionary and String(row.get("kind", "")) == "active":
			saw_active = true
			var prefix := "NEXT - " if bool(row.get("is_next", false)) else ""
			lines.append("  - " + prefix + String(row.get("text", "")))
	if not saw_active:
		lines.append("  No active objectives.")
	lines.append("")
	lines.append("Completed Objectives")
	var saw_done := false
	for row in payload.get("objectives", []):
		if row is Dictionary and String(row.get("kind", "")) == "completed":
			saw_done = true
			lines.append("  - " + String(row.get("text", "")))
	if not saw_done:
		lines.append("  No completed objectives yet.")
	for w in payload.get("warnings", []):
		var ws := String(w).strip_edges()
		if ws == "":
			continue
		lines.append("")
		lines.append("Note: " + ws)
	return "\n".join(lines)


func _scheme_cards_text() -> String:
	if not MissionAutoloadResolver.has_game_state():
		return "Scheme card data is not available right now."
	var snap := MissionPauseDataProvider.get_scheme_card_snapshot("", _mission_node())
	return MissionSchemeCardFormatter.format_player_pause_scheme_text(snap)


func _clues_text() -> String:
	var snap := MissionPauseDataProvider.get_clue_snapshot("", _mission_node())
	var lines: Array[String] = ["Found Clues"]
	if snap.get("items", []).is_empty():
		lines.append("  none")
	else:
		for row in snap.get("items", []):
			if row is Dictionary:
				lines.append(
					"  - %s: %s"
					% [String(row.get("title", row.get("id", ""))), String(row.get("description", ""))]
				)
	for w in snap.get("warnings", []):
		var ws := String(w).strip_edges()
		if ws == "":
			continue
		lines.append("")
		lines.append("Note: " + ws)
	return "\n".join(lines)


func _inventory_text() -> String:
	var snap := MissionPauseDataProvider.get_inventory_snapshot()
	var lines: Array[String] = ["Mission Inventory"]
	if snap.get("items", []).is_empty():
		lines.append("  empty")
	else:
		for row in snap.get("items", []):
			if row is Dictionary:
				var item_id := String(row.get("item_id", ""))
				var display := String(row.get("display_name", item_id)).strip_edges()
				if display == "":
					display = item_id
				lines.append(
					"  - %s x%d [%s]"
					% [display, int(row.get("count", 0)), String(row.get("category", ""))]
				)
	return "\n".join(lines)


func _mission_node() -> Node:
	var node := get_parent()
	while node != null:
		if node.has_method("get_mission_id"):
			return node
		node = node.get_parent()
	return null

func _bindings(action_name: String, fallback: String) -> String:
	return InputBindingFormatterScript.action_summary(StringName(action_name), fallback)
