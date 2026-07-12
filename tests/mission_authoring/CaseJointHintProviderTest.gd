extends GdUnitTestSuite

const BridgeScript := preload("res://src/missions/iso/runtime/authoring/MissionInteractionBridge.gd")
const DefinitionScript := preload("res://src/missions/iso/runtime/readability/CaseHintDefinition.gd")
const PlayerScript := preload("res://src/player/Player.gd")
const ProviderScript := preload("res://src/missions/iso/runtime/readability/MissionCaseHintProvider.gd")
const RequirementScript := preload("res://src/missions/iso/authoring/core/MissionRequirement.gd")
const RequirementSetScript := preload("res://src/missions/iso/authoring/core/RequirementSet.gd")


func test_bridge_q_does_not_interact_but_e_still_does() -> void:
	var bridge := _spawn_bridge()
	var player := Node2D.new()
	player.name = "Player"
	bridge.add_child(player)
	bridge.player_path = NodePath("Player")
	var candidate := _Candidate.new()
	candidate.add_to_group("interactable")
	add_child(candidate)

	var q_event := InputEventAction.new()
	q_event.action = &"case_the_joint"
	q_event.pressed = true
	bridge.call("_input", q_event)
	assert_int(candidate.calls).is_equal(0)

	var e_event := InputEventAction.new()
	e_event.action = &"interact"
	e_event.pressed = true
	bridge.call("_input", e_event)
	assert_int(candidate.calls).is_equal(1)

	candidate.queue_free()
	bridge.queue_free()


func test_bridge_prompt_refresh_is_callable_and_clears_out_of_range() -> void:
	var bridge := _spawn_bridge()
	bridge.interaction_radius = 50.0
	var player := Node2D.new()
	player.name = "Player"
	bridge.add_child(player)
	bridge.player_path = NodePath("Player")
	var label := Label.new()
	label.name = "Prompt"
	bridge.add_child(label)
	bridge.prompt_target_path = NodePath("Prompt")
	var candidate := _Candidate.new()
	candidate.prompt = "Press E"
	candidate.add_to_group("interactable")
	add_child(candidate)

	bridge.refresh_nearest_prompt()
	assert_str(label.text).is_equal("Press E")
	assert_bool(label.visible).is_true()
	player.global_position = Vector2(100.0, 0.0)
	bridge.refresh_nearest_prompt()
	assert_str(label.text).is_empty()
	assert_bool(label.visible).is_false()

	candidate.queue_free()
	bridge.queue_free()


func test_provider_filters_requirements_and_distance_then_uses_priority() -> void:
	var provider: Variant = _spawn_provider()
	var actor := Node2D.new()
	add_child(actor)
	var near_anchor := Node2D.new()
	near_anchor.name = "Near"
	provider.add_child(near_anchor)
	var far_anchor := Node2D.new()
	far_anchor.name = "Far"
	far_anchor.position = Vector2(200.0, 0.0)
	provider.add_child(far_anchor)

	var blocked: Variant = _hint("Blocked", 100)
	blocked.requirements = _failing_requirements()
	var distant: Variant = _hint("Distant", 90)
	distant.anchor_path = NodePath("Far")
	distant.max_distance = 50.0
	var low: Variant = _hint("Low", 10)
	low.anchor_path = NodePath("Near")
	low.max_distance = 50.0
	var high: Variant = _hint("High", 20)
	var definitions: Array[DefinitionScript] = [blocked, distant, low, high]
	provider.hints = definitions

	var result: Dictionary = provider.select_hint(actor, 1000)
	assert_bool(result.get("ok", false)).is_true()
	assert_object(result.get("definition")).is_same(high)

	actor.queue_free()
	provider.queue_free()


func test_provider_selection_is_stable_and_respects_per_hint_cooldown() -> void:
	var provider: Variant = _spawn_provider()
	var actor := Node2D.new()
	add_child(actor)
	var first: Variant = _hint("First", 10)
	first.cooldown = 2.0
	var second: Variant = _hint("Second", 10)
	var definitions: Array[DefinitionScript] = [first, second]
	provider.hints = definitions

	assert_object(provider.select_hint(actor, 1000).get("definition")).is_same(first)
	assert_object(provider.request_hint(actor, 1000).get("definition")).is_same(first)
	assert_object(provider.select_hint(actor, 1001).get("definition")).is_same(second)
	assert_object(provider.select_hint(actor, 3000).get("definition")).is_same(first)

	actor.queue_free()
	provider.queue_free()


func test_provider_uses_dedicated_hint_signal_not_objective_updates() -> void:
	var provider: Variant = _spawn_provider()
	var actor := Node2D.new()
	add_child(actor)
	var definitions: Array[DefinitionScript] = [_hint("Quiet route", 1)]
	provider.hints = definitions
	var case_messages: Array[String] = []
	var objective_messages: Array[String] = []
	var on_case := func(text: String, _speaker: String) -> void: case_messages.append(text)
	var on_objective := func(text: String) -> void: objective_messages.append(text)
	EventBus.case_hint_requested.connect(on_case)
	EventBus.objective_updated.connect(on_objective)

	assert_bool(provider.request_hint(actor, 1000).get("ok", false)).is_true()
	assert_array(case_messages).contains_exactly(["Quiet route"])
	assert_array(objective_messages).is_empty()

	EventBus.case_hint_requested.disconnect(on_case)
	EventBus.objective_updated.disconnect(on_objective)
	actor.queue_free()
	provider.queue_free()


func test_player_queries_only_one_grouped_provider_after_case_pulse() -> void:
	var first_provider := _ProviderProbe.new()
	first_provider.add_to_group("mission_case_hint_provider")
	add_child(first_provider)
	var second_provider := _ProviderProbe.new()
	second_provider.add_to_group("mission_case_hint_provider")
	add_child(second_provider)
	var player: CharacterBody2D = PlayerScript.new()
	player.case_joint_cooldown = 0.0
	add_child(player)

	player.call("_try_case_the_joint")
	assert_int(first_provider.calls).is_equal(1)
	assert_int(second_provider.calls).is_equal(0)

	player.queue_free()
	first_provider.queue_free()
	second_provider.queue_free()


func _spawn_bridge() -> MissionInteractionBridge:
	var bridge: MissionInteractionBridge = BridgeScript.new()
	bridge.cooldown_seconds = 0.0
	bridge.interaction_radius = 500.0
	add_child(bridge)
	return bridge


func _spawn_provider() -> Node:
	var provider: Node = ProviderScript.new()
	add_child(provider)
	return provider


func _hint(hint_text: String, hint_priority: int) -> Variant:
	var definition: Variant = DefinitionScript.new()
	definition.text = hint_text
	definition.priority = hint_priority
	return definition


func _failing_requirements() -> RequirementSet:
	var requirement: MissionRequirement = RequirementScript.new()
	requirement.fact_type = &"always"
	requirement.expected_bool = false
	var requirement_set: RequirementSet = RequirementSetScript.new()
	requirement_set.requirements = [requirement]
	return requirement_set


class _Candidate extends Node2D:
	var calls := 0
	var prompt := "Interact"

	func interact(_actor: Node = null) -> bool:
		calls += 1
		return true

	func get_interaction_text() -> String:
		return prompt


class _ProviderProbe extends Node:
	var calls := 0

	func request_hint(_actor: Node) -> Dictionary:
		calls += 1
		return {"ok": true}
