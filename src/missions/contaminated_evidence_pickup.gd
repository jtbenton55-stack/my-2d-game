extends Area2D
## Optional Mission Bible beat: spend one poop bag to recover contaminated intel safely.

func _ready() -> void:
	add_to_group("interactable")


func interact(_player: Node) -> void:
	if GameState.try_consume_poop_bag():
		GameState.intel_points += 1
		EventBus.objective_updated.emit("Poop bag secured contaminated route slip — +1 intel. Bentley is personally offended.")
		AudioManager.play_sfx("item_pickup", global_position)
		queue_free()
	else:
		DialogueManager.show_dialogue("Parmida", "I need a clean pickup — maybe one of Bentley's bags — before I touch this.")
