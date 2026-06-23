class_name PlayerControlBridge
extends Node

@export var player_path: NodePath = NodePath("../Player")

var _locked_players: Dictionary = {}


func _exit_tree() -> void:
	restore_all_controls()


func lock_input(reason: String = "presentation", player: Node = null) -> Dictionary:
	var target := _resolve_player(player)
	if target == null:
		return _result(false, "player_missing", "Player node is missing.")
	var key := str(target.get_path())
	if not _locked_players.has(key):
		_locked_players[key] = {"player": target, "can_control": _get_can_control(target)}
	_set_can_control(target, false)
	return _result(true, "player_input_locked", "Player input locked.", key, {"reason": reason})


func restore_input(player: Node = null) -> Dictionary:
	var target := _resolve_player(player)
	if target == null:
		return _result(false, "player_missing", "Player node is missing.")
	var key := str(target.get_path())
	var previous := true
	if _locked_players.has(key):
		var data: Dictionary = _locked_players.get(key, {})
		previous = bool(data.get("can_control", true))
		_locked_players.erase(key)
	_set_can_control(target, previous)
	return _result(true, "player_input_restored", "Player input restored.", key, {"can_control": previous})


func restore_all_controls() -> Dictionary:
	var restored := 0
	for key in _locked_players.keys():
		var data: Dictionary = _locked_players.get(key, {})
		var player: Node = data.get("player", null) as Node
		if is_instance_valid(player):
			_set_can_control(player, bool(data.get("can_control", true)))
			restored += 1
	_locked_players.clear()
	return _result(true, "player_inputs_restored", "Player controls restored.", "", {"count": restored})


func guide_to(position: Vector2, player: Node = null, restore_after: bool = true) -> Dictionary:
	var target := _resolve_player(player)
	if target == null or not (target is Node2D):
		return _result(false, "player_missing", "Player Node2D is missing.")
	var lock_result := lock_input("guided_movement", target)
	(target as Node2D).global_position = position
	if restore_after:
		restore_input(target)
	return _result(true, "player_guided", "Player moved to guided position.", str(target.get_path()), {"position": position, "lock_result": lock_result})


func _resolve_player(candidate: Node = null) -> Node:
	if candidate != null:
		return candidate
	var from_path := get_node_or_null(player_path)
	if from_path != null:
		return from_path
	if is_inside_tree():
		var grouped := get_tree().get_first_node_in_group("player")
		if grouped != null:
			return grouped
		if get_tree().current_scene != null:
			return get_tree().current_scene.find_child("Player", true, false)
	return null


func _get_can_control(player: Node) -> bool:
	if _has_property(player, "can_control"):
		return bool(player.get("can_control"))
	return player.process_mode != Node.PROCESS_MODE_DISABLED


func _set_can_control(player: Node, value: bool) -> void:
	if _has_property(player, "can_control"):
		player.set("can_control", value)
	else:
		player.process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED


func _has_property(node: Node, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
