# Player.gd
# Top-down player controller with movement, dodge, attack, stealth

extends CharacterBody2D

# Movement
@export var speed: float = 300.0
@export var stealth_speed: float = 150.0
@export var acceleration: float = 15.0
@export var friction: float = 10.0

# Dodge
@export var dodge_speed: float = 600.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 0.5
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

# Attack
@export var attack_damage: int = 20
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 0.5
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

# Health
@export var max_health: int = 100
var health: int = max_health

# Stealth
var is_stealth: bool = false
@export var stealth_detection_multiplier: float = 0.5

# Components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea

# Input
var input_vector: Vector2 = Vector2.ZERO
var mouse_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	health = max_health
	GameState.set_max_health(max_health)
	GameState.set_player_health(health)
	
	# Connect signals
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	EventBus.debug("Player loaded")

func _process(delta: float) -> void:
	# Update timers
	if dodge_timer > 0:
		dodge_timer -= delta
		if dodge_timer <= 0:
			_end_dodge()
	
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			_end_attack()
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# Update animation
	_update_animation()

func _physics_process(delta: float) -> void:
	# Get input
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	mouse_position = get_global_mouse_position()
	
	# Handle actions
	if Input.is_action_just_pressed("dodge") and can_dodge():
		_start_dodge()
	
	if Input.is_action_just_pressed("attack") and can_attack():
		_start_attack()
	
	if Input.is_action_just_pressed("stealth"):
		toggle_stealth()
	
	# Calculate movement
	var target_velocity: Vector2
	var current_speed: float = stealth_speed if is_stealth else speed
	
	if is_dodging:
		# Dodge movement
		target_velocity = dodge_direction * dodge_speed
	elif input_vector.length() > 0:
		# Normal movement
		target_velocity = input_vector.normalized() * current_speed
	else:
		# Friction
		target_velocity = velocity.move_toward(Vector2.ZERO, friction)
	
	# Apply movement
	velocity = velocity.move_toward(target_velocity, acceleration)
	move_and_slide()
	
	# Update GameState
	GameState.player_position = global_position

# Dodge functions
func can_dodge() -> bool:
	return not is_dodging and dodge_cooldown_timer <= 0 and input_vector.length() > 0

func _start_dodge() -> void:
	is_dodging = true
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	dodge_direction = input_vector.normalized()
	
	# Enable i-frames
	hurtbox.monitoring = false
	
	EventBus.player_dodged.emit()
	EventBus.debug("Player dodged")

func _end_dodge() -> void:
	is_dodging = false
	dodge_direction = Vector2.ZERO
	
	# Disable i-frames
	hurtbox.monitoring = true

# Attack functions
func can_attack() -> bool:
	return not is_attacking and attack_cooldown_timer <= 0

func _start_attack() -> void:
	is_attacking = true
	attack_timer = 0.2  # Attack duration
	attack_cooldown_timer = attack_cooldown
	
	# Enable hitbox
	hitbox.monitoring = true
	
	EventBus.debug("Player attacked")

func _end_attack() -> void:
	is_attacking = false
	
	# Disable hitbox
	hitbox.monitoring = false

# Stealth functions
func toggle_stealth() -> void:
	is_stealth = not is_stealth
	EventBus.player_stealth_changed.emit(is_stealth)
	
	# Update detection area
	if is_stealth:
		detection_area.scale = Vector2.ONE * stealth_detection_multiplier
	else:
		detection_area.scale = Vector2.ONE

# Damage functions
func take_damage(amount: int, source: Node = null) -> void:
	if is_dodging:
		EventBus.debug("Dodge i-frames prevented damage")
		return
	
	health -= amount
	GameState.damage_player(amount)
	
	EventBus.damage_received.emit(self, source, amount)
	EventBus.debug("Player took " + str(amount) + " damage")
	
	if health <= 0:
		die()

func die() -> void:
	EventBus.player_died.emit()
	EventBus.debug("Player died")
	# In a real game, this would trigger respawn or game over

# Animation
func _update_animation() -> void:
	if is_dodging:
		sprite.animation = "dodge"
		sprite.flip_h = dodge_direction.x < 0
	elif is_attacking:
		sprite.animation = "attack"
		# Face attack direction (towards mouse)
		var attack_dir := (mouse_position - global_position).normalized()
		sprite.flip_h = attack_dir.x < 0
	elif input_vector.length() > 0:
		sprite.animation = "run"
		sprite.flip_h = input_vector.x < 0
	else:
		sprite.animation = "idle"
		# Face mouse when idle
		var look_dir := (mouse_position - global_position).normalized()
		sprite.flip_h = look_dir.x < 0

# Signal handlers
func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Handle damage from enemy attacks
	if area.is_in_group("enemy_attack"):
		var damage: int = area.get("damage", 10)
		take_damage(damage, area.get_parent())

func _on_hurtbox_body_entered(body: Node) -> void:
	# Handle collision damage
	if body.is_in_group("enemy"):
		var damage: int = body.get("collision_damage", 5)
		take_damage(damage, body)