@tool
class_name PaperTrailTraceEvent
extends Resource

const STATUS_ACTIVE := "active"
const STATUS_CLEANED := "cleaned"
const STATUS_REDIRECTED := "redirected"

@export var trace_id: StringName = &"trace_event"
@export var mission_id: String = ""
@export var source_id: StringName = &"source"
@export_enum("generic", "camera_seen", "door_memory", "audit_log", "evidence_touch", "noise", "witness", "cleanup", "misdirection") var trace_type: String = "generic"
@export_range(0, 5, 1) var severity: int = 1
@export var can_cleanup: bool = true
@export var cleanup_requirement: StringName = &""
@export var created_at: int = 0
@export var status: String = STATUS_ACTIVE
@export var redirected_to: StringName = &""
@export var payload: Dictionary = {}


static func make_event(
	trace_id_value: String,
	mission_id_value: String,
	source_id_value: String,
	trace_type_value: String,
	severity_value: int = 1,
	can_cleanup_value: bool = true,
	cleanup_requirement_value: String = "",
	extra_payload: Dictionary = {}
) -> Dictionary:
	var now := Time.get_unix_time_from_system()
	return {
		"trace_id": trace_id_value,
		"mission_id": mission_id_value,
		"source_id": source_id_value,
		"trace_type": trace_type_value,
		"severity": clampi(severity_value, 0, 5),
		"original_severity": clampi(severity_value, 0, 5),
		"can_cleanup": can_cleanup_value,
		"cleanup_requirement": cleanup_requirement_value,
		"created_at": now,
		"status": STATUS_ACTIVE,
		"redirected_to": "",
		"cleaned_at": 0,
		"payload": extra_payload.duplicate(true),
	}


func to_dictionary() -> Dictionary:
	return {
		"trace_id": String(trace_id),
		"mission_id": mission_id,
		"source_id": String(source_id),
		"trace_type": trace_type,
		"severity": severity,
		"can_cleanup": can_cleanup,
		"cleanup_requirement": String(cleanup_requirement),
		"created_at": created_at,
		"status": status,
		"redirected_to": String(redirected_to),
		"payload": payload.duplicate(true),
	}


static func debug_summary(event: Dictionary) -> String:
	return "%s/%s severity=%d status=%s" % [
		String(event.get("trace_id", "")),
		String(event.get("trace_type", "generic")),
		int(event.get("severity", 0)),
		String(event.get("status", STATUS_ACTIVE)),
	]
