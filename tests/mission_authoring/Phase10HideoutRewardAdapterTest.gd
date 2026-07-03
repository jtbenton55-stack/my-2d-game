extends GdUnitTestSuite

const HideoutRewardAdapterScript := preload("res://src/hideout/HideoutRewardAdapter.gd")
const HideoutMissionBoardControllerScript := preload("res://src/hideout/HideoutMissionBoardController.gd")
const HideoutStateControllerScript := preload("res://src/hideout/HideoutStateController.gd")


func test_completed_taco_rewards_apply_to_hideout_state() -> void:
	var snapshot := _snapshot_game_state()
	var state := _spawn_state()
	GameState.completed_missions = ["taco_bell_drop"]
	GameState.typed_collectibles.clear()
	GameState.record_typed_collectible("taco_bell_glow_guy", "glow_guy", {"mission_id": "taco_bell_drop"})

	var result: Dictionary = HideoutRewardAdapterScript.apply_completed_mission_rewards_to_state(state, "taco_bell_drop")

	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("hideout_rewards_applied")
	assert_bool(state.taco_bell_completed).is_true()
	assert_bool(state.louis_unlocked).is_true()
	assert_bool(state.sauce_paw_cleanup_available).is_true()
	assert_array(state.unlocked_scheme_cards).contains("louis_delivery_route")
	assert_array(state.available_store_items).contains("taco_bell_stool")
	assert_array(state.available_store_items).contains("suspicious_fry_basket")
	assert_bool(state.get_collectible_state().get("polaroid_taco_bell", {}).get("found", false)).is_true()
	assert_bool(state.get_collectible_state().get("glow_guy_taco_bell", {}).get("found", false)).is_true()
	assert_int(state.case_cash).is_greater_equal(150)

	_restore_game_state(snapshot)
	_free_state(state)


func test_adapter_is_idempotent_for_store_and_card_unlocks() -> void:
	var snapshot := _snapshot_game_state()
	var state := _spawn_state()
	GameState.completed_missions = ["taco_bell_drop"]

	HideoutRewardAdapterScript.apply_completed_mission_rewards_to_state(state, "taco_bell_drop")
	HideoutRewardAdapterScript.apply_completed_mission_rewards_to_state(state, "taco_bell_drop")

	assert_int(_count_value(state.available_store_items, "taco_bell_stool")).is_equal(1)
	assert_int(_count_value(state.unlocked_scheme_cards, "louis_delivery_route")).is_equal(1)

	_restore_game_state(snapshot)
	_free_state(state)


func test_uncompleted_mission_does_not_apply_hideout_rewards() -> void:
	var snapshot := _snapshot_game_state()
	var state := _spawn_state()
	GameState.completed_missions = []

	var result: Dictionary = HideoutRewardAdapterScript.apply_completed_mission_rewards_to_state(state, "taco_bell_drop")

	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("mission_not_completed")
	assert_bool(state.taco_bell_completed).is_false()
	assert_bool(state.louis_unlocked).is_false()
	assert_bool(state.available_store_items.has("taco_bell_stool")).is_false()

	_restore_game_state(snapshot)
	_free_state(state)


func test_completed_rewards_survive_save_load_contract_path() -> void:
	var snapshot := _snapshot_game_state()
	GameState.completed_missions = ["taco_bell_drop"]
	var saved := GameState.to_dict()
	GameState.reset_for_new_game(false)
	GameState.from_dict(saved)

	var state := _spawn_state()
	var result: Dictionary = HideoutRewardAdapterScript.apply_all_completed_rewards_to_state(state)

	assert_bool(result.get("ok", false)).is_true()
	assert_bool(state.taco_bell_completed).is_true()
	assert_bool(state.louis_unlocked).is_true()
	assert_array(state.available_store_items).contains("neon_menu_panel")

	_restore_game_state(snapshot)
	_free_state(state)


func test_dev_taco_completion_shortcut_uses_game_state_completion_path() -> void:
	var snapshot := _snapshot_game_state()
	GameState.completed_missions = []
	var state := _spawn_state()

	var mission_result: Dictionary = GameState.complete_mission("taco_bell_drop")
	var reward_result: Dictionary = HideoutRewardAdapterScript.apply_completed_mission_rewards_to_state(state, "taco_bell_drop")

	assert_bool(mission_result.get("success", false)).is_true()
	assert_array(GameState.completed_missions).contains("taco_bell_drop")
	assert_str(String(reward_result.get("code", ""))).is_equal("hideout_rewards_applied")
	assert_bool(state.taco_bell_completed).is_true()
	assert_bool(state.louis_unlocked).is_true()
	assert_array(state.unlocked_scheme_cards).contains("louis_delivery_route")
	assert_bool(state.sauce_paw_cleanup_available).is_true()

	_restore_game_state(snapshot)
	_free_state(state)


func test_mission_board_exposes_dev_completion_button_only_in_debug_builds() -> void:
	var board := HideoutMissionBoardControllerScript.new()
	add_child(board)
	var state := _spawn_state()
	var buttons: Array = board.get_buttons(state)
	var has_dev_button := _buttons_have_action(buttons, "dev_mark_taco_bell_complete")

	if OS.is_debug_build():
		assert_bool(has_dev_button).is_true()
	else:
		assert_bool(has_dev_button).is_false()

	_free_state(state)
	_free_state(board)


func _spawn_state() -> HideoutStateController:
	var state := HideoutStateControllerScript.new()
	state.name = "Phase10HideoutState"
	add_child(state)
	state.apply_debug_state("fresh")
	return state


func _free_state(state: Node) -> void:
	if is_instance_valid(state):
		state.queue_free()


func _count_value(values: Array, value: String) -> int:
	var count := 0
	for item in values:
		if String(item) == value:
			count += 1
	return count


func _buttons_have_action(buttons: Array, action_id: String) -> bool:
	for button in buttons:
		if button is Dictionary and String((button as Dictionary).get("action", "")) == action_id:
			return true
	return false


func _snapshot_game_state() -> Dictionary:
	return {
		"available_missions": GameState.available_missions.duplicate(),
		"completed_missions": GameState.completed_missions.duplicate(),
		"failed_attempts": GameState.failed_attempts.duplicate(true),
		"unlocked_cards": GameState.unlocked_cards.duplicate(),
		"selected_cards": GameState.selected_cards.duplicate(),
		"collected_polaroids": GameState.collected_polaroids.duplicate(),
		"crew_members": GameState.crew_members.duplicate(),
		"friend_favors": GameState.friend_favors.duplicate(true),
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"intel_points": GameState.intel_points,
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"unlocked_scheme_cards": GameState.unlocked_scheme_cards.duplicate(true),
		"typed_collectibles": GameState.typed_collectibles.duplicate(true),
		"crew_assists": GameState.crew_assists.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
		"mission_alert_states": GameState.mission_alert_states.duplicate(true),
		"poop_bag_count": GameState.poop_bag_count,
		"poop_bag_inventory": GameState.poop_bag_inventory.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.available_missions = _as_string_array(snapshot.get("available_missions", []))
	GameState.completed_missions = _as_string_array(snapshot.get("completed_missions", []))
	GameState.failed_attempts = (snapshot.get("failed_attempts", {}) as Dictionary).duplicate(true)
	GameState.unlocked_cards = _as_string_array(snapshot.get("unlocked_cards", []))
	GameState.selected_cards = _as_string_array(snapshot.get("selected_cards", []))
	GameState.collected_polaroids = _as_string_array(snapshot.get("collected_polaroids", []))
	GameState.crew_members = _as_string_array(snapshot.get("crew_members", []))
	GameState.friend_favors = (snapshot.get("friend_favors", {}) as Dictionary).duplicate(true)
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.intel_points = int(snapshot.get("intel_points", 0))
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.unlocked_scheme_cards = (snapshot.get("unlocked_scheme_cards", {}) as Dictionary).duplicate(true)
	GameState.typed_collectibles = (snapshot.get("typed_collectibles", {}) as Dictionary).duplicate(true)
	GameState.crew_assists = (snapshot.get("crew_assists", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	GameState.mission_alert_states = (snapshot.get("mission_alert_states", {}) as Dictionary).duplicate(true)
	GameState.poop_bag_count = int(snapshot.get("poop_bag_count", 0))
	GameState.poop_bag_inventory = (snapshot.get("poop_bag_inventory", {}) as Dictionary).duplicate(true)


func _as_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out
