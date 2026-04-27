# Guard.gd
# Specific guard enemy with patrol behavior and vision cone detection

extends EnemyBase

# Patrol
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 100.0
@export var wait_time_at_points: float = 2.0
var current_patrol_index: int = 0
var wait_timer: float = 0.0
var is_waiting: bool = false

# Detection
@export var detection_speed: float = 1.0  # How fast detection meter fills
@export var detection_decay: float = 0.5  # How fast detection meter decays
var detection_meter: float = 0.0
var is_player_visible: bool = false

# Alert
@export var alert_duration: float = 5.0
var alert_timer: float = 0.0

func _ready() -> void:
	super._ready()
	
	# If no patrol points, add current position as single point
	if patrol_points.is_empty():
		patrol_points.append(global_position)
	
	_change_state(State.PATROL)

func _process(delta: float) -> void:
	super._process(delta)
	
	# Update detection meter
	if is_player_visible and target:
		detection_meter += detection_speed * delta
		detection_meter = clamp(detection_meter, 0.0, 1.0)
		
		# Update detection UI
		EventBus.update_detection_meter.emit(detection_meter)
		
		# Check if detection is complete
		if detection_meter >= 1.0 and current_state != State.CHASE:
			_change_state(State.CHASE)
			EventBus.debug("Guard fully detected player")
	else:
		detection_meter -= detection_decay * delta
		detection_meter = clamp(detection_meter, 0.0, 1.0)
		
		# Update detection UI
		EventBus.update_detection_meter.emit(detection_meter)
	
	# Update alert timer
	if current_state == State.ALERT:
		alert_timer -= delta
		if alert_timer <= 0:
			_change_state(State.PATROL)
			EventBus.debug("Guard alert ended")

# Patrol state
func _state_patrol(delta: float) -> void:
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			_move_to_next_patrol_point()
		return
	
	var target_point := patrol_points[current_patrol_index]
	var direction := (target_point - global_position).normalized()
	var distance := global_position.distance_to(target_point)
	
	if distance < 10.0:
		# Reached patrol point
		is_waiting = true
		wait_timer = wait_time_at_points
		EventBus.debug("Guard waiting at patrol point")
		return
	
	var target_velocity := direction * patrol_speed
	velocity = velocity.move_toward(target_velocity, acceleration)

func _move_to_next_patrol_point() -> void:
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	EventBus.debug("Guard moving to patrol point " + str(current_patrol_index))

# Alert state
func _state_alert(delta: float) -> void:
	# Move to last known position
	if last_known_position != Vector2.ZERO:
		var direction := (last_known_position - global_position).normalized()
		var distance := global_position.distance_to(last_known_position)
		
		if distance < 10.0:
			# Reached last known position, look around
			velocity = velocity.move_toward(Vector2.ZERO, acceleration)
			alert_timer = alert_duration
		else:
			var target_velocity := direction * speed
			velocity = velocity.move_toward(target_velocity, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

# Chase state
func _state_chase(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var direction := (target.global_position - global_position).normalized()
	var distance := global_position.distance_to(target.global_position)
	
	# Check attack range
	if distance <= attack_range:
		_change_state(State.ATTACK)
		return
	
	# Chase target
	var target_velocity := direction * chase_speed
	velocity = velocity.move_toward(target_velocity, acceleration)

# Attack state
func _state_attack(delta: float) -> void:
	if not target:
		_change_state(State.ALERT)
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	# Face target
	var direction := (target.global_position - global_position).normalized()
	
	# Check if target moved out of range
	if distance > attack_range:
		_change_state(State.CHASE)
		return
	
	# Stop moving while attacking
	velocity = velocity.move_toward(Vector2.ZERO, acceleration)
	
	# Attack if cooldown is ready
	if attack_timer <= 0:
		attack_timer = attack_cooldown
		target.take_damage(attack_damage, self)

# Override vision area handlers to track player visibility
func _on_vision_area_body_entered(body: Node) -> void:
	super._on_vision_area_body_entered(body)
	if body.is_in_group("player"):
		is_player_visible = true
		EventBus.show_detection_meter.emit(true)

func _on_vision_area_body_exited(body: Node) -> void:
	super._on_vision_area_body_exited(body)
	if body.is_in_group("player"):
		is_player_visible = false
		EventBus.show_detection_meter.emit(false)

# Override take_damage to immediately chase attacker
func take_damage(amount: int, source: Node = null) -> void:
	super.take_damage(amount, source)
	
	# If damaged by player, immediately chase
	if source and source.is_in_group("player"):
		target = source
		_change_state(State.CHASE)