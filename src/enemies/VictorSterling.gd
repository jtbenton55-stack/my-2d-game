# VictorSterling.gd
# Final boss — Victor Sterling, head of the Sterling Syndicate.
# Multi-phase fight with guards, security activation, and desperation attacks.

extends EnemyBase
class_name VictorSterling

# ============================================================================
# SIGNALS
# ============================================================================
signal phase_changed(new_phase)
signal health_changed(current, maximum)
signal died
signal summon_guards
signal activate_security

# ============================================================================
# PHASE CONFIG
# ============================================================================
enum BossPhase {
	PHASE_1_CALL_GUARDS,      # 100% - 70%: Calls guards, hangs back
	PHASE_2_PERSONAL,         # 70% - 30%: Fights personally, faster attacks
	PHASE_3_DESPERATION       # 30% - 0%:  Desperation mode, summons + lasers
}
var current_boss_phase: BossPhase = BossPhase.PHASE_1_CALL_GUARDS

# Phase thresholds (% of max health)
const PHASE_2_THRESHOLD: float = 0.70
const PHASE_3_THRESHOLD: float = 0.30

# ============================================================================
# STATS (tuned for final boss)
# ============================================================================
@export var boss_max_health: int = 300
@export var phase_2_speed_multiplier: float = 1.5
@export var phase_3_speed_multiplier: float = 2.0

# Attack patterns
@export var pistol_damage: int = 15
@export var pistol_cooldown: float = 1.2
@export var shotgun_damage: int = 25
@export var shotgun_cooldown: float = 2.5
@export var dash_damage: int = 20
@export var dash_cooldown: float = 3.0

# Movement
@export var retreat_distance: float = 250.0
@export var preferred_combat_distance: float = 180.0

# Summoning
@export var summon_cooldown: float = 8.0
@export var max_summons_per_phase: int = 3
var summon_count: int = 0
var summon_timer: float = 0.0

# Phase transition invulnerability
@export var phase_transition_duration: float = 2.0
var is_transitioning: bool = false
var transition_timer: float = 0.0

# ============================================================================
# STATE
# ============================================================================
var original_speed: float = 0.0
var original_chase_speed: float = 0.0
var original_attack_cooldown: float = 0.0
var attack_pattern_timer: float = 0.0
var current_attack_pattern: int = 0

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
const DASH_DURATION: float = 0.4
const DASH_SPEED: float = 500.0

# ============================================================================
# REFERENCES
# ============================================================================
@onready var attack_range_area: Area2D = $AttackRangeArea
@onready var retreat_range_area: Area2D = $RetreatRangeArea
@onready var pistol_projectile_spawn: Marker2D = $PistolProjectileSpawn
@onready var shotgun_projectile_spawn: Marker2D = $ShotgunProjectileSpawn

# ============================================================================
# READY
# ============================================================================
func _ready() -> void:
	# Override base stats
	max_health = boss_max_health
	health = max_health
	speed = 120.0
	chase_speed = 180.0
	attack_damage = pistol_damage
	attack_cooldown = pistol_cooldown
	
	original_speed = speed
	original_chase_speed = chase_speed
	original_attack_cooldown = attack_cooldown
	
	# Remove from generic enemy group, add boss group
	remove_from_group("enemy")
	add_to_group("boss")
	
	# Connect vision
	if vision_area:
		vision_area.body_entered.connect(_on_vision_area_body_entered)
		vision_area.body_exited.connect(_on_vision_area_body_exited)
	
	EventBus.debug("Victor Sterling initialized - Phase 1")
	emit_signal("health_changed", health, max_health)

# ============================================================================
# PROCESS & PHYSICS
# ============================================================================
func _process(delta: float) -> void:
	# Update timers
	if summon_timer > 0:
		summon_timer -= delta
	
	if is_transitioning:
		transition_timer -= delta
		if transition_timer <= 0:
			_end_phase_transition()
		return
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			_end_dash()
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# Update animation
	_update_boss_animation()

func _physics_process(delta: float) -> void:
	if is_transitioning:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * 2)
		move_and_slide()
		return
	
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

# ============================================================================
# STATE OVERRIDES
# ============================================================================
func _state_idle(delta: float) -> void:
	# Boss never truly idles — if player in range, alert
	if target:
		_change_state(State.ALERT)
		return
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)

func _state_patrol(delta: float) -> void:
	# Boss doesn't patrol — override to idle
	_change_state(State.IDLE)

func _state_alert(delta: float) -> void:
	if not target:
		_change_state(State.IDLE)
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	# Phase-specific behavior
	match current_boss_phase:
		BossPhase.PHASE_1_CALL_GUARDS:
			# Stay at preferred distance, summon guards
			if distance < retreat_distance:
				_retreat_from_target(delta)
			else:
				_move_toward_preferred_distance(delta)
			
			# Try summon
			_try_summon()
			
			# Attack if in range
			if distance <= attack_range and attack_timer <= 0:
				_change_state(State.ATTACK)
		
		BossPhase.PHASE_2_PERSONAL:
			# More aggressive — close distance
			if distance > attack_range:
				_change_state(State.CHASE)
			elif attack_timer <= 0:
				_change_state(State.ATTACK)
		
		BossPhase.PHASE_3_DESPERATION:
			# Erratic — dash, summon, attack
			if distance > attack_range * 1.5:
				_change_state(State.CHASE)
			elif attack_timer <= 0:
				_change_state(State.ATTACK)
			
			_try_summon()
			_try_dash()

func _state_chase(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var direction := (target.global_position - global_position).normalized()
	var distance := global_position.distance_to(target.global_position)
	
	# Phase 1: don't chase too close
	if current_boss_phase == BossPhase.PHASE_1_CALL_GUARDS and distance < preferred_combat_distance:
		_change_state(State.ALERT)
		return
	
	# Check attack range
	if distance <= attack_range and attack_timer <= 0:
		_change_state(State.ATTACK)
		return
	
	var target_velocity := direction * chase_speed
	velocity = velocity.move_toward(target_velocity, acceleration)

func _state_attack(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var distance := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()
	
	# Face target
	if sprite:
		sprite.flip_h = direction.x < 0
	
	# Stop moving while attacking
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * 2)
	
	# Execute attack
	if attack_timer <= 0:
		_execute_attack()
		attack_timer = attack_cooldown
		
		# Return to alert after attack
		_change_state(State.ALERT)

func _state_dead(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)

# ============================================================================
# ATTACK PATTERNS
# ============================================================================
func _execute_attack() -> void:
	match current_boss_phase:
		BossPhase.PHASE_1_CALL_GUARDS:
			_pistol_shot()
		BossPhase.PHASE_2_PERSONAL:
			# Alternate between pistol and shotgun
			if current_attack_pattern % 2 == 0:
				_pistol_shot()
			else:
				_shotgun_blast()
			current_attack_pattern += 1
		BossPhase.PHASE_3_DESPERATION:
			# Rapid pistol + occasional shotgun
			if current_attack_pattern % 3 == 0:
				_shotgun_blast()
			else:
				_pistol_shot()
			current_attack_pattern += 1

func _pistol_shot() -> void:
	if not target:
		return
	
	attack_damage = pistol_damage
	
	# Face target
	var direction := (target.global_position - global_position).normalized()
	if sprite:
		sprite.flip_h = direction.x < 0
	
	# Deal damage directly (melee-range pistol for simplicity)
	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range + 20:
		target.take_damage(pistol_damage, self)
		EventBus.debug("Victor: Pistol shot for " + str(pistol_damage))
	
	# Visual feedback
	_show_attack_flash(Color(1.0, 0.8, 0.2, 0.5))

func _shotgun_blast() -> void:
	if not target:
		return
	
	attack_damage = shotgun_damage
	attack_cooldown = shotgun_cooldown
	
	var direction := (target.global_position - global_position).normalized()
	if sprite:
		sprite.flip_h = direction.x < 0
	
	# Shotgun hits in a wider arc — check multiple angles
	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range + 40:
		target.take_damage(shotgun_damage, self)
		EventBus.debug("Victor: Shotgun blast for " + str(shotgun_damage))
	
	_show_attack_flash(Color(1.0, 0.4, 0.1, 0.6))

# ============================================================================
# MOVEMENT HELPERS
# ============================================================================
func _retreat_from_target(delta: float) -> void:
	if not target:
		return
	var away_dir := (global_position - target.global_position).normalized()
	var target_velocity := away_dir * speed
	velocity = velocity.move_toward(target_velocity, acceleration)

func _move_toward_preferred_distance(delta: float) -> void:
	if not target:
		return
	var distance := global_position.distance_to(target.global_position)
	var direction := (target.global_position - global_position).normalized()
	
	if distance > preferred_combat_distance + 30:
		var target_velocity := direction * speed
		velocity = velocity.move_toward(target_velocity, acceleration)
	elif distance < preferred_combat_distance - 30:
		var away_dir := -direction
		var target_velocity := away_dir * speed
		velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

# ============================================================================
# DASH MECHANIC (Phase 3)
# ============================================================================
func _try_dash() -> void:
	if current_boss_phase != BossPhase.PHASE_3_DESPERATION:
		return
	if is_dashing:
		return
	if not target:
		return
	
	# Random chance to dash
	if randf() > 0.02:  # ~2% per frame
		return
	
	_start_dash()

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_DURATION
	
	if target:
		dash_direction = (target.global_position - global_position).normalized()
	else:
		dash_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Brief invulnerability during dash
	if hurtbox:
		hurtbox.monitoring = false
	
	EventBus.debug("Victor: DASH!")

func _end_dash() -> void:
	is_dashing = false
	
	if hurtbox:
		hurtbox.monitoring = true
	
	# Deal damage if near player after dash
	if target:
		var distance := global_position.distance_to(target.global_position)
		if distance <= attack_range:
			target.take_damage(dash_damage, self)
			EventBus.debug("Victor: Dash hit for " + str(dash_damage))

# ============================================================================
# SUMMON GUARDS
# ============================================================================
func _try_summon() -> void:
	if summon_timer > 0:
		return
	if summon_count >= max_summons_per_phase:
		return
	
	# Phase-dependent summon chance
	var summon_chance := 0.0
	match current_boss_phase:
		BossPhase.PHASE_1_CALL_GUARDS:
			summon_chance = 0.015
		BossPhase.PHASE_3_DESPERATION:
			summon_chance = 0.01
		_:
			return
	
	if randf() > summon_chance:
		return
	
	summon_timer = summon_cooldown
	summon_count += 1
	
	emit_signal("summon_guards")
	EventBus.debug("Victor: Summoning guards! (" + str(summon_count) + "/" + str(max_summons_per_phase) + ")")

# ============================================================================
# DAMAGE & PHASE TRANSITIONS
# ============================================================================
func take_damage(amount: int, source: Node = null) -> void:
	if is_transitioning:
		return  # Invulnerable during phase transition
	
	health -= amount
	emit_signal("health_changed", health, max_health)
	
	EventBus.damage_dealt.emit(source, self, amount)
	EventBus.debug("Victor took " + str(amount) + " damage (" + str(health) + "/" + str(max_health) + ")")
	
	# Check phase transitions
	var health_percent := float(health) / float(max_health)
	
	if current_boss_phase == BossPhase.PHASE_1_CALL_GUARDS and health_percent <= PHASE_2_THRESHOLD:
		_start_phase_transition(BossPhase.PHASE_2_PERSONAL)
		return
	
	if current_boss_phase == BossPhase.PHASE_2_PERSONAL and health_percent <= PHASE_3_THRESHOLD:
		_start_phase_transition(BossPhase.PHASE_3_DESPERATION)
		return
	
	if health <= 0:
		die()
		return
	
	# Alert on damage
	if source and source.is_in_group("player"):
		target = source
		if current_state != State.ATTACK:
			_change_state(State.ALERT)

func _start_phase_transition(new_phase: BossPhase) -> void:
	is_transitioning = true
	transition_timer = phase_transition_duration
	current_boss_phase = new_phase
	
	EventBus.debug("Victor: Phase transition to " + str(new_phase))
	
	# Apply phase modifiers
	match new_phase:
		BossPhase.PHASE_2_PERSONAL:
			speed = original_speed * phase_2_speed_multiplier
			chase_speed = original_chase_speed * phase_2_speed_multiplier
			attack_cooldown = original_attack_cooldown * 0.7
			summon_count = 0  # Reset summon count
		BossPhase.PHASE_3_DESPERATION:
			speed = original_speed * phase_3_speed_multiplier
			chase_speed = original_chase_speed * phase_3_speed_multiplier
			attack_cooldown = original_attack_cooldown * 0.5
			summon_count = 0
			# Activate security
			emit_signal("activate_security")
	
	emit_signal("phase_changed", int(new_phase))

func _end_phase_transition() -> void:
	is_transitioning = false
	EventBus.debug("Victor: Phase transition complete")

# ============================================================================
# DEATH
# ============================================================================
func die() -> void:
	if current_state == State.DEAD:
		return
	
	_change_state(State.DEAD)
	emit_signal("died")
	emit_signal("health_changed", 0, max_health)
	EventBus.enemy_died.emit(self)
	EventBus.debug("Victor Sterling has fallen!")
	
	# Death animation / effects would go here
	# Keep body for a moment, then queue_free
	await get_tree().create_timer(3.0).timeout
	queue_free()

# ============================================================================
# VISION OVERRIDES
# ============================================================================
func _on_vision_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target = body
		EventBus.enemy_spotted_player.emit(self, target)
		if current_state == State.IDLE:
			_change_state(State.ALERT)

func _on_vision_area_body_exited(body: Node) -> void:
	if body == target:
		last_known_position = target.global_position
		target = null
		EventBus.enemy_lost_player.emit(self)

# ============================================================================
# VISUAL HELPERS
# ============================================================================
func _update_boss_animation() -> void:
	if not sprite:
		return
	
	if current_state == State.DEAD:
		sprite.animation = "dead"
	elif is_transitioning:
		sprite.animation = "hurt"
	elif is_dashing:
		sprite.animation = "dash"
	elif current_state == State.ATTACK:
		sprite.animation = "attack"
	elif velocity.length() > 10:
		sprite.animation = "run"
		sprite.flip_h = velocity.x < 0
	else:
		sprite.animation = "idle"
		if target:
			var look_dir := (target.global_position - global_position).normalized()
			sprite.flip_h = look_dir.x < 0

func _show_attack_flash(color: Color) -> void:
	# Simple visual flash effect
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(-30, -50), Vector2(30, -50),
		Vector2(30, 10), Vector2(-30, 10)
	])
	flash.color = color
	add_child(flash)
	
	# Fade out
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
