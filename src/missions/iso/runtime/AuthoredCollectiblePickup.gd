extends Area2D
## DEPRECATED (D6-06B): collision-only pickup path — use AuthoredPhase0JInteractablePickup instead.
## Kept for reference; CollectibleAuthoringRuntimeBuilder no longer spawns this script.

const TypedMissionCollectibleHelper := preload("res://src/missions/iso/TypedMissionCollectible.gd")
const PLAYER_COLLISION_MASK := 1

var _mission: Node = null
var _collectible_id: String = ""
var _collectible_type: String = ""
var _display_name: String = ""
var _one_shot := true
var _poop_count := 1
var _money_amount := 1
var _currency_type := "cash"
var _objective_id := ""
var _pickup_event_id := ""
var _pickup_radius := 40.0
var _collected := false
var _body_entered_connected := false


func _ready() -> void:
	_apply_pickup_collision_settings()
	_ensure_body_entered_connected()
	set_physics_process(true)


func configure_from_config(mission: Node, config: Dictionary) -> void:
	_mission = mission
	_collectible_id = String(config.get("collectible_id", "")).strip_edges()
	_collectible_type = String(config.get("collectible_type", "")).strip_edges()
	_display_name = String(config.get("display_name", "")).strip_edges()
	_one_shot = bool(config.get("one_shot", true))
	_poop_count = maxi(int(config.get("poop_count", 1)), 1)
	_money_amount = maxi(int(config.get("amount", 1)), 1)
	_currency_type = String(config.get("currency_type", "cash")).strip_edges()
	_objective_id = String(config.get("objective_id", "")).strip_edges()
	_pickup_event_id = String(config.get("pickup_event_id", "")).strip_edges()
	_pickup_radius = maxf(float(config.get("pickup_radius", 40.0)), 16.0)
	var pos_v: Variant = config.get("global_position", Vector2.ZERO)
	if pos_v is Vector2:
		global_position = pos_v as Vector2
	var color_v: Variant = config.get("preview_color", Color.WHITE)
	if color_v is Color:
		_apply_visual(color_v as Color)
	_apply_shape_radius(_pickup_radius)
	_apply_pickup_collision_settings()
	_ensure_body_entered_connected()
	if is_inside_tree():
		call_deferred("_check_overlapping_bodies")
	set_physics_process(not (_collected and _one_shot))


func _physics_process(_delta: float) -> void:
	if _collected and _one_shot:
		set_physics_process(false)
		return
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		if _is_player_collider(body):
			try_collect("overlap_scan", body)
			return


func _apply_shape_radius(radius: float) -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var circle := shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle
	circle.radius = radius
	shape_node.disabled = false


func _apply_pickup_collision_settings() -> void:
	collision_layer = 0
	collision_mask = PLAYER_COLLISION_MASK
	monitoring = true
	monitorable = false


func _ensure_body_entered_connected() -> void:
	if _body_entered_connected:
		return
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_body_entered_connected = true


func _check_overlapping_bodies() -> void:
	if _collected and _one_shot:
		return
	for body in get_overlapping_bodies():
		if _is_player_collider(body):
			try_collect("overlap_scan", body)
			return


func _apply_visual(tint: Color) -> void:
	var visual := get_node_or_null("Visual") as ColorRect
	if visual != null:
		visual.color = tint
		var half := _pickup_radius * 0.45
		visual.offset_left = -half
		visual.offset_top = -half
		visual.offset_right = half
		visual.offset_bottom = half
	var label := get_node_or_null("Label") as Label
	if label != null and _display_name != "":
		label.text = _display_name.substr(0, 1).to_upper()


func _is_player_collider(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	if body is CharacterBody2D:
		return true
	if body is PhysicsBody2D and (int(body.collision_layer) & PLAYER_COLLISION_MASK) != 0:
		return true
	var parent := body.get_parent()
	if parent != null and parent.is_in_group("player"):
		return true
	return false


func _on_body_entered(body: Node) -> void:
	if not _is_player_collider(body):
		return
	try_collect("body_entered", body)


func try_collect(source: String = "try_collect", body: Node = null) -> Dictionary:
	if _collected and _one_shot:
		return {"result": "already_collected", "collectible_id": _collectible_id, "source": source}
	var result := _perform_collect()
	result["source"] = source
	if body != null and is_instance_valid(body):
		result["body_name"] = body.name
		result["body_path"] = str(body.get_path())
	if bool(result.get("success", false)):
		_collected = true
		_record_on_mission(result)
		_emit_pickup_event()
		AudioManager.play_sfx("item_pickup", global_position)
		if _one_shot:
			_disable_pickup_collision()
			visible = false
			call_deferred("queue_free")
	return result


func _disable_pickup_collision() -> void:
	monitoring = false
	set_physics_process(false)
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null:
		shape_node.set_deferred("disabled", true)


func get_runtime_pickup_debug_state() -> Dictionary:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var radius := _pickup_radius
	if shape_node != null and shape_node.shape is CircleShape2D:
		radius = (shape_node.shape as CircleShape2D).radius
	return {
		"collectible_id": _collectible_id,
		"has_collision_shape": shape_node != null and shape_node.shape != null,
		"shape_disabled": shape_node.disabled if shape_node != null else true,
		"pickup_radius": radius,
		"monitoring": monitoring,
		"collision_mask": collision_mask,
		"collected": _collected,
	}


func _perform_collect() -> Dictionary:
	if _collectible_id == "" or _collectible_type == "":
		return {"success": false, "result": "rejected_missing_id", "collectible_id": _collectible_id}
	var mission_id := ""
	if _mission != null:
		var def_v: Variant = _mission.get("mission_definition")
		if def_v != null:
			mission_id = String(def_v.mission_id)
	match _collectible_type:
		"money":
			return _collect_money_proof(mission_id)
		"poop_bag":
			return _collect_poop_bag(mission_id)
		_:
			return _collect_typed(mission_id)


func _collect_typed(mission_id: String) -> Dictionary:
	var ok := TypedMissionCollectibleHelper.collect(
		_collectible_id, _collectible_type, mission_id, _display_name
	)
	if not ok:
		return {"success": false, "result": "already_collected", "collectible_id": _collectible_id}
	_emit_feedback_for_type()
	return {"success": true, "result": "collected", "collectible_id": _collectible_id}


func _collect_poop_bag(mission_id: String) -> Dictionary:
	var ok := TypedMissionCollectibleHelper.collect(
		_collectible_id, "poop_bag", mission_id, _display_name
	)
	if not ok:
		return {"success": false, "result": "already_collected", "collectible_id": _collectible_id}
	for _i in range(_poop_count - 1):
		GameState.add_poop_bag()
		if _mission != null and _mission.has_method("increment_attempt_counter"):
			_mission.call("increment_attempt_counter", "poop_bags_collected", 1)
	EventBus.objective_updated.emit(
		"+1 Bentley poop bag. Bentley pretends he didn't notice."
		if _poop_count <= 1
		else "+%d Bentley poop bags collected." % _poop_count
	)
	return {"success": true, "result": "collected", "collectible_id": _collectible_id}


func _collect_money_proof(_mission_id: String) -> Dictionary:
	var flag_key := "d6_06_money:" + _collectible_id
	if GameState.dialogue_flags.get(flag_key, false) == true:
		return {"success": false, "result": "already_collected", "collectible_id": _collectible_id}
	GameState.dialogue_flags[flag_key] = true
	if _mission != null and _mission.has_method("increment_attempt_counter"):
		var counter_key := "d6_06_authored_money_%s" % _currency_type
		_mission.call("increment_attempt_counter", counter_key, _money_amount)
	EventBus.game_state_changed.emit()
	EventBus.objective_updated.emit(
		"[proof] +$%d %s (no mission currency yet)" % [_money_amount, _currency_type]
	)
	return {"success": true, "result": "proof_collected", "collectible_id": _collectible_id}


func _emit_feedback_for_type() -> void:
	match _collectible_type:
		"polaroid":
			EventBus.objective_updated.emit("Polaroid collected: " + _display_name)
		"tiny_icon":
			EventBus.objective_updated.emit("Tiny Icon collected: " + _display_name)
		_:
			pass


func _record_on_mission(result: Dictionary) -> void:
	if _mission == null or not _mission.has_method("record_authored_collectible_pickup"):
		return
	var meta := get_runtime_pickup_debug_state()
	meta["source"] = String(result.get("source", "unknown"))
	meta["body_name"] = String(result.get("body_name", ""))
	meta["body_path"] = String(result.get("body_path", ""))
	_mission.call(
		"record_authored_collectible_pickup",
		_collectible_type,
		_collectible_id,
		result,
		_objective_id,
		meta
	)


func _emit_pickup_event() -> void:
	if _pickup_event_id == "" or _mission == null:
		return
	if not _mission.has_method("get_security_event_router"):
		return
	var router_v: Variant = _mission.call("get_security_event_router")
	if router_v is Node and (router_v as Node).has_method("emit_event"):
		(router_v as Node).call("emit_event", StringName(_pickup_event_id), {})
