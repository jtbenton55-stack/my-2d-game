extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var image_rect: TextureRect = $Panel/VBoxContainer/ImageRect
@onready var body_label: Label = $Panel/VBoxContainer/BodyLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var pending_title := ""
var pending_body := ""
var pending_image: Texture2D
var _modal_key_close_ok := false

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	_apply_note()
	close_button.grab_focus()
	call_deferred("_enable_modal_key_close")

func _enable_modal_key_close() -> void:
	_modal_key_close_ok = true

func _input(event: InputEvent) -> void:
	if not _modal_key_close_ok or not is_visible_in_tree():
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		var layer := get_parent()
		if layer is CanvasLayer:
			layer.remove_from_group("blocking_ui")
		queue_free()
		get_viewport().set_input_as_handled()

func set_note(title: String, body: String, image: Texture2D = null) -> void:
	pending_title = title
	pending_body = body
	pending_image = image
	if is_node_ready():
		_apply_note()

func _apply_note() -> void:
	title_label.text = pending_title
	body_label.text = pending_body
	if pending_image != null:
		image_rect.texture = pending_image
		image_rect.show()
	else:
		image_rect.hide()
