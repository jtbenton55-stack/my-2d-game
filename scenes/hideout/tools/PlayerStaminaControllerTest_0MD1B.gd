extends Node
## Minimal harness: open this scene in editor or run F6; check Output for stamina snapshots.

const PlayerStaminaController := preload("res://src/player/PlayerStaminaController.gd")


func _ready() -> void:
	var c := PlayerStaminaController.new()
	c.reset_stamina()
	print("[0MD1B stamina] ", JSON.stringify(c.get_stamina_snapshot()))
	c.process_frame(0.5, true, true)
	print("[0MD1B stamina] ", JSON.stringify(c.get_stamina_snapshot()))
	c.process_frame(1.0, false, false)
	print("[0MD1B stamina] ", JSON.stringify(c.get_stamina_snapshot()))
