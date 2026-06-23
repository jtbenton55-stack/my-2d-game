@tool
class_name DoorStateMemoryNode
extends MechanicAreaBase

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")

@export_group("Door Memory")
@export var door_id: StringName = &"door_memory"
@export_enum("opened", "closed", "forced", "left_ajar") var door_state: String = "opened"
@export var trace_id: StringName = &""
@export_range(0, 5, 1) var trace_severity: int = 2
@export var can_cleanup: bool = true
@export var cleanup_requirement: StringName = &"wipe_down"
@export var opened_flag: StringName = &""
@export var mark_opened_flag: bool = true

var last_memory_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Use door"
	display_name = "Door State Memory"
	preview_color = Color(0.75, 0.55, 1.0, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["door_id"] = String(door_id)
	context["door_state"] = door_state
	context["trace_id"] = _resolved_trace_id()
	return context


func record_door_memory(actor: Node = null, reason: String = "interact") -> Dictionary:
	var context := build_context(actor)
	last_memory_result = _record_trace(context, reason)
	return last_memory_result


func apply_success_effects(context: Dictionary) -> Dictionary:
	last_memory_result = _record_trace(context, "success")
	if not bool(last_memory_result.get("ok", false)):
		return last_memory_result
	var flag_result := _set_opened_flag(context)
	var effect_result := super.apply_success_effects(context)
	return _result(
		bool(effect_result.get("ok", true)),
		"door_memory_recorded",
		"Door memory trace recorded.",
		String(mechanic_id),
		{"memory_result": last_memory_result, "opened_flag_result": flag_result, "effect_result": effect_result}
	)


func get_memory_summary() -> Dictionary:
	return {
		"door_id": String(door_id),
		"door_state": door_state,
		"trace_id": _resolved_trace_id(),
		"trace_severity": trace_severity,
		"cleanup_requirement": String(cleanup_requirement),
		"last_memory_result": last_memory_result.duplicate(true),
	}


func _record_trace(context: Dictionary, reason: String) -> Dictionary:
	var payload := {
		"door_id": String(door_id),
		"door_state": door_state,
		"reason": reason,
	}
	return PaperTrailAdapterScript.record_trace(
		_resolved_trace_id(),
		String(door_id),
		"door_memory",
		trace_severity,
		can_cleanup,
		String(cleanup_requirement),
		context,
		payload
	)


func _set_opened_flag(context: Dictionary) -> Dictionary:
	if not mark_opened_flag:
		return _result(true, "opened_flag_skipped", "Opened flag skipped.")
	var flag := String(opened_flag).strip_edges()
	if flag == "":
		flag = "%s_%s" % [String(door_id), door_state]
	return MissionFactBridge.set_fact_value(&"mission_flag", flag, true, context)


func _resolved_trace_id() -> String:
	var explicit := String(trace_id).strip_edges()
	if explicit != "":
		return explicit
	return "%s_%s_trace" % [String(door_id), door_state]


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	return "DOOR MEMORY %s" % String(door_id)
