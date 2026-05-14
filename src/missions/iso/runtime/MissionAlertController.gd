class_name MissionAlertController
extends Node

signal alert_state_changed(state: String)
signal alert_event(kind: String, source_id: String)

const VALID_STATES := ["normal", "suspicious", "alerted", "resolved"]
const COVER_TILE := Vector2i(2, 0)

@export var mission_id: String = ""
@export var suspicious_decay_seconds: float = 6.0

var alert_state: String = "normal"
var alert_score: float = 0.0
var player_detection_modifier: float = 1.0
var _zone_detection_modifier: float = 1.0
var _cover_detection_modifier: float = 1.0
var _sneak_detection_modifier: float = 1.0
var last_detection_source: String = ""
var _suspicious_timer: float = 0.0
## Per-source throttle for alarm-driven guard spawns (prevents multi-camera stampede).
var _last_spawn_msec_by_source: Dictionary = {}
var _security_adapter: MissionSecurityEventAdapter = null


func _ready() -> void:
	_ensure_security_adapter()
	call_deferred("_sync_security_adapter_context")
	set_process(true)
	_sync_state()


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
			if String(source_id).findn("garage_entry_beam") != -1:
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
	_suspicious_timer = 0.0
	_last_spawn_msec_by_source.clear()
	if _security_adapter != null:
		_security_adapter.reset_attempt_security_state()
	_sync_state()
