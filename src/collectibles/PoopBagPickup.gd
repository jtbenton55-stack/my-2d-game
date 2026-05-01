extends Area2D
## Mission Bible: Bentley poop bag pickup — increments global inventory and per-run count for Responsible Crime Lord bonus.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_poop_bag()
	AudioManager.play_sfx("item_pickup", global_position)
	EventBus.objective_updated.emit("+1 Bentley poop bag. Bentley pretends he didn't notice.")
	queue_free()
