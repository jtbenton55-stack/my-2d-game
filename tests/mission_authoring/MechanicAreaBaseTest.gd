# GdUnit4 smoke tests for Packet 2B-1 MechanicAreaBase.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_ready_adds_groups_and_initializes_used() -> void:
	var mechanic := MechanicAreaBaseScript.new()
	mechanic.starts_used = true
	add_child(mechanic)
	assert_bool(mechanic.is_in_group("interactable")).is_true()
	assert_bool(mechanic.is_in_group("mission_mechanic")).is_true()
	assert_bool(mechanic.is_in_group("phase0j_interactable")).is_false()
	assert_bool(mechanic.used).is_true()
	_free_mechanic(mechanic)


func test_disabled_node_is_unavailable() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.enabled = false
	assert_bool(mechanic.is_interaction_available()).is_false()
	assert_str(mechanic.get_interaction_text()).is_equal("")
	_free_mechanic(mechanic)


func test_one_shot_used_node_is_unavailable() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.used = true
	assert_bool(mechanic.is_interaction_available()).is_false()
	assert_str(mechanic.get_interaction_text()).is_equal("")
	_free_mechanic(mechanic)


func test_actor_group_filtering() -> void:
	var mechanic := _spawn_mechanic()
	var player := Node2D.new()
	player.add_to_group("player")
	var stranger := Node2D.new()
	assert_bool(mechanic.can_actor_use(player)).is_true()
	assert_bool(mechanic.can_actor_use(stranger)).is_false()
	assert_bool(mechanic.is_interaction_available(player)).is_true()
	assert_bool(mechanic.is_interaction_available(stranger)).is_false()
	player.free()
	stranger.free()
	_free_mechanic(mechanic)


func test_empty_requirements_allow_interaction() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.requirements = null
	assert_bool(mechanic.is_interaction_available()).is_true()
	assert_str(mechanic.get_interaction_text()).is_equal(mechanic.prompt_text)
	_free_mechanic(mechanic)


func test_failing_requirements_block_availability_and_show_locked_prompt() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.requirements = _failing_requirement_set("Need the keycard")
	assert_bool(mechanic.is_interaction_available()).is_false()
	assert_str(mechanic.get_interaction_text()).is_equal("Need the keycard")
	_free_mechanic(mechanic)


func test_passing_requirements_allow_interaction() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.dialogue_flags["mission_flag:test_mission:gate_open"] = true

	var mechanic := _spawn_mechanic()
	mechanic.mission_id_override = "test_mission"
	mechanic.requirements = _mission_flag_requirement_set("gate_open")
	assert_bool(mechanic.is_interaction_available()).is_true()
	assert_str(mechanic.get_interaction_text()).is_equal(mechanic.prompt_text)
	_restore_game_state(snapshot)
	_free_mechanic(mechanic)


func test_success_effect_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = "test_mission"

	var mechanic := _spawn_mechanic()
	mechanic.mission_id_override = "test_mission"
	mechanic.one_shot = false
	mechanic.success_effects = _set_mission_flag_effect_set("loading_dock_open")

	var result: Dictionary = mechanic.activate()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:loading_dock_open", false)).is_true()

	_restore_game_state(snapshot)
	_free_mechanic(mechanic)


func test_one_shot_marks_used_after_successful_activation() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var mechanic := _spawn_mechanic()
	mechanic.one_shot = true
	mechanic.success_effects = _set_mission_flag_effect_set("used_flag")

	var result: Dictionary = mechanic.activate()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(mechanic.used).is_true()
	assert_bool(mechanic.is_completed()).is_true()

	_restore_game_state(snapshot)
	_free_mechanic(mechanic)


func test_failure_effects_apply_when_requirements_fail() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var mechanic := _spawn_mechanic()
	mechanic.mission_id_override = "test_mission"
	mechanic.one_shot = true
	mechanic.requirements = _failing_requirement_set()
	mechanic.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = mechanic.activate()
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()
	assert_bool(mechanic.used).is_false()

	_restore_game_state(snapshot)
	_free_mechanic(mechanic)


func test_failed_activation_does_not_mark_used() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.requirements = _failing_requirement_set()
	var result: Dictionary = mechanic.activate()
	assert_bool(result.get("ok", true)).is_false()
	assert_bool(mechanic.used).is_false()
	_free_mechanic(mechanic)


func test_interaction_aliases_route_to_activation() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var mechanic := _spawn_mechanic()
	mechanic.one_shot = false
	mechanic.success_effects = _set_mission_flag_effect_set("alias_flag")

	assert_bool(mechanic.interact()).is_true()
	mechanic.used = false
	GameState.dialogue_flags.clear()
	assert_bool(mechanic.on_interact()).is_true()
	mechanic.used = false
	GameState.dialogue_flags.clear()
	assert_bool(mechanic.use()).is_true()
	mechanic.used = false
	GameState.dialogue_flags.clear()
	assert_bool(mechanic.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_mechanic(mechanic)


func test_get_interaction_priority_returns_export() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.interaction_priority = 777
	assert_int(mechanic.get_interaction_priority()).is_equal(777)
	_free_mechanic(mechanic)


func test_is_completed_reflects_used_one_shot() -> void:
	var mechanic := _spawn_mechanic()
	mechanic.one_shot = true
	assert_bool(mechanic.is_completed()).is_false()
	mechanic.used = true
	assert_bool(mechanic.is_completed()).is_true()
	_free_mechanic(mechanic)


func _spawn_mechanic() -> Node:
	var mechanic: Node = MechanicAreaBaseScript.new()
	mechanic.name = "TestMechanic"
	add_child(mechanic)
	return mechanic


func _free_mechanic(mechanic: Node) -> void:
	if is_instance_valid(mechanic):
		mechanic.queue_free()


func _failing_requirement_set(locked_message: String = "Locked") -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "missing_flag"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"
	var set := RequirementSetScript.new()
	set.requirements = [req]
	set.locked_message = locked_message
	return set


func _mission_flag_requirement_set(flag_key: String) -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = flag_key
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
