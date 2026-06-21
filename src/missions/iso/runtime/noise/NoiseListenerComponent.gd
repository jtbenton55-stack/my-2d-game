class_name NoiseListenerComponent
extends Node

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

signal noise_heard(noise_event: Dictionary)

@export var listener_id: StringName = &"noise_listener"
@export var enabled: bool = true
@export var radius_multiplier: float = 1.0
@export var accepted_kinds: PackedStringArray = PackedStringArray()
@export var accepted_teams: PackedStringArray = PackedStringArray()
@export var reaction_seconds: float = 2.0
@export var call_parent_reaction: bool = true
@export var set_parent_debug_metadata: bool = true

var heard_count: int = 0
var last_heard_noise: Dictionary = {}
var last_reaction_result: Dictionary = {}


func _ready() -> void:
	add_to_group("noise_listener")
	if not Engine.is_editor_hint() and EventBus.has_signal("mission_noise_emitted"):
		if not EventBus.mission_noise_emitted.is_connected(_on_mission_noise_emitted):
			EventBus.mission_noise_emitted.connect(_on_mission_noise_emitted)


func _exit_tree() -> void:
	if EventBus.has_signal("mission_noise_emitted") and EventBus.mission_noise_emitted.is_connected(_on_mission_noise_emitted):
		EventBus.mission_noise_emitted.disconnect(_on_mission_noise_emitted)


func can_hear(noise_event: Dictionary) -> bool:
	if not enabled:
		return false
	var kind := String(noise_event.get("kind", "generic"))
	if not _accepts_value(accepted_kinds, kind):
		return false
	var team := String(noise_event.get("team", "neutral"))
	if not _accepts_value(accepted_teams, team):
		return false
	var event := noise_event.duplicate(true)
	event["radius"] = float(event.get("radius", 0.0)) * maxf(0.0, radius_multiplier)
	return NoiseEventHelper.is_point_in_range(event, _listener_position())


func register_noise(noise_event: Dictionary) -> Dictionary:
	if not can_hear(noise_event):
		last_reaction_result = {"ok": false, "code": "noise_ignored", "listener_id": String(listener_id)}
		return last_reaction_result
	heard_count += 1
	last_heard_noise = noise_event.duplicate(true)
	last_reaction_result = _apply_debug_reaction(last_heard_noise)
	noise_heard.emit(last_heard_noise)
	return last_reaction_result


func get_debug_summary() -> Dictionary:
	return {
		"listener_id": String(listener_id),
		"enabled": enabled,
		"heard_count": heard_count,
		"last_heard_noise": last_heard_noise.duplicate(true),
		"last_reaction_result": last_reaction_result.duplicate(true),
	}


func _on_mission_noise_emitted(noise_event: Dictionary) -> void:
	register_noise(noise_event)


func _apply_debug_reaction(noise_event: Dictionary) -> Dictionary:
	var target := get_parent()
	var result := {
		"ok": true,
		"code": "noise_heard",
		"listener_id": String(listener_id),
		"source_id": String(noise_event.get("source_id", "")),
		"kind": String(noise_event.get("kind", "generic")),
	}
	if target != null and set_parent_debug_metadata:
		target.set_meta("last_noise_event", noise_event.duplicate(true))
		target.set_meta("noise_reaction_until", Time.get_ticks_msec() + int(reaction_seconds * 1000.0))
		target.set_meta("noise_reaction_kind", String(noise_event.get("kind", "generic")))
	if target != null and call_parent_reaction and target.has_method("on_noise_heard"):
		var value: Variant = target.call("on_noise_heard", noise_event.duplicate(true), self)
		if value is Dictionary:
			result["parent_result"] = value
		else:
			result["parent_result"] = {"ok": true, "code": "parent_reaction_called"}
	EventBus.debug("Noise listener %s heard %s" % [String(listener_id), NoiseEventHelper.debug_summary(noise_event)])
	return result


func _listener_position() -> Vector2:
	var parent := get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_position
	return Vector2.ZERO


func _accepts_value(values: PackedStringArray, value: String) -> bool:
	if values.is_empty():
		return true
	return values.has(value)
