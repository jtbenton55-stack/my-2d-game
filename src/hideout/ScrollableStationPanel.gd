extends PanelContainer
class_name ScrollableStationPanel

signal action_pressed(action_id: String)
signal panel_action_pressed(action_id: String, payload: Dictionary)
signal closed

@onready var _title: Label = $MarginContainer/VBoxContainer/Title
@onready var _body: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/Body
@onready var _buttons: VBoxContainer = $MarginContainer/VBoxContainer/ActionButtons

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_configure_text_nodes()
	hide()
	if has_node("MarginContainer/VBoxContainer/CloseButton"):
		$MarginContainer/VBoxContainer/CloseButton.pressed.connect(close_panel)

func open_panel(title: String, body: String, buttons: Array = []) -> void:
	_title.text = title if title.strip_edges() != "" else "Hideout Station"
	_body.text = body if body.strip_edges() != "" else "This station is wired, but its text has not been filled in yet."
	_configure_text_nodes()
	_build_buttons(buttons)
	add_to_group("blocking_ui")
	show()
	print("[ScrollableStationPanel] Opened: " + _title.text)
	grab_focus()

func close() -> void:
	close_panel()

func close_panel() -> void:
	hide()
	remove_from_group("blocking_ui")
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
		var button := Button.new()
		button.text = String(button_data.get("label", "Back"))
		button.custom_minimum_size = Vector2(220, 34)
		var action_id := String(button_data.get("action", "close"))
		button.pressed.connect(func() -> void:
			action_pressed.emit(action_id)
			panel_action_pressed.emit(action_id, button_data)
			if action_id == "back" or action_id == "close":
				close_panel()
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
	if action == "back":
		action = "close"
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
		_body.custom_minimum_size = Vector2(620, 420)
		_body.fit_content = true
		_body.scroll_active = false
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_theme_color_override("default_color", Color(0.92, 0.95, 1, 1))
