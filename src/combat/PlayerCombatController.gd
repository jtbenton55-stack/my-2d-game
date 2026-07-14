extends Node
## Hitbox melee combat: combos, heavy, dash, style finisher, stealth takedowns. Parent must be Player CharacterBody2D.

signal style_changed(current: float, maximum: float)

@export var enabled: bool = true
@export var max_style: float = 100.0
@export var style_per_hit: float = 18.0
@export var style_decay_rate: float = 32.0
@export var combo_window_base: float = 0.55
@export var light_active_window: float = 0.09
@export var light_recovery: float = 0.14
@export var heavy_windup: float = 0.12
@export var heavy_active: float = 0.11
@export var heavy_recovery_time: float = 0.4
@export var finisher_active: float = 0.12
@export var finisher_recovery: float = 0.32
@export var dash_cooldown_base: float = 0.48
@export var melee_forward_distance: float = 34.0
@export var finisher_forward_distance: float = 48.0
@export var base_light_damage: float = 18.0
@export var heavy_damage_multiplier: float = 2.2
@export var combo_damage_bonus_per_step: float = 0.16

var can_act: bool = true

var current_style: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0
var time_since_last_hit: float = 999.0

var _player: CharacterBody2D
var _dash: DashAbility
var _melee: Area2D
var _stealth_zone: Area2D

var _dash_cd: float = 0.0
var _light_cd: float = 0.0
var _heavy_cd: float = 0.0
var _busy: bool = false
var last_attack_kind := ""

var _combo_window_mult: float = 1.0
var _style_decay_reduction: float = 0.0


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_dash = get_node_or_null("DashAbility")
	_melee = get_node_or_null("MeleeHitbox") as Area2D
	_stealth_zone = get_node_or_null("StealthTakedownZone") as Area2D
	if _melee and _melee.has_method("setup_damage_source"):
		_melee.setup_damage_source(_player)
	apply_card_effects()
	if not EventBus.card_selection_changed.is_connected(_on_card_selection_changed):
		EventBus.card_selection_changed.connect(_on_card_selection_changed)


func _on_card_selection_changed(_selected: Variant) -> void:
	apply_card_effects()


func apply_card_effects() -> void:
	var ce: Node = get_node_or_null("/root/CardEffects")
	if ce == null:
		_combo_window_mult = 1.0
		_style_decay_reduction = 0.0
		return
	if ce.has_method("get_combo_window_multiplier"):
		_combo_window_mult = float(ce.call("get_combo_window_multiplier"))
	else:
		_combo_window_mult = 1.0
	if ce.has_method("get_style_decay_reduction"):
		_style_decay_reduction = float(ce.call("get_style_decay_reduction"))
	else:
		_style_decay_reduction = 0.0


func is_dashing() -> bool:
	return _dash != null and _dash.is_dashing


func _card_is_active(card_id: String) -> bool:
	var cm: Node = get_node_or_null("/root/CardManager")
	if cm == null:
		return false
	if cm.has_method("is_card_active"):
		return cm.call("is_card_active", card_id) == true
	if cm.has_method("is_selected"):
		return cm.call("is_selected", card_id) == true
	return false


func _process(delta: float) -> void:
	if not enabled:
		return
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _light_cd > 0.0:
		_light_cd -= delta
	if _heavy_cd > 0.0:
		_heavy_cd -= delta
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_count = 0
	time_since_last_hit += delta
	var decay_mult: float = maxf(0.0, 1.0 - _style_decay_reduction)
	if time_since_last_hit > 2.0 and current_style > 0.0:
		current_style = maxf(0.0, current_style - style_decay_rate * decay_mult * delta)
	_emit_style()


func _emit_style() -> void:
	style_changed.emit(current_style, max_style)
	EventBus.combat_style_changed.emit(current_style, max_style)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or _busy:
		return
	if _should_block_combat_input():
		return
	if event.is_action_pressed("finisher"):
		_request_finisher()
	elif event.is_action_pressed("heavy"):
		_request_heavy()
	elif event.is_action_pressed("attack"):
		_request_light_or_takedown()
	elif event.is_action_pressed("dodge"):
		_request_dash()


func _should_block_combat_input() -> bool:
	if get_tree().paused:
		return true
	if DialogueManager.is_in_dialogue:
		return true
	if _player == null or not _player.can_control:
		return true
	if _player.has_method("is_poop_bag_targeting") and bool(_player.call("is_poop_bag_targeting")):
		return true
	return false


func _get_move_vector_from_input() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y).normalized()


func _facing_dir() -> Vector2:
	if _player and _player.facing.length_squared() > 0.0001:
		return _player.facing.normalized()
	return Vector2.DOWN


func _position_melee_forward(distance: float) -> void:
	if _melee == null or _player == null:
		return
	var f := _facing_dir()
	_melee.global_position = _player.global_position + f * distance
	_melee.global_rotation = f.angle()


func _cooldown_reduction() -> float:
	var ce: Node = get_node_or_null("/root/CardEffects")
	if ce and ce.has_method("get_cooldown_reduction"):
		return float(ce.call("get_cooldown_reduction"))
	return 0.0


func _attack_damage_bonus() -> int:
	var ce: Node = get_node_or_null("/root/CardEffects")
	if ce and ce.has_method("get_attack_damage_bonus"):
		return int(ce.call("get_attack_damage_bonus"))
	return 0


func _finisher_damage_bonus() -> float:
	var ce: Node = get_node_or_null("/root/CardEffects")
	if ce and ce.has_method("get_finisher_damage_bonus"):
		return float(ce.call("get_finisher_damage_bonus"))
	return 0.0


func _add_style_on_hit() -> void:
	current_style = minf(max_style, current_style + style_per_hit)
	time_since_last_hit = 0.0
	_emit_style()


func _try_stealth_takedown() -> bool:
	if _stealth_zone == null or _player == null:
		return false
	if not _player.is_stealth_active():
		return false
	for body in _stealth_zone.get_overlapping_bodies():
		if not body.is_in_group("enemy"):
			continue
		if body.has_method("is_aware") and body.call("is_aware") == true:
			continue
		if not _is_behind_enemy(body as Node2D):
			continue
		if body.has_method("instant_kill"):
			body.call("instant_kill")
			AudioManager.play_sfx("enemy_hit", _player.global_position)
			EventBus.screen_shake.emit(5.0, 0.09)
			return true
	return false


func _is_behind_enemy(enemy: Node2D) -> bool:
	if enemy == null or _player == null:
		return false
	var to_player: Vector2 = (_player.global_position - enemy.global_position).normalized()
	var forward := Vector2.RIGHT
	if enemy is CharacterBody2D:
		var eb: CharacterBody2D = enemy
		if eb.velocity.length_squared() > 25.0:
			forward = eb.velocity.normalized()
	return to_player.dot(forward) < -0.3


func _request_light_or_takedown() -> void:
	if not can_act:
		return
	if _light_cd > 0.0:
		if _player != null and _player.has_method("notify_attack_spam"):
			_player.call("notify_attack_spam", 0.22)
		return
	if _try_stealth_takedown():
		last_attack_kind = "takedown"
		return
	last_attack_kind = "light"
	_run_light_attack_async()


func _request_heavy() -> void:
	if not can_act or _heavy_cd > 0.0:
		return
	last_attack_kind = "heavy"
	_run_heavy_attack_async()


func _request_finisher() -> void:
	if not can_act:
		return
	if current_style < max_style - 0.5:
		EventBus.objective_updated.emit("Finisher not ready: STYLE %d/%d." % [roundi(current_style), roundi(max_style)])
		return
	last_attack_kind = "finisher"
	_run_finisher_async()


func _request_dash() -> void:
	if not can_act or _dash == null:
		return
	if _dash.is_dashing:
		return
	if _dash_cd > 0.0:
		return
	var dir := _get_move_vector_from_input()
	if dir.length_squared() < 0.0001:
		return
	_run_dash_async(dir)


func _run_light_attack_async() -> void:
	var cd_red := _cooldown_reduction()
	_busy = true
	can_act = false
	if combo_timer > 0.0:
		combo_count = mini(combo_count + 1, 3)
	else:
		combo_count = 1
	combo_timer = combo_window_base * _combo_window_mult
	var bonus := float(_attack_damage_bonus())
	var dmg: float = base_light_damage * (1.0 + combo_damage_bonus_per_step * float(combo_count - 1)) + bonus
	_position_melee_forward(melee_forward_distance)
	_melee.damage = dmg
	_melee.begin_swing()
	AudioManager.play_sfx("quick_attack", _player.global_position)
	await get_tree().create_timer(light_active_window).timeout
	_melee.end_swing()
	await get_tree().create_timer(light_recovery).timeout
	_add_style_on_hit()
	_light_cd = 0.28 * (1.0 - cd_red)
	can_act = true
	_busy = false


func _run_heavy_attack_async() -> void:
	if _melee == null or _player == null:
		return
	var cd_red := _cooldown_reduction()
	_busy = true
	can_act = false
	var bonus := float(_attack_damage_bonus())
	var dmg: float = base_light_damage * heavy_damage_multiplier + bonus
	_position_melee_forward(melee_forward_distance * 1.05)
	_melee.damage = dmg
	await get_tree().create_timer(heavy_windup).timeout
	_melee.begin_swing()
	AudioManager.play_sfx("heavy_attack", _player.global_position)
	EventBus.screen_shake.emit(4.0, 0.1)
	await get_tree().create_timer(heavy_active).timeout
	_melee.end_swing()
	await get_tree().create_timer(heavy_recovery_time).timeout
	_add_style_on_hit()
	combo_count = 0
	combo_timer = 0.0
	_heavy_cd = 0.85 * (1.0 - cd_red)
	can_act = true
	_busy = false


func _run_finisher_async() -> void:
	if _melee == null or _player == null:
		return
	var cd_red := _cooldown_reduction()
	_busy = true
	can_act = false
	var dmg: float = base_light_damage * 4.0 + _finisher_damage_bonus()
	_position_melee_forward(finisher_forward_distance)
	_melee.damage = dmg
	await get_tree().create_timer(heavy_windup * 0.5).timeout
	_melee.begin_swing()
	AudioManager.play_sfx("quick_attack", _player.global_position)
	EventBus.screen_shake.emit(8.0, 0.12)
	await get_tree().create_timer(finisher_active).timeout
	_melee.end_swing()
	current_style = 0.0
	_emit_style()
	combo_count = 0
	combo_timer = 0.0
	await get_tree().create_timer(finisher_recovery).timeout
	_heavy_cd = maxf(_heavy_cd, 0.35 * (1.0 - cd_red))
	can_act = true
	_busy = false


func _run_dash_async(direction: Vector2) -> void:
	if _dash == null or _player == null:
		return
	var cd_red := _cooldown_reduction()
	_busy = true
	can_act = false
	_dash.execute(direction)
	AudioManager.play_sfx("dodge", _player.global_position)
	await _dash.dash_ended
	can_act = true
	_busy = false
	_dash_cd = dash_cooldown_base * (1.0 - cd_red)
