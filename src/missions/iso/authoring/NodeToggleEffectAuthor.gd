@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Node Target")
@export var target_node_path: NodePath
@export var toggle_action: StringName = &"show"


func get_effect_type() -> String:
	return "node_toggle"


func _apply_effect(_event_id: String, _payload: Dictionary) -> Dictionary:
	if target_node_path.is_empty():
		return _reject("rejected_missing_target_path")
	var target := _resolve_target()
	if target == null:
		return _reject("rejected_missing_target_node")
	var action := String(toggle_action).strip_edges().to_lower()
	match action:
		"show":
			if target is CanvasItem:
				(target as CanvasItem).visible = true
			target.set_process(true)
			target.set_physics_process(true)
			return _success("shown", action, {"target_path": str(target.get_path())})
		"hide":
			if target is CanvasItem:
				(target as CanvasItem).visible = false
			return _success("hidden", action, {"target_path": str(target.get_path())})
		"toggle_visible":
			if target is CanvasItem:
				(target as CanvasItem).visible = not (target as CanvasItem).visible
				return _success("toggled_visible", action, {"visible": (target as CanvasItem).visible})
			return _reject("rejected_not_canvas_item")
		"enable_process":
			target.set_process(true)
			return _success("process_enabled", action)
		"disable_process":
			target.set_process(false)
			return _success("process_disabled", action)
		"activate":
			if target is Node:
				(target as Node).process_mode = Node.PROCESS_MODE_INHERIT
			return _success("activated", action)
		"deactivate":
			if target is Node:
				(target as Node).process_mode = Node.PROCESS_MODE_DISABLED
			return _success("deactivated", action)
	return _reject("rejected_unknown_toggle_action")


func _resolve_target() -> Node:
	if target_node_path.is_empty():
		return null
	var local := get_node_or_null(target_node_path)
	if local != null:
		return local
	if _mission != null:
		return _mission.get_node_or_null(target_node_path)
	return null
