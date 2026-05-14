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
var _security_search_net_active := false

func _ready() -> void:
	super._ready()

## Call from mission code with a scene Path2D; uses world-space points from the curve.
func assign_patrol_path(path_node: Path2D) -> void:
	_patrol_points.clear()
	_patrol_state = 0
	_patrol_idle_timer = 0.0
	_security_search_net_active = false
	if path_node == null or path_node.curve == null:
		return
	for i in range(path_node.curve.point_count):
		_patrol_points.append(path_node.to_global(path_node.curve.get_point_position(i)))
	if _patrol_points.size() < 2:
		return
	global_position = _patrol_points[0]
	_patrol_target_index = 1 % _patrol_points.size()


## D6-01-FIX7: apply an explicit local search-net route for security-response guards.
## This avoids default patrol restoration and keeps fallback near the encounter area.
func apply_security_search_net(search_net: Dictionary) -> void:
	var points_v: Variant = search_net.get("route_points", [])
	if not (points_v is Array):
		return
	var points := points_v as Array
	if points.size() < 2:
		return
	_patrol_points.clear()
	for p in points:
		if p is Vector2:
			_patrol_points.append(p as Vector2)
	if _patrol_points.size() < 2:
		return
	_patrol_state = 0
	_patrol_idle_timer = 0.0
	_security_search_net_active = true
	var direction := int(search_net.get("direction", 1))
	if direction < 0:
		_patrol_target_index = _patrol_points.size() - 1
	else:
		_patrol_target_index = 1 % _patrol_points.size()
	set_meta("security_search_net_active", true)
	set_meta("security_search_direction", direction)
	set_meta("security_search_route_points_count", _patrol_points.size())
	if search_net.has("role"):
		set_meta("security_search_role", String(search_net.get("role", "")))
	if search_net.has("ordinal"):
		set_meta("security_search_ordinal", int(search_net.get("ordinal", -1)))

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
