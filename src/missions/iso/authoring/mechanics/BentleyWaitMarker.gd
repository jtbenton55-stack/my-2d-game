@tool
class_name BentleyWaitMarker
extends CompanionCommandPoint

@export var success_dialogue_lines: Array[Dictionary] = []


func _init() -> void:
	command_type = "wait"
	command_label = "Bentley wait"
	prompt_text = "Press E: Ask Bentley to wait"
	shape_size = Vector2(96.0, 96.0)
	preview_color = Color(0.35, 0.65, 1.0, 0.35)


func run_command(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result := super.run_command(actor, reason)
	if bool(result.get("ok", false)) and String(result.get("code", "")) == "companion_command_succeeded" and not success_dialogue_lines.is_empty():
		DialogueManager.start_simple_dialogue(success_dialogue_lines)
	return result
