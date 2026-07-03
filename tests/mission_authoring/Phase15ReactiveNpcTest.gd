# GdUnit4 tests for Phase 15A-15I bounded reactive NPC/social consequence layer.
extends GdUnitTestSuite

const SignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const AttentionBudgetScript := preload("res://src/missions/iso/ai/NpcAttentionBudget.gd")
const ReactionRuleScript := preload("res://src/missions/iso/ai/SocialReactionRuleSet.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const InvestigationPointNodeScript := preload("res://src/missions/iso/authoring/mechanics/InvestigationPointNode.gd")
const RoutineOverrideNodeScript := preload("res://src/missions/iso/authoring/mechanics/RoutineOverrideNode.gd")


class FakeLimboAdapter:
	extends RefCounted

	func execute_reaction(reaction_id: String, signal_event: Resource, payload: Dictionary, _context: Dictionary = {}) -> Dictionary:
		return {
			"ok": true,
			"code": "fake_limbo_reaction",
			"message": "Fake Limbo adapter handled %s." % reaction_id,
			"source_id": String(signal_event.get("signal_id")),
			"details": payload.duplicate(true),
		}


func test_social_signal_event_validates_and_round_trips_records() -> void:
	var event := SignalEventScript.from_dictionary({
		"signal_id": "unit_signal",
		"signal_type": "suspicious_action_seen",
		"mission_id": "test_mission",
		"severity": 2,
		"position": Vector2(12, 34),
		"allowed_reaction_tags": ["inspect"],
	})
	assert_bool(event.validate().get("ok", false)).is_true()
	assert_bool(event.allows_reaction_tag("inspect")).is_true()
	assert_bool(event.allows_reaction_tag("report")).is_false()
	var record: Dictionary = event.to_record()
	assert_str(String(record.get("signal_id", ""))).is_equal("unit_signal")
	assert_vector(record.get("position", Vector2.ZERO)).is_equal(Vector2(12, 34))


func test_brain_adapter_records_signals_and_budgeted_fallback_reactions() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "unit", "npc_id": "guard_a", "now": 10.0}
	var event := _make_signal("signal_a", "suspicious_action_seen")
	var budget := AttentionBudgetScript.new()
	budget.cooldown_seconds = 30.0
	var rule := _make_rule("inspect_rule", "suspicious_action_seen", "inspect_point")
	var result: Dictionary = ReactiveNpcBrainAdapterScript.evaluate_signal(event, [rule], budget, context)
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_signal_recorded", "signal_a", context)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_reaction_recorded", "inspect_point", context)).is_true()
	assert_int(int(MissionFactBridge.get_fact_value(&"reactive_signal_type_count", "suspicious_action_seen", context))).is_equal(1)

	var second := _make_signal("signal_b", "suspicious_action_seen")
	var denied: Dictionary = ReactiveNpcBrainAdapterScript.evaluate_signal(second, [rule], budget, context)
	assert_bool(denied.get("ok", true)).is_false()
	var summary := ReactiveNpcBrainAdapterScript.get_summary("test_mission")
	assert_int(int(summary.get("signal_count", 0))).is_equal(2)
	_restore_game_state(snapshot)


func test_effects_and_facts_route_through_reactive_adapter() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "effect_test"}
	var record_effect := MissionEffectScript.new()
	record_effect.effect_type = MissionEffectScript.EffectType.RECORD_SOCIAL_SIGNAL
	record_effect.key = "effect_signal"
	record_effect.payload = {"signal_type": "trace_found", "severity": 3}
	assert_bool(record_effect.apply(context).get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_signal_recorded", "effect_signal", context)).is_true()

	var tag_effect := MissionEffectScript.new()
	tag_effect.effect_type = MissionEffectScript.EffectType.SET_REACTIVE_NPC_RESULT_TAG
	tag_effect.key = "witness_noticed"
	tag_effect.value_bool = true
	assert_bool(tag_effect.apply(context).get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_result_tag", "witness_noticed", context)).is_true()
	_restore_game_state(snapshot)


func test_authoring_nodes_emit_bounded_reactive_signals() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var budget := AttentionBudgetScript.new()
	budget.cooldown_seconds = 0.0
	var inspect_rule := _make_rule("inspect_rule", "suspicious_action_seen", "inspect_point")
	var investigation := InvestigationPointNodeScript.new()
	investigation.mission_id_override = "test_mission"
	investigation.mechanic_id = &"unit_investigation"
	investigation.investigation_point_id = &"unit_investigation"
	investigation.investigated_flag = &"unit_investigated"
	investigation.reaction_rule_sets = [inspect_rule]
	investigation.attention_budget = budget
	add_child(investigation)
	assert_bool(investigation.investigate(null, "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:unit_investigated", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_reaction_recorded", "inspect_point", {"mission_id": "test_mission"})).is_true()

	var routine_rule := _make_rule("routine_rule", "route_tampered", "change_patrol")
	var routine := RoutineOverrideNodeScript.new()
	routine.mission_id_override = "test_mission"
	routine.mechanic_id = &"unit_routine"
	routine.routine_id = &"guard_loop"
	routine.override_id = &"guard_loop_override"
	routine.routine_override_flag = &"guard_loop_override_active"
	routine.reaction_rule_sets = [routine_rule]
	routine.attention_budget = budget
	add_child(routine)
	assert_bool(routine.apply_override(null, "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:guard_loop_override_active", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"reactive_reaction_recorded", "change_patrol", {"mission_id": "test_mission"})).is_true()
	_restore_game_state(snapshot)
	_free_node(investigation)
	_free_node(routine)


func test_mission_result_receives_reactive_npc_summary_and_limbo_is_adapter_gated() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	GameState.start_mission("test_mission")
	var rule := _make_rule("limbo_rule", "suspicious_action_seen", "look_toward")
	var event := _make_signal("limbo_signal", "suspicious_action_seen")
	ReactiveNpcBrainAdapterScript.evaluate_signal(event, [rule], AttentionBudgetScript.new(), {"mission_id": "test_mission", "limbo_reactive_npc_adapter": FakeLimboAdapter.new()})
	var result: Dictionary = GameState.complete_mission("test_mission")
	assert_bool(result.has("reactive_npc")).is_true()
	assert_str(String(result.get("reactive_npc_state", ""))).is_equal("noticed")
	var summary: Dictionary = result.get("reactive_npc", {})
	assert_bool(summary.get("limbo_adapter_used", false)).is_true()
	_restore_game_state(snapshot)


func test_templates_and_proof_scene_contain_phase15_nodes_and_buttons() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/InvestigationPointNodeTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/RoutineOverrideNodeTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase15ReactiveNpcProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/InvestigationPointNode_phase15_ignore")).is_instanceof(InvestigationPointNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/InvestigationPointNode_phase15_inspect")).is_instanceof(InvestigationPointNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/InvestigationPointNode_phase15_report")).is_instanceof(InvestigationPointNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/RoutineOverrideNode_phase15_route")).is_instanceof(RoutineOverrideNodeScript)
	assert_object(root.find_child("Run Ignored Signal", true, false)).is_not_null()
	assert_object(root.find_child("Run Investigation Reaction", true, false)).is_not_null()
	assert_object(root.find_child("Run Authority Report", true, false)).is_not_null()
	assert_object(root.find_child("Run Routine Override", true, false)).is_not_null()
	_free_node(root)


func _make_signal(signal_id: String, signal_type: String) -> Resource:
	var event := SignalEventScript.new()
	event.signal_id = StringName(signal_id)
	event.signal_type = StringName(signal_type)
	event.mission_id = "test_mission"
	event.severity = 2
	return event


func _make_rule(rule_id: String, signal_type: String, reaction_id: String) -> Resource:
	var rule := ReactionRuleScript.new()
	rule.rule_id = StringName(rule_id)
	rule.accepted_signal_types = [StringName(signal_type)]
	rule.reaction_id = StringName(reaction_id)
	rule.target_investigation_point_id = &"unit_target"
	rule.target_authority_id = &"unit_authority"
	return rule


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(true),
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.completed_missions = (snapshot.get("completed_missions", []) as Array).duplicate(true)
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	ReactiveNpcBrainAdapterScript.clear_all()


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
