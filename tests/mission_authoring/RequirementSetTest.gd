# GdUnit4 smoke tests for Packet 1 mission authoring requirements.
extends GdUnitTestSuite

const MissionFactBridgeScript := preload("res://src/missions/iso/authoring/core/MissionFactBridge.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")


func test_selected_card_requirement_reads_game_state() -> void:
	var prev_selected := GameState.selected_cards.duplicate()
	var prev_unlocked := GameState.unlocked_cards.duplicate()
	GameState.unlocked_cards.clear()
	GameState.unlocked_cards.append("louis_delivery_route")
	GameState.selected_cards.clear()
	GameState.selected_cards.append("louis_delivery_route")

	var req := MissionRequirementScript.new()
	req.fact_type = &"selected_card"
	req.key = "louis_delivery_route"
	req.operator = MissionRequirementScript.Operator.EQUALS
	req.expected_value_type = "bool"
	req.expected_bool = true

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	_restore_string_array(GameState.selected_cards, prev_selected)
	_restore_string_array(GameState.unlocked_cards, prev_unlocked)


func test_unlocked_card_requirement_reads_typed_scheme_registry() -> void:
	var prev_unlocked := GameState.unlocked_cards.duplicate()
	var prev_scheme_cards := GameState.unlocked_scheme_cards.duplicate(true)
	GameState.unlocked_cards.clear()
	GameState.unlocked_scheme_cards.clear()
	GameState.unlocked_scheme_cards["mere_legal_eyes"] = {"is_unlocked": true}

	var req := MissionRequirementScript.new()
	req.fact_type = &"unlocked_card"
	req.key = "mere_legal_eyes"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	_restore_string_array(GameState.unlocked_cards, prev_unlocked)
	GameState.unlocked_scheme_cards = prev_scheme_cards


func test_scheme_effect_requirement_reads_selected_card_effect() -> void:
	_ensure_card_catalog_loaded()
	var prev_selected := GameState.selected_cards.duplicate()
	var prev_unlocked := GameState.unlocked_cards.duplicate()
	GameState.unlocked_cards.clear()
	GameState.unlocked_cards.append("louis_delivery_route")
	GameState.selected_cards.clear()
	GameState.selected_cards.append("louis_delivery_route")

	var req := MissionRequirementScript.new()
	req.fact_type = &"scheme_effect"
	req.key = "has_delivery_route"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	_restore_string_array(GameState.selected_cards, prev_selected)
	_restore_string_array(GameState.unlocked_cards, prev_unlocked)


func test_scheme_effect_requirement_reads_current_loadout_effect() -> void:
	_ensure_card_catalog_loaded()
	var prev_selected := GameState.selected_cards.duplicate()
	var prev_loadout := GameState.get_current_scheme_loadout()
	GameState.selected_cards.clear()
	GameState.set_current_scheme_loadout({"plan": "louis_delivery_route", "trick": "", "comfort_chaos": ""})

	var req := MissionRequirementScript.new()
	req.fact_type = &"scheme_effect"
	req.key = "has_delivery_route"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	_restore_string_array(GameState.selected_cards, prev_selected)
	GameState.set_current_scheme_loadout(prev_loadout)


func test_completed_objective_requirement_reads_quest_manager() -> void:
	var prev_active_quest_id := QuestManager.active_quest_id
	var prev_active_objective := QuestManager.active_objective
	var prev_objectives := QuestManager.objectives.duplicate(true)
	var prev_records := QuestManager.objective_records.duplicate(true)
	var prev_active := QuestManager.active_objectives.duplicate(true)
	var prev_completed := QuestManager.completed_objectives.duplicate(true)

	QuestManager.add_objective("delivery_bag_recovered", "Recover delivery bag", "active", "taco_bell_drop")
	QuestManager.complete_objective_id("delivery_bag_recovered", "Recover delivery bag", "taco_bell_drop")

	var req := MissionRequirementScript.new()
	req.fact_type = &"objective_completed"
	req.key = "delivery_bag_recovered"
	req.operator = MissionRequirementScript.Operator.EQUALS
	req.expected_value_type = "bool"
	req.expected_bool = true

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	QuestManager.active_quest_id = prev_active_quest_id
	QuestManager.active_objective = prev_active_objective
	QuestManager.objectives = prev_objectives
	QuestManager.objective_records = prev_records
	QuestManager.active_objectives = prev_active
	QuestManager.completed_objectives = prev_completed


func test_mission_flag_requirement_uses_namespaced_dialogue_flag() -> void:
	var prev := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.clear()
	MissionFactBridgeScript.set_fact_value(&"mission_flag", "loading_dock_open", true, {"mission_id": "taco_bell_drop"})

	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "loading_dock_open"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:taco_bell_drop:loading_dock_open")).is_true()

	GameState.dialogue_flags = prev


func test_typed_collectible_count_requirement_counts_type_and_group() -> void:
	var prev := GameState.typed_collectibles.duplicate(true)
	GameState.typed_collectibles = {
		"poop_01": {"type": "poop_bag", "collection_group": "bags"},
		"poop_02": {"type": "item", "collection_group": "poop_bag"},
		"photo_01": {"type": "polaroid", "collection_group": "photos"},
	}

	var req := MissionRequirementScript.new()
	req.fact_type = &"typed_collectible_type_count"
	req.key = "poop_bag"
	req.operator = MissionRequirementScript.Operator.GREATER_OR_EQUAL
	req.expected_value_type = "int"
	req.expected_int = 2

	var result: Dictionary = req.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()

	GameState.typed_collectibles = prev


func test_requirement_set_any_passes_when_one_requirement_passes() -> void:
	var prev_selected := GameState.selected_cards.duplicate()
	GameState.selected_cards.clear()
	GameState.selected_cards.append("louis_delivery_route")

	var missing := MissionRequirementScript.new()
	missing.fact_type = &"selected_card"
	missing.key = "missing_card"
	missing.expected_bool = true

	var present := MissionRequirementScript.new()
	present.fact_type = &"selected_card"
	present.key = "louis_delivery_route"
	present.expected_bool = true

	var set := RequirementSetScript.new()
	set.match_mode = RequirementSetScript.MatchMode.ANY
	set.requirements = [missing, present]

	var result: Dictionary = set.evaluate({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()
	assert_int(int(result.get("details", {}).get("passed_count", 0))).is_equal(1)

	_restore_string_array(GameState.selected_cards, prev_selected)


func _restore_string_array(target: Array[String], previous: Array) -> void:
	target.clear()
	for item in previous:
		target.append(String(item))


func _ensure_card_catalog_loaded() -> void:
	if CardManager.cards.is_empty() and CardManager.has_method("load_cards"):
		CardManager.load_cards()
