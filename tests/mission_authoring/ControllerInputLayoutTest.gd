extends GdUnitTestSuite

const PLAYER_SCENE := preload("res://scenes/characters/player.tscn")
const DOG_SCENE := preload("res://scenes/characters/dog.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const InputBindingFormatterScript := preload("res://src/utils/InputBindingFormatter.gd")


func after() -> void:
	for action: StringName in [&"aim_left", &"aim_right", &"aim_up", &"aim_down", &"bentley_toggle_stay"]:
		Input.action_release(action)
	get_tree().paused = false
	if DialogueManager.is_in_dialogue:
		DialogueManager.end_dialogue()


func test_gamesir_xbox_layout_is_exact() -> void:
	assert_array(_joy_buttons(&"interact")).is_equal([JOY_BUTTON_A])
	assert_array(_joy_buttons(&"ui_accept")).is_equal([JOY_BUTTON_A])
	assert_array(_joy_buttons(&"ui_cancel")).is_equal([JOY_BUTTON_B])
	assert_array(_joy_buttons(&"dodge")).is_equal([JOY_BUTTON_B])
	assert_array(_joy_buttons(&"poop_bag_targeting")).is_equal([JOY_BUTTON_X])
	assert_array(_joy_buttons(&"finisher")).is_equal([JOY_BUTTON_Y])
	assert_array(_joy_buttons(&"sprint")).is_equal([JOY_BUTTON_LEFT_SHOULDER])
	assert_array(_joy_buttons(&"heavy")).is_equal([JOY_BUTTON_RIGHT_SHOULDER])
	assert_array(_joy_buttons(&"case_the_joint")).is_equal([JOY_BUTTON_RIGHT_STICK])
	assert_array(_joy_buttons(&"pause")).is_equal([JOY_BUTTON_START])
	assert_array(_joy_buttons(&"bentley_bark")).is_equal([JOY_BUTTON_DPAD_LEFT])
	assert_array(_joy_buttons(&"bentley_sniff")).is_equal([JOY_BUTTON_DPAD_UP])
	assert_array(_joy_buttons(&"bentley_fetch")).is_equal([JOY_BUTTON_DPAD_RIGHT])
	assert_array(_joy_buttons(&"bentley_toggle_stay")).is_equal([JOY_BUTTON_DPAD_DOWN])
	assert_array(_joy_buttons(&"bentley_ability")).is_empty()
	assert_array(_joy_axes(&"attack")).is_equal([[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	assert_array(_joy_axes(&"stealth")).is_equal([[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	assert_array(_joy_axes(&"aim_left")).is_equal([[JOY_AXIS_RIGHT_X, -1.0]])
	assert_array(_joy_axes(&"aim_right")).is_equal([[JOY_AXIS_RIGHT_X, 1.0]])
	assert_array(_joy_axes(&"aim_up")).is_equal([[JOY_AXIS_RIGHT_Y, -1.0]])
	assert_array(_joy_axes(&"aim_down")).is_equal([[JOY_AXIS_RIGHT_Y, 1.0]])
	var a_event := InputEventJoypadButton.new()
	a_event.button_index = JOY_BUTTON_A
	a_event.pressed = true
	assert_bool(a_event.is_action_pressed("ui_accept")).is_true()
	var enter_event := InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	enter_event.pressed = true
	assert_bool(enter_event.is_action_pressed("ui_accept")).is_true()
	var space_event := InputEventKey.new()
	space_event.keycode = KEY_SPACE
	space_event.pressed = true
	assert_bool(space_event.is_action_pressed("ui_accept")).is_true()


func test_semantic_binding_labels_are_player_facing() -> void:
	assert_str(InputBindingFormatterScript.action_summary(&"interact", "E")).is_equal("A / E")
	assert_str(InputBindingFormatterScript.action_summary(&"attack", "J")).is_equal("RT / J / Mouse Left")
	assert_str(InputBindingFormatterScript.action_summary(&"heavy", "Mouse Right")).is_equal("RB / Mouse Right")
	assert_str(InputBindingFormatterScript.action_summary(&"bentley_sniff", "2")).is_equal("D-pad Up / 2")
	assert_str(InputBindingFormatterScript.format_interact_prompt("Press E: Open")).is_equal("Press A / E: Open")


func test_right_bumper_dispatches_the_existing_heavy_attack() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	var combat := player.get_node("PlayerCombatController")
	var rb_event := InputEventJoypadButton.new()
	rb_event.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb_event.pressed = true
	assert_bool(rb_event.is_action_pressed("heavy")).is_true()
	combat.call("_unhandled_input", rb_event)
	assert_bool(bool(combat.get("_busy"))).is_true()
	assert_str(String(combat.get("last_attack_kind"))).is_equal("heavy")
	await get_tree().create_timer(0.75).timeout
	assert_bool(bool(combat.get("_busy"))).is_false()
	assert_float(float(combat.get("current_style"))).is_greater(0.0)
	player.queue_free()
	await get_tree().process_frame


func test_controller_poop_bag_targeting_aims_throws_and_cancels() -> void:
	var original_scene := get_tree().current_scene
	var original_count := GameState.poop_bag_count
	var original_inventory := GameState.poop_bag_inventory.duplicate(true)
	var surface := ToolSurface.new()
	get_tree().root.add_child(surface)
	get_tree().current_scene = surface
	var player := PLAYER_SCENE.instantiate()
	surface.add_child(player)
	await get_tree().process_frame
	GameState.poop_bag_count = 1
	GameState.poop_bag_inventory["count"] = 1

	var x_event := InputEventJoypadButton.new()
	x_event.button_index = JOY_BUTTON_X
	x_event.pressed = true
	player.call("_unhandled_input", x_event)
	assert_bool(player.call("is_poop_bag_targeting")).is_true()
	assert_bool(bool((player.call("get_poop_bag_targeting_debug") as Dictionary).get("reticle_visible", false))).is_true()

	Input.action_press(&"aim_right", 1.0)
	player.call("_update_poop_bag_controller_aim")
	Input.action_release(&"aim_right")
	var target_position: Vector2 = (player.call("get_poop_bag_targeting_debug") as Dictionary).get("target_position", Vector2.ZERO)
	assert_float(target_position.x).is_greater(player.global_position.x)
	assert_float(player.global_position.distance_to(target_position)).is_less_equal(player.poop_throw_range)

	var rt_event := InputEventJoypadMotion.new()
	rt_event.axis = JOY_AXIS_TRIGGER_RIGHT
	rt_event.axis_value = 1.0
	assert_bool(rt_event.is_action_pressed("attack")).is_true()
	player.call("_unhandled_input", rt_event)
	assert_bool(player.call("is_poop_bag_targeting")).is_false()
	assert_int(GameState.poop_bag_count).is_equal(0)
	assert_vector(surface.last_deploy_position).is_equal(target_position)

	GameState.poop_bag_count = 1
	GameState.poop_bag_inventory["count"] = 1
	player.call("_unhandled_input", x_event)
	var b_event := InputEventJoypadButton.new()
	b_event.button_index = JOY_BUTTON_B
	b_event.pressed = true
	assert_bool(b_event.is_action_pressed("ui_cancel")).is_true()
	player.call("_unhandled_input", b_event)
	assert_bool(player.call("is_poop_bag_targeting")).is_false()
	assert_int(GameState.poop_bag_count).is_equal(1)

	get_tree().current_scene = original_scene
	surface.queue_free()
	await get_tree().process_frame
	GameState.poop_bag_count = original_count
	GameState.poop_bag_inventory = original_inventory


func test_contextual_controller_feedback_survives_hud_refresh() -> void:
	var original_mission_id := GameState.current_mission_id
	var original_in_mission := GameState.is_in_mission
	GameState.current_mission_id = "controller_feedback_test"
	GameState.is_in_mission = true
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	await get_tree().process_frame
	var objective_label := hud.get_node("ObjectiveLabel") as Label
	hud.call("_on_objective_updated", "No poop bags. Pick one up before targeting.")
	hud.call("_refresh_mission_compact_hud")
	assert_str(objective_label.text).contains("No poop bags")
	hud.set("_objective_feedback_until_msec", 0)
	hud.call("_refresh_mission_compact_hud")
	assert_bool(objective_label.text.contains("No poop bags")).is_false()
	hud.queue_free()
	await get_tree().process_frame
	GameState.current_mission_id = original_mission_id
	GameState.is_in_mission = original_in_mission


func test_bentley_dpad_commands_ignore_blocking_ui() -> void:
	var dog := DOG_SCENE.instantiate()
	add_child(dog)
	await get_tree().process_frame
	dog.set_physics_process(false)
	var blocker := Node.new()
	blocker.add_to_group("blocking_ui")
	add_child(blocker)
	Input.action_press(&"bentley_toggle_stay")
	dog.call("_handle_commands")
	Input.action_release(&"bentley_toggle_stay")
	assert_bool(bool((dog.call("get_command_state") as Dictionary).get("staying", false))).is_false()
	blocker.queue_free()
	await get_tree().process_frame
	Input.action_press(&"bentley_toggle_stay")
	dog.call("_handle_commands")
	Input.action_release(&"bentley_toggle_stay")
	assert_bool(bool((dog.call("get_command_state") as Dictionary).get("staying", false))).is_true()
	dog.queue_free()
	await get_tree().process_frame


func _joy_buttons(action: StringName) -> Array[int]:
	var buttons: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append((event as InputEventJoypadButton).button_index)
	return buttons


func _joy_axes(action: StringName) -> Array:
	var axes: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			axes.append([motion.axis, motion.axis_value])
	return axes


class ToolSurface:
	extends Node2D

	var last_deploy_position := Vector2.ZERO

	func supports_tool(tool_id: String) -> bool:
		return tool_id == "poop_bag"

	func handle_tool_use(tool_id: String, payload: Dictionary = {}) -> Dictionary:
		last_deploy_position = payload.get("world_pos", Vector2.ZERO)
		return {"ok": tool_id == "poop_bag", "handled": true, "reason": ""}
