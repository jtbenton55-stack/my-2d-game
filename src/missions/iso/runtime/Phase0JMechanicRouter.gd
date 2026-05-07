@tool
class_name Phase0JMechanicRouter
extends Node

@export var mission_state_adapter_path: NodePath = NodePath("../Phase0JMissionStateAdapter")
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")

var parity_by_category: Dictionary = {
	"ROUTE_IN": "INSPECT_ONLY_DEFERRED",
	"ROUTE_RET": "INSPECT_ONLY_DEFERRED",
	"ROUTE_DEST": "INSPECT_ONLY_DEFERRED",
	"VENT_IN": "INSPECT_ONLY_DEFERRED",
	"VENT_OUT": "INSPECT_ONLY_DEFERRED",
	"BENTLEY_SWITCH": "INSPECT_ONLY_DEFERRED",
	"SWITCH": "INSPECT_ONLY_DEFERRED",
	"CONTROL": "INSPECT_ONLY_DEFERRED",
	"DOOR": "INSPECT_ONLY_DEFERRED",
	"EXIT": "INSPECT_ONLY_DEFERRED",
	"GATE": "SEPARATE_CODE_UI_IMPLEMENTED",
	"GUARD": "SEPARATE_PASS_REQUIRED",
	"PATROL": "SEPARATE_PASS_REQUIRED",
	"CAM": "SEPARATE_PASS_REQUIRED",
	"FLOOD": "SEPARATE_PASS_REQUIRED",
	"ALARM": "SEPARATE_PASS_REQUIRED",
}


func _ready() -> void:
	set_meta("generated_by", "Phase0J-C4")
	set_meta("scene_local_only", true)


func route_marker(marker_id: String, category: String, payload: Dictionary = {}) -> Dictionary:
	var status := String(parity_by_category.get(category, "NO_OLD_MECHANIC_FOUND"))
	var warning := "%s inspected - %s" % [marker_id, _human_status(status, category)]
	var state := get_node_or_null(mission_state_adapter_path)
	if _is_objective_category(category) and state != null and state.has_method("mark_objective"):
		state.call("mark_objective", marker_id, "inspected")
		warning = "Objective updated: %s" % marker_id
	if state != null and state.has_method("inspect_marker"):
		var enriched := payload.duplicate(true)
		enriched["deferred_mechanic"] = _human_status(status, category)
		enriched["warning"] = status
		state.call("inspect_marker", marker_id, category, enriched)
	_show(warning)
	return {
		"success": true,
		"parity_status": status,
		"message": warning,
		"real_mechanic_ran": status == "PARITY_IMPLEMENTED",
	}


func get_parity_status(category: String) -> String:
	return String(parity_by_category.get(category, "NO_OLD_MECHANIC_FOUND"))


func _human_status(status: String, category: String) -> String:
	match status:
		"SEPARATE_CODE_UI_IMPLEMENTED":
			return "code gate handled by Phase0JCodeInputUI."
		"SEPARATE_PASS_REQUIRED":
			return "%s mechanic deferred to combat/detection pass." % category
		"INSPECT_ONLY_DEFERRED":
			return "%s old-map wrapper is unsafe for C4; marker remains inspectable." % category
		_:
			return "No safe old mechanic found for %s." % category


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)


func _is_objective_category(category: String) -> bool:
	var cat := category.to_upper()
	return cat == "OBJ" or cat.begins_with("OBJECTIVE")
