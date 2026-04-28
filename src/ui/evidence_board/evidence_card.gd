extends Control

signal card_clicked(card: Control)

var _title := "Evidence"
var _description := "A clue from the city."
var _highlight := false
var title: String:
	get:
		return _title
	set(value):
		_title = value
		_refresh()
var description: String:
	get:
		return _description
	set(value):
		_description = value
		_refresh()
var highlight := false:
	get:
		return _highlight
	set(value):
		_highlight = value
		modulate = Color(1.25, 1.15, 1.55, 1.0) if _highlight else Color.WHITE

var is_dragging := false
var drag_offset := Vector2.ZERO
var board: Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel

func _ready() -> void:
	_refresh()

func setup(parent: Control, card_title := "Evidence", card_description := "A clue from the city.") -> void:
	board = parent
	title = card_title
	description = card_description

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			card_clicked.emit(self)
		else:
			is_dragging = false
	elif is_dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - drag_offset
		_clamp_to_board()

func _clamp_to_board() -> void:
	if board == null:
		return
	var local := board.get_global_transform().affine_inverse() * global_position
	local.x = clamp(local.x, 0.0, max(0.0, board.size.x - size.x))
	local.y = clamp(local.y, 0.0, max(0.0, board.size.y - size.y))
	position = local

func _refresh() -> void:
	if not is_node_ready():
		return
	title_label.text = _title
	description_label.text = _description
