@tool
class_name SocialReactionRuleSet
extends Resource

const REACTION_IGNORE := &"ignore"
const REACTION_LOOK_TOWARD := &"look_toward"
const REACTION_INSPECT_POINT := &"inspect_point"
const REACTION_QUESTION_PLAYER := &"question_player"
const REACTION_REPORT_TO_AUTHORITY := &"report_to_authority"
const REACTION_BLOCK_ROUTE := &"block_route"
const REACTION_CHANGE_PATROL := &"change_patrol"
const REACTION_RAISE_LOCAL_SUSPICION := &"raise_local_suspicion"
const REACTION_TRIGGER_DIALOGUE_BARK := &"trigger_dialogue_bark"
const REACTION_REQUEST_ENCOUNTER_METER_DELTA := &"request_encounter_meter_delta"
const REACTION_APPLY_EFFECT_SET := &"apply_effect_set"

const SUPPORTED_REACTIONS: Array[StringName] = [
	REACTION_IGNORE,
	REACTION_LOOK_TOWARD,
	REACTION_INSPECT_POINT,
	REACTION_QUESTION_PLAYER,
	REACTION_REPORT_TO_AUTHORITY,
	REACTION_BLOCK_ROUTE,
	REACTION_CHANGE_PATROL,
	REACTION_RAISE_LOCAL_SUSPICION,
	REACTION_TRIGGER_DIALOGUE_BARK,
	REACTION_REQUEST_ENCOUNTER_METER_DELTA,
	REACTION_APPLY_EFFECT_SET,
]

@export var rule_id: StringName = &"reaction_rule"
@export var display_name: String = "Social Reaction Rule"
@export var accepted_signal_types: Array[StringName] = []
@export var required_facts: Array[Dictionary] = []
@export var blocked_by_facts: Array[Dictionary] = []
@export var reaction_id: StringName = REACTION_IGNORE
@export var reaction_tag: StringName = &""
@export var target_investigation_point_id: StringName = &""
@export var target_authority_id: StringName = &""
@export var max_chain_depth: int = 1
@export var cooldown_seconds: float = 2.0
@export var success_effects: EffectSet
@export var failure_effects: EffectSet
@export_multiline var debug_notes: String = ""


func matches_signal(signal_event: Resource, context: Dictionary = {}) -> Dictionary:
	if signal_event == null:
		return _result(false, "signal_missing", "Signal event is missing.", String(rule_id))
	var signal_type := String(signal_event.get("signal_type"))
	if not accepted_signal_types.is_empty() and not accepted_signal_types.has(StringName(signal_type)):
		return _result(false, "signal_type_not_accepted", "Signal type is not accepted by this rule.", String(rule_id), {"signal_type": signal_type, "accepted_signal_types": _names_to_strings(accepted_signal_types)})
	if not bool(signal_event.call("allows_reaction_tag", String(reaction_tag))):
		return _result(false, "reaction_tag_not_allowed", "Signal does not allow this reaction tag.", String(rule_id), {"reaction_tag": String(reaction_tag)})
	if int(context.get("chain_depth", 0)) > max_chain_depth:
		return _result(false, "rule_chain_depth_exceeded", "Rule chain depth exceeded.", String(rule_id), {"max_chain_depth": max_chain_depth})
	var required_result := _evaluate_required_facts(context)
	if not bool(required_result.get("ok", false)):
		return required_result
	var blocked_result := _evaluate_blocked_facts(context)
	if not bool(blocked_result.get("ok", false)):
		return blocked_result
	return _result(true, "reaction_rule_matched", "Reaction rule matched.", String(rule_id), get_reaction_payload(signal_event, context))


func get_reaction_payload(signal_event: Resource, context: Dictionary = {}) -> Dictionary:
	return {
		"rule_id": String(rule_id),
		"display_name": display_name,
		"signal_id": String(signal_event.get("signal_id")) if signal_event != null else "",
		"signal_type": String(signal_event.get("signal_type")) if signal_event != null else "",
		"reaction_id": String(reaction_id),
		"reaction_tag": String(reaction_tag),
		"target_investigation_point_id": String(target_investigation_point_id),
		"target_authority_id": String(target_authority_id),
		"max_chain_depth": max_chain_depth,
		"cooldown_seconds": cooldown_seconds,
		"debug_notes": debug_notes,
		"chain_depth": int(context.get("chain_depth", 0)),
	}


func apply_success(context: Dictionary = {}) -> Dictionary:
	if success_effects == null or success_effects.is_empty():
		return _result(true, "no_reaction_success_effects", "No reaction success effects assigned.", String(rule_id))
	return success_effects.apply_all(context)


func apply_failure(context: Dictionary = {}) -> Dictionary:
	if failure_effects == null or failure_effects.is_empty():
		return _result(true, "no_reaction_failure_effects", "No reaction failure effects assigned.", String(rule_id))
	return failure_effects.apply_all(context)


func is_supported_reaction() -> bool:
	return SUPPORTED_REACTIONS.has(reaction_id)


func get_debug_snapshot() -> Dictionary:
	return {
		"rule_id": String(rule_id),
		"display_name": display_name,
		"accepted_signal_types": _names_to_strings(accepted_signal_types),
		"reaction_id": String(reaction_id),
		"reaction_tag": String(reaction_tag),
		"target_investigation_point_id": String(target_investigation_point_id),
		"target_authority_id": String(target_authority_id),
		"max_chain_depth": max_chain_depth,
		"cooldown_seconds": cooldown_seconds,
		"supported_reaction": is_supported_reaction(),
		"debug_notes": debug_notes,
	}


func _evaluate_required_facts(context: Dictionary) -> Dictionary:
	for fact in required_facts:
		var result := _evaluate_fact_record(fact, context)
		if not bool(result.get("ok", false)):
			return _result(false, "required_fact_missing", "Required fact did not match.", String(rule_id), {"fact": fact, "fact_result": result})
	return _result(true, "required_facts_matched", "Required facts matched.", String(rule_id))


func _evaluate_blocked_facts(context: Dictionary) -> Dictionary:
	for fact in blocked_by_facts:
		var result := _evaluate_fact_record(fact, context)
		if bool(result.get("ok", false)):
			return _result(false, "blocked_by_fact", "Blocked fact matched.", String(rule_id), {"fact": fact, "fact_result": result})
	return _result(true, "blocked_facts_clear", "No blocked facts matched.", String(rule_id))


func _evaluate_fact_record(fact: Dictionary, context: Dictionary) -> Dictionary:
	var fact_type := StringName(String(fact.get("fact_type", "mission_flag")))
	var key := String(fact.get("key", ""))
	var expected: Variant = fact.get("expected", true)
	return MissionFactBridge.evaluate_fact(fact_type, key, expected, context)


func _names_to_strings(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
