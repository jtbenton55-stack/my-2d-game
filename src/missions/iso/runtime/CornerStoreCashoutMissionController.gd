class_name CornerStoreCashoutMissionController
extends Node

const MISSION_ID := "corner_store_cashout"

@export var mission_id: String = MISSION_ID

var entry_clue_found := false
var badge_collected := false
var back_office_unlocked := false
var terminal_hacked := false
var records_found := false
var evidence_collected := false
var route_selected := false
var extracted := false
var mission_completed := false
var completed_objectives: Dictionary = {}


func _ready() -> void:
	set_meta("scene_local_only", true)
	_seed_objectives()
	if not Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	sync_from_mission_facts()


func reset_attempt_state() -> Dictionary:
	entry_clue_found = false
	badge_collected = false
	back_office_unlocked = false
	terminal_hacked = false
	records_found = false
	evidence_collected = false
	route_selected = false
	extracted = false
	mission_completed = false
	completed_objectives.clear()
	return _seed_objectives()


func sync_from_mission_facts() -> void:
	var context := {"mission_id": mission_id}
	if _mission_flag_set("csc_entry_clue_found", context):
		set_entry_clue_found(true)
	if _mission_flag_set("csc_badge_collected", context):
		set_badge_collected(true)
	if _mission_flag_set("csc_checkpoint_open", context):
		set_back_office_unlocked(true)
	if _mission_flag_set("csc_terminal_hacked", context):
		set_terminal_hacked(true)
	if _mission_flag_set("csc_records_found", context):
		set_records_found(true)
	if _mission_flag_set("csc_evidence_collected", context):
		set_evidence_collected(true)
	var route_choice: Variant = MissionFactBridge.get_fact_value(&"mission_flag", "csc_route_selected", context)
	if route_choice != null and str(route_choice).strip_edges() != "":
		set_route_selected(true)
	if _mission_flag_set("csc_extracted", context):
		set_extracted(true)


func _mission_flag_set(flag_id: String, context: Dictionary) -> bool:
	return bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_id, context))


func set_entry_clue_found(value: bool) -> void:
	if entry_clue_found == value:
		return
	entry_clue_found = value
	if value:
		set_objective_complete("find_back_office_clue")
		ObjectiveStepController.activate_objective("collect_employee_badge", "Grab or fake an employee credential.", mission_id)
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_entry_clue_found", true, {"mission_id": mission_id})


func set_badge_collected(value: bool) -> void:
	if badge_collected == value:
		return
	badge_collected = value
	if value:
		set_objective_complete("collect_employee_badge")
		ObjectiveStepController.activate_objective("open_back_office", "Bypass the employee-only door.", mission_id)
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_badge_collected", true, {"mission_id": mission_id})


func set_back_office_unlocked(value: bool) -> void:
	if back_office_unlocked == value:
		return
	back_office_unlocked = value
	if value:
		set_objective_complete("open_back_office")
		ObjectiveStepController.activate_objective("recover_cashout_evidence", "Recover the cash envelope and insurance scam folder.", mission_id)
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_checkpoint_open", true, {"mission_id": mission_id})


func set_terminal_hacked(value: bool) -> void:
	if terminal_hacked == value:
		return
	terminal_hacked = value
	if value:
		set_objective_complete("hack_security_log")
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_terminal_hacked", true, {"mission_id": mission_id})


func set_records_found(value: bool) -> void:
	if records_found == value:
		return
	records_found = value
	if value:
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_records_found", true, {"mission_id": mission_id})


func set_evidence_collected(value: bool) -> void:
	if evidence_collected == value:
		return
	evidence_collected = value
	if value:
		set_objective_complete("recover_cashout_evidence")
		ObjectiveStepController.activate_objective("choose_cleanup_route", "Choose how to leave without starting a scene.", mission_id)
		ObjectiveStepController.activate_objective("extract_alley", "Extract through the alley.", mission_id)
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_evidence_collected", true, {"mission_id": mission_id})


func set_route_selected(value: bool) -> void:
	if route_selected == value:
		return
	route_selected = value
	if value:
		set_objective_complete("choose_cleanup_route")
		# Do not write csc_route_selected here: route actions store the chosen
		# route id string in that flag and a bool write would clobber it.


func set_extracted(value: bool) -> void:
	if extracted == value:
		return
	extracted = value
	if value:
		set_objective_complete("extract_alley")
		MissionFactBridge.set_fact_value(&"mission_flag", "csc_extracted", true, {"mission_id": mission_id})


func set_objective_complete(objective_id: String) -> void:
	completed_objectives[objective_id] = true
	ObjectiveStepController.complete_objective(objective_id, "", mission_id)


func are_exit_requirements_met() -> bool:
	return evidence_collected and route_selected


func get_missing_requirements() -> Array[String]:
	var missing: Array[String] = []
	if not evidence_collected:
		missing.append("recover the cash envelope and scam folder")
	if not route_selected:
		missing.append("choose a cleanup route")
	return missing


func complete_mission_and_exit() -> Dictionary:
	if mission_completed:
		return {"success": true, "already_done": true, "mission_id": mission_id}
	if not are_exit_requirements_met():
		return {"success": false, "message": "Exit requirements not met", "missing": get_missing_requirements()}
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("request_exit_completion"):
		var ok := bool(mission.call("request_exit_completion"))
		if ok:
			mission_completed = true
			set_extracted(true)
			return {"success": true, "mission_id": mission_id, "via": "request_exit_completion"}
	return {"success": false, "mission_id": mission_id, "via": "request_exit_completion_rejected"}


func _seed_objectives() -> Dictionary:
	return MissionObjectiveBridge.seed_runtime_objectives_for_mission(mission_id, [
		{"id": "find_back_office_clue", "text": "Find how employees reach the back office.", "status": "active"},
		{"id": "collect_employee_badge", "text": "Grab or fake an employee credential.", "status": "locked"},
		{"id": "open_back_office", "text": "Bypass the employee-only door.", "status": "locked"},
		{"id": "recover_cashout_evidence", "text": "Recover the cash envelope and insurance scam folder.", "status": "locked"},
		{"id": "choose_cleanup_route", "text": "Choose how to leave without starting a scene.", "status": "locked"},
		{"id": "extract_alley", "text": "Extract through the alley.", "status": "locked"},
	])
