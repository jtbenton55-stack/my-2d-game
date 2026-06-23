@tool
class_name SideObjectiveNode
extends MechanicAreaBase

enum ObjectiveAction {
	ACTIVATE,
	COMPLETE,
	FAIL,
}

@export_group("Side Objective")
@export var objective_id: StringName = &""
@export var objective_text: String = ""
@export var objective_action: ObjectiveAction = ObjectiveAction.COMPLETE
@export var objective_flag: StringName = &""
@export var starts_handled: bool = false
@export var mark_handled_on_success: bool = true
@export var stay_available_after_handled: bool = false

@export_group("Objective Targets")
@export var nodes_to_show_on_handle: Array[NodePath] = []
@export var nodes_to_hide_on_handle: Array[NodePath] = []

@export_group("Objective Feedback")
@export var handled_prompt_text: String = "Objective already handled"
@export var activated_message: String = "Objective activated."
@export var completed_message: String = "Objective completed."
@export var failed_message: String = "Objective failed."
@export var missing_objective_message: String = "Objective is not available."
@export var objective_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var handled: bool = false
var last_objective_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	handled = starts_handled


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["objective_id"] = String(objective_id)
	context["objective_text"] = objective_text
	context["objective_action"] = objective_action
	context["objective_flag"] = String(objective_flag)
	context["handled"] = handled
	return context


func handle_objective(actor: Node = null, reason: String = "interact") -> Dictionary:
	if handled:
		if not stay_available_after_handled:
			last_objective_result = _objective_result(
				true,
				"already_handled",
				handled_prompt_text if handled_prompt_text.strip_edges() != "" else "Objective already handled.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_objective_result
		last_objective_result = _objective_result(
			true,
			"already_handled",
			handled_prompt_text if handled_prompt_text.strip_edges() != "" else "Objective already handled.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_objective_result

	var activation_result: Dictionary = activate(actor, reason)
	last_objective_result = _enrich_objective_result(activation_result, actor, reason)

	if not bool(activation_result.get("ok", false)):
		return last_objective_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		return last_objective_result

	var context := build_context(actor)
	var objective_status: Dictionary = get_objective_status(context)
	var action_result: Dictionary = apply_objective_action(context)
	last_objective_result = _merge_objective_details(last_objective_result, {
		"objective_status": objective_status,
		"objective_action_result": action_result,
		"activation_result": activation_result,
	})

	if not bool(action_result.get("ok", false)):
		last_objective_result["ok"] = false
		last_objective_result["code"] = String(action_result.get("code", "objective_action_failed"))
		last_objective_result["message"] = String(action_result.get("message", missing_objective_message))
		return last_objective_result

	if mark_handled_on_success:
		handled = true
	var flag_result: Dictionary = set_objective_flag(context)
	var targets_result: Dictionary = apply_handled_targets()
	last_objective_result = _merge_objective_details(last_objective_result, {
		"objective_flag_result": flag_result,
		"objective_targets_result": targets_result,
	})

	var message := _message_for_action()
	last_objective_result["ok"] = true
	last_objective_result["code"] = "side_objective_handled"
	last_objective_result["message"] = message

	_emit_objective_debug(activation_result, action_result)
	_notify_availability()
	refresh_debug_label()
	return last_objective_result


func reset_objective_node() -> void:
	handled = false
	_notify_availability()
	refresh_debug_label()


func is_handled() -> bool:
	return handled


func apply_objective_action(context: Dictionary) -> Dictionary:
	var oid := String(objective_id).strip_edges()
	if oid == "":
		return _result(
			false,
			"objective_id_missing",
			missing_objective_message if missing_objective_message.strip_edges() != "" else "Objective id is required.",
			String(mechanic_id),
			{"objective_id": oid}
		)
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Objective action skipped in editor.", String(mechanic_id))

	var mid := _mission_id_from_context(context)
	var text := objective_text
	var action_result: Dictionary
	match objective_action:
		ObjectiveAction.ACTIVATE:
			action_result = ObjectiveStepController.activate_objective(oid, text, mid, context)
		ObjectiveAction.COMPLETE:
			action_result = ObjectiveStepController.complete_objective(oid, text, mid, context)
		ObjectiveAction.FAIL:
			action_result = ObjectiveStepController.fail_objective(oid, text, mid, context)
		_:
			action_result = _result(false, "unknown_objective_action", "Unknown objective action.", String(mechanic_id))

	var details: Dictionary = (action_result.get("details", {}) as Dictionary).duplicate(true)
	details["objective_id"] = oid
	details["mission_id"] = mid
	details["objective_action"] = objective_action
	return {
		"ok": bool(action_result.get("ok", false)),
		"code": String(action_result.get("code", "")),
		"message": String(action_result.get("message", "")),
		"source_id": String(action_result.get("source_id", oid)),
		"details": details,
	}


func set_objective_flag(context: Dictionary) -> Dictionary:
	if objective_flag == &"":
		return _result(true, "no_objective_flag", "No objective_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Objective flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(objective_flag), true, context)


func get_objective_status(context: Dictionary = {}) -> Dictionary:
	var oid := String(objective_id).strip_edges()
	var mid := _mission_id_from_context(context if not context.is_empty() else build_context(null))
	if oid == "" or mid == "":
		return {
			"ok": false,
			"objective_id": oid,
			"mission_id": mid,
			"active": false,
			"completed": false,
		}
	var record := ObjectiveStepController.get_objective_record(oid, mid, context)
	return {
		"ok": true,
		"objective_id": oid,
		"mission_id": mid,
		"active": bool(record.get("active", false)),
		"completed": bool(record.get("completed", false)),
		"status": String(record.get("status", "")),
		"record": record,
	}


func apply_handled_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Objective targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"warnings": [],
	}
	for node_path: NodePath in nodes_to_show_on_handle:
		_apply_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_on_handle:
		_apply_visibility(node_path, false, details, "hidden")

	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"objective_targets_applied" if warning_count == 0 else "objective_targets_applied_with_warnings",
		"Objective targets applied." if warning_count == 0 else "Objective targets applied with warnings.",
		String(mechanic_id),
		details
	)


func interact(actor: Node = null) -> bool:
	return bool(handle_objective(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(handle_objective(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(handle_objective(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(handle_objective(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if handled and not stay_available_after_handled:
		return false
	if handled and stay_available_after_handled:
		return true
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if handled and not stay_available_after_handled:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if handled:
		if not stay_available_after_handled:
			return ""
		return handled_prompt_text
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func _apply_visibility(node_path: NodePath, visible_value: bool, details: Dictionary, bucket: String) -> void:
	if node_path == NodePath():
		return
	var node := get_node_or_null(node_path)
	if node == null or not (node is CanvasItem):
		(details.get("warnings", []) as Array).append("Missing CanvasItem target: %s" % [str(node_path)])
		return
	(node as CanvasItem).visible = visible_value
	(details.get(bucket, []) as Array).append(str(node_path))


func _mission_id_from_context(context: Dictionary) -> String:
	var override := mission_id_override.strip_edges()
	if override != "":
		return override
	return MissionFactBridge.resolve_mission_id(context)


func _message_for_action() -> String:
	match objective_action:
		ObjectiveAction.ACTIVATE:
			return activated_message if activated_message.strip_edges() != "" else "Objective activated."
		ObjectiveAction.COMPLETE:
			return completed_message if completed_message.strip_edges() != "" else "Objective completed."
		ObjectiveAction.FAIL:
			return failed_message if failed_message.strip_edges() != "" else "Objective failed."
		_:
			return "Objective handled."


func _enrich_objective_result(activation_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (activation_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["objective_id"] = String(objective_id)
	details["objective_text"] = objective_text
	details["objective_action"] = objective_action
	details["objective_flag"] = String(objective_flag)
	details["handled"] = handled
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(activation_result.get("ok", false)),
		"code": String(activation_result.get("code", "")),
		"message": String(activation_result.get("message", "")),
		"source_id": String(activation_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _objective_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["objective_id"] = String(objective_id)
	merged["objective_action"] = objective_action
	merged["objective_flag"] = String(objective_flag)
	merged["handled"] = handled
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_objective_details(base: Dictionary, extra: Dictionary) -> Dictionary:
	var details: Dictionary = (base.get("details", {}) as Dictionary).duplicate(true)
	for key: String in extra.keys():
		details[key] = extra[key]
	base["details"] = details
	return base


func _emit_objective_debug(activation_result: Dictionary, action_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	event_bus.call(
		"debug",
		"SideObjectiveNode %s (%s/%s) activation=%s action=%s" % [
			String(mechanic_id),
			String(objective_id),
			ObjectiveAction.keys()[objective_action],
			String(activation_result.get("code", "")),
			String(action_result.get("code", "")),
		]
	)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if handled:
		return "HANDLED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
