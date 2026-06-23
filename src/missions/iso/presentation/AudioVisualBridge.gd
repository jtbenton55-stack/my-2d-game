class_name AudioVisualBridge
extends Node

@export var audio_player_path: NodePath
@export var resonant_adapter_path: NodePath
@export var named_cue_payloads: Dictionary = {}


func play_cue(cue_id: String, context: Dictionary = {}) -> Dictionary:
	var id := cue_id.strip_edges()
	if id == "":
		return _result(false, "cue_id_missing", "Presentation cue id is missing.")
	var payload := _cue_payload(id)
	var resonant_result := _try_resonant(id, payload, context)
	var audio_result := _play_audio(id, payload, context)
	var shake_result := _emit_shake(payload)
	_emit_debug(id, payload)
	return _result(true, "presentation_cue_played", "Presentation cue played: %s." % id, id, {"payload": payload, "resonant": resonant_result, "audio": audio_result, "shake": shake_result})


func _cue_payload(cue_id: String) -> Dictionary:
	var raw: Variant = named_cue_payloads.get(cue_id, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


func _try_resonant(cue_id: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	var adapter := get_node_or_null(resonant_adapter_path)
	if adapter == null:
		return _result(true, "resonant_missing_safe", "Resonant adapter missing; cue used built-in fallback.", cue_id)
	for method in ["play_cue", "trigger_cue", "apply_cue"]:
		if adapter.has_method(method):
			adapter.call(method, cue_id, payload, context)
			return _result(true, "resonant_cue_played", "Resonant adapter cue played.", cue_id, {"adapter": str(adapter.get_path())})
	return _result(true, "resonant_api_missing_safe", "Resonant adapter API missing; cue used built-in fallback.", cue_id)


func _play_audio(cue_id: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	var player := get_node_or_null(audio_player_path)
	if player != null and player.has_method("play"):
		player.call("play")
		return _result(true, "audio_player_started", "AudioStreamPlayer started.", cue_id, {"player": str(player.get_path())})
	var sfx_id := String(payload.get("sfx_id", cue_id)).strip_edges()
	if sfx_id == "":
		return _result(true, "audio_skipped", "No SFX id supplied.", cue_id)
	var audio_manager := _autoload("AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.call("play_sfx", sfx_id, context.get("position", Vector2.ZERO))
		return _result(true, "sfx_played", "SFX cue sent to AudioManager.", cue_id, {"sfx_id": sfx_id})
	return _result(true, "audio_manager_missing_safe", "AudioManager missing; cue logged only.", cue_id, {"sfx_id": sfx_id})


func _emit_shake(payload: Dictionary) -> Dictionary:
	if not payload.has("shake_intensity") and not payload.has("shake_duration"):
		return _result(true, "shake_skipped", "No shake payload supplied.")
	var event_bus := _autoload("EventBus")
	if event_bus != null and event_bus.has_signal("screen_shake"):
		var intensity := float(payload.get("shake_intensity", 1.0))
		var duration := float(payload.get("shake_duration", 0.1))
		event_bus.emit_signal("screen_shake", intensity, duration)
		return _result(true, "shake_emitted", "Screen shake emitted.", "", {"intensity": intensity, "duration": duration})
	return _result(true, "shake_missing_safe", "EventBus missing; shake skipped.")


func _emit_debug(cue_id: String, payload: Dictionary) -> void:
	var event_bus := _autoload("EventBus")
	if event_bus != null and event_bus.has_method("debug"):
		event_bus.call("debug", "Presentation cue %s %s" % [cue_id, str(payload)])


func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null(name)
	return null


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
