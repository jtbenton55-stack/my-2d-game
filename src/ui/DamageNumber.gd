extends Label

@export var float_distance := 40.0
@export var lifetime := 0.8

func show_damage(amount: int, world_position: Vector2) -> void:
	text = str(amount)
	global_position = world_position
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", world_position + Vector2(0, -float_distance), lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.finished.connect(queue_free)
