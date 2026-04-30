extends Area2D

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	var mission := get_tree().current_scene
	if mission and mission.has_method("start_music_puzzle"):
		mission.start_music_puzzle()
