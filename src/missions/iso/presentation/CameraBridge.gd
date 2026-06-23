class_name CameraBridge
extends Node

@export var camera_path: NodePath = NodePath("../Camera2D")
@export var phantom_adapter_path: NodePath
@export var named_target_paths: Dictionary = {}
@export var default_blend_seconds: float = 0.2

var _camera: Camera2D = null
var _restore_state: Dictionary = {}
var _active_tween: Tween = null


func _ready() -> void:
	_camera = _resolve_camera()


func focus_named_target(target_name: String, blend_seconds: float = -1.0, context: Dictionary = {}) -> Dictionary:
	var target := get_named_target(target_name, context)
	if target == null:
		return _result(false, "camera_target_missing", "Camera target is missing: %s." % target_name, target_name)
	return focus_node(target, blend_seconds, context)


func focus_node(target: Node, blend_seconds: float = -1.0, _context: Dictionary = {}) -> Dictionary:
	if target == null or not (target is Node2D):
		return _result(false, "camera_target_missing", "Camera target must be a Node2D.")
	var phantom_result := _try_phantom_focus(target, blend_seconds)
	if bool(phantom_result.get("handled", false)):
		return phantom_result.get("result", {}) as Dictionary
	var camera := _camera_or_resolve()
	if camera == null:
		return _result(false, "camera_missing", "Camera2D is missing.")
	_capture_restore_state(camera)
	var duration := _blend_duration(blend_seconds)
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if duration > 0.0 and is_inside_tree():
		_active_tween = create_tween()
		_active_tween.tween_property(camera, "global_position", (target as Node2D).global_position, duration)
	else:
		camera.global_position = (target as Node2D).global_position
	return _result(true, "camera_focused", "Camera focused target.", str(target.get_path()), {"position": (target as Node2D).global_position, "blend_seconds": duration, "fallback": "built_in"})


func restore_camera(blend_seconds: float = -1.0) -> Dictionary:
	var phantom_result := _try_phantom_restore(blend_seconds)
	if bool(phantom_result.get("handled", false)):
		return phantom_result.get("result", {}) as Dictionary
	var camera := _camera_or_resolve()
	if camera == null:
		return _result(false, "camera_missing", "Camera2D is missing.")
	if _restore_state.is_empty():
		return _result(true, "camera_restore_skipped", "No camera restore state captured.")
	var duration := _blend_duration(blend_seconds)
	var position: Vector2 = _restore_state.get("global_position", camera.global_position) as Vector2
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if duration > 0.0 and is_inside_tree():
		_active_tween = create_tween()
		_active_tween.tween_property(camera, "global_position", position, duration)
	else:
		camera.global_position = position
	camera.zoom = _restore_state.get("zoom", camera.zoom) as Vector2
	camera.offset = _restore_state.get("offset", camera.offset) as Vector2
	return _result(true, "camera_restored", "Camera restore requested.", "", {"position": position, "blend_seconds": duration})


func shake(intensity: float = 1.0, duration: float = 0.1) -> Dictionary:
	var event_bus := _autoload("EventBus")
	if event_bus != null and event_bus.has_signal("screen_shake"):
		event_bus.emit_signal("screen_shake", intensity, duration)
		return _result(true, "camera_shake_emitted", "Camera shake emitted.", "", {"intensity": intensity, "duration": duration})
	return _result(false, "event_bus_missing", "EventBus screen_shake signal is missing.")


func get_named_target(target_name: String, context: Dictionary = {}) -> Node:
	var name := target_name.strip_edges()
	if name == "":
		return null
	var raw_path: Variant = named_target_paths.get(name, null)
	if raw_path != null:
		var from_path := _node_from_path(raw_path)
		if from_path != null:
			return from_path
	var root: Node = context.get("mechanic", null) as Node
	if root == null:
		root = get_tree().current_scene if is_inside_tree() else null
	if root != null:
		var found := root.find_child(name, true, false)
		if found != null:
			return found
	if is_inside_tree():
		return get_tree().get_first_node_in_group(name)
	return null


func _capture_restore_state(camera: Camera2D) -> void:
	if not _restore_state.is_empty():
		return
	_restore_state = {
		"global_position": camera.global_position,
		"zoom": camera.zoom,
		"offset": camera.offset,
	}


func _resolve_camera() -> Camera2D:
	var by_path := get_node_or_null(camera_path) as Camera2D
	if by_path != null:
		return by_path
	if is_inside_tree() and get_tree().current_scene != null:
		var found := get_tree().current_scene.find_child("Camera2D", true, false) as Camera2D
		if found != null:
			return found
	if is_inside_tree():
		return get_viewport().get_camera_2d()
	return null


func _camera_or_resolve() -> Camera2D:
	if _camera == null:
		_camera = _resolve_camera()
	return _camera


func _node_from_path(raw_path: Variant) -> Node:
	var path := NodePath(str(raw_path))
	if raw_path is NodePath:
		path = raw_path as NodePath
	if path == NodePath():
		return null
	var node := get_node_or_null(path)
	if node != null:
		return node
	if is_inside_tree() and get_tree().current_scene != null:
		return get_tree().current_scene.get_node_or_null(path)
	return null


func _try_phantom_focus(target: Node, blend_seconds: float) -> Dictionary:
	var adapter := get_node_or_null(phantom_adapter_path)
	if adapter == null:
		return {"handled": false}
	for method in ["focus_node", "focus_target", "set_follow_target"]:
		if adapter.has_method(method):
			adapter.call(method, target, _blend_duration(blend_seconds))
			return {"handled": true, "result": _result(true, "phantom_camera_focused", "PhantomCamera adapter focused target.", str(target.get_path()), {"adapter": str(adapter.get_path())})}
	return {"handled": false}


func _try_phantom_restore(blend_seconds: float) -> Dictionary:
	var adapter := get_node_or_null(phantom_adapter_path)
	if adapter == null:
		return {"handled": false}
	for method in ["restore_camera", "restore", "clear_follow_target"]:
		if adapter.has_method(method):
			adapter.call(method, _blend_duration(blend_seconds))
			return {"handled": true, "result": _result(true, "phantom_camera_restored", "PhantomCamera adapter restore requested.", "", {"adapter": str(adapter.get_path())})}
	return {"handled": false}


func _blend_duration(value: float) -> float:
	return default_blend_seconds if value < 0.0 else value


func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null(name)
	return null


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
