class_name CoverMeterRuntime
extends Node

## Replan Packet 3: professionalism becomes a live Cover meter. Out-of-role
## behavior (running indoors, hauling incriminating gear) drains it over time;
## believable tasks refill it (via BelievableTaskZone deltas) and grant alibi
## windows that suppress witness reports and auto-pass roaming inspections.

signal cover_drained(reason: String, new_value: int)
signal alibi_window_started(seconds: float)

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var enabled: bool = true
## Seconds of continuous running before the meter drains 1 point.
@export var run_drain_interval: float = 4.0
## Carrying at least this much incriminating weight starts the slow drain.
@export var incriminating_drain_threshold: int = 3
@export var incriminating_drain_interval: float = 10.0
## The meter never drains below this floor from passive behavior.
@export var drain_floor: int = -3

var _run_accum := 0.0
var _incriminating_accum := 0.0
var _alibi_until_msec: int = 0


func _ready() -> void:
	add_to_group("cover_meter_runtime")


func _process(delta: float) -> void:
	if not enabled or Engine.is_editor_hint():
		return
	var player := _find_player()
	if player == null:
		return
	_process_run_drain(player, delta)
	_process_incriminating_drain(delta)


func register_alibi_window(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	_alibi_until_msec = maxi(_alibi_until_msec, until)
	alibi_window_started.emit(seconds)
	EventBus.debug("Alibi window active for %.1fs" % seconds)


func is_alibi_active() -> bool:
	return Time.get_ticks_msec() < _alibi_until_msec


func get_alibi_seconds_remaining() -> float:
	return maxf(0.0, float(_alibi_until_msec - Time.get_ticks_msec()) / 1000.0)


func get_cover_summary() -> Dictionary:
	var social := SocialStealthAdapterScript.get_summary("")
	return {
		"professionalism": int(social.get("professionalism", 0)),
		"cleanliness": int(social.get("cleanliness", 0)),
		"alibi_active": is_alibi_active(),
		"alibi_seconds_remaining": get_alibi_seconds_remaining(),
	}


func _process_run_drain(player: Node, delta: float) -> void:
	if _is_running(player):
		_run_accum += delta
		if _run_accum >= run_drain_interval:
			_run_accum = 0.0
			_drain(1, "running_indoors")
	else:
		_run_accum = maxf(0.0, _run_accum - delta * 2.0)


func _process_incriminating_drain(delta: float) -> void:
	if MissionInventory.get_incriminating_total() >= incriminating_drain_threshold:
		_incriminating_accum += delta
		if _incriminating_accum >= incriminating_drain_interval:
			_incriminating_accum = 0.0
			_drain(1, "incriminating_gear")
	else:
		_incriminating_accum = 0.0


func _drain(amount: int, reason: String) -> void:
	var current := int(SocialStealthAdapterScript.get_summary("").get("professionalism", 0))
	if current <= drain_floor:
		return
	var result := SocialStealthAdapterScript.adjust_professionalism(-amount, {})
	var new_value := int((result.get("details", {}) as Dictionary).get("value", current - amount))
	cover_drained.emit(reason, new_value)
	match reason:
		"running_indoors":
			EventBus.objective_updated.emit("Running looks unprofessional. Cover slipping.")
		"incriminating_gear":
			EventBus.objective_updated.emit("That gear is hard to explain. Cover slipping.")


func _is_running(player: Node) -> bool:
	if player.has_method("is_stealth_active") and bool(player.call("is_stealth_active")):
		return false
	var velocity: Vector2 = player.get("velocity") if player.get("velocity") is Vector2 else Vector2.ZERO
	var walk_speed := float(player.get("speed")) if player.get("speed") != null else 300.0
	return velocity.length() > walk_speed * 1.05


func _find_player() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")
