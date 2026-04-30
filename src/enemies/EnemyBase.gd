extends CharacterBody2D

signal died(enemy)
## Emitted once when the enemy first gains line-of-sight while the player is in aggro range.
signal spotted_player()

@export var max_health := 40
@export var speed := 120.0
@export var chase_speed := 180.0
@export var acceleration := 10.0
@export var detection_range := 200.0
@export var attack_damage := 8
@export var attack_range := 42.0
@export var aggro_range := 120.0
@export var attack_cooldown := 0.8
@export var stealth_aggro_multiplier := 0.35

var health := 40
var target: Node2D = null
var attack_timer := 0.0
var stunned_timer := 0.0
var detection_multiplier := 1.0
var _spotted_emitted := false
var _agent_debug_ai_samples := 0

#region agent log
func _agent_debug_log(hypothesis_id: String, message: String, data: Dictionary = {}) -> void:
	if name != "ClubOwner":
		return
	var payload := {
		"sessionId": "755971",
		"runId": "initial",
		"hypothesisId": hypothesis_id,
		"location": "src/enemies/EnemyBase.gd",
		"message": message,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	var path := "res://debug-755971.log"
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE_READ)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(payload))
		file.close()
#endregion

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_tree().get_first_node_in_group("player") as Node2D
	_agent_debug_log("H4", "enemy ready target acquisition", {
		"self_pos": global_position,
		"target_valid": is_instance_valid(target),
		"target_pos": target.global_position if is_instance_valid(target) else Vector2.ZERO,
		"max_health": max_health,
		"aggro_range": aggro_range,
		"chase_speed": chase_speed,
		"process_mode": process_mode
	})

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta
	if stunned_timer > 0.0:
		stunned_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D
	_update_ai(delta)

func _update_ai(_delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	var effective_aggro_range := aggro_range
	if target.has_method("is_stealth_active") and target.is_stealth_active():
		effective_aggro_range *= stealth_aggro_multiplier
	var can_see := _can_see_player()
	var branch := "idle"
	if distance <= attack_range and can_see:
		branch = "attack"
		velocity = Vector2.ZERO
		move_and_slide()
		_try_attack()
	elif distance <= effective_aggro_range and can_see:
		branch = "chase"
		if not _spotted_emitted:
			_spotted_emitted = true
			spotted_player.emit()
		velocity = (target.global_position - global_position).normalized() * chase_speed
		move_and_slide()
	else:
		if distance > effective_aggro_range * 1.75:
			_spotted_emitted = false
		_patrol_or_idle(_delta)
	if name == "ClubOwner" and _agent_debug_ai_samples < 5:
		_agent_debug_ai_samples += 1
		_agent_debug_log("H4,H5", "club owner ai sample", {
			"sample": _agent_debug_ai_samples,
			"branch": branch,
			"self_pos": global_position,
			"target_valid": is_instance_valid(target),
			"target_pos": target.global_position if is_instance_valid(target) else Vector2.ZERO,
			"distance": distance,
			"aggro_range": aggro_range,
			"effective_aggro_range": effective_aggro_range,
			"attack_range": attack_range,
			"can_see": can_see,
			"velocity": velocity
		})

func _can_see_player() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.exclude = [get_rid()]
	query.collision_mask = 3
	var result := space.intersect_ray(query)
	if result.is_empty():
		return true
	return result.get("collider") == target

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	_agent_debug_log("H5", "club owner attack attempt", {
		"target_valid": is_instance_valid(target),
		"target_pos": target.global_position if is_instance_valid(target) else Vector2.ZERO,
		"self_pos": global_position,
		"damage": attack_damage
	})
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

func take_damage(amount: int, source: Node = null) -> void:
	health = max(0, health - amount)
	_agent_debug_log("H5", "club owner took damage", {
		"amount": amount,
		"health": health,
		"source": String(source.name) if source else ""
	})
	AudioManager.play_sfx("enemy_hit", global_position)
	if source is Node2D:
		var knock: Vector2 = (global_position - source.global_position).normalized() * 16.0
		global_position += knock
	if health <= 0:
		_die()

func stun(duration: float) -> void:
	stunned_timer = max(stunned_timer, duration)

func _die() -> void:
	died.emit(self)
	queue_free()

func set_detection_multiplier(mult: float) -> void:
	detection_multiplier = mult
	# Adjust detection range
	detection_range *= mult

func _patrol_or_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
