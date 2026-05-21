# GdUnit4 smoke tests for Packet 2B-3A MissionInteractionBridge.
extends GdUnitTestSuite

const MissionInteractionBridgeScript := preload("res://src/missions/iso/runtime/authoring/MissionInteractionBridge.gd")
const TriggerZoneScript := preload("res://src/missions/iso/authoring/mechanics/TriggerZone.gd")


func test_collects_mission_mechanic_and_generic_interactable() -> void:
	var bridge := _spawn_bridge()
	var mechanic: Node = TriggerZoneScript.new()
	mechanic.name = "MissionMechanic"
	mechanic.add_to_group("mission_mechanic")
	add_child(mechanic)

	var generic := _MockInteractCandidate.new()
	generic.name = "GenericInteractable"
	generic.add_to_group("interactable")
	add_child(generic)

	var collected: Array = bridge.collect_candidates()
	assert_int(collected.size()).is_equal(2)
	assert_bool(collected.has(mechanic)).is_true()
	assert_bool(collected.has(generic)).is_true()

	_teardown(bridge, [mechanic, generic])


func test_collects_generic_interactable_without_generated_by() -> void:
	var bridge := _spawn_bridge()
	var generic := _MockInteractCandidate.new()
	generic.name = "NoMetadataInteractable"
	generic.add_to_group("interactable")
	add_child(generic)

	var collected: Array = bridge.collect_candidates()
	assert_int(collected.size()).is_equal(1)
	assert_bool(collected.has(generic)).is_true()

	_teardown(bridge, [generic])


func test_include_legacy_candidates_false_ignores_phase0j_groups() -> void:
	var bridge := _spawn_bridge()
	bridge.include_legacy_candidates = false
	var mechanic: Node = TriggerZoneScript.new()
	mechanic.name = "PilotMechanic"
	mechanic.add_to_group("mission_mechanic")
	add_child(mechanic)

	var legacy := _MockInteractCandidate.new()
	legacy.name = "LegacyPhase0J"
	legacy.add_to_group("phase0j_interactable")
	add_child(legacy)

	var louis := _MockInteractCandidate.new()
	louis.name = "LegacyLouis"
	louis.add_to_group("phase0k_louis_exit")
	add_child(louis)

	var collected: Array = bridge.collect_candidates()
	assert_int(collected.size()).is_equal(1)
	assert_bool(collected.has(mechanic)).is_true()

	_teardown(bridge, [mechanic, legacy, louis])


func test_interact_method_activates_candidate() -> void:
	var bridge := _spawn_bridge()
	var candidate := _MockInteractCandidate.new()
	candidate.global_position = Vector2.ZERO
	candidate.add_to_group("interactable")
	add_child(candidate)

	assert_bool(bridge.try_interact_at_position(Vector2.ZERO)).is_true()
	assert_bool(candidate.interact_called).is_true()
	assert_object(bridge.last_candidate).is_same(candidate)

	_teardown(bridge, [candidate])


func test_use_only_candidate_can_be_activated() -> void:
	var bridge := _spawn_bridge()
	var candidate := _MockUseOnlyCandidate.new()
	candidate.global_position = Vector2.ZERO
	candidate.add_to_group("interactable")
	add_child(candidate)

	assert_bool(bridge.try_interact_at_position(Vector2.ZERO)).is_true()
	assert_bool(candidate.use_called).is_true()

	_teardown(bridge, [candidate])


func test_method_order_prefers_interact_over_use() -> void:
	var bridge := _spawn_bridge()
	var candidate := _MockDualMethodCandidate.new()
	candidate.global_position = Vector2.ZERO
	candidate.add_to_group("interactable")
	add_child(candidate)

	assert_bool(bridge.try_interact_at_position(Vector2.ZERO)).is_true()
	assert_bool(candidate.interact_called).is_true()
	assert_bool(candidate.use_called).is_false()

	_teardown(bridge, [candidate])


func test_higher_priority_wins() -> void:
	var bridge := _spawn_bridge()
	var low := _MockInteractCandidate.new()
	low.priority = 100
	low.global_position = Vector2(10, 0)
	low.add_to_group("interactable")
	add_child(low)

	var high := _MockInteractCandidate.new()
	high.priority = 900
	high.global_position = Vector2(20, 0)
	high.add_to_group("interactable")
	add_child(high)

	var entry: Dictionary = bridge.find_best_candidate(Vector2.ZERO, false)
	assert_object(entry.get("node")).is_same(high)

	_teardown(bridge, [low, high])


func test_closer_candidate_wins_when_priority_ties() -> void:
	var bridge := _spawn_bridge()
	var near := _MockInteractCandidate.new()
	near.priority = 500
	near.global_position = Vector2(10, 0)
	near.add_to_group("interactable")
	add_child(near)

	var far := _MockInteractCandidate.new()
	far.priority = 500
	far.global_position = Vector2(80, 0)
	far.add_to_group("interactable")
	add_child(far)

	var entry: Dictionary = bridge.find_best_candidate(Vector2.ZERO, false)
	assert_object(entry.get("node")).is_same(near)

	_teardown(bridge, [near, far])


func test_available_wins_when_prefer_available() -> void:
	var bridge := _spawn_bridge()
	bridge.prefer_available = true
	var unavailable := _MockInteractCandidate.new()
	unavailable.available = false
	unavailable.priority = 900
	unavailable.global_position = Vector2(5, 0)
	unavailable.add_to_group("interactable")
	add_child(unavailable)

	var available := _MockInteractCandidate.new()
	available.available = true
	available.priority = 100
	available.global_position = Vector2(50, 0)
	available.add_to_group("interactable")
	add_child(available)

	var entry: Dictionary = bridge.find_best_candidate(Vector2.ZERO, false)
	assert_object(entry.get("node")).is_same(available)

	_teardown(bridge, [unavailable, available])


func test_uncompleted_wins_when_prefer_uncompleted() -> void:
	var bridge := _spawn_bridge()
	bridge.prefer_uncompleted = true
	var completed := _MockInteractCandidate.new()
	completed.completed = true
	completed.priority = 900
	completed.global_position = Vector2(5, 0)
	completed.add_to_group("interactable")
	add_child(completed)

	var active := _MockInteractCandidate.new()
	active.completed = false
	active.priority = 100
	active.global_position = Vector2(50, 0)
	active.add_to_group("interactable")
	add_child(active)

	var entry: Dictionary = bridge.find_best_candidate(Vector2.ZERO, false)
	assert_object(entry.get("node")).is_same(active)

	_teardown(bridge, [completed, active])


func test_find_best_candidate_excludes_unavailable_when_required() -> void:
	var bridge := _spawn_bridge()
	var unavailable := _MockInteractCandidate.new()
	unavailable.available = false
	unavailable.global_position = Vector2.ZERO
	unavailable.add_to_group("interactable")
	add_child(unavailable)

	assert_bool(bridge.find_best_candidate(Vector2.ZERO, true).is_empty()).is_true()
	assert_bool(bridge.find_best_candidate(Vector2.ZERO, false).is_empty()).is_false()

	_teardown(bridge, [unavailable])


func test_prompt_priority_and_completed_helpers() -> void:
	var bridge := _spawn_bridge()
	var candidate := _MockInteractCandidate.new()
	candidate.prompt_text = "Press E: Test"
	candidate.priority = 777
	candidate.completed = true
	add_child(candidate)

	assert_str(bridge.get_candidate_prompt(candidate)).is_equal("Press E: Test")
	assert_int(bridge.get_candidate_priority(candidate)).is_equal(777)

	var plain := Node2D.new()
	plain.name = "FallbackName"
	assert_str(bridge.get_candidate_prompt(plain)).is_equal("FallbackName")
	assert_int(bridge.get_candidate_priority(plain)).is_equal(300)
	assert_bool(bridge.is_candidate_completed(candidate)).is_true()

	plain.free()
	_teardown(bridge, [candidate])


func test_cooldown_blocks_immediate_repeat() -> void:
	var bridge := _spawn_bridge()
	bridge.cooldown_seconds = 1.0
	var candidate := _MockInteractCandidate.new()
	candidate.global_position = Vector2.ZERO
	candidate.add_to_group("interactable")
	add_child(candidate)

	assert_bool(bridge.try_interact_at_position(Vector2.ZERO)).is_true()
	candidate.interact_called = false
	assert_bool(bridge.try_interact_at_position(Vector2.ZERO)).is_false()
	assert_bool(candidate.interact_called).is_false()

	_teardown(bridge, [candidate])


func test_find_player_uses_explicit_path_and_group_fallback() -> void:
	var bridge := _spawn_bridge()
	var explicit := Node2D.new()
	explicit.name = "ExplicitPlayer"
	add_child(explicit)
	bridge.player_path = bridge.get_path_to(explicit)

	assert_object(bridge.find_player()).is_same(explicit)

	bridge.player_path = NodePath()
	explicit.queue_free()
	var grouped := Node2D.new()
	grouped.name = "GroupedPlayer"
	grouped.add_to_group("player")
	add_child(grouped)

	assert_object(bridge.find_player()).is_same(grouped)

	grouped.free()
	_teardown(bridge, [])


func _spawn_bridge() -> Node:
	var bridge: Node = MissionInteractionBridgeScript.new()
	bridge.name = "TestMissionInteractionBridge"
	bridge.interaction_radius = 500.0
	bridge.cooldown_seconds = 0.0
	bridge.prefer_available = true
	bridge.prefer_uncompleted = true
	add_child(bridge)
	return bridge


func _teardown(bridge: Node, nodes: Array) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	if is_instance_valid(bridge):
		bridge.queue_free()


class _MockInteractCandidate extends Node2D:
	var available: bool = true
	var completed: bool = false
	var priority: int = 300
	var prompt_text: String = ""
	var interact_called: bool = false

	func interact(_actor: Node = null) -> bool:
		interact_called = true
		return true

	func is_interaction_available(_actor: Node = null) -> bool:
		return available

	func is_completed() -> bool:
		return completed

	func get_interaction_priority(_actor: Node = null) -> int:
		return priority

	func get_interaction_text() -> String:
		return prompt_text


class _MockUseOnlyCandidate extends Node2D:
	var use_called: bool = false

	func use(_actor: Node = null) -> bool:
		use_called = true
		return true

	func is_interaction_available(_actor: Node = null) -> bool:
		return true


class _MockDualMethodCandidate extends Node2D:
	var interact_called: bool = false
	var use_called: bool = false

	func interact(_actor: Node = null) -> bool:
		interact_called = true
		return true

	func use(_actor: Node = null) -> bool:
		use_called = true
		return true

	func is_interaction_available(_actor: Node = null) -> bool:
		return true
