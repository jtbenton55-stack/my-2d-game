# GdUnit4 tests for Packet 2B-5 ExtractionZone.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const ExtractionZoneScript := preload("res://src/missions/iso/authoring/mechanics/ExtractionZone.gd")
const ObjectiveStepControllerScript := preload("res://src/missions/iso/authoring/core/ObjectiveStepController.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_extraction_zone_extends_mechanic_area_base() -> void:
	var zone := ExtractionZoneScript.new()
	assert_object(zone).is_instanceof(MechanicAreaBaseScript)
	zone.free()


func test_ready_groups_and_starts_extracted() -> void:
	var zone := _spawn_extraction()
	assert_bool(zone.is_in_group("interactable")).is_true()
	assert_bool(zone.is_in_group("mission_mechanic")).is_true()
	assert_bool(zone.is_in_group("phase0j_interactable")).is_false()
	assert_bool(zone.extracted).is_false()
	_free_extraction(zone)

	var extracted_zone := ExtractionZoneScript.new()
	extracted_zone.name = "TestExtractionZoneExtracted"
	extracted_zone.starts_extracted = true
	add_child(extracted_zone)
	assert_bool(extracted_zone.extracted).is_true()
	_free_extraction(extracted_zone)


func test_successful_clean_extraction_without_mission_completion() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("extraction_clean")
	assert_bool(zone.extracted).is_true()
	assert_bool(zone.last_extraction_result.is_empty()).is_false()
	assert_str(String(result.get("details", {}).get("outcome", ""))).is_equal("clean")

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_base_requirement_gating_blocks_extraction() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = true
	zone.requirements = _failing_requirement_set()
	zone.clean_exit_effects = _set_mission_flag_effect_set("should_not_fire_clean")
	zone.messy_exit_effects = _set_mission_flag_effect_set("should_not_fire_messy")
	zone.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(zone.extracted).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire_clean", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire_messy", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_required_objective_gating() -> void:
	var snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.required_objective_ids = _string_name_array([&"dev_required_obj"])

	var blocked: Dictionary = zone.extract(null, "script")
	assert_bool(blocked.get("ok", false)).is_false()
	assert_str(String(blocked.get("code", ""))).is_equal("missing_required_objectives")
	assert_bool(zone.extracted).is_false()
	var missing: Array = blocked.get("details", {}).get("missing_required_objectives", [])
	assert_bool(missing.has("dev_required_obj")).is_true()

	ObjectiveStepControllerScript.complete_objective("dev_required_obj", "Required", "test_mission")
	var allowed: Dictionary = zone.extract(null, "script")
	assert_bool(allowed.get("ok", false)).is_true()
	assert_str(String(allowed.get("code", ""))).is_equal("extraction_clean")
	assert_bool(zone.extracted).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_optional_objective_reporting() -> void:
	var snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.optional_objective_ids = _string_name_array([&"opt_done", &"opt_pending"])
	ObjectiveStepControllerScript.complete_objective("opt_done", "Done", "test_mission")

	var result: Dictionary = zone.extract(null, "script")
	var optional_status: Dictionary = result.get("details", {}).get("optional_objectives", {})
	assert_bool(optional_status.get("ok", false)).is_true()
	var completed: Array = optional_status.get("completed", [])
	var incomplete: Array = optional_status.get("incomplete", [])
	assert_bool(completed.has("opt_done")).is_true()
	assert_bool(incomplete.has("opt_pending")).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_extraction_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.extraction_flag = &"dev_extracted"

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_extracted", false)).is_true()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_clean_exit_effects_apply_only_for_clean_outcome() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.clean_exit_effects = _set_mission_flag_effect_set("dev_clean_exit")
	zone.messy_exit_effects = _set_mission_flag_effect_set("dev_messy_exit")

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("details", {}).get("outcome", ""))).is_equal("clean")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_clean_exit", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_messy_exit", false)).is_false()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_messy_exit_effects_when_alerted() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"
	GameState.set_mission_alert_state("test_mission", "alerted")

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.fail_if_alerted = false
	zone.messy_if_alerted = true
	zone.clean_exit_effects = _set_mission_flag_effect_set("dev_clean_exit")
	zone.messy_exit_effects = _set_mission_flag_effect_set("dev_messy_exit")

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("extraction_messy")
	assert_str(String(result.get("details", {}).get("outcome", ""))).is_equal("messy")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_messy_exit", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_clean_exit", false)).is_false()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_alert_failure_blocks_extraction_and_completion() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"
	GameState.set_mission_alert_state("test_mission", "alerted")

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = true
	zone.fail_if_alerted = true
	zone.messy_if_alerted = true
	zone.clean_exit_effects = _set_mission_flag_effect_set("should_not_fire")

	var before_completion: Dictionary = GameState.last_mission_result.duplicate(true)
	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("extraction_failed_alerted")
	assert_bool(zone.extracted).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_dict(GameState.last_mission_result).is_equal(before_completion)

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_mission_completion_request_when_enabled() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = true

	var result: Dictionary = zone.extract(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	var completion_result: Dictionary = result.get("details", {}).get("completion_result", {})
	assert_bool(completion_result.get("ok", false)).is_true()
	assert_bool(bool(GameState.last_mission_result.get("success", false))).is_true()
	assert_str(String(GameState.last_mission_result.get("mission_id", ""))).is_equal("test_mission")

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_already_extracted_does_not_reapply_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.stay_available_after_extract = false
	zone.complete_mission_on_success = false
	zone.clean_exit_effects = _set_mission_flag_effect_set("dev_clean_exit")

	var first: Dictionary = zone.extract(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:dev_clean_exit")

	var second: Dictionary = zone.extract(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_extracted")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:dev_clean_exit")).is_false()
	assert_bool(zone.is_interaction_available()).is_false()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_prompt_behavior() -> void:
	var snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.current_mission_id = "test_mission"

	var zone := _spawn_extraction()
	zone.prompt_text = "Press E: Extract"
	zone.missing_objective_message = "Finish required objective first"
	zone.required_objective_ids = _string_name_array([&"dev_required_obj"])
	assert_str(zone.get_interaction_text()).is_equal("Finish required objective first")

	ObjectiveStepControllerScript.complete_objective("dev_required_obj", "Required", "test_mission")
	assert_str(zone.get_interaction_text()).is_equal("Press E: Extract")

	zone.extract(null, "script")
	zone.stay_available_after_extract = false
	assert_str(zone.get_interaction_text()).is_equal("")

	zone.stay_available_after_extract = true
	zone.extracted_prompt_text = "Already extracted"
	assert_str(zone.get_interaction_text()).is_equal("Already extracted")

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(snapshot)
	_free_extraction(zone)


func test_interface_methods_route_to_extract() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_extraction()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.complete_mission_on_success = false
	zone.clean_exit_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(zone.interact()).is_true()
	assert_bool(zone.extracted).is_true()

	zone.reset_extraction()
	zone.clean_exit_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(zone.on_interact()).is_true()

	zone.reset_extraction()
	assert_bool(zone.use()).is_true()

	zone.reset_extraction()
	assert_bool(zone.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_extraction(zone)


func _string_name_array(values: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for value: Variant in values:
		out.append(value as StringName)
	return out


func _spawn_extraction() -> Node:
	var zone := ExtractionZoneScript.new()
	zone.name = "TestExtractionZone"
	add_child(zone)
	return zone


func _free_extraction(zone: Node) -> void:
	if is_instance_valid(zone):
		zone.queue_free()


func _failing_requirement_set(locked_message: String = "") -> RequirementSet:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = "missing_flag"
	requirement.operator = MissionRequirement.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [requirement]
	var message := locked_message.strip_edges()
	if message == "":
		message = "Requirements not met."
	req_set.locked_message = message
	return req_set


func _set_mission_flag_effect_set(flag_id: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffect.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(),
		"mission_alert_states": GameState.mission_alert_states.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	_restore_string_array(GameState.completed_missions, snapshot.get("completed_missions", []))
	GameState.mission_alert_states = (snapshot.get("mission_alert_states", {}) as Dictionary).duplicate(true)


func _snapshot_quest_manager() -> Dictionary:
	return {
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_quest_manager(snapshot: Dictionary) -> void:
	QuestManager.objectives = (snapshot.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("completed_objectives", {}) as Dictionary).duplicate(true)


func _restore_string_array(target: Array[String], previous: Variant) -> void:
	target.clear()
	if previous is Array:
		for item in previous:
			target.append(String(item))
