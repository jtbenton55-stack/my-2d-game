extends CharacterBody2D

signal died(enemy)

@export var max_health := 40
@export var speed := 120.0
@export var chase_speed := 180.0
@export var acceleration := 10.0
@export var detection_range := 200.0
@export var attack_damage := 8
@export var attack_range := 42.0
@export var aggro_range := 240.0
@export var attack_cooldown := 0.8

var health := 40
var target: Node2D = null
var attack_timer := 0.0
var stunned_timer := 0.0

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	target = get_tree().get_first_node_in_group("player") as Node2D

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

func _update_ai(delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		_try_attack()
	elif distance <= aggro_range:
		velocity = (target.global_position - global_position).normalized() * chase_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

func take_damage(amount: int, source: Node = null) -> void:
	health = max(0, health - amount)
	AudioManager.play_sfx("enemy_hit", global_position)
	if source is Node2D:
		var knock := (global_position - source.global_position).normalized() * 16.0
		global_position += knock
	if health <= 0:
		_die()

func stun(duration: float) -> void:
	stunned_timer = max(stunned_timer, duration)

func _die() -> void:
	died.emit(self)
	queue_free()
