extends Button

func set_mission(mission_id: String, mission_data: Dictionary) -> void:
	name = mission_id
	
	var display_name = mission_data.get("name", mission_id)
	var is_completed = GameState.has_completed(mission_id)
	var prefix = "[DONE] " if is_completed else ""
	
	text = prefix + display_name
	tooltip_text = mission_data.get("description", "")
	
	if is_completed:
		modulate = Color(0.6, 0.8, 0.6, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
