@tool
class_name EncounterController
extends Node

signal phase_changed(encounter_id: String, phase_id: String, previous_phase_id: String)
signal meter_changed(encounter_id: String, meter_id: String, value: int, delta: int)
signal event_recorded(encounter_id: String, event_id: String, details: Dictionary)
signal encounter_won(encounter_id: String, result_tag: String)
signal encounter_failed(encounter_id: String, reason: String)

const PhaseDataScript := preload("res://src/missions/iso/encounters/EncounterPhaseData.gd")
const MeterDataScript := preload("res://src/missions/iso/encounters/ChallengeMeterData.gd")

@export var encounter_id: StringName = &"encounter"
@export var display_name: String = "Encounter"
@export var mission_id_override: String = ""
@export var initial_phase_id: StringName = &""
@export var start_on_ready: bool = true
@export var phases: Array[Resource] = []
@export var meters: Array[Resource] = []

var current_phase_id: String = ""
var active: bool = false
var resolved: bool = false
var success: bool = false
var result_tags: Dictionary = {}
var meter_values: Dictionary = {}
var event_log: Array[Dictionary] = []
var last_phase_result: Dictionary = {}


func _ready() -> void:
	add_to_group("mission_encounter_controller")
	if Engine.is_editor_hint():
		return
	reset_encounter()
	if start_on_ready:
		start_encounter()


func reset_encounter() -> void:
	active = false
	resolved = false
	success = false
	result_tags.clear()
	event_log.clear()
	last_phase_result = {}
	meter_values.clear()
	for meter in meters:
		if meter == null:
			continue
		meter_values[_id_text(meter.get("meter_id"))] = int(meter.call("get_initial_value"))
	current_phase_id = _resolve_initial_phase_id()


func start_encounter() -> Dictionary:
	if resolved:
		return _result(false, "encounter_resolved", "Encounter is already resolved.", String(encounter_id))
	active = true
	if current_phase_id.strip_edges() == "":
		current_phase_id = _resolve_initial_phase_id()
	var phase: Resource = get_current_phase_data()
	var effect_result: Dictionary = phase.call("apply_enter_effects", _context()) if phase != null else _result(true, "phase_missing", "No phase to enter.")
	return _result(true, "encounter_started", "Encounter started.", String(encounter_id), {"phase_id": current_phase_id, "effect_result": effect_result})


func set_phase(phase_id: String, reason: String = "set_phase") -> Dictionary:
	var target := _id_text(phase_id)
	if target == "":
		return _result(false, "phase_id_missing", "Encounter phase id is missing.", String(encounter_id))
	if get_phase_data(target) == null:
		return _result(false, "phase_missing", "Encounter phase does not exist: %s." % target, String(encounter_id))
	var previous := current_phase_id
	current_phase_id = target
	active = true
	var current_phase: Resource = get_current_phase_data()
	var enter_result: Dictionary = current_phase.call("apply_enter_effects", _context())
	phase_changed.emit(String(encounter_id), current_phase_id, previous)
	return _result(true, "phase_set", "Encounter phase set to %s." % target, String(encounter_id), {"phase_id": target, "previous_phase_id": previous, "reason": reason, "effect_result": enter_result})


func evaluate_current_phase() -> Dictionary:
	var phase: Resource = get_current_phase_data()
	if phase == null:
		return _result(false, "phase_missing", "No current encounter phase.", String(encounter_id), {"phase_id": current_phase_id})
	last_phase_result = phase.call("evaluate", _context())
	return last_phase_result


func complete_current_phase(route_tag: String = "", details: Dictionary = {}) -> Dictionary:
	var phase: Resource = get_current_phase_data()
	if phase == null:
		return _result(false, "phase_missing", "No current encounter phase.", String(encounter_id), {"phase_id": current_phase_id})
	var context := _context(details)
	var requirement_result: Dictionary = phase.call("evaluate", context)
	if not bool(requirement_result.get("ok", false)):
		var failure_effect: Dictionary = phase.call("apply_failure_effects", context)
		if bool(phase.get("fail_on_failure")):
			fail_encounter(String(requirement_result.get("message", "Phase requirements failed.")))
		last_phase_result = _result(false, "phase_requirements_failed", String(requirement_result.get("message", "Phase requirements failed.")), String(phase.get("phase_id")), {"requirement_result": requirement_result, "effect_result": failure_effect})
		return last_phase_result
	var effect_result: Dictionary = phase.call("apply_success_effects", context)
	var resolved_route := route_tag.strip_edges()
	if resolved_route == "":
		resolved_route = _id_text(phase.get("route_tag_on_success"))
	if resolved_route != "":
		set_result_tag(resolved_route, true)
	var phase_tag := _id_text(phase.get("result_tag_on_success"))
	if phase_tag != "":
		set_result_tag(phase_tag, true)
	last_phase_result = _result(true, "phase_completed", "Encounter phase completed: %s." % _id_text(phase.get("phase_id")), _id_text(phase.get("phase_id")), {"requirement_result": requirement_result, "effect_result": effect_result, "route_tag": resolved_route})
	if bool(phase.get("win_on_success")):
		win_encounter(phase_tag if phase_tag != "" else resolved_route)
	elif _id_text(phase.get("next_phase_id")) != "":
		set_phase(_id_text(phase.get("next_phase_id")), "phase_completed")
	return last_phase_result


func record_event(event_id: String, details: Dictionary = {}) -> Dictionary:
	var id := event_id.strip_edges()
	if id == "":
		id = "encounter_event"
	var record := details.duplicate(true)
	record["event_id"] = id
	record["encounter_id"] = String(encounter_id)
	record["phase_id"] = current_phase_id
	event_log.append(record)
	event_recorded.emit(String(encounter_id), id, record)
	return _result(true, "encounter_event_recorded", "Encounter event recorded: %s." % id, id, {"event": record})


func adjust_meter(meter_id: String, delta: int, details: Dictionary = {}) -> Dictionary:
	var id := _id_text(meter_id)
	if id == "":
		return _result(false, "meter_id_missing", "Challenge meter id is missing.", String(encounter_id))
	var data: Resource = get_meter_data(id)
	var old_value := int(meter_values.get(id, int(data.call("get_initial_value")) if data != null else 0))
	var new_value := old_value + delta
	if data != null:
		new_value = int(data.call("clamp_value", new_value))
	meter_values[id] = new_value
	meter_changed.emit(String(encounter_id), id, new_value, delta)
	return _result(true, "encounter_meter_adjusted", "Meter %s adjusted by %d." % [id, delta], id, {"old_value": old_value, "value": new_value, "delta": delta, "details": details})


func set_meter_value(meter_id: String, value: int, details: Dictionary = {}) -> Dictionary:
	var id := _id_text(meter_id)
	var current := int(meter_values.get(id, 0))
	return adjust_meter(id, value - current, details)


func set_result_tag(tag: String, value: bool = true) -> Dictionary:
	var id := _id_text(tag)
	if id == "":
		return _result(false, "result_tag_missing", "Encounter result tag is missing.", String(encounter_id))
	result_tags[id] = value
	return _result(true, "encounter_result_tag_set", "Encounter result tag %s set to %s." % [id, str(value)], id, {"value": value})


func win_encounter(result_tag: String = "") -> Dictionary:
	active = false
	resolved = true
	success = true
	if result_tag.strip_edges() != "":
		set_result_tag(result_tag, true)
	encounter_won.emit(String(encounter_id), result_tag)
	return _result(true, "encounter_won", "Encounter won.", String(encounter_id), {"result_tag": result_tag})


func fail_encounter(reason: String = "Encounter failed.") -> Dictionary:
	active = false
	resolved = true
	success = false
	set_result_tag("failed", true)
	encounter_failed.emit(String(encounter_id), reason)
	return _result(false, "encounter_failed", reason, String(encounter_id))


func get_fact_value(fact_type: StringName, key: String, _context: Dictionary = {}) -> Variant:
	match fact_type:
		&"encounter_phase":
			var normalized_key := _id_text(key)
			return current_phase_id if normalized_key == "" or normalized_key == _id_text(encounter_id) else current_phase_id == normalized_key
		&"encounter_meter":
			return int(meter_values.get(key, 0))
		&"encounter_result_tag":
			return bool(result_tags.get(key, false))
	return null


func get_current_phase_data() -> Resource:
	return get_phase_data(current_phase_id)


func get_phase_data(phase_id: String) -> Resource:
	var target := _id_text(phase_id)
	for phase in phases:
		if phase != null and _id_text(phase.get("phase_id")) == target:
			return phase
	return null


func get_meter_data(meter_id: String) -> Resource:
	var target := _id_text(meter_id)
	for meter in meters:
		if meter != null and _id_text(meter.get("meter_id")) == target:
			return meter
	return null


func get_summary() -> Dictionary:
	var meter_summaries: Dictionary = {}
	for meter_id in meter_values.keys():
		var id := String(meter_id)
		var data: Resource = get_meter_data(id)
		meter_summaries[id] = data.call("to_summary", int(meter_values[id])) if data != null else {"meter_id": id, "value": int(meter_values[id])}
	return {
		"encounter_id": String(encounter_id),
		"display_name": display_name,
		"mission_id": _resolved_mission_id(),
		"active": active,
		"resolved": resolved,
		"success": success,
		"current_phase_id": current_phase_id,
		"meters": meter_summaries,
		"result_tags": result_tags.duplicate(true),
		"event_count": event_log.size(),
		"last_phase_result": last_phase_result.duplicate(true),
	}


func _resolve_initial_phase_id() -> String:
	var explicit := _id_text(initial_phase_id)
	if explicit != "":
		return explicit
	for phase in phases:
		if phase != null:
			return _id_text(phase.get("phase_id"))
	return ""


func _context(extra: Dictionary = {}) -> Dictionary:
	var context := extra.duplicate(true)
	context["mission_id"] = _resolved_mission_id()
	context["source_id"] = String(encounter_id)
	context["encounter_id"] = String(encounter_id)
	context["encounter_controller"] = self
	context["encounter"] = get_summary()
	return context


func _resolved_mission_id() -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id({})


func _id_text(value: Variant) -> String:
	var text := String(value).strip_edges()
	if text.begins_with("&\"") and text.ends_with("\""):
		return text.substr(2, text.length() - 3)
	if text.begins_with("\"") and text.ends_with("\""):
		return text.substr(1, text.length() - 2)
	return text


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
