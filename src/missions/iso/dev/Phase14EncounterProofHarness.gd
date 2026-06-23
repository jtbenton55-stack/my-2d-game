@tool
class_name Phase14EncounterProofHarness
extends Node

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var encounter_controller_path: NodePath = NodePath("../../MissionMechanics/EncounterController_phase14_encounter")
@export var status_label_path: NodePath = NodePath("StatusLabel")

@onready var _controller: Node = get_node_or_null(encounter_controller_path)
@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_connect_button("Run Clean Social Route", _run_clean_social_route)
	_connect_button("Run Bentley Route", _run_bentley_route)
	_connect_button("Run Evidence Route", _run_evidence_route)
	_connect_button("Run Messy Route", _run_messy_route)
	_set_status("Phase 14 encounter proof ready. Use a route button to simulate a non-HP challenge win.")


func _run_clean_social_route() -> void:
	_prepare_route()
	SocialStealthAdapterScript.set_cover_story("night_cleaner", {}, _context())
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, _context())
	SocialStealthAdapterScript.adjust_professionalism(2, _context())
	_controller.call("adjust_meter", "plausible_deniability", 3, {"route": "clean_social"})
	_controller.call("adjust_meter", "suspicion", -1, {"route": "clean_social"})
	_advance_to_win("clean_social")


func _run_bentley_route() -> void:
	_prepare_route()
	_controller.call("adjust_meter", "bentley_confidence", 4, {"route": "bentley"})
	_controller.call("adjust_meter", "security_integrity", -2, {"route": "bentley"})
	_advance_to_win("bentley")


func _run_evidence_route() -> void:
	_prepare_route()
	_controller.call("adjust_meter", "evidence_strength", 4, {"route": "evidence"})
	_controller.call("adjust_meter", "plausible_deniability", 1, {"route": "evidence"})
	_advance_to_win("evidence")


func _run_messy_route() -> void:
	_prepare_route()
	PaperTrailAdapterScript.record_trace("messy_route_trace", "phase14_proof", "witness", 3, true, "cleanup", _context(), {"route": "messy"})
	_controller.call("adjust_meter", "suspicion", 4, {"route": "messy"})
	_controller.call("adjust_meter", "security_integrity", -3, {"route": "messy"})
	_controller.call("adjust_meter", "evidence_strength", 2, {"route": "messy"})
	_advance_to_win("messy")


func _prepare_route() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.is_in_mission = true
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission("test_mission")
	if _controller != null:
		_controller.call("reset_encounter")
		_controller.call("start_encounter")


func _advance_to_win(route_tag: String) -> void:
	_controller.call("record_event", "%s_route_started" % route_tag, {"route": route_tag})
	_controller.call("complete_current_phase", route_tag, {"route": route_tag})
	_controller.call("complete_current_phase", route_tag, {"route": route_tag})
	_controller.call("complete_current_phase", route_tag, {"route": route_tag})
	_set_status(_summary_line(route_tag))


func _summary_line(route_tag: String) -> String:
	if _controller == null or not _controller.has_method("get_summary"):
		return "Missing EncounterController."
	var summary: Dictionary = _controller.call("get_summary")
	var meters: Dictionary = summary.get("meters", {})
	var parts: Array[String] = []
	for meter_id in meters.keys():
		var meter: Dictionary = meters.get(meter_id, {})
		parts.append("%s=%d" % [String(meter_id), int(meter.get("value", 0))])
	return "Route %s -> state=%s phase=%s tags=%s meters=[%s]" % [route_tag, "won" if bool(summary.get("success", false)) else "active", String(summary.get("current_phase_id", "")), str(summary.get("result_tags", {})), ", ".join(parts)]


func _connect_button(button_name: String, target: Callable) -> void:
	var button := find_child(button_name, true, false) as Button
	if button != null and not button.pressed.is_connected(target):
		button.pressed.connect(target)


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _context() -> Dictionary:
	return {"mission_id": "test_mission", "source_id": "phase14_proof", "encounter_controller": _controller}
