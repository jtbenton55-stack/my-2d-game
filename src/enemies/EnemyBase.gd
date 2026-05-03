extends CharacterBody2D

signal died(enemy)
## Emitted once when the enemy first gains line-of-sight while the player is in aggro range.
signal spotted_player()
signal health_changed(current: int, max_health: int)

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
@export var hit_recovery_delay: float = 0.42

var health := 40
var target: Node2D = null
var attack_timer := 0.0
var stunned_timer := 0.0
var detection_multiplier := 1.0
var _spotted_emitted := false
var _aware := false

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_tree().get_first_node_in_group("player") as Node2D
	health_changed.emit(health, max_health)

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

func is_aware() -> bool:
	return _aware


func instant_kill() -> void:
	if health <= 0:
		return
	health = 0
	health_changed.emit(health, max_health)
	_die()


func _update_ai(_delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	var effective_aggro_range := aggro_range
	if target.has_method("is_stealth_active") and target.is_stealth_active():
		effective_aggro_range *= stealth_aggro_multiplier
	if distance <= attack_range and _can_see_player():
		_aware = true
		velocity = Vector2.ZERO
		move_and_slide()
		_try_attack()
	elif distance <= effective_aggro_range and _can_see_player():
		_aware = true
		if not _spotted_emitted:
			_spotted_emitted = true
			spotted_player.emit()
		velocity = (target.global_position - global_position).normalized() * chase_speed
		move_and_slide()
	else:
		if distance > effective_aggro_range * 1.75:
			_spotted_emitted = false
			_aware = false
		_patrol_or_idle(_delta)

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
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

func take_damage(amount: int, source: Node = null) -> void:
	EventBus.debug("Guard hit.")
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	attack_timer = maxf(attack_timer, hit_recovery_delay)
	AudioManager.play_sfx("enemy_hit", global_position)
	if source is Node2D:
		var knock: Vector2 = (global_position - source.global_position).normalized() * 16.0
		global_position += knock
	if health <= 0:
		EventBus.debug("Guard defeated.")
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
