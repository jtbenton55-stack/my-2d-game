class_name EncounterResultAdapter
extends RefCounted


static func annotate_mission_result(result: Dictionary) -> Dictionary:
	var out := result.duplicate(true)
	var controller := _find_controller()
	if controller == null or not controller.has_method("get_summary"):
		return out
	var summary: Dictionary = controller.call("get_summary")
	var result_mission := String(out.get("mission_id", ""))
	var encounter_mission := String(summary.get("mission_id", ""))
	if result_mission != "" and encounter_mission != "" and result_mission != encounter_mission:
		return out
	out["encounter"] = summary
	out["encounter_state"] = _result_state(summary)
	return out


static func get_active_summary() -> Dictionary:
	var controller := _find_controller()
	if controller != null and controller.has_method("get_summary"):
		return controller.call("get_summary")
	return {}


static func _find_controller() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	var tree := main_loop as SceneTree
	var grouped := tree.get_first_node_in_group("mission_encounter_controller")
	if grouped != null:
		return grouped
	if tree.current_scene != null:
		return tree.current_scene.find_child("EncounterController", true, false)
	return null


static func _result_state(summary: Dictionary) -> String:
	if bool(summary.get("success", false)):
		return "won"
	if bool(summary.get("resolved", false)):
		return "failed"
	if bool(summary.get("active", false)):
		return "active"
	return "unstarted"
