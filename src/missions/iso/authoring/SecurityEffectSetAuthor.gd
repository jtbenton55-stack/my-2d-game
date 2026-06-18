@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Effect Set")
@export var effects: EffectSet
@export var mission_id_override: String = ""
@export var include_payload_in_context := true


func get_effect_type() -> String:
	return "effect_set"


func _apply_effect(event_id: String, payload: Dictionary) -> Dictionary:
	if effects == null:
		return _reject("rejected_missing_effect_set")
	if effects.is_empty():
		return _reject("rejected_empty_effect_set")
	var effect_result: Dictionary = effects.apply_all(_build_effect_context(event_id, payload))
	var ok := bool(effect_result.get("ok", false))
	return {
		"handled": ok,
		"result": "effect_set_applied" if ok else "effect_set_failed",
		"reason": String(effect_result.get("code", "")),
		"effect_id": String(effect_id),
		"effect_type": get_effect_type(),
		"event_id": event_id,
		"effect_set_id": String(effects.set_id),
		"effect_set_result": effect_result,
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
