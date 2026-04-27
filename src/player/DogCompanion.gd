# DogCompanion.gd
# Loyal black Shiba companion that follows player and can distract enemies

extends CharacterBody2D

# Movement
@export var follow_distance: float = 50.0
@export var max_speed: float = 400.0
@export var acceleration: float = 20.0
@export var rotation_speed: float = 10.0

# Distraction
@export var distraction_duration: float = 5.0
@export var distraction_cooldown: float = 10.0
var is_distracting: bool = false
var distraction_timer: float = 0.0
var distraction_cooldown_timer: float = 0.0
var distraction_target: Vector2 = Vector2.ZERO

# States
enum State {
	FOLLOWING,
	DISTRACTING,
	RETURNING
}
var current_state: State = State.FOLLOWING

# References
var player: Node2D = null
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var distraction_area: Area2D = $DistractionArea

func _ready() -> void:
	EventBus.debug("Dog companion loaded")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		EventBus.debug("Warning: Dog couldn't find player")

func _process(delta: float) -> void:
	# Update timers
	if distraction_timer > 0:
		distraction_timer -= delta
		if distraction_timer <= 0:
			_end_distraction()
	
	if distraction_cooldown_timer > 0:
		distraction_cooldown_timer -= delta
	
	# Update animation
	_update_animation()

func _physics_process(delta: float) -> void:
	match current_state:
		State.FOLLOWING:
			_follow_player(delta)
		State.DISTRACTING:
			_move_to_distraction(delta)
		State.RETURNING:
			_return_to_player(delta)
	
	move_and_slide()

# Follow the player with smooth lag
func _follow_player(delta: float) -> void:
	if not player:
		return
	
	var target_position := player.global_position
	var direction := (target_position - global_position).normalized()
	var distance := global_position.distance_to(target_position)
	
	# Slow down when close to player
	var speed_scale := clamp(distance / follow_distance, 0.1, 1.0)
	var target_velocity := direction * max_speed * speed_scale
	
	# Apply acceleration
	velocity = velocity.move_toward(target_velocity, acceleration)
	
	# Rotate to face movement direction
	if velocity.length() > 10:
		var target_rotation := atan2(direction.y, direction.x)
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

# Move to distraction target
func _move_to_distraction(delta: float) -> void:
	var direction := (distraction_target - global_position).normalized()
	var distance := global_position.distance_to(distraction_target)
	
	if distance < 10.0:
		# Reached distraction target
		_start_distraction_effect()
		return
	
	var target_velocity := direction * max_speed
	velocity = velocity.move_toward(target_velocity, acceleration)
	
	# Rotate to face movement direction
	if velocity.length() > 10:
		var target_rotation := atan2(direction.y, direction.x)
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

# Return to player after distraction
func _return_to_player(delta: float) -> void:
	if not player:
		current_state = State.FOLLOWING
		return
	
	var direction := (player.global_position - global_position).normalized()
	var distance := global_position.distance_to(player.global_position)
	
	if distance < follow_distance:
		# Close enough to player
		current_state = State.FOLLOWING
		return
	
	var target_velocity := direction * max_speed
	velocity = velocity.move_toward(target_velocity, acceleration)
	
	# Rotate to face movement direction
	if velocity.length() > 10:
		var target_rotation := atan2(direction.y, direction.x)
		rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

# Start distraction
func start_distraction(target: Vector2) -> bool:
	if is_distracting or distraction_cooldown_timer > 0:
		return false
	
	distraction_target = target
	current_state = State.DISTRACTING
	is_distracting = true
	
	EventBus.debug("Dog sent to distract at " + str(target))
	return true

# Start distraction effect (barking, drawing attention)
func _start_distraction_effect() -> void:
	distraction_timer = distraction_duration
	current_state = State.DISTRACTING
	
	# Enable distraction area
	distraction_area.monitoring = true
	
	EventBus.debug("Dog distracting for " + str(distraction_duration) + " seconds")
	
	# In a real game, this would play a bark sound and visual effect

# End distraction
func _end_distraction() -> void:
	is_distracting = false
	distraction_cooldown_timer = distraction_cooldown
	current_state = State.RETURNING
	
	# Disable distraction area
	distraction_area.monitoring = false
	
	EventBus.debug("Dog distraction ended, returning to player")

# Check if distraction is available
func can_distract() -> bool:
	return not is_distracting and distraction_cooldown_timer <= 0

# Get distraction cooldown progress (0.0 to 1.0)
func get_distraction_cooldown_progress() -> float:
	if distraction_cooldown <= 0:
		return 1.0
	return 1.0 - (distraction_cooldown_timer / distraction_cooldown)

# Animation
func _update_animation() -> void:
	if velocity.length() > 10:
		sprite.animation = "run"
		sprite.flip_h = velocity.x < 0
	else:
		sprite.animation = "idle"
		# Face player when idle
		if player:
			var look_dir := (player.global_position - global_position).normalized()
			sprite.flip_h = look_dir.x < 0

# Signal handler for distraction area
func _on_distraction_area_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		EventBus.debug("Dog distracted enemy: " + body.name)
		# In a real game, this would trigger enemy distraction behavior