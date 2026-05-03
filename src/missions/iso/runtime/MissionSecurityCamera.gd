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

var _player: Node2D = null
var _detection_value := 0.0
var _controller: MissionAlertController = null
var _debug_cone: Polygon2D = null


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
	set_process(true)


func _process(delta: float) -> void:
	if not enabled:
		return
	if _player != null and is_instance_valid(_player) and _is_in_cone(_player.global_position) and _has_los(_player.global_position):
		var mod := 1.0
		if _controller != null:
			mod = _controller.player_detection_modifier
		_detection_value = clampf(_detection_value + detection_rate * mod * delta, 0.0, 2.0)
		if _detection_value >= detection_threshold:
			player_detected.emit(camera_id)
			EventBus.debug("Camera detected player: " + camera_id)
			if _controller != null:
				_controller.register_detection_event(camera_id, 1.0, "camera_detected")
			_detection_value = 0.0
	else:
		_detection_value = maxf(0.0, _detection_value - detection_decay * delta)


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
