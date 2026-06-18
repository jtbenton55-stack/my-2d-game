@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Effect Set")
@export var effects: EffectSet
@export var mission_id_override: String = ""
@export var include_payload_in_context := true
@export var debug_chain_label: String = ""

var last_effect_set_result: Dictionary = {}


func get_effect_type() -> String:
	return "effect_set"


func _apply_effect(event_id: String, payload: Dictionary) -> Dictionary:
	if effects == null:
		return _reject("rejected_missing_effect_set")
	if effects.is_empty():
		return _reject("rejected_empty_effect_set")
	var effect_result: Dictionary = effects.apply_all(_build_effect_context(event_id, payload))
	last_effect_set_result = effect_result.duplicate(true)
	var ok := bool(effect_result.get("ok", false))
	var details: Dictionary = effect_result.get("details", {}) as Dictionary
	return {
		"handled": ok,
		"result": "effect_set_applied" if ok else "effect_set_failed",
		"reason": String(effect_result.get("code", "")),
		"effect_id": String(effect_id),
		"effect_type": get_effect_type(),
		"event_id": event_id,
		"effect_set_id": String(effects.set_id),
		"effect_set_message": String(effect_result.get("message", "")),
		"effect_set_applied_count": int(details.get("applied_count", 0)),
		"effect_set_failed_count": int(details.get("failed_count", 0)),
		"effect_set_summary": effects.get_designer_summary(),
		"debug_chain": get_debug_chain(event_id, payload),
		"effect_set_result": effect_result,
	}


func get_debug_chain(event_id: String = "", payload: Dictionary = {}) -> PackedStringArray:
	var label := debug_chain_label.strip_edges()
	if label == "":
		label = "%s -> %s" % [String(effect_id), String(effects.set_id) if effects != null else "missing_effect_set"]
	var chain := PackedStringArray()
	chain.append(label)
	if event_id.strip_edges() != "":
		chain.append("event:%s" % event_id)
	if effects != null:
		chain.append("effect_set:%s" % String(effects.set_id))
		var summary := effects.get_designer_summary()
		if summary.strip_edges() != "":
			chain.append(summary)
	var payload_keys := _payload_keys(payload)
	if not payload_keys.is_empty():
		chain.append("payload:%s" % ",".join(payload_keys))
	return chain


func get_security_effect_debug_summary() -> Dictionary:
	var details: Dictionary = last_effect_set_result.get("details", {}) as Dictionary
	return {
		"effect_id": String(effect_id),
		"effect_type": get_effect_type(),
		"trigger_events": _trigger_event_strings(),
		"effect_set_id": String(effects.set_id) if effects != null else "",
		"effect_set_empty": effects == null or effects.is_empty(),
		"effect_set_summary": effects.get_designer_summary() if effects != null else "",
		"debug_chain_label": debug_chain_label,
		"last_event": last_trigger_event,
		"last_result": last_effect_result,
		"last_reason": last_effect_reason,
		"last_applied_count": int(details.get("applied_count", 0)),
		"last_failed_count": int(details.get("failed_count", 0)),
	}


func _build_effect_context(event_id: String, payload: Dictionary) -> Dictionary:
	var context := {
		"mission_id": _resolve_mission_id(),
		"mechanic": self,
		"source_id": String(effect_id),
		"source_path": str(get_path()),
		"security_event_id": event_id,
	}
	if include_payload_in_context:
		context["security_event_payload"] = payload.duplicate(true)
		context["payload"] = payload.duplicate(true)
	if payload.has("actor"):
		context["actor"] = payload.get("actor")
	return context


func _resolve_mission_id() -> String:
	var explicit := mission_id_override.strip_edges()
	if explicit != "":
		return explicit
	if _mission != null and is_instance_valid(_mission):
		var def: Variant = _mission.get("mission_definition")
		if def != null:
			var mid := String(def.get("mission_id")).strip_edges()
			if mid != "":
				return mid
	if MissionAutoloadResolver.has_game_state():
		return String(GameState.current_mission_id).strip_edges()
	return ""


func _trigger_event_strings() -> PackedStringArray:
	var out := PackedStringArray()
	for ev in trigger_events:
		out.append(String(ev))
	return out


func _payload_keys(payload: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for key in payload.keys():
		out.append(String(key))
	out.sort()
	return out
