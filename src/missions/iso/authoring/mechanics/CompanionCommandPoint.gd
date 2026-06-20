@tool
class_name CompanionCommandPoint
extends MechanicAreaBase

@export_group("Companion Command")
@export_enum("bark", "sniff", "fetch") var command_type: String = "bark"
@export var companion_group: StringName = &"bentley"
@export var companion_path: NodePath
@export var command_label: String = "Bentley command"

var last_command_result: Dictionary = {}


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["companion_command"] = command_type
	context["command_label"] = command_label
	context["companion_group"] = String(companion_group)
	context["command_result"] = last_command_result
	return context


func run_command(actor: Node = null, reason: String = "interact") -> Dictionary:
	current_actor = actor
	last_command_result = {}
	activation_started.emit(String(mechanic_id), actor)

	if not enabled:
		last_activation_result = _result(false, "mechanic_disabled", "Companion command point is disabled.", String(mechanic_id), {"reason": reason})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	if one_shot and used:
		last_activation_result = _result(true, "already_used", "Companion command point already used.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result

	if actor != null and not can_actor_use(actor):
		last_activation_result = _result(false, "actor_not_allowed", "Actor cannot use this companion command point.", String(mechanic_id), {"reason": reason, "actor": actor})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	if Engine.is_editor_hint():
		last_activation_result = _result(true, "editor_preview", "Companion command skipped in editor.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result

	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		effects_applied.emit(String(mechanic_id), last_effect_result)
		last_activation_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	var companion := _find_companion()
	if companion == null:
		last_command_result = _command_result(false, "companion_missing", "No Bentley companion found.")
		last_effect_result = apply_failure_effects(context)
		effects_applied.emit(String(mechanic_id), last_effect_result)
		last_activation_result = _result(false, "companion_missing", "No Bentley companion found.", String(mechanic_id), {"reason": reason, "command_result": last_command_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	last_command_result = _execute_companion_command(companion, actor, context)
	context["companion"] = companion
	context["command_result"] = last_command_result
	if not bool(last_command_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		effects_applied.emit(String(mechanic_id), last_effect_result)
		last_activation_result = _result(false, "companion_command_failed", String(last_command_result.get("message", "Companion command failed.")), String(mechanic_id), {"reason": reason, "command_result": last_command_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	last_effect_result = apply_success_effects(context)
	effects_applied.emit(String(mechanic_id), last_effect_result)
	if one_shot:
		mark_used()
	last_activation_result = _result(true, "companion_command_succeeded", String(last_command_result.get("message", "Companion command succeeded.")), String(mechanic_id), {"reason": reason, "command_result": last_command_result, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_activation_result)
	refresh_debug_label()
	return last_activation_result


func interact(actor: Node = null) -> bool:
	return bool(run_command(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(run_command(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(run_command(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(run_command(actor, "interact").get("ok", false))


func get_command_summary() -> Dictionary:
	return {
		"command_type": command_type,
		"command_label": command_label,
		"companion_group": String(companion_group),
		"last_command_result": last_command_result,
	}


func _find_companion() -> Node:
	if companion_path != NodePath():
		var explicit := get_node_or_null(companion_path)
		if explicit != null:
			return explicit
	var tree := get_tree()
	if tree == null:
		return null
	var group_name := String(companion_group).strip_edges()
	if group_name == "":
		return null
	return tree.get_first_node_in_group(group_name)


func _execute_companion_command(companion: Node, actor: Node, context: Dictionary) -> Dictionary:
	var normalized := command_type.strip_edges().to_lower()
	var method_name := "command_%s" % normalized
	if companion.has_method(method_name):
		return _normalize_command_call_result(companion.call(method_name, actor, context), normalized)
	match normalized:
		"bark":
			if companion.has_method("bark_stun"):
				return _command_result(bool(companion.call("bark_stun")), "bark_executed", "Bentley barked.")
		"sniff":
			if companion.has_method("sniff"):
				companion.call("sniff")
				return _command_result(true, "sniff_executed", "Bentley sniffed the trail.")
	return _command_result(false, "command_missing", "Companion does not support command '%s'." % normalized)


func _normalize_command_call_result(value: Variant, command_name: String) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is bool:
		return _command_result(bool(value), "%s_executed" % command_name, "Companion command %s executed." % command_name)
	return _command_result(true, "%s_executed" % command_name, "Companion command %s executed." % command_name)


func _command_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": String(mechanic_id),
		"details": details,
	}
