class_name Phase16GarageManagerDeniabilityController
extends EncounterController

const ChallengeMeterDataScript := preload("res://src/missions/iso/encounters/ChallengeMeterData.gd")
const EncounterPhaseDataScript := preload("res://src/missions/iso/encounters/EncounterPhaseData.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")
const SocialReactionRuleSetScript := preload("res://src/missions/iso/ai/SocialReactionRuleSet.gd")

@export var auto_configure_default_data: bool = true
@export var garage_manager_id: StringName = &"taco_garage_manager"
@export var authority_id: StringName = &"taco_shift_authority"
@export_multiline var debug_note: String = "Phase 16 Taco garage-manager deniability encounter adoption."

var route_log: Array[Dictionary] = []
var last_route_id: String = ""


func _ready() -> void:
	if auto_configure_default_data:
		_ensure_default_encounter_data()
	super._ready()


func run_clean_social_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _phase16_context(details)
	var results: Array[Dictionary] = []
	results.append(SocialStealthAdapterScript.set_cover_story("garage_vendor_checkin", {"display_name": "Routine vendor check-in", "manager_id": String(garage_manager_id)}, context))
	results.append(SocialStealthAdapterScript.grant_credential("louis_delivery_invoice", {"display_name": "Louis delivery invoice"}, context))
	results.append(SocialStealthAdapterScript.complete_task("restock_sauce_crates", {"display_name": "Restock sauce crates"}, context))
	results.append(SocialStealthAdapterScript.complete_protocol("garage_manager_small_talk", {"display_name": "Manager small-talk protocol"}, context))
	results.append(SocialStealthAdapterScript.adjust_professionalism(2, context))
	results.append(SocialStealthAdapterScript.record_inspection("garage_manager_checkin", true, {"reason": "The player looked like a routine delivery helper."}, context))
	results.append(adjust_meter("plausible_deniability", 4, {"route": "clean_social"}))
	results.append(adjust_meter("suspicion", -2, {"route": "clean_social"}))
	results.append(set_result_tag("clean_social_route", true))
	results.append(set_result_tag("garage_manager_satisfied", true))
	results.append(record_event("clean_social_route", {"manager_id": String(garage_manager_id), "protocol": "garage_manager_small_talk"}))
	var resolution := win_encounter("clean_social_route")
	return _route_result("clean_social_route", resolution, results)


func run_bentley_distraction_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _phase16_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("phase16_bentley_sauce_paw", "garage_manager_deniability", "witness", 2, false, "", context, {"explanation": "Bentley sauce-paw distraction"}))
	results.append(PaperTrailAdapterScript.redirect_traces({"trace_id": "phase16_bentley_sauce_paw", "severity_reduction": 2}, "bentley_sauce_paw_distraction", context))
	var signal_event := _make_signal("phase16_bentley_distraction_seen", SocialSignalEventScript.SIGNAL_BENTLEY_DISTRACTION_SEEN, 1, "Bentley drew the manager away from the garage office.")
	results.append(ReactiveNpcBrainAdapterScript.record_signal(signal_event, context))
	results.append(adjust_meter("bentley_confidence", 4, {"route": "bentley_distraction"}))
	results.append(adjust_meter("plausible_deniability", 2, {"route": "bentley_distraction"}))
	results.append(set_result_tag("bentley_distraction_route", true))
	results.append(record_event("bentley_distraction_route", {"trace_id": "phase16_bentley_sauce_paw"}))
	var resolution := win_encounter("bentley_distraction_route")
	return _route_result("bentley_distraction_route", resolution, results)


func run_evidence_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _phase16_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("phase16_garage_invoice_touch", "garage_manager_deniability", "evidence_touch", 2, true, "invoice_chain_of_custody", context, {"evidence_id": "taco_bell_sterling_route_invoice"}))
	results.append(SocialStealthAdapterScript.complete_protocol("invoice_chain_of_custody", {"display_name": "Invoice chain of custody"}, context))
	results.append(adjust_meter("evidence_strength", 5, {"route": "evidence"}))
	results.append(adjust_meter("plausible_deniability", 1, {"route": "evidence"}))
	results.append(set_result_tag("evidence_route", true))
	results.append(record_event("evidence_route", {"evidence_id": "taco_bell_sterling_route_invoice"}))
	var resolution := win_encounter("evidence_route")
	return _route_result("evidence_route", resolution, results)


func run_messy_authority_route(details: Dictionary = {}) -> Dictionary:
	_ensure_started_route()
	var context := _phase16_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.record_trace("phase16_manager_witness_report", "garage_manager_deniability", "witness", 4, true, "manager_story_redirect", context, {"manager_id": String(garage_manager_id)}))
	var report_signal := _make_signal("phase16_manager_authority_report", SocialSignalEventScript.SIGNAL_AUTHORITY_CALLED, 4, "Garage manager called the shift authority.")
	var report_rule := _make_authority_report_rule()
	results.append(ReactiveNpcBrainAdapterScript.evaluate_signal(report_signal, [report_rule], null, context))
	results.append(adjust_meter("suspicion", 5, {"route": "messy_authority"}))
	results.append(adjust_meter("security_integrity", -4, {"route": "messy_authority"}))
	results.append(set_result_tag("messy_authority_route", true))
	results.append(record_event("messy_authority_route", {"authority_id": String(authority_id)}))
	var resolution := fail_encounter("Garage manager escalated to authority.")
	return _route_result("messy_authority_route", resolution, results)


func run_cleanup_redirect_trace(details: Dictionary = {}) -> Dictionary:
	var context := _phase16_context(details)
	var results: Array[Dictionary] = []
	results.append(PaperTrailAdapterScript.redirect_traces({"source_id": "garage_manager_deniability", "severity_reduction": 2}, "manager_story_redirect", context))
	results.append(PaperTrailAdapterScript.cleanup_traces({"source_id": "garage_manager_deniability", "cleanup_mode": "weaken", "cleanup_strength": 1}, context))
	results.append(adjust_meter("plausible_deniability", 2, {"route": "cleanup_redirect"}))
	results.append(adjust_meter("suspicion", -1, {"route": "cleanup_redirect"}))
	results.append(set_result_tag("cleanup_redirect_trace", true))
	results.append(record_event("cleanup_redirect_trace", {"explanation": "manager_story_redirect"}))
	return _route_result("cleanup_redirect_trace", _result(true, "cleanup_redirect_applied", "Cleanup/redirect applied.", String(encounter_id)), results)


func get_phase16_summary() -> Dictionary:
	var mission_id := _phase16_mission_id()
	var summary := get_summary()
	summary["phase16"] = true
	summary["last_route_id"] = last_route_id
	summary["last_route_label"] = _route_label(last_route_id)
	summary["route_log"] = route_log.duplicate(true)
	summary["paper_trail"] = PaperTrailAdapterScript.get_summary(mission_id)
	summary["social_stealth"] = SocialStealthAdapterScript.get_summary(mission_id)
	summary["reactive_npc"] = ReactiveNpcBrainAdapterScript.get_summary(mission_id)
	return summary


func get_summary() -> Dictionary:
	var summary := super.get_summary()
	summary["phase16"] = true
	summary["last_route_id"] = last_route_id
	summary["last_route_label"] = _route_label(last_route_id)
	summary["route_log"] = route_log.duplicate(true)
	return summary


func _ensure_started_route() -> void:
	_ensure_default_encounter_data()
	if resolved:
		reset_encounter()
	if not active:
		start_encounter()


func _ensure_default_encounter_data() -> void:
	if String(encounter_id).strip_edges() == "encounter":
		encounter_id = &"phase16_taco_garage_manager_deniability"
	if display_name.strip_edges() == "Encounter":
		display_name = "Garage Manager Deniability"
	if mission_id_override.strip_edges() == "":
		mission_id_override = "taco_bell_drop"
	if String(initial_phase_id).strip_edges() == "":
		initial_phase_id = &"manager_noticed"
	if phases.is_empty():
		var noticed := _make_phase(&"manager_noticed", "Manager Noticed", "Keep the garage manager from escalating.", &"manager_pressure", false, &"")
		var pressure := _make_phase(&"manager_pressure", "Manager Pressure", "Resolve the suspicion through social, Bentley, evidence, or cleanup play.", &"resolution", false, &"")
		var resolution := _make_phase(&"resolution", "Resolution", "Lock the chosen deniability route.", &"", true, &"garage_manager_resolved")
		var phase_list: Array[Resource] = []
		phase_list.append(noticed)
		phase_list.append(pressure)
		phase_list.append(resolution)
		phases = phase_list
	if meters.is_empty():
		var meter_list: Array[Resource] = []
		meter_list.append(_make_meter(&"suspicion", "Suspicion Pressure", 0, 10, 2, false))
		meter_list.append(_make_meter(&"security_integrity", "Security Integrity", 0, 10, 6, true))
		meter_list.append(_make_meter(&"evidence_strength", "Evidence Strength", 0, 10, 0, true))
		meter_list.append(_make_meter(&"bentley_confidence", "Bentley Confidence", 0, 10, 0, true))
		meter_list.append(_make_meter(&"plausible_deniability", "Plausible Deniability", 0, 10, 1, true))
		meters = meter_list


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
	event.set("source_id", garage_manager_id)
	event.set("mission_id", _phase16_mission_id())
	event.set("zone_id", &"taco_garage_office")
	event.set("severity", severity)
	event.set("witness_group", garage_manager_id)
	event.set("debug_summary", debug_summary)
	return event


func _make_authority_report_rule() -> Resource:
	var rule: Resource = SocialReactionRuleSetScript.new()
	rule.set("rule_id", &"phase16_manager_reports_authority")
	rule.set("display_name", "Garage manager reports to authority")
	var accepted_types: Array[StringName] = []
	accepted_types.append(SocialSignalEventScript.SIGNAL_AUTHORITY_CALLED)
	rule.set("accepted_signal_types", accepted_types)
	rule.set("reaction_id", SocialReactionRuleSetScript.REACTION_REPORT_TO_AUTHORITY)
	rule.set("target_authority_id", authority_id)
	rule.set("cooldown_seconds", 0.0)
	return rule


func _phase16_context(extra: Dictionary = {}) -> Dictionary:
	var context := extra.duplicate(true)
	context["mission_id"] = _phase16_mission_id()
	context["source_id"] = "garage_manager_deniability"
	context["encounter_id"] = String(encounter_id)
	context["encounter_controller"] = self
	context["garage_manager_id"] = String(garage_manager_id)
	return context


func _phase16_mission_id() -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id({})


func _route_result(route_id: String, resolution: Dictionary, results: Array[Dictionary]) -> Dictionary:
	last_route_id = route_id
	var record := {
		"route_id": route_id,
		"route_label": _route_label(route_id),
		"ok": bool(resolution.get("ok", false)),
		"code": String(resolution.get("code", "")),
		"paper_trail_state": String(PaperTrailAdapterScript.get_summary(_phase16_mission_id()).get("result_state", "clean")),
	}
	route_log.append(record)
	var ok := bool(resolution.get("ok", false))
	return _result(ok, "phase16_route_resolved" if ok else "phase16_route_escalated", String(resolution.get("message", "Phase 16 route resolved.")), route_id, {"route": record, "steps": results, "summary": get_phase16_summary()})


func _route_label(route_id: String) -> String:
	match route_id:
		"clean_social_route":
			return "Clean Social"
		"bentley_distraction_route":
			return "Bentley Distraction"
		"evidence_route":
			return "Evidence Chain"
		"messy_authority_route":
			return "Messy Authority Report"
		"cleanup_redirect_trace":
			return "Cleanup / Redirect"
		_:
			return "-" if route_id.strip_edges() == "" else route_id.capitalize()
