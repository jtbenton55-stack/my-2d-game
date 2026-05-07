@tool
class_name Phase0JInteractionBridge
extends Node

@export var player_path: NodePath
@export var interactables_root_path: NodePath = NodePath("../../GeneratedRuntimeInteractables")
@export var marker_debug_root_path: NodePath = NodePath("../../GeneratedRuntimeMarkerDebugInteractables")
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")
@export var action_interact: String = "interact"
@export var action_scan_or_debug: String = "case_the_joint"
@export var interaction_radius: float = 144.0
@export var cooldown_seconds: float = 0.20
@export var debug_enabled: bool = true
@export var prefer_uncollected: bool = true
@export var show_nearest_on_hud: bool = true

var _cooldown := 0.0

func _ready() -> void:
	set_meta("generated_by", "Phase0J-C2")
	set_meta("scene_local_only", true)
	if interaction_radius < 96.0:
		interaction_radius = 96.0
	_hud_message("Phase0J bridge ready: E/Q radius %.0f" % interaction_radius)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if show_nearest_on_hud and not _is_code_ui_open():
		var player := _find_player()
		if player is Node2D:
			var entry := find_best_candidate((player as Node2D).global_position, false)
			if not entry.is_empty():
				var node: Node = entry.get("node")
				_set_nearest(_candidate_id(node), _candidate_category(node), float(entry.get("dist", 0.0)))


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _is_code_ui_open() or _has_blocking_ui():
		return
	if _cooldown > 0.0:
		return
	if InputMap.has_action(action_interact) and event.is_action_pressed(action_interact):
		if _try_interact():
			get_viewport().set_input_as_handled()
		return
	if InputMap.has_action(action_scan_or_debug) and event.is_action_pressed(action_scan_or_debug):
		_try_interact()
		return


func _try_interact() -> bool:
	var player := _find_player()
	if not (player is Node2D):
		return false
	var entry := find_best_candidate((player as Node2D).global_position, true)
	if entry.is_empty():
		_hud_message("No Phase0J marker nearby")
		_cooldown = cooldown_seconds
		return false
	var best: Node = entry.get("node")
	if debug_enabled:
		var id := _candidate_id(best)
		print("[Phase0J-C] Interacting with %s" % id)
	_call_candidate(best, player)
	_cooldown = cooldown_seconds
	return true


func find_best_candidate(test_position: Vector2, require_available: bool = true) -> Dictionary:
	var candidates: Array = []
	for node in _collect_candidates():
		if not (node is Node2D):
			continue
		if not _has_interaction_method(node):
			continue
		if require_available and node.has_method("is_interaction_available") and not bool(node.call("is_interaction_available", _find_player())):
			continue
		var dist := test_position.distance_to((node as Node2D).global_position)
		if dist > interaction_radius:
			continue
		candidates.append({
			"node": node,
			"dist": dist,
			"priority": _candidate_priority(node),
			"safe": _candidate_id(node) == "SAFE_CODE_INPUT_ZONE",
			"completed": _candidate_completed(node),
		})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.safe) != bool(b.safe):
			return bool(a.safe)
		if prefer_uncollected and bool(a.completed) != bool(b.completed):
			return not bool(a.completed)
		if int(a.priority) != int(b.priority):
			return int(a.priority) > int(b.priority)
		return float(a.dist) < float(b.dist)
	)
	return candidates[0]


func try_interact_at_position(test_position: Vector2) -> bool:
	var entry := find_best_candidate(test_position, false)
	if entry.is_empty():
		return false
	return _call_candidate(entry.get("node"), _find_player())


func _find_player() -> Node:
	if player_path != NodePath():
		var explicit := get_node_or_null(player_path)
		if explicit != null:
			return explicit
	return get_tree().get_first_node_in_group("player")


func _has_blocking_ui() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


func _is_code_ui_open() -> bool:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("is_code_ui_open") and bool(hud.call("is_code_ui_open")):
		return true
	return false


func _collect_candidates() -> Array:
	var out: Array = []
	var seen := {}
	for group_name in ["phase0j_interactable", "phase0j_marker_debug", "interactable"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if seen.has(node):
				continue
			if not _is_phase0j_candidate(node):
				continue
			seen[node] = true
			out.append(node)
	return out


func _is_phase0j_candidate(node: Node) -> bool:
	if node == null:
		return false
	if node.is_in_group("phase0j_interactable") or node.is_in_group("phase0j_marker_debug"):
		return true
	var generated := String(node.get_meta("generated_by", ""))
	return generated.begins_with("Phase0J")


func _has_interaction_method(node: Node) -> bool:
	return node.has_method("interact") or node.has_method("on_interact") or node.has_method("use") or node.has_method("inspect_marker")


func _call_candidate(node: Node, player: Node) -> bool:
	for method in ["interact", "on_interact", "use", "inspect_marker"]:
		if node.has_method(method):
			node.call(method, player)
			return true
	return false


func _candidate_id(node: Node) -> String:
	if node == null:
		return ""
	for property_name in ["candidate_id", "marker_id"]:
		var value = node.get(property_name)
		if value != null and String(value) != "":
			return String(value)
	return String(node.name)


func _candidate_category(node: Node) -> String:
	if node == null:
		return ""
	var value = node.get("category")
	if value != null and String(value) != "":
		return String(value)
	return String(node.get_meta("category", ""))


func _candidate_priority(node: Node) -> int:
	if node != null and node.has_method("get_interaction_priority"):
		return int(node.call("get_interaction_priority", _find_player()))
	return 300


func _candidate_completed(node: Node) -> bool:
	if node != null and node.has_method("is_completed"):
		return bool(node.call("is_completed"))
	var value = node.get("collected")
	return bool(value) if value != null else false


func _hud_message(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 3.0)


func _set_nearest(id: String, category: String, distance: float) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("set_nearest_marker"):
		hud.call("set_nearest_marker", id, category, distance)
