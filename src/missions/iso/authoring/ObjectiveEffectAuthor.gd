@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Objective")
@export var objective_id: StringName = &"d6_05_debug_objective"
@export var objective_action: StringName = &"set_debug_flag"
@export var debug_label: String = "Security event triggered objective flag."


func get_effect_type() -> String:
	return "objective"


func _apply_effect(event_id: String, _payload: Dictionary) -> Dictionary:
	var action := String(objective_action).strip_edges().to_lower()
	var oid := String(objective_id).strip_edges()
	if oid == "":
		return _reject("rejected_missing_objective_id")
	var mid := ""
	if _mission != null and _mission.get("mission_definition") != null:
		var def: Variant = _mission.get("mission_definition")
		if def != null and def.has_method("get"):
			mid = String(def.get("mission_id"))
	if mid == "":
		mid = String(GameState.current_mission_id)
	match action:
		"set_debug_flag":
			var flag_key := "d6_05_objective_flag:%s" % oid
			GameState.dialogue_flags[flag_key] = true
			if _mission != null:
				_mission.set_meta(flag_key, {"event": event_id, "label": debug_label, "msec": Time.get_ticks_msec()})
			if debug_label != "":
				QuestManager.set_objective("[DEBUG] %s" % debug_label, mid)
			return _success("debug_flag_set", oid, {"objective_id": oid, "event_id": event_id})
		"mark_seen", "mark_started":
			if QuestManager.has_method("add_objective"):
				QuestManager.add_objective(oid, debug_label if debug_label != "" else oid, "active", mid)
				return _success("objective_started", oid)
		"mark_completed":
			if QuestManager.has_method("complete_objective_id"):
				QuestManager.complete_objective_id(oid, debug_label, mid)
				return _success("objective_completed", oid)
		"mark_failed":
			if QuestManager.has_method("add_objective"):
				QuestManager.add_objective(oid, debug_label, "failed", mid)
				return _success("objective_failed", oid)
	return _reject("rejected_unknown_objective_action")
