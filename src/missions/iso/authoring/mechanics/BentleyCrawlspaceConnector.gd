@tool
class_name BentleyCrawlspaceConnector
extends CompanionCommandPoint


func _init() -> void:
	command_type = "crawlspace"
	command_label = "Bentley crawlspace"
	prompt_text = "Press E: Send Bentley through"
	shape_size = Vector2(112.0, 112.0)
	preview_color = Color(0.25, 0.85, 0.9, 0.35)
