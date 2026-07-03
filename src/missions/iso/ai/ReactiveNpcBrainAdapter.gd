class_name ReactiveNpcBrainAdapter
extends RefCounted

const SignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const FallbackDriverScript := preload("res://src/missions/iso/ai/ReactiveNpcFallbackDriver.gd")
const AttentionBudgetScript := preload("res://src/missions/iso/ai/NpcAttentionBudget.gd")

const FACT_SIGNAL_RECORDED := &"reactive_signal_recorded"
const FACT_SIGNAL_TYPE_COUNT := &"reactive_signal_type_count"
const FACT_REACTION_RECORDED := &"reactive_reaction_recorded"
const FACT_AUTHORITY_REPORTED := &"reactive_authority_reported"
const FACT_RESULT_TAG := &"reactive_result_tag"

static var _mission_state: Dictionary = {}


static func clear_all() -> void:
	_mission_state.clear()


static func reset_mission(mission_id: String) -> void:
	var mid := _mission_id(mission_id, {})
	if mid == "":
		return
	_mission_state[mid] = _default_state(mid)


static func record_signal(signal_event: Resource, context: Dictionary = {}) -> Dictionary:
	var event := _coerce_signal(signal_event, context)
	if event == null:
		return _result(false, "signal_missing", "Reactive NPC signal is missing.")
	event.call("ensure_created_time", float(context.get("now", -1.0)))
	var validation: Dictionary = event.call("validate")
	if not bool(validation.get("ok", false)):
		return validation
	var state := _state_for_context(context, String(event.get("mission_id")))
	var signals: Dictionary = state.get("signals", {})
	var record: Dictionary = event.call("to_record")
	if String(record.get("mission_id", "")).strip_edges() == "":
		record["mission_id"] = String(state.get("mission_id", ""))
	signals[String(event.get("signal_id"))] = record
	state["signals"] = signals
	state["last_signal"] = record.duplicate(true)
	var counts: Dictionary = state.get("signal_type_counts", {})
	var signal_type := String(event.get("signal_type"))
	counts[signal_type] = int(counts.get(signal_type, 0)) + 1
	state["signal_type_counts"] = counts
	return _result(true, "reactive_signal_recorded", "Reactive NPC signal recorded: %s." % String(event.get("signal_id")), String(event.get("signal_id")), {"signal": record})


static func evaluate_signal(signal_event: Resource, rule_sets: Array = [], attention_budget: Resource = null, context: Dictionary = {}) -> Dictionary:
	var event := _coerce_signal(signal_event, context)
	if event == null:
		return _result(false, "signal_missing", "Reactive NPC signal is missing.")
	var record_result := record_signal(event, context)
	if not bool(record_result.get("ok", false)):
		return record_result
	if bool(event.call("is_expired", float(context.get("now", -1.0)))):
		return _result(true, "reactive_signal_expired", "Reactive NPC signal expired and was ignored safely.", String(event.get("signal_id")))
	var rules := _rules_from_inputs(rule_sets, context)
	if rules.is_empty():
		return _record_reaction(event, "ignore", {}, _result(true, "no_reaction_rules", "No reaction rules assigned; signal ignored safely."), context)
	var budget := attention_budget
	if budget == null and context.get("attention_budget", null) is Resource:
		budget = context.get("attention_budget") as Resource
	if budget == null:
		budget = AttentionBudgetScript.new()
	var reaction_results: Array[Dictionary] = []
	for rule in rules:
		if rule == null or not rule.has_method("matches_signal"):
			continue
		var match_result: Dictionary = rule.call("matches_signal", event, context)
		if not bool(match_result.get("ok", false)):
			continue
		var payload: Dictionary = rule.call("get_reaction_payload", event, context)
		var reaction_id := String(payload.get("reaction_id", "ignore"))
		var budget_context := context.duplicate(true)
		budget_context["npc_id"] = String(context.get("npc_id", event.get("witness_group")))
		budget_context["chain_depth"] = int(payload.get("chain_depth", context.get("chain_depth", 0)))
		var budget_result: Dictionary = budget.call("approve_reaction", event, reaction_id, budget_context)
		if not bool(budget_result.get("ok", false)):
			reaction_results.append(_record_reaction(event, reaction_id, payload, budget_result, context))
			continue
		var execution_context := context.duplicate(true)
		execution_context["attention_budget"] = budget
		var execution_result := _execute_reaction(reaction_id, event, payload, execution_context)
		if bool(execution_result.get("ok", false)):
			rule.call("apply_success", execution_context)
		else:
			rule.call("apply_failure", execution_context)
		reaction_results.append(_record_reaction(event, reaction_id, payload, execution_result, execution_context))
		break
	if reaction_results.is_empty():
		return _record_reaction(event, "ignore", {}, _result(true, "no_matching_reaction_rule", "No matching reaction rule; signal ignored safely."), context)
	var final_result: Dictionary = reaction_results.back()
	final_result["details"]["reaction_results"] = reaction_results
	return final_result


static func set_result_tag(tag: String, value: bool = true, context: Dictionary = {}) -> Dictionary:
	var clean_tag := tag.strip_edges()
	if clean_tag == "":
		return _result(false, "reactive_result_tag_missing", "Reactive NPC result tag is missing.")
	var state := _state_for_context(context)
	var tags: Dictionary = state.get("result_tags", {})
	tags[clean_tag] = value
	state["result_tags"] = tags
	return _result(true, "reactive_result_tag_set", "Reactive NPC result tag set: %s." % clean_tag, clean_tag, {"value": value})


static func get_fact_value(fact_type: StringName, key: String, context: Dictionary = {}) -> Variant:
	var state := _state_for_context(context)
	match fact_type:
		FACT_SIGNAL_RECORDED:
			return (state.get("signals", {}) as Dictionary).has(key)
		FACT_SIGNAL_TYPE_COUNT:
			return int((state.get("signal_type_counts", {}) as Dictionary).get(key, 0))
		FACT_REACTION_RECORDED:
			if key.strip_edges() == "":
				return int(state.get("reaction_count", 0))
			return int((state.get("reaction_counts", {}) as Dictionary).get(key, 0)) > 0
		FACT_AUTHORITY_REPORTED:
			return int(state.get("authority_reports", 0)) if key.strip_edges() == "" else bool((state.get("authority_report_targets", {}) as Dictionary).get(key, false))
		FACT_RESULT_TAG:
			return bool((state.get("result_tags", {}) as Dictionary).get(key, false))
	return null


static func get_summary(mission_id: String = "") -> Dictionary:
	var mid := _mission_id(mission_id, {})
	var state := _state(mid)
	return {
		"mission_id": String(state.get("mission_id", mid)),
		"signal_count": (state.get("signals", {}) as Dictionary).size(),
		"signal_type_counts": (state.get("signal_type_counts", {}) as Dictionary).duplicate(true),
		"reaction_count": int(state.get("reaction_count", 0)),
		"reaction_counts": (state.get("reaction_counts", {}) as Dictionary).duplicate(true),
		"authority_reports": int(state.get("authority_reports", 0)),
		"result_tags": (state.get("result_tags", {}) as Dictionary).duplicate(true),
		"last_signal": (state.get("last_signal", {}) as Dictionary).duplicate(true),
		"last_reaction": (state.get("last_reaction", {}) as Dictionary).duplicate(true),
		"limbo_adapter_used": bool(state.get("limbo_adapter_used", false)),
		"limbo_adapter_available": bool(state.get("limbo_adapter_available", false)),
	}


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	var out := result.duplicate(true)
	var summary := get_summary(String(out.get("mission_id", "")))
	out["reactive_npc"] = summary
	out["reactive_npc_state"] = _result_state(summary)
	return out


static func _execute_reaction(reaction_id: String, signal_event: Resource, payload: Dictionary, context: Dictionary) -> Dictionary:
	var limbo_adapter: Variant = context.get("limbo_reactive_npc_adapter", null)
	var state := _state_for_context(context, String(signal_event.get("mission_id")))
	state["limbo_adapter_available"] = limbo_adapter != null
	if limbo_adapter != null and limbo_adapter.has_method("execute_reaction"):
		state["limbo_adapter_used"] = true
		var result: Dictionary = limbo_adapter.call("execute_reaction", reaction_id, signal_event, payload, context)
		result["details"]["limbo_adapter_used"] = true
		return result
	return FallbackDriverScript.execute_reaction(reaction_id, signal_event, payload, context)


static func _record_reaction(signal_event: Resource, reaction_id: String, payload: Dictionary, reaction_result: Dictionary, context: Dictionary) -> Dictionary:
	var state := _state_for_context(context, String(signal_event.get("mission_id")))
	var record := payload.duplicate(true)
	record["signal_id"] = String(signal_event.get("signal_id"))
	record["signal_type"] = String(signal_event.get("signal_type"))
	record["reaction_id"] = reaction_id
	record["result_code"] = String(reaction_result.get("code", ""))
	record["ok"] = bool(reaction_result.get("ok", false))
	record["limbo_adapter_used"] = bool((reaction_result.get("details", {}) as Dictionary).get("limbo_adapter_used", false))
	var reactions: Array = state.get("reactions", [])
	reactions.append(record)
	state["reactions"] = reactions
	state["last_reaction"] = record.duplicate(true)
	state["reaction_count"] = int(state.get("reaction_count", 0)) + 1
	var counts: Dictionary = state.get("reaction_counts", {})
	counts[reaction_id] = int(counts.get(reaction_id, 0)) + 1
	state["reaction_counts"] = counts
	if reaction_id == "report_to_authority" and bool(reaction_result.get("ok", false)):
		state["authority_reports"] = int(state.get("authority_reports", 0)) + 1
		var targets: Dictionary = state.get("authority_report_targets", {})
		var target := String(payload.get("target_authority_id", "authority"))
		targets[target] = true
		state["authority_report_targets"] = targets
	return _result(bool(reaction_result.get("ok", false)), String(reaction_result.get("code", "reactive_reaction_recorded")), String(reaction_result.get("message", "Reactive NPC reaction recorded.")), reaction_id, {"reaction": record, "reaction_result": reaction_result})


static func _coerce_signal(signal_event: Resource, context: Dictionary) -> Resource:
	if signal_event != null:
		if String(signal_event.get("mission_id")).strip_edges() == "":
			signal_event.set("mission_id", _mission_id("", context))
		return signal_event
	var data: Variant = context.get("signal", context.get("payload", {}))
	if data is Dictionary:
		var event: Resource = SignalEventScript.from_dictionary(data as Dictionary)
		if String(event.get("mission_id")).strip_edges() == "":
			event.set("mission_id", _mission_id("", context))
		return event
	return null


static func _rules_from_inputs(rule_sets: Array, context: Dictionary) -> Array:
	var out: Array = []
	for rule in rule_sets:
		if rule != null:
			out.append(rule)
	var context_rules: Variant = context.get("reaction_rule_sets", [])
	if context_rules is Array:
		for rule in context_rules as Array:
			if rule != null:
				out.append(rule)
	return out


static func _state_for_context(context: Dictionary, explicit: String = "") -> Dictionary:
	return _state(_mission_id(explicit, context))


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
		"signals": {},
		"signal_type_counts": {},
		"reactions": [],
		"reaction_count": 0,
		"reaction_counts": {},
		"authority_reports": 0,
		"authority_report_targets": {},
		"result_tags": {},
		"last_signal": {},
		"last_reaction": {},
		"limbo_adapter_used": false,
		"limbo_adapter_available": false,
	}


static func _mission_id(explicit: String, context: Dictionary) -> String:
	var mid := explicit.strip_edges()
	if mid != "":
		return mid
	mid = String(context.get("mission_id", "")).strip_edges()
	if mid != "":
		return mid
	return MissionFactBridge.resolve_mission_id(context)


static func _result_state(summary: Dictionary) -> String:
	if int(summary.get("authority_reports", 0)) > 0:
		return "reported"
	if int(summary.get("reaction_count", 0)) > 0:
		return "noticed"
	if int(summary.get("signal_count", 0)) > 0:
		return "signaled"
	return "quiet"


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
