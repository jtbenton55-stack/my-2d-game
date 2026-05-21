@tool
class_name RouteUnlockNode
extends MechanicAreaBase

@export_group("Route")
@export var route_id: StringName = &"route"
@export var route_flag: StringName = &""
@export var starts_unlocked: bool = false
@export var mark_unlocked_on_success: bool = true
@export var stay_available_after_unlock: bool = false

@export_group("Route Targets")
@export var nodes_to_show: Array[NodePath] = []
@export var nodes_to_hide: Array[NodePath] = []
@export var collisions_to_enable: Array[NodePath] = []
@export var collisions_to_disable: Array[NodePath] = []

@export_group("Route Feedback")
@export var unlocked_prompt_text: String = "Route already unlocked"
@export var unlocked_message: String = "Route unlocked."
@export var locked_route_message: String = "Route is not available yet."
@export var unlock_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var route_unlocked: bool = false
var last_route_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	route_unlocked = starts_unlocked
	if route_unlocked:
		_apply_starts_unlocked_targets()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["route_id"] = String(route_id)
	context["route_flag"] = String(route_flag)
	context["route_unlocked"] = route_unlocked
	return context


func unlock_route(actor: Node = null, reason: String = "interact") -> Dictionary:
	if route_unlocked:
		if not stay_available_after_unlock:
			last_route_result = _route_result(
				true,
				"already_unlocked",
				unlocked_prompt_text if unlocked_prompt_text.strip_edges() != "" else "Route already unlocked.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_route_result
		last_route_result = _route_result(
			true,
			"already_unlocked",
			unlocked_prompt_text if unlocked_prompt_text.strip_edges() != "" else "Route already unlocked.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_route_result

	var activation_result: Dictionary = activate(actor, reason)
	last_route_result = _enrich_route_result(activation_result, actor, reason)

	if not bool(activation_result.get("ok", false)):
		return last_route_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		return last_route_result

	if mark_unlocked_on_success:
		route_unlocked = true
	var context := build_context(actor)

	var flag_result: Dictionary = set_route_flag(context)
	var targets_result: Dictionary = apply_route_targets()
	last_route_result = _merge_route_details(last_route_result, {
		"route_flag_result": flag_result,
		"route_targets_result": targets_result,
		"activation_result": activation_result,
	})

	var message := unlocked_message if unlocked_message.strip_edges() != "" else "Route unlocked."
	last_route_result["ok"] = true
	last_route_result["code"] = "route_unlocked"
	last_route_result["message"] = message

	_emit_route_debug(activation_result)
	_notify_availability()
	refresh_debug_label()
	return last_route_result


func reset_route() -> void:
	route_unlocked = false
	_notify_availability()
	refresh_debug_label()


func is_route_unlocked() -> bool:
	return route_unlocked


func set_route_flag(context: Dictionary) -> Dictionary:
	if route_flag == &"":
		return _result(true, "no_route_flag", "No route_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Route flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(route_flag), true, context)


func apply_route_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Route targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"collisions_enabled": [],
		"collisions_disabled": [],
		"warnings": [],
	}

	for node_path: NodePath in nodes_to_show:
		_apply_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide:
		_apply_visibility(node_path, false, details, "hidden")
	for node_path: NodePath in collisions_to_enable:
		_apply_collision(node_path, true, details, "collisions_enabled")
	for node_path: NodePath in collisions_to_disable:
		_apply_collision(node_path, false, details, "collisions_disabled")

	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty() or not (details.get("collisions_enabled", []) as Array).is_empty() or not (details.get("collisions_disabled", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"route_targets_applied" if warning_count == 0 else "route_targets_applied_with_warnings",
		"Route targets applied." if warning_count == 0 else "Route targets applied with warnings.",
		String(mechanic_id),
		details
	)


func interact(actor: Node = null) -> bool:
	return bool(unlock_route(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(unlock_route(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(unlock_route(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(unlock_route(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if route_unlocked and not stay_available_after_unlock:
		return false
	if route_unlocked and stay_available_after_unlock:
		return true
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if route_unlocked and not stay_available_after_unlock:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if route_unlocked:
		if not stay_available_after_unlock:
			return ""
		return unlocked_prompt_text
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	var route_locked := locked_route_message.strip_edges()
	if route_locked != "":
		return route_locked
	return locked_prompt_text


func _apply_starts_unlocked_targets() -> void:
	if Engine.is_editor_hint():
		return
	apply_route_targets()


func _enrich_route_result(activation_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (activation_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["route_id"] = String(route_id)
	details["route_flag"] = String(route_flag)
	details["route_unlocked"] = route_unlocked
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(activation_result.get("ok", false)),
		"code": String(activation_result.get("code", "")),
		"message": String(activation_result.get("message", "")),
		"source_id": String(activation_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _route_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["route_id"] = String(route_id)
	merged["route_flag"] = String(route_flag)
	merged["route_unlocked"] = route_unlocked
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_route_details(base: Dictionary, extra: Dictionary) -> Dictionary:
	var details: Dictionary = (base.get("details", {}) as Dictionary).duplicate(true)
	for key: String in extra.keys():
		details[key] = extra[key]
	base["details"] = details
	return base


func _resolve_target(node_path: NodePath) -> Node:
	if node_path == NodePath():
		return null
	var local := get_node_or_null(node_path)
	if local != null:
		return local
	var scene := get_tree().current_scene if not Engine.is_editor_hint() else null
	if scene == null and is_inside_tree():
		scene = get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
	if scene != null:
		return scene.get_node_or_null(node_path)
	return null


func _apply_visibility(node_path: NodePath, visible: bool, details: Dictionary, bucket: String, label: String = "") -> void:
	var node := _resolve_target(node_path)
	var entry_label := label if label != "" else str(node_path)
	if node == null:
		(details.get("warnings", []) as Array).append("Missing visibility target: %s" % entry_label)
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = visible
		(details.get(bucket, []) as Array).append(entry_label)
		return
	if node is Node2D:
		(node as Node2D).visible = visible
		(details.get(bucket, []) as Array).append(entry_label)
		return
	(details.get("warnings", []) as Array).append("Unsupported visibility target: %s (%s)" % [entry_label, node.get_class()])


func _apply_collision(node_path: NodePath, enabled_state: bool, details: Dictionary, bucket: String, label: String = "") -> void:
	var node := _resolve_target(node_path)
	var entry_label := label if label != "" else str(node_path)
	if node == null:
		(details.get("warnings", []) as Array).append("Missing collision target: %s" % entry_label)
		return
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = not enabled_state
		(details.get(bucket, []) as Array).append(entry_label)
		return
	if node is CollisionPolygon2D:
		(node as CollisionPolygon2D).disabled = not enabled_state
		(details.get(bucket, []) as Array).append(entry_label)
		return
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = enabled_state
		area.monitorable = enabled_state
		(details.get(bucket, []) as Array).append(entry_label)
		return
	(details.get("warnings", []) as Array).append("Unsupported collision target: %s (%s)" % [entry_label, node.get_class()])


func _emit_route_debug(activation_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	var status := "ok" if bool(activation_result.get("ok", false)) else "fail"
	event_bus.call(
		"debug",
		"RouteUnlockNode %s (%s) %s: %s" % [String(mechanic_id), String(route_id), status, String(activation_result.get("code", ""))]
	)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if route_unlocked:
		return "UNLOCKED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
