@tool
class_name Phase17LevelBuilderProofHarness
extends Control

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const SocialSignalEventScript := preload("res://src/missions/iso/ai/SocialSignalEvent.gd")

@export var mission_id: String = "level_builder_readiness_dev"
@export var encounter_controller_path: NodePath = NodePath("../../MissionMechanics/EncounterController_level_builder_readiness")
@export var noise_emitter_path: NodePath = NodePath("../../MissionMechanics/NoiseEmitterNode_level_builder_decoy")
@export var status_label_path: NodePath = NodePath("StatusLabel")

@onready var _controller: Node = get_node_or_null(encounter_controller_path)
@onready var _noise_emitter: Node = get_node_or_null(noise_emitter_path)
@onready var _status_label: Label = get_node_or_null(status_label_path) as Label


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var button := find_child("Run Integrated Proof", true, false) as Button
	if button != null and not button.pressed.is_connected(run_integrated_proof):
		button.pressed.connect(run_integrated_proof)
	_set_status("Phase 17 level-builder proof ready. Run Integrated Proof to exercise non-Taco reusable systems.")


func run_integrated_proof() -> Dictionary:
	_prepare_runtime_state()
	if _controller == null:
		return _finish(false, "encounter_controller_missing", "Missing level-builder encounter controller.", {})
	_controller.call("reset_encounter")
	_controller.call("start_encounter")
	var context := _context()
	var steps: Array[Dictionary] = []
	steps.append(SocialStealthAdapterScript.set_cover_story("service_walkthrough", {"display_name": "Service walkthrough"}, context))
	steps.append(SocialStealthAdapterScript.grant_credential("temporary_vendor_badge", {"display_name": "Temporary vendor badge"}, context))
	steps.append(SocialStealthAdapterScript.complete_task("inspect_delivery_shelf", {"display_name": "Inspect delivery shelf"}, context))
	steps.append(SocialStealthAdapterScript.record_inspection("front_desk_check", true, {"reason": "Credential matched the walkthrough."}, context))
	steps.append(PaperTrailAdapterScript.record_trace("level_builder_invoice_touch", "level_builder_readiness", "evidence_touch", 2, true, "invoice_redirect", context, {"proof": "non_taco_skeleton"}))
	steps.append(PaperTrailAdapterScript.redirect_traces({"trace_id": "level_builder_invoice_touch", "severity_reduction": 1}, "service_walkthrough_cover", context))
	steps.append(ReactiveNpcBrainAdapterScript.record_signal(_make_signal(), context))
	steps.append(_controller.call("adjust_meter", "plausible_deniability", 3, {"route": "level_builder_readiness"}) as Dictionary)
	steps.append(_controller.call("adjust_meter", "evidence_strength", 2, {"route": "level_builder_readiness"}) as Dictionary)
	steps.append(_controller.call("adjust_meter", "bentley_confidence", 1, {"route": "level_builder_readiness"}) as Dictionary)
	steps.append(_controller.call("set_result_tag", "level_builder_route_ready", true) as Dictionary)
	steps.append(_controller.call("record_event", "level_builder_route_ready", {"route": "integrated_proof"}) as Dictionary)
	if _noise_emitter != null and _noise_emitter.has_method("emit_noise"):
		steps.append(_noise_emitter.call("emit_noise", null, "phase17_level_builder_proof") as Dictionary)
	var win_result: Dictionary = _controller.call("win_encounter", "level_builder_route_ready") as Dictionary
	steps.append(win_result)
	var summary := {
		"encounter": _controller.call("get_summary") if _controller.has_method("get_summary") else {},
		"paper_trail": PaperTrailAdapterScript.get_summary(mission_id),
		"social_stealth": SocialStealthAdapterScript.get_summary(mission_id),
		"reactive_npc": ReactiveNpcBrainAdapterScript.get_summary(mission_id),
		"steps": steps,
	}
	return _finish(bool(win_result.get("ok", false)), "phase17_level_builder_proof_complete", "Level-builder integrated proof complete.", summary)


func _prepare_runtime_state() -> void:
	GameState.current_mission_id = mission_id
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.begin_mission_performance(mission_id)
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission(mission_id)
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission(mission_id)
	ReactiveNpcBrainAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.reset_mission(mission_id)


func _context() -> Dictionary:
	return {"mission_id": mission_id, "source_id": "level_builder_readiness", "encounter_controller": _controller}


func _make_signal() -> Resource:
	var event: Resource = SocialSignalEventScript.new()
	event.set("signal_id", &"level_builder_walkthrough_seen")
	event.set("signal_type", SocialSignalEventScript.SIGNAL_SUSPICIOUS_ACTION_SEEN)
	event.set("mission_id", mission_id)
	event.set("source_id", &"level_builder_readiness")
	event.set("severity", 1)
	event.set("debug_summary", "NPC noticed the service walkthrough but did not escalate.")
	return event


func _finish(ok: bool, code: String, message: String, details: Dictionary) -> Dictionary:
	var result := {"ok": ok, "code": code, "message": message, "source_id": "phase17_level_builder_proof", "details": details}
	_set_status(_summary_line(result))
	return result


func _summary_line(result: Dictionary) -> String:
	var details: Dictionary = result.get("details", {})
	var encounter: Dictionary = details.get("encounter", {})
	var paper: Dictionary = details.get("paper_trail", {})
	var social: Dictionary = details.get("social_stealth", {})
	var reactive: Dictionary = details.get("reactive_npc", {})
	return "%s: %s | encounter=%s route=%s paper=%s social_tasks=%d reactive_signals=%d" % [
		"PASS" if bool(result.get("ok", false)) else "FAIL",
		String(result.get("message", "")),
		"won" if bool(encounter.get("success", false)) else "active",
		str((encounter.get("result_tags", {}) as Dictionary).keys()),
		String(paper.get("result_state", "clean")),
		int(social.get("task_count", 0)),
		int(reactive.get("signal_count", 0)),
	]


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
