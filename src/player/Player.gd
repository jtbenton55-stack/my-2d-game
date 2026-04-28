extends CharacterBody2D

signal died
signal health_changed(current_health, max_health)

@export var speed := 300.0
@export var stealth_speed := 150.0
@export var acceleration := 15.0
@export var friction := 10.0
@export var dodge_speed := 600.0
@export var dodge_duration := 0.16
@export var dodge_cooldown := 0.45
@export var attack_damage := 20
@export var attack_range := 54.0
@export var attack_cooldown := 0.35
@export var max_health := 100
@export var stealth_detection_multiplier := 0.5

var current_health := 100
var facing := Vector2.DOWN
var dodge_timer := 0.0
var dodge_cooldown_timer := 0.0
var attack_timer := 0.0
var invulnerable := false
var can_control := true

func _ready() -> void:
	add_to_group("player")
	max_health = int(CardEffects.get_player_max_health())
	current_health = min(max_health, GameState.player_health if GameState.player_health > 0 else max_health)
	GameState.player_max_health = max_health
	GameState.player_health = current_health
	EventBus.player_health_changed.emit(current_health, max_health)
	var hitbox := get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = false
	_update_sprite()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if not can_control:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_vector := _get_move_vector()
	if input_vector.length() > 0.01:
		facing = input_vector.normalized()
	
	var dodge_cd_reduction: float = CardEffects.get_cooldown_reduction()
	var effective_dodge_cooldown: float = dodge_cooldown * (1.0 - dodge_cd_reduction)
	
	if _action_just_pressed("dodge") and input_vector.length() > 0.01 and dodge_cooldown_timer <= 0.0:
		dodge_timer = dodge_duration
		dodge_cooldown_timer = effective_dodge_cooldown
		invulnerable = true
		AudioManager.play_sfx("dodge", global_position)
	if _action_just_pressed("attack") and attack_timer <= 0.0:
		_attack()
	
	var speed_mult: float = CardEffects.get_player_speed_multiplier()
	var effective_speed: float = speed * speed_mult
	var effective_stealth_speed: float = stealth_speed * speed_mult
	var move_speed := effective_stealth_speed if _action_pressed("stealth") else effective_speed
	
	if dodge_timer > 0.0:
		velocity = facing * dodge_speed
	else:
		velocity = input_vector * move_speed
	move_and_slide()
	_update_sprite()
	if _action_just_pressed("interact"):
		_try_interact()

func _update_timers(delta: float) -> void:
	if dodge_timer > 0.0:
		dodge_timer -= delta
		if dodge_timer <= 0.0:
			invulnerable = false
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer -= delta
	if attack_timer > 0.0:
		attack_timer -= delta

func _get_move_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y).normalized()

func _attack() -> void:
	var cd_reduction: float = CardEffects.get_cooldown_reduction()
	attack_timer = attack_cooldown * (1.0 - cd_reduction)
	AudioManager.play_sfx("quick_attack", global_position)
	var damage_bonus: int = CardEffects.get_attack_damage_bonus()
	var total_damage: int = attack_damage + damage_bonus
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= attack_range:
			var direction: Vector2 = (enemy.global_position - global_position).normalized()
			if facing.dot(direction) > -0.25 and enemy.has_method("take_damage"):
				enemy.take_damage(total_damage, self)

func take_damage(amount: int, _source: Node = null) -> void:
	if invulnerable or current_health <= 0:
		return
	if GameState.has_selected_card("bentley_dental_boy") and not GameState.dialogue_flags.get("dental_boy_used", false):
		GameState.dialogue_flags["dental_boy_used"] = true
		AudioManager.play_sfx("bentley_save", global_position)
		return
	current_health = max(0, current_health - amount)
	GameState.player_health = current_health
	health_changed.emit(current_health, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_damaged.emit(amount, current_health)
	if current_health <= 0:
		_die()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	GameState.player_health = current_health
	health_changed.emit(current_health, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)

func _die() -> void:
	can_control = false
	died.emit()
	EventBus.player_died.emit()
	var level := get_tree().current_scene
	if level and level.has_method("fail_level"):
		level.fail_level("Jake has concerns. Bentley refuses to discuss it.")
	else:
		GameState.fail_mission("", "Jake has concerns. Bentley refuses to discuss it.")
		SceneManager.show_mission_result()

func _try_interact() -> void:
	var best: Node = null
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Node2D:
			var dist := global_position.distance_to(node.global_position)
			if dist < 72.0 and dist < best_dist:
				best = node
				best_dist = dist
	if best and best.has_method("interact"):
		best.interact(self)

func _update_sprite() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.has_method("play"):
		if velocity.length() > 5.0 and sprite.sprite_frames and sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		elif sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _action_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)

func _action_just_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)
