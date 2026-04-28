extends Area2D

## Lets the player collect the bag with E (interact) as well as walking into the zone.

func interact(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var mission := _find_mission()
	if mission and mission.has_method("try_collect_bag_from_interact"):
		mission.call("try_collect_bag_from_interact", body)

func _find_mission() -> Node:
	var n: Node = get_parent()
	while n:
		if n.has_method("try_collect_bag_from_interact"):
			return n
		n = n.get_parent()
	return null
