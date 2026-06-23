class_name PresentationSequencePlayer
extends Node

@export var sequence_steps: Array[Dictionary] = []
@export var sequence_library: Dictionary = {}
@export var run_on_ready: bool = false
@export var intro_sequence_id: String = "intro"
@export var outro_sequence_id: String = "outro"
@export var run_intro_on_mission_started: bool = false
@export var run_outro_on_mission_completed: bool = false
@export var run_outro_on_mission_failed: bool = false
@export var camera_bridge_path: NodePath = NodePath("../CameraBridge")
@export var player_control_bridge_path: NodePath = NodePath("../PlayerControlBridge")
@export var audio_visual_bridge_path: NodePath = NodePath("../AudioVisualBridge")

var last_sequence_result: Dictionary = {}


func _ready() -> void:
	_connect_mission_hooks()
	if run_on_ready:
		call_deferred("play_sequence", "", {})


func play_intro(context: Dictionary = {}) -> Dictionary:
	return play_sequence(intro_sequence_id, context)


func play_outro(context: Dictionary = {}) -> Dictionary:
	return play_sequence(outro_sequence_id, context)


func play_sequence(sequence_id: String = "", context: Dictionary = {}) -> Dictionary:
	var steps := _steps_for(sequence_id)
	var results: Array[Dictionary] = []
	var ok := true
	for i in steps.size():
		var step: Dictionary = steps[i]
		var step_context := context.duplicate(true)
		step_context["sequence_id"] = sequence_id
		step_context["sequence_step_index"] = i
		step_context["source_id"] = String(step.get("id", "%s_%d" % [sequence_id, i]))
		var step_result := _play_step(step, step_context)
		results.append(step_result)
		if not bool(step_result.get("ok", false)):
			ok = false
			if bool(step.get("stop_on_failure", true)):
				break
	last_sequence_result = _result(ok, "presentation_sequence_played" if ok else "presentation_sequence_partial", "Presentation sequence played." if ok else "Presentation sequence stopped after a failed step.", sequence_id, {"step_results": results})
	return last_sequence_result


func _play_step(step: Dictionary, context: Dictionary) -> Dictionary:
	var step_type := String(step.get("type", "")).strip_edges()
	match step_type:
		"dialogue_key":
			var dialogue_context := context.duplicate(true)
			dialogue_context["payload"] = _step_payload(step)
			return MissionDialogueBridge.play_dialogue_key(String(step.get("key", "")), dialogue_context)
		"simple_dialogue":
			return MissionDialogueBridge.play_simple_line(_step_payload(step), context)
		"bark":
			return MissionDialogueBridge.play_bark(String(step.get("speaker", "Bentley")), String(step.get("text", "Bark.")), context)
		"camera_focus":
			var camera: Variant = _camera_bridge()
			if camera == null:
				return _result(false, "camera_bridge_missing", "CameraBridge is missing.")
			return camera.focus_named_target(String(step.get("target", "")), float(step.get("blend_seconds", -1.0)), context)
		"camera_restore":
			var camera_restore: Variant = _camera_bridge()
			if camera_restore == null:
				return _result(false, "camera_bridge_missing", "CameraBridge is missing.")
			return camera_restore.restore_camera(float(step.get("blend_seconds", -1.0)))
		"camera_shake":
			var camera_shake: Variant = _camera_bridge()
			if camera_shake != null:
				return camera_shake.shake(float(step.get("intensity", 1.0)), float(step.get("duration", 0.1)))
			return _emit_screen_shake(float(step.get("intensity", 1.0)), float(step.get("duration", 0.1)))
		"player_lock":
			var player_bridge: Variant = _player_bridge()
			if player_bridge == null:
				return _result(false, "player_control_bridge_missing", "PlayerControlBridge is missing.")
			return player_bridge.lock_input(String(step.get("reason", "presentation")))
		"player_restore":
			var player_restore: Variant = _player_bridge()
			if player_restore == null:
				return _result(false, "player_control_bridge_missing", "PlayerControlBridge is missing.")
			return player_restore.restore_input()
		"player_guide":
			var guide_bridge: Variant = _player_bridge()
			if guide_bridge == null:
				return _result(false, "player_control_bridge_missing", "PlayerControlBridge is missing.")
			return guide_bridge.guide_to(step.get("position", Vector2.ZERO) as Vector2)
		"audio_visual":
			var av: Variant = _audio_visual_bridge()
			if av == null:
				return _result(false, "audio_visual_bridge_missing", "AudioVisualBridge is missing.")
			return av.play_cue(String(step.get("cue", "")), context)
		"wait":
			return _result(true, "wait_step_recorded", "Wait step recorded without blocking tests.", String(step.get("id", "")), {"duration": float(step.get("duration", 0.0))})
		_:
			return _result(false, "unknown_presentation_step", "Unknown presentation step: %s." % step_type)


func _steps_for(sequence_id: String) -> Array[Dictionary]:
	var id := sequence_id.strip_edges()
	if id != "" and sequence_library.has(id):
		var raw: Variant = sequence_library.get(id)
		if raw is Array:
			var out: Array[Dictionary] = []
			for item in raw as Array:
				if item is Dictionary:
					out.append((item as Dictionary).duplicate(true))
			return out
	return sequence_steps.duplicate(true)


func _step_payload(step: Dictionary) -> Dictionary:
	var payload: Dictionary = {}
	var raw_payload: Variant = step.get("payload", {})
	if raw_payload is Dictionary:
		payload = (raw_payload as Dictionary).duplicate(true)
	for key in ["speaker", "text", "fallback_speaker", "fallback_text", "lines"]:
		if step.has(key) and not payload.has(key):
			payload[key] = step[key]
	return payload


func _connect_mission_hooks() -> void:
	var event_bus := _autoload("EventBus")
	if event_bus == null:
		return
	if run_intro_on_mission_started and event_bus.has_signal("mission_started") and not event_bus.mission_started.is_connected(_on_mission_started):
		event_bus.mission_started.connect(_on_mission_started)
	if run_outro_on_mission_completed and event_bus.has_signal("mission_completed") and not event_bus.mission_completed.is_connected(_on_mission_completed):
		event_bus.mission_completed.connect(_on_mission_completed)
	if run_outro_on_mission_failed and event_bus.has_signal("mission_failed") and not event_bus.mission_failed.is_connected(_on_mission_failed):
		event_bus.mission_failed.connect(_on_mission_failed)


func _on_mission_started(mission_id: String) -> void:
	play_intro({"mission_id": mission_id})


func _on_mission_completed(mission_id: String, rewards: Dictionary) -> void:
	play_outro({"mission_id": mission_id, "rewards": rewards})


func _on_mission_failed(mission_id: String, reason: String) -> void:
	play_outro({"mission_id": mission_id, "failure_reason": reason})


func _camera_bridge() -> Variant:
	return get_node_or_null(camera_bridge_path)


func _player_bridge() -> Variant:
	return get_node_or_null(player_control_bridge_path)


func _audio_visual_bridge() -> Variant:
	return get_node_or_null(audio_visual_bridge_path)


func _emit_screen_shake(intensity: float, duration: float) -> Dictionary:
	var event_bus := _autoload("EventBus")
	if event_bus != null and event_bus.has_signal("screen_shake"):
		event_bus.emit_signal("screen_shake", intensity, duration)
		return _result(true, "camera_shake_emitted", "Camera shake emitted.")
	return _result(false, "event_bus_missing", "EventBus is missing.")


func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root.get_node_or_null(name)
	return null


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
