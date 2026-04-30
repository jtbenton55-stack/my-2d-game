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
var is_stealth := false
var stealth_indicator: ColorRect = null

func is_stealth_active() -> bool:
	return is_stealth

func _ready() -> void:
	add_to_group("player")
	max_health = _card_int("get_player_max_health", max_health)
	current_health = min(max_health, GameState.player_health if GameState.player_health > 0 else max_health)
	GameState.player_max_health = max_health
	GameState.player_health = current_health
	EventBus.player_health_changed.emit(current_health, max_health)
	var hitbox := get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = false
	_create_stealth_indicator()
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
	
	var dodge_cd_reduction: float = _card_float("get_cooldown_reduction", 0.0)
	var effective_dodge_cooldown: float = dodge_cooldown * (1.0 - dodge_cd_reduction)
	
	if _action_just_pressed("dodge") and input_vector.length() > 0.01 and dodge_cooldown_timer <= 0.0:
		dodge_timer = dodge_duration
		dodge_cooldown_timer = effective_dodge_cooldown
		invulnerable = true
		AudioManager.play_sfx("dodge", global_position)
	if _action_just_pressed("attack") and attack_timer <= 0.0:
		_attack()
	
	var speed_mult: float = _card_float("get_player_speed_multiplier", 1.0)
	var stealth_mult: float = _card_float("get_player_stealth_multiplier", 1.0)
	var effective_speed: float = speed * speed_mult
	var effective_stealth_speed: float = stealth_speed * speed_mult * stealth_mult
	is_stealth = _action_pressed("stealth")
	var move_speed := effective_stealth_speed if is_stealth else effective_speed
	
	if dodge_timer > 0.0:
		velocity = facing * dodge_speed
	else:
		velocity = input_vector * move_speed
	move_and_slide()
	_clamp_to_scene_bounds()
	_update_stealth_visual()
	_update_sprite()
	# Advance dialogue from here too: fullscreen UI can eat _unhandled_input before DialogueBox sees E.
	if _action_just_pressed("interact"):
		if DialogueManager.is_in_dialogue:
			DialogueManager.next_line()
		elif not _should_skip_world_interact():
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
	var cd_reduction: float = _card_float("get_cooldown_reduction", 0.0)
	attack_timer = attack_cooldown * (1.0 - cd_reduction)
	AudioManager.play_sfx("quick_attack", global_position)
	var damage_bonus: int = _card_int("get_attack_damage_bonus", 0)
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
		EventBus.card_triggered.emit("bentley_dental_boy", "used", "Bentley took the hit.")
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

func _should_skip_world_interact() -> bool:
	if get_tree().get_nodes_in_group("blocking_ui").size() > 0:
		return true
	return false

func _try_interact() -> void:
	var best: Node = null
	var best_dist := 999999.0
	for node in get_tree().get_nodes_in_group("interactable"):
		# Only consider nodes that actually implement interact; otherwise a large
		# Area2D in "interactable" (e.g. trigger zones) wins by distance and blocks E.
		if node is Node2D and node.has_method("interact"):
			var dist := global_position.distance_to(node.global_position)
			if dist < 72.0 and dist < best_dist:
				best = node
				best_dist = dist
	if best != null:
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

func _clamp_to_scene_bounds() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var camera := scene.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	if camera.limit_right <= camera.limit_left or camera.limit_bottom <= camera.limit_top:
		return
	var margin := 24.0
	global_position.x = clamp(global_position.x, float(camera.limit_left) + margin, float(camera.limit_right) - margin)
	global_position.y = clamp(global_position.y, float(camera.limit_top) + margin, float(camera.limit_bottom) - margin)

func _create_stealth_indicator() -> void:
	stealth_indicator = ColorRect.new()
	stealth_indicator.name = "StealthIndicator"
	stealth_indicator.custom_minimum_size = Vector2(22, 6)
	stealth_indicator.position = Vector2(-11, -54)
	stealth_indicator.color = Color(0.3, 0.7, 1.0, 0.75)
	stealth_indicator.visible = false
	add_child(stealth_indicator)

func _update_stealth_visual() -> void:
	if stealth_indicator:
		stealth_indicator.visible = is_stealth

func _card_float(method_name: String, fallback: float) -> float:
	var card_effects = get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method(method_name):
		return float(card_effects.call(method_name))
	return fallback

func _card_int(method_name: String, fallback: int) -> int:
	var card_effects = get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method(method_name):
		return int(card_effects.call(method_name))
	return fallback
