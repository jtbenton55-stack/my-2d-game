# GdUnit4 smoke tests for Phase 6B mission modifier data.
extends GdUnitTestSuite

const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const MissionModifierSetScript := preload("res://src/missions/iso/authoring/core/MissionModifierSet.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_modifier_set_keeps_card_bundle_inspectable() -> void:
	var req_set := _always_requirement_set()
	var effect_set := _set_mission_flag_effect_set("phase6b_setup_applied")

	var modifier := MissionModifierSetScript.new()
	modifier.modifier_id = &"louis_delivery_route_setup"
	modifier.source_card_id = &"louis_delivery_route"
	modifier.requirements = req_set
	modifier.setup_effects = effect_set
	modifier.debug_note = "Inspectable card setup bundle."

	assert_str(String(modifier.modifier_id)).is_equal("louis_delivery_route_setup")
	assert_str(String(modifier.source_card_id)).is_equal("louis_delivery_route")
	assert_bool(modifier.requirements == req_set).is_true()
	assert_bool(modifier.setup_effects == effect_set).is_true()
	assert_bool(modifier.has_setup_effects()).is_true()
	assert_bool(modifier.matches_source_card("louis_delivery_route")).is_true()
	assert_bool(modifier.matches_source_card("mere_legal_eyes")).is_false()


func test_modifier_set_evaluates_requirement_set() -> void:
	var modifier := MissionModifierSetScript.new()
	modifier.modifier_id = &"requires_selected_card"
	modifier.source_card_id = &"louis_delivery_route"
	modifier.requirements = _selected_card_requirement_set("louis_delivery_route")

	var prev_selected := GameState.selected_cards.duplicate()
	GameState.selected_cards.clear()

	var blocked: Dictionary = modifier.evaluate_requirements({"mission_id": "taco_bell_drop"})
	assert_bool(blocked.get("ok", true)).is_false()

	GameState.selected_cards.append("louis_delivery_route")
	var allowed: Dictionary = modifier.evaluate_requirements({"mission_id": "taco_bell_drop"})
	assert_bool(allowed.get("ok", false)).is_true()

	_restore_string_array(GameState.selected_cards, prev_selected)


func test_modifier_set_applies_setup_effects_without_manager() -> void:
	var prev_flags := GameState.dialogue_flags.duplicate(true)
	GameState.dialogue_flags.clear()

	var modifier := MissionModifierSetScript.new()
	modifier.modifier_id = &"setup_route_flag"
	modifier.source_card_id = &"louis_delivery_route"
	modifier.setup_effects = _set_mission_flag_effect_set("phase6b_route_ready")

	var result: Dictionary = modifier.apply_setup_effects({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:taco_bell_drop:phase6b_route_ready", false)).is_true()

	GameState.dialogue_flags = prev_flags


func test_modifier_set_empty_setup_effects_is_safe_noop() -> void:
	var modifier := MissionModifierSetScript.new()
	modifier.modifier_id = &"empty_modifier"

	var result: Dictionary = modifier.apply_setup_effects({"mission_id": "taco_bell_drop"})
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("no_setup_effects")
	assert_str(String(result.get("source_id", ""))).is_equal("empty_modifier")


func _always_requirement_set() -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"always"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var req_set := RequirementSetScript.new()
	req_set.requirements = [req]
	return req_set


func _selected_card_requirement_set(card_id: String) -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"selected_card"
	req.key = card_id
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"

	var req_set := RequirementSetScript.new()
	req_set.requirements = [req]
	return req_set


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true

	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _restore_string_array(target: Array[String], previous: Array) -> void:
	target.clear()
	for item in previous:
		target.append(String(item))
