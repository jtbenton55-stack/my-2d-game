@tool
class_name CornerStoreCashoutIntegratedProofHarness
extends Control

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")

@export var mission_id: String = "corner_store_cashout"
@export var mission_controller_path: NodePath = NodePath("../../../../RuntimeHelpers/CornerStoreCashoutMissionController")
@export var encounter_controller_path: NodePath = NodePath("../../../../RuntimeHelpers/CornerStoreCashoutEncounterController")
@export var status_label_path: NodePath = NodePath("../StatusLabel")

@onready var _mission_controller: Node = get_node_or_null(mission_controller_path)
@onready var _encounter_controller: Node = get_node_or_null(encounter_controller_path)
@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var button: Button = null
	var parent := get_parent()
	if parent != null:
		button = parent.find_child("Run Integrated Proof", true, false) as Button
	if button == null:
		button = find_child("Run Integrated Proof", true, false) as Button
	if button != null and not button.pressed.is_connected(run_integrated_proof):
		button.pressed.connect(run_integrated_proof)
	_set_status("Corner Store integrated proof ready.")


func run_integrated_proof() -> Dictionary:
	_prepare_runtime_state()
	if _encounter_controller == null:
		return _finish(false, "encounter_controller_missing", "Missing corner store encounter controller.", {})
	if _mission_controller == null:
		return _finish(false, "mission_controller_missing", "Missing corner store mission controller.", {})
	_encounter_controller.call("reset_encounter")
	_encounter_controller.call("start_encounter")
	var context := _context()
	var steps: Array[Dictionary] = []
	steps.append(SocialStealthAdapterScript.set_cover_story("delivery_restock_helper", {"display_name": "Delivery restock helper"}, context))
	steps.append(SocialStealthAdapterScript.grant_credential("corner_store_vendor_badge", {"display_name": "Vendor restock badge"}, context))
	steps.append(PaperTrailAdapterScript.record_trace("csc_proof_invoice_touch", mission_id, "evidence_touch", 2, true, "security_log_cleanup", context, {"proof": "corner_store_cashout"}))
	steps.append(ReactiveNpcBrainAdapterScript.record_signal(_make_signal(), context))
	steps.append(_encounter_controller.call("run_clean_social_route", context) as Dictionary)
	MissionFactBridge.set_fact_value(&"mission_flag", "csc_entry_clue_found", true, context)
	MissionFactBridge.set_fact_value(&"mission_flag", "csc_badge_collected", true, context)
	MissionFactBridge.set_fact_value(&"mission_flag", "csc_checkpoint_open", true, context)
	MissionFactBridge.set_fact_value(&"mission_flag", "csc_evidence_collected", true, context)
	MissionFactBridge.set_fact_value(&"mission_flag", "csc_route_selected", "clean_social_route", context)
	if _mission_controller.has_method("sync_from_mission_facts"):
		_mission_controller.call("sync_from_mission_facts")
	var summary := {
		"encounter": _encounter_controller.call("get_summary") if _encounter_controller.has_method("get_summary") else {},
		"paper_trail": PaperTrailAdapterScript.get_summary(mission_id),
		"social_stealth": SocialStealthAdapterScript.get_summary(mission_id),
		"reactive_npc": ReactiveNpcBrainAdapterScript.get_summary(mission_id),
		"mission_controller_ready": bool(_mission_controller.call("are_exit_requirements_met")) if _mission_controller.has_method("are_exit_requirements_met") else false,
		"steps": steps,
	}
	var ok := bool(summary.get("mission_controller_ready", false))
	return _finish(ok, "corner_store_integrated_proof_complete" if ok else "corner_store_integrated_proof_incomplete", "Corner store integrated proof finished.", summary)


func _prepare_runtime_state() -> void:
	GameState.current_mission_id = mission_id
	GameState.is_in_mission = true
	GameState.begin_mission_performance(mission_id)
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission(mission_id)
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission(mission_id)
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission(mission_id)


func _context() -> Dictionary:
	return {
		"mission_id": mission_id,
		"source_id": "corner_store_cashout",
		"encounter_controller": _encounter_controller,
		"completion_controller": _mission_controller,
	}


func _make_signal() -> Resource:
	var event: Resource = SocialSignalEventScript.new()
	event.set("signal_id", &"corner_store_clerk_glance")
	event.set("signal_type", SocialSignalEventScript.SIGNAL_SUSPICIOUS_ACTION_SEEN)
	event.set("mission_id", mission_id)
	event.set("source_id", &"corner_store_clerk")
	event.set("severity", 1)
	event.set("debug_summary", "Clerk noticed the delivery helper but did not escalate.")
	return event


func _finish(ok: bool, code: String, message: String, details: Dictionary) -> Dictionary:
	var result := {"ok": ok, "code": code, "message": message, "source_id": "corner_store_integrated_proof", "details": details}
	_set_status("%s | %s" % [code, message])
	return result


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
