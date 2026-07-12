@tool
extends Node2D

@export_group("Spawn Identity")
@export var spawn_id: StringName = &"guard_spawn"
@export var enabled := true
@export var trigger_events: Array[StringName] = [&"ambush_beam_tripped"]
@export var spawn_on_ready: bool = false

@export_group("Guard")
@export var guard_archetype: StringName = &"grunt"
@export var spawn_count: int = 1
@export var max_alive_from_this_spawn: int = 3
@export var spawn_spread_radius: float = 0.0
@export var guard_scene: PackedScene

@export_group("Behavior")
@export var initial_behavior: StringName = &"attack_player"
@export var fallback_behavior: StringName = &"security_net"
@export var patrol_route_id: StringName = &""

@export_group("Perception")
@export var detection_range_override: float = -1.0
@export var vision_angle_degrees_override: float = -1.0
@export var detection_speed_override: float = -1.0
@export var detection_decay_override: float = -1.0
@export var detection_threshold_override: float = -1.0
@export var inspection_rule_set: InspectionRuleSet
@export var social_cover_mission_id: String = ""
@export var ignore_social_cover: bool = false
## Optional world-space room that turns this guard hostile as soon as the player enters it.
@export var hostile_on_player_enter_rect: Rect2 = Rect2()
## Alarm events may already own performance accounting for guards spawned directly into combat.
@export var report_initial_awareness: bool = true

@export_group("Limits")
@export var cooldown_seconds: float = 4.0
@export var spawn_delay_seconds: float = 0.0
@export var heat_min: int = 0
@export var heat_max: int = 99
@export var one_shot: bool = false

@export_group("Editor Preview")
@export var preview_color: Color = Color(1.0, 0.55, 0.1, 0.9)
@export var show_label := true

var _label: Label = null
var _mission: Node = null
var _last_spawn_msec: int = -1_000_000
var _one_shot_used := false
var _alive_from_spawn: Array[Node] = []
var last_spawn_result: String = ""
var last_spawn_reason: String = ""
var last_spawned_count: int = 0
var last_trigger_event: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		_ensure_label()
		_refresh_label()
		queue_redraw()


func bind_mission(mission: Node) -> void:
	_mission = mission


func spawn_initial() -> Dictionary:
	if not spawn_on_ready:
		return {"handled": false, "result": "ignored", "reason": "spawn_on_ready_disabled", "spawned_count": 0}
	return _dispatch_spawn("initial", {"source_type": "initial_guard_spawn"})


func on_security_event(event_id: StringName, payload: Dictionary) -> Dictionary:
	if not enabled:
		last_spawn_result = "rejected_disabled"
		last_spawn_reason = "rejected_disabled"
		return _reject("rejected_disabled")
	if one_shot and _one_shot_used:
		last_spawn_result = "rejected_one_shot"
		last_spawn_reason = "one_shot_already_used"
		return _reject("rejected_one_shot")
	var want := String(event_id).strip_edges()
	if want == "":
		last_spawn_result = "rejected_invalid_event"
		return _reject("rejected_invalid_event")
	var matched := false
	for ev in trigger_events:
		if String(ev).strip_edges() == want:
			matched = true
			break
	if not matched:
		return {"handled": false, "result": "ignored", "reason": "rejected_invalid_event", "spawned_count": 0}
	last_trigger_event = want
	if spawn_delay_seconds > 0.0:
		var timer := get_tree().create_timer(spawn_delay_seconds)
		timer.timeout.connect(_dispatch_spawn.bind(want, payload))
		return {"handled": true, "result": "scheduled", "reason": "spawn_delayed", "spawned_count": 0}
	return _dispatch_spawn(want, payload)


func _dispatch_spawn(event_id: String, payload: Dictionary) -> Dictionary:
	_prune_alive()
	if _mission == null or not is_instance_valid(_mission):
		last_spawn_result = "rejected_missing_mission"
		last_spawn_reason = "no_mission"
		last_spawned_count = 0
		return _reject("rejected_missing_mission")
	if not _mission.has_method("_spawn_guard_from_authoring_spawn"):
		last_spawn_result = "rejected_missing_mission"
		last_spawn_reason = "mission_missing_spawn_api"
		last_spawned_count = 0
		return _reject("rejected_missing_mission")
	var reject_reason := _get_reject_reason(String(event_id), payload)
	if reject_reason != "":
		last_spawn_result = reject_reason
		last_spawn_reason = reject_reason
		last_spawned_count = 0
		return _reject(reject_reason)
	var result: Dictionary = _mission.call(
		"_spawn_guard_from_authoring_spawn",
		self,
		StringName(event_id),
		payload,
	)
	last_spawn_result = String(result.get("result", "unknown"))
	last_spawn_reason = String(result.get("reason", ""))
	last_spawned_count = int(result.get("spawned_count", 0))
	var handled := last_spawned_count > 0 or last_spawn_result == "spawned"
	if last_spawned_count > 0:
		_last_spawn_msec = Time.get_ticks_msec()
		if one_shot:
			_one_shot_used = true
		var spawned_v: Variant = result.get("spawned_guards", [])
		if spawned_v is Array:
			for g in spawned_v as Array:
				if g is Node and is_instance_valid(g):
					_alive_from_spawn.append(g as Node)
					_bind_spawned_guard(g as Node)
	return {
		"handled": handled,
		"result": last_spawn_result,
		"reason": last_spawn_reason,
		"spawned_count": last_spawned_count,
	}


func _bind_spawned_guard(guard: Node) -> void:
	if guard.has_method("apply_guard_authoring_config"):
		guard.call("apply_guard_authoring_config", {
			"detection_range": detection_range_override,
			"vision_angle_degrees": vision_angle_degrees_override,
			"detection_speed": detection_speed_override,
			"detection_decay": detection_decay_override,
			"detection_threshold": detection_threshold_override,
			"inspection_rule_set": inspection_rule_set,
			"social_cover_mission_id": social_cover_mission_id,
			"ignore_social_cover": ignore_social_cover,
			"hostile_on_player_enter_rect": hostile_on_player_enter_rect,
		})
	if guard.has_signal("spotted_player"):
		var callback := Callable(self, "_on_authored_guard_spotted").bind(String(spawn_id))
		if not guard.is_connected("spotted_player", callback):
			guard.connect("spotted_player", callback)
	if report_initial_awareness and guard.has_method("is_aware") and bool(guard.call("is_aware")):
		_on_authored_guard_spotted(String(spawn_id))


func _on_authored_guard_spotted(source_id: String) -> void:
	if _mission == null or not is_instance_valid(_mission):
		return
	var alert := _mission.find_child("MissionAlertController", true, false)
	if alert == null:
		var tree := get_tree()
		if tree != null:
			alert = tree.get_first_node_in_group("iso_alert_controller")
	if alert != null and alert.has_method("register_detection_event"):
		alert.call("register_detection_event", "guard:" + source_id, 1.0, "guard_detected")


func _get_reject_reason(event_id: String, payload: Dictionary) -> String:
	if not can_accept_event(event_id, payload):
		if one_shot and _one_shot_used:
			return "rejected_one_shot"
		var now := Time.get_ticks_msec()
		if cooldown_seconds > 0.0 and now - _last_spawn_msec < int(cooldown_seconds * 1000.0):
			return "rejected_cooldown"
		_prune_alive()
		if max_alive_from_this_spawn > 0 and _alive_from_spawn.size() >= max_alive_from_this_spawn:
			return "rejected_cap"
		var heat := 0
		if GameState.has_method("get_mission_heat"):
			heat = int(GameState.get_mission_heat(String(GameState.current_mission_id)))
		if heat < heat_min:
			return "rejected_heat"
		if heat > heat_max:
			return "rejected_heat"
		if String(initial_behavior).strip_edges().to_lower() == "patrol":
			var route := String(patrol_route_id).strip_edges()
			if route != "" and _mission != null:
				var sec := _mission.get_node_or_null("GameplayRoot/SecurityAuthoringRoot")
				if sec != null and sec.has_method("find_patrol_route"):
					if sec.call("find_patrol_route", StringName(route)) == null:
						return "rejected_missing_patrol_route"
		return "rejected_spawn_failed"
	return ""


func _reject(reason: String) -> Dictionary:
	return {"handled": false, "result": "rejected", "reason": reason, "spawned_count": 0}


func _prune_alive() -> void:
	var kept: Array[Node] = []
	for g in _alive_from_spawn:
		if g != null and is_instance_valid(g):
			kept.append(g)
	_alive_from_spawn = kept


func get_alive_count() -> int:
	_prune_alive()
	return _alive_from_spawn.size()


func can_accept_event(_event_id: String, _payload: Dictionary) -> bool:
	if not enabled:
		return false
	if one_shot and _one_shot_used:
		return false
	var now := Time.get_ticks_msec()
	if cooldown_seconds > 0.0 and now - _last_spawn_msec < int(cooldown_seconds * 1000.0):
		return false
	_prune_alive()
	if max_alive_from_this_spawn > 0 and _alive_from_spawn.size() >= max_alive_from_this_spawn:
		return false
	var heat := 0
	if GameState.has_method("get_mission_heat"):
		heat = int(GameState.get_mission_heat(String(GameState.current_mission_id)))
	if heat < heat_min or heat > heat_max:
		return false
	return true


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_circle(Vector2.ZERO, 10.0, Color(preview_color.r, preview_color.g, preview_color.b, 0.25))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, preview_color, 2.0)


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size = Vector2(180.0, 22.0)
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)
		if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
			_label.owner = get_tree().edited_scene_root


func _refresh_label() -> void:
	_ensure_label()
	if _label == null:
		return
	var evs: PackedStringArray = []
	for e in trigger_events:
		evs.append(String(e))
	_label.text = "SPAWN %s <- %s" % [String(spawn_id), ", ".join(evs)]
	_label.position = Vector2(-90.0, -28.0)
