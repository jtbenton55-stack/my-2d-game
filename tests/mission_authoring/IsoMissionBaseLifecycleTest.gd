extends GdUnitTestSuite

const IsoMissionBaseScript := preload("res://src/levels/IsoMissionBase.gd")
const VELVET_SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"


func before() -> void:
	_reset_game_state()


func after() -> void:
	_reset_game_state()


func test_ensure_node_frees_unused_fallback_and_returns_existing() -> void:
	var parent := Node.new()
	add_child(parent)
	var existing := Node.new()
	existing.name = "Existing"
	parent.add_child(existing)
	var fallback := Node.new()
	var fallback_id := fallback.get_instance_id()
	var mission: Node = IsoMissionBaseScript.new()

	var result: Node = mission.call("_ensure_node", parent, "Existing", fallback)

	assert_object(result).is_same(existing)
	assert_bool(is_instance_id_valid(fallback_id)).is_false()
	assert_object(mission.call("_ensure_node", parent, "Existing", existing)).is_same(existing)
	assert_object(mission.call("_ensure_node", parent, "Existing", null)).is_same(existing)
	mission.free()
	parent.free()


func test_ensure_node_attaches_valid_fallback_when_child_is_missing() -> void:
	var parent := Node.new()
	add_child(parent)
	var fallback := Node.new()
	var mission: Node = IsoMissionBaseScript.new()

	var result: Node = mission.call("_ensure_node", parent, "Attached", fallback)

	assert_object(result).is_same(fallback)
	assert_object(parent.get_node_or_null("Attached")).is_same(fallback)
	assert_bool(is_instance_valid(fallback)).is_true()
	assert_object(fallback.get_parent()).is_same(parent)
	mission.free()
	parent.free()


func test_minimal_iso_mission_lifecycle_is_teardown_safe() -> void:
	var orphan_ids_before := get_tree().root.get_orphan_node_ids()
	var mission: Node = IsoMissionBaseScript.new()
	mission.set("dev_harness_enabled", false)
	add_child(mission)
	await get_tree().process_frame
	await _free_runtime_node(mission)

	assert_array(_new_orphan_ids(orphan_ids_before)).is_empty()


func test_velvet_scene_lifecycle_twice_does_not_accumulate_orphans() -> void:
	var packed := load(VELVET_SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var orphan_ids_before := get_tree().root.get_orphan_node_ids()

	for cycle in range(2):
		var mission := packed.instantiate()
		add_child(mission)
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().process_frame
		assert_bool(mission.is_inside_tree()).override_failure_message("Velvet cycle %d did not enter the tree." % cycle).is_true()
		assert_str(GameState.current_mission_id).is_equal("velvet_paw_jazz_club")
		await _free_runtime_node(mission)
		assert_array(_new_orphan_ids(orphan_ids_before)).override_failure_message("Velvet cycle %d introduced orphan IDs." % cycle).is_empty()


func _free_runtime_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _new_orphan_ids(ids_before: Array[int]) -> Array[int]:
	var new_ids: Array[int] = []
	for id: int in get_tree().root.get_orphan_node_ids():
		if not ids_before.has(id):
			new_ids.append(id)
	new_ids.sort()
	return new_ids


func _reset_game_state() -> void:
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	GameState.velvet_paw_club_hostile = false
	GameState.velvet_paw_basement_shard_collected = false
	GameState.velvet_paw_basement_keycard_collected = false
	for key: Variant in GameState.dialogue_flags.keys():
		if String(key).begins_with("mission_flag:velvet_paw_jazz_club:"):
			GameState.dialogue_flags.erase(key)
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()
