extends Area2D

@export var polaroid_id: String = ""

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	if polaroid_id == "":
		return
	if CollectibleManager.collect_polaroid(polaroid_id):
		AudioManager.play_sfx("collect", global_position)
	queue_free()
