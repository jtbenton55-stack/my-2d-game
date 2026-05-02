extends Area2D

func _ready() -> void:
	add_to_group("interactable")


func interact(_player: Node) -> void:
	var m := get_tree().current_scene
	if m and m.has_method("try_yordano_basement_interact"):
		m.try_yordano_basement_interact()
