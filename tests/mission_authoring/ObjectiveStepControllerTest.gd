# GdUnit4 tests for Packet 2B-4C ObjectiveStepController.
extends GdUnitTestSuite

const ObjectiveStepControllerScript := preload("res://src/missions/iso/authoring/core/ObjectiveStepController.gd")


func test_result_contract_has_required_fields() -> void:
	var result: Dictionary = ObjectiveStepControllerScript.activate_objective(
		"dev_objective",
		"Find the clue",
		"dev_mission"
	)
	assert_bool(result.has("ok")).is_true()
	assert_bool(result.has("code")).is_true()
	assert_bool(result.has("message")).is_true()
	assert_bool(result.has("source_id")).is_true()
	assert_bool(result.has("details")).is_true()
	assert_str(String(result.get("source_id", ""))).is_equal("dev_objective")


func test_mission_id_resolution_prefers_explicit_argument() -> void:
	var snapshot := _snapshot_quest_manager()
	var game_snapshot := _snapshot_game_state()
	GameState.current_mission_id = "from_game_state"

	var result: Dictionary = ObjectiveStepControllerScript.activate_objective(
		"explicit_mission_obj",
		"Explicit mission test",
		"explicit_mission"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("details", {}).get("mission_id", ""))).is_equal("explicit_mission")

	_restore_game_state(game_snapshot)
	_restore_quest_manager(snapshot)


func test_mission_id_resolution_uses_context_when_explicit_empty() -> void:
	var snapshot := _snapshot_quest_manager()
	var game_snapshot := _snapshot_game_state()
	GameState.current_mission_id = "should_not_use"

	var result: Dictionary = ObjectiveStepControllerScript.activate_objective(
		"context_mission_obj",
		"Context mission test",
		"",
		{"mission_id": "context_mission"}
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("details", {}).get("mission_id", ""))).is_equal("context_mission")

	_restore_game_state(game_snapshot)
	_restore_quest_manager(snapshot)


func test_mission_id_resolution_falls_back_to_game_state() -> void:
	var snapshot := _snapshot_quest_manager()
	var game_snapshot := _snapshot_game_state()
	GameState.current_mission_id = "game_state_mission"

	var result: Dictionary = ObjectiveStepControllerScript.activate_objective(
		"game_state_obj",
		"Game state mission test"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("details", {}).get("mission_id", ""))).is_equal("game_state_mission")

	_restore_game_state(game_snapshot)
	_restore_quest_manager(snapshot)


func test_activate_objective_marks_active() -> void:
	var snapshot := _snapshot_quest_manager()

	var result: Dictionary = ObjectiveStepControllerScript.activate_objective(
		"dev_objective",
		"Find the clue",
		"dev_mission"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("objective_activated")
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_objective", "dev_mission")).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("dev_objective", "dev_mission")).is_false()
	assert_str(String(result.get("details", {}).get("text", ""))).is_equal("Find the clue")

	_restore_quest_manager(snapshot)


func test_complete_objective_after_activate() -> void:
	var snapshot := _snapshot_quest_manager()

	ObjectiveStepControllerScript.activate_objective("dev_complete_obj", "Complete me", "dev_mission")
	var result: Dictionary = ObjectiveStepControllerScript.complete_objective(
		"dev_complete_obj",
		"Complete me",
		"dev_mission"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("objective_completed")
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("dev_complete_obj", "dev_mission")).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_complete_obj", "dev_mission")).is_false()

	_restore_quest_manager(snapshot)


func test_complete_missing_objective_uses_quest_manager_behavior() -> void:
	var snapshot := _snapshot_quest_manager()

	var result: Dictionary = ObjectiveStepControllerScript.complete_objective(
		"missing_objective",
		"Created on complete",
		"dev_mission"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("missing_objective", "dev_mission")).is_true()

	_restore_quest_manager(snapshot)


func test_fail_objective_marks_failed_and_not_active() -> void:
	var snapshot := _snapshot_quest_manager()

	ObjectiveStepControllerScript.activate_objective("dev_fail_obj", "Fail me", "dev_mission")
	var result: Dictionary = ObjectiveStepControllerScript.fail_objective(
		"dev_fail_obj",
		"Fail me",
		"dev_mission"
	)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("objective_failed")
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_fail_obj", "dev_mission")).is_false()
	assert_bool(ObjectiveStepControllerScript.is_objective_completed("dev_fail_obj", "dev_mission")).is_false()
	var record := ObjectiveStepControllerScript.get_objective_record("dev_fail_obj", "dev_mission")
	assert_str(String(record.get("status", ""))).is_equal("failed")

	_restore_quest_manager(snapshot)


func test_get_objective_record_for_active_and_missing() -> void:
	var snapshot := _snapshot_quest_manager()

	ObjectiveStepControllerScript.activate_objective("dev_record_obj", "Record test", "dev_mission")
	var record: Dictionary = ObjectiveStepControllerScript.get_objective_record("dev_record_obj", "dev_mission")
	assert_str(String(record.get("objective_id", ""))).is_equal("dev_record_obj")
	assert_str(String(record.get("mission_id", ""))).is_equal("dev_mission")
	assert_bool(record.get("active", false)).is_true()
	assert_bool(record.get("completed", true)).is_false()
	assert_str(String(record.get("text", ""))).is_equal("Record test")

	assert_bool(ObjectiveStepControllerScript.get_objective_record("missing_record_obj", "dev_mission").is_empty()).is_true()

	_restore_quest_manager(snapshot)


func test_missing_objective_id_returns_clean_failure() -> void:
	var result: Dictionary = ObjectiveStepControllerScript.activate_objective("", "No id", "dev_mission")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("objective_id_missing")


func test_quest_manager_presence() -> void:
	assert_bool(ObjectiveStepControllerScript._has_quest_manager()).is_true()


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
	QuestManager.objectives = (snapshot.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("completed_objectives", {}) as Dictionary).duplicate(true)


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
