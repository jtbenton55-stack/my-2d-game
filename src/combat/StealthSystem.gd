extends Node

static func can_see(observer: Node2D, target: Node2D, max_distance = 240.0) -> bool:
	if observer == null or target == null:
		return false
	return observer.global_position.distance_to(target.global_position) <= max_distance
