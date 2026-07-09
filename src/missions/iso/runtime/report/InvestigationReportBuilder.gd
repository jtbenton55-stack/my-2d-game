class_name InvestigationReportBuilder
extends RefCounted

## Replan Packet 4: after extraction, investigators read the scene the player
## left behind. This builder turns surviving paper traces, alarms, witness
## reports, and leftover mess into a stylized police report -- the single
## narrative payoff for the whole trace/mess economy, and the input to venue
## heat (Packet 6).

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")

static var last_report: Dictionary = {}


static func build_report(mission_id: String) -> Dictionary:
	var mid := mission_id.strip_edges()
	var paper := PaperTrailAdapterScript.get_summary(mid)
	var social := SocialStealthAdapterScript.get_summary(mid)
	var reactive := ReactiveNpcBrainAdapterScript.get_summary(mid)
	var alarms := _performance_int(mid, "alarms_triggered")
	var authority_reports := int(reactive.get("authority_reports", 0))
	var open_mess := _count_open_mess()
	var verdict := _verdict(paper, alarms, authority_reports)
	var narrative := _narrative_lines(mid, paper, alarms, authority_reports, open_mess, social)
	narrative.append(_sterling_signoff(verdict))
	var report := {
		"mission_id": mid,
		"verdict": verdict,
		"headline": _headline(verdict),
		"prime_suspect": _prime_suspect(verdict, mid),
		"lines": narrative,
		"heat_delta": _heat_delta(verdict, paper, alarms, authority_reports, open_mess),
		"alarms_triggered": alarms,
		"authority_reports": authority_reports,
		"open_mess": open_mess,
		"paper_result_state": String(paper.get("result_state", "clean")),
	}
	last_report = report.duplicate(true)
	return report


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	var out := result.duplicate(true)
	var mid := String(out.get("mission_id", ""))
	if mid == "":
		return out
	out["investigation_report"] = build_report(mid)
	return out


static func _verdict(paper: Dictionary, alarms: int, authority_reports: int) -> String:
	var state := String(paper.get("result_state", "clean"))
	if state == "seen" or alarms > 0 or authority_reports > 0:
		return "hot_pursuit"
	if state == "clean":
		return "cold_case"
	if state == "explainable":
		return "misdirected"
	return "open_investigation"


static func _headline(verdict: String) -> String:
	match verdict:
		"cold_case":
			return "CASE CLOSED: UNSOLVED"
		"misdirected":
			return "CASE CLOSED: SUSPECT IDENTIFIED"
		"hot_pursuit":
			return "ACTIVE INVESTIGATION: SUSPECT AT LARGE"
		_:
			return "CASE OPEN: EVIDENCE UNDER REVIEW"


static func _prime_suspect(verdict: String, _mission_id: String) -> String:
	match verdict:
		"cold_case":
			return "none"
		"misdirected":
			return "local raccoon"
		"hot_pursuit":
			return "unidentified figure with a small brown dog"
		_:
			return "person or persons unknown"


static func _narrative_lines(mission_id: String, paper: Dictionary, alarms: int, authority_reports: int, open_mess: int, social: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for event in PaperTrailAdapterScript.get_trace_events(mission_id):
		var status := String(event.get("status", "active"))
		var severity := int(event.get("severity", 0))
		if status == "cleaned" or severity <= 0 and status != "redirected":
			continue
		var line := _trace_line(String(event.get("trace_type", "generic")), status)
		if line != "" and not lines.has(line):
			lines.append(line)
	if alarms > 0:
		lines.append("Alarm records show %d activation(s) during the incident window." % alarms)
	if authority_reports > 0:
		lines.append("%d staff report(s) were filed describing suspicious behavior." % authority_reports)
	if open_mess > 0:
		lines.append("The scene was left in disarray (%d uncleaned spot(s) catalogued)." % open_mess)
	if int(social.get("inspections_failed", 0)) > 0:
		lines.append("Staff recall an employee who could not explain themselves when questioned.")
	if lines.is_empty():
		lines.append("No usable evidence recovered. Investigators are stumped.")
	return lines


static func _trace_line(trace_type: String, status: String) -> String:
	if status == "redirected":
		return "Evidence trail conveniently points elsewhere. Investigators nod along."
	match trace_type:
		"door_memory":
			return "A door was found open that staff swear they locked."
		"camera_seen":
			return "Camera footage captured a figure on the premises."
		"audit_log":
			return "System audit logs show tampering during the incident window."
		"evidence_touch":
			return "Handled items were found out of place."
		"noise":
			return "Multiple witnesses reported unexplained sounds."
		"witness":
			return "A witness gave a description to investigators."
		_:
			return "Unexplained traces were recovered at the scene."


## Mission Bible v2: reports read like Sterling's fixers wrote them, so the
## villain has a voice in the failure loop.
static func _sterling_signoff(verdict: String) -> String:
	match verdict:
		"cold_case":
			return "Copy forwarded to Sterling Holdings Risk Division. Annotation in the margin: \"Nothing. Again. Find them.\""
		"misdirected":
			return "Copy forwarded to Sterling Holdings Risk Division. Annotation: \"A raccoon. You are billing me for a raccoon.\""
		"hot_pursuit":
			return "Copy forwarded to Sterling Holdings Risk Division. Annotation: \"Now we have a description. Mr. Sterling sends his regards.\""
		_:
			return "Copy forwarded to Sterling Holdings Risk Division. Annotation: \"Keep the file open. Everything surfaces eventually.\""


static func _heat_delta(verdict: String, paper: Dictionary, alarms: int, authority_reports: int, open_mess: int) -> int:
	if verdict == "cold_case":
		return 0
	var heat := 0
	heat += clampi(int(round(float(paper.get("severity_score", 0)) / 3.0)), 0, 3)
	if alarms > 0:
		heat += 1
	if authority_reports > 0:
		heat += 1
	if open_mess >= 3:
		heat += 1
	if verdict == "misdirected":
		heat = maxi(0, heat - 2)
	return clampi(heat, 0, 5)


static func _performance_int(mission_id: String, key: String) -> int:
	var game_state := _autoload("GameState")
	if game_state == null:
		return 0
	var performance: Variant = game_state.get("mission_performance")
	if not (performance is Dictionary):
		return 0
	var record: Variant = (performance as Dictionary).get(mission_id, {})
	if not (record is Dictionary):
		return 0
	return int((record as Dictionary).get(key, 0))


static func _count_open_mess() -> int:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return 0
	var count := 0
	for node in (main_loop as SceneTree).get_nodes_in_group("mission_mess"):
		if is_instance_valid(node):
			count += 1
	return count


static func format_report_text(report: Dictionary) -> String:
	var text := "%s\n" % String(report.get("headline", ""))
	text += "Prime suspect: %s\n" % String(report.get("prime_suspect", "unknown"))
	for line: Variant in (report.get("lines", []) as Array):
		text += "- %s\n" % String(line)
	text += "Venue heat: +%d" % int(report.get("heat_delta", 0))
	return text


static func _autoload(autoload_name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(autoload_name)
