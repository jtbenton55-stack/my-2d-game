class_name MissionSecurityCamera
extends Area2D

signal player_detected(source_id: String)

@export var camera_id: String = ""
@export var detection_rate: float = 0.7
@export var detection_decay: float = 0.4
@export var detection_threshold: float = 1.0
@export var sight_range: float = 180.0
@export var fov_angle_degrees: float = 70.0
@export var enabled := true
@export var sweep_min_degrees: float = -45.0
@export var sweep_max_degrees: float = 45.0
@export var sweep_speed: float = 0.85
## When false, cone occupancy alone drives exposure (Taco: LOS often blocked by iso walls, leaving many cameras “dead”).
@export var require_line_of_sight: bool = false

var _player: Node2D = null
var _detection_value := 0.0
var _controller: MissionAlertController = null
var _debug_cone: Polygon2D = null
var _base_rotation := 0.0
var _sweep_t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("iso_security_camera")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = sight_range
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_controller = _find_controller()
	_create_debug_cone()
	## Sweep basis must reflect final world placement (Phase0K used to parent before moving).
	call_deferred("refresh_sweep_basis_from_world")
	set_process(true)


func refresh_sweep_basis_from_world() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_base_rotation = global_rotation
	var h := hash(camera_id)
	_sweep_t = absf(float(h % 997)) * 0.01


func _process(delta: float) -> void:
	if not enabled:
		return
	_ensure_controller()
	_sweep_t += delta * sweep_speed
	var span := clampf(sweep_max_degrees - sweep_min_degrees, 1.0, 180.0)
	var center := (sweep_max_degrees + sweep_min_degrees) * 0.5
	var amp := span * 0.5
	global_rotation = _base_rotation + deg_to_rad(center + sin(_sweep_t) * amp)
	if _player != null and is_instance_valid(_player) and _is_in_cone(_player.global_position) and _los_ok(_player.global_position):
		var mod := 1.0
		if _controller != null:
			mod = _controller.player_detection_modifier
		_detection_value = clampf(_detection_value + detection_rate * mod * delta, 0.0, 2.0)
		if _controller != null:
			_controller.accumulate_exposure(camera_id, detection_rate * mod * delta, "camera_detected")
		if _detection_value >= detection_threshold:
			player_detected.emit(camera_id)
			EventBus.debug("Camera detected player: " + camera_id)
			_detection_value = 0.0
	else:
		## Local cone meter only — do NOT call MissionAlertController.decay_exposure here.
		## Multiple cameras each ran decay every frame while the player was outside their cone,
		## draining the shared alert_score and preventing alarms/spawns (D6-01-FIX2 regression).
		_detection_value = maxf(0.0, _detection_value - detection_decay * delta)
	if _debug_cone != null:
		_debug_cone.visible = OS.is_debug_build()


func set_camera_enabled(active: bool) -> void:
	enabled = active
	monitoring = active
	if not enabled:
		_detection_value = 0.0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node2D:
		_player = body


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null


func _is_in_cone(target_position: Vector2) -> bool:
	var to_target := target_position - global_position
	if to_target.length() > sight_range:
		return false
	var facing := Vector2.RIGHT.rotated(global_rotation)
	var angle := facing.angle_to(to_target)
	return absf(angle) <= deg_to_rad(fov_angle_degrees * 0.5)


func _has_los(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position)
	query.exclude = [get_rid()]
	query.collision_mask = 5
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == _player


func _find_controller() -> MissionAlertController:
	var node := get_tree().get_first_node_in_group("iso_alert_controller")
	if node is MissionAlertController:
		return node
	return null


func _ensure_controller() -> void:
	if _controller != null and is_instance_valid(_controller):
		return
	_controller = _find_controller()


func _los_ok(target_position: Vector2) -> bool:
	if not require_line_of_sight:
		return true
	return _has_los(target_position)


func get_detection_value() -> float:
	return _detection_value


func _create_debug_cone() -> void:
	if not OS.is_debug_build():
		return
	_debug_cone = Polygon2D.new()
	_debug_cone.color = Color(0.9, 0.2, 0.2, 0.15)
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	var half := deg_to_rad(fov_angle_degrees * 0.5)
	points.append(Vector2.RIGHT.rotated(-half) * sight_range)
	points.append(Vector2.RIGHT.rotated(half) * sight_range)
	_debug_cone.polygon = points
	add_child(_debug_cone)
