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
@export var click_interaction_radius := 72.0
@export var case_joint_range := 220.0
@export var case_joint_duration := 1.8
@export var case_joint_cooldown := 9.0
@export var poop_throw_range := 210.0

var current_health := 100
var facing := Vector2.DOWN
var dodge_timer := 0.0
var dodge_cooldown_timer := 0.0
var attack_timer := 0.0
var invulnerable := false
var can_control := true
var is_stealth := false
var stealth_indicator: ColorRect = null

var _combat: Node = null
## Blocks duplicate damage for a short window after Bentley's one-shot save (multi-hit attacks).
var _dental_save_grace_until_msec: int = 0
var _stun_timer: float = 0.0
var _guard_spam_pressure: float = 0.0
var _case_joint_timer: float = 0.0
var _case_joint_cooldown_timer: float = 0.0
var _case_highlights: Dictionary = {}
var _poop_bag_targeting := false

func is_stealth_active() -> bool:
	return is_stealth

func _uses_hitbox_combat() -> bool:
	return _combat != null and _combat.enabled

func _ready() -> void:
	add_to_group("player")
	_combat = get_node_or_null("PlayerCombatController")
	max_health = _card_int("get_player_max_health", max_health)
	current_health = min(max_health, GameState.player_health if GameState.player_health > 0 else max_health)
	GameState.player_max_health = max_health
	GameState.player_health = current_health
	EventBus.player_health_changed.emit(current_health, max_health)
	var melee_hb := get_node_or_null("PlayerCombatController/MeleeHitbox")
	if melee_hb:
		melee_hb.monitoring = false
	_create_stealth_indicator()
	_update_sprite()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not can_control:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_vector := _get_move_vector()
	if input_vector.length() > 0.01:
		facing = input_vector.normalized()

	var combat_on := _uses_hitbox_combat()
	if combat_on:
		var dashing := false
		if _combat.has_method("is_dashing"):
			dashing = _combat.is_dashing()
		if not _combat.can_act and not dashing:
			input_vector = Vector2.ZERO
	else:
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
	
	if combat_on:
		velocity = input_vector * move_speed
	elif dodge_timer > 0.0:
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


func _unhandled_input(event: InputEvent) -> void:
	if not can_control:
		return
	if event.is_action_pressed("case_the_joint"):
		_try_case_the_joint()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("poop_bag_targeting"):
		if _poop_bag_targeting:
			_cancel_poop_bag_targeting("Throw canceled.")
		else:
			_enter_poop_bag_targeting()
		get_viewport().set_input_as_handled()
		return
	if _poop_bag_targeting and event.is_action_pressed("ui_cancel"):
		_cancel_poop_bag_targeting("Throw canceled.")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _poop_bag_targeting:
			_try_throw_poop_bag(get_global_mouse_position())
			get_viewport().set_input_as_handled()
			return
		if _should_skip_world_interact():
			return
		if _try_click_interact(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
	elif _poop_bag_targeting and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_poop_bag_targeting("Throw canceled.")
		get_viewport().set_input_as_handled()

func _update_timers(delta: float) -> void:
	if not _uses_hitbox_combat():
		if dodge_timer > 0.0:
			dodge_timer -= delta
			if dodge_timer <= 0.0:
				invulnerable = false
		if dodge_cooldown_timer > 0.0:
			dodge_cooldown_timer -= delta
		if attack_timer > 0.0:
			attack_timer -= delta
	if _case_joint_timer > 0.0:
		_case_joint_timer -= delta
		if _case_joint_timer <= 0.0:
			_clear_case_highlights()
	if _case_joint_cooldown_timer > 0.0:
		_case_joint_cooldown_timer -= delta
	_guard_spam_pressure = maxf(0.0, _guard_spam_pressure - delta * 0.8)


func notify_attack_spam(amount: float = 0.25) -> void:
	_guard_spam_pressure = clampf(_guard_spam_pressure + amount, 0.0, 1.0)


func apply_guard_stun(base_chance: float = 0.1, duration: float = 0.5) -> bool:
	var chance := clampf(base_chance + _guard_spam_pressure * 0.45, 0.0, 0.9)
	if randf() > chance:
		return false
	_stun_timer = maxf(_stun_timer, duration)
	DialogueManager.start_simple_dialogue([{ "speaker": "Jake", "text": "Stunned by baton strike!" }])
	EventBus.screen_shake.emit(1.4, 0.08)
	return true

func _get_move_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y).normalized()

func _attack() -> void:
	var cd_reduction: float = _card_float("get_cooldown_reduction", 0.0)
	attack_timer = attack_cooldown * (1.0 - cd_reduction)
	AudioManager.play_sfx("quick_attack", global_position)
	EventBus.debug("Player attacked.")
	var damage_bonus: int = _card_int("get_attack_damage_bonus", 0)
	var total_damage: int = attack_damage + damage_bonus
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= attack_range:
			var direction: Vector2 = (enemy.global_position - global_position).normalized()
			if facing.dot(direction) > -0.25 and enemy.has_method("take_damage"):
				enemy.take_damage(total_damage, self)

func take_damage(amount: int, _source: Node = null) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec < _dental_save_grace_until_msec:
		return
	if invulnerable or is_in_group("invulnerable") or current_health <= 0:
		return
	if GameState.has_selected_card("bentley_dental_boy") and not GameState.dialogue_flags.get("dental_boy_used", false):
		GameState.dialogue_flags["dental_boy_used"] = true
		_dental_save_grace_until_msec = now_msec + 500
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
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("interactable"):
		# Only consider nodes that actually implement interact; otherwise a large
		# Area2D in "interactable" (e.g. trigger zones) wins by distance and blocks E.
		if node is Node2D and node.has_method("interact"):
			if node.has_method("is_interaction_available") and not _as_bool_safe(node.call("is_interaction_available", self)):
				continue
			if node.has_method("should_show_interaction_prompt") and not _as_bool_safe(node.call("should_show_interaction_prompt")):
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist >= 72.0:
				continue
			var priority := 400
			if node.has_method("get_interaction_priority"):
				priority = _as_priority_safe(node.call("get_interaction_priority", self), node)
			var completed := false
			if node.has_method("is_completed"):
				completed = _as_bool_safe(node.call("is_completed"))
			elif node.has_method("get"):
				completed = _as_bool_safe(node.get("completed"))
			candidates.append({
				"node": node,
				"dist": dist,
				"priority": priority,
				"completed": completed,
			})
	if candidates.is_empty():
		return
	var incomplete: Array = []
	for entry in candidates:
		if not _as_bool_safe(entry["completed"]):
			incomplete.append(entry)
	var pool := incomplete if not incomplete.is_empty() else candidates
	pool.sort_custom(func(a, b):
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) > int(b["priority"])
		return float(a["dist"]) < float(b["dist"])
	)
	var best: Node = pool[0]["node"] as Node
	if best != null:
		best.interact(self)


func _try_click_interact(world_pos: Vector2) -> bool:
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node2D and node.has_method("interact")):
			continue
		if node.has_method("is_interaction_available") and not _as_bool_safe(node.call("is_interaction_available", self)):
			continue
		var click_dist := world_pos.distance_to((node as Node2D).global_position)
		if click_dist > 44.0:
			continue
		var priority := 400
		if node.has_method("get_interaction_priority"):
			priority = _as_priority_safe(node.call("get_interaction_priority", self), node)
		candidates.append({"node": node, "click_dist": click_dist, "priority": priority})
	if candidates.is_empty():
		return false
	candidates.sort_custom(func(a, b):
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) > int(b["priority"])
		return float(a["click_dist"]) < float(b["click_dist"])
	)
	if candidates.size() > 1 and OS.is_debug_build():
		EventBus.warn("Ambiguous click interaction near %s (%d candidates)." % [str(world_pos), candidates.size()])
	var target: Node2D = candidates[0]["node"] as Node2D
	if target == null:
		return false
	var dist_to_player := global_position.distance_to(target.global_position)
	if dist_to_player > click_interaction_radius:
		DialogueManager.start_simple_dialogue([{ "speaker": "Jake", "text": "Move closer." }])
		return true
	target.interact(self)
	return true


func _try_case_the_joint() -> void:
	if _case_joint_cooldown_timer > 0.0:
		EventBus.objective_updated.emit("Focus not ready.")
		return
	_case_joint_cooldown_timer = case_joint_cooldown
	_case_joint_timer = case_joint_duration
	_clear_case_highlights()
	var found := 0
	for node in _collect_case_targets():
		_highlight_case_target(node)
		found += 1
		if found >= 12:
			break
	EventBus.screen_shake.emit(0.55, 0.05)
	EventBus.objective_updated.emit("Case the Joint: %d nearby points of interest." % found)


func _collect_case_targets() -> Array:
	var out: Array = []
	var groups := ["interactable", "enemy", "iso_security_camera"]
	for group_name in groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D):
				continue
			if global_position.distance_to((node as Node2D).global_position) > case_joint_range:
				continue
			out.append(node)
	return out


func _highlight_case_target(node: Node) -> void:
	if node == null or _case_highlights.has(node):
		return
	if node is CanvasItem:
		_case_highlights[node] = (node as CanvasItem).modulate
		(node as CanvasItem).modulate = Color(1.18, 1.12, 0.78, 1.0)


func _clear_case_highlights() -> void:
	for node in _case_highlights.keys():
		if not is_instance_valid(node):
			continue
		if node is CanvasItem:
			(node as CanvasItem).modulate = _case_highlights[node]
	_case_highlights.clear()


func _enter_poop_bag_targeting() -> void:
	if GameState.get_poop_bag_count() <= 0:
		EventBus.objective_updated.emit("No poop bags.")
		return
	_poop_bag_targeting = true
	EventBus.objective_updated.emit("Click where to throw.")


func _cancel_poop_bag_targeting(text: String = "Throw canceled.") -> void:
	_poop_bag_targeting = false
	if text != "":
		EventBus.objective_updated.emit(text)


func _try_throw_poop_bag(world_pos: Vector2) -> void:
	if not _poop_bag_targeting:
		return
	if global_position.distance_to(world_pos) > poop_throw_range:
		EventBus.objective_updated.emit("Too far.")
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("deploy_poop_bag_decoy_at"):
		EventBus.objective_updated.emit("Can't throw there.")
		return
	if not scene.call("deploy_poop_bag_decoy_at", world_pos):
		EventBus.objective_updated.emit("Can't throw there.")
		return
	if not GameState.try_consume_poop_bag():
		EventBus.objective_updated.emit("No poop bags.")
		return
	if scene.has_method("increment_attempt_counter"):
		scene.call("increment_attempt_counter", "poop_bags_used", 1)
	_poop_bag_targeting = false
	EventBus.objective_updated.emit("Poop bag deployed.")


func _as_bool_safe(value: Variant) -> bool:
	if value == null:
		return false
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return absf(float(value)) > 0.00001
		TYPE_STRING:
			var text := String(value).strip_edges().to_lower()
			if text == "" or text == "false" or text == "0" or text == "no":
				return false
			return true
		_:
			return true


func _as_priority_safe(value: Variant, node: Node) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return int(round(float(value)))
		_:
			if OS.is_debug_build():
				push_warning("Invalid interaction priority from %s; using default 400." % [str(node.name)])
			return 400

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
