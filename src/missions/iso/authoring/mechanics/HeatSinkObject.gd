@tool
class_name HeatSinkObject
extends MechanicAreaBase

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

@export_group("Heat Sink")
@export var heat_sink_id: StringName = &"heat_sink"
@export var explanation_id: StringName = &"plausible_misdirection"
@export var target_trace_id: StringName = &""
@export_enum("any", "generic", "camera_seen", "door_memory", "audit_log", "evidence_touch", "noise", "witness") var target_trace_type: String = "any"
@export var target_source_id: StringName = &""
@export_range(0, 5, 1) var severity_reduction: int = 1

var last_redirect_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Plant misdirection"
	display_name = "Heat Sink Object"
	preview_color = Color(0.95, 0.65, 0.2, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["heat_sink_id"] = String(heat_sink_id)
	context["explanation_id"] = String(explanation_id)
	return context


func redirect_trace(actor: Node = null, reason: String = "interact") -> Dictionary:
	var context := build_context(actor)
	last_redirect_result = PaperTrailAdapterScript.redirect_traces(_criteria(), String(explanation_id), context)
	last_redirect_result["details"]["reason"] = reason
	return last_redirect_result


func apply_success_effects(context: Dictionary) -> Dictionary:
	last_redirect_result = PaperTrailAdapterScript.redirect_traces(_criteria(), String(explanation_id), context)
	if not bool(last_redirect_result.get("ok", false)):
		return last_redirect_result
	var effect_result := super.apply_success_effects(context)
	return _result(
		bool(effect_result.get("ok", true)),
		"heat_sink_applied",
		"Heat sink applied.",
		String(mechanic_id),
		{"redirect_result": last_redirect_result, "effect_result": effect_result}
	)


func get_heat_sink_summary() -> Dictionary:
	return {
		"heat_sink_id": String(heat_sink_id),
		"explanation_id": String(explanation_id),
		"target_trace_id": String(target_trace_id),
		"target_trace_type": target_trace_type,
		"severity_reduction": severity_reduction,
		"last_redirect_result": last_redirect_result.duplicate(true),
	}


func _criteria() -> Dictionary:
	return {
		"trace_id": String(target_trace_id),
		"trace_type": "" if target_trace_type == "any" else target_trace_type,
		"source_id": String(target_source_id),
		"severity_reduction": severity_reduction,
	}


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	return "HEAT SINK %s" % String(heat_sink_id)
