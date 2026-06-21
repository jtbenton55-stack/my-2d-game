class_name NoiseReactiveGuard
extends Node2D

signal noise_reaction_started(noise_event: Dictionary)

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export var guard_id: StringName = &"noise_reactive_guard"
@export var reaction_seconds: float = 3.0
@export var face_noise_source: bool = true
@export var add_enemy_group: bool = false

var reaction_state: String = "idle"
var reaction_count: int = 0
var investigate_position: Vector2 = Vector2.ZERO
var investigate_until_msec: int = 0
var last_noise_event: Dictionary = {}


func _ready() -> void:
	add_to_group("noise_reactive_guard")
	if add_enemy_group:
		add_to_group("enemy")
	set_process(true)


func _process(_delta: float) -> void:
	if reaction_state == "investigating_noise" and Time.get_ticks_msec() >= investigate_until_msec:
		reaction_state = "idle"
		set_meta("noise_reaction_state", reaction_state)


func on_noise_heard(noise_event: Dictionary, listener: Node = null) -> Dictionary:
	reaction_count += 1
	last_noise_event = noise_event.duplicate(true)
	investigate_position = noise_event.get("position", global_position)
	investigate_until_msec = Time.get_ticks_msec() + int(reaction_seconds * 1000.0)
	reaction_state = "investigating_noise"
	if face_noise_source and not global_position.is_equal_approx(investigate_position):
		rotation = (investigate_position - global_position).angle()
	set_meta("noise_reaction_state", reaction_state)
	set_meta("noise_investigate_position", investigate_position)
	set_meta("noise_reaction_until", investigate_until_msec)
	set_meta("last_noise_event", last_noise_event.duplicate(true))
	var result := {
		"ok": true,
		"code": "guard_investigating_noise",
		"guard_id": String(guard_id),
		"reaction_state": reaction_state,
		"investigate_position": investigate_position,
		"reaction_count": reaction_count,
	}
	if listener != null:
		result["listener_id"] = String(listener.get("listener_id"))
	EventBus.debug("Noise reactive guard %s investigating %s" % [String(guard_id), NoiseEventHelper.debug_summary(noise_event)])
	noise_reaction_started.emit(last_noise_event)
	return result


func get_noise_reaction_summary() -> Dictionary:
	return {
		"guard_id": String(guard_id),
		"reaction_state": reaction_state,
		"reaction_count": reaction_count,
		"investigate_position": investigate_position,
		"investigate_until_msec": investigate_until_msec,
		"last_noise_event": last_noise_event.duplicate(true),
	}
