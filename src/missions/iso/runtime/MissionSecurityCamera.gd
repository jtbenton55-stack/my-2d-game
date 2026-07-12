class_name MissionSecurityCamera
extends Area2D

signal player_detected(source_id: String)

@export var camera_id: String = ""
@export var detection_rate: float = 0.7
@export var detection_decay: float = 0.4
@export var detection_threshold: float = 1.0
@export var exposure_requires_player_movement := false
@export var player_movement_threshold: float = 8.0
@export var sight_range: float = 180.0
@export var fov_angle_degrees: float = 70.0
@export var enabled := true
@export var sweep_min_degrees: float = -45.0
@export var sweep_max_degrees: float = 45.0
@export var sweep_speed: float = 0.85
@export var sweep_readability_label: String = ""
## When false, cone occupancy alone drives exposure (Taco: LOS often blocked by iso walls, leaving many cameras “dead”).
@export var require_line_of_sight: bool = false
@export_flags_2d_physics var occlusion_collision_mask: int = 4
@export var occlude_cover_tiles: bool = false
@export_range(3, 65, 2) var visible_cone_ray_count: int = 17
@export var show_visible_cone: bool = true

var _player: Node2D = null
var _detection_value := 0.0
var _controller: MissionAlertController = null
var _debug_cone: Polygon2D = null
var _base_rotation := 0.0
var _sweep_t := 0.0
var _camera_visual: Node2D = null
var _cover_layers: Array[TileMapLayer] = []
var _last_player_position := Vector2.ZERO
var _has_last_player_position := false


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
	_create_camera_visual()
	_create_debug_cone()
	call_deferred("_cache_cover_layers")
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
	exposure_requires_player_movement = bool(cfg.get("exposure_requires_player_movement", exposure_requires_player_movement))
	player_movement_threshold = float(cfg.get("player_movement_threshold", player_movement_threshold))
	enabled = bool(cfg.get("enabled", enabled))
	sweep_readability_label = String(cfg.get("sweep_readability_label", sweep_readability_label))
	require_line_of_sight = bool(cfg.get("require_line_of_sight", require_line_of_sight))
	occlusion_collision_mask = int(cfg.get("occlusion_collision_mask", occlusion_collision_mask))
	occlude_cover_tiles = bool(cfg.get("occlude_cover_tiles", occlude_cover_tiles))
	visible_cone_ray_count = int(cfg.get("visible_cone_ray_count", visible_cone_ray_count))
	show_visible_cone = bool(cfg.get("show_visible_cone", show_visible_cone))
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
		"require_line_of_sight": require_line_of_sight,
		"occlusion_collision_mask": occlusion_collision_mask,
		"occlude_cover_tiles": occlude_cover_tiles,
		"camera_exposure_allowed": _camera_exposure_allowed(),
		"exposure_requires_player_movement": exposure_requires_player_movement,
		"player_movement_threshold": player_movement_threshold,
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
	var player_observed := _player != null and is_instance_valid(_player) and _is_in_cone(_player.global_position) and _los_ok(_player.global_position)
	var exposure_allowed := player_observed and _camera_exposure_allowed()
	var movement_allows_exposure := _player_movement_allows_exposure(delta)
	if exposure_allowed and movement_allows_exposure:
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
	elif not exposure_allowed:
		## Local cone meter only — do NOT call MissionAlertController.decay_exposure here.
		## Multiple cameras each ran decay every frame while the player was outside their cone,
		## draining the shared alert_score and preventing alarms/spawns (D6-01-FIX2 regression).
		_detection_value = maxf(0.0, _detection_value - detection_decay * delta)
	if _debug_cone != null:
		_debug_cone.visible = show_visible_cone
		_update_visible_cone()


func set_camera_enabled(active: bool) -> void:
	enabled = active
	monitoring = active
	if _debug_cone != null:
		_debug_cone.visible = active and show_visible_cone
	if not enabled:
		_detection_value = 0.0
		if _player != null:
			_player = null
		_has_last_player_position = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node2D:
		_player = body
		_last_player_position = (body as Node2D).global_position
		_has_last_player_position = true


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_has_last_player_position = false


func _player_movement_allows_exposure(delta: float) -> bool:
	if not exposure_requires_player_movement:
		return true
	if _player == null or not is_instance_valid(_player):
		_has_last_player_position = false
		return false
	var current_position := _player.global_position
	var speed := 0.0
	if _player is CharacterBody2D:
		speed = (_player as CharacterBody2D).velocity.length()
	elif _has_last_player_position and delta > 0.0:
		speed = current_position.distance_to(_last_player_position) / delta
	_last_player_position = current_position
	_has_last_player_position = true
	return speed >= maxf(0.0, player_movement_threshold)


func _is_in_cone(target_position: Vector2) -> bool:
	var to_target := target_position - global_position
	if to_target.length() > sight_range:
		return false
	var facing := Vector2.RIGHT.rotated(global_rotation)
	var angle := facing.angle_to(to_target)
	return absf(angle) <= deg_to_rad(fov_angle_degrees * 0.5)


func _has_los(target_position: Vector2) -> bool:
	if occlusion_collision_mask != 0:
		var query := PhysicsRayQueryParameters2D.create(global_position, target_position)
		query.exclude = [get_rid()]
		query.collision_mask = occlusion_collision_mask
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			return false
	return not occlude_cover_tiles or _cover_ray_endpoint(target_position).is_equal_approx(target_position)


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


func has_line_of_sight_to(target_position: Vector2) -> bool:
	return _has_los(target_position)


func _camera_exposure_allowed() -> bool:
	if _controller == null or not is_instance_valid(_controller):
		return true
	return _controller.should_camera_accumulate_exposure(_player, camera_id)


func get_detection_value() -> float:
	return _detection_value


func _create_debug_cone() -> void:
	_debug_cone = Polygon2D.new()
	_debug_cone.name = "DetectionCone"
	_debug_cone.color = Color(0.9, 0.2, 0.2, 0.11)
	_debug_cone.z_index = -1
	add_child(_debug_cone)
	_update_visible_cone()


func _update_visible_cone() -> void:
	if _debug_cone == null or not is_inside_tree():
		return
	var points := PackedVector2Array([Vector2.ZERO])
	var ray_count := maxi(3, visible_cone_ray_count)
	var half := deg_to_rad(fov_angle_degrees * 0.5)
	for index in range(ray_count):
		var weight := float(index) / float(ray_count - 1)
		var angle := lerpf(-half, half, weight)
		points.append(_visible_ray_endpoint(angle))
	_debug_cone.polygon = points


func _visible_ray_endpoint(local_angle: float) -> Vector2:
	var local_end := Vector2.RIGHT.rotated(local_angle) * sight_range
	if not require_line_of_sight:
		return local_end
	var endpoint := to_global(local_end)
	if occlusion_collision_mask != 0:
		var query := PhysicsRayQueryParameters2D.create(global_position, endpoint)
		query.exclude = [get_rid()]
		query.collision_mask = occlusion_collision_mask
		var result := get_world_2d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			endpoint = result.get("position")
	if occlude_cover_tiles:
		endpoint = _cover_ray_endpoint(endpoint)
	return to_local(endpoint)


func _cache_cover_layers() -> void:
	_cover_layers.clear()
	if not occlude_cover_tiles or get_tree() == null or get_tree().current_scene == null:
		return
	for candidate: Node in get_tree().current_scene.find_children("*CoverLayer*", "TileMapLayer", true, false):
		if candidate is TileMapLayer:
			_cover_layers.append(candidate as TileMapLayer)


func _cover_ray_endpoint(target_position: Vector2) -> Vector2:
	if _cover_layers.is_empty():
		return target_position
	var delta := target_position - global_position
	var distance := delta.length()
	if distance <= 0.01:
		return target_position
	var step_count := maxi(1, ceili(distance / 12.0))
	for step in range(1, step_count + 1):
		var point := global_position.lerp(target_position, float(step) / float(step_count))
		for layer: TileMapLayer in _cover_layers:
			var cell := layer.local_to_map(layer.to_local(point))
			if layer.get_cell_source_id(cell) >= 0:
				return global_position.lerp(target_position, float(maxi(0, step - 1)) / float(step_count))
	return target_position


func get_visible_cone_points() -> PackedVector2Array:
	return _debug_cone.polygon.duplicate() if _debug_cone != null else PackedVector2Array()


func _create_camera_visual() -> void:
	if _camera_visual != null:
		return
	_camera_visual = Node2D.new()
	_camera_visual.name = "CameraVisual"
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.12, 0.14, 0.17, 1.0)
	body.polygon = PackedVector2Array([Vector2(-12, -8), Vector2(9, -8), Vector2(14, 0), Vector2(9, 8), Vector2(-12, 8)])
	_camera_visual.add_child(body)
	var lens := Polygon2D.new()
	lens.name = "Lens"
	lens.position = Vector2(10, 0)
	lens.color = Color(0.25, 0.85, 1.0, 1.0)
	lens.polygon = PackedVector2Array([Vector2(0, -4), Vector2(6, -2), Vector2(6, 2), Vector2(0, 4)])
	_camera_visual.add_child(lens)
	add_child(_camera_visual)
