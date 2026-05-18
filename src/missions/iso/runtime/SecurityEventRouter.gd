extends Node

## Mission-local security event router. Not an autoload.

var _listeners_by_event: Dictionary = {}
var _recent_events: Array[Dictionary] = []
const MAX_RECENT_EVENTS := 12

var last_dispatched_event: String = ""
var last_dispatch_msec: int = 0
var total_dispatched: int = 0
var last_listener_warning: String = ""
var last_dispatch_result: Dictionary = {}


func register_listener(event_id: StringName, listener: Node) -> void:
	var key := String(event_id).strip_edges()
	if key == "" or listener == null or not is_instance_valid(listener):
		return
	if not _listeners_by_event.has(key):
		_listeners_by_event[key] = []
	var list: Array = _listeners_by_event[key]
	for existing in list:
		if existing == listener:
			return
	list.append(listener)


func unregister_listener(event_id: StringName, listener: Node) -> void:
	var key := String(event_id).strip_edges()
	if key == "" or not _listeners_by_event.has(key):
		return
	var list: Array = _listeners_by_event[key]
	list.erase(listener)
	if list.is_empty():
		_listeners_by_event.erase(key)


func has_listeners(event_id: StringName) -> bool:
	return get_listener_count(event_id) > 0


func get_listener_count(event_id: StringName) -> int:
	var key := String(event_id).strip_edges()
	if not _listeners_by_event.has(key):
		return 0
	return (_listeners_by_event[key] as Array).size()


func get_registered_event_count() -> int:
	return _listeners_by_event.size()


func emit_event(event_id: StringName, payload: Dictionary = {}) -> Dictionary:
	var key := String(event_id).strip_edges()
	var result := _make_dispatch_result(key)
	if key == "":
		result["reasons"] = ["empty_event_id"]
		last_dispatch_result = result
		return result
	var full_payload := payload.duplicate(true)
	full_payload["event_id"] = key
	if not full_payload.has("timestamp"):
		full_payload["timestamp"] = Time.get_ticks_msec()
	last_dispatched_event = key
	last_dispatch_msec = int(full_payload.get("timestamp", Time.get_ticks_msec()))
	total_dispatched += 1
	_recent_events.append(full_payload.duplicate(true))
	while _recent_events.size() > MAX_RECENT_EVENTS:
		_recent_events.pop_front()
	if not _listeners_by_event.has(key):
		result["reasons"] = ["no_listeners_registered"]
		last_dispatch_result = result
		return result
	var listeners: Array = (_listeners_by_event[key] as Array).duplicate()
	result["listeners_registered"] = listeners.size()
	for listener in listeners:
		if listener == null or not is_instance_valid(listener):
			result["listeners_rejected"] += 1
			(result["reasons"] as Array).append("listener_freed")
			continue
		if bool(listener.get("enabled")) == false:
			result["listeners_rejected"] += 1
			(result["reasons"] as Array).append("listener_disabled:%s" % str(listener.get_path()))
			continue
		result["listeners_called"] += 1
		var listener_result := _call_listener(listener, StringName(key), full_payload)
		if bool(listener_result.get("handled", false)):
			result["listeners_handled"] += 1
			(result["successful_listener_paths"] as Array).append(str(listener.get_path()))
		else:
			result["listeners_rejected"] += 1
			var reason := String(listener_result.get("reason", listener_result.get("result", "rejected")))
			if reason == "":
				reason = "not_handled"
			(result["reasons"] as Array).append("%s:%s" % [str(listener.get_path()), reason])
	result["handled"] = int(result["listeners_handled"]) > 0
	last_dispatch_result = result
	return result


func get_last_dispatch_result() -> Dictionary:
	return last_dispatch_result.duplicate(true)


func event_was_handled(event_id: StringName) -> bool:
	if String(last_dispatched_event).strip_edges() != String(event_id).strip_edges():
		return false
	return bool(last_dispatch_result.get("handled", false))


func listeners_responded(event_id: StringName) -> bool:
	if String(last_dispatched_event).strip_edges() != String(event_id).strip_edges():
		return false
	return int(last_dispatch_result.get("listeners_called", 0)) > 0


func _call_listener(listener: Node, event_id: StringName, payload: Dictionary) -> Dictionary:
	if not listener.has_method("on_security_event"):
		last_listener_warning = "missing on_security_event: %s" % str(listener.get_path())
		return {"handled": false, "result": "rejected", "reason": "rejected_missing_method"}
	var ret: Variant = listener.call("on_security_event", event_id, payload)
	if ret is Dictionary:
		var d := ret as Dictionary
		if not d.has("handled"):
			d["handled"] = String(d.get("result", "")).strip_edges() in ["spawned", "handled", "success"]
		return d
	return {"handled": true, "result": "legacy_void", "reason": ""}


func _make_dispatch_result(event_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"listeners_registered": 0,
		"listeners_called": 0,
		"listeners_handled": 0,
		"listeners_rejected": 0,
		"handled": false,
		"reasons": [],
		"successful_listener_paths": [],
		"timestamp": Time.get_ticks_msec(),
	}


func get_debug_summary() -> Dictionary:
	var listener_counts: Dictionary = {}
	for key in _listeners_by_event.keys():
		listener_counts[key] = (_listeners_by_event[key] as Array).size()
	return {
		"active": true,
		"registered_event_count": get_registered_event_count(),
		"listener_counts": listener_counts,
		"total_dispatched": total_dispatched,
		"last_dispatched_event": last_dispatched_event,
		"last_dispatch_msec": last_dispatch_msec,
		"recent_events": _recent_events.duplicate(true),
		"last_listener_warning": last_listener_warning,
		"last_dispatch_result": last_dispatch_result.duplicate(true),
	}
