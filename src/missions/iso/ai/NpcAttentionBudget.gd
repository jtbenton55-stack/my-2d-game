@tool
class_name NpcAttentionBudget
extends Resource

@export var budget_id: StringName = &"npc_attention_budget"
@export var max_reactions_per_signal: int = 1
@export var max_reactions_per_zone: int = 3
@export var max_reactions_per_npc: int = 3
@export var max_chain_depth: int = 1
@export var cooldown_seconds: float = 2.0
@export var max_active_investigations: int = 1
@export var max_authority_reports: int = 1
@export var ignore_lower_severity_while_busy: bool = true
@export var debug_enabled: bool = true

var signal_reaction_counts: Dictionary = {}
var zone_reaction_counts: Dictionary = {}
var npc_reaction_counts: Dictionary = {}
var recent_reaction_times: Dictionary = {}
var active_investigations: int = 0
var authority_reports: int = 0
var busy_severity: int = 0
var last_decision: Dictionary = {}


func reset() -> void:
	signal_reaction_counts.clear()
	zone_reaction_counts.clear()
	npc_reaction_counts.clear()
	recent_reaction_times.clear()
	active_investigations = 0
	authority_reports = 0
	busy_severity = 0
	last_decision = {}


func approve_reaction(signal_event: Resource, reaction_id: String, context: Dictionary = {}) -> Dictionary:
	var now := float(context.get("now", Time.get_ticks_msec() / 1000.0))
	var signal_id := _signal_text(signal_event, "signal_id", String(context.get("signal_id", "signal")))
	var signal_type := _signal_text(signal_event, "signal_type", String(context.get("signal_type", "")))
	var zone_id := _signal_text(signal_event, "zone_id", String(context.get("zone_id", "global")))
	if zone_id == "":
		zone_id = "global"
	var npc_id := String(context.get("npc_id", context.get("source_id", "npc"))).strip_edges()
	if npc_id == "":
		npc_id = "npc"
	var chain_depth := int(context.get("chain_depth", 0))
	var severity := int(_signal_value(signal_event, "severity", context.get("severity", 0)))
	var reasons: Array[String] = []

	if chain_depth > max_chain_depth:
		reasons.append("chain_depth_exceeded")
	if int(signal_reaction_counts.get(signal_id, 0)) >= max_reactions_per_signal:
		reasons.append("signal_reaction_cap")
	if int(zone_reaction_counts.get(zone_id, 0)) >= max_reactions_per_zone:
		reasons.append("zone_reaction_cap")
	if int(npc_reaction_counts.get(npc_id, 0)) >= max_reactions_per_npc:
		reasons.append("npc_reaction_cap")
	if reaction_id == "inspect_point" and active_investigations >= max_active_investigations:
		reasons.append("active_investigation_cap")
	if reaction_id == "report_to_authority" and authority_reports >= max_authority_reports:
		reasons.append("authority_report_cap")
	if ignore_lower_severity_while_busy and active_investigations > 0 and severity < busy_severity:
		reasons.append("lower_severity_ignored_while_busy")

	var cooldown_key := "%s|%s|%s" % [npc_id, signal_type, reaction_id]
	var last_time := float(recent_reaction_times.get(cooldown_key, -999999.0))
	var elapsed := now - last_time
	if elapsed < cooldown_seconds:
		reasons.append("cooldown_active")

	var approved := reasons.is_empty()
	if approved:
		_register(signal_id, zone_id, npc_id, cooldown_key, reaction_id, severity, now)
	last_decision = _decision(approved, "attention_budget_approved" if approved else "attention_budget_denied", reasons, signal_id, signal_type, reaction_id, npc_id, zone_id, chain_depth, severity, elapsed)
	return last_decision


func release_reaction(reaction_id: String = "") -> Dictionary:
	if reaction_id == "inspect_point" and active_investigations > 0:
		active_investigations -= 1
	if active_investigations <= 0:
		busy_severity = 0
	return _result(true, "attention_budget_released", "Attention budget released.", String(budget_id), {"active_investigations": active_investigations})


func record_authority_report() -> Dictionary:
	authority_reports += 1
	return _result(true, "authority_report_counted", "Authority report counted.", String(budget_id), {"authority_reports": authority_reports})


func adjust_budget(delta: int) -> Dictionary:
	max_reactions_per_signal = maxi(0, max_reactions_per_signal + delta)
	max_reactions_per_zone = maxi(0, max_reactions_per_zone + delta)
	max_reactions_per_npc = maxi(0, max_reactions_per_npc + delta)
	return _result(true, "attention_budget_adjusted", "Attention budget adjusted.", String(budget_id), {"delta": delta, "max_reactions_per_signal": max_reactions_per_signal})


func get_debug_snapshot() -> Dictionary:
	return {
		"budget_id": String(budget_id),
		"max_reactions_per_signal": max_reactions_per_signal,
		"max_reactions_per_zone": max_reactions_per_zone,
		"max_reactions_per_npc": max_reactions_per_npc,
		"max_chain_depth": max_chain_depth,
		"cooldown_seconds": cooldown_seconds,
		"active_investigations": active_investigations,
		"authority_reports": authority_reports,
		"signal_reaction_counts": signal_reaction_counts.duplicate(true),
		"zone_reaction_counts": zone_reaction_counts.duplicate(true),
		"npc_reaction_counts": npc_reaction_counts.duplicate(true),
		"last_decision": last_decision.duplicate(true),
	}


func _register(signal_id: String, zone_id: String, npc_id: String, cooldown_key: String, reaction_id: String, severity: int, now: float) -> void:
	signal_reaction_counts[signal_id] = int(signal_reaction_counts.get(signal_id, 0)) + 1
	zone_reaction_counts[zone_id] = int(zone_reaction_counts.get(zone_id, 0)) + 1
	npc_reaction_counts[npc_id] = int(npc_reaction_counts.get(npc_id, 0)) + 1
	recent_reaction_times[cooldown_key] = now
	if reaction_id == "inspect_point":
		active_investigations += 1
		busy_severity = maxi(busy_severity, severity)
	if reaction_id == "report_to_authority":
		authority_reports += 1


func _decision(approved: bool, code: String, reasons: Array[String], signal_id: String, signal_type: String, reaction_id: String, npc_id: String, zone_id: String, chain_depth: int, severity: int, cooldown_elapsed: float) -> Dictionary:
	return _result(approved, code, "Reaction approved." if approved else "Reaction denied by attention budget.", String(budget_id), {
		"budget_result": "approved" if approved else "denied",
		"reasons": reasons,
		"signal_id": signal_id,
		"signal_type": signal_type,
		"reaction_id": reaction_id,
		"npc_id": npc_id,
		"zone_id": zone_id,
		"chain_depth": chain_depth,
		"severity": severity,
		"cooldown_elapsed": cooldown_elapsed,
	})


func _signal_text(signal_event: Resource, property: String, fallback: String) -> String:
	if signal_event != null:
		return String(signal_event.get(property)).strip_edges()
	return fallback.strip_edges()


func _signal_value(signal_event: Resource, property: String, fallback: Variant) -> Variant:
	if signal_event != null:
		return signal_event.get(property)
	return fallback


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
