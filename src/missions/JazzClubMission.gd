extends "res://src/levels/LevelBase.gd"

func _ready() -> void:
	mission_id = "velvet_paw_jazz_club"
	objective_text = "Find the hidden ledger and exit through the backstage door."
	super._ready()
	AudioManager.play_music("velvet_paw_jazz")
	_spawn_story_enemies(2)

func _spawn_story_enemies(count: int) -> void:
	var scene := preload("res://scenes/characters/goon.tscn")
	for i in range(count):
		var enemy := scene.instantiate()
		add_child(enemy)
		enemy.global_position = Vector2(260 + i * 180, 280)
