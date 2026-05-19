@tool
class_name Phase0KMissionCompletionController
extends Node

@export var mission_id := "taco_bell_drop"
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")

var delivery_bag_collected := false
var code_gate_unlocked := false
var required_objectives_complete := false
var exit_unlocked := false
var mission_completed := false
var completed_objectives: Dictionary = {}


func _ready() -> void:
	set_meta("generated_by", "Phase0K")
	set_meta("scene_local_only", true)
	_seed_objectives()


func set_delivery_bag_collected(value: bool) -> void:
	delivery_bag_collected = value
	if value:
		set_objective_complete("recover_delivery_bag")
		_show("Delivery bag recovered.")


func set_code_gate_unlocked(value: bool) -> void:
	code_gate_unlocked = value
	if value:
		set_objective_complete("open_garage_code_gate")


func set_objective_complete(objective_id: String) -> void:
	completed_objectives[objective_id] = true
	if objective_id == "recover_delivery_bag":
		required_objectives_complete = true


func are_exit_requirements_met() -> bool:
	return delivery_bag_collected and code_gate_unlocked


func get_missing_requirements() -> Array[String]:
	var missing: Array[String] = []
	if not delivery_bag_collected:
		missing.append("recover the delivery bag")
	if not code_gate_unlocked:
		missing.append("open the garage code gate")
	return missing


func unlock_exit() -> void:
	exit_unlocked = true
	_show("Louis exit unlocked.")


func is_exit_unlocked() -> bool:
	return exit_unlocked


func complete_mission_and_exit() -> Dictionary:
	if mission_completed:
		return {"success": true, "already_done": true, "mission_id": mission_id}
	if not are_exit_requirements_met():
		var missing_reqs := get_missing_requirements()
		return {"success": false, "message": "Exit requirements not met", "missing": missing_reqs}
	exit_unlocked = true
	var quest_manager := get_node_or_null("/root/QuestManager")
	if quest_manager != null and quest_manager.has_method("complete_objective_id"):
		quest_manager.call("complete_objective_id", "return_to_louis", "Return to Louis at the exit.", mission_id)
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("request_exit_completion"):
		var ok := bool(mission.call("request_exit_completion"))
		if ok:
			mission_completed = true
			return {"success": true, "mission_id": mission_id, "via": "request_exit_completion"}
	# Phase0K Louis exit: Taco-only fallback when formal IsoMission objectives are not all flagged.
	if mission != null and mission.has_method("apply_phase0k_louis_exit_completion"):
		var fallback: Dictionary = mission.call("apply_phase0k_louis_exit_completion")
		if bool(fallback.get("success", false)):
			mission_completed = true
			return fallback
		if String(fallback.get("via", "")) == "fallback_denied":
			_show("Louis: Exit fallback is not enabled for this mission.")
			return fallback
	_show("Louis: Mission exit blocked - finish required objectives first.")
	return {"success": false, "mission_id": mission_id, "via": "request_exit_completion_rejected"}


func _seed_objectives() -> void:
	var qm := get_node_or_null("/root/QuestManager")
	if qm != null and qm.has_method("add_objective"):
		qm.call("add_objective", "open_garage_code_gate", "Open the garage code gate.", "active", mission_id)
		qm.call("add_objective", "recover_delivery_bag", "Recover the delivery bag.", "active", mission_id)
		qm.call("add_objective", "return_to_louis", "Return to Louis at the exit.", "locked", mission_id)


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.objective_updated.emit(text)
