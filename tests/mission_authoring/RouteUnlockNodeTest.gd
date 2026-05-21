# GdUnit4 tests for Packet 2B-8 RouteUnlockNode.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_route_unlock_node_extends_mechanic_area_base() -> void:
	var route := RouteUnlockNodeScript.new()
	assert_object(route).is_instanceof(MechanicAreaBaseScript)
	route.free()


func test_ready_groups_and_starts_unlocked() -> void:
	var route := _spawn_route()
	assert_bool(route.is_in_group("interactable")).is_true()
	assert_bool(route.is_in_group("mission_mechanic")).is_true()
	assert_bool(route.is_in_group("phase0j_interactable")).is_false()
	assert_bool(route.route_unlocked).is_false()
	_free_route(route)

	var unlocked_route := RouteUnlockNodeScript.new()
	unlocked_route.name = "TestRouteUnlocked"
	unlocked_route.starts_unlocked = true
	add_child(unlocked_route)
	assert_bool(unlocked_route.route_unlocked).is_true()
	_free_route(unlocked_route)


func test_successful_route_unlock() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.route_id = &"dev_shortcut"

	var result: Dictionary = route.unlock_route(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("route_unlocked")
	assert_bool(route.route_unlocked).is_true()
	assert_bool(route.last_route_result.is_empty()).is_false()
	assert_str(String(result.get("details", {}).get("route_id", ""))).is_equal("dev_shortcut")

	_restore_game_state(snapshot)
	_free_route(route)


func test_effect_set_and_no_duplicate_on_repeat() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.stay_available_after_unlock = false
	route.success_effects = _set_mission_flag_effect_set("dev_route_effect_applied")

	var first: Dictionary = route.unlock_route(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_route_effect_applied", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:dev_route_effect_applied")

	var second: Dictionary = route.unlock_route(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_unlocked")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:dev_route_effect_applied")).is_false()

	_restore_game_state(snapshot)
	_free_route(route)


func test_route_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.route_flag = &"dev_route_open"

	var result: Dictionary = route.unlock_route(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_route_open", false)).is_true()

	_restore_game_state(snapshot)
	_free_route(route)


func test_requirement_gating_blocks_unlock() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = true
	route.requirements = _failing_requirement_set()
	route.success_effects = _set_mission_flag_effect_set("should_not_fire")
	route.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = route.unlock_route(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(route.route_unlocked).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_route(route)


func test_mission_flag_requirement_delegates_gating() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.requirements = _flag_requirement_set("dev_reward_collected", "Collect the dev reward first")
	route.success_effects = _set_mission_flag_effect_set("dev_route_effect_applied")

	var blocked: Dictionary = route.unlock_route(null, "script")
	assert_bool(blocked.get("ok", false)).is_false()
	assert_str(String(blocked.get("code", ""))).is_equal("requirements_failed")

	GameState.dialogue_flags["mission_flag:test_mission:dev_reward_collected"] = true
	var allowed: Dictionary = route.unlock_route(null, "script")
	assert_bool(allowed.get("ok", false)).is_true()
	assert_str(String(allowed.get("code", ""))).is_equal("route_unlocked")

	_restore_game_state(snapshot)
	_free_route(route)


func test_already_unlocked_availability() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.stay_available_after_unlock = false

	route.unlock_route(null, "script")
	var second: Dictionary = route.unlock_route(null, "script")
	assert_str(String(second.get("code", ""))).is_equal("already_unlocked")
	assert_bool(route.is_interaction_available()).is_false()

	_restore_game_state(snapshot)
	_free_route(route)


func test_prompt_behavior() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.prompt_text = "Press E: Unlock route"
	route.locked_prompt_text = "Cannot unlock yet"
	route.locked_route_message = "Route blocked"
	route.requirements = _failing_requirement_set("Need reward")
	assert_str(route.get_interaction_text()).is_equal("Need reward")

	route.requirements = null
	assert_str(route.get_interaction_text()).is_equal("Press E: Unlock route")

	route.unlock_route(null, "script")
	route.stay_available_after_unlock = false
	assert_str(route.get_interaction_text()).is_equal("")

	route.stay_available_after_unlock = true
	route.unlocked_prompt_text = "Route already open"
	assert_str(route.get_interaction_text()).is_equal("Route already open")

	_restore_game_state(snapshot)
	_free_route(route)


func test_visual_target_toggling_and_warnings() -> void:
	var route := _spawn_route()
	var blocked_visual := ColorRect.new()
	blocked_visual.name = "RouteBlockedVisual"
	blocked_visual.visible = true
	route.add_child(blocked_visual)

	var open_visual := ColorRect.new()
	open_visual.name = "RouteOpenVisual"
	open_visual.visible = false
	route.add_child(open_visual)

	var show_paths: Array[NodePath] = [NodePath("RouteOpenVisual")]
	var hide_paths: Array[NodePath] = [NodePath("RouteBlockedVisual")]
	route.nodes_to_show = show_paths
	route.nodes_to_hide = hide_paths

	var result: Dictionary = route.apply_route_targets()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(open_visual.visible).is_true()
	assert_bool(blocked_visual.visible).is_false()

	var missing_paths: Array[NodePath] = [NodePath("MissingVisual")]
	route.nodes_to_show = missing_paths
	var warning_result: Dictionary = route.apply_route_targets()
	var warnings: Array = warning_result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)

	_free_route(route)


func test_collision_target_toggling() -> void:
	var route := _spawn_route()
	var blocker := CollisionShape2D.new()
	blocker.name = "RouteBlocker"
	blocker.disabled = false
	route.add_child(blocker)

	var passage := CollisionShape2D.new()
	passage.name = "RoutePassageShape"
	passage.disabled = true
	route.add_child(passage)

	var disable_paths: Array[NodePath] = [NodePath("RouteBlocker")]
	var enable_paths: Array[NodePath] = [NodePath("RoutePassageShape")]
	route.collisions_to_disable = disable_paths
	route.collisions_to_enable = enable_paths

	var result: Dictionary = route.apply_route_targets()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(blocker.disabled).is_true()
	assert_bool(passage.disabled).is_false()

	var missing_paths: Array[NodePath] = [NodePath("MissingCollider")]
	route.collisions_to_enable = missing_paths
	var warning_result: Dictionary = route.apply_route_targets()
	var warnings: Array = warning_result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)

	_free_route(route)


func test_interface_methods_route_to_unlock() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var route := _spawn_route()
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(route.interact()).is_true()
	assert_bool(route.route_unlocked).is_true()

	route.reset_route()
	route.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(route.on_interact()).is_true()

	route.reset_route()
	assert_bool(route.use()).is_true()

	route.reset_route()
	assert_bool(route.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_route(route)


func _spawn_route() -> Node:
	var route := RouteUnlockNodeScript.new()
	route.name = "TestRouteUnlockNode"
	add_child(route)
	return route


func _free_route(route: Node) -> void:
	if is_instance_valid(route):
		route.queue_free()


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


func _flag_requirement_set(flag_id: String, locked_message: String) -> RequirementSet:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = flag_id
	requirement.operator = MissionRequirement.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [requirement]
	req_set.locked_message = locked_message
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
		"selected_cards": GameState.selected_cards.duplicate(),
		"unlocked_cards": GameState.unlocked_cards.duplicate(),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	_restore_string_array(GameState.selected_cards, snapshot.get("selected_cards", []))
	_restore_string_array(GameState.unlocked_cards, snapshot.get("unlocked_cards", []))


func _restore_string_array(target: Array[String], previous: Variant) -> void:
	target.clear()
	if previous is Array:
		for item in previous:
			target.append(String(item))
