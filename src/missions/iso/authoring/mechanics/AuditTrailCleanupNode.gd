@tool
class_name AuditTrailCleanupNode
extends MechanicAreaBase

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

@export_group("Paper Trail Cleanup")
@export var cleanup_id: StringName = &"audit_cleanup"
@export var target_trace_id: StringName = &""
@export_enum("any", "generic", "camera_seen", "door_memory", "audit_log", "evidence_touch", "noise", "witness") var target_trace_type: String = "any"
@export var target_source_id: StringName = &""
@export var cleanup_requirement: StringName = &""
@export_enum("clean", "weaken") var cleanup_mode: String = "clean"
@export_range(1, 5, 1) var cleanup_strength: int = 5

var last_cleanup_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Clean audit trail"
	display_name = "Audit Trail Cleanup"
	one_shot = false
	preview_color = Color(0.35, 0.9, 0.55, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["cleanup_id"] = String(cleanup_id)
	context["target_trace_id"] = String(target_trace_id)
	context["target_trace_type"] = target_trace_type
	return context


func cleanup_trace(actor: Node = null, reason: String = "interact") -> Dictionary:
	var context := build_context(actor)
	var criteria := _criteria()
	criteria["cleanup_mode"] = cleanup_mode
	criteria["cleanup_strength"] = cleanup_strength
	last_cleanup_result = PaperTrailAdapterScript.cleanup_traces(criteria, context)
	last_cleanup_result["details"]["reason"] = reason
	return last_cleanup_result


func apply_success_effects(context: Dictionary) -> Dictionary:
	last_cleanup_result = PaperTrailAdapterScript.cleanup_traces(_criteria(), context)
	if not bool(last_cleanup_result.get("ok", false)):
		return last_cleanup_result
	var effect_result := super.apply_success_effects(context)
	return _result(
		bool(effect_result.get("ok", true)),
		"audit_cleanup_applied",
		"Audit cleanup applied.",
		String(mechanic_id),
		{"cleanup_result": last_cleanup_result, "effect_result": effect_result}
	)


func get_cleanup_summary() -> Dictionary:
	return {
		"cleanup_id": String(cleanup_id),
		"target_trace_id": String(target_trace_id),
		"target_trace_type": target_trace_type,
		"cleanup_requirement": String(cleanup_requirement),
		"cleanup_mode": cleanup_mode,
		"last_cleanup_result": last_cleanup_result.duplicate(true),
	}


func _criteria() -> Dictionary:
	return {
		"trace_id": String(target_trace_id),
		"trace_type": "" if target_trace_type == "any" else target_trace_type,
		"source_id": String(target_source_id),
		"cleanup_requirement": String(cleanup_requirement),
		"cleanup_mode": cleanup_mode,
		"cleanup_strength": cleanup_strength,
	}


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	return "CLEANUP %s" % String(cleanup_id)
