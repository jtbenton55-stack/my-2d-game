class_name PaperTrailAdapter
extends RefCounted

const TraceEvent := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailTraceEvent.gd")

const FACT_TRACE_ACTIVE := &"paper_trace_active"
const FACT_TRACE_TYPE_COUNT := &"paper_trace_type_count"
const FACT_TRAIL_RESULT_STATE := &"paper_trail_result_state"
const FACT_TRAIL_SEVERITY_SCORE := &"paper_trail_severity_score"

static var _trace_events_by_mission: Dictionary = {}
## Replan Packet 4: traces harden after this many seconds and can no longer be
## wiped -- only redirected. 0 disables hardening.
static var default_hardening_seconds: float = 0.0


static func clear_all() -> void:
	_trace_events_by_mission.clear()
	default_hardening_seconds = 0.0


static func set_hardening_seconds(seconds: float) -> void:
	default_hardening_seconds = maxf(0.0, seconds)


static func is_trace_hardened(event: Dictionary) -> bool:
	if default_hardening_seconds <= 0.0:
		return false
	if String(event.get("status", TraceEvent.STATUS_ACTIVE)) == TraceEvent.STATUS_CLEANED:
		return false
	var created_at := float(event.get("created_at", 0))
	if created_at <= 0.0:
		return false
	return Time.get_unix_time_from_system() - created_at >= default_hardening_seconds


static func reset_mission(mission_id: String) -> void:
	var mid := mission_id.strip_edges()
	if mid == "":
		return
	_trace_events_by_mission[mid] = {}


static func record_trace(
	trace_id: String,
	source_id: String,
	trace_type: String,
	severity: int,
	can_cleanup: bool,
	cleanup_requirement: String,
	context: Dictionary = {},
	payload: Dictionary = {}
) -> Dictionary:
	var mid := _resolve_mission_id(context)
	if mid == "":
		return _result(false, "mission_id_missing", "Cannot record paper trace without a mission id.", trace_id)
	var tid := trace_id.strip_edges()
	if tid == "":
		tid = "%s_%s" % [source_id.strip_edges(), trace_type.strip_edges()]
	if tid.strip_edges() == "_":
		return _result(false, "trace_id_missing", "Paper trace is missing trace_id/source/type.", trace_id)
	var source := source_id.strip_edges()
	if source == "":
		source = String(context.get("source_id", tid))
	var event := TraceEvent.make_event(tid, mid, source, trace_type, severity, can_cleanup, cleanup_requirement, payload)
	if context.has("source_path"):
		event["source_path"] = String(context.get("source_path", ""))
	if context.has("position"):
		event["position"] = context.get("position")
	_events_for_mission(mid)[tid] = event
	_record_performance(mid, "paper_traces_recorded", 1)
	return _result(true, "paper_trace_recorded", "Paper trace recorded: %s." % tid, tid, {"mission_id": mid, "event": event.duplicate(true)})


static func cleanup_traces(criteria: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var mid := _resolve_mission_id(context)
	if mid == "":
		return _result(false, "mission_id_missing", "Cannot clean paper traces without a mission id.")
	var matches := _matching_trace_ids(mid, criteria, true)
	if matches.is_empty():
		return _result(false, "paper_trace_not_found", "No cleanup-eligible paper traces matched.", String(criteria.get("trace_id", "")), {"mission_id": mid, "criteria": criteria.duplicate(true)})
	var mode := String(criteria.get("cleanup_mode", "clean")).strip_edges()
	if mode == "":
		mode = "clean"
	var strength := maxi(1, int(criteria.get("cleanup_strength", 5)))
	var cleaned: Array[String] = []
	var weakened: Array[String] = []
	var hardened: Array[String] = []
	var events := _events_for_mission(mid)
	for trace_id in matches:
		var event: Dictionary = (events.get(trace_id, {}) as Dictionary).duplicate(true)
		if is_trace_hardened(event):
			hardened.append(String(trace_id))
			continue
		if mode == "weaken":
			event["severity"] = maxi(0, int(event.get("severity", 0)) - strength)
			if int(event.get("severity", 0)) <= 0:
				event["status"] = TraceEvent.STATUS_CLEANED
				event["cleaned_at"] = Time.get_unix_time_from_system()
				cleaned.append(String(trace_id))
			else:
				weakened.append(String(trace_id))
		else:
			event["severity"] = 0
			event["status"] = TraceEvent.STATUS_CLEANED
			event["cleaned_at"] = Time.get_unix_time_from_system()
			cleaned.append(String(trace_id))
		events[trace_id] = event
	_record_performance(mid, "paper_traces_cleaned", cleaned.size())
	if cleaned.is_empty() and weakened.is_empty() and not hardened.is_empty():
		return _result(false, "paper_trace_hardened", "Those traces have set in. Only misdirection works now.", String(criteria.get("trace_id", "")), {"mission_id": mid, "hardened": hardened})
	return _result(true, "paper_trace_cleanup_applied", "Paper trace cleanup applied.", String(criteria.get("trace_id", "")), {"mission_id": mid, "cleaned": cleaned, "weakened": weakened, "hardened": hardened})


static func redirect_traces(criteria: Dictionary = {}, explanation_id: String = "", context: Dictionary = {}) -> Dictionary:
	var mid := _resolve_mission_id(context)
	if mid == "":
		return _result(false, "mission_id_missing", "Cannot redirect paper traces without a mission id.")
	var matches := _matching_trace_ids(mid, criteria, false)
	if matches.is_empty():
		return _result(false, "paper_trace_not_found", "No paper traces matched for redirection.", String(criteria.get("trace_id", "")), {"mission_id": mid, "criteria": criteria.duplicate(true)})
	var explanation := explanation_id.strip_edges()
	if explanation == "":
		explanation = String(criteria.get("explanation_id", "plausible_misdirection"))
	var reduction := maxi(0, int(criteria.get("severity_reduction", 1)))
	var redirected: Array[String] = []
	var events := _events_for_mission(mid)
	for trace_id in matches:
		var event: Dictionary = (events.get(trace_id, {}) as Dictionary).duplicate(true)
		if String(event.get("status", TraceEvent.STATUS_ACTIVE)) == TraceEvent.STATUS_CLEANED:
			continue
		event["status"] = TraceEvent.STATUS_REDIRECTED
		event["redirected_to"] = explanation
		event["severity"] = maxi(0, int(event.get("severity", 0)) - reduction)
		event["redirected_at"] = Time.get_unix_time_from_system()
		events[trace_id] = event
		redirected.append(String(trace_id))
	_record_performance(mid, "paper_traces_redirected", redirected.size())
	return _result(true, "paper_trace_redirected", "Paper trace redirected to %s." % explanation, explanation, {"mission_id": mid, "redirected": redirected})


static func get_trace_events(mission_id: String) -> Array[Dictionary]:
	var mid := mission_id.strip_edges()
	if mid == "":
		return []
	var events := _events_for_mission(mid)
	var out: Array[Dictionary] = []
	for trace_id in events.keys():
		out.append((events[trace_id] as Dictionary).duplicate(true))
	return out


static func has_active_trace(mission_id: String, trace_id: String) -> bool:
	var event: Variant = _events_for_mission(mission_id).get(trace_id, {})
	return event is Dictionary and String((event as Dictionary).get("status", TraceEvent.STATUS_ACTIVE)) != TraceEvent.STATUS_CLEANED and int((event as Dictionary).get("severity", 0)) > 0


static func count_active_traces_by_type(mission_id: String, trace_type: String) -> int:
	var count := 0
	for event in get_trace_events(mission_id):
		if String(event.get("trace_type", "")) == trace_type and String(event.get("status", TraceEvent.STATUS_ACTIVE)) != TraceEvent.STATUS_CLEANED and int(event.get("severity", 0)) > 0:
			count += 1
	return count


static func get_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Variant:
	var mid := _resolve_mission_id(context)
	match fact_type:
		FACT_TRACE_ACTIVE:
			return has_active_trace(mid, key)
		FACT_TRACE_TYPE_COUNT:
			return count_active_traces_by_type(mid, key)
		FACT_TRAIL_RESULT_STATE:
			return String(get_summary(mid).get("result_state", "clean"))
		FACT_TRAIL_SEVERITY_SCORE:
			return int(get_summary(mid).get("severity_score", 0))
		_:
			return null


static func get_summary(mission_id: String) -> Dictionary:
	var mid := mission_id.strip_edges()
	var total := 0
	var active := 0
	var cleaned := 0
	var redirected := 0
	var seen := 0
	var suspicious := 0
	var severity_score := 0
	var max_severity := 0
	for event in get_trace_events(mid):
		total += 1
		var status := String(event.get("status", TraceEvent.STATUS_ACTIVE))
		var severity := int(event.get("severity", 0))
		if status == TraceEvent.STATUS_CLEANED or severity <= 0:
			cleaned += 1
		else:
			active += 1
			severity_score += severity
			max_severity = maxi(max_severity, severity)
			var ttype := String(event.get("trace_type", ""))
			if ttype in ["camera_seen", "witness"]:
				seen += 1
			if severity >= 2 or ttype in ["door_memory", "audit_log", "evidence_touch"]:
				suspicious += 1
		if status == TraceEvent.STATUS_REDIRECTED:
			redirected += 1
	var result_state := _result_state(active, redirected, seen, severity_score, max_severity)
	return {
		"mission_id": mid,
		"total_events": total,
		"active_events": active,
		"cleaned_events": cleaned,
		"redirected_events": redirected,
		"seen_events": seen,
		"suspicious_events": suspicious,
		"explainable_events": redirected,
		"deniable_events": cleaned + redirected,
		"severity_score": severity_score,
		"max_severity": max_severity,
		"result_state": result_state,
		"result_line": _result_line(result_state, active, cleaned, redirected, severity_score),
	}


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	var annotated := result.duplicate(true)
	var mid := String(annotated.get("mission_id", ""))
	if mid == "":
		return annotated
	var summary := get_summary(mid)
	annotated["paper_trail"] = summary
	annotated["paper_trail_state"] = String(summary.get("result_state", "clean"))
	return annotated


static func _matching_trace_ids(mission_id: String, criteria: Dictionary, cleanup_only: bool) -> Array[String]:
	var target_trace_id := String(criteria.get("trace_id", "")).strip_edges()
	var target_trace_type := String(criteria.get("trace_type", "")).strip_edges()
	var target_source_id := String(criteria.get("source_id", "")).strip_edges()
	var required_cleanup := String(criteria.get("cleanup_requirement", "")).strip_edges()
	var out: Array[String] = []
	var events := _events_for_mission(mission_id)
	for trace_id in events.keys():
		var event: Dictionary = events.get(trace_id, {})
		if target_trace_id != "" and String(event.get("trace_id", "")) != target_trace_id:
			continue
		if target_trace_type != "" and String(event.get("trace_type", "")) != target_trace_type:
			continue
		if target_source_id != "" and String(event.get("source_id", "")) != target_source_id:
			continue
		if cleanup_only and not bool(event.get("can_cleanup", true)):
			continue
		if cleanup_only and required_cleanup != "" and String(event.get("cleanup_requirement", "")) != required_cleanup:
			continue
		if String(event.get("status", TraceEvent.STATUS_ACTIVE)) == TraceEvent.STATUS_CLEANED:
			continue
		out.append(String(trace_id))
	return out


static func _events_for_mission(mission_id: String) -> Dictionary:
	var mid := mission_id.strip_edges()
	if mid == "":
		return {}
	if not _trace_events_by_mission.has(mid):
		_trace_events_by_mission[mid] = {}
	return _trace_events_by_mission[mid]


static func _resolve_mission_id(context: Dictionary = {}) -> String:
	var mid := String(context.get("mission_id", "")).strip_edges()
	if mid != "":
		return mid
	var game_state := _autoload("GameState")
	if game_state != null:
		mid = String(game_state.get("current_mission_id")).strip_edges()
		if mid != "":
			return mid
		mid = String(game_state.get("pending_mission_id")).strip_edges()
	return mid


static func _record_performance(mission_id: String, key: String, delta: int) -> void:
	var game_state := _autoload("GameState")
	if game_state != null and game_state.has_method("record_mission_performance_event"):
		game_state.call("record_mission_performance_event", mission_id, key, delta)


static func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(name)


static func _result_state(active: int, redirected: int, seen: int, severity_score: int, max_severity: int) -> String:
	if active <= 0:
		return "clean"
	if seen > 0 or max_severity >= 4:
		return "seen"
	if redirected >= active and severity_score <= active * 2:
		return "explainable"
	if redirected > 0:
		return "deniable"
	return "suspicious"


static func _result_line(result_state: String, active: int, cleaned: int, redirected: int, severity_score: int) -> String:
	match result_state:
		"clean":
			return "Clean paper trail: %d trace(s) cleaned." % cleaned
		"explainable":
			return "Explainable paper trail: %d trace(s) redirected." % redirected
		"deniable":
			return "Deniable paper trail: %d active trace(s), %d redirected." % [active, redirected]
		"seen":
			return "Seen paper trail: trace severity %d needs explanation." % severity_score
		_:
			return "Suspicious paper trail: %d active trace(s), severity %d." % [active, severity_score]


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
