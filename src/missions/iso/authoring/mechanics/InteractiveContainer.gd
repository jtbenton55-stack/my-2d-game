@tool
class_name InteractiveContainer
extends SearchZone

@export_group("Container")
@export_enum("drawer", "locker", "fridge", "filing_cabinet", "crate", "trash", "safe", "generic")
var container_kind: String = "drawer"
@export var opened_flag: StringName = &""
@export var starts_open: bool = false
@export var close_after_search: bool = false
@export var mark_open_on_success: bool = true

@export_group("Container Targets")
@export var closed_visual_path: NodePath
@export var open_visual_path: NodePath
@export var nodes_to_show_when_open: Array[NodePath] = []
@export var nodes_to_hide_when_open: Array[NodePath] = []
@export var nodes_to_show_when_closed: Array[NodePath] = []
@export var nodes_to_hide_when_closed: Array[NodePath] = []

@export_group("Container Feedback")
@export var open_prompt_text: String = "Open"
@export var close_prompt_text: String = "Close"
@export var already_open_prompt_text: String = "Already open"
@export var opened_message: String = "Opened container."
@export var closed_message: String = "Closed container."
@export var open_sound_key: StringName = &""
@export var close_sound_key: StringName = &""

var opened: bool = false
var last_container_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	opened = starts_open
	if opened:
		apply_container_open_targets()
	else:
		apply_container_closed_targets()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["container_kind"] = container_kind
	context["opened_flag"] = String(opened_flag)
	context["opened"] = opened
	context["close_after_search"] = close_after_search
	return context


func open_container(actor: Node = null, reason: String = "interact") -> Dictionary:
	if opened and searched and not stay_available_after_search:
		var prompt := already_open_prompt_text if already_open_prompt_text.strip_edges() != "" else searched_prompt_text
		last_container_result = _container_result(
			true,
			"already_searched",
			prompt if prompt.strip_edges() != "" else "Already searched.",
			{"reason": reason, "reapplied_effects": false, "opened": opened, "searched": searched}
		)
		return last_container_result

	var search_result: Dictionary = search(actor, reason)
	last_container_result = _enrich_container_result(search_result, actor, reason)

	if not bool(search_result.get("ok", false)):
		return last_container_result
	if String(search_result.get("code", "")) != "activation_succeeded" and String(search_result.get("code", "")) != "already_searched":
		return last_container_result

	var context := build_context(actor)
	var open_targets_result: Dictionary = {}
	var opened_flag_result: Dictionary = {}
	var closed_targets_result: Dictionary = {}

	if mark_open_on_success and not close_after_search:
		opened = true

	if opened_flag != &"" and not Engine.is_editor_hint():
		opened_flag_result = set_opened_flag(context)

	if not close_after_search:
		open_targets_result = apply_container_open_targets()
	else:
		closed_targets_result = close_container(actor, "close_after_search")

	var message := opened_message if opened_message.strip_edges() != "" else "Opened container."
	last_container_result = _container_result(
		true,
		"container_opened" if not close_after_search else "container_searched_and_closed",
		message,
		{
			"reason": reason,
			"search_result": search_result,
			"opened_flag_result": opened_flag_result,
			"open_targets_result": open_targets_result,
			"closed_targets_result": closed_targets_result,
			"opened": opened,
			"searched": searched,
			"close_after_search": close_after_search,
		}
	)
	_notify_availability()
	refresh_debug_label()
	return last_container_result


func close_container(actor: Node = null, reason: String = "script") -> Dictionary:
	opened = false
	var closed_targets_result: Dictionary = apply_container_closed_targets()
	var message := closed_message if closed_message.strip_edges() != "" else "Closed container."
	last_container_result = _container_result(
		true,
		"container_closed",
		message,
		{
			"reason": reason,
			"closed_targets_result": closed_targets_result,
			"opened": opened,
			"searched": searched,
		}
	)
	_notify_availability()
	refresh_debug_label()
	return last_container_result


func toggle_container(actor: Node = null, reason: String = "interact") -> Dictionary:
	if opened:
		return close_container(actor, reason)
	return open_container(actor, reason)


func is_open() -> bool:
	return opened


func set_opened_flag(context: Dictionary) -> Dictionary:
	if opened_flag == &"":
		return _result(true, "no_opened_flag", "No opened_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Opened flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(opened_flag), true, context)


func apply_container_open_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Container open targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"warnings": [],
	}

	if open_visual_path != NodePath():
		_apply_container_visibility(open_visual_path, true, details, "shown", "open_visual_path")
	if closed_visual_path != NodePath():
		_apply_container_visibility(closed_visual_path, false, details, "hidden", "closed_visual_path")
	for node_path: NodePath in nodes_to_show_when_open:
		_apply_container_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_when_open:
		_apply_container_visibility(node_path, false, details, "hidden")

	return _container_targets_result(details)


func apply_container_closed_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Container closed targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"warnings": [],
	}

	if closed_visual_path != NodePath():
		_apply_container_visibility(closed_visual_path, true, details, "shown", "closed_visual_path")
	if open_visual_path != NodePath():
		_apply_container_visibility(open_visual_path, false, details, "hidden", "open_visual_path")
	for node_path: NodePath in nodes_to_show_when_closed:
		_apply_container_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_when_closed:
		_apply_container_visibility(node_path, false, details, "hidden")

	return _container_targets_result(details)


func interact(actor: Node = null) -> bool:
	return bool(open_container(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(open_container(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(open_container(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(open_container(actor, "interact").get("ok", false))


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if searched and not stay_available_after_search:
		return ""
	if searched and stay_available_after_search:
		if opened:
			return already_open_prompt_text if already_open_prompt_text.strip_edges() != "" else searched_prompt_text
		return searched_prompt_text
	if opened and not searched:
		var open_text := prompt_text.strip_edges()
		if open_text != "":
			return open_text
		return open_prompt_text
	if _requirements_pass():
		var prompt := prompt_text.strip_edges()
		if prompt != "":
			return prompt
		return open_prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func _enrich_container_result(search_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (search_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["container_kind"] = container_kind
	details["opened_flag"] = String(opened_flag)
	details["opened"] = opened
	details["searched"] = searched
	details["close_after_search"] = close_after_search
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(search_result.get("ok", false)),
		"code": String(search_result.get("code", "")),
		"message": String(search_result.get("message", "")),
		"source_id": String(search_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _container_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["container_kind"] = container_kind
	merged["opened_flag"] = String(opened_flag)
	merged["opened"] = opened
	merged["searched"] = searched
	merged["close_after_search"] = close_after_search
	return _result(ok, code, message, String(mechanic_id), merged)


func _container_targets_result(details: Dictionary) -> Dictionary:
	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"container_targets_applied" if warning_count == 0 else "container_targets_applied_with_warnings",
		"Container targets applied." if warning_count == 0 else "Container targets applied with warnings.",
		String(mechanic_id),
		details
	)


func _apply_container_visibility(node_path: NodePath, visible: bool, details: Dictionary, bucket: String, label: String = "") -> void:
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


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if searched and not stay_available_after_search:
		return "SEARCHED"
	if opened:
		return "OPEN"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
