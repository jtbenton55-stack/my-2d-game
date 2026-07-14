class_name InputBindingFormatter
extends RefCounted


static func action_summary(action_name: StringName, fallback: String = "") -> String:
	if not InputMap.has_action(action_name):
		return fallback
	var controller_labels: Array[String] = []
	var other_labels: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action_name):
		var label := event_label(event)
		if label == "":
			continue
		var labels := controller_labels if event is InputEventJoypadButton or event is InputEventJoypadMotion else other_labels
		if not labels.has(label):
			labels.append(label)
	var labels: Array[String] = []
	labels.append_array(controller_labels)
	labels.append_array(other_labels)
	return " / ".join(labels) if not labels.is_empty() else fallback


static func format_interact_prompt(text: String) -> String:
	var binding := action_summary(&"interact", "E")
	return text.replace("Press E", "Press %s" % binding).replace("[E]", "[%s]" % binding)


static func event_label(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return joypad_button_label((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return joypad_axis_label(motion.axis, motion.axis_value)
	if event is InputEventKey:
		var key := event as InputEventKey
		return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != 0 else key.keycode)
	if event is InputEventMouseButton:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			_:
				return "Mouse %d" % (event as InputEventMouseButton).button_index
	return ""


static func joypad_button_label(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_BACK:
			return "View"
		JOY_BUTTON_GUIDE:
			return "Xbox"
		JOY_BUTTON_START:
			return "Menu"
		JOY_BUTTON_LEFT_STICK:
			return "L3"
		JOY_BUTTON_RIGHT_STICK:
			return "R3"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB"
		JOY_BUTTON_DPAD_UP:
			return "D-pad Up"
		JOY_BUTTON_DPAD_DOWN:
			return "D-pad Down"
		JOY_BUTTON_DPAD_LEFT:
			return "D-pad Left"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-pad Right"
		_:
			return "Button %d" % button_index


static func joypad_axis_label(axis: int, axis_value: float) -> String:
	var direction := "-" if axis_value < 0.0 else "+"
	match axis:
		JOY_AXIS_LEFT_X:
			return "Left Stick Left" if axis_value < 0.0 else "Left Stick Right"
		JOY_AXIS_LEFT_Y:
			return "Left Stick Up" if axis_value < 0.0 else "Left Stick Down"
		JOY_AXIS_RIGHT_X:
			return "Right Stick Left" if axis_value < 0.0 else "Right Stick Right"
		JOY_AXIS_RIGHT_Y:
			return "Right Stick Up" if axis_value < 0.0 else "Right Stick Down"
		JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
		_:
			return "Axis %d%s" % [axis, direction]
