extends GdUnitTestSuite

const MissionHudDataProviderScript := preload("res://src/missions/ui/MissionHudDataProvider.gd")
const MissionPauseDataProviderScript := preload("res://src/missions/ui/MissionPauseDataProvider.gd")


func test_taco_success_posts_first_sterling_clue_and_result_status() -> void:
	var game_snapshot := _snapshot_game_state()
	GameState.current_mission_id = "taco_bell_drop"
	GameState.is_in_mission = true
	GameState.poop_bag_count = 2
	GameState.poop_bags_this_mission_attempt = 2
	GameState.poop_bag_inventory = {"count": 2, "collected_this_mission": 2, "used_this_mission": 0}

	var result: Dictionary = GameState.complete_mission("taco_bell_drop")

	assert_bool(result.get("success", false)).is_true()
	assert_bool(GameState.sterling_clues.has(GameState.TACO_SUCCESS_STERLING_CLUE_ID)).is_true()
	assert_bool(bool(GameState.sterling_clues[GameState.TACO_SUCCESS_STERLING_CLUE_ID].get("discovered", false))).is_true()
	assert_bool(GameState.evidence_clues.has(GameState.TACO_SUCCESS_STERLING_CLUE_ID)).is_true()
	assert_array(Array(result.get("evidence_clues", []))).is_not_empty()
	assert_str(String(result.get("continue_label", ""))).is_equal("Return to Hideout")
	var poop_status: Dictionary = result.get("poop_bag_status", {}) as Dictionary
	assert_int(int(poop_status.get("target", 0))).is_equal(3)
	assert_int(int(poop_status.get("collected_this_attempt", 0))).is_equal(2)
	assert_bool(bool(poop_status.get("complete", true))).is_false()

	_restore_game_state(game_snapshot)


func test_pause_provider_marks_taco_next_objective() -> void:
	var quest_snapshot := _snapshot_quest_manager()
	QuestManager.active_quest_id = "taco_bell_drop"
	QuestManager.active_objective = "Recover the delivery bag."
	QuestManager.objectives = {"taco_bell_drop": "Recover the delivery bag."}
	QuestManager.objective_records = {
		"taco_bell_drop": {
			"recover_delivery_bag": {"id": "recover_delivery_bag", "text": "Recover the delivery bag.", "status": "active", "mission_id": "taco_bell_drop"},
			"open_garage_code_gate": {"id": "open_garage_code_gate", "text": "Open the garage code gate.", "status": "active", "mission_id": "taco_bell_drop"},
		}
	}
	QuestManager.active_objectives = {
		"taco_bell_drop": {
			"recover_delivery_bag": {"id": "recover_delivery_bag", "text": "Recover the delivery bag.", "status": "active", "mission_id": "taco_bell_drop"},
			"open_garage_code_gate": {"id": "open_garage_code_gate", "text": "Open the garage code gate.", "status": "active", "mission_id": "taco_bell_drop"},
		}
	}
	QuestManager.completed_objectives = {}

	var snap: Dictionary = MissionPauseDataProviderScript.get_objective_snapshot("taco_bell_drop")

	assert_str(String(snap.get("next_objective_text", ""))).is_equal("Recover the delivery bag.")
	var found_next := false
	for row in snap.get("items", []):
		if row is Dictionary and bool(row.get("is_next", false)):
			found_next = true
			assert_str(String(row.get("text", ""))).is_equal("Recover the delivery bag.")
	assert_bool(found_next).is_true()

	_restore_quest_manager(quest_snapshot)


func test_hud_payload_exposes_next_objective_and_three_bag_status() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "taco_bell_drop"
	GameState.is_in_mission = true
	GameState.poop_bag_count = 1
	GameState.poop_bags_this_mission_attempt = 1
	GameState.poop_bag_inventory = {"count": 1, "collected_this_mission": 1, "used_this_mission": 0}
	QuestManager.active_quest_id = "taco_bell_drop"
	QuestManager.active_objective = "Internal stale objective"
	QuestManager.objectives = {"taco_bell_drop": "Internal stale objective"}

	var payload: Dictionary = MissionHudDataProviderScript.get_hud_payload()

	assert_str(String(payload.get("objective_text", ""))).is_equal("Recover the delivery bag.")
	assert_int(int(payload.get("poop_bags_available", -1))).is_equal(1)
	assert_int(int(payload.get("poop_bags_collected_this_attempt", -1))).is_equal(1)
	assert_int(int(payload.get("poop_bag_bonus_target", 0))).is_equal(3)
	assert_str(String(payload.get("poop_bag_status_text", ""))).contains("1/3")

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)


func _snapshot_game_state() -> Dictionary:
	return {
		"available_missions": GameState.available_missions.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(true),
		"unlocked_cards": GameState.unlocked_cards.duplicate(true),
		"collected_polaroids": GameState.collected_polaroids.duplicate(true),
		"crew_members": GameState.crew_members.duplicate(true),
		"friend_favors": GameState.friend_favors.duplicate(true),
		"intel_points": GameState.intel_points,
		"current_mission_id": GameState.current_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"sterling_clues": GameState.sterling_clues.duplicate(true),
		"evidence_clues": GameState.evidence_clues.duplicate(true),
		"crew_assists": GameState.crew_assists.duplicate(true),
		"poop_bag_count": GameState.poop_bag_count,
		"poop_bags_this_mission_attempt": GameState.poop_bags_this_mission_attempt,
		"poop_bag_inventory": GameState.poop_bag_inventory.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.available_missions = snapshot.get("available_missions", []).duplicate(true)
	GameState.completed_missions = snapshot.get("completed_missions", []).duplicate(true)
	GameState.unlocked_cards = snapshot.get("unlocked_cards", []).duplicate(true)
	GameState.collected_polaroids = snapshot.get("collected_polaroids", []).duplicate(true)
	GameState.crew_members = snapshot.get("crew_members", []).duplicate(true)
	GameState.friend_favors = snapshot.get("friend_favors", {}).duplicate(true)
	GameState.intel_points = int(snapshot.get("intel_points", 0))
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.last_mission_result = snapshot.get("last_mission_result", {}).duplicate(true)
	GameState.sterling_clues = snapshot.get("sterling_clues", {}).duplicate(true)
	GameState.evidence_clues = snapshot.get("evidence_clues", {}).duplicate(true)
	GameState.crew_assists = snapshot.get("crew_assists", {}).duplicate(true)
	GameState.poop_bag_count = int(snapshot.get("poop_bag_count", 0))
	GameState.poop_bags_this_mission_attempt = int(snapshot.get("poop_bags_this_mission_attempt", 0))
	GameState.poop_bag_inventory = snapshot.get("poop_bag_inventory", {}).duplicate(true)


func _snapshot_quest_manager() -> Dictionary:
	return {
		"active_quest_id": QuestManager.active_quest_id,
		"active_objective": QuestManager.active_objective,
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_quest_manager(snapshot: Dictionary) -> void:
	QuestManager.active_quest_id = String(snapshot.get("active_quest_id", ""))
	QuestManager.active_objective = String(snapshot.get("active_objective", ""))
	QuestManager.objectives = snapshot.get("objectives", {}).duplicate(true)
	QuestManager.objective_records = snapshot.get("objective_records", {}).duplicate(true)
	QuestManager.active_objectives = snapshot.get("active_objectives", {}).duplicate(true)
	QuestManager.completed_objectives = snapshot.get("completed_objectives", {}).duplicate(true)
