@tool
class_name InvestigationPointNode
extends MechanicAreaBase

const SignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")

@export_group("Reactive NPC")
@export var investigation_point_id: StringName = &""
@export var signal_type: StringName = SignalEventScript.SIGNAL_SUSPICIOUS_ACTION_SEEN
@export var signal_severity: int = 1
@export var signal_confidence: float = 1.0
@export var witness_group: StringName = &"witness"
@export var allowed_reaction_tags: Array[StringName] = []
@export var reaction_rule_sets: Array[Resource] = []
@export var attention_budget: Resource
@export var investigated_flag: StringName = &""


func _init() -> void:
	prompt_text = "Press E: Investigate"
	locked_prompt_text = "Investigation unavailable"
	preview_color = Color(0.95, 0.75, 0.25, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["investigation_point_id"] = String(_resolved_investigation_point_id())
	context["reaction_rule_sets"] = reaction_rule_sets
	if attention_budget != null:
		context["attention_budget"] = attention_budget
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)) and not Engine.is_editor_hint():
		last_activation_result = _run_reactive_investigation(actor, reason, result)
		activation_succeeded.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
	return last_activation_result if not last_activation_result.is_empty() else result


func investigate(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _run_reactive_investigation(actor: Node, reason: String, base_result: Dictionary) -> Dictionary:
	var context := build_context(actor)
	context["reason"] = reason
	var event := _build_signal(context)
	var reactive_result := ReactiveNpcBrainAdapterScript.evaluate_signal(event, reaction_rule_sets, attention_budget, context)
	_set_investigated_flag(context)
	return _result(bool(reactive_result.get("ok", false)), "investigation_reactive_result", "Investigation point emitted a bounded reactive NPC signal.", String(mechanic_id), {"base_result": base_result, "reactive_result": reactive_result})


func _build_signal(context: Dictionary) -> Resource:
	var event := SignalEventScript.new()
	event.signal_id = StringName("%s_signal" % String(_resolved_investigation_point_id()))
	event.signal_type = signal_type
	event.source_id = _resolved_investigation_point_id()
	event.source_node_path = get_path()
	event.mission_id = String(context.get("mission_id", ""))
	event.zone_id = StringName(String(context.get("investigation_point_id", "")))
	event.severity = signal_severity
	event.confidence = signal_confidence
	event.position = global_position
	event.witness_group = witness_group
	event.allowed_reaction_tags = allowed_reaction_tags
	event.debug_summary = "Investigation point %s emitted %s." % [String(_resolved_investigation_point_id()), String(signal_type)]
	return event


func _set_investigated_flag(context: Dictionary) -> void:
	var flag := String(investigated_flag).strip_edges()
	if flag == "":
		return
	MissionFactBridge.set_fact_value(&"mission_flag", flag, true, context)


func _resolved_investigation_point_id() -> StringName:
	if investigation_point_id != &"":
		return investigation_point_id
	return mechanic_id
