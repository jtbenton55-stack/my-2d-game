@tool
class_name DialogueTriggerZone
extends "res://src/missions/iso/authoring/mechanics/TriggerZone.gd"

@export_group("Dialogue")
@export var dialogue_key: StringName = &""
@export var fallback_speaker: String = "Mission"
@export_multiline var fallback_text: String = ""
@export var dialogue_payload: Dictionary = {}
@export var play_dialogue_before_effects: bool = true
@export var cooldown_seconds: float = 0.75

var last_dialogue_result: Dictionary = {}
var _last_dialogue_msec: int = -1000000


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not _cooldown_ready():
		last_activation_result = _result(false, "dialogue_cooldown", "Dialogue trigger is cooling down.", String(mechanic_id), {"remaining_seconds": _cooldown_remaining_seconds()})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	var context := build_context(actor)
	context["trigger_reason"] = reason
	var dialogue_result: Dictionary = {}
	if play_dialogue_before_effects:
		dialogue_result = _play_dialogue(context)
		if not bool(dialogue_result.get("ok", false)):
			last_dialogue_result = dialogue_result
			last_activation_result = _result(false, "dialogue_failed", String(dialogue_result.get("message", "Dialogue failed.")), String(mechanic_id), {"dialogue_result": dialogue_result})
			activation_failed.emit(String(mechanic_id), last_activation_result)
			refresh_debug_label()
			return last_activation_result
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)) and not play_dialogue_before_effects:
		dialogue_result = _play_dialogue(context)
	if not dialogue_result.is_empty():
		last_dialogue_result = dialogue_result
		_add_detail(result, "dialogue_result", dialogue_result)
	if bool(result.get("ok", false)):
		_stamp_cooldown()
	return result


func play_dialogue(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _play_dialogue(context: Dictionary) -> Dictionary:
	var key := String(dialogue_key).strip_edges()
	var payload := dialogue_payload.duplicate(true)
	if not payload.has("fallback_speaker"):
		payload["fallback_speaker"] = fallback_speaker
	if not payload.has("speaker"):
		payload["speaker"] = fallback_speaker
	if not payload.has("fallback_text"):
		payload["fallback_text"] = fallback_text
	var dialogue_context := context.duplicate(true)
	dialogue_context["payload"] = payload
	if key != "":
		return MissionDialogueBridge.play_dialogue_key(key, dialogue_context)
	return MissionDialogueBridge.play_simple_line(payload, dialogue_context)


func _cooldown_ready() -> bool:
	if cooldown_seconds <= 0.0:
		return true
	var elapsed := float(Time.get_ticks_msec() - _last_dialogue_msec) / 1000.0
	return elapsed >= cooldown_seconds


func _cooldown_remaining_seconds() -> float:
	if cooldown_seconds <= 0.0:
		return 0.0
	var elapsed := float(Time.get_ticks_msec() - _last_dialogue_msec) / 1000.0
	return maxf(0.0, cooldown_seconds - elapsed)


func _stamp_cooldown() -> void:
	_last_dialogue_msec = Time.get_ticks_msec()


func _add_detail(result: Dictionary, key: String, value: Variant) -> void:
	var details: Dictionary = {}
	var raw_details: Variant = result.get("details", {})
	if raw_details is Dictionary:
		details = (raw_details as Dictionary).duplicate(true)
	details[key] = value
	result["details"] = details


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
