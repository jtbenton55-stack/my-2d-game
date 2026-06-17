# GdUnit4 smoke tests for Phase 6C/6D-lite/6E-lite scheme-card triggers.
extends GdUnitTestSuite

const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const MissionModifierSetScript := preload("res://src/missions/iso/authoring/core/MissionModifierSet.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const SchemeCardTriggerNodeScript := preload("res://src/missions/iso/authoring/mechanics/SchemeCardTriggerNode.gd")


func test_selected_card_modifier_applies_setup_effect() -> void:
	_ensure_card_catalog_loaded()
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.selected_cards.clear()
	GameState.selected_cards.append("louis_delivery_route")
	GameState.set_current_scheme_loadout({"plan": "", "trick": "", "comfort_chaos": ""})

	var trigger := _spawn_trigger()
	trigger.call("set_modifier_sets", [_modifier("louis_delivery_route", _set_mission_flag_effect_set("phase6c_card_setup_ready"))])

	var result: Dictionary = trigger.call("trigger_scheme_cards", null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("scheme_card_trigger_applied")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase6c_card_setup_ready", false)).is_true()
	assert_bool(trigger.last_matched_card_ids.has("louis_delivery_route")).is_true()

	_restore_game_state(snapshot)
	_free_node(trigger)


func test_missing_selected_card_blocks_trigger() -> void:
	_ensure_card_catalog_loaded()
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.selected_cards.clear()
	GameState.set_current_scheme_loadout({"plan": "", "trick": "", "comfort_chaos": ""})

	var trigger := _spawn_trigger()
	trigger.call("set_modifier_sets", [_modifier("louis_delivery_route", _set_mission_flag_effect_set("should_not_apply"))])

	var result: Dictionary = trigger.call("trigger_scheme_cards", null, "script")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("no_matching_scheme_card_modifier")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:should_not_apply")).is_false()

	_restore_game_state(snapshot)
	_free_node(trigger)


func test_current_loadout_card_modifier_unlocks_route_requirement() -> void:
	_ensure_card_catalog_loaded()
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.selected_cards.clear()
	GameState.set_current_scheme_loadout({"plan": "louis_delivery_route", "trick": "", "comfort_chaos": ""})

	var route := _spawn_route()
	route.requirements = _mission_flag_requirement_set("phase6d_route_ready")
	assert_bool(route.is_interaction_available()).is_false()

	var trigger := _spawn_trigger()
	trigger.call("set_modifier_sets", [_modifier("louis_delivery_route", _set_mission_flag_effect_set("phase6d_route_ready"))])

	var result: Dictionary = trigger.call("trigger_scheme_cards", null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(route.is_interaction_available()).is_true()

	_restore_game_state(snapshot)
	_free_node(trigger)
	_free_node(route)


func test_apply_on_ready_runs_starting_setup_hook() -> void:
	_ensure_card_catalog_loaded()
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.selected_cards.clear()
	GameState.selected_cards.append("louis_delivery_route")
	GameState.set_current_scheme_loadout({"plan": "", "trick": "", "comfort_chaos": ""})

	var trigger: Node = SchemeCardTriggerNodeScript.new()
	trigger.name = "ReadySchemeCardTrigger"
	trigger.mission_id_override = "test_mission"
	trigger.apply_on_ready = true
	trigger.call("set_modifier_sets", [_modifier("louis_delivery_route", _set_mission_flag_effect_set("phase6e_starting_setup_ready"))])
	add_child(trigger)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase6e_starting_setup_ready", false)).is_true()
	assert_bool(trigger.used).is_true()

	_restore_game_state(snapshot)
	_free_node(trigger)


func _spawn_trigger() -> Node:
	var trigger: Node = SchemeCardTriggerNodeScript.new()
	trigger.name = "TestSchemeCardTrigger"
	trigger.mission_id_override = "test_mission"
	trigger.one_shot = false
	add_child(trigger)
	return trigger


func _spawn_route() -> Node:
	var route: Node = RouteUnlockNodeScript.new()
	route.name = "TestRouteUnlockNode"
	route.mission_id_override = "test_mission"
	route.one_shot = false
	add_child(route)
	return route


func _modifier(source_card_id: String, setup_effects: EffectSet) -> MissionModifierSet:
	var modifier := MissionModifierSetScript.new()
	modifier.modifier_id = &"test_modifier"
	modifier.source_card_id = StringName(source_card_id)
	modifier.setup_effects = setup_effects
	return modifier


func _mission_flag_requirement_set(flag_key: String) -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = flag_key
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


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"selected_cards": GameState.selected_cards.duplicate(),
		"current_scheme_loadout": GameState.get_current_scheme_loadout(),
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	_restore_string_array(GameState.selected_cards, snapshot.get("selected_cards", []))
	GameState.set_current_scheme_loadout(snapshot.get("current_scheme_loadout", {}) as Dictionary)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))


func _restore_string_array(target: Array[String], previous: Array) -> void:
	target.clear()
	for item in previous:
		target.append(String(item))


func _ensure_card_catalog_loaded() -> void:
	if CardManager.cards.is_empty() and CardManager.has_method("load_cards"):
		CardManager.load_cards()


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
