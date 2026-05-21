# GdUnit4 smoke tests for Packet 2A mission completion bridge.
extends GdUnitTestSuite

const MissionCompletionBridgeScript := preload("res://src/missions/iso/authoring/core/MissionCompletionBridge.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")


func test_request_complete_uses_game_state_fallback() -> void:
	var snapshot := _snapshot_game_state()
	var result: Dictionary = MissionCompletionBridgeScript.request_complete("test_mission")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(bool(GameState.last_mission_result.get("success", false))).is_true()
	assert_str(String(GameState.last_mission_result.get("mission_id", ""))).is_equal("test_mission")
	_restore_game_state(snapshot)


func test_request_fail_uses_game_state_fallback() -> void:
	var snapshot := _snapshot_game_state()
	var result: Dictionary = MissionCompletionBridgeScript.request_fail("test_mission", "test reason")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(bool(GameState.last_mission_result.get("success", true))).is_false()
	assert_str(String(GameState.last_mission_result.get("mission_id", ""))).is_equal("test_mission")
	_restore_game_state(snapshot)


func test_missing_mission_id_fails_cleanly() -> void:
	var snapshot := _snapshot_game_state()
	GameState.current_mission_id = ""
	GameState.pending_mission_id = ""
	var result: Dictionary = MissionCompletionBridgeScript.request_complete("")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("mission_id_missing")
	_restore_game_state(snapshot)


func test_request_mission_fail_effect_routes_through_applier() -> void:
	var snapshot := _snapshot_game_state()
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.REQUEST_MISSION_FAIL
	effect.key = "test_mission"
	effect.value_type = "string"
	effect.value_string = "effect requested failure"
	var result: Dictionary = effect.apply({})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(bool(GameState.last_mission_result.get("success", true))).is_false()
	assert_str(String(GameState.last_mission_result.get("mission_id", ""))).is_equal("test_mission")
	_restore_game_state(snapshot)


func _snapshot_game_state() -> Dictionary:
	return {
		"is_in_mission": GameState.is_in_mission,
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"completed_missions": GameState.completed_missions.duplicate(),
		"failed_attempts": GameState.failed_attempts.duplicate(true),
		"unlocked_cards": GameState.unlocked_cards.duplicate(),
		"selected_cards": GameState.selected_cards.duplicate(),
		"crew_members": GameState.crew_members.duplicate(),
		"friend_favors": GameState.friend_favors.duplicate(true),
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"intel_points": GameState.intel_points,
		"player_max_health": GameState.player_max_health,
		"player_health": GameState.player_health,
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"mission_mutation_state": GameState.mission_mutation_state.duplicate(true),
		"mission_heat_states": GameState.mission_heat_states.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
		"mission_alert_states": GameState.mission_alert_states.duplicate(true),
		"poop_bag_count": GameState.poop_bag_count,
		"poop_bags_this_mission_attempt": GameState.poop_bags_this_mission_attempt,
		"poop_bag_inventory": GameState.poop_bag_inventory.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	_restore_string_array(GameState.completed_missions, snapshot.get("completed_missions", []))
	_restore_string_array(GameState.unlocked_cards, snapshot.get("unlocked_cards", []))
	_restore_string_array(GameState.selected_cards, snapshot.get("selected_cards", []))
	_restore_string_array(GameState.crew_members, snapshot.get("crew_members", []))
	GameState.failed_attempts = (snapshot.get("failed_attempts", {}) as Dictionary).duplicate(true)
	GameState.friend_favors = (snapshot.get("friend_favors", {}) as Dictionary).duplicate(true)
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.intel_points = int(snapshot.get("intel_points", 0))
	GameState.player_max_health = int(snapshot.get("player_max_health", 100))
	GameState.player_health = int(snapshot.get("player_health", GameState.player_max_health))
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.mission_mutation_state = (snapshot.get("mission_mutation_state", {}) as Dictionary).duplicate(true)
	GameState.mission_heat_states = (snapshot.get("mission_heat_states", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	GameState.mission_alert_states = (snapshot.get("mission_alert_states", {}) as Dictionary).duplicate(true)
	GameState.poop_bag_count = int(snapshot.get("poop_bag_count", 0))
	GameState.poop_bags_this_mission_attempt = int(snapshot.get("poop_bags_this_mission_attempt", 0))
	GameState.poop_bag_inventory = (snapshot.get("poop_bag_inventory", {}) as Dictionary).duplicate(true)


func _restore_string_array(target: Array[String], previous: Variant) -> void:
	target.clear()
	if previous is Array:
		for item in previous:
			target.append(String(item))
