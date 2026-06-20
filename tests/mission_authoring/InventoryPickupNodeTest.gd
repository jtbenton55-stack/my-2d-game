# GdUnit4 tests for Phase 5D-lite InventoryPickupNode.
extends GdUnitTestSuite

const InventoryPickupNodeScript := preload("res://src/missions/iso/authoring/mechanics/InventoryPickupNode.gd")
const RewardNodeScript := preload("res://src/missions/iso/authoring/mechanics/RewardNode.gd")
const RouteUnlockNodeScript := preload("res://src/missions/iso/authoring/mechanics/RouteUnlockNode.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const IsoMissionDebugPanelScript := preload("res://src/missions/iso/runtime/IsoMissionDebugPanel.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")


func test_inventory_pickup_extends_reward_node() -> void:
	var pickup := InventoryPickupNodeScript.new()
	assert_object(pickup).is_instanceof(RewardNodeScript)
	pickup.free()


func test_successful_pickup_grants_item_once() -> void:
	var snapshot := _snapshot_game_state()
	MissionInventoryScript.clear_all()
	var pickup := _spawn_pickup("delivery_badge", 1)

	var result: Dictionary = pickup.collect(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("reward_collected")
	assert_int(MissionInventoryScript.get_item_count("delivery_badge")).is_equal(1)
	assert_bool(result.get("details", {}).has("item_grant_result")).is_true()

	var second: Dictionary = pickup.collect(null, "script")
	assert_bool(second.get("ok", false)).is_true()
	assert_str(String(second.get("code", ""))).is_equal("already_collected")
	assert_int(MissionInventoryScript.get_item_count("delivery_badge")).is_equal(1)

	_restore_game_state(snapshot)
	_free_node(pickup)


func test_requirement_failure_does_not_grant_item() -> void:
	var snapshot := _snapshot_game_state()
	MissionInventoryScript.clear_all()
	GameState.dialogue_flags.clear()
	var pickup := _spawn_pickup("vault_key", 1)
	pickup.requirements = _missing_flag_requirement_set()

	var result: Dictionary = pickup.collect(null, "script")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_int(MissionInventoryScript.get_item_count("vault_key")).is_equal(0)

	_restore_game_state(snapshot)
	_free_node(pickup)


func test_collected_flag_still_uses_reward_node_flow() -> void:
	var snapshot := _snapshot_game_state()
	MissionInventoryScript.clear_all()
	GameState.dialogue_flags.clear()
	var pickup := _spawn_pickup("route_manifest", 1)
	pickup.collected_flag = &"route_manifest_collected"

	var result: Dictionary = pickup.collect(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:route_manifest_collected", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(pickup)


func test_pickup_item_requirement_unlocks_route() -> void:
	var snapshot := _snapshot_game_state()
	MissionInventoryScript.clear_all()
	GameState.dialogue_flags.clear()
	var pickup := _spawn_pickup("delivery_badge", 1)
	var route := _spawn_route_requiring_item("delivery_badge")

	var blocked: Dictionary = route.unlock_route(null, "script")
	assert_bool(blocked.get("ok", true)).is_false()
	assert_str(String(blocked.get("code", ""))).is_equal("requirements_failed")

	assert_bool(pickup.collect(null, "script").get("ok", false)).is_true()
	var opened: Dictionary = route.unlock_route(null, "script")
	assert_bool(opened.get("ok", false)).is_true()
	assert_str(String(opened.get("code", ""))).is_equal("route_unlocked")

	_restore_game_state(snapshot)
	_free_node(pickup)
	_free_node(route)


func test_dev_scene_contains_phase5d_pickup_route_chain() -> void:
	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)

	var pickup := root.get_node_or_null("MissionMechanics/InventoryPickupNode_phase5d_delivery_badge")
	var route := root.get_node_or_null("MissionMechanics/RouteUnlockNode_phase5d_badge_route")
	assert_object(pickup).is_not_null()
	assert_object(route).is_not_null()
	assert_str(String(pickup.get("item_id"))).is_equal("delivery_badge")
	assert_object(route.get("requirements")).is_not_null()

	root.queue_free()


func test_f10_debug_line_shows_mission_inventory_snapshot() -> void:
	MissionInventoryScript.clear_all()
	MissionInventoryScript.add_item("delivery_badge", 1, {"category": "credential", "stackable": true, "max_stack": 1})
	var panel := IsoMissionDebugPanelScript.new()

	var line: String = panel.call("_format_mission_inventory_line")
	assert_str(line).contains("mission_inv")
	assert_str(line).contains("delivery_badge x1 [credential]")

	panel.free()
	MissionInventoryScript.clear_all()


func _spawn_pickup(item_id: String, count: int) -> Node:
	var pickup := InventoryPickupNodeScript.new()
	pickup.name = "TestInventoryPickup"
	pickup.mission_id_override = "test_mission"
	pickup.one_shot = false
	pickup.item_id = StringName(item_id)
	pickup.item_count = count
	pickup.item_category = "credential"
	pickup.item_stackable = true
	pickup.item_max_stack = 5
	pickup.reward_id = StringName(item_id)
	add_child(pickup)
	return pickup


func _spawn_route_requiring_item(item_id: String) -> Node:
	var route := RouteUnlockNodeScript.new()
	route.name = "TestInventoryRoute"
	route.mission_id_override = "test_mission"
	route.one_shot = false
	route.route_id = &"delivery_badge_route"
	route.route_flag = &"delivery_badge_route_open"
	route.requirements = _item_requirement_set(item_id)
	add_child(route)
	return route


func _item_requirement_set(item_id: String) -> Resource:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"inventory_has_item"
	requirement.key = item_id
	requirement.operator = MissionRequirementScript.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var set := RequirementSetScript.new()
	set.requirements = [requirement]
	set.locked_message = "Need %s." % item_id
	return set


func _missing_flag_requirement_set() -> Resource:
	var requirement := MissionRequirementScript.new()
	requirement.fact_type = &"mission_flag"
	requirement.key = "missing_flag"
	requirement.operator = MissionRequirementScript.Operator.EXISTS
	requirement.expected_value_type = "exists"
	var set := RequirementSetScript.new()
	set.requirements = [requirement]
	return set


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


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
	MissionInventoryScript.clear_all()
