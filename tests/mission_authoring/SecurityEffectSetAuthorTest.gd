# GdUnit4 tests for Phase 4A security event -> EffectSet authoring bridge.
extends GdUnitTestSuite

const SecurityEffectSetAuthorScript := preload("res://src/missions/iso/authoring/SecurityEffectSetAuthor.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")
const ProofScene := preload("res://scenes/dev/mission_authoring/SecurityEffectSetAuthorProofRoom.tscn")

const TEST_MISSION_ID := "security_effect_set_test"


func test_security_event_applies_effect_set_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var author := _spawn_author(&"camera_alarm", _mission_flag_effect("camera_alarm_seen"))
	var result: Dictionary = author.on_security_event(&"camera_alarm", {"source_id": "test_camera"})

	assert_bool(result.get("handled", false)).is_true()
	assert_str(String(result.get("result", ""))).is_equal("effect_set_applied")
	assert_str(String(result.get("effect_type", ""))).is_equal("effect_set")
	assert_bool(GameState.dialogue_flags.get("mission_flag:%s:camera_alarm_seen" % TEST_MISSION_ID, false)).is_true()

	_restore_game_state(snapshot)
	_free_node(author)


func test_unmatched_security_event_does_not_apply_effect_set() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var author := _spawn_author(&"camera_alarm", _mission_flag_effect("should_not_set"))
	var result: Dictionary = author.on_security_event(&"beam_trip", {"source_id": "test_beam"})

	assert_bool(result.get("handled", true)).is_false()
	assert_str(String(result.get("reason", ""))).is_equal("event_not_listened")
	assert_bool(GameState.dialogue_flags.has("mission_flag:%s:should_not_set" % TEST_MISSION_ID)).is_false()

	_restore_game_state(snapshot)
	_free_node(author)


func test_missing_effect_set_rejects_security_event() -> void:
	var author := SecurityEffectSetAuthorScript.new()
	author.name = "MissingEffectSetAuthor"
	author.effect_id = &"missing_effect_set"
	author.trigger_events = [&"camera_alarm"]
	author.mission_id_override = TEST_MISSION_ID
	add_child(author)

	var result: Dictionary = author.on_security_event(&"camera_alarm", {})

	assert_bool(result.get("handled", true)).is_false()
	assert_str(String(result.get("result", ""))).is_equal("rejected")
	assert_str(String(result.get("reason", ""))).is_equal("rejected_missing_effect_set")

	_free_node(author)


func test_debug_summary_exposes_effect_chain_result() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	GameState.current_mission_id = TEST_MISSION_ID

	var author := _spawn_author(&"camera_alarm", _mission_flag_effect("debug_summary_seen"))
	author.debug_chain_label = "Camera alarm -> debug summary flag"
	var result: Dictionary = author.on_security_event(&"camera_alarm", {"source_id": "test_camera"})
	var summary: Dictionary = author.call("get_security_effect_debug_summary")

	assert_bool(result.get("handled", false)).is_true()
	assert_str(String(summary.get("effect_type", ""))).is_equal("effect_set")
	assert_str(String(summary.get("effect_set_id", ""))).is_equal("security_event_effect_set")
	assert_str(String(summary.get("last_result", ""))).is_equal("effect_set_applied")
	assert_int(int(summary.get("last_applied_count", 0))).is_equal(1)

	_restore_game_state(snapshot)
	_free_node(author)


func test_dev_scene_security_event_applies_effect_set() -> void:
	var scene := ProofScene.instantiate()
	add_child(scene)
	await get_tree().process_frame

	var result: Dictionary = scene.call("emit_phase4b_test_event")
	var summary: Dictionary = scene.call("get_phase4b_debug_summary")

	assert_bool(result.get("handled", false)).is_true()
	assert_bool(scene.call("is_phase4b_flag_set")).is_true()
	assert_int(int(summary.get("registered_event_count", 0))).is_equal(1)
	assert_int(int(summary.get("effect_set_count", 0))).is_equal(1)
	assert_str(String(summary.get("last_effect_type", ""))).is_equal("effect_set")

	_free_node(scene)


func _spawn_author(trigger_event: StringName, effect: MissionEffect) -> Node:
	var author := SecurityEffectSetAuthorScript.new()
	author.name = "SecurityEffectSetAuthorUnderTest"
	author.effect_id = &"security_event_effects"
	author.trigger_events = [trigger_event]
	author.mission_id_override = TEST_MISSION_ID
	var set := EffectSetScript.new()
	set.set_id = &"security_event_effect_set"
	set.effects = [effect]
	author.effects = set
	add_child(author)
	return author


func _mission_flag_effect(flag_id: String) -> MissionEffect:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	return effect


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
