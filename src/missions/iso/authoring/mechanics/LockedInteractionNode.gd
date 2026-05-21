@tool
class_name LockedInteractionNode
extends MechanicAreaBase

@export_group("Lock")
@export_enum("door", "gate", "safe", "terminal", "scanner", "container", "generic")
var lock_kind: String = "door"
@export var unlocked_flag: StringName = &""
@export var starts_unlocked: bool = false
@export var open_on_success: bool = true
@export var stay_available_after_unlock: bool = false

@export_group("Targets")
@export var target_visual_path: NodePath
@export var target_collision_path: NodePath
@export var nodes_to_show_on_unlock: Array[NodePath] = []
@export var nodes_to_hide_on_unlock: Array[NodePath] = []
@export var collisions_to_enable_on_unlock: Array[NodePath] = []
@export var collisions_to_disable_on_unlock: Array[NodePath] = []

@export_group("Feedback")
@export var unlocked_prompt_text: String = "Unlocked"
@export var already_unlocked_prompt_text: String = "Already unlocked"
@export var locked_sound_key: StringName = &""
@export var unlocked_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var unlocked: bool = false
var last_unlock_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	unlocked = starts_unlocked
	if unlocked and open_on_success:
		_apply_starts_unlocked_targets()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["lock_kind"] = lock_kind
	context["unlocked_flag"] = String(unlocked_flag)
	context["unlocked"] = unlocked
	return context


func unlock(actor: Node = null, reason: String = "interact") -> Dictionary:
	if unlocked:
		if not stay_available_after_unlock:
			last_unlock_result = _unlock_result(
				true,
				"already_unlocked",
				already_unlocked_prompt_text if already_unlocked_prompt_text.strip_edges() != "" else "Already unlocked.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_unlock_result
		last_unlock_result = _unlock_result(
			true,
			"already_unlocked",
			already_unlocked_prompt_text if already_unlocked_prompt_text.strip_edges() != "" else "Already unlocked.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_unlock_result

	var activation_result: Dictionary = activate(actor, reason)
	last_unlock_result = _enrich_unlock_result(activation_result, actor, reason)

	if not bool(activation_result.get("ok", false)):
		return last_unlock_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		return last_unlock_result

	unlocked = true
	var context := build_context(actor)

	var flag_result: Dictionary = set_unlocked_flag(context)
	if open_on_success:
		var target_result: Dictionary = apply_unlock_targets()
		last_unlock_result = _merge_unlock_details(last_unlock_result, {
			"unlocked_flag_result": flag_result,
			"target_result": target_result,
		})
	else:
		last_unlock_result = _merge_unlock_details(last_unlock_result, {"unlocked_flag_result": flag_result})

	_emit_unlock_debug(activation_result)
	_notify_availability()
	refresh_debug_label()
	return last_unlock_result


func lock() -> void:
	unlocked = false
	_notify_availability()
	refresh_debug_label()


func is_unlocked() -> bool:
	return unlocked


func apply_unlock_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Unlock targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"collisions_enabled": [],
		"collisions_disabled": [],
		"warnings": [],
	}

	for node_path: NodePath in nodes_to_show_on_unlock:
		_apply_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_on_unlock:
		_apply_visibility(node_path, false, details, "hidden")
	for node_path: NodePath in collisions_to_enable_on_unlock:
		_apply_collision(node_path, true, details, "collisions_enabled")
	for node_path: NodePath in collisions_to_disable_on_unlock:
		_apply_collision(node_path, false, details, "collisions_disabled")

	if target_visual_path != NodePath():
		_apply_visibility(target_visual_path, false, details, "hidden", "target_visual_path")
	if target_collision_path != NodePath():
		_apply_collision(target_collision_path, false, details, "collisions_disabled", "target_collision_path")

	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty() or not (details.get("collisions_enabled", []) as Array).is_empty() or not (details.get("collisions_disabled", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"unlock_targets_applied" if warning_count == 0 else "unlock_targets_applied_with_warnings",
		"Unlock targets applied." if warning_count == 0 else "Unlock targets applied with warnings.",
		String(mechanic_id),
		details
	)


func set_unlocked_flag(context: Dictionary) -> Dictionary:
	if unlocked_flag == &"":
		return _result(true, "no_unlocked_flag", "No unlocked_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Unlocked flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(unlocked_flag), true, context)


func interact(actor: Node = null) -> bool:
	return bool(unlock(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(unlock(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(unlock(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(unlock(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if unlocked and not stay_available_after_unlock:
		return false
	if unlocked and stay_available_after_unlock:
		return true
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if unlocked and not stay_available_after_unlock:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if unlocked:
		if not stay_available_after_unlock:
			return ""
		var unlocked_text := unlocked_prompt_text.strip_edges()
		if unlocked_text != "":
			return unlocked_text
		return already_unlocked_prompt_text
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func _apply_starts_unlocked_targets() -> void:
	if Engine.is_editor_hint():
		return
	if not open_on_success:
		return
	apply_unlock_targets()


func _enrich_unlock_result(activation_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (activation_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["lock_kind"] = lock_kind
	details["unlocked_flag"] = String(unlocked_flag)
	details["unlocked"] = unlocked
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(activation_result.get("ok", false)),
		"code": String(activation_result.get("code", "")),
		"message": String(activation_result.get("message", "")),
		"source_id": String(activation_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _unlock_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["lock_kind"] = lock_kind
	merged["unlocked_flag"] = String(unlocked_flag)
	merged["unlocked"] = unlocked
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_unlock_details(base: Dictionary, extra: Dictionary) -> Dictionary:
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


func _emit_unlock_debug(activation_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	var status := "ok" if bool(activation_result.get("ok", false)) else "fail"
	event_bus.call(
		"debug",
		"LockedInteractionNode %s (%s) %s: %s" % [String(mechanic_id), lock_kind, status, String(activation_result.get("code", ""))]
	)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if unlocked:
		return "UNLOCKED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
