# GdUnit4 tests for Packet 2B-6 InteractiveContainer.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const SearchZoneScript := preload("res://src/missions/iso/authoring/mechanics/SearchZone.gd")
const InteractiveContainerScript := preload("res://src/missions/iso/authoring/mechanics/InteractiveContainer.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_interactive_container_extends_search_zone_and_mechanic_area_base() -> void:
	var container := InteractiveContainerScript.new()
	assert_object(container).is_instanceof(SearchZoneScript)
	assert_object(container).is_instanceof(MechanicAreaBaseScript)
	container.free()


func test_ready_groups_and_starts_open() -> void:
	var container := _spawn_container()
	assert_bool(container.is_in_group("interactable")).is_true()
	assert_bool(container.is_in_group("mission_mechanic")).is_true()
	assert_bool(container.is_in_group("phase0j_interactable")).is_false()
	assert_bool(container.opened).is_false()
	_free_container(container)

	var open_container := InteractiveContainerScript.new()
	open_container.name = "TestContainerOpen"
	open_container.starts_open = true
	add_child(open_container)
	assert_bool(open_container.opened).is_true()
	_free_container(open_container)


func test_successful_open_search() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false

	var result: Dictionary = container.open_container(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("container_opened")
	assert_bool(container.opened).is_true()
	assert_bool(container.searched).is_true()
	assert_bool(container.last_container_result.is_empty()).is_false()

	_restore_game_state(snapshot)
	_free_container(container)


func test_search_zone_reuse_and_no_duplicate_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false
	container.searched_flag = &"dev_container_searched"
	container.success_effects = _set_mission_flag_effect_set("dev_container_item")
	container.stay_available_after_search = false

	var first: Dictionary = container.open_container(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_container_searched", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_container_item", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:dev_container_item")

	var second: Dictionary = container.open_container(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_searched")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:dev_container_item")).is_false()

	_restore_game_state(snapshot)
	_free_container(container)


func test_opened_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false
	container.opened_flag = &"dev_locker_opened"

	var result: Dictionary = container.open_container(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_locker_opened", false)).is_true()

	_restore_game_state(snapshot)
	_free_container(container)


func test_requirement_gating_blocks_open_and_search() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = true
	container.requirements = _failing_requirement_set()
	container.success_effects = _set_mission_flag_effect_set("should_not_fire")
	container.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = container.open_container(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(container.opened).is_false()
	assert_bool(container.searched).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_container(container)


func test_close_container_keeps_searched_and_flags() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false
	container.opened_flag = &"dev_locker_opened"
	container.searched_flag = &"dev_locker_searched"
	container.success_effects = _set_mission_flag_effect_set("dev_locker_found_item")

	container.open_container(null, "script")
	assert_bool(container.searched).is_true()
	assert_bool(container.opened).is_true()

	var close_result: Dictionary = container.close_container(null, "script")
	assert_bool(close_result.get("ok", false)).is_true()
	assert_str(String(close_result.get("code", ""))).is_equal("container_closed")
	assert_bool(container.opened).is_false()
	assert_bool(container.searched).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_locker_opened", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_locker_searched", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_locker_found_item", false)).is_true()

	_restore_game_state(snapshot)
	_free_container(container)


func test_close_after_search_ends_closed() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false
	container.close_after_search = true
	container.success_effects = _set_mission_flag_effect_set("dev_locker_found_item")

	var result: Dictionary = container.open_container(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("container_searched_and_closed")
	assert_bool(container.searched).is_true()
	assert_bool(container.opened).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_locker_found_item", false)).is_true()

	_restore_game_state(snapshot)
	_free_container(container)


func test_prompt_behavior() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.prompt_text = "Press E: Open locker"
	container.open_prompt_text = "Open locker"
	container.locked_prompt_text = "Cannot open yet"
	container.requirements = _failing_requirement_set("Need key")
	assert_str(container.get_interaction_text()).is_equal("Need key")

	container.requirements = null
	assert_str(container.get_interaction_text()).is_equal("Press E: Open locker")

	container.open_container(null, "script")
	container.stay_available_after_search = false
	assert_str(container.get_interaction_text()).is_equal("")

	container.stay_available_after_search = true
	container.already_open_prompt_text = "Locker already open"
	assert_str(container.get_interaction_text()).is_equal("Locker already open")

	_restore_game_state(snapshot)
	_free_container(container)


func test_target_toggling_and_missing_path_warnings() -> void:
	var container := _spawn_container()
	var closed := ColorRect.new()
	closed.name = "LockerClosedVisual"
	closed.visible = true
	container.add_child(closed)

	var open_visual := ColorRect.new()
	open_visual.name = "LockerOpenVisual"
	open_visual.visible = false
	container.add_child(open_visual)

	container.closed_visual_path = NodePath("LockerClosedVisual")
	container.open_visual_path = NodePath("LockerOpenVisual")

	var open_result: Dictionary = container.apply_container_open_targets()
	assert_bool(open_result.get("ok", false)).is_true()
	assert_bool(closed.visible).is_false()
	assert_bool(open_visual.visible).is_true()

	var close_result: Dictionary = container.apply_container_closed_targets()
	assert_bool(close_result.get("ok", false)).is_true()
	assert_bool(closed.visible).is_true()
	assert_bool(open_visual.visible).is_false()

	var missing_paths: Array[NodePath] = [NodePath("MissingNode")]
	container.nodes_to_show_when_open = missing_paths
	var warning_result: Dictionary = container.apply_container_open_targets()
	var warnings: Array = warning_result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)

	_free_container(container)


func test_interface_methods_route_to_open_container() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var container := _spawn_container()
	container.mission_id_override = "test_mission"
	container.one_shot = false
	container.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(container.interact()).is_true()
	assert_bool(container.searched).is_true()

	container.searched = false
	container.opened = false
	container.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(container.on_interact()).is_true()

	container.searched = false
	container.opened = false
	container.success_effects = _set_mission_flag_effect_set("interface_flag_3")
	assert_bool(container.use()).is_true()

	container.searched = false
	container.opened = false
	assert_bool(container.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_container(container)


func _spawn_container() -> Node:
	var container := InteractiveContainerScript.new()
	container.name = "TestInteractiveContainer"
	add_child(container)
	return container


func _free_container(container: Node) -> void:
	if is_instance_valid(container):
		container.queue_free()


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
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
