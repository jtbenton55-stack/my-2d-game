extends "res://src/enemies/EnemyBase.gd"

@export var patrol_speed := 100.0
@export var wait_time_at_points := 2.0
@export var detection_speed := 1.0
@export var detection_decay := 0.5
@export var alert_duration := 5.0

var _patrol_points: Array[Vector2] = []
var _patrol_target_index := 0
var _patrol_state := 0
var _patrol_idle_timer := 0.0

func _ready() -> void:
	super._ready()

## Call from mission code with a scene Path2D; uses world-space points from the curve.
func assign_patrol_path(path_node: Path2D) -> void:
	_patrol_points.clear()
	_patrol_state = 0
	_patrol_idle_timer = 0.0
	if path_node == null or path_node.curve == null:
		return
	for i in range(path_node.curve.point_count):
		_patrol_points.append(path_node.to_global(path_node.curve.get_point_position(i)))
	if _patrol_points.size() < 2:
		return
	global_position = _patrol_points[0]
	_patrol_target_index = 1 % _patrol_points.size()

func _patrol_or_idle(delta: float) -> void:
	if _patrol_points.size() < 2:
		super._patrol_or_idle(delta)
		return
	var dest := _patrol_points[_patrol_target_index]
	if _patrol_state == 0:
		var dir := (dest - global_position).normalized()
		if dir.length_squared() < 0.0001:
			_patrol_state = 1
			_patrol_idle_timer = wait_time_at_points
			velocity = Vector2.ZERO
			move_and_slide()
			return
		velocity = dir * patrol_speed
		move_and_slide()
		if global_position.distance_to(dest) < 12.0:
			velocity = Vector2.ZERO
			_patrol_state = 1
			_patrol_idle_timer = wait_time_at_points
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		_patrol_idle_timer -= delta
		if _patrol_idle_timer <= 0.0:
			_patrol_target_index = (_patrol_target_index + 1) % _patrol_points.size()
			_patrol_state = 0
