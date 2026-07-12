extends "res://src/enemies/EnemyBase.gd"

const InspectionRuleSetScript := preload("res://src/missions/iso/social/InspectionRuleSet.gd")

@export var patrol_speed := 100.0
@export var wait_time_at_points := 2.0
@export_group("Social Cover")
@export var inspection_rule_set: InspectionRuleSet
@export var social_cover_mission_id: String = ""
@export var ignore_social_cover: bool = false

@export_group("Noise Investigation")
@export var decoy_inspection_seconds: float = 3.0
@export var noise_attention_threshold: float = 1.0
@export var noise_attention_decay: float = 0.5

var _patrol_points: Array[Vector2] = []
var _patrol_target_index := 0
var _patrol_state := 0
var _patrol_idle_timer := 0.0
var _security_search_net_active := false
var _noise_attention := 0.0
var _investigation_state := "idle"
var _investigate_position := Vector2.ZERO
var _investigate_timer := 0.0
var _resume_patrol_index := 0
var _hostile_on_player_enter_rect := Rect2()

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
	_noise_attention = maxf(0.0, _noise_attention - noise_attention_decay * delta)
	if not is_hostile() and target != null and is_instance_valid(target) and _hostile_on_player_enter_rect.has_area():
		if _hostile_on_player_enter_rect.has_point(target.global_position):
			set_hostile(true)
	if _investigation_state != "idle":
		if is_hostile() or is_aware():
			_cancel_noise_investigation()
		else:
			_update_noise_investigation(delta)
			return
	if has_meta("authoring_force_chase") and bool(get_meta("authoring_force_chase")):
		if _authoring_chase_should_end():
			_enter_authoring_fallback()
			super._update_ai(delta)
			return
		if target == null or not is_instance_valid(target):
			target = get_tree().get_first_node_in_group("player") as Node2D
		if _target_is_hidden():
			_enter_authoring_fallback()
			super._update_ai(delta)
			return
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
			set_hostile(true)
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


func apply_guard_authoring_config(config: Dictionary) -> void:
	if float(config.get("detection_range", -1.0)) >= 0.0:
		detection_range = float(config.get("detection_range"))
	if float(config.get("vision_angle_degrees", -1.0)) >= 0.0:
		debug_cone_angle_degrees = float(config.get("vision_angle_degrees"))
	if float(config.get("detection_speed", -1.0)) >= 0.0:
		detection_speed = float(config.get("detection_speed"))
	if float(config.get("detection_decay", -1.0)) >= 0.0:
		detection_decay = float(config.get("detection_decay"))
	if float(config.get("detection_threshold", -1.0)) > 0.0:
		detection_threshold = float(config.get("detection_threshold"))
	var rules: Variant = config.get("inspection_rule_set")
	if rules is InspectionRuleSetScript:
		inspection_rule_set = rules
	social_cover_mission_id = String(config.get("social_cover_mission_id", social_cover_mission_id))
	ignore_social_cover = bool(config.get("ignore_social_cover", ignore_social_cover))
	var hostile_rect: Variant = config.get("hostile_on_player_enter_rect", Rect2())
	if hostile_rect is Rect2:
		_hostile_on_player_enter_rect = hostile_rect
	_update_vision_cone_visual()


func on_noise_heard(noise_event: Dictionary, listener: Node = null) -> Dictionary:
	var kind := String(noise_event.get("kind", "generic"))
	var team := String(noise_event.get("team", "neutral"))
	if is_hostile() or is_aware() or (has_meta("authoring_force_chase") and bool(get_meta("authoring_force_chase"))):
		return {"ok": false, "code": "guard_ignored_noise_in_combat", "kind": kind}
	if team != "player":
		return {"ok": false, "code": "guard_ignored_non_player_noise", "kind": kind}
	_noise_attention += maxf(0.0, float(noise_event.get("strength", 0.0)))
	if kind in ["decoy", "poop_decoy"] or _noise_attention >= noise_attention_threshold:
		_begin_noise_investigation(noise_event.get("position", global_position))
		return {
			"ok": true,
			"code": "guard_investigating_noise",
			"kind": kind,
			"investigate_position": _investigate_position,
			"listener_id": String(listener.get("listener_id")) if listener != null else "",
		}
	return {"ok": true, "code": "guard_noise_attention_accumulated", "kind": kind, "attention": _noise_attention}


func get_noise_investigation_state() -> Dictionary:
	return {
		"state": _investigation_state,
		"position": _investigate_position,
		"resume_patrol_index": _resume_patrol_index,
		"patrol_target_index": _patrol_target_index,
		"attention": _noise_attention,
	}


func _begin_noise_investigation(position: Vector2) -> void:
	_resume_patrol_index = _patrol_target_index
	_investigate_position = position
	_investigate_timer = decoy_inspection_seconds
	_investigation_state = "traveling"
	set_meta("noise_reaction_state", _investigation_state)
	set_meta("noise_investigate_position", position)


func _update_noise_investigation(delta: float) -> void:
	if _investigation_state == "traveling":
		var offset := _investigate_position - global_position
		if offset.length() <= 12.0:
			velocity = Vector2.ZERO
			move_and_slide()
			_investigation_state = "inspecting"
			set_meta("noise_reaction_state", _investigation_state)
			return
		velocity = offset.normalized() * patrol_speed
		move_and_slide()
		return
	velocity = Vector2.ZERO
	move_and_slide()
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		_cancel_noise_investigation()


func _cancel_noise_investigation() -> void:
	_investigation_state = "idle"
	_noise_attention = 0.0
	if not _patrol_points.is_empty():
		_patrol_target_index = clampi(_resume_patrol_index, 0, _patrol_points.size() - 1)
	_patrol_state = 0
	set_meta("noise_reaction_state", _investigation_state)


func _should_suppress_innocent_detection() -> bool:
	if ignore_social_cover or inspection_rule_set == null or is_hostile():
		return false
	return bool(inspection_rule_set.evaluate({"mission_id": social_cover_mission_id}).get("ok", false))


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
