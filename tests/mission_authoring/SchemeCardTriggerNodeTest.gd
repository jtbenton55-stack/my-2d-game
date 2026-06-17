# GdUnit4 smoke tests for Phase 6C/6D-lite/6E-lite scheme-card triggers.
extends GdUnitTestSuite

const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const HideoutSchemeCardControllerScript := preload("res://src/hideout/HideoutSchemeCardController.gd")
const HideoutStateControllerScript := preload("res://src/hideout/HideoutStateController.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const MissionModifierSetScript := preload("res://src/missions/iso/authoring/core/MissionModifierSet.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const SchemeCardTriggerNodeScript := preload("res://src/missions/iso/authoring/mechanics/SchemeCardTriggerNode.gd")
const TacoProductionScene := preload("res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn")


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


func test_phase6f_taco_scene_has_louis_route_card_slice() -> void:
	var scene_root: Node = TacoProductionScene.instantiate()
	var setup: Node = scene_root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthLouisRouteCardSetup")
	var route: Node = scene_root.get_node_or_null("GameplayRoot/PlugAndPlayPilot/PpTacoSouthRoutePeek")

	assert_object(setup).is_not_null()
	assert_object(route).is_not_null()
	assert_bool(bool(setup.get("apply_on_ready"))).is_true()
	assert_bool(bool(setup.get("require_matching_modifier"))).is_true()
	assert_str(String(setup.get("mission_id_override"))).is_equal("taco_bell_drop")
	assert_str(String(setup.get("mechanic_id"))).is_equal("pp_taco_south_louis_route_card_setup")

	var modifier_sets: Array = setup.get("modifier_sets")
	assert_int(modifier_sets.size()).is_equal(1)
	assert_str(String(modifier_sets[0].get("source_card_id"))).is_equal("louis_delivery_route")

	var requirements: Resource = route.get("requirements")
	assert_object(requirements).is_not_null()
	assert_int(int(requirements.get("match_mode"))).is_equal(RequirementSetScript.MatchMode.ANY)
	var route_requirements: Array = requirements.get("requirements")
	assert_int(route_requirements.size()).is_equal(2)
	assert_str(String(route_requirements[0].get("key"))).is_equal("pp_taco_south_reward_collected")
	assert_str(String(route_requirements[1].get("key"))).is_equal("pp_taco_south_louis_route_card_ready")

	_free_node(scene_root)


func test_planning_table_dev_louis_override_does_not_unlock_card() -> void:
	var state: Node = HideoutStateControllerScript.new()
	var controller: Node = HideoutSchemeCardControllerScript.new()
	add_child(state)
	add_child(controller)
	state.call("apply_debug_state", "fresh")

	var unlocked_before: Array = state.get("unlocked_scheme_cards").duplicate()
	var message: String = controller.call("dev_equip_louis_delivery_route", state)
	var loadout: Dictionary = state.call("get_current_scheme_loadout")

	assert_bool(message.contains("DEV override equipped Louis Delivery Route")).is_true()
	assert_str(String(loadout.get("plan", ""))).is_equal("louis_delivery_route")
	assert_bool((state.get("unlocked_scheme_cards") as Array).has("louis_delivery_route")).is_false()
	assert_array(state.get("unlocked_scheme_cards")).is_equal(unlocked_before)
	assert_str(controller.call("card_name", "louis_delivery_route")).is_equal("Louis Delivery Route")

	_free_node(controller)
	_free_node(state)


func test_start_mission_clears_stale_phase6f_attempt_flags() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.dialogue_flags["mission_flag:taco_bell_drop:pp_taco_south_louis_route_card_ready"] = true
	GameState.dialogue_flags["mission_flag:taco_bell_drop:pp_taco_south_reward_collected"] = true
	GameState.dialogue_flags["mission_flag:other_mission:pp_taco_south_louis_route_card_ready"] = true
	GameState.dialogue_flags["met_louis"] = true

	GameState.start_mission("taco_bell_drop")

	assert_bool(GameState.dialogue_flags.has("mission_flag:taco_bell_drop:pp_taco_south_louis_route_card_ready")).is_false()
	assert_bool(GameState.dialogue_flags.has("mission_flag:taco_bell_drop:pp_taco_south_reward_collected")).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:other_mission:pp_taco_south_louis_route_card_ready", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("met_louis", false)).is_true()

	_restore_game_state(snapshot)


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
		"is_in_mission": GameState.is_in_mission,
		"poop_bags_this_mission_attempt": GameState.poop_bags_this_mission_attempt,
		"mission_performance": GameState.mission_performance.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	_restore_string_array(GameState.selected_cards, snapshot.get("selected_cards", []))
	GameState.set_current_scheme_loadout(snapshot.get("current_scheme_loadout", {}) as Dictionary)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.poop_bags_this_mission_attempt = int(snapshot.get("poop_bags_this_mission_attempt", 0))
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)


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
