extends Area2D

@export var prop_id: String = ""

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	var m := get_tree().current_scene
	if m != null and m.has_method("velvet_prop_interacted"):
		m.velvet_prop_interacted(prop_id)
