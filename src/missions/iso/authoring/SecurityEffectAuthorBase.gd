@tool
extends Node2D
## Shared cooldown / event-match / result reporting for downstream security effect authors.

@export_group("Effect Identity")
@export var effect_id: StringName = &"security_effect"
@export var enabled := true
@export var trigger_events: Array[StringName] = []

@export_group("Limits")
@export var one_shot := false
@export var cooldown_seconds: float = 0.0

@export_group("Editor Preview")
@export var preview_color: Color = Color(0.65, 0.4, 0.95, 0.9)
@export var show_label := true

var _label: Label = null
var _mission: Node = null
var _last_trigger_msec: int = -1_000_000
var _one_shot_used := false
var last_effect_result: String = ""
var last_effect_reason: String = ""
var last_trigger_event: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_label()
		_refresh_label()
		queue_redraw()


func is_downstream_effect_author() -> bool:
	return true


func get_effect_type() -> String:
	return "effect"


func bind_mission(mission: Node) -> void:
	_mission = mission


func on_security_event(event_id: StringName, payload: Dictionary) -> Dictionary:
	if not enabled:
		return _reject("rejected_disabled")
	if one_shot and _one_shot_used:
		return _reject("rejected_one_shot")
	var want := String(event_id).strip_edges()
	if want == "":
		return _reject("rejected_invalid_event")
	if not _event_matches(want):
		return {"handled": false, "result": "ignored", "reason": "event_not_listened", "effect_id": String(effect_id)}
	if cooldown_seconds > 0.0:
		var now := Time.get_ticks_msec()
		if now - _last_trigger_msec < int(cooldown_seconds * 1000.0):
			return _reject("rejected_cooldown")
	last_trigger_event = want
	var result := _apply_effect(want, payload)
	if bool(result.get("handled", false)):
		_last_trigger_msec = Time.get_ticks_msec()
		if one_shot:
			_one_shot_used = true
	last_effect_result = String(result.get("result", ""))
	last_effect_reason = String(result.get("reason", ""))
	_report_to_mission(result)
	return result


func _apply_effect(_event_id: String, _payload: Dictionary) -> Dictionary:
	return _reject("not_implemented")


func _event_matches(event_id: String) -> bool:
	for ev in trigger_events:
		if String(ev).strip_edges() == event_id:
			return true
	return false


func _reject(reason: String) -> Dictionary:
	last_effect_result = "rejected"
	last_effect_reason = reason
	var result := {
		"handled": false,
		"result": "rejected",
		"reason": reason,
		"effect_id": String(effect_id),
		"effect_type": get_effect_type(),
	}
	_report_to_mission(result)
	return result


func _success(result_key: String, reason: String = "", extra: Dictionary = {}) -> Dictionary:
	var result := {
		"handled": true,
		"result": result_key,
		"reason": reason,
		"effect_id": String(effect_id),
		"effect_type": get_effect_type(),
	}
	for key in extra.keys():
		result[key] = extra[key]
	return result


func _report_to_mission(result: Dictionary) -> void:
	if _mission == null or not is_instance_valid(_mission):
		return
	if _mission.has_method("_record_authoring_effect_result"):
		_mission.call("_record_authoring_effect_result", get_effect_type(), self, result)


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size = Vector2(200.0, 22.0)
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)
		if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
			_label.owner = get_tree().edited_scene_root


func _refresh_label() -> void:
	_ensure_label()
	if _label == null or not show_label:
		return
	var evs: PackedStringArray = []
	for e in trigger_events:
		evs.append(String(e))
	_label.text = "%s %s <- %s" % [get_effect_type().to_upper(), String(effect_id), ", ".join(evs)]
	_label.position = Vector2(-100.0, -28.0)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 8.0, Color(preview_color.r, preview_color.g, preview_color.b, 0.3))
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, preview_color, 2.0)
