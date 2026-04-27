# Bruiser.gd
# Slow, heavy-hitting enemy variant for Velvet Paw Jazz Club
# High health, high damage, slow movement, telegraphed attacks

extends EnemyBase

# Bruiser-specific stats (overrides base defaults)
@export var wind_up_time: float = 1.2  # Seconds before attack lands
@export var slam_radius: float = 60.0   # AoE attack range
@export var recovery_time: float = 0.8  # Stunned after attack

# State extensions
enum BruiserState {
	WIND_UP,
	RECOVERY
}
var bruiser_substate = -1

# Timers
var wind_up_timer: float = 0.0
var recovery_timer: float = 0.0

# Visuals
@onready var body_visual: Polygon2D = $PlaceholderBody
@onready var head_visual: Polygon2D = $PlaceholderHead
@onready var telegraph_indicator: Polygon2D = $TelegraphIndicator
@onready var slam_area: Area2D = $SlamArea

# Tracking
var is_winding_up: bool = false
var is_recovering: bool = false

func _ready() -> void:
	super._ready()
	# Bruiser defaults
	max_health = 100
	health = max_health
	speed = 80.0
	chase_speed = 150.0
	attack_damage = 20
	attack_cooldown = 2.5
	attack_range = 55.0
	acceleration = 8.0
	
	if telegraph_indicator:
		telegraph_indicator.visible = false
	if slam_area:
		slam_area.monitoring = false
	
	_change_state(State.IDLE)

func _process(delta: float) -> void:
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	
	if is_winding_up:
		wind_up_timer -= delta
		_update_telegraph()
		if wind_up_timer <= 0:
			_execute_slam()
	
	if is_recovering:
		recovery_timer -= delta
		if recovery_timer <= 0:
			is_recovering = false
			if target and global_position.distance_to(target.global_position) <= attack_range:
				_change_state(State.ATTACK)
			else:
				_change_state(State.CHASE)
	
	_update_visuals()

# ===== STATE OVERRIDES =====

func _state_idle(delta: float) -> void:
	# Slow wander
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * 0.5)

func _state_alert(delta: float) -> void:
	if last_known_position != Vector2.ZERO:
		var direction := (last_known_position - global_position).normalized()
		var distance := global_position.distance_to(last_known_position)
		if distance < 15.0:
			last_known_position = Vector2.ZERO
			_change_state(State.IDLE)
			return
		var target_velocity := direction * speed
		velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		_change_state(State.IDLE)

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

func _state_attack(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range * 1.5:
		_change_state(State.CHASE)
		return
	
	# Stop moving
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	# Start wind-up if not already
	if not is_winding_up and not is_recovering and attack_timer <= 0:
		_start_wind_up()

func _state_dead(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)

# ===== TELEGRAPHED ATTACK SYSTEM =====

func _start_wind_up() -> void:
	is_winding_up = true
	wind_up_timer = wind_up_time
	bruiser_substate = BruiserState.WIND_UP
	EventBus.debug(name + " winding up slam attack!")
	
	if telegraph_indicator:
		telegraph_indicator.visible = true
		_telegraph_pulse(1.0)

func _update_telegraph() -> void:
	if not telegraph_indicator:
		return
	var progress := 1.0 - (wind_up_timer / wind_up_time)
	_telegraph_pulse(progress)
	
	# Flash faster as wind-up nears completion
	if progress > 0.7:
		telegraph_indicator.color = Color(1.0, 0.2, 0.2, 0.6 + sin(Time.get_ticks_msec() * 0.02) * 0.3)

func _telegraph_pulse(progress: float) -> void:
	if not telegraph_indicator:
		return
	var base_scale := 1.0 + progress * 0.5
	telegraph_indicator.scale = Vector2(base_scale, base_scale)
	telegraph_indicator.color = Color(1.0, 0.3, 0.1, 0.4 + progress * 0.4)

func _execute_slam() -> void:
	is_winding_up = false
	if telegraph_indicator:
		telegraph_indicator.visible = false
	
	# Enable slam area briefly
	if slam_area:
		slam_area.monitoring = true
		# Damage all players in slam area
		for body in slam_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				body.take_damage(attack_damage, self)
				EventBus.debug(name + " slammed player for " + str(attack_damage))
		
		# Disable after one frame
		await get_tree().create_timer(0.1).timeout
		if slam_area:
			slam_area.monitoring = false
	
	# Enter recovery
	is_recovering = true
	recovery_timer = recovery_time
	bruiser_substate = BruiserState.RECOVERY
	attack_timer = attack_cooldown
	EventBus.debug(name + " slam attack executed, entering recovery")

# ===== VISUALS =====

func _update_visuals() -> void:
	if not body_visual or not head_visual:
		return
	
	# Face movement or target
	var look_dir := 1.0
	if velocity.length() > 10:
		look_dir = 1.0 if velocity.x >= 0 else -1.0
	elif target:
		look_dir = 1.0 if (target.global_position - global_position).x >= 0 else -1.0
	
	body_visual.scale.x = look_dir
	head_visual.scale.x = look_dir
	
	# Wind-up visual: tint red and shake slightly
	if is_winding_up:
		body_visual.color = Color(0.9, 0.3, 0.3, 1.0)
		head_visual.color = Color(0.8, 0.2, 0.2, 1.0)
		var shake := Vector2(randf() - 0.5, randf() - 0.5) * 2.0
		body_visual.position = shake
		head_visual.position = shake
	elif is_recovering:
		body_visual.color = Color(0.5, 0.5, 0.5, 1.0)
		head_visual.color = Color(0.4, 0.4, 0.4, 1.0)
		body_visual.position = Vector2.ZERO
		head_visual.position = Vector2.ZERO
	else:
		body_visual.color = Color(0.4, 0.25, 0.2, 1.0)  # Brown/bruiser color
		head_visual.color = Color(0.3, 0.2, 0.15, 1.0)
		body_visual.position = Vector2.ZERO
		head_visual.position = Vector2.ZERO

# ===== OVERRIDES =====

func _on_vision_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target = body
		EventBus.enemy_spotted_player.emit(self, target)
		if not is_winding_up and not is_recovering:
			_change_state(State.CHASE)

func _on_vision_area_body_exited(body: Node) -> void:
	if body == target:
		last_known_position = target.global_position
		target = null
		EventBus.enemy_lost_player.emit(self)
		if not is_winding_up:
			_change_state(State.ALERT)

func take_damage(amount: int, source: Node = null) -> void:
	super.take_damage(amount, source)
	# Interrupt wind-up if hit
	if is_winding_up:
		is_winding_up = false
		wind_up_timer = 0.0
		if telegraph_indicator:
			telegraph_indicator.visible = false
		EventBus.debug(name + " wind-up interrupted!")
	
	if source and source.is_in_group("player") and not is_recovering:
		target = source
		_change_state(State.CHASE)

func die() -> void:
	_change_state(State.DEAD)
	EventBus.enemy_died.emit(self)
	EventBus.debug(name + " died")
	
	# Brief death visual before removal
	if body_visual:
		body_visual.color = Color(0.2, 0.2, 0.2, 1.0)
	if head_visual:
		head_visual.color = Color(0.15, 0.15, 0.15, 1.0)
	
	await get_tree().create_timer(0.5).timeout
	queue_free()
