# GdUnit4 smoke tests for Packet 1 mission authoring effects.
extends GdUnitTestSuite

const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_effect_set_sets_mission_flag() -> void:
	var prev_flags := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.clear()

	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = "loading_dock_open"
	effect.value_type = "bool"
	effect.value_bool = true

	var set := EffectSetScript.new()
	set.effects = [effect]

	var result: Dictionary = set.apply_all({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:loading_dock_open", false)).is_true()

	GameState.dialogue_flags = prev_flags


func test_effect_set_completes_objective() -> void:
	var prev_active_quest_id := QuestManager.active_quest_id
	var prev_active_objective := QuestManager.active_objective
	var prev_objectives := QuestManager.objectives.duplicate(true)
	var prev_records := QuestManager.objective_records.duplicate(true)
	var prev_active := QuestManager.active_objectives.duplicate(true)
	var prev_completed := QuestManager.completed_objectives.duplicate(true)

	QuestManager.add_objective("test_objective", "Test objective", "active", "test_mission")

	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.COMPLETE_OBJECTIVE
	effect.key = "test_objective"
	effect.value_type = "string"
	effect.value_string = "Test objective"

	var set := EffectSetScript.new()
	set.effects = [effect]

	var result: Dictionary = set.apply_all({"mission_id": "test_mission"})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(QuestManager.is_objective_completed("test_objective", "test_mission")).is_true()

	QuestManager.active_quest_id = prev_active_quest_id
	QuestManager.active_objective = prev_active_objective
	QuestManager.objectives = prev_objectives
	QuestManager.objective_records = prev_records
	QuestManager.active_objectives = prev_active
	QuestManager.completed_objectives = prev_completed


func test_effect_set_stops_on_failure_when_configured() -> void:
	var prev_flags := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.clear()

	var failing := MissionEffectScript.new()
	failing.effect_type = MissionEffectScript.EffectType.CALL_METHOD
	failing.effect_id = &"missing_call"
	failing.method_name = &"missing_method"

	var should_not_run := MissionEffectScript.new()
	should_not_run.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	should_not_run.key = "should_not_be_set"
	should_not_run.value_bool = true

	var set := EffectSetScript.new()
	set.stop_on_failure = true
	set.effects = [failing, should_not_run]

	var result: Dictionary = set.apply_all({"mission_id": "test_mission"})
	assert_bool(result.get("ok", true)).is_false()
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:should_not_be_set")).is_false()

	GameState.dialogue_flags = prev_flags
