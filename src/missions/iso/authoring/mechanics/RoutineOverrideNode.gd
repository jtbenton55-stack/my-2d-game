@tool
class_name RoutineOverrideNode
extends MechanicAreaBase

const SignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")

@export_group("Routine Override")
@export var routine_id: StringName = &""
@export var override_id: StringName = &""
@export var routine_override_flag: StringName = &""
@export var signal_type: StringName = SignalEventScript.SIGNAL_ROUTE_TAMPERED
@export var signal_severity: int = 2
@export var reaction_rule_sets: Array[Resource] = []
@export var attention_budget: Resource


func _init() -> void:
	prompt_text = "Press E: Override routine"
	locked_prompt_text = "Routine override unavailable"
	preview_color = Color(0.2, 0.85, 0.65, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["routine_id"] = String(_resolved_routine_id())
	context["routine_override_id"] = String(_resolved_override_id())
	context["reaction_rule_sets"] = reaction_rule_sets
	if attention_budget != null:
		context["attention_budget"] = attention_budget
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)) and not Engine.is_editor_hint():
		last_activation_result = _run_routine_override(actor, reason, result)
		activation_succeeded.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
	return last_activation_result if not last_activation_result.is_empty() else result


func apply_override(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _run_routine_override(actor: Node, reason: String, base_result: Dictionary) -> Dictionary:
	var context := build_context(actor)
	context["reason"] = reason
	var flag := String(routine_override_flag).strip_edges()
	if flag == "":
		flag = "%s_override_active" % String(_resolved_routine_id())
	MissionFactBridge.set_fact_value(&"mission_flag", flag, true, context)
	var event := _build_signal(context)
	var reactive_result := ReactiveNpcBrainAdapterScript.evaluate_signal(event, reaction_rule_sets, attention_budget, context)
	return _result(bool(reactive_result.get("ok", false)), "routine_override_reactive_result", "Routine override emitted a bounded reactive NPC signal.", String(mechanic_id), {"base_result": base_result, "reactive_result": reactive_result, "routine_override_flag": flag})


func _build_signal(context: Dictionary) -> Resource:
	var event := SignalEventScript.new()
	event.signal_id = StringName("%s_signal" % String(_resolved_override_id()))
	event.signal_type = signal_type
	event.source_id = _resolved_override_id()
	event.source_node_path = get_path()
	event.mission_id = String(context.get("mission_id", ""))
	event.zone_id = _resolved_routine_id()
	event.severity = signal_severity
	event.confidence = 1.0
	event.position = global_position
	event.witness_group = &"routine_witness"
	event.debug_summary = "Routine %s overridden by %s." % [String(_resolved_routine_id()), String(_resolved_override_id())]
	return event


func _resolved_routine_id() -> StringName:
	if routine_id != &"":
		return routine_id
	return mechanic_id


func _resolved_override_id() -> StringName:
	if override_id != &"":
		return override_id
	return StringName("%s_override" % String(mechanic_id))
