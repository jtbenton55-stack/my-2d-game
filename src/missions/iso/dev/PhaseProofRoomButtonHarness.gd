extends Control

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export_enum("phase9", "phase11", "phase12", "phase13") var proof_id: String = "phase9"
@export var mission_id: String = "test_mission"
@export var status_label_path: NodePath = NodePath("StatusLabel")

@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	match proof_id:
		"phase9":
			_connect_button("Run 9G Course", _run_phase9g_course)
			_connect_button("Run 9H Snack Trail", _run_phase9h_snack_trail)
			_connect_button("Reset Phase 9", _reset_phase9)
			_set_status("Phase 9 proof ready. Use buttons to run the reusable side-job chains.")
		"phase11":
			_connect_button("Record Door Trace", _record_phase11_door_trace)
			_connect_button("Clean Door Trace", _clean_phase11_trace)
			_connect_button("Redirect Door Trace", _redirect_phase11_trace)
			_connect_button("Run Deniable Route", _run_phase11_deniable_route)
			_set_status("Phase 11 proof ready. Record, clean, or redirect a paper trail.")
		"phase12":
			_connect_button("Play Intro Dialogue", _play_phase12_intro_dialogue)
			_connect_button("Play Bentley Bark", _play_phase12_bark)
			_connect_button("Run Intro Sequence", _run_phase12_intro_sequence)
			_connect_button("Run Outro Sequence", _run_phase12_outro_sequence)
			_set_status("Phase 12 proof ready. Trigger dialogue, bark, and presentation sequences.")
		"phase13":
			_connect_button("Grant Staff Identity", _grant_phase13_identity)
			_connect_button("Run Clean Staff Route", _run_phase13_clean_route)
			_connect_button("Run Failed Inspection", _run_phase13_failed_inspection)
			_connect_button("Reset Social State", _reset_phase13)
			_set_status("Phase 13 proof ready. Grant identity or run inspection routes.")


func _run_phase9g_course() -> void:
	_prepare_phase9()
	var results: Array[String] = []
	results.append(_call_code("TimedSwitch_phase9g_start", "trigger_switch", [null, "proof_button"]))
	results.append(_call_code("PressurePlate_phase9g_hold", "press", [null, "proof_button"]))
	results.append(_call_code("PowerCircuit_phase9g_finish", "check_circuit", [null, "proof_button"]))
	results.append(_call_code("Phase9GSequenceRunner", "complete_step", ["start_course", "proof_button"]))
	results.append(_call_code("Phase9GSequenceRunner", "complete_step", ["hold_plate", "proof_button"]))
	results.append(_call_code("Phase9GSequenceRunner", "complete_step", ["power_circuit", "proof_button"]))
	_set_status("9G course -> %s\n%s" % [_sequence_summary("Phase9GSequenceRunner"), ", ".join(results)])


func _run_phase9h_snack_trail() -> void:
	_prepare_phase9()
	var results: Array[String] = []
	results.append(_call_code("DeadDrop_phase9h_retrieve", "use_dead_drop", [null, "proof_button"]))
	results.append(_call_code("ObjectSwap_phase9h_swap", "swap_object", [null, "proof_button"]))
	results.append(_call_code("BugPlant_phase9h_bug", "plant_bug", [null, "proof_button"]))
	results.append(_call_code("Eavesdrop_phase9h_listen", "start_eavesdrop", [null, "proof_button"]))
	results.append(_call_code("Phase9HSequenceRunner", "complete_step", ["retrieve_snack", "proof_button"]))
	results.append(_call_code("Phase9HSequenceRunner", "complete_step", ["swap_snack", "proof_button"]))
	results.append(_call_code("Phase9HSequenceRunner", "complete_step", ["listen_route", "proof_button"]))
	_set_status("9H snack trail -> %s\n%s\nInventory: %s" % [_sequence_summary("Phase9HSequenceRunner"), ", ".join(results), str(MissionInventoryScript.get_snapshot())])


func _reset_phase9() -> void:
	_prepare_phase9()
	_set_status("Phase 9 proof reset. Mission inventory cleared and sequence runners reset.")


func _record_phase11_door_trace() -> void:
	_prepare_phase11(false)
	var code := _call_code("DoorStateMemoryNode_phase11e_door_memory", "record_door_memory", [null, "proof_button"])
	_set_status("Door trace -> %s\n%s" % [code, _paper_summary()])


func _clean_phase11_trace() -> void:
	_prepare_phase11(false)
	if PaperTrailAdapterScript.get_trace_events(mission_id).is_empty():
		_call_code("DoorStateMemoryNode_phase11e_door_memory", "record_door_memory", [null, "proof_seed"])
	var code := _call_code("AuditTrailCleanupNode_phase11c_cleanup", "cleanup_trace", [null, "proof_button"])
	_set_status("Cleanup -> %s\n%s" % [code, _paper_summary()])


func _redirect_phase11_trace() -> void:
	_prepare_phase11(false)
	if PaperTrailAdapterScript.get_trace_events(mission_id).is_empty():
		_call_code("DoorStateMemoryNode_phase11e_door_memory", "record_door_memory", [null, "proof_seed"])
	var code := _call_code("HeatSinkObject_phase11d_misdirection", "redirect_trace", [null, "proof_button"])
	_set_status("Redirect -> %s\n%s" % [code, _paper_summary()])


func _run_phase11_deniable_route() -> void:
	_prepare_phase11(true)
	var results: Array[String] = []
	results.append(_call_code("DoorStateMemoryNode_phase11e_door_memory", "record_door_memory", [null, "proof_button"]))
	results.append(_call_code("HeatSinkObject_phase11d_misdirection", "redirect_trace", [null, "proof_button"]))
	results.append(_call_code("AuditTrailCleanupNode_phase11c_cleanup", "cleanup_trace", [null, "proof_button"]))
	_set_status("Deniable route -> %s\n%s" % [", ".join(results), _paper_summary()])


func _play_phase12_intro_dialogue() -> void:
	_prepare_mission()
	var code := _call_code("DialogueTriggerZone_phase12a_intro_line", "play_dialogue", [null, "proof_button"])
	_set_status("Intro dialogue -> %s" % code)


func _play_phase12_bark() -> void:
	_prepare_mission()
	var code := _call_code("BarkTrigger_phase12b_bentley_bark", "play_dialogue", [null, "proof_button"])
	_set_status("Bentley bark -> %s" % code)


func _run_phase12_intro_sequence() -> void:
	_prepare_mission()
	var code := _call_code("PresentationSequencePlayer", "play_intro", [_context("phase12_intro_button")])
	_set_status("Intro sequence -> %s" % code)


func _run_phase12_outro_sequence() -> void:
	_prepare_mission()
	var code := _call_code("PresentationSequencePlayer", "play_outro", [_context("phase12_outro_button")])
	_set_status("Outro sequence -> %s" % code)


func _grant_phase13_identity() -> void:
	_prepare_phase13(false)
	var context := _context("phase13_identity_button")
	var story := SocialStealthAdapterScript.set_cover_story("staff_cleaner", {}, context)
	var credential := SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)
	_set_status("Identity -> %s, %s\n%s" % [String(story.get("code", "")), String(credential.get("code", "")), _social_summary()])


func _run_phase13_clean_route() -> void:
	_prepare_phase13(true)
	_grant_phase13_identity_without_status()
	var results: Array[String] = []
	results.append(_call_code("BelievableTaskZone_phase13e_believable_task", "complete_task", [null, "proof_button"]))
	results.append(_call_code("ProtocolZone_phase13f_protocol", "complete_protocol", [null, "proof_button"]))
	results.append(_call_code("InspectionZone_phase13d_inspection", "inspect_actor", [null, "proof_button"]))
	results.append(_call_code("CleanlinessGate_phase13f_cleanliness_gate", "unlock", [null, "proof_button"]))
	_set_status("Clean staff route -> %s\n%s" % [", ".join(results), _social_summary()])


func _run_phase13_failed_inspection() -> void:
	_prepare_phase13(true)
	var code := _call_code("InspectionZone_phase13d_inspection", "inspect_actor", [null, "proof_button"])
	_set_status("Failed inspection route -> %s\n%s" % [code, _social_summary()])


func _reset_phase13() -> void:
	_prepare_phase13(true)
	_set_status("Phase 13 social state reset.\n%s" % _social_summary())


func _prepare_phase9() -> void:
	mission_id = "phase9_side_job_proof"
	_prepare_mission()
	MissionInventoryScript.clear_all()
	_call_void("Phase9GSequenceRunner", "reset_sequence")
	_call_void("Phase9HSequenceRunner", "reset_sequence")
	_clear_flag("phase9g_timer_active")
	_clear_flag("phase9g_plate_held")
	_clear_flag("phase9g_course_complete")
	_clear_flag("phase9h_bug_planted")


func _prepare_phase11(clear_state: bool) -> void:
	mission_id = "test_mission"
	_prepare_mission()
	if clear_state:
		PaperTrailAdapterScript.clear_all()
		PaperTrailAdapterScript.reset_mission(mission_id)


func _prepare_phase13(clear_state: bool) -> void:
	mission_id = "test_mission"
	_prepare_mission()
	if clear_state:
		SocialStealthAdapterScript.clear_all()
		SocialStealthAdapterScript.reset_mission(mission_id)
		var meter := _find_node("ProfessionalismMeterNode_phase13f_professionalism")
		if meter != null and meter.has_method("adjust_professionalism"):
			SocialStealthAdapterScript.set_professionalism(int(meter.get("initial_professionalism")), _context("phase13_reset"))
			SocialStealthAdapterScript.set_cleanliness(int(meter.get("initial_cleanliness")), _context("phase13_reset"))


func _prepare_mission() -> void:
	GameState.current_mission_id = mission_id
	GameState.is_in_mission = true


func _grant_phase13_identity_without_status() -> void:
	var context := _context("phase13_identity_seed")
	SocialStealthAdapterScript.set_cover_story("staff_cleaner", {}, context)
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)


func _call_code(node_name: String, method_name: String, args: Array = []) -> String:
	var node := _find_node(node_name)
	if node == null:
		return "%s:missing" % node_name
	if not node.has_method(method_name):
		return "%s:%s_missing" % [node_name, method_name]
	var result: Variant = node.callv(method_name, args)
	if result is Dictionary:
		return String((result as Dictionary).get("code", "ok"))
	return "ok" if bool(result) else "failed"


func _call_void(node_name: String, method_name: String) -> void:
	var node := _find_node(node_name)
	if node != null and node.has_method(method_name):
		node.call(method_name)


func _clear_flag(flag: String) -> void:
	if flag.strip_edges() == "":
		return
	MissionFactBridge.clear_fact_value(&"mission_flag", flag, _context("proof_reset"))


func _sequence_summary(runner_name: String) -> String:
	var node := _find_node(runner_name)
	if node == null or not node.has_method("get_sequence_summary"):
		return "%s summary missing" % runner_name
	var summary: Dictionary = node.call("get_sequence_summary")
	return "sequence=%s complete=%s steps=%s" % [String(summary.get("sequence_id", "")), str(summary.get("all_steps_complete", false)), str(summary.get("completed_steps", []))]


func _paper_summary() -> String:
	return "paper=%s events=%s" % [str(PaperTrailAdapterScript.get_summary(mission_id)), str(PaperTrailAdapterScript.get_trace_events(mission_id))]


func _social_summary() -> String:
	return "social=%s" % str(SocialStealthAdapterScript.get_summary(mission_id))


func _find_node(node_name: String) -> Node:
	if get_tree() == null or get_tree().current_scene == null:
		return null
	return get_tree().current_scene.find_child(node_name, true, false)


func _connect_button(button_name: String, target: Callable) -> void:
	var button := find_child(button_name, true, false) as Button
	if button != null and not button.pressed.is_connected(target):
		button.pressed.connect(target)


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _context(source_id: String) -> Dictionary:
	return {"mission_id": mission_id, "source_id": source_id}
