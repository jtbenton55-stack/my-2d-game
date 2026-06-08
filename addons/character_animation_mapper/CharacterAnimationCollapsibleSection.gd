@tool
extends VBoxContainer

var _toggle: Button
var _content: VBoxContainer
var _title: String = ""
var _expanded: bool = true


func setup(title: String, expanded: bool = true) -> void:
	_title = title
	_expanded = expanded
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle = Button.new()
	_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_toggle.flat = true
	_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle.pressed.connect(_on_toggle_pressed)
	add_child(_toggle)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_content)
	_apply_expanded_state()


func get_content() -> VBoxContainer:
	return _content


func set_expanded(expanded: bool) -> void:
	_expanded = expanded
	_apply_expanded_state()


func _on_toggle_pressed() -> void:
	_expanded = not _expanded
	_apply_expanded_state()


func _apply_expanded_state() -> void:
	if _content:
		_content.visible = _expanded
	if _toggle:
		_toggle.text = ("%s %s" % ["▼" if _expanded else "▶", _title])
