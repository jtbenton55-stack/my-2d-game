# GdUnit4 tests for Packet 2B-4B SearchZone.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const SearchZoneScript := preload("res://src/missions/iso/authoring/mechanics/SearchZone.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_search_zone_extends_mechanic_area_base() -> void:
	var zone := SearchZoneScript.new()
	assert_object(zone).is_instanceof(MechanicAreaBaseScript)
	zone.free()


func test_ready_groups_and_starts_searched() -> void:
	var zone := _spawn_search()
	assert_bool(zone.is_in_group("interactable")).is_true()
	assert_bool(zone.is_in_group("mission_mechanic")).is_true()
	assert_bool(zone.is_in_group("phase0j_interactable")).is_false()
	assert_bool(zone.searched).is_false()
	_free_search(zone)

	var searched_zone := SearchZoneScript.new()
	searched_zone.name = "TestSearchZoneSearched"
	searched_zone.starts_searched = true
	add_child(searched_zone)
	assert_bool(searched_zone.searched).is_true()
	_free_search(searched_zone)


func test_successful_search_without_requirements() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.mission_id_override = "test_mission"
	zone.one_shot = true
	zone.success_effects = _set_mission_flag_effect_set("search_success_flag")

	var result: Dictionary = zone.search(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("activation_succeeded")
	assert_bool(zone.searched).is_true()
	assert_bool(zone.last_search_result.is_empty()).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:search_success_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_search(zone)


func test_searched_flag_sets_namespaced_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.mission_id_override = "test_mission"
	zone.searched_flag = &"dev_drawer_searched"
	zone.one_shot = false

	var result: Dictionary = zone.search(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:dev_drawer_searched", false)).is_true()

	_restore_game_state(snapshot)
	_free_search(zone)


func test_requirement_failure_prevents_search_and_can_apply_failure_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.mission_id_override = "test_mission"
	zone.one_shot = true
	zone.requirements = _failing_requirement_set()
	zone.success_effects = _set_mission_flag_effect_set("should_not_fire")
	zone.failure_effects = _set_mission_flag_effect_set("failure_flag")

	var result: Dictionary = zone.search(null, "script")
	assert_bool(result.get("ok", false)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_bool(zone.searched).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:failure_flag", false)).is_true()

	_restore_game_state(snapshot)
	_free_search(zone)


func test_already_searched_does_not_reapply_effects_when_not_staying_available() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.stay_available_after_search = false
	zone.success_effects = _set_mission_flag_effect_set("drawer_flag")

	var first: Dictionary = zone.search(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	GameState.dialogue_flags.erase("mission_flag:test_mission:drawer_flag")

	var second: Dictionary = zone.search(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_searched")
	assert_bool(GameState.dialogue_flags.has("mission_flag:test_mission:drawer_flag")).is_false()
	assert_bool(zone.is_interaction_available()).is_false()

	_restore_game_state(snapshot)
	_free_search(zone)


func test_prompt_behavior_for_unsearched_and_searched_states() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.prompt_text = "Press E: Search drawer"
	zone.locked_prompt_text = "Cannot search yet"
	zone.requirements = _failing_requirement_set("Need clearance")
	assert_str(zone.get_interaction_text()).is_equal("Need clearance")

	zone.requirements = null
	assert_str(zone.get_interaction_text()).is_equal("Press E: Search drawer")

	zone.search(null, "script")
	zone.stay_available_after_search = false
	assert_str(zone.get_interaction_text()).is_equal("")

	zone.stay_available_after_search = true
	zone.searched_prompt_text = "Drawer already searched"
	assert_str(zone.get_interaction_text()).is_equal("Drawer already searched")

	_restore_game_state(snapshot)
	_free_search(zone)


func test_target_toggling_show_hide_and_visual_shorthand() -> void:
	var zone := _spawn_search()
	var closed := ColorRect.new()
	closed.name = "DrawerClosedVisual"
	closed.visible = true
	zone.add_child(closed)

	var found := ColorRect.new()
	found.name = "DrawerFoundVisual"
	found.visible = false
	zone.add_child(found)

	zone.target_visual_path = NodePath("DrawerClosedVisual")
	var show_paths: Array[NodePath] = [NodePath("DrawerFoundVisual")]
	zone.nodes_to_show_on_search = show_paths

	var result: Dictionary = zone.apply_search_targets()
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(closed.visible).is_false()
	assert_bool(found.visible).is_true()

	_free_search(zone)


func test_missing_target_path_returns_warnings_without_crash() -> void:
	var zone := _spawn_search()
	var missing_paths: Array[NodePath] = [NodePath("MissingNode")]
	zone.nodes_to_show_on_search = missing_paths
	var result: Dictionary = zone.apply_search_targets()
	var warnings: Array = result.get("details", {}).get("warnings", [])
	assert_int(warnings.size()).is_greater(0)
	_free_search(zone)


func test_interface_methods_route_to_search() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()

	var zone := _spawn_search()
	zone.mission_id_override = "test_mission"
	zone.one_shot = false
	zone.success_effects = _set_mission_flag_effect_set("interface_flag")

	assert_bool(zone.interact()).is_true()
	assert_bool(zone.searched).is_true()

	zone.reset_search()
	zone.success_effects = _set_mission_flag_effect_set("interface_flag_2")
	assert_bool(zone.on_interact()).is_true()
	assert_bool(zone.use()).is_true()

	zone.reset_search()
	assert_bool(zone.inspect_marker()).is_true()

	_restore_game_state(snapshot)
	_free_search(zone)


func _spawn_search() -> Node:
	var zone: Node = SearchZoneScript.new()
	zone.name = "TestSearchZone"
	zone.interaction_mode = MechanicAreaBaseScript.InteractionMode.INTERACT_REQUIRED
	add_child(zone)
	return zone


func _free_search(zone: Node) -> void:
	if is_instance_valid(zone):
		zone.queue_free()


func _failing_requirement_set(locked_message: String = "") -> RequirementSet:
	var req := MissionRequirementScript.new()
	req.fact_type = &"mission_flag"
	req.key = "missing_flag"
	req.operator = MissionRequirementScript.Operator.EXISTS
	req.expected_value_type = "exists"
	var req_set := RequirementSetScript.new()
	req_set.requirements = [req]
	if locked_message != "":
		req_set.locked_message = locked_message
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
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
