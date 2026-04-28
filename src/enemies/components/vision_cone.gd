extends Area2D

@export var sight_range: float = 150.0
@export var fov_angle_degrees: float = 60.0
@export var alert_increase_speed: float = 0.45
@export var alert_decrease_speed: float = 0.75
@export var emit_once_until_cleared := true

var player_body: Node2D
var alert_level := 0.0
var has_emitted_full_alert := false

signal alert_full(player: Node2D)

func _ready() -> void:
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = sight_range
	col_shape.shape = circle
	add_child(col_shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if player_body != null and _is_within_cone():
		var stealth_multiplier := 1.0
		if player_body.has_method("is_stealth_active") and player_body.is_stealth_active():
			stealth_multiplier = 0.35
		alert_level = clamp(alert_level + alert_increase_speed * stealth_multiplier * delta, 0.0, 1.0)
		if alert_level >= 1.0 and (not has_emitted_full_alert or not emit_once_until_cleared):
			has_emitted_full_alert = true
			alert_full.emit(player_body)
	else:
		alert_level = max(alert_level - alert_decrease_speed * delta, 0.0)
		if alert_level <= 0.0:
			has_emitted_full_alert = false

func _is_within_cone() -> bool:
	if player_body == null:
		return false
	var to_player := player_body.global_position - global_position
	if to_player.length() > sight_range:
		return false
	var forward := Vector2.RIGHT.rotated(global_rotation)
	var angle := forward.angle_to(to_player)
	return abs(angle) <= deg_to_rad(fov_angle_degrees * 0.5) and _has_line_of_sight()

func _has_line_of_sight() -> bool:
	if player_body == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player_body.global_position)
	var exclude: Array[RID] = [get_rid()]
	var parent_body := get_parent() as CollisionObject2D
	if parent_body != null:
		exclude.append(parent_body.get_rid())
	query.exclude = exclude
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == player_body

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node2D:
		player_body = body

func _on_body_exited(body: Node) -> void:
	if body == player_body:
		player_body = null
