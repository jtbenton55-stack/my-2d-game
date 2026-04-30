extends Node
class_name DashAbility
## Short burst movement with i-frames. Parent must be PlayerCombatController; player body is grandparent.

signal dash_ended

@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.15

var is_dashing: bool = false

var _time_left: float = 0.0
var _direction: Vector2 = Vector2.RIGHT
var _player: CharacterBody2D


func _ready() -> void:
	_player = get_parent().get_parent() as CharacterBody2D
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not is_dashing:
		return
	_time_left -= delta
	if _player:
		_player.velocity = _direction * dash_speed
		_player.move_and_slide()
	if _time_left <= 0.0:
		_end_dash()


func execute(direction: Vector2) -> void:
	if is_dashing or _player == null:
		return
	_direction = direction.normalized()
	if _direction.length_squared() < 0.0001:
		_direction = Vector2.RIGHT
	is_dashing = true
	_time_left = dash_duration
	_player.add_to_group("invulnerable")
	_player.invulnerable = true
	set_physics_process(true)


func _end_dash() -> void:
	is_dashing = false
	set_physics_process(false)
	if _player:
		_player.remove_from_group("invulnerable")
		_player.invulnerable = false
	dash_ended.emit()
