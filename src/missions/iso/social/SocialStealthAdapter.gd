class_name SocialStealthAdapter
extends RefCounted

const FACT_COVER_STORY_ACTIVE := &"social_cover_story_active"
const FACT_CREDENTIAL_ACTIVE := &"social_credential_active"
const FACT_PROTOCOL_COMPLETE := &"social_protocol_complete"
const FACT_BELIEVABLE_TASK_COMPLETE := &"social_task_complete"
const FACT_PROFESSIONALISM_SCORE := &"professionalism_score"
const FACT_CLEANLINESS_SCORE := &"cleanliness_score"
const FACT_INSPECTION_PASSED := &"social_inspection_passed"
const FACT_INSPECTION_FAILED := &"social_inspection_failed"

static var _mission_state: Dictionary = {}


static func clear_all() -> void:
	_mission_state.clear()


static func reset_mission(mission_id: String) -> void:
	var mid := _mission_id(mission_id, {})
	if mid == "":
		return
	_mission_state[mid] = _default_state(mid)


static func set_cover_story(cover_story_id: String, data: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var id := cover_story_id.strip_edges()
	if id == "":
		return _result(false, "cover_story_id_missing", "Cover story id is missing.")
	var state := _state_for_context(context)
	var stories: Dictionary = state.get("cover_stories", {})
	var record := data.duplicate(true)
	record["cover_story_id"] = id
	record["active"] = true
	stories[id] = record
	state["cover_stories"] = stories
	state["active_cover_story_id"] = id
	return _result(true, "cover_story_set", "Cover story active: %s." % id, id, {"mission_id": state.get("mission_id", ""), "cover_story": record})


static func grant_credential(credential_id: String, data: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var id := credential_id.strip_edges()
	if id == "":
		return _result(false, "credential_id_missing", "Credential id is missing.")
	var state := _state_for_context(context)
	var credentials: Dictionary = state.get("credentials", {})
	var record := data.duplicate(true)
	record["credential_id"] = id
	record["active"] = true
	credentials[id] = record
	state["credentials"] = credentials
	return _result(true, "credential_granted", "Credential granted: %s." % id, id, {"mission_id": state.get("mission_id", ""), "credential": record})


static func complete_protocol(protocol_id: String, data: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var id := protocol_id.strip_edges()
	if id == "":
		return _result(false, "protocol_id_missing", "Protocol id is missing.")
	var state := _state_for_context(context)
	var protocols: Dictionary = state.get("protocols", {})
	var record := data.duplicate(true)
	record["protocol_id"] = id
	record["complete"] = true
	protocols[id] = record
	state["protocols"] = protocols
	return _result(true, "protocol_completed", "Protocol completed: %s." % id, id, {"mission_id": state.get("mission_id", ""), "protocol": record})


static func complete_task(task_id: String, data: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var id := task_id.strip_edges()
	if id == "":
		return _result(false, "task_id_missing", "Believable task id is missing.")
	var state := _state_for_context(context)
	var tasks: Dictionary = state.get("tasks", {})
	var record := data.duplicate(true)
	record["task_id"] = id
	record["complete"] = true
	tasks[id] = record
	state["tasks"] = tasks
	return _result(true, "believable_task_completed", "Believable task completed: %s." % id, id, {"mission_id": state.get("mission_id", ""), "task": record})


static func adjust_professionalism(delta: int, context: Dictionary = {}) -> Dictionary:
	var state := _state_for_context(context)
	var value := int(state.get("professionalism", 0)) + delta
	state["professionalism"] = value
	return _result(true, "professionalism_adjusted", "Professionalism adjusted by %d." % delta, "professionalism", {"value": value, "delta": delta})


static func set_professionalism(value: int, context: Dictionary = {}) -> Dictionary:
	var state := _state_for_context(context)
	state["professionalism"] = value
	return _result(true, "professionalism_set", "Professionalism set to %d." % value, "professionalism", {"value": value})


static func adjust_cleanliness(delta: int, context: Dictionary = {}) -> Dictionary:
	var state := _state_for_context(context)
	var value := int(state.get("cleanliness", 0)) + delta
	state["cleanliness"] = value
	return _result(true, "cleanliness_adjusted", "Cleanliness adjusted by %d." % delta, "cleanliness", {"value": value, "delta": delta})


static func set_cleanliness(value: int, context: Dictionary = {}) -> Dictionary:
	var state := _state_for_context(context)
	state["cleanliness"] = value
	return _result(true, "cleanliness_set", "Cleanliness set to %d." % value, "cleanliness", {"value": value})


static func record_inspection(inspection_id: String, passed: bool, inspection_result: Dictionary, context: Dictionary = {}) -> Dictionary:
	var id := inspection_id.strip_edges()
	if id == "":
		id = String(context.get("source_id", "inspection"))
	var state := _state_for_context(context)
	var bucket_key := "inspections_passed" if passed else "inspections_failed"
	var bucket: Dictionary = state.get(bucket_key, {})
	bucket[id] = inspection_result.duplicate(true)
	state[bucket_key] = bucket
	state["last_inspection_result"] = inspection_result.duplicate(true)
	return _result(true, "inspection_recorded", "Inspection recorded: %s." % id, id, {"passed": passed, "inspection_result": inspection_result})


static func get_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Variant:
	var state := _state_for_context(context)
	match fact_type:
		FACT_COVER_STORY_ACTIVE:
			if key.strip_edges() == "":
				return String(state.get("active_cover_story_id", ""))
			return (state.get("cover_stories", {}) as Dictionary).has(key)
		FACT_CREDENTIAL_ACTIVE:
			if key.strip_edges() == "":
				return not (state.get("credentials", {}) as Dictionary).is_empty()
			return (state.get("credentials", {}) as Dictionary).has(key)
		FACT_PROTOCOL_COMPLETE:
			return (state.get("protocols", {}) as Dictionary).has(key)
		FACT_BELIEVABLE_TASK_COMPLETE:
			return (state.get("tasks", {}) as Dictionary).has(key)
		FACT_PROFESSIONALISM_SCORE:
			return int(state.get("professionalism", 0))
		FACT_CLEANLINESS_SCORE:
			return int(state.get("cleanliness", 0))
		FACT_INSPECTION_PASSED:
			return (state.get("inspections_passed", {}) as Dictionary).has(key)
		FACT_INSPECTION_FAILED:
			return (state.get("inspections_failed", {}) as Dictionary).has(key)
	return null


static func get_summary(mission_id: String = "") -> Dictionary:
	var mid := _mission_id(mission_id, {})
	var state := _state(mid)
	return {
		"mission_id": mid,
		"active_cover_story_id": String(state.get("active_cover_story_id", "")),
		"cover_story_count": (state.get("cover_stories", {}) as Dictionary).size(),
		"credential_count": (state.get("credentials", {}) as Dictionary).size(),
		"protocol_count": (state.get("protocols", {}) as Dictionary).size(),
		"task_count": (state.get("tasks", {}) as Dictionary).size(),
		"professionalism": int(state.get("professionalism", 0)),
		"cleanliness": int(state.get("cleanliness", 0)),
		"inspections_passed": (state.get("inspections_passed", {}) as Dictionary).size(),
		"inspections_failed": (state.get("inspections_failed", {}) as Dictionary).size(),
		"last_inspection_result": (state.get("last_inspection_result", {}) as Dictionary).duplicate(true),
	}


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	var out := result.duplicate(true)
	var mission_id := String(out.get("mission_id", ""))
	var summary := get_summary(mission_id)
	out["social_stealth"] = summary
	out["social_stealth_state"] = _result_state(summary)
	return out


static func _result_state(summary: Dictionary) -> String:
	if int(summary.get("inspections_failed", 0)) > 0:
		return "questioned"
	if int(summary.get("inspections_passed", 0)) > 0:
		return "credible"
	if int(summary.get("task_count", 0)) > 0 or int(summary.get("protocol_count", 0)) > 0:
		return "believable"
	return "unproven"


static func _state_for_context(context: Dictionary) -> Dictionary:
	return _state(_mission_id(String(context.get("mission_id", "")), context))


static func _state(mission_id: String) -> Dictionary:
	var mid := _mission_id(mission_id, {})
	if mid == "":
		mid = "test_mission"
	if not _mission_state.has(mid):
		_mission_state[mid] = _default_state(mid)
	return _mission_state[mid]


static func _default_state(mission_id: String) -> Dictionary:
	return {
		"mission_id": mission_id,
		"active_cover_story_id": "",
		"cover_stories": {},
		"credentials": {},
		"protocols": {},
		"tasks": {},
		"professionalism": 0,
		"cleanliness": 0,
		"inspections_passed": {},
		"inspections_failed": {},
		"last_inspection_result": {},
	}


static func _mission_id(explicit: String, context: Dictionary) -> String:
	var mid := explicit.strip_edges()
	if mid != "":
		return mid
	var context_mid := String(context.get("mission_id", "")).strip_edges()
	if context_mid != "":
		return context_mid
	return MissionFactBridge.resolve_mission_id(context)


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
