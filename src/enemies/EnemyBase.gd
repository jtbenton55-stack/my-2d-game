# EnemyBase.gd
# Base class for all enemies with common functionality

extends CharacterBody2D
class_name EnemyBase

# Health
@export var max_health: int = 50
var health: int = max_health

# States
enum State {
	IDLE,
	PATROL,
	ALERT,
	CHASE,
	ATTACK,
	DEAD
}
var current_state: State = State.IDLE

# Detection
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
var target: Node2D = null
var last_known_position: Vector2 = Vector2.ZERO

# Movement
@export var speed: float = 150.0
@export var chase_speed: float = 250.0
@export var acceleration: float = 10.0

# Attack
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

# Components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $VisionArea
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	EventBus.debug(name + " enemy loaded")

func _process(delta: float) -> void:
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update animation
	_update_animation()

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.ALERT:
			_state_alert(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.DEAD:
			_state_dead(delta)
	
	move_and_slide()

# State handlers (to be overridden by specific enemies)
func _state_idle(delta: float) -> void:
	pass

func _state_patrol(delta: float) -> void:
	pass

func _state_alert(delta: float) -> void:
	pass

func _state_chase(delta: float) -> void:
	pass

func _state_attack(delta: float) -> void:
	pass

func _state_dead(delta: float) -> void:
	pass

# Damage handling
func take_damage(amount: int, source: Node = null) -> void:
	health -= amount
	
	EventBus.damage_dealt.emit(source, self, amount)
	EventBus.debug(name + " took " + str(amount) + " damage")
	
	if health <= 0:
		die()
	else:
		# Alert on taking damage
		if source and source.is_in_group("player"):
			target = source
			last_known_position = source.global_position
			_change_state(State.ALERT)

func die() -> void:
	_change_state(State.DEAD)
	EventBus.enemy_died.emit(self)
	EventBus.debug(name + " died")
	
	# In a real game, this would play death animation and drop loot
	queue_free()

# State management
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		State.ATTACK:
			_exit_attack_state()
	
	# Enter new state
	current_state = new_state
	EventBus.debug(name + " changed state to " + str(new_state))
	
	match new_state:
		State.ATTACK:
			_enter_attack_state()

func _exit_attack_state() -> void:
	attack_area.monitoring = false

func _enter_attack_state() -> void:
	attack_area.monitoring = true

# Target detection
func _on_vision_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target = body
		EventBus.enemy_spotted_player.emit(self, target)
		_change_state(State.ALERT)

func _on_vision_area_body_exited(body: Node) -> void:
	if body == target:
		last_known_position = target.global_position
		target = null
		EventBus.enemy_lost_player.emit(self)

# Attack handling
func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and attack_timer <= 0:
		attack_timer = attack_cooldown
		body.take_damage(attack_damage, self)
		EventBus.debug(name + " attacked player")

# Animation
func _update_animation() -> void:
	if current_state == State.DEAD:
		sprite.animation = "dead"
	elif current_state == State.ATTACK:
		sprite.animation = "attack"
	elif velocity.length() > 10:
		sprite.animation = "run"
		sprite.flip_h = velocity.x < 0
	else:
		sprite.animation = "idle"
		# Face target if exists
		if target:
			var look_dir := (target.global_position - global_position).normalized()
			sprite.flip_h = look_dir.x < 0