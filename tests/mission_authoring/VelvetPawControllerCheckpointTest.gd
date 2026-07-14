extends GdUnitTestSuite

const MISSION_SCENE := preload("res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn")
const PAUSE_SCENE := preload("res://src/ui/test_ui/pause_menu.tscn")
const MARKER_PATH := "GameplayRoot/MissionMechanics/BentleyWaitMarker_velvet_paw_jazz_club_bentley_wait_marker_01"
const BRIDGE_PATH := "GameplayRoot/RuntimeHelpers/MissionInteractionBridge"
const PLAYER_PATH := "EntityRoot/Player"


func before() -> void:
	get_tree().paused = false
	if DialogueManager.is_in_dialogue:
		DialogueManager.end_dialogue()


func after() -> void:
	get_tree().paused = false
	if DialogueManager.is_in_dialogue:
		DialogueManager.end_dialogue()
	GameState.current_mission_id = ""
	GameState.is_in_mission = false


func test_start_and_a_use_pause_and_interact_actions() -> void:
	assert_bool(_action_has_joypad_button(&"pause", 6)).is_true()
	assert_bool(_action_has_joypad_button(&"interact", 0)).is_true()
	assert_bool(_action_has_joypad_button(&"bentley_toggle_stay", 0)).is_false()


func test_start_toggles_mission_pause_but_hidden_cancel_does_not_open_it() -> void:
	var menu := PAUSE_SCENE.instantiate()
	add_child(menu)
	await get_tree().process_frame
	var cancel_event := _action_event(&"ui_cancel")
	menu.call("_unhandled_input", cancel_event)
	assert_bool(menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()

	var pause_event := _action_event(&"pause")
	menu.call("_unhandled_input", pause_event)
	assert_bool(menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool((menu.get_node("Overlay/CenterContainer/VBoxContainer/ResumeButton") as Button).has_focus()).is_true()

	menu.call("_unhandled_input", pause_event)
	assert_bool(menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()

	menu.call("_unhandled_input", pause_event)
	assert_bool(get_tree().paused).is_true()
	menu.call("_toggle_info_panel", "controls")
	var info_panel := menu.get("info_panel") as Panel
	assert_bool(info_panel.visible).is_true()
	menu.call("_unhandled_input", cancel_event)
	assert_bool(info_panel.visible).is_false()
	assert_bool(menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	menu.call("_unhandled_input", cancel_event)
	assert_bool(menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()
	menu.queue_free()
	await get_tree().process_frame


func test_controller_a_routes_through_production_bridge_to_exact_bentley_marker() -> void:
	var mission := MISSION_SCENE.instantiate()
	add_child(mission)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var marker := mission.get_node(MARKER_PATH) as Node2D
	var bridge := mission.get_node(BRIDGE_PATH)
	var player := mission.get_node(PLAYER_PATH) as CharacterBody2D
	var bentley := _mission_bentley(mission)
	assert_object(bentley).is_not_null()
	player.global_position = marker.global_position
	var a_event := InputEventJoypadButton.new()
	a_event.button_index = 0
	a_event.pressed = true
	assert_bool(a_event.is_action_pressed("interact")).is_true()
	bridge.call("_input", a_event)
	var state: Dictionary = bentley.call("get_command_state")
	assert_object(bridge.get("last_candidate")).is_same(marker)
	assert_bool(bool(state.get("staying", false))).is_true()
	assert_str(String(state.get("wait_marker_id", ""))).is_equal(String(marker.get("mechanic_id")))
	assert_vector(Vector2(state.get("wait_marker_position", Vector2.ZERO))).is_equal(marker.global_position)
	assert_vector(bentley.global_position).is_equal(marker.global_position)
	mission.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame


func _action_has_joypad_button(action: StringName, button_index: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return true
	return false


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _mission_bentley(mission: Node) -> Node2D:
	for node: Node in get_tree().get_nodes_in_group("bentley"):
		if mission.is_ancestor_of(node):
			return node as Node2D
	return null
