extends Node
## Run F6: verifies sprint action exists + stamina controller behavior (no animation).


func _ready() -> void:
	const PSC := preload("res://src/player/PlayerStaminaController.gd")
	var has_sprint := InputMap.has_action("sprint")
	print("[0MD2 sprint] InputMap.has_action(sprint)=", has_sprint)
	var c := PSC.new()
	c.reset_stamina()
	var snap0 := c.get_stamina_snapshot()
	c.process_frame(0.5, true, true)
	var snap1 := c.get_stamina_snapshot()
	c.process_frame(2.0, false, true)
	var snap2 := c.get_stamina_snapshot()
	print("[0MD2 stamina] t0 ", JSON.stringify(snap0))
	print("[0MD2 stamina] sprinting ", JSON.stringify(snap1))
	print("[0MD2 stamina] regen ", JSON.stringify(snap2))
