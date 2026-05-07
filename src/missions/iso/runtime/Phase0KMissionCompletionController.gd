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
	mission_completed = true
	exit_unlocked = true
	if has_node("/root/QuestManager") and QuestManager.has_method("complete_objective_id"):
		QuestManager.call("complete_objective_id", "return_to_louis", "Return to Louis at the exit.", mission_id)
	var result := {"success": true, "mission_id": mission_id, "phase0k_placeholder": true}
	if has_node("/root/GameState") and GameState.has_method("complete_mission"):
		result = GameState.call("complete_mission", mission_id)
	if has_node("/root/SceneManager") and SceneManager.has_method("show_mission_result"):
		SceneManager.call("show_mission_result", result)
	else:
		_show("Mission complete: return to hideout.")
	return result


func _seed_objectives() -> void:
	if has_node("/root/QuestManager"):
		var qm := get_node("/root/QuestManager")
		if qm.has_method("add_objective"):
			qm.call("add_objective", "open_garage_code_gate", "Open the garage code gate.", "active", mission_id)
			qm.call("add_objective", "recover_delivery_bag", "Recover the delivery bag.", "active", mission_id)
			qm.call("add_objective", "return_to_louis", "Return to Louis at the exit.", "locked", mission_id)


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)
	if has_node("/root/EventBus"):
		EventBus.objective_updated.emit(text)
