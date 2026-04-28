extends "res://src/levels/LevelBase.gd"

func _ready() -> void:
	mission_id = "rewrite_room"
	objective_text = "Recover the chain-of-title proof and escape."
	super._ready()
	AudioManager.play_music("corporate_thriller")
	if GameState.has_selected_card("mere_legal_eyes"):
		QuestManager.set_objective("Mere highlights the safest document: Chain-of-title memo.", mission_id)
