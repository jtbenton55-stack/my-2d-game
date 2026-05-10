extends Node
## 0M-D2A: Print sprint input map + PlayerStaminaController.is_sprint_requested() (run scene F6).


func _ready() -> void:
	const PSC := preload("res://src/player/PlayerStaminaController.gd")
	print("=== 0M-D2A PlayerSprintInputTest ===")
	print("InputMap.has_action(sprint)=", InputMap.has_action("sprint"))
	if InputMap.has_action("sprint"):
		var evs := InputMap.action_get_events("sprint")
		print("sprint event count=", evs.size())
		for i in range(evs.size()):
			var ev := evs[i]
			if ev is InputEventKey:
				var k := ev as InputEventKey
				print("  [", i, "] InputEventKey physical_keycode=", k.physical_keycode, " unicode=", k.unicode)
	var c := PSC.new()
	c.reset_stamina()
	print("sprint_action_name=", c.sprint_action_name, " alternates=", c.alternate_sprint_action_names)
	print("is_sprint_requested()=", c.is_sprint_requested(), " (depends on live input)")
	print("can_sprint()=", c.can_sprint())
	print("get_speed_multiplier (idle)=", c.get_speed_multiplier())
	c.process_frame(0.25, c.is_sprint_requested(), true)
	print("snapshot after 0.25s moving+request=", JSON.stringify(c.get_stamina_snapshot()))
