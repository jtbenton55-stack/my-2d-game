class_name MissionCompletionBridge
extends RefCounted


static func request_complete(mission_id: String, context: Dictionary = {}) -> Dictionary:
	var resolved_mission_id := _resolve_requested_mission_id(mission_id, context)
	if resolved_mission_id == "":
		return _result(false, "mission_id_missing", "Cannot complete mission without a mission id.")
	var controller := find_completion_controller(context)
	if controller != null and controller.has_method("complete_mission_and_exit"):
		var controller_result: Variant = controller.call("complete_mission_and_exit")
		var normalized := _normalize_controller_result(controller_result, resolved_mission_id)
		if bool(normalized.get("ok", false)):
			return normalized
		return normalized
	var game_state := _autoload("GameState")
	if game_state == null or not game_state.has_method("complete_mission"):
		return _result(false, "game_state_api_missing", "GameState.complete_mission is missing.", resolved_mission_id)
	var raw_result: Variant = game_state.call("complete_mission", resolved_mission_id)
	var result: Dictionary = {}
	if raw_result is Dictionary:
		result = raw_result
	return _result(true, "mission_completed", "Mission completed via GameState: %s." % resolved_mission_id, resolved_mission_id, {"mission_id": resolved_mission_id, "result": result})


static func request_fail(mission_id: String, reason: String = "The job went sideways.", context: Dictionary = {}) -> Dictionary:
	var resolved_mission_id := _resolve_requested_mission_id(mission_id, context)
	if resolved_mission_id == "":
		return _result(false, "mission_id_missing", "Cannot fail mission without a mission id.")
	var game_state := _autoload("GameState")
	if game_state == null or not game_state.has_method("fail_mission"):
		return _result(false, "game_state_api_missing", "GameState.fail_mission is missing.", resolved_mission_id)
	var resolved_reason := reason.strip_edges()
	if resolved_reason == "":
		resolved_reason = "The job went sideways."
	var raw_result: Variant = game_state.call("fail_mission", resolved_mission_id, resolved_reason)
	var result: Dictionary = {}
	if raw_result is Dictionary:
		result = raw_result
	return _result(true, "mission_failed", "Mission failed via GameState: %s." % resolved_mission_id, resolved_mission_id, {"mission_id": resolved_mission_id, "reason": resolved_reason, "result": result})


static func find_completion_controller(context: Dictionary = {}) -> Node:
	var explicit: Variant = context.get("completion_controller", null)
	if explicit is Node:
		return explicit as Node
	var mechanic: Variant = context.get("mechanic", null)
	if mechanic is Node:
		var from_mechanic := _find_controller_under(mechanic as Node)
		if from_mechanic != null:
			return from_mechanic
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var scene := (main_loop as SceneTree).current_scene
		if scene != null:
			return _find_controller_under(scene)
	return null


static func _resolve_requested_mission_id(mission_id: String, context: Dictionary) -> String:
	var explicit := mission_id.strip_edges()
	if explicit != "":
		return explicit
	var context_mission := String(context.get("mission_id", "")).strip_edges()
	if context_mission != "":
		return context_mission
	return MissionFactBridge.resolve_mission_id(context)


static func _find_controller_under(root: Node) -> Node:
	if root == null:
		return null
	if root.name == &"Phase0KMissionCompletionController" or root.name == &"MissionCompletionController":
		return root
	var phase0k := root.find_child("Phase0KMissionCompletionController", true, false)
	if phase0k != null:
		return phase0k
	return root.find_child("MissionCompletionController", true, false)


static func _normalize_controller_result(controller_result: Variant, mission_id: String) -> Dictionary:
	if controller_result is Dictionary:
		var result := (controller_result as Dictionary).duplicate(true)
		var ok := bool(result.get("success", false))
		return _result(ok, "mission_completed" if ok else "completion_controller_rejected", String(result.get("message", "Completion controller handled request.")), mission_id, {"mission_id": mission_id, "result": result})
	var ok := bool(controller_result)
	return _result(ok, "mission_completed" if ok else "completion_controller_rejected", "Completion controller handled request.", mission_id, {"mission_id": mission_id, "result": controller_result})


static func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(name)


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
