class_name MissionAlertController
extends Node

signal alert_state_changed(state: String)
signal alert_event(kind: String, source_id: String)

const VALID_STATES := ["normal", "suspicious", "alerted", "resolved"]

@export var mission_id: String = ""
@export var suspicious_decay_seconds: float = 6.0

var alert_state: String = "normal"
var alert_score: float = 0.0
var player_detection_modifier: float = 1.0
var last_detection_source: String = ""
var _suspicious_timer: float = 0.0


func _ready() -> void:
	set_process(true)
	_sync_state()


func _process(delta: float) -> void:
	if alert_state == "suspicious":
		_suspicious_timer -= delta
		if _suspicious_timer <= 0.0:
			set_alert_state("resolved")


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


func record_alarm_event(kind: String = "alarm", source_id: String = "") -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.record_mission_performance_event(mid, "alarms_triggered", 1)
		GameState.set_mission_alert_state(mid, "alerted")
		if kind == "guard_detected":
			GameState.record_mission_performance_event(mid, "guards_alerted", 1)
	EventBus.debug("Alarm event %s source=%s" % [kind, source_id])
	EventBus.debug("Camera shake: intensity 2.0 duration 0.12 (alarm)")
	EventBus.screen_shake.emit(2.0, 0.12)


func set_detection_modifier(modifier: float) -> void:
	player_detection_modifier = clampf(modifier, 0.1, 3.0)
	_emit_detection_state()


func _sync_state() -> void:
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.set_mission_alert_state(mid, alert_state)
	_emit_detection_state()


func _emit_detection_state() -> void:
	EventBus.detection_state_changed.emit(alert_score, 1.0, alert_state, player_detection_modifier, last_detection_source)
