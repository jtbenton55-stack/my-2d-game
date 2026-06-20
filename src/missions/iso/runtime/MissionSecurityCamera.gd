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
@export var sweep_readability_label: String = ""
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
	monitoring = enabled
	monitorable = false
	add_to_group("iso_security_camera")
	_ensure_detection_shape()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_controller = _find_controller()
	_create_debug_cone()
	## Sweep basis must reflect final world placement (Phase0K used to parent before moving).
	call_deferred("refresh_sweep_basis_from_world")
	call_deferred("_sync_initial_overlaps")
	set_process(true)


## Shared runtime config for Phase0K markers and SecurityCameraAuthor (parity path).
func apply_authoring_config(cfg: Dictionary) -> void:
	camera_id = String(cfg.get("camera_id", camera_id))
	sight_range = float(cfg.get("range_px", cfg.get("sight_range", sight_range)))
	fov_angle_degrees = float(cfg.get("fov_degrees", cfg.get("fov_angle_degrees", fov_angle_degrees)))
	detection_rate = float(cfg.get("detection_rate", detection_rate))
	detection_decay = float(cfg.get("detection_decay", detection_decay))
	detection_threshold = float(cfg.get("alarm_threshold", cfg.get("detection_threshold", detection_threshold)))
	enabled = bool(cfg.get("enabled", enabled))
	sweep_readability_label = String(cfg.get("sweep_readability_label", sweep_readability_label))
	require_line_of_sight = bool(cfg.get("require_line_of_sight", require_line_of_sight))
	var sweep_on := bool(cfg.get("sweep_enabled", false))
	if sweep_on:
		var arc := float(cfg.get("sweep_arc_degrees", 90.0))
		sweep_min_degrees = -arc * 0.5
		sweep_max_degrees = arc * 0.5
		var spd_deg := float(cfg.get("sweep_speed_degrees", 45.0))
		sweep_speed = maxf(0.15, spd_deg * 0.02)
	else:
		sweep_min_degrees = float(cfg.get("sweep_min_degrees", 0.0))
		sweep_max_degrees = float(cfg.get("sweep_max_degrees", 0.0))
		sweep_speed = float(cfg.get("sweep_speed", 0.0))
	monitoring = enabled
	_update_detection_shape_radius()
	if _debug_cone != null:
		_debug_cone.queue_free()
		_debug_cone = null
	_create_debug_cone()


func _ensure_detection_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)
	var circle := shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle
	circle.radius = sight_range


func _update_detection_shape_radius() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is CircleShape2D):
		return
	(shape_node.shape as CircleShape2D).radius = sight_range


func _sync_initial_overlaps() -> void:
	if not is_inside_tree() or not monitoring:
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func is_player_in_cone() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return _is_in_cone(_player.global_position) and _los_ok(_player.global_position)


func get_runtime_debug_state() -> Dictionary:
	var state := {
		"camera_id": camera_id,
		"class_name": get_class(),
		"enabled": enabled,
		"monitoring": monitoring,
		"sight_range": sight_range,
		"fov_angle_degrees": fov_angle_degrees,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
		"has_shape": get_node_or_null("CollisionShape2D") != null,
		"player_tracked": _player != null and is_instance_valid(_player),
		"player_in_cone": is_player_in_cone(),
		"detection_value": _detection_value,
		"controller_found": _controller != null,
	}
	state["sweep"] = get_sweep_debug_state()
	state["sweep_readability_line"] = get_sweep_readability_line()
	return state


func get_sweep_debug_state() -> Dictionary:
	var span := maxf(0.0, sweep_max_degrees - sweep_min_degrees)
	return {
		"enabled": sweep_speed > 0.0 and span > 0.01,
		"min_degrees": sweep_min_degrees,
		"max_degrees": sweep_max_degrees,
		"span_degrees": span,
		"speed": sweep_speed,
		"loop_seconds": get_sweep_loop_seconds(),
		"base_rotation_degrees": rad_to_deg(_base_rotation),
		"current_rotation_degrees": rad_to_deg(global_rotation),
		"label": sweep_readability_label,
	}


func get_sweep_loop_seconds() -> float:
	if sweep_speed <= 0.0:
		return 0.0
	return TAU / sweep_speed


func get_sweep_readability_line() -> String:
	var label := sweep_readability_label.strip_edges()
	if label == "":
		label = camera_id
	var span := maxf(0.0, sweep_max_degrees - sweep_min_degrees)
	if sweep_speed <= 0.0 or span <= 0.01:
		return "%s: fixed camera cone" % label
	return "%s: sweeps %.0f deg every %.1fs" % [label, span, get_sweep_loop_seconds()]


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
		if _player != null:
			_player = null


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
