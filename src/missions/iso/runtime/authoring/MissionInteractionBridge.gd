class_name MissionInteractionBridge
extends Node

const InputBindingFormatterScript := preload("res://src/utils/InputBindingFormatter.gd")
const LEGACY_CANDIDATE_GROUPS: Array[String] = [
	"phase0j_interactable",
	"phase0j_marker_debug",
	"phase0k_louis_exit",
]
const PLUG_AND_PLAY_CANDIDATE_GROUPS: Array[String] = [
	"mission_mechanic",
	"interactable",
]
const INTERACTION_METHODS: Array[String] = ["interact", "on_interact", "use", "inspect_marker"]

@export var player_path: NodePath
@export var action_interact: StringName = &"interact"
@export var interaction_radius: float = 144.0
@export var cooldown_seconds: float = 0.20
@export var prompt_refresh_interval: float = 0.20
@export var prefer_available: bool = true
@export var prefer_uncompleted: bool = true
@export var debug_enabled: bool = true
@export var include_legacy_candidates: bool = true
@export var prompt_target_path: NodePath
@export var wall_occlusion_mask: int = 4
@export var feedback_hold_seconds: float = 2.25

var last_candidate: Node = null
var last_interaction_result: bool = false
var last_prompt_text: String = ""

var _cooldown: float = 0.0
var _prompt_refresh_elapsed: float = 0.0
var _feedback_hold_remaining: float = 0.0


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
	if _feedback_hold_remaining > 0.0:
		_feedback_hold_remaining = maxf(0.0, _feedback_hold_remaining - delta)
		return
	if prompt_target_path != NodePath():
		_prompt_refresh_elapsed += delta
		if _prompt_refresh_elapsed >= maxf(prompt_refresh_interval, 0.05):
			_prompt_refresh_elapsed = 0.0
			refresh_nearest_prompt()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _cooldown > 0.0:
		return
	if _is_action_pressed(event, action_interact):
		if try_interact():
			get_viewport().set_input_as_handled()
		return


func find_player() -> Node:
	if player_path != NodePath():
		var explicit := get_node_or_null(player_path)
		if explicit != null:
			return explicit
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")


func collect_candidates() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var tree := get_tree()
	if tree == null:
		return out
	for group_name: String in _candidate_groups():
		for node: Node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if seen.has(node):
				continue
			if not has_interaction_method(node):
				continue
			seen[node] = true
			out.append(node)
	return out


func find_best_candidate(test_position: Vector2, require_available: bool = true) -> Dictionary:
	var actor := find_player()
	var candidates: Array[Dictionary] = []
	for node: Node in collect_candidates():
		if not (node is Node2D):
			continue
		var node2d := node as Node2D
		var dist: float = test_position.distance_to(node2d.global_position)
		if node is Area2D and actor is PhysicsBody2D and (node as Area2D).overlaps_body(actor as PhysicsBody2D):
			dist = 0.0
		if dist > interaction_radius:
			continue
		if _is_candidate_occluded(test_position, node2d):
			continue
		var available: bool = is_candidate_available(node, actor)
		if require_available and not available:
			continue
		candidates.append({
			"node": node,
			"dist": dist,
			"priority": get_candidate_priority(node, actor),
			"available": available,
			"completed": is_candidate_completed(node),
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_candidate_entries(a, b)
	)
	return candidates[0]


func try_interact() -> bool:
	var player := find_player()
	if not (player is Node2D):
		last_candidate = null
		last_interaction_result = false
		return false
	return try_interact_at_position((player as Node2D).global_position)


func try_interact_at_position(test_position: Vector2) -> bool:
	if _cooldown > 0.0:
		return false
	var entry := find_best_candidate(test_position, prefer_available)
	if entry.is_empty():
		var locked_entry := find_best_candidate(test_position, false)
		if not locked_entry.is_empty():
			var locked_candidate: Node = locked_entry.get("node")
			last_candidate = locked_candidate
			last_interaction_result = false
			_update_prompt_label(get_candidate_prompt(locked_candidate))
			_cooldown = cooldown_seconds
			return true
		last_candidate = null
		last_interaction_result = false
		_update_prompt_label("")
		return false
	var candidate: Node = entry.get("node")
	var actor := find_player()
	var result: bool = _call_candidate(candidate, actor)
	last_candidate = candidate
	last_interaction_result = result
	var feedback := _candidate_result_message(candidate)
	if feedback == "":
		feedback = get_candidate_prompt(candidate)
	_show_feedback(feedback)
	_cooldown = cooldown_seconds
	if debug_enabled:
		print("[MissionInteractionBridge] Interacted with %s -> %s" % [candidate.name, _candidate_debug_result(candidate, result)])
	return result


func get_candidate_prompt(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_interaction_text"):
		return String(node.call("get_interaction_text"))
	return node.name


func get_candidate_priority(node: Node, actor: Node = null) -> int:
	if node != null and node.has_method("get_interaction_priority"):
		return int(node.call("get_interaction_priority", actor))
	return 300


func is_candidate_available(node: Node, actor: Node = null) -> bool:
	if node == null:
		return false
	if node.has_method("is_interaction_available"):
		return bool(node.call("is_interaction_available", actor))
	return true


func is_candidate_completed(node: Node) -> bool:
	if node == null:
		return false
	if node.has_method("is_completed"):
		return bool(node.call("is_completed"))
	if node.get("used") != null:
		return bool(node.get("used"))
	if node.get("collected") != null:
		return bool(node.get("collected"))
	return false


func has_interaction_method(node: Node) -> bool:
	if node == null:
		return false
	for method_name: String in INTERACTION_METHODS:
		if node.has_method(method_name):
			return true
	return false


func _sort_candidate_entries(a: Dictionary, b: Dictionary) -> bool:
	if prefer_available and bool(a.get("available", true)) != bool(b.get("available", true)):
		return bool(a.get("available", true))
	if prefer_uncompleted and bool(a.get("completed", false)) != bool(b.get("completed", false)):
		return not bool(a.get("completed", false))
	if int(a.get("priority", 0)) != int(b.get("priority", 0)):
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	return float(a.get("dist", 0.0)) < float(b.get("dist", 0.0))


func _call_candidate(node: Node, actor: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	for method_name: String in INTERACTION_METHODS:
		if not node.has_method(method_name):
			continue
		var result: Variant = node.call(method_name, actor)
		if result is bool:
			return bool(result)
		return true
	return false


func _candidate_debug_result(node: Node, fallback: bool) -> String:
	for property_name in ["last_extraction_result", "last_teleport_result", "last_activation_result"]:
		var value: Variant = node.get(property_name) if node != null else null
		if value is Dictionary and not (value as Dictionary).is_empty():
			var result: Dictionary = value as Dictionary
			return "%s ok=%s message=%s" % [
				String(result.get("code", "result")),
				str(bool(result.get("ok", fallback))),
				String(result.get("message", "")),
			]
	return str(fallback)


func _candidate_result_message(node: Node) -> String:
	for property_name: String in ["last_activation_result", "last_inspection_result", "last_protocol_result", "last_task_result", "last_command_result", "last_hide_result"]:
		var value: Variant = node.get(property_name) if node != null else null
		if value is Dictionary and not (value as Dictionary).is_empty():
			var message := String((value as Dictionary).get("message", "")).strip_edges()
			if message != "" and message != "Mechanic activated.":
				return message
	return ""


func _show_feedback(text: String) -> void:
	_feedback_hold_remaining = maxf(feedback_hold_seconds, 0.0)
	_update_prompt_label(text)


func _is_candidate_occluded(from_position: Vector2, candidate: Node2D) -> bool:
	if wall_occlusion_mask == 0 or candidate == null or not candidate.is_inside_tree():
		return false
	var to_position := candidate.global_position
	var delta := to_position - from_position
	if delta.length() <= 6.0:
		return false
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position - delta.normalized() * 4.0)
	query.collision_mask = wall_occlusion_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not candidate.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func refresh_nearest_prompt() -> void:
	var player := find_player()
	if not (player is Node2D):
		_update_prompt_label("")
		return
	var entry := find_best_candidate((player as Node2D).global_position, false)
	if entry.is_empty():
		_update_prompt_label("")
		return
	var candidate: Node = entry.get("node")
	_update_prompt_label(get_candidate_prompt(candidate))


func _update_prompt_label(text: String) -> void:
	var display_text := InputBindingFormatterScript.format_interact_prompt(text)
	last_prompt_text = display_text
	if prompt_target_path == NodePath():
		return
	var target := get_node_or_null(prompt_target_path)
	if target == null:
		return
	if target.has_method("set_text"):
		target.call("set_text", display_text)
	if target is CanvasItem:
		(target as CanvasItem).visible = display_text.strip_edges() != ""


func _candidate_groups() -> Array[String]:
	var groups: Array[String] = []
	groups.append_array(PLUG_AND_PLAY_CANDIDATE_GROUPS)
	if include_legacy_candidates:
		groups.append_array(LEGACY_CANDIDATE_GROUPS)
	return groups


func _is_action_pressed(event: InputEvent, action: StringName) -> bool:
	if action == &"":
		return false
	var action_name := String(action)
	if InputMap.has_action(action_name):
		return event.is_action_pressed(action_name)
	return false
