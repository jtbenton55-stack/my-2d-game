class_name CornerStoreCashoutEncounterController
extends EncounterController

const ChallengeMeterDataScript := preload("res://src/missions/iso/encounters/ChallengeMeterData.gd")
const EncounterPhaseDataScript := preload("res://src/missions/iso/encounters/EncounterPhaseData.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const SocialReactionRuleSetScript := preload("res://src/missions/iso/ai/SocialReactionRuleSet.gd")

@export var auto_configure_default_data: bool = true
@export var clerk_id: StringName = &"corner_store_clerk"
@export var guard_id: StringName = &"corner_store_guard"

var route_log: Array[Dictionary] = []
var last_route_id: String = ""
var last_route_style_label: String = ""


func _ready() -> void:
	if auto_configure_default_data:
		_ensure_default_encounter_data()
	start_on_ready = false
	super._ready()


func run_clean_social_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _route_context(details)
	var results: Array[Dictionary] = []
	results.append(SocialStealthAdapterScript.set_cover_story("delivery_restock_helper", {"display_name": "Delivery restock helper", "clerk_id": String(clerk_id)}, context))
	results.append(SocialStealthAdapterScript.grant_credential("corner_store_vendor_badge", {"display_name": "Vendor restock badge"}, context))
	results.append(SocialStealthAdapterScript.complete_task("restock_neon_aisle", {"display_name": "Restock neon aisle"}, context))
	results.append(SocialStealthAdapterScript.complete_protocol("clerk_small_talk", {"display_name": "Clerk small-talk protocol"}, context))
	results.append(SocialStealthAdapterScript.adjust_professionalism(2, context))
	results.append(SocialStealthAdapterScript.record_inspection("clerk_checkin", true, {"reason": "Looked like a bored delivery helper."}, context))
	results.append(adjust_meter("plausible_deniability", 4, {"route": "clean_social"}))
	results.append(adjust_meter("suspicion", -2, {"route": "clean_social"}))
	results.append(set_result_tag("clean_social_route", true))
	results.append(record_event("clean_social_route", {"clerk_id": String(clerk_id)}))
	var resolution := win_encounter("clean_social_route")
	return _route_result("clean_social_route", resolution, results)


func run_bentley_distraction_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _route_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("csc_bentley_chip_bag", "corner_store_cashout", "witness", 2, false, "", context, {"explanation": "Bentley chip-bag distraction"}))
	results.append(PaperTrailAdapterScript.redirect_traces({"trace_id": "csc_bentley_chip_bag", "severity_reduction": 2}, "bentley_chip_bag_distraction", context))
	var signal_event := _make_signal("csc_bentley_distraction_seen", SocialSignalEventScript.SIGNAL_BENTLEY_DISTRACTION_SEEN, 1, "Bentley pulled the bored guard toward the snack aisle.")
	results.append(ReactiveNpcBrainAdapterScript.record_signal(signal_event, context))
	results.append(adjust_meter("bentley_confidence", 4, {"route": "bentley_distraction"}))
	results.append(adjust_meter("plausible_deniability", 2, {"route": "bentley_distraction"}))
	results.append(set_result_tag("bentley_distraction_route", true))
	results.append(record_event("bentley_distraction_route", {"trace_id": "csc_bentley_chip_bag"}))
	var resolution := win_encounter("bentley_distraction_route")
	return _route_result("bentley_distraction_route", resolution, results)


func run_evidence_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _route_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("csc_security_log_edit", "corner_store_cashout", "evidence_touch", 2, true, "security_log_cleanup", context, {"evidence_id": "corner_store_insurance_scam_folder"}))
	results.append(SocialStealthAdapterScript.complete_protocol("security_log_cleanup", {"display_name": "Security log cleanup"}, context))
	results.append(adjust_meter("evidence_strength", 5, {"route": "evidence"}))
	results.append(adjust_meter("plausible_deniability", 1, {"route": "evidence"}))
	results.append(set_result_tag("evidence_route", true))
	results.append(record_event("evidence_route", {"evidence_id": "corner_store_insurance_scam_folder"}))
	var resolution := win_encounter("evidence_route")
	return _route_result("evidence_route", resolution, results)


func run_messy_authority_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _route_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("csc_guard_witness_report", "corner_store_cashout", "witness", 4, true, "clerk_story_redirect", context, {"guard_id": String(guard_id)}))
	var report_signal := _make_signal("csc_guard_authority_report", SocialSignalEventScript.SIGNAL_AUTHORITY_CALLED, 4, "Guard called the district loss-prevention line.")
	var report_rule := _make_authority_report_rule()
	results.append(ReactiveNpcBrainAdapterScript.evaluate_signal(report_signal, [report_rule], null, context))
	results.append(adjust_meter("suspicion", 5, {"route": "messy_authority"}))
	results.append(adjust_meter("security_integrity", -4, {"route": "messy_authority"}))
	results.append(set_result_tag("messy_authority_route", true))
	results.append(record_event("messy_authority_route", {"guard_id": String(guard_id)}))
	var resolution := fail_encounter("Corner-store guard escalated to authority.")
	return _route_result("messy_authority_route", resolution, results)


func run_cleanup_redirect_trace(details: Dictionary = {}) -> Dictionary:
	var context := _route_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.redirect_traces({"source_id": "corner_store_cashout", "severity_reduction": 2}, "clerk_story_redirect", context))
	results.append(PaperTrailAdapterScript.cleanup_traces({"source_id": "corner_store_cashout", "cleanup_mode": "weaken", "cleanup_strength": 1}, context))
	results.append(adjust_meter("plausible_deniability", 2, {"route": "cleanup_redirect"}))
	results.append(adjust_meter("suspicion", -1, {"route": "cleanup_redirect"}))
	results.append(set_result_tag("cleanup_redirect_trace", true))
	results.append(record_event("cleanup_redirect_trace", {"explanation": "clerk_story_redirect"}))
	return _route_result("cleanup_redirect_trace", _result(true, "cleanup_redirect_applied", "Cleanup/redirect applied.", String(encounter_id)), results)


func get_summary() -> Dictionary:
	var summary := super.get_summary()
	summary["last_route_id"] = last_route_id
	summary["last_route_label"] = _route_label(last_route_id)
	summary["last_route_style_label"] = _route_style_label(last_route_id)
	summary["route_log"] = route_log.duplicate(true)
	summary["paper_trail"] = PaperTrailAdapterScript.get_summary(_mission_id())
	summary["social_stealth"] = SocialStealthAdapterScript.get_summary(_mission_id())
	summary["reactive_npc"] = ReactiveNpcBrainAdapterScript.get_summary(_mission_id())
	return summary


func _ensure_started_route() -> void:
	_ensure_default_encounter_data()
	if resolved:
		reset_encounter()
	if not active:
		start_encounter()


func _ensure_default_encounter_data() -> void:
	if String(encounter_id).strip_edges() == "encounter":
		encounter_id = &"corner_store_cashout_cleanup"
	if display_name.strip_edges() == "Encounter":
		display_name = "Corner Store Cleanup"
	if mission_id_override.strip_edges() == "":
		mission_id_override = "corner_store_cashout"
	if String(initial_phase_id).strip_edges() == "":
		initial_phase_id = &"clerk_noticed"
	if phases.is_empty():
		var noticed := _make_phase(&"clerk_noticed", "Clerk Noticed", "Keep the clerk from escalating.", &"cleanup_pressure", false, &"")
		var pressure := _make_phase(&"cleanup_pressure", "Cleanup Pressure", "Resolve suspicion through social, Bentley, evidence, or bluff.", &"resolution", false, &"")
		var resolution := _make_phase(&"resolution", "Resolution", "Lock the chosen cleanup route.", &"", true, &"corner_store_resolved")
		phases = [noticed, pressure, resolution]
	if meters.is_empty():
		meters = [
			_make_meter(&"suspicion", "Suspicion Pressure", 0, 10, 2, false),
			_make_meter(&"security_integrity", "Security Integrity", 0, 10, 6, true),
			_make_meter(&"evidence_strength", "Evidence Strength", 0, 10, 0, true),
			_make_meter(&"bentley_confidence", "Bentley Confidence", 0, 10, 0, true),
			_make_meter(&"plausible_deniability", "Plausible Deniability", 0, 10, 1, true),
		]


func _make_phase(id: StringName, label: String, objective: String, next_id: StringName, win_on_success: bool, result_tag: StringName) -> Resource:
	var phase: Resource = EncounterPhaseDataScript.new()
	phase.set("phase_id", id)
	phase.set("display_name", label)
	phase.set("objective_text", objective)
	phase.set("next_phase_id", next_id)
	phase.set("win_on_success", win_on_success)
	phase.set("result_tag_on_success", result_tag)
	return phase


func _make_meter(id: StringName, label: String, min_value: int, max_value: int, initial_value: int, favorable_when_high: bool) -> Resource:
	var meter: Resource = ChallengeMeterDataScript.new()
	meter.set("meter_id", id)
	meter.set("display_name", label)
	meter.set("min_value", min_value)
	meter.set("max_value", max_value)
	meter.set("initial_value", initial_value)
	meter.set("favorable_when_high", favorable_when_high)
	if favorable_when_high:
		meter.set("warning_value", 3)
		meter.set("danger_value", 1)
	else:
		meter.set("warning_value", 4)
		meter.set("danger_value", 7)
	return meter


func _make_signal(signal_id: String, signal_type: StringName, severity: int, debug_summary: String) -> Resource:
	var event: Resource = SocialSignalEventScript.new()
	event.set("signal_id", StringName(signal_id))
	event.set("signal_type", signal_type)
	event.set("source_id", clerk_id)
	event.set("mission_id", _mission_id())
	event.set("zone_id", &"corner_store_back_office")
	event.set("severity", severity)
	event.set("witness_group", clerk_id)
	event.set("debug_summary", debug_summary)
	return event


func _make_authority_report_rule() -> Resource:
	var rule: Resource = SocialReactionRuleSetScript.new()
	rule.set("rule_id", &"csc_guard_reports_authority")
	rule.set("display_name", "Guard reports to authority")
	rule.set("accepted_signal_types", [SocialSignalEventScript.SIGNAL_AUTHORITY_CALLED])
	rule.set("reaction_id", SocialReactionRuleSetScript.REACTION_REPORT_TO_AUTHORITY)
	rule.set("target_authority_id", guard_id)
	rule.set("cooldown_seconds", 0.0)
	return rule


func _route_context(extra: Dictionary = {}) -> Dictionary:
	var context := extra.duplicate(true)
	context["mission_id"] = _mission_id()
	context["source_id"] = "corner_store_cashout"
	context["encounter_id"] = String(encounter_id)
	context["encounter_controller"] = self
	return context


func _mission_id() -> String:
	var override := mission_id_override.strip_edges()
	return override if override != "" else MissionFactBridge.resolve_mission_id({})


func _route_result(route_id: String, resolution: Dictionary, results: Array[Dictionary]) -> Dictionary:
	last_route_id = route_id
	last_route_style_label = _route_style_label(route_id)
	var record := {
		"route_id": route_id,
		"route_label": _route_label(route_id),
		"route_style_label": last_route_style_label,
		"ok": bool(resolution.get("ok", false)),
		"code": String(resolution.get("code", "")),
	}
	route_log.append(record)
	var ok := bool(resolution.get("ok", false))
	return _result(ok, "corner_store_route_resolved" if ok else "corner_store_route_escalated", String(resolution.get("message", "Corner store route resolved.")), route_id, {"route": record, "steps": results, "summary": get_summary()})


func _route_label(route_id: String) -> String:
	match route_id:
		"clean_social_route": return "Clean Social"
		"bentley_distraction_route": return "Bentley Distraction"
		"evidence_route": return "Evidence / Paper Trail"
		"messy_authority_route": return "Messy Authority"
		"cleanup_redirect_trace": return "Cleanup / Redirect"
		_: return route_id.capitalize() if route_id.strip_edges() != "" else "-"


func _route_style_label(route_id: String) -> String:
	match route_id:
		"clean_social_route": return "Deniable"
		"bentley_distraction_route": return "Bentley-Led"
		"evidence_route": return "Evidence-Strong"
		"messy_authority_route": return "Messy / Escalated"
		"cleanup_redirect_trace": return "Cleaned Up"
		_: return ""
