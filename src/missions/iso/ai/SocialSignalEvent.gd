@tool
class_name SocialSignalEvent
extends Resource

const SIGNAL_NOISE_HEARD := &"noise_heard"
const SIGNAL_SUSPICIOUS_ACTION_SEEN := &"suspicious_action_seen"
const SIGNAL_CREDENTIAL_FAILED := &"credential_failed"
const SIGNAL_COVER_STORY_FAILED := &"cover_story_failed"
const SIGNAL_TRACE_FOUND := &"trace_found"
const SIGNAL_EVIDENCE_SPOTTED := &"evidence_spotted"
const SIGNAL_DISRUPTION_SEEN := &"disruption_seen"
const SIGNAL_ROUTE_TAMPERED := &"route_tampered"
const SIGNAL_PROTOCOL_BROKEN := &"protocol_broken"
const SIGNAL_CLEANLINESS_FAILED := &"cleanliness_failed"
const SIGNAL_ENCOUNTER_PRESSURE_SPIKE := &"encounter_pressure_spike"
const SIGNAL_BENTLEY_DISTRACTION_SEEN := &"bentley_distraction_seen"
const SIGNAL_AUTHORITY_CALLED := &"authority_called"

const KNOWN_SIGNAL_TYPES: Array[StringName] = [
	SIGNAL_NOISE_HEARD,
	SIGNAL_SUSPICIOUS_ACTION_SEEN,
	SIGNAL_CREDENTIAL_FAILED,
	SIGNAL_COVER_STORY_FAILED,
	SIGNAL_TRACE_FOUND,
	SIGNAL_EVIDENCE_SPOTTED,
	SIGNAL_DISRUPTION_SEEN,
	SIGNAL_ROUTE_TAMPERED,
	SIGNAL_PROTOCOL_BROKEN,
	SIGNAL_CLEANLINESS_FAILED,
	SIGNAL_ENCOUNTER_PRESSURE_SPIKE,
	SIGNAL_BENTLEY_DISTRACTION_SEEN,
	SIGNAL_AUTHORITY_CALLED,
]

@export var signal_id: StringName = &"signal"
@export var signal_type: StringName = SIGNAL_SUSPICIOUS_ACTION_SEEN
@export var source_id: StringName = &""
@export var source_node_path: NodePath
@export var mission_id: String = ""
@export var zone_id: StringName = &""
@export_range(0, 10, 1) var severity: int = 1
@export_range(0.0, 1.0, 0.01) var confidence: float = 1.0
@export var position: Vector2 = Vector2.ZERO
@export var created_time: float = 0.0
@export var expires_after_seconds: float = 10.0
@export var witness_group: StringName = &"witness"
@export var allowed_reaction_tags: Array[StringName] = []
@export var paper_trail_trace_id: StringName = &""
@export var social_context: Dictionary = {}
@export_multiline var debug_summary: String = ""


func ensure_created_time(now: float = -1.0) -> void:
	if created_time > 0.0:
		return
	created_time = now if now >= 0.0 else _now_seconds()


func is_expired(now: float = -1.0) -> bool:
	if expires_after_seconds <= 0.0:
		return false
	var current := now if now >= 0.0 else _now_seconds()
	return created_time > 0.0 and current - created_time > expires_after_seconds


func validate() -> Dictionary:
	var errors: Array[String] = []
	if String(signal_id).strip_edges() == "":
		errors.append("signal_id_missing")
	if not KNOWN_SIGNAL_TYPES.has(signal_type):
		errors.append("unknown_signal_type:%s" % String(signal_type))
	if severity < 0:
		errors.append("severity_negative")
	if confidence < 0.0 or confidence > 1.0:
		errors.append("confidence_out_of_range")
	var ok := errors.is_empty()
	return _result(ok, "signal_valid" if ok else "signal_invalid", "Signal is valid." if ok else "Signal validation failed.", String(signal_id), {"errors": errors, "signal_type": String(signal_type)})


func matches_type(type_id: String) -> bool:
	return String(signal_type) == type_id.strip_edges()


func allows_reaction_tag(tag: String) -> bool:
	var clean_tag := tag.strip_edges()
	if clean_tag == "" or allowed_reaction_tags.is_empty():
		return true
	return allowed_reaction_tags.has(StringName(clean_tag))


func to_record() -> Dictionary:
	return {
		"signal_id": String(signal_id),
		"signal_type": String(signal_type),
		"source_id": String(source_id),
		"source_node_path": str(source_node_path),
		"mission_id": mission_id,
		"zone_id": String(zone_id),
		"severity": severity,
		"confidence": confidence,
		"position": position,
		"created_time": created_time,
		"expires_after_seconds": expires_after_seconds,
		"witness_group": String(witness_group),
		"allowed_reaction_tags": _string_names_to_strings(allowed_reaction_tags),
		"paper_trail_trace_id": String(paper_trail_trace_id),
		"social_context": social_context.duplicate(true),
		"debug_summary": debug_summary,
	}


func get_debug_snapshot(now: float = -1.0) -> Dictionary:
	var validation := validate()
	var record := to_record()
	record["ok"] = bool(validation.get("ok", false))
	record["code"] = String(validation.get("code", "signal_debug"))
	record["expired"] = is_expired(now)
	record["known_signal_type"] = KNOWN_SIGNAL_TYPES.has(signal_type)
	return record


static func from_dictionary(data: Dictionary) -> Resource:
	var script := load("res://src/missions/iso/ai/SocialSignalEvent.gd") as Script
	var event: Resource = script.new()
	event.signal_id = StringName(String(data.get("signal_id", "signal")))
	event.signal_type = StringName(String(data.get("signal_type", SIGNAL_SUSPICIOUS_ACTION_SEEN)))
	event.source_id = StringName(String(data.get("source_id", "")))
	event.source_node_path = NodePath(String(data.get("source_node_path", "")))
	event.mission_id = String(data.get("mission_id", ""))
	event.zone_id = StringName(String(data.get("zone_id", "")))
	event.severity = int(data.get("severity", 1))
	event.confidence = float(data.get("confidence", 1.0))
	var raw_position: Variant = data.get("position", Vector2.ZERO)
	event.position = raw_position if raw_position is Vector2 else Vector2.ZERO
	event.created_time = float(data.get("created_time", 0.0))
	event.expires_after_seconds = float(data.get("expires_after_seconds", 10.0))
	event.witness_group = StringName(String(data.get("witness_group", "witness")))
	event.allowed_reaction_tags = _string_array_to_names(data.get("allowed_reaction_tags", []))
	event.paper_trail_trace_id = StringName(String(data.get("paper_trail_trace_id", "")))
	if data.get("social_context", null) is Dictionary:
		event.social_context = (data.get("social_context") as Dictionary).duplicate(true)
	event.debug_summary = String(data.get("debug_summary", ""))
	return event


static func is_known_signal_type(type_id: StringName) -> bool:
	return KNOWN_SIGNAL_TYPES.has(type_id)


static func _string_array_to_names(value: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if value is Array:
		for item in value as Array:
			out.append(StringName(String(item)))
	return out


static func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0


func _result(ok: bool, code: String, message: String, source: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source, "details": details}
