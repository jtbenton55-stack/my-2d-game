extends Area2D

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	var m := get_tree().current_scene
	if m != null and m.has_method("try_enter_owner_suite"):
		m.call("try_enter_owner_suite")
