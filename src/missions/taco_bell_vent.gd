extends Area2D
## Service garage vent — Bentley can squeeze through and fetch the booth keycard.

func _ready() -> void:
	add_to_group("interactable")


func interact(_player: Node) -> void:
	var m := _find_mission()
	if m and m.has_method("try_vent_unlock"):
		m.try_vent_unlock(self)


func _find_mission() -> Node:
	var n: Node = get_parent()
	while n:
		if n.has_method("try_vent_unlock"):
			return n
		n = n.get_parent()
	var cs := get_tree().current_scene
	if cs and cs.has_method("try_vent_unlock"):
		return cs
	return null
