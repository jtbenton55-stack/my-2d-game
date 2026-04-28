extends "res://src/levels/LevelBase.gd"

func _ready() -> void:
	mission_id = "fast_family_getaway"
	objective_text = "Survive the getaway and hit the exit marker."
	super._ready()
	AudioManager.play_music("rainy_getaway")
	if GameState.has_selected_card("doms_getaway_keys"):
		QuestManager.set_objective("Dom found a cleaner route. Reach the exit.", mission_id)
