@tool
class_name BentleyWaitMarker
extends CompanionCommandPoint


func _init() -> void:
	command_type = "wait"
	command_label = "Bentley wait"
	prompt_text = "Press E: Ask Bentley to wait"
	shape_size = Vector2(96.0, 96.0)
	preview_color = Color(0.35, 0.65, 1.0, 0.35)
