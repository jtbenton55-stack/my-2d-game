extends CharacterBody2D

@export var max_speed := 400.0
@export var acceleration := 20.0
@export var follow_distance := 48.0
@export var rotation_speed := 10.0
@export var ability_max := 100.0
@export var recharge_rate := 22.0
@export var bark_cost := 35.0
@export var bark_radius := 130.0
@export var bark_stun_time := 2.0
@export var distraction_duration := 5.0
@export var distraction_cooldown := 10.0

var ability_meter := 100.0
var target: Node2D = null

func _ready() -> void:
	add_to_group("bentley")
	target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		call_deferred("_find_target")
	var recharge_mult: float = _card_float("get_bentley_recharge_multiplier", 1.0)
	recharge_rate *= recharge_mult
	var radius_mult: float = _card_float("get_bentley_bark_radius_multiplier", 1.0)
	bark_radius *= radius_mult
	EventBus.bentley_meter_changed.emit(ability_meter, ability_max)

func _find_target() -> void:
	target = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
	_recharge(delta)
	_follow(delta)
	if _ability_pressed():
		bark_stun()

func _follow(delta: float) -> void:
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_target := target.global_position - global_position
	if to_target.length() > follow_distance:
		velocity = to_target.normalized() * min(max_speed, to_target.length() * 5.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, max_speed * delta * 4.0)
	move_and_slide()
	_clamp_to_scene_bounds()

func _recharge(delta: float) -> void:
	var rate: float = recharge_rate
	var recharge_mult: float = _card_float("get_bentley_recharge_multiplier", 1.0)
	rate *= recharge_mult
	ability_meter = min(ability_max, ability_meter + rate * delta)
	EventBus.bentley_meter_changed.emit(ability_meter, ability_max)

func bark_stun() -> bool:
	if ability_meter < bark_cost:
		return false
	ability_meter -= bark_cost
	AudioManager.play_sfx("bentley_bark", global_position)
	var radius_mult: float = _card_float("get_bentley_bark_radius_multiplier", 1.0)
	var effective_radius: float = bark_radius * radius_mult
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= effective_radius:
			if enemy.has_method("stun"):
				enemy.stun(bark_stun_time)
	EventBus.bentley_ability_used.emit("bark_stun")
	EventBus.bentley_meter_changed.emit(ability_meter, ability_max)
	return true

func sniff() -> void:
	EventBus.objective_updated.emit("Bentley sniffs out the next clue.")
	AudioManager.play_sfx("bentley_sniff", global_position)

func _ability_pressed() -> bool:
	if InputMap.has_action("bentley_ability") and Input.is_action_just_pressed("bentley_ability"):
		return true
	return false

func set_rain_penalty(active: bool) -> void:
	# Rain slows Bentley's ability recharge
	if active:
		recharge_rate *= 0.6  # 40% slower in rain without raincoat
		EventBus.objective_updated.emit("Bentley: *shakes rain from fur*")
	else:
		recharge_rate = 22.0  # Reset to base

func _card_float(method_name: String, fallback: float) -> float:
	var card_effects = get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method(method_name):
		return float(card_effects.call(method_name))
	return fallback

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
