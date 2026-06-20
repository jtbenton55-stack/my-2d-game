# GdUnit4 tests for Phase 7A-7D-lite CompanionCommandPoint.
extends GdUnitTestSuite

const CompanionCommandPointScript := preload("res://src/missions/iso/authoring/mechanics/CompanionCommandPoint.gd")
const BentleyCrawlspaceConnectorScript := preload("res://src/missions/iso/authoring/mechanics/BentleyCrawlspaceConnector.gd")
const BentleyWaitMarkerScript := preload("res://src/missions/iso/authoring/mechanics/BentleyWaitMarker.gd")
const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const DogCompanionScript := preload("res://src/player/DogCompanion.gd")
const MissionRequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_companion_command_point_extends_mechanic_area_base() -> void:
	var point := CompanionCommandPointScript.new()
	assert_object(point).is_instanceof(MechanicAreaBaseScript)
	point.free()


func test_bark_command_calls_companion_and_applies_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var companion := _MockCompanion.new()
	companion.add_to_group("bentley")
	add_child(companion)
	var point := _spawn_point("bark")
	point.success_effects = _set_mission_flag_effect_set("phase7_bark_used")

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("companion_command_succeeded")
	assert_array(companion.calls).contains("bark")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase7_bark_used", false)).is_true()
	assert_str(String(point.last_command_result.get("code", ""))).is_equal("bark_executed")

	_restore_game_state(snapshot)
	_free_node(point)
	_free_node(companion)


func test_requirement_failure_blocks_companion_command() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var companion := _MockCompanion.new()
	companion.add_to_group("bentley")
	add_child(companion)
	var point := _spawn_point("sniff")
	point.requirements = _missing_flag_requirement_set()
	point.success_effects = _set_mission_flag_effect_set("should_not_fire")
	point.failure_effects = _set_mission_flag_effect_set("phase7_command_blocked")

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("requirements_failed")
	assert_int(companion.calls.size()).is_equal(0)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:should_not_fire", false)).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase7_command_blocked", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(point)
	_free_node(companion)


func test_missing_companion_returns_clean_failure() -> void:
	var point := _spawn_point("fetch")

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", true)).is_false()
	assert_str(String(result.get("code", ""))).is_equal("companion_missing")
	assert_str(String(point.last_command_result.get("code", ""))).is_equal("companion_missing")

	_free_node(point)


func test_fetch_command_calls_companion_fetch_method() -> void:
	var companion := _MockCompanion.new()
	companion.add_to_group("bentley")
	add_child(companion)
	var point := _spawn_point("fetch")

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_array(companion.calls).contains("fetch")
	assert_str(String(point.last_command_result.get("code", ""))).is_equal("fetch_executed")

	_free_node(point)
	_free_node(companion)


func test_crawlspace_connector_calls_companion_and_applies_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var companion := _MockCompanion.new()
	companion.add_to_group("bentley")
	add_child(companion)
	var point := BentleyCrawlspaceConnectorScript.new()
	point.name = "TestBentleyCrawlspaceConnector"
	point.mission_id_override = "test_mission"
	point.one_shot = false
	point.mechanic_id = &"test_crawlspace_command"
	point.success_effects = _set_mission_flag_effect_set("phase7_crawlspace_used")
	add_child(point)

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(point.get("command_type"))).is_equal("crawlspace")
	assert_array(companion.calls).contains("crawlspace")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase7_crawlspace_used", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(point)
	_free_node(companion)


func test_wait_marker_calls_companion_and_applies_effects() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var companion := _MockCompanion.new()
	companion.add_to_group("bentley")
	add_child(companion)
	var point := BentleyWaitMarkerScript.new()
	point.name = "TestBentleyWaitMarker"
	point.mission_id_override = "test_mission"
	point.one_shot = false
	point.mechanic_id = &"test_wait_command"
	point.success_effects = _set_mission_flag_effect_set("phase7_wait_marker_used")
	add_child(point)

	var result: Dictionary = point.run_command(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(point.get("command_type"))).is_equal("wait")
	assert_array(companion.calls).contains("wait")
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase7_wait_marker_used", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(point)
	_free_node(companion)


func test_dog_companion_public_command_api() -> void:
	var dog := DogCompanionScript.new()
	dog.name = "BentleyUnderTest"
	add_child(dog)
	dog.ability_meter = 0.0
	var bark_blocked: Dictionary = dog.command_bark()
	assert_bool(bark_blocked.get("ok", true)).is_false()
	assert_str(String(bark_blocked.get("code", ""))).is_equal("bark_not_ready")

	var sniff: Dictionary = dog.command_sniff()
	assert_bool(sniff.get("ok", false)).is_true()
	assert_str(String(sniff.get("code", ""))).is_equal("sniff_executed")
	var sniff_cooldown: Dictionary = dog.command_sniff()
	assert_bool(sniff_cooldown.get("ok", true)).is_false()
	assert_str(String(sniff_cooldown.get("code", ""))).is_equal("sniff_cooldown")

	_free_node(dog)


func test_dog_companion_wait_and_crawlspace_commands_hold_position() -> void:
	var dog := DogCompanionScript.new()
	dog.name = "BentleyWaitUnderTest"
	dog.global_position = Vector2.ZERO
	add_child(dog)

	var wait_result: Dictionary = dog.command_wait(null, {"position": Vector2(32, 16)})
	assert_bool(wait_result.get("ok", false)).is_true()
	assert_str(String(wait_result.get("code", ""))).is_equal("wait_executed")
	assert_bool(bool(dog.get_command_state().get("staying", false))).is_true()
	assert_vector(dog.global_position).is_equal(Vector2(32, 16))

	var crawl_result: Dictionary = dog.command_crawlspace(null, {"position": Vector2(96, -24)})
	assert_bool(crawl_result.get("ok", false)).is_true()
	assert_str(String(crawl_result.get("code", ""))).is_equal("crawlspace_executed")
	assert_bool(bool(dog.get_command_state().get("staying", false))).is_true()
	assert_vector(dog.global_position).is_equal(Vector2(96, -24))

	_free_node(dog)


func test_dog_companion_fetch_interacts_with_fetchable_node() -> void:
	var dog := DogCompanionScript.new()
	dog.name = "BentleyFetchUnderTest"
	dog.fetch_range = 200.0
	dog.global_position = Vector2.ZERO
	add_child(dog)
	var fetchable := _MockFetchable.new()
	fetchable.name = "FetchableKeycard"
	fetchable.placeholder_id = "keycard"
	fetchable.global_position = Vector2(24, 0)
	fetchable.add_to_group("interactable")
	add_child(fetchable)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	var result: Dictionary = dog.command_fetch(player)
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(result.get("code", ""))).is_equal("fetch_executed")
	assert_bool(fetchable.interacted).is_true()

	_free_node(player)
	_free_node(fetchable)
	_free_node(dog)


func test_card_modifiers_tune_bentley_fetch_range_and_cooldowns() -> void:
	var snapshot := _snapshot_game_state()
	GameState.selected_cards.clear()
	GameState.selected_cards.append("fish_treat_focus")
	var dog := DogCompanionScript.new()
	dog.name = "BentleyCardUnderTest"
	dog.fetch_range = 50.0
	dog.fetch_cooldown = 10.0
	dog.sniff_cooldown = 10.0
	dog.global_position = Vector2.ZERO
	add_child(dog)
	var fetchable := _MockFetchable.new()
	fetchable.name = "CardRangeFetchable"
	fetchable.placeholder_id = "keycard"
	fetchable.global_position = Vector2(70, 0)
	fetchable.add_to_group("interactable")
	add_child(fetchable)

	var fetch_result: Dictionary = dog.command_fetch()
	assert_bool(fetch_result.get("ok", false)).is_true()
	assert_float(float((fetch_result.get("details", {}) as Dictionary).get("fetch_range", 0.0))).is_equal(75.0)
	assert_float(float((fetch_result.get("details", {}) as Dictionary).get("cooldown", 0.0))).is_equal(7.5)
	var sniff_result: Dictionary = dog.command_sniff()
	assert_bool(sniff_result.get("ok", false)).is_true()
	assert_float(float((sniff_result.get("details", {}) as Dictionary).get("cooldown", 0.0))).is_equal(6.5)

	_restore_game_state(snapshot)
	_free_node(fetchable)
	_free_node(dog)


func test_dev_scene_contains_phase7_command_points() -> void:
	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)

	var bark := root.get_node_or_null("MissionMechanics/CompanionCommandPoint_phase7_bark")
	var sniff := root.get_node_or_null("MissionMechanics/CompanionCommandPoint_phase7_sniff")
	var fetch := root.get_node_or_null("MissionMechanics/CompanionCommandPoint_phase7_fetch")
	var crawlspace := root.get_node_or_null("MissionMechanics/BentleyCrawlspaceConnector_phase7e")
	var wait_marker := root.get_node_or_null("MissionMechanics/BentleyWaitMarker_phase7f")
	assert_object(bark).is_not_null()
	assert_object(sniff).is_not_null()
	assert_object(fetch).is_not_null()
	assert_object(crawlspace).is_not_null()
	assert_object(wait_marker).is_not_null()
	assert_str(String(bark.get("command_type"))).is_equal("bark")
	assert_str(String(sniff.get("command_type"))).is_equal("sniff")
	assert_str(String(fetch.get("command_type"))).is_equal("fetch")
	assert_str(String(crawlspace.get("command_type"))).is_equal("crawlspace")
	assert_str(String(wait_marker.get("command_type"))).is_equal("wait")

	root.queue_free()


func _spawn_point(command_type: String) -> Node:
	var point := CompanionCommandPointScript.new()
	point.name = "TestCompanionCommandPoint"
	point.mission_id_override = "test_mission"
	point.one_shot = false
	point.command_type = command_type
	point.mechanic_id = StringName("test_%s_command" % command_type)
	add_child(point)
	return point


func _set_mission_flag_effect_set(flag_id: String) -> Resource:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	var set := EffectSetScript.new()
	set.effects = [effect]
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


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


class _MockCompanion extends Node2D:
	var calls: Array = []

	func command_bark(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
		calls.append("bark")
		return {"ok": true, "code": "bark_executed", "message": "Mock bark.", "details": {}}

	func command_sniff(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
		calls.append("sniff")
		return {"ok": true, "code": "sniff_executed", "message": "Mock sniff.", "details": {}}

	func command_fetch(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
		calls.append("fetch")
		return {"ok": true, "code": "fetch_executed", "message": "Mock fetch.", "details": {}}

	func command_crawlspace(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
		calls.append("crawlspace")
		return {"ok": true, "code": "crawlspace_executed", "message": "Mock crawlspace.", "details": {}}

	func command_wait(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
		calls.append("wait")
		return {"ok": true, "code": "wait_executed", "message": "Mock wait.", "details": {}}


class _MockFetchable extends Node2D:
	var placeholder_id := ""
	var interacted := false

	func interact(_actor: Node = null) -> bool:
		interacted = true
		return true
