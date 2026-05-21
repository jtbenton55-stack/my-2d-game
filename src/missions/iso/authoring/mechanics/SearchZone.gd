@tool
class_name SearchZone
extends MechanicAreaBase

@export_group("Search")
@export_enum("drawer", "shelf", "trash", "counter", "desk", "body", "evidence", "stash", "generic")
var search_kind: String = "generic"
@export var searched_flag: StringName = &""
@export var starts_searched: bool = false
@export var mark_searched_on_success: bool = true
@export var stay_available_after_search: bool = false

@export_group("Targets")
@export var target_visual_path: NodePath
@export var nodes_to_show_on_search: Array[NodePath] = []
@export var nodes_to_hide_on_search: Array[NodePath] = []

@export_group("Feedback")
@export var searched_prompt_text: String = "Already searched"
@export var found_message: String = "Found something."
@export var empty_message: String = "Nothing useful here."
@export var search_sound_key: StringName = &""
@export var found_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var searched: bool = false
var last_search_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	searched = starts_searched
	if searched:
		_apply_starts_searched_targets()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["search_kind"] = search_kind
	context["searched_flag"] = String(searched_flag)
	context["searched"] = searched
	return context


func search(actor: Node = null, reason: String = "interact") -> Dictionary:
	if searched:
		if not stay_available_after_search:
			last_search_result = _search_result(
				true,
				"already_searched",
				searched_prompt_text if searched_prompt_text.strip_edges() != "" else "Already searched.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_search_result
		last_search_result = _search_result(
			true,
			"already_searched",
			searched_prompt_text if searched_prompt_text.strip_edges() != "" else "Already searched.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_search_result

	var activation_result: Dictionary = activate(actor, reason)
	last_search_result = _enrich_search_result(activation_result, actor, reason)

	if not bool(activation_result.get("ok", false)):
		return last_search_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		return last_search_result

	if mark_searched_on_success:
		searched = true
	var context := build_context(actor)

	var flag_result: Dictionary = set_searched_flag(context)
	var target_result: Dictionary = apply_search_targets()
	last_search_result = _merge_search_details(last_search_result, {
		"searched_flag_result": flag_result,
		"target_result": target_result,
	})

	_emit_search_debug(activation_result)
	_notify_availability()
	refresh_debug_label()
	return last_search_result


func reset_search() -> void:
	searched = false
	_notify_availability()
	refresh_debug_label()


func is_searched() -> bool:
	return searched


func apply_search_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Search targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"warnings": [],
	}

	for node_path: NodePath in nodes_to_show_on_search:
		_apply_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_on_search:
		_apply_visibility(node_path, false, details, "hidden")

	if target_visual_path != NodePath():
		_apply_visibility(target_visual_path, false, details, "hidden", "target_visual_path")

	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"search_targets_applied" if warning_count == 0 else "search_targets_applied_with_warnings",
		"Search targets applied." if warning_count == 0 else "Search targets applied with warnings.",
		String(mechanic_id),
		details
	)


func set_searched_flag(context: Dictionary) -> Dictionary:
	if searched_flag == &"":
		return _result(true, "no_searched_flag", "No searched_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Searched flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(searched_flag), true, context)


func interact(actor: Node = null) -> bool:
	return bool(search(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(search(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(search(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(search(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if searched and not stay_available_after_search:
		return false
	if searched and stay_available_after_search:
		return true
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if searched and not stay_available_after_search:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if searched:
		if not stay_available_after_search:
			return ""
		return searched_prompt_text
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func _apply_starts_searched_targets() -> void:
	if Engine.is_editor_hint():
		return
	apply_search_targets()


func _enrich_search_result(activation_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (activation_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["search_kind"] = search_kind
	details["searched_flag"] = String(searched_flag)
	details["searched"] = searched
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(activation_result.get("ok", false)),
		"code": String(activation_result.get("code", "")),
		"message": String(activation_result.get("message", "")),
		"source_id": String(activation_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _search_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["search_kind"] = search_kind
	merged["searched_flag"] = String(searched_flag)
	merged["searched"] = searched
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_search_details(base: Dictionary, extra: Dictionary) -> Dictionary:
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


func _emit_search_debug(activation_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	var status := "ok" if bool(activation_result.get("ok", false)) else "fail"
	event_bus.call(
		"debug",
		"SearchZone %s (%s) %s: %s" % [String(mechanic_id), search_kind, status, String(activation_result.get("code", ""))]
	)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if searched:
		return "SEARCHED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
