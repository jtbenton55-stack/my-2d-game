@tool
class_name RewardNode
extends MechanicAreaBase

@export_group("Reward")
@export_enum("clue", "cash", "typed_collectible", "card", "item", "evidence", "bonus", "generic")
var reward_kind: String = "generic"
@export var reward_id: StringName = &""
@export var collected_flag: StringName = &""
@export var starts_collected: bool = false
@export var mark_collected_on_success: bool = true
@export var stay_available_after_collect: bool = false

@export_group("Reward Targets")
@export var target_visual_path: NodePath
@export var nodes_to_show_on_collect: Array[NodePath] = []
@export var nodes_to_hide_on_collect: Array[NodePath] = []

@export_group("Reward Feedback")
@export var collected_prompt_text: String = "Already collected"
@export var collected_message: String = "Collected reward."
@export var empty_message: String = "Nothing to collect."
@export var collect_sound_key: StringName = &""
@export var emit_eventbus_debug: bool = false

var collected: bool = false
var last_collect_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	collected = starts_collected
	if collected:
		_apply_starts_collected_targets()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["reward_kind"] = reward_kind
	context["reward_id"] = String(reward_id)
	context["collected_flag"] = String(collected_flag)
	context["collected"] = collected
	return context


func collect(actor: Node = null, reason: String = "interact") -> Dictionary:
	if collected:
		if not stay_available_after_collect:
			last_collect_result = _collect_result(
				true,
				"already_collected",
				collected_prompt_text if collected_prompt_text.strip_edges() != "" else "Already collected.",
				{"reason": reason, "reapplied_effects": false}
			)
			return last_collect_result
		last_collect_result = _collect_result(
			true,
			"already_collected",
			collected_prompt_text if collected_prompt_text.strip_edges() != "" else "Already collected.",
			{"reason": reason, "reapplied_effects": false, "stay_available": true}
		)
		return last_collect_result

	var activation_result: Dictionary = activate(actor, reason)
	last_collect_result = _enrich_collect_result(activation_result, actor, reason)

	if not bool(activation_result.get("ok", false)):
		return last_collect_result
	if String(activation_result.get("code", "")) != "activation_succeeded":
		return last_collect_result

	if mark_collected_on_success:
		collected = true
	var context := build_context(actor)

	var flag_result: Dictionary = set_collected_flag(context)
	var targets_result: Dictionary = apply_collect_targets()
	last_collect_result = _merge_collect_details(last_collect_result, {
		"collected_flag_result": flag_result,
		"collect_targets_result": targets_result,
		"activation_result": activation_result,
	})

	var message := collected_message if collected_message.strip_edges() != "" else "Collected reward."
	last_collect_result["ok"] = true
	last_collect_result["code"] = "reward_collected"
	last_collect_result["message"] = message

	_emit_collect_debug(activation_result)
	_notify_availability()
	refresh_debug_label()
	return last_collect_result


func reset_reward() -> void:
	collected = false
	_notify_availability()
	refresh_debug_label()


func is_collected() -> bool:
	return collected


func set_collected_flag(context: Dictionary) -> Dictionary:
	if collected_flag == &"":
		return _result(true, "no_collected_flag", "No collected_flag configured.")
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Collected flag skipped in editor.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(collected_flag), true, context)


func apply_collect_targets() -> Dictionary:
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Collect targets skipped in editor.")

	var details: Dictionary = {
		"shown": [],
		"hidden": [],
		"warnings": [],
	}

	for node_path: NodePath in nodes_to_show_on_collect:
		_apply_collect_visibility(node_path, true, details, "shown")
	for node_path: NodePath in nodes_to_hide_on_collect:
		_apply_collect_visibility(node_path, false, details, "hidden")

	if target_visual_path != NodePath():
		_apply_collect_visibility(target_visual_path, false, details, "hidden", "target_visual_path")

	var warning_count: int = (details.get("warnings", []) as Array).size()
	var had_changes: bool = not (details.get("shown", []) as Array).is_empty() or not (details.get("hidden", []) as Array).is_empty()
	var targets_ok: bool = warning_count == 0 or had_changes
	return _result(
		targets_ok,
		"collect_targets_applied" if warning_count == 0 else "collect_targets_applied_with_warnings",
		"Collect targets applied." if warning_count == 0 else "Collect targets applied with warnings.",
		String(mechanic_id),
		details
	)


func interact(actor: Node = null) -> bool:
	return bool(collect(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(collect(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(collect(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(collect(actor, "interact").get("ok", false))


func is_interaction_available(actor: Node = null) -> bool:
	if not enabled:
		return false
	if collected and not stay_available_after_collect:
		return false
	if collected and stay_available_after_collect:
		return true
	return super.is_interaction_available(actor)


func is_completed() -> bool:
	if collected and not stay_available_after_collect:
		return true
	return super.is_completed()


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if collected:
		if not stay_available_after_collect:
			return ""
		return collected_prompt_text
	if _requirements_pass():
		return prompt_text
	if requirements != null:
		var locked := requirements.locked_message.strip_edges()
		if locked != "":
			return locked
	return locked_prompt_text


func _apply_starts_collected_targets() -> void:
	if Engine.is_editor_hint():
		return
	apply_collect_targets()


func _enrich_collect_result(activation_result: Dictionary, actor: Node, reason: String) -> Dictionary:
	var details: Dictionary = (activation_result.get("details", {}) as Dictionary).duplicate(true)
	details["reason"] = reason
	details["reward_kind"] = reward_kind
	details["reward_id"] = String(reward_id)
	details["collected_flag"] = String(collected_flag)
	details["collected"] = collected
	if actor != null:
		details["actor"] = actor
	return {
		"ok": bool(activation_result.get("ok", false)),
		"code": String(activation_result.get("code", "")),
		"message": String(activation_result.get("message", "")),
		"source_id": String(activation_result.get("source_id", String(mechanic_id))),
		"details": details,
	}


func _collect_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	var merged := details.duplicate(true)
	merged["reward_kind"] = reward_kind
	merged["reward_id"] = String(reward_id)
	merged["collected_flag"] = String(collected_flag)
	merged["collected"] = collected
	return _result(ok, code, message, String(mechanic_id), merged)


func _merge_collect_details(base: Dictionary, extra: Dictionary) -> Dictionary:
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


func _apply_collect_visibility(node_path: NodePath, visible: bool, details: Dictionary, bucket: String, label: String = "") -> void:
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


func _emit_collect_debug(activation_result: Dictionary) -> void:
	if Engine.is_editor_hint() or not emit_eventbus_debug:
		return
	var event_bus := get_tree().root.get_node_or_null("EventBus") if get_tree() != null else null
	if event_bus == null or not event_bus.has_method("debug"):
		return
	var status := "ok" if bool(activation_result.get("ok", false)) else "fail"
	event_bus.call(
		"debug",
		"RewardNode %s (%s/%s) %s: %s" % [String(mechanic_id), reward_kind, String(reward_id), status, String(activation_result.get("code", ""))]
	)


func _debug_label_text() -> String:
	if not enabled:
		return "DISABLED"
	if collected:
		return "COLLECTED"
	if _requirements_pass():
		return "READY"
	return "LOCKED"
