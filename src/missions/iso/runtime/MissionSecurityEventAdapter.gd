class_name MissionSecurityEventAdapter
extends Node
## Thin attempt-local security event normalizer for iso missions (D6-01).
## Persistent heat stays in GameState.failed_attempts (capped); this adapter does NOT increment heat for mid-run alarms.

signal security_event_reported(event: Dictionary)

const MAX_EVENT_LOG := 12

var _alert_controller: MissionAlertController = null
var _mission_id: String = ""
var _attempt_id: String = ""
var _coalesce_frame: int = -1
var _coalesce_keys: Dictionary = {}
var _counters: Dictionary = {}
var _last_events: Array[Dictionary] = []
var _deferred_notes: PackedStringArray = PackedStringArray([
	"Guard patrol LOS beyond runtime guard spot is not wired to adapter in D6-01.",
])


func setup(context_node: Node = null, mission_id: String = "") -> void:
	if context_node is MissionAlertController:
		_alert_controller = context_node as MissionAlertController
	if mission_id.strip_edges() != "":
		_mission_id = mission_id.strip_edges()
	elif _alert_controller != null and String(_alert_controller.mission_id).strip_edges() != "":
		_mission_id = String(_alert_controller.mission_id)


func reset_attempt_security_state() -> void:
	_attempt_id = "%d_%d" % [Time.get_ticks_msec(), randi()]
	_counters.clear()
	_last_events.clear()
	_coalesce_frame = -1
	_coalesce_keys.clear()


func report_security_event(kind: String, source_id: String = "", severity: int = 1, flags: Dictionary = {}) -> Dictionary:
	var k := String(kind).strip_edges()
	if k == "":
		k = "alarm"
	var src := String(source_id).strip_edges()
	var frame := Engine.get_process_frames()
	if _coalesce_frame != frame:
		_coalesce_frame = frame
		_coalesce_keys.clear()
	var dedupe_key := "%s|%s" % [k, src]
	if _coalesce_keys.has(dedupe_key):
		return {"deduped": true, "kind": k, "source_id": src}
	_coalesce_keys[dedupe_key] = true

	var mid := _resolve_mission_id()
	var ev := {
		"kind": k,
		"source_id": src,
		"mission_id": mid,
		"severity": severity,
		"timestamp_msec": Time.get_ticks_msec(),
		"frame": frame,
		"attempt_id": _attempt_id,
		"flags": flags.duplicate(true),
	}
	_counters[k] = int(_counters.get(k, 0)) + 1
	_last_events.append(ev.duplicate(true))
	while _last_events.size() > MAX_EVENT_LOG:
		_last_events.pop_front()
	security_event_reported.emit(ev.duplicate(true))
	return ev.duplicate(true)


func get_security_debug_snapshot() -> Dictionary:
	var mid := _resolve_mission_id()
	var heat := 0
	var failed := 0
	if MissionAutoloadResolver.has_game_state():
		heat = GameState.get_mission_heat(mid)
		failed = int(GameState.failed_attempts.get(mid, 0))
	var alert := ""
	if _alert_controller != null and is_instance_valid(_alert_controller):
		alert = String(_alert_controller.alert_state)
	elif MissionAutoloadResolver.has_game_state() and mid != "":
		alert = String(GameState.get_mission_alert_state(mid))
	return {
		"mission_id": mid,
		"heat": heat,
		"max_heat": 5,
		"failed_attempts": failed,
		"alert_state": alert,
		"counters_by_kind": _counters.duplicate(true),
		"last_events": _pack_events_for_debug(),
		"deferred_wiring_notes": _deferred_notes.duplicate(),
		"heat_policy_note": "Mid-run security events are attempt-local; persistent heat rises only on mission failure (GameState.fail_mission).",
	}


func get_pause_security_summary() -> Dictionary:
	var mid := _resolve_mission_id()
	if not MissionAutoloadResolver.has_game_state() or mid == "":
		return {"ok": false, "plain_text": ""}
	var heat := GameState.get_mission_heat(mid)
	return {
		"ok": true,
		"mission_id": mid,
		"heat": heat,
		"max_heat": 5,
		"plain_text": "Heat: %d/5 — failed runs make this mission more guarded on replay. Current alarms affect only this attempt." % heat,
	}


func _resolve_mission_id() -> String:
	if _mission_id.strip_edges() != "":
		return _mission_id.strip_edges()
	if _alert_controller != null and is_instance_valid(_alert_controller):
		var mid := String(_alert_controller.mission_id).strip_edges()
		if mid != "":
			return mid
	if MissionAutoloadResolver.has_game_state():
		return String(GameState.current_mission_id).strip_edges()
	return ""


func _pack_events_for_debug() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in _last_events:
		if ev is Dictionary:
			out.append((ev as Dictionary).duplicate(true))
	return out
