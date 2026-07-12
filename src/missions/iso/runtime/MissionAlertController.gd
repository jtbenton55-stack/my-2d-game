class_name MissionAlertController
extends Node

signal alert_state_changed(state: String)
signal alert_event(kind: String, source_id: String)
signal noise_event_registered(noise_event: Dictionary)

const VALID_STATES := ["normal", "suspicious", "alerted", "resolved"]
const COVER_TILE := Vector2i(2, 0)

@export var mission_id: String = ""
@export var suspicious_decay_seconds: float = 6.0
@export var noise_suspicious_threshold: float = 0.5

@export_group("Camera Policy")
## Opt-in social-stealth policy. Other missions retain always-actionable cameras.
@export var camera_action_required_at_normal_initial_heat: bool = false
@export var camera_raised_initial_heat_threshold: int = 1

var alert_state: String = "normal"
var alert_score: float = 0.0
var player_detection_modifier: float = 1.0
var _zone_detection_modifier: float = 1.0
var _cover_detection_modifier: float = 1.0
var _sneak_detection_modifier: float = 1.0
var last_detection_source: String = ""
var last_noise_event: Dictionary = {}
var total_noise_events: int = 0
var _suspicious_timer: float = 0.0
## Per-source throttle for alarm-driven guard spawns (prevents multi-camera stampede).
var _last_spawn_msec_by_source: Dictionary = {}
var _security_adapter: MissionSecurityEventAdapter = null
var _recent_noise_events: Array[Dictionary] = []
const MAX_RECENT_NOISE_EVENTS := 8
var _camera_initial_heat: int = 0
var _suspicious_actions: Dictionary = {}
var _last_camera_policy_result: Dictionary = {}


func _ready() -> void:
	add_to_group("iso_alert_controller")
	_capture_camera_initial_heat()
	_ensure_security_adapter()
	call_deferred("_sync_security_adapter_context")
	set_process(true)
	_sync_state()


func configure_camera_detection_policy(require_action_at_normal_heat: bool, initial_heat: int = -1) -> void:
	camera_action_required_at_normal_initial_heat = require_action_at_normal_heat
	if initial_heat >= 0:
		_camera_initial_heat = initial_heat
	else:
		_capture_camera_initial_heat()


func register_suspicious_action(action_id: String, kind: String = "theft") -> Dictionary:
	var id := action_id.strip_edges()
	if id == "":
		return {"ok": false, "code": "invalid_action_id", "action_id": action_id}
	var entry: Dictionary = _suspicious_actions.get(id, {})
	entry["kind"] = kind.strip_edges().to_lower() if kind.strip_edges() != "" else "suspicious"
	entry["count"] = int(entry.get("count", 0)) + 1
	_suspicious_actions[id] = entry
	return {"ok": true, "code": "suspicious_action_registered", "action_id": id, "kind": entry["kind"], "count": entry["count"]}


func end_suspicious_action(action_id: String) -> Dictionary:
	var id := action_id.strip_edges()
	if not _suspicious_actions.has(id):
		return {"ok": false, "code": "suspicious_action_not_registered", "action_id": id}
	var entry: Dictionary = _suspicious_actions[id]
	var count := int(entry.get("count", 1)) - 1
	if count <= 0:
		_suspicious_actions.erase(id)
	else:
		entry["count"] = count
		_suspicious_actions[id] = entry
	return {"ok": true, "code": "suspicious_action_ended", "action_id": id, "remaining_count": maxi(0, count)}


func is_suspicious_action_active(action_id: String = "") -> bool:
	var id := action_id.strip_edges()
	return not _suspicious_actions.is_empty() if id == "" else _suspicious_actions.has(id)


func should_camera_accumulate_exposure(actor: Node = null, source_id: String = "") -> bool:
	return bool(evaluate_camera_exposure(actor, source_id).get("actionable", true))


func evaluate_camera_exposure(actor: Node = null, source_id: String = "") -> Dictionary:
	var actionable := true
	var reason := "default_always_detect"
	if camera_action_required_at_normal_initial_heat:
		if _camera_initial_heat >= camera_raised_initial_heat_threshold:
			reason = "raised_initial_posture"
		elif _suspicious_actions.is_empty():
			actionable = false
			reason = "normal_posture_no_suspicious_action"
		else:
			var theft_active := false
			var other_action_active := false
			for entry_value in _suspicious_actions.values():
				var entry: Dictionary = entry_value
				if String(entry.get("kind", "")) == "theft":
					theft_active = true
				else:
					other_action_active = true
			if theft_active and not other_action_active and _is_actor_camera_protected(actor):
				actionable = false
				reason = "suspicious_theft_concealed"
			else:
				reason = "suspicious_action_active"
	_last_camera_policy_result = {
		"actionable": actionable,
		"reason": reason,
		"source_id": source_id,
		"initial_heat": _camera_initial_heat,
		"active_action_count": _suspicious_actions.size(),
		"actor_stealth_active": actor != null and actor.has_method("is_stealth_active") and actor.call("is_stealth_active") == true,
		"actor_mission_hidden": actor != null and actor.is_in_group("mission_hidden"),
	}
	return _last_camera_policy_result.duplicate(true)


func get_camera_policy_debug_state() -> Dictionary:
	return {
		"enabled": camera_action_required_at_normal_initial_heat,
		"initial_heat": _camera_initial_heat,
		"raised_initial_heat_threshold": camera_raised_initial_heat_threshold,
		"active_actions": _suspicious_actions.duplicate(true),
		"last_evaluation": _last_camera_policy_result.duplicate(true),
	}


func _capture_camera_initial_heat() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	_camera_initial_heat = GameState.get_mission_heat(mid) if mid != "" else 0


func _is_actor_camera_protected(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if actor.is_in_group("mission_hidden"):
		return true
	return actor.has_method("is_stealth_active") and actor.call("is_stealth_active") == true


func _process(delta: float) -> void:
	if alert_state == "suspicious":
		_suspicious_timer -= delta
		if _suspicious_timer <= 0.0:
			set_alert_state("resolved")
	_update_cover_modifier()
	_update_sneak_modifier()


func set_alert_state(next_state: String) -> void:
	if not VALID_STATES.has(next_state):
		return
	if alert_state == next_state:
		return
	alert_state = next_state
	if next_state == "suspicious":
		_suspicious_timer = suspicious_decay_seconds
	_sync_state()
	alert_state_changed.emit(alert_state)
	EventBus.debug("Mission alert state -> %s" % alert_state)


func register_detection_event(source_id: String, amount: float, kind: String = "detection") -> void:
	alert_score = clampf(alert_score + amount, 0.0, 10.0)
	last_detection_source = source_id
	if amount > 0.01 and alert_state == "normal":
		set_alert_state("suspicious")
	if alert_score >= 1.0:
		set_alert_state("alerted")
		record_alarm_event(kind, source_id)
	alert_event.emit(kind, source_id)
	_emit_detection_state()


func accumulate_exposure(source_id: String, amount: float, kind: String = "camera_detected") -> void:
	alert_score = clampf(alert_score + amount, 0.0, 1.0)
	last_detection_source = source_id
	if alert_score > 0.01 and alert_state == "normal":
		set_alert_state("suspicious")
	if alert_score >= 1.0:
		set_alert_state("alerted")
		record_alarm_event(kind, source_id)
		alert_score = 0.0
	_emit_detection_state()


func decay_exposure(amount: float) -> void:
	alert_score = maxf(0.0, alert_score - amount)
	if alert_score <= 0.01 and alert_state == "suspicious":
		set_alert_state("resolved")
	_emit_detection_state()


func record_alarm_event(kind: String = "alarm", source_id: String = "") -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	var scene := get_tree().current_scene
	if mid != "":
		GameState.record_mission_performance_event(mid, "alarms_triggered", 1)
		GameState.set_mission_alert_state(mid, "alerted")
		if scene != null and scene.has_method("increment_attempt_counter"):
			scene.call("increment_attempt_counter", "alarms", 1)
		if kind == "guard_detected":
			GameState.record_mission_performance_event(mid, "guards_alerted", 1)
			if scene != null and scene.has_method("increment_attempt_counter"):
				scene.call("increment_attempt_counter", "guards_alerted", 1)
		if kind == "camera_detected":
			GameState.record_mission_performance_event(mid, "cameras_triggered", 1)
			if scene != null and scene.has_method("increment_attempt_counter"):
				scene.call("increment_attempt_counter", "cameras_triggered", 1)
	EventBus.debug("Alarm event %s source=%s" % [kind, source_id])
	EventBus.debug("Camera shake: intensity 2.0 duration 0.12 (alarm)")
	EventBus.screen_shake.emit(2.0, 0.12)
	var now := Time.get_ticks_msec()
	var allow_guard_spawn := true
	if scene != null and scene.has_method("can_spawn_alarm_guard_for_source"):
		allow_guard_spawn = scene.call("can_spawn_alarm_guard_for_source", source_id) == true
	var cd_ms := 2000
	match String(kind):
		"camera_detected":
			cd_ms = 7000
		"wrong_code_alarm", "alarm_zone":
			cd_ms = 2600
		_:
			cd_ms = 2000
	var sk := String(source_id) if String(source_id) != "" else String(kind)
	var last_t := int(_last_spawn_msec_by_source.get(sk, -1_000_000))
	if now - last_t < cd_ms:
		allow_guard_spawn = false
	if allow_guard_spawn and scene != null and scene.has_method("spawn_attack_guard_near_player"):
		_last_spawn_msec_by_source[sk] = now
		scene.call("spawn_attack_guard_near_player", source_id)
	_route_alarm_to_security_adapter(kind, source_id)


func register_noise_event(noise_event: Dictionary) -> Dictionary:
	last_noise_event = noise_event.duplicate(true)
	total_noise_events += 1
	_recent_noise_events.append(last_noise_event.duplicate(true))
	while _recent_noise_events.size() > MAX_RECENT_NOISE_EVENTS:
		_recent_noise_events.pop_front()
	var kind := String(noise_event.get("kind", "generic"))
	var source_id := String(noise_event.get("source_id", ""))
	var strength := float(noise_event.get("strength", 0.0))
	var team := String(noise_event.get("team", "neutral"))
	if team == "player" and strength >= noise_suspicious_threshold and alert_state == "normal":
		set_alert_state("suspicious")
	alert_event.emit("noise:%s" % kind, source_id)
	noise_event_registered.emit(last_noise_event)
	EventBus.debug("Noise registered kind=%s source=%s strength=%.2f" % [kind, source_id, strength])
	return {
		"ok": true,
		"code": "noise_registered",
		"source_id": source_id,
		"kind": kind,
		"alert_state": alert_state,
		"total_noise_events": total_noise_events,
	}


func get_noise_debug_summary() -> Dictionary:
	return {
		"total_noise_events": total_noise_events,
		"last_noise_event": last_noise_event.duplicate(true),
		"recent_noise_events": _recent_noise_events.duplicate(true),
	}


func get_security_event_adapter() -> MissionSecurityEventAdapter:
	_ensure_security_adapter()
	return _security_adapter


func _ensure_security_adapter() -> void:
	if _security_adapter != null:
		return
	_security_adapter = MissionSecurityEventAdapter.new()
	_security_adapter.name = "MissionSecurityEventAdapter"
	add_child(_security_adapter)
	_sync_security_adapter_context()


func _sync_security_adapter_context() -> void:
	if _security_adapter == null:
		return
	_security_adapter.setup(self, mission_id)


func _route_alarm_to_security_adapter(raw_kind: String, source_id: String) -> void:
	_ensure_security_adapter()
	var nk := "alarm"
	match String(raw_kind):
		"camera_detected":
			nk = "camera_detection"
		"guard_detected":
			nk = "guard_detection"
		"wrong_code_alarm":
			nk = "wrong_code_alarm"
		"alarm_zone":
			if String(source_id).findn("garage_entry_beam") != -1 or String(source_id).findn("AMBUSH_security_beam") != -1:
				nk = "beam_trip"
			else:
				nk = "alarm"
		_:
			nk = "alarm"
	var sev := 1
	if nk == "beam_trip" or nk == "wrong_code_alarm":
		sev = 2
	_security_adapter.report_security_event(nk, source_id, sev, {"record_alarm_kind": raw_kind})


func set_detection_modifier(modifier: float) -> void:
	_zone_detection_modifier = clampf(modifier, 0.1, 3.0)
	_recompute_detection_modifier()
	_emit_detection_state()


func _update_cover_modifier() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var collision := scene.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if player == null or collision == null:
		return
	var cell := collision.local_to_map(collision.to_local(player.global_position))
	var atlas := collision.get_cell_atlas_coords(cell)
	var next_cover := 0.7 if atlas == COVER_TILE else 1.0
	if absf(next_cover - _cover_detection_modifier) <= 0.001:
		return
	_cover_detection_modifier = next_cover
	_recompute_detection_modifier()
	_emit_detection_state()


func _recompute_detection_modifier() -> void:
	player_detection_modifier = clampf(_zone_detection_modifier * _cover_detection_modifier * _sneak_detection_modifier, 0.1, 3.0)


func _update_sneak_modifier() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("is_stealth_active"):
		return
	var next := 0.55 if player.call("is_stealth_active") == true else 1.15
	if absf(next - _sneak_detection_modifier) <= 0.001:
		return
	_sneak_detection_modifier = next
	_recompute_detection_modifier()
	_emit_detection_state()


func _sync_state() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.set_mission_alert_state(mid, alert_state)
	_emit_detection_state()


func _emit_detection_state() -> void:
	EventBus.detection_state_changed.emit(alert_score, 1.0, alert_state, player_detection_modifier, last_detection_source)


func reset_attempt_state() -> void:
	alert_state = "normal"
	alert_score = 0.0
	last_detection_source = ""
	last_noise_event.clear()
	total_noise_events = 0
	_recent_noise_events.clear()
	_suspicious_timer = 0.0
	_last_spawn_msec_by_source.clear()
	_suspicious_actions.clear()
	_last_camera_policy_result.clear()
	_capture_camera_initial_heat()
	if _security_adapter != null:
		_security_adapter.reset_attempt_security_state()
	_sync_state()
