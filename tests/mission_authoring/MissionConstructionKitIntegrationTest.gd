# GdUnit4 integration tests for Packet 2B-10 construction-kit multi-instance isolation.
extends GdUnitTestSuite

const RewardNodeScript := preload("res://src/missions/iso/authoring/mechanics/RewardNode.gd")
const SearchZoneScript := preload("res://src/missions/iso/authoring/mechanics/SearchZone.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const SideObjectiveNodeScript := preload("res://src/missions/iso/authoring/mechanics/SideObjectiveNode.gd")
const ObjectiveStepControllerScript := preload("res://src/missions/iso/authoring/core/ObjectiveStepController.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")

const TEST_MISSION_ID := "construction_kit_test"


func test_two_reward_nodes_do_not_cross_contaminate() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var reward_a := _spawn_reward("RewardA", &"dev_multi_reward_a", &"dev_multi_reward_a_collected")
	var reward_b := _spawn_reward("RewardB", &"dev_multi_reward_b", &"dev_multi_reward_b_collected")

	var result_a: Dictionary = reward_a.collect(null, "script")
	assert_bool(result_a.get("ok", false)).is_true()
	assert_bool(reward_a.collected).is_true()
	assert_bool(reward_b.collected).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:%s:dev_multi_reward_a_collected" % TEST_MISSION_ID, false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:%s:dev_multi_reward_b_collected" % TEST_MISSION_ID)).is_false()
	assert_str(String(result_a.get("details", {}).get("reward_id", ""))).is_equal("dev_multi_reward_a")
	assert_str(String(result_a.get("source_id", ""))).is_equal("dev_multi_reward_a")

	var repeat_a: Dictionary = reward_a.collect(null, "script")
	assert_str(String(repeat_a.get("code", ""))).is_equal("already_collected")
	var result_b: Dictionary = reward_b.collect(null, "script")
	assert_bool(result_b.get("ok", false)).is_true()
	assert_str(String(result_b.get("details", {}).get("reward_id", ""))).is_equal("dev_multi_reward_b")

	_restore_game_state(snapshot)
	_free_node(reward_a)
	_free_node(reward_b)


func test_two_search_zones_do_not_cross_contaminate() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var search_a := _spawn_search("SearchA", &"dev_multi_search_a_searched")
	var search_b := _spawn_search("SearchB", &"dev_multi_search_b_searched")

	var result_a: Dictionary = search_a.search(null, "script")
	assert_bool(result_a.get("ok", false)).is_true()
	assert_bool(search_a.searched).is_true()
	assert_bool(search_b.searched).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:%s:dev_multi_search_a_searched" % TEST_MISSION_ID, false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:%s:dev_multi_search_b_searched" % TEST_MISSION_ID)).is_false()

	var repeat_a: Dictionary = search_a.search(null, "script")
	assert_str(String(repeat_a.get("code", ""))).is_equal("already_searched")
	var result_b: Dictionary = search_b.search(null, "script")
	assert_bool(result_b.get("ok", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(search_a)
	_free_node(search_b)


func test_two_route_unlock_nodes_do_not_cross_contaminate() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var route_a := _spawn_route("RouteA", &"dev_multi_route_a", &"dev_multi_route_a_open")
	var route_b := _spawn_route("RouteB", &"dev_multi_route_b", &"dev_multi_route_b_open")

	var result_a: Dictionary = route_a.unlock_route(null, "script")
	assert_bool(result_a.get("ok", false)).is_true()
	assert_bool(route_a.route_unlocked).is_true()
	assert_bool(route_b.route_unlocked).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:%s:dev_multi_route_a_open" % TEST_MISSION_ID, false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:%s:dev_multi_route_b_open" % TEST_MISSION_ID)).is_false()
	assert_str(String(result_a.get("details", {}).get("route_id", ""))).is_equal("dev_multi_route_a")

	var repeat_a: Dictionary = route_a.unlock_route(null, "script")
	assert_str(String(repeat_a.get("code", ""))).is_equal("already_unlocked")
	var result_b: Dictionary = route_b.unlock_route(null, "script")
	assert_bool(result_b.get("ok", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(route_a)
	_free_node(route_b)


func test_two_side_objective_nodes_do_not_cross_contaminate() -> void:
	var game_snapshot := _snapshot_game_state()
	var quest_snapshot := _snapshot_quest_manager()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var node_a := _spawn_side_objective("SideA", &"dev_side_a", &"dev_side_a_handled")
	var node_b := _spawn_side_objective("SideB", &"dev_side_b", &"dev_side_b_handled")

	node_a.handle_objective(null, "script")
	assert_bool(node_a.handled).is_true()
	assert_bool(node_b.handled).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:%s:dev_side_a_handled" % TEST_MISSION_ID, false)).is_true()
	assert_bool(GameState.dialogue_flags.has("mission_flag:%s:dev_side_b_handled" % TEST_MISSION_ID)).is_false()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_side_a", TEST_MISSION_ID)).is_true()
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_side_b", TEST_MISSION_ID)).is_false()

	var repeat_a: Dictionary = node_a.handle_objective(null, "script")
	assert_str(String(repeat_a.get("code", ""))).is_equal("already_handled")
	node_b.handle_objective(null, "script")
	assert_bool(ObjectiveStepControllerScript.is_objective_active("dev_side_b", TEST_MISSION_ID)).is_true()

	_restore_quest_manager(quest_snapshot)
	_restore_game_state(game_snapshot)
	_free_node(node_a)
	_free_node(node_b)


func _spawn_reward(node_name: String, reward_id: StringName, collected_flag: StringName) -> RewardNode:
	var reward := RewardNodeScript.new()
	reward.name = node_name
	reward.mission_id_override = TEST_MISSION_ID
	reward.mechanic_id = reward_id
	reward.reward_id = reward_id
	reward.collected_flag = collected_flag
	reward.one_shot = false
	reward.mark_collected_on_success = true
	reward.stay_available_after_collect = false
	add_child(reward)
	return reward


func _spawn_search(node_name: String, searched_flag: StringName) -> SearchZone:
	var search := SearchZoneScript.new()
	search.name = node_name
	search.mission_id_override = TEST_MISSION_ID
	search.mechanic_id = searched_flag
	search.searched_flag = searched_flag
	search.one_shot = true
	search.mark_searched_on_success = true
	search.stay_available_after_search = false
	add_child(search)
	return search


func _spawn_route(node_name: String, route_id: StringName, route_flag: StringName) -> RouteUnlockNode:
	var route := RouteUnlockNodeScript.new()
	route.name = node_name
	route.mission_id_override = TEST_MISSION_ID
	route.mechanic_id = route_id
	route.route_id = route_id
	route.route_flag = route_flag
	route.one_shot = false
	route.mark_unlocked_on_success = true
	route.stay_available_after_unlock = false
	add_child(route)
	return route


func _spawn_side_objective(node_name: String, objective_id: StringName, objective_flag: StringName) -> SideObjectiveNode:
	var node := SideObjectiveNodeScript.new()
	node.name = node_name
	node.mission_id_override = TEST_MISSION_ID
	node.mechanic_id = objective_id
	node.objective_id = objective_id
	node.objective_action = SideObjectiveNodeScript.ObjectiveAction.ACTIVATE
	node.objective_flag = objective_flag
	node.one_shot = false
	node.mark_handled_on_success = true
	node.stay_available_after_handled = false
	add_child(node)
	return node


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


func _snapshot_quest_manager() -> Dictionary:
	return {
		"active_quest_id": QuestManager.active_quest_id,
		"active_objective": QuestManager.active_objective,
		"objectives": QuestManager.objectives.duplicate(true),
		"objective_records": QuestManager.objective_records.duplicate(true),
		"active_objectives": QuestManager.active_objectives.duplicate(true),
		"completed_objectives": QuestManager.completed_objectives.duplicate(true),
	}


func _restore_quest_manager(snapshot: Dictionary) -> void:
	QuestManager.active_quest_id = String(snapshot.get("active_quest_id", ""))
	QuestManager.active_objective = String(snapshot.get("active_objective", ""))
	QuestManager.objectives = (snapshot.get("objectives", {}) as Dictionary).duplicate(true)
	QuestManager.objective_records = (snapshot.get("objective_records", {}) as Dictionary).duplicate(true)
	QuestManager.active_objectives = (snapshot.get("active_objectives", {}) as Dictionary).duplicate(true)
	QuestManager.completed_objectives = (snapshot.get("completed_objectives", {}) as Dictionary).duplicate(true)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
