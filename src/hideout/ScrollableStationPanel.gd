extends PanelContainer
class_name ScrollableStationPanel

signal action_pressed(action_id: String)
signal panel_action_pressed(action_id: String, payload: Dictionary)
signal closed

@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _body_scroll: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var _body: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/Body
@onready var _buttons: VBoxContainer = $MarginContainer/VBoxContainer/ActionButtons
@onready var _close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var current_panel_data: Dictionary = {}
var panel_history: Array[Dictionary] = []
var _button_scroll: ScrollContainer = null

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_wrap_button_list_for_scrolling()
	_configure_text_nodes()
	hide()
	if _close_button:
		_close_button.text = "Close"
		_close_button.pressed.connect(close_panel)

func open_panel(title: String, body: String, buttons: Array = [], push_history: bool = false) -> void:
	if push_history and not current_panel_data.is_empty():
		panel_history.append(current_panel_data.duplicate(true))
	_title.text = title if title.strip_edges() != "" else "Hideout Station"
	_body.text = body if body.strip_edges() != "" else "This station is wired, but its text has not been filled in yet."
	var normalized_buttons := _without_close_buttons(buttons)
	current_panel_data = {"title": _title.text, "body": _body.text, "buttons": normalized_buttons.duplicate(true)}
	_configure_text_nodes()
	_fit_to_viewport(normalized_buttons.size())
	_build_buttons(normalized_buttons)
	_reset_scroll()
	add_to_group("blocking_ui")
	show()
	print("[ScrollableStationPanel] Opened: " + _title.text)
	grab_focus()

func open_subpanel(title: String, body: String, buttons: Array = []) -> void:
	open_panel(title, body, buttons, true)

func go_back() -> void:
	if panel_history.is_empty():
		close_panel()
		return
	var previous: Dictionary = panel_history.pop_back()
	open_panel(String(previous.get("title", "Hideout Station")), String(previous.get("body", "")), previous.get("buttons", []), false)

func clear_history() -> void:
	panel_history.clear()

func close() -> void:
	close_panel()

func close_panel() -> void:
	hide()
	remove_from_group("blocking_ui")
	clear_history()
	current_panel_data.clear()
	print("[ScrollableStationPanel] Closed")
	closed.emit()

func is_open() -> bool:
	return visible

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()

func _build_buttons(buttons: Array) -> void:
	for child in _buttons.get_children():
		child.queue_free()
	for raw_button in buttons:
		var button_data := _normalize_button_data(raw_button)
		if String(button_data.get("action", "")) == "close" or String(button_data.get("label", "")).strip_edges().to_lower() == "close":
			continue
		var button := Button.new()
		button.text = String(button_data.get("label", "Back"))
		button.custom_minimum_size = Vector2(220, 34)
		var action_id := String(button_data.get("action", "close"))
		button.pressed.connect(func() -> void:
			action_pressed.emit(action_id)
			panel_action_pressed.emit(action_id, button_data)
		)
		_buttons.add_child(button)

func _normalize_button_data(raw_button) -> Dictionary:
	if raw_button is Dictionary:
		var data := Dictionary(raw_button)
		if not data.has("label"):
			data["label"] = String(data.get("id", data.get("action", "Back"))).replace("_", " ").capitalize()
		if not data.has("action"):
			data["action"] = String(data.get("id", "close"))
		if not data.has("id"):
			data["id"] = String(data.get("action", "close"))
		return data
	var label := String(raw_button)
	var action := label.to_snake_case()
	return {
		"id": action,
		"label": label if label != "" else "Back",
		"action": action,
	}

func _configure_text_nodes() -> void:
	if _title:
		_title.visible = true
		_title.modulate = Color(1, 1, 1, 1)
		_title.add_theme_color_override("font_color", Color(1, 0.85, 0.35, 1))
		_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		_title.add_theme_constant_override("outline_size", 4)
	if _body:
		_body.visible = true
		_body.modulate = Color(1, 1, 1, 1)
		_body.custom_minimum_size = Vector2(620, 220)
		_body.fit_content = false
		_body.scroll_active = true
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_theme_color_override("default_color", Color(0.92, 0.95, 1, 1))

func _wrap_button_list_for_scrolling() -> void:
	if _button_scroll != null or _buttons == null:
		return
	var parent := _buttons.get_parent()
	if parent == null:
		return
	var index := _buttons.get_index()
	parent.remove_child(_buttons)
	_button_scroll = ScrollContainer.new()
	_button_scroll.name = "ActionButtonScroll"
	_button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_button_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	parent.add_child(_button_scroll)
	parent.move_child(_button_scroll, index)
	_button_scroll.add_child(_buttons)

func _fit_to_viewport(button_count: int) -> void:
	var viewport_size := get_viewport_rect().size
	var panel_width := minf(760.0, viewport_size.x * 0.92)
	var panel_height := minf(620.0, viewport_size.y * 0.86)
	offset_left = -panel_width * 0.5
	offset_right = panel_width * 0.5
	offset_top = -panel_height * 0.5
	offset_bottom = panel_height * 0.5
	var close_height := 42.0
	var title_height := 38.0
	var margins_and_gaps := 104.0
	var button_height := clampf(float(button_count) * 40.0, 44.0, minf(190.0, panel_height * 0.30))
	if _button_scroll:
		_button_scroll.custom_minimum_size = Vector2(panel_width - 64.0, button_height)
		_button_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _body_scroll:
		var body_height := maxf(140.0, panel_height - close_height - title_height - margins_and_gaps - button_height)
		_body_scroll.custom_minimum_size = Vector2(panel_width - 64.0, body_height)
	if _close_button:
		_close_button.custom_minimum_size = Vector2(panel_width - 64.0, 36.0)

func _reset_scroll() -> void:
	if _body_scroll:
		_body_scroll.scroll_vertical = 0
	if _button_scroll:
		_button_scroll.scroll_vertical = 0

func _without_close_buttons(buttons: Array) -> Array:
	var out: Array = []
	for raw_button in buttons:
		var data := _normalize_button_data(raw_button)
		if String(data.get("action", "")) == "close" or String(data.get("label", "")).strip_edges().to_lower() == "close":
			continue
		out.append(data)
	return out
