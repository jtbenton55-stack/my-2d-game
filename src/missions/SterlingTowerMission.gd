extends "res://src/levels/LevelBase.gd"

func _ready() -> void:
	mission_id = "sterling_tower_heist"
	objective_text = "Reach Victor Sterling and trigger the final crew payoff."
	super._ready()
	AudioManager.play_music("sterling_tower")
	_spawn_victor()

func _spawn_victor() -> void:
	var scene := preload("res://scenes/characters/VictorSterling.tscn")
	var victor := scene.instantiate()
	add_child(victor)
	victor.global_position = Vector2(520, 260)

func complete_level() -> void:
	if not GameState.dialogue_flags.get("final_line_seen", false):
		GameState.dialogue_flags["final_line_seen"] = true
		DialogueManager.start_simple_dialogue([
			{ "speaker": "Protagonist", "text": "You built an empire out of fear. I built mine out of favors." },
			{ "speaker": "Bentley", "text": "..." },
			{ "speaker": "Narrator", "text": "Friends helping friends. That was the whole job." }
		])
	super.complete_level()
