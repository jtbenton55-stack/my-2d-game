# Goon.gd
# Basic melee enemy - simpler than Guard, no patrol, instant detection

extends EnemyBase

# Wander
@export var wander_radius: float = 50.0
@export var wander_speed: float = 80.0
@export var wait_time: float = 1.5
var home_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wait_timer: float = 0.0
var is_waiting: bool = false

# Placeholder visuals (no AnimatedSprite2D in scene)
@onready var body_visual: Polygon2D = $PlaceholderBody
@onready var head_visual: Polygon2D = $PlaceholderHead

func _ready() -> void:
	super._ready()
	home_position = global_position
	_pick_new_wander_target()
	_change_state(State.IDLE)

func _process(delta: float) -> void:
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update placeholder visuals
	_update_visuals()

# Idle state - small wander
func _state_idle(delta: float) -> void:
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			_pick_new_wander_target()
		return
	
	var direction := (wander_target - global_position).normalized()
	var distance := global_position.distance_to(wander_target)
	
	if distance < 5.0:
		is_waiting = true
		wait_timer = wait_time
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)
		return
	
	var target_velocity := direction * wander_speed
	velocity = velocity.move_toward(target_velocity, acceleration)

# Alert state - move to last known position, then return to idle
func _state_alert(delta: float) -> void:
	if last_known_position != Vector2.ZERO:
		var direction := (last_known_position - global_position).normalized()
		var distance := global_position.distance_to(last_known_position)
		
		if distance < 10.0:
			last_known_position = Vector2.ZERO
			_change_state(State.IDLE)
			return
		
		var target_velocity := direction * speed
		velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		_change_state(State.IDLE)

# Chase state - run at player
func _state_chase(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var direction := (target.global_position - global_position).normalized()
	var distance := global_position.distance_to(target.global_position)
	
	if distance <= attack_range:
		_change_state(State.ATTACK)
		return
	
	var target_velocity := direction * chase_speed
	velocity = velocity.move_toward(target_velocity, acceleration)

# Attack state
func _state_attack(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	if distance > attack_range:
		_change_state(State.CHASE)
		return
	
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	if attack_timer <= 0:
		attack_timer = attack_cooldown
		target.take_damage(attack_damage, self)

# Pick a random point near home to wander to
func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var distance := randf() * wander_radius
	wander_target = home_position + Vector2(cos(angle), sin(angle)) * distance

# Override vision - instant chase, no detection meter
func _on_vision_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target = body
		EventBus.enemy_spotted_player.emit(self, target)
		_change_state(State.CHASE)

func _on_vision_area_body_exited(body: Node) -> void:
	if body == target:
		last_known_position = target.global_position
		target = null
		EventBus.enemy_lost_player.emit(self)
		_change_state(State.ALERT)

# Override take_damage to immediately chase
func take_damage(amount: int, source: Node = null) -> void:
	super.take_damage(amount, source)
	if source and source.is_in_group("player"):
		target = source
		_change_state(State.CHASE)

# Placeholder visual update (no AnimatedSprite2D needed)
func _update_visuals() -> void:
	if velocity.length() > 10:
		# Face movement direction
		if velocity.x < 0:
			body_visual.scale.x = -1
			head_visual.scale.x = -1
		elif velocity.x > 0:
			body_visual.scale.x = 1
			head_visual.scale.x = 1
