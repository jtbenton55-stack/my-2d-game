@tool
class_name DistractionObject
extends "res://src/missions/iso/runtime/noise/NoiseEmitterNode.gd"


func _init() -> void:
	noise_id = &"distraction_noise"
	noise_kind = "decoy"
	noise_team = "player"
	noise_radius = 220.0
	noise_strength = 0.75
	prompt_text = "Press E: Create distraction"
	display_name = "Distraction Object"
	preview_color = Color(0.2, 0.9, 1.0, 0.35)
