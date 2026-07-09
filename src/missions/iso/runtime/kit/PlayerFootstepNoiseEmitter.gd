class_name PlayerFootstepNoiseEmitter
extends Node

## Replan Packet 2: movement is a noise decision. Emits footstep NoiseEvents
## sized by movement tier (sneak/walk/run) so the pulse rings from Packet 1
## show exactly how loud the player is being. Bulky cargo raises the radius.
## Footsteps go to EventBus (in-range NoiseListenerComponents react) but are
## NOT routed straight to the alert controller -- only a listener that
## actually hears you should escalate.

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export var sneak_radius: float = 40.0
@export var walk_radius: float = 95.0
@export var run_radius: float = 190.0
@export var sneak_strength: float = 0.15
@export var walk_strength: float = 0.35
@export var run_strength: float = 0.7
@export var step_interval_walk: float = 0.45
@export var step_interval_run: float = 0.3
@export var bulky_radius_multiplier: float = 1.5
@export var min_speed_for_step: float = 20.0

var last_tier: String = "idle"
var total_steps_emitted: int = 0

var _step_timer := 0.0
var _step_index := 0


func _process(delta: float) -> void:
	var player := _find_player()
	if player == null:
		return
	var speed: float = (player.get("velocity") as Vector2).length() if player.get("velocity") is Vector2 else 0.0
	if speed < min_speed_for_step:
		last_tier = "idle"
		_step_timer = 0.0
		return
	var tier := _movement_tier(player, speed)
	last_tier = tier
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	_step_timer = step_interval_run if tier == "run" else step_interval_walk
	_emit_footstep(player, tier)


func _movement_tier(player: Node, speed: float) -> String:
	if player.has_method("is_stealth_active") and bool(player.call("is_stealth_active")):
		return "sneak"
	var walk_speed := float(player.get("speed")) if player.get("speed") != null else 300.0
	if speed > walk_speed * 1.1:
		return "run"
	return "walk"


func _emit_footstep(player: Node, tier: String) -> void:
	var radius := walk_radius
	var strength := walk_strength
	match tier:
		"sneak":
			radius = sneak_radius
			strength = sneak_strength
		"run":
			radius = run_radius
			strength = run_strength
	if MissionInventory.has_bulky_item():
		radius *= bulky_radius_multiplier
		strength = minf(1.0, strength + 0.1)
	_step_index += 1
	total_steps_emitted += 1
	var event := NoiseEventHelper.make_event(
		"player_footstep_%d" % _step_index,
		"player_footsteps",
		(player as Node2D).global_position,
		radius,
		strength,
		"footstep",
		"player",
		{"tier": tier, "bulky": MissionInventory.has_bulky_item()}
	)
	if EventBus.has_signal("mission_noise_emitted"):
		EventBus.mission_noise_emitted.emit(event)


func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D
