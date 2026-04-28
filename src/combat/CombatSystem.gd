extends Node

static func apply_damage(target: Node, amount: int, source: Node = null) -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(amount, source)

static func find_enemies_in_radius(tree: SceneTree, origin: Vector2, radius: float) -> Array:
	var out: Array = []
	for enemy in tree.get_nodes_in_group("enemy"):
		if enemy is Node2D and origin.distance_to(enemy.global_position) <= radius:
			out.append(enemy)
	return out
