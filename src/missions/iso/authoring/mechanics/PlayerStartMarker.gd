@tool
class_name PlayerStartMarker
extends Marker2D

@export var marker_type: StringName = &"PLAYER_SPAWN"
@export var marker_id: StringName = &"start_main"
@export var group_id: StringName = &"spawns"
@export var show_label: bool = true

var _label: Label = null


func _ready() -> void:
	add_to_group("mission_authoring_marker")
	if Engine.is_editor_hint():
		_ensure_label()
		_refresh_label()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_ensure_label()
		_refresh_label()


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)


func _refresh_label() -> void:
	if _label == null:
		return
	_label.visible = show_label
	_label.text = "Player Start: %s" % String(marker_id)
	_label.position = Vector2(-80.0, -36.0)
	_label.size = Vector2(160.0, 22.0)
