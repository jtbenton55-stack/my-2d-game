@tool
class_name Phase0JInteractablePickup
extends Area2D

signal collected_signal(candidate_id: String, category: String)

@export var candidate_id: String = ""
@export var category: String = "ITEM"
@export var prompt_text: String = "Pick up"
@export var one_shot: bool = true
@export var collected: bool = false
@export var debug_enabled: bool = true
@export var visual_type: String = "item"
@export var interaction_priority: int = 500
@export var code_gate_controller_path: NodePath
@export var debug_hud_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JDebugHUD")
@export var runtime_label_path: NodePath
@export var mission_state_adapter_path: NodePath = NodePath("../../RuntimeHelpers/Phase0JMissionStateAdapter")


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("phase0j_interactable")
	collision_layer = 8
	collision_mask = 1
	set_meta("generated_by", "Phase0J-C2")
	set_meta("candidate_id", candidate_id)
	set_meta("category", category)
	set_meta("collected", collected)


func interact(player: Node = null) -> bool:
	return _do_interact(player)


func on_interact(player: Node = null) -> bool:
	return _do_interact(player)


func use(player: Node = null) -> bool:
	return _do_interact(player)


func pickup(player: Node = null) -> bool:
	return _do_interact(player)


func collect(player: Node = null) -> bool:
	return _do_interact(player)


func is_interaction_available(_player: Node = null) -> bool:
	if one_shot and collected:
		return false
	return true


func should_show_interaction_prompt() -> bool:
	return is_interaction_available()


func get_interaction_priority(_player: Node = null) -> int:
	return interaction_priority


func is_completed() -> bool:
	return collected


func get_interaction_text() -> String:
	return prompt_text


func _do_interact(_player: Node = null) -> bool:
	if one_shot and collected:
		_feedback("Already collected: %s" % candidate_id, false)
		return true
	if code_gate_controller_path != NodePath():
		var controller := get_node_or_null(code_gate_controller_path)
		if controller != null and controller.has_method("open_code_ui"):
			controller.call("open_code_ui")
			return true
		push_warning("[Phase0J-C] Code gate controller missing for %s" % candidate_id)
		_feedback("Code gate controller missing", false)
		return false
	var result := _collect_with_state_adapter()
	if not bool(result.get("success", false)):
		_feedback(String(result.get("message", "Collection failed")), false)
		return false
	if bool(result.get("already_done", false)):
		_feedback(String(result.get("message", "Already collected: %s" % candidate_id)), false)
		return true
	_mark_collected()
	_feedback(String(result.get("message", _collect_message())), true)
	collected_signal.emit(candidate_id, category)
	return true


func _mark_collected() -> void:
	collected = true
	set_meta("collected", true)
	if one_shot:
		for child in get_children():
			if child is CanvasItem:
				(child as CanvasItem).modulate = Color(0.35, 0.35, 0.35, 0.6)
		var label := get_node_or_null(runtime_label_path)
		if label != null and label.has_method("mark_collected"):
			label.call("mark_collected")
		_disable_pickup_collision()


func _disable_pickup_collision() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0


func _safe_add_poop_bag() -> void:
	if Engine.is_editor_hint():
		return
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		if game_state != null and game_state.has_method("add_poop_bag"):
			game_state.call("add_poop_bag")


func _collect_with_state_adapter() -> Dictionary:
	var payload := _payload()
	var adapter := get_node_or_null(mission_state_adapter_path)
	if adapter != null and adapter.has_method("collect_item"):
		return adapter.call("collect_item", candidate_id, category, payload)
	return {
		"success": false,
		"already_done": false,
		"message": "Mission state adapter missing for %s" % candidate_id,
		"real_system_updated": false,
		"menu_updated": false,
		"warning": "Phase0JMissionStateAdapter missing",
	}


func _payload() -> Dictionary:
	var aliases: Array = []
	var raw_aliases = get_meta("merged_aliases", PackedStringArray())
	if raw_aliases is PackedStringArray:
		for alias in raw_aliases:
			aliases.append(String(alias))
	elif raw_aliases is Array:
		for alias in raw_aliases:
			aliases.append(String(alias))
	return {
		"candidate_id": candidate_id,
		"marker_id": candidate_id,
		"category": category,
		"display_name": _display_name(),
		"source": String(get_meta("source", "")),
		"final_cell": get_meta("final_cell", PackedInt32Array()),
		"mission_id": "taco_bell_drop",
		"aliases": aliases,
		"polaroid_id": _payload_polaroid_id(aliases),
		"clue_id": candidate_id,
		"objective_id": "delivery_bag_recovered" if candidate_id == "OBJ_bag_recovery" else "",
		"count_group": category,
	}


func _payload_polaroid_id(aliases: Array) -> String:
	for alias in aliases:
		var text := String(alias)
		if text == "hidden_polaroid_market_rain":
			return "taco_bell_midnight_market_rain"
		if text == "perfect_polaroid_garage_ambush":
			return "taco_bell_perfect_ambush"
	return candidate_id


func _display_name() -> String:
	return candidate_id.replace("_", " ").capitalize()


func inspect_marker(player: Node = null) -> bool:
	return _do_interact(player)


func _collect_message() -> String:
	match category:
		"BAG", "poop_bag":
			return "Collected poop bag: %s" % candidate_id
		"evidence_clue", "CLUE", "intel":
			return "Collected clue: %s" % candidate_id
		"polaroid", "PHOTO":
			return "Collected photo: %s" % candidate_id
		"glow_guy", "GLOW":
			return "Collected Glow Guy: %s" % candidate_id
		"tiny_icon", "TINY":
			return "Collected tiny item: %s" % candidate_id
		_:
			if candidate_id == "OBJ_bag_recovery":
				return "Objective collected: Delivery bag"
			return "Collected: %s (%s)" % [candidate_id, category]


func _feedback(text: String, did_collect: bool) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null:
		if hud.has_method("show_message"):
			hud.call("show_message", text, 3.0)
		if did_collect and hud.has_method("increment_collected"):
			hud.call("increment_collected", category)
	if debug_enabled:
		print("[Phase0J-C2] " + text)
