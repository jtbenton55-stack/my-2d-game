extends CharacterBody2D

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

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
@export var sniff_cooldown := 4.0
@export var fetch_cooldown := 5.0
@export var fetch_range := 170.0

var ability_meter := 100.0
var target: Node2D = null
var _sniff_cd := 0.0
var _fetch_cd := 0.0
var _stay_mode := false
var last_noise_result: Dictionary = {}

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
	_sniff_cd = maxf(0.0, _sniff_cd - delta)
	_fetch_cd = maxf(0.0, _fetch_cd - delta)
	_recharge(delta)
	_handle_commands()
	if not _stay_mode:
		_follow(delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide()

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
	last_noise_result = _emit_noise_event("bentley_bark", "bark", effective_radius, 1.0, {"ability": "bark_stun"})
	EventBus.bentley_ability_used.emit("bark_stun")
	EventBus.bentley_meter_changed.emit(ability_meter, ability_max)
	return true


func command_bark(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
	var ok := bark_stun()
	return _command_result(
		ok,
		"bark_executed" if ok else "bark_not_ready",
		"Bentley barked." if ok else "Bentley needs a breather.",
		{"ability_meter": ability_meter, "bark_radius": bark_radius, "noise_result": last_noise_result}
	)

func sniff() -> void:
	EventBus.objective_updated.emit("Bentley sniffs out the next clue.")
	AudioManager.play_sfx("bentley_sniff", global_position)


func command_sniff(_actor: Node = null, _context: Dictionary = {}) -> Dictionary:
	if _sniff_cd > 0.0:
		EventBus.objective_updated.emit("Bentley is still sniffing.")
		return _command_result(false, "sniff_cooldown", "Bentley is still sniffing.", {"cooldown": _sniff_cd})
	_sniff_cd = _effective_sniff_cooldown()
	EventBus.objective_updated.emit("Bentley sniffs the trail.")
	sniff()
	EventBus.bentley_ability_used.emit("sniff")
	return _command_result(true, "sniff_executed", "Bentley sniffed the trail.", {"cooldown": _sniff_cd})


func command_fetch(actor: Node = null, _context: Dictionary = {}) -> Dictionary:
	return _try_fetch(actor)


func command_crawlspace(_actor: Node = null, context: Dictionary = {}) -> Dictionary:
	global_position = _context_position(context, global_position)
	_stay_mode = true
	EventBus.objective_updated.emit("Bentley slips through the crawlspace.")
	EventBus.bentley_ability_used.emit("crawlspace")
	return _command_result(true, "crawlspace_executed", "Bentley used the crawlspace.", {"position": global_position, "staying": _stay_mode})


func command_wait(_actor: Node = null, context: Dictionary = {}) -> Dictionary:
	global_position = _context_position(context, global_position)
	_stay_mode = true
	EventBus.objective_updated.emit("Bentley waits.")
	EventBus.bentley_ability_used.emit("wait")
	return _command_result(true, "wait_executed", "Bentley waits at the marker.", {"position": global_position, "staying": _stay_mode})


func get_command_state() -> Dictionary:
	return {
		"staying": _stay_mode,
		"sniff_cooldown": _sniff_cd,
		"fetch_cooldown": _fetch_cd,
		"fetch_range": fetch_range,
		"effective_fetch_range": _effective_fetch_range(),
		"last_noise_result": last_noise_result,
	}


func _emit_noise_event(noise_id: String, kind: String, radius: float, strength: float, details: Dictionary = {}) -> Dictionary:
	var event := NoiseEventHelper.make_event(noise_id, "bentley", global_position, radius, strength, kind, "player", details)
	if EventBus.has_signal("mission_noise_emitted"):
		EventBus.mission_noise_emitted.emit(event)
	EventBus.debug("Bentley noise emitted %s radius=%.1f" % [kind, radius])
	var alert_result := {}
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller == null and get_tree().current_scene != null:
		controller = get_tree().current_scene.find_child("MissionAlertController", true, false)
	if controller != null and controller.has_method("register_noise_event"):
		alert_result = controller.call("register_noise_event", event)
	return {"ok": true, "code": "noise_emitted", "noise_event": event, "alert_result": alert_result}

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


func _handle_commands() -> void:
	if _command_pressed("bentley_bark") or _ability_pressed():
		if not bool(command_bark().get("ok", false)):
			EventBus.objective_updated.emit("Bentley needs a breather.")
	if _command_pressed("bentley_sniff"):
		command_sniff()
	if _command_pressed("bentley_fetch"):
		command_fetch()
	if _command_pressed("bentley_toggle_stay"):
		_stay_mode = not _stay_mode
		if _stay_mode:
			EventBus.objective_updated.emit("Bentley waits.")
		else:
			EventBus.objective_updated.emit("Bentley returns.")


func _try_fetch(actor: Node = null) -> Dictionary:
	if _fetch_cd > 0.0:
		EventBus.objective_updated.emit("Bentley needs a second.")
		return _command_result(false, "fetch_cooldown", "Bentley needs a second.", {"cooldown": _fetch_cd})
	_fetch_cd = _effective_fetch_cooldown()
	var player := actor if actor != null else get_tree().get_first_node_in_group("player")
	var nearest: Node2D = null
	var nearest_dist := INF
	var effective_range := _effective_fetch_range()
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node2D):
			continue
		var dist := global_position.distance_to((node as Node2D).global_position)
		if dist > effective_range or dist >= nearest_dist:
			continue
		if not _is_fetchable_node(node):
			continue
		nearest = node
		nearest_dist = dist
	if nearest == null:
		EventBus.objective_updated.emit("Nothing nearby to fetch.")
		return _command_result(false, "nothing_fetchable", "Nothing nearby to fetch.", {"fetch_range": effective_range})
	global_position = nearest.global_position + Vector2(-8, -8)
	var interacted := false
	if nearest.has_method("interact"):
		var result: Variant = nearest.interact(player if player != null else self)
		interacted = bool(result) if result is bool else true
	EventBus.objective_updated.emit("Bentley fetches it!")
	EventBus.bentley_ability_used.emit("fetch")
	return _command_result(
		interacted,
		"fetch_executed" if interacted else "fetch_interaction_failed",
		"Bentley fetches it!" if interacted else "Bentley reached the target, but could not fetch it.",
		{"target_path": str(nearest.get_path()), "target_name": nearest.name, "cooldown": _fetch_cd, "fetch_range": effective_range}
	)


func _is_fetchable_node(node: Node) -> bool:
	if node == null:
		return false
	var placeholder_id := _string_property_or_meta(node, "placeholder_id")
	var item_id := _string_property_or_meta(node, "item_id")
	var reward_kind := _string_property_or_meta(node, "reward_kind")
	var clue_id := _string_property_or_meta(node, "clue_id")
	var collectible_id := _string_property_or_meta(node, "collectible_id")
	var ctype := _string_property_or_meta(node, "collectible_type")
	if ctype == "":
		ctype = _string_property_or_meta(node, "category").to_lower()
	if item_id != "" or reward_kind == "item":
		return true
	if clue_id != "" or collectible_id != "":
		return true
	if ctype == "poop_bag" or ctype == "tiny_icon" or ctype == "glow_guy":
		return true
	return placeholder_id.contains("poop_bag") or placeholder_id.contains("keycard")


func _string_property_or_meta(node: Node, key: String) -> String:
	if node.has_meta(key):
		return String(node.get_meta(key))
	for property in node.get_property_list():
		if String(property.get("name", "")) == key:
			var value = node.get(key)
			return "" if value == null else String(value)
	return ""


func _effective_sniff_cooldown() -> float:
	return maxf(0.0, sniff_cooldown * _card_float("get_bentley_sniff_cooldown_multiplier", 1.0))


func _effective_fetch_cooldown() -> float:
	return maxf(0.0, fetch_cooldown * _card_float("get_bentley_fetch_cooldown_multiplier", 1.0))


func _effective_fetch_range() -> float:
	return fetch_range * _card_float("get_bentley_fetch_range_multiplier", 1.0)


func _context_position(context: Dictionary, fallback: Vector2) -> Vector2:
	var value: Variant = context.get("target_position", context.get("position", fallback))
	if value is Vector2:
		return value
	return fallback


func _command_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)


func _command_result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": "bentley",
		"details": details,
	}
