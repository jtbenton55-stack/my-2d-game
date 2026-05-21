# GdUnit4 smoke tests for Packet 2B-2 TriggerZone.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const TriggerZoneScript := preload("res://src/missions/iso/authoring/mechanics/TriggerZone.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_trigger_zone_extends_mechanic_area_base() -> void:
	var trigger := TriggerZoneScript.new()
	assert_object(trigger).is_instanceof(MechanicAreaBaseScript)
	trigger.free()


func test_ready_keeps_mission_mechanic_groups() -> void:
	var trigger := _spawn_trigger()
	assert_bool(trigger.is_in_group("interactable")).is_true()
	assert_bool(trigger.is_in_group("mission_mechanic")).is_true()
	assert_bool(trigger.is_in_group("phase0j_interactable")).is_false()
	_free_trigger(trigger)


func test_script_trigger_activates_and_sets_reason() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger()
	trigger.mission_id_override = "test_mission"
	trigger.one_shot = false
	trigger.success_effects = _set_mission_flag_effect_set("script_flag")

	var result: Dictionary = trigger.trigger(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(trigger.last_trigger_reason).is_equal("script")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:script_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_trigger(trigger)


func test_build_context_includes_trigger_metadata() -> void:
	var trigger := _spawn_trigger()
	trigger.trigger_event_id = &"loading_dock"
	trigger.last_trigger_reason = "script"
	var context: Dictionary = trigger.build_context()
	assert_str(String(context.get("trigger_event_id", ""))).is_equal("loading_dock")
	assert_str(String(context.get("trigger_reason", ""))).is_equal("script")
	_free_trigger(trigger)


func test_one_shot_marks_used_and_second_trigger_is_already_used() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger()
	trigger.mission_id_override = "test_mission"
	trigger.one_shot = true
	trigger.success_effects = _set_mission_flag_effect_set("once_flag")

	var first: Dictionary = trigger.trigger(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	assert_bool(trigger.used).is_true()

	var second: Dictionary = trigger.trigger(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_used")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:once_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_trigger(trigger)


func test_requirement_failure_applies_failure_effects_without_marking_used() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger()
	trigger.mission_id_override = "test_mission"
	trigger.one_shot = true
	trigger.requirements = _failing_requirement_set()
	trigger.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = trigger.trigger(null, "script")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()
	assert_bool(trigger.used).is_false()

	_restore_game_state(snapshot)
	_free_trigger(trigger)


func test_interact_required_does_not_auto_activate_on_body_enter() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger(MechanicAreaBaseScript.InteractionMode.INTERACT_REQUIRED)
	trigger.mission_id_override = "test_mission"
	trigger.success_effects = _set_mission_flag_effect_set("enter_flag")

	var player := Node2D.new()
	player.add_to_group("player")
	trigger.handle_body_entered(player)
	assert_bool(trigger.used).is_false()
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:enter_flag")).is_false()

	var manual: Dictionary = trigger.trigger(player, "script")
	assert_bool(manual.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:enter_flag", false)).is_true()

	player.free()
	_restore_game_state(snapshot)
	_free_trigger(trigger)


func test_automatic_on_enter_handler_activates_allowed_actor() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger(MechanicAreaBaseScript.InteractionMode.AUTOMATIC_ON_ENTER)
	trigger.trigger_on_enter = true
	trigger.mission_id_override = "test_mission"
	trigger.success_effects = _set_mission_flag_effect_set("auto_enter_flag")

	var player := Node2D.new()
	player.add_to_group("player")
	trigger.handle_body_entered(player)
	assert_str(trigger.last_trigger_reason).is_equal("body_entered")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:auto_enter_flag", false)).is_true()

	player.free()
	_restore_game_state(snapshot)
	_free_trigger(trigger)


func test_interact_routes_with_interact_reason() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var trigger := _spawn_trigger(MechanicAreaBaseScript.InteractionMode.INTERACT_REQUIRED)
	trigger.one_shot = false
	trigger.mission_id_override = "test_mission"
	trigger.success_effects = _set_mission_flag_effect_set("interact_flag")

	assert_bool(trigger.interact()).is_true()
	assert_str(trigger.last_trigger_reason).is_equal("interact")

	_restore_game_state(snapshot)
	_free_trigger(trigger)


func _spawn_trigger(mode: int = MechanicAreaBaseScript.InteractionMode.AUTOMATIC_ON_ENTER) -> Node:
	var trigger: Node = TriggerZoneScript.new()
	trigger.name = "TestTriggerZone"
	trigger.interaction_mode = mode
	add_child(trigger)
	return trigger


func _free_trigger(trigger: Node) -> void:
	if is_instance_valid(trigger):
		trigger.queue_free()


func _failing_requirement_set() -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "missing_flag"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"
	var set := RequirementSetScript.new()
	set.requirements = [req]
	return set


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var set := EffectSetScript.new()
	set.effects = [effect]
	return set


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
