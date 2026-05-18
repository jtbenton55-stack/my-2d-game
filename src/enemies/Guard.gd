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

const AUTHORING_CHASE_MAX_DISTANCE := 480.0
const AUTHORING_CHASE_MAX_SECONDS := 14.0
const AUTHORING_DEBUG_CONE_RANGE := 140.0

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


## D6-03: apply hand-placed guard spawn behavior from GuardSpawnAuthor.
func _update_ai(delta: float) -> void:
	if has_meta("authoring_force_chase") and bool(get_meta("authoring_force_chase")):
		if _authoring_chase_should_end():
			_enter_authoring_fallback()
			super._update_ai(delta)
			return
		if target == null or not is_instance_valid(target):
			target = get_tree().get_first_node_in_group("player") as Node2D
		if target != null:
			var distance := global_position.distance_to(target.global_position)
			if distance <= attack_range:
				_aware = true
				velocity = Vector2.ZERO
				move_and_slide()
				_try_attack()
				return
			_aware = true
			if not _spotted_emitted:
				_spotted_emitted = true
				spotted_player.emit()
			var dir := (target.global_position - global_position).normalized()
			velocity = dir * chase_speed
			move_and_slide()
			return
		_enter_authoring_fallback()
		super._update_ai(delta)
		return
	super._update_ai(delta)


func apply_authoring_spawn_behavior(behavior: StringName, payload: Dictionary = {}) -> void:
	var behavior_key := String(behavior).strip_edges().to_lower()
	set_meta("authoring_initial_behavior", behavior_key)
	set_meta("authoring_behavior_payload", payload)
	var fallback_key := String(payload.get("fallback_behavior", "")).strip_edges().to_lower()
	if fallback_key != "":
		set_meta("authoring_fallback_behavior", fallback_key)
	match behavior_key:
		"attack_player":
			remove_meta("authoring_fallback_entered")
			target = get_tree().get_first_node_in_group("player") as Node2D
			_aware = true
			_spotted_emitted = true
			_security_search_net_active = false
			set_meta("authoring_force_chase", true)
			set_meta("authoring_chase_started_msec", Time.get_ticks_msec())
			set_meta("authoring_debug_cone_range", AUTHORING_DEBUG_CONE_RANGE)
		"patrol":
			set_meta("authoring_force_chase", false)
			var pts_v: Variant = payload.get("patrol_points", [])
			if pts_v is Array:
				assign_patrol_points_world(pts_v as Array, bool(payload.get("loop_route", true)))
			else:
				set_meta("authoring_patrol_missing", true)
		"investigate":
			var pos: Vector2 = payload.get("investigate_position", global_position)
			assign_patrol_points_world([global_position, pos], false)
		"guard_post":
			assign_patrol_points_world([global_position], true)
		"security_net", "join_security_net":
			set_meta("authoring_force_chase", false)
			remove_meta("authoring_debug_cone_range")
			var net_v: Variant = payload.get("search_net", {})
			if net_v is Dictionary and not (net_v as Dictionary).is_empty():
				apply_security_search_net(net_v as Dictionary)
			elif has_meta("authoring_fallback_entered"):
				assign_patrol_points_world([global_position, global_position + Vector2(48.0, 0.0)], true)
		_:
			pass


func _authoring_chase_should_end() -> bool:
	var started := int(get_meta("authoring_chase_started_msec", 0))
	if started > 0 and Time.get_ticks_msec() - started > int(AUTHORING_CHASE_MAX_SECONDS * 1000.0):
		return true
	if target == null or not is_instance_valid(target):
		return true
	return global_position.distance_to(target.global_position) > AUTHORING_CHASE_MAX_DISTANCE


func _enter_authoring_fallback() -> void:
	if has_meta("authoring_fallback_entered") and bool(get_meta("authoring_fallback_entered")):
		set_meta("authoring_force_chase", false)
		return
	var payload_v: Variant = get_meta("authoring_behavior_payload", {})
	var payload := payload_v as Dictionary if payload_v is Dictionary else {}
	var fallback_key := String(get_meta("authoring_fallback_behavior", payload.get("fallback_behavior", "security_net")))
	set_meta("authoring_force_chase", false)
	remove_meta("authoring_debug_cone_range")
	remove_meta("authoring_chase_started_msec")
	_spotted_emitted = false
	_aware = false
	set_meta("authoring_fallback_entered", true)
	apply_authoring_spawn_behavior(StringName(fallback_key), payload)


func get_authoring_debug_state() -> Dictionary:
	var fb_entered := has_meta("authoring_fallback_entered") and bool(get_meta("authoring_fallback_entered"))
	fb_entered = fb_entered or _security_search_net_active
	return {
		"force_chase": has_meta("authoring_force_chase") and bool(get_meta("authoring_force_chase")),
		"fallback_behavior": String(get_meta("authoring_fallback_behavior", "")),
		"fallback_entered": fb_entered,
		"chase_max_distance": AUTHORING_CHASE_MAX_DISTANCE,
		"chase_max_seconds": AUTHORING_CHASE_MAX_SECONDS,
		"debug_cone_range": float(get_meta("authoring_debug_cone_range", aggro_range)),
		"aggro_range": aggro_range,
	}


func assign_patrol_points_world(points: Array, loop: bool = true) -> void:
	_patrol_points.clear()
	for p in points:
		if p is Vector2:
			_patrol_points.append(p as Vector2)
	if _patrol_points.size() < 2:
		if _patrol_points.size() == 1:
			_patrol_points.append(_patrol_points[0] + Vector2(24.0, 0.0))
		else:
			return
	_security_search_net_active = false
	_patrol_state = 0
	_patrol_idle_timer = 0.0
	global_position = _patrol_points[0]
	_patrol_target_index = 1 % _patrol_points.size()
	set_meta("authoring_patrol_loop", loop)


func apply_archetype_metadata(archetype: StringName) -> void:
	var key := String(archetype).strip_edges().to_lower()
	set_meta("guard_archetype", key)
	match key:
		"fast":
			patrol_speed = 130.0
			chase_speed = 220.0
		"tough":
			max_health = 60
			health = max_health
			health_changed.emit(health, max_health)
		_:
			pass


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
