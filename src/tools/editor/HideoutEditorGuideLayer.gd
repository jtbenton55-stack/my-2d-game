@tool
extends Node2D
class_name HideoutEditorGuideLayer

@export var visible_in_editor := true
@export var hide_on_play := true


func _ready() -> void:
	if Engine.is_editor_hint():
		visible = visible_in_editor
	elif hide_on_play:
		visible = false
