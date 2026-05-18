@tool
extends "res://src/missions/iso/authoring/SecurityEffectAuthorBase.gd"

@export_group("Door / Gate Target")
@export var target_node_path: NodePath
@export var target_gate_id: StringName = &""

@export_group("Lock Action")
@export var lock_action: StringName = &"unlock"
@export var required_item_id: StringName = &""
@export var required_code_key: StringName = &""


func get_effect_type() -> String:
	return "door_lock"


func _apply_effect(_event_id: String, _payload: Dictionary) -> Dictionary:
	var action := String(lock_action).strip_edges().to_lower()
	var gate_id := String(target_gate_id).strip_edges()
	var target := _resolve_target_node()
	if gate_id == "" and target == null:
		return _reject("rejected_missing_target")
	if gate_id != "" and gate_id != "GATE_garage_code":
		if _mission != null and _mission.has_method("set_code_gate_open"):
			return _apply_code_gate(gate_id, action)
	if gate_id == "GATE_garage_code":
		return _reject("rejected_protected_gate")
	if target != null:
		return _apply_to_target_node(target, action, _event_id)
	if gate_id != "" and _mission != null and _mission.has_method("set_code_gate_open"):
		return _apply_code_gate(gate_id, action)
	return _reject("rejected_missing_lock_api")


func _resolve_target_node() -> Node:
	var proof := _resolve_proof_door_from_group()
	if proof != null:
		return proof
	if target_node_path.is_empty():
		return null
	var local := get_node_or_null(target_node_path)
	if local != null:
		return local
	var sec_root := get_parent()
	if sec_root != null:
		local = sec_root.get_node_or_null(target_node_path)
		if local != null:
			return local
	if _mission == null:
		return null
	local = _mission.get_node_or_null(target_node_path)
	if local != null:
		return local
	var authoring := _mission.get_node_or_null("GameplayRoot/SecurityAuthoringRoot")
	if authoring != null:
		local = authoring.get_node_or_null(target_node_path)
		if local != null:
			return local
	var rel := str(target_node_path)
	if rel.begins_with("../"):
		rel = rel.substr(3)
	return _mission.get_node_or_null("GameplayRoot/SecurityAuthoringRoot/" + rel)


func _resolve_proof_door_from_group() -> Node:
	if not _targets_proof_door():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("d6_05a_test_door_lock"):
		if node != null and is_instance_valid(node):
			return node
	return null


func _targets_proof_door() -> bool:
	var path_s := str(target_node_path)
	return (
		"d6_05a_test_door" in path_s.to_lower()
		or "testdoorlock" in path_s.to_lower().replace("_", "")
	)


func _apply_code_gate(gate_id: String, action: String) -> Dictionary:
	match action:
		"unlock", "open":
			_mission.call("set_code_gate_open", gate_id, true)
			GameState.dialogue_flags["mission_gate:" + gate_id] = true
			return _door_success("unlocked", "code_gate_open", gate_id, true, {})
		"lock", "close":
			_mission.call("set_code_gate_open", gate_id, false)
			GameState.dialogue_flags.erase("mission_gate:" + gate_id)
			return _door_success("locked", "code_gate_closed", gate_id, false, {})
		"toggle":
			var was_open: bool = GameState.dialogue_flags.get("mission_gate:" + gate_id, false) == true
			_mission.call("set_code_gate_open", gate_id, not was_open)
			GameState.dialogue_flags["mission_gate:" + gate_id] = not was_open
			return _door_success("toggled", "code_gate_toggled", gate_id, not was_open, {})
		"require_key", "require_code":
			return _door_success("configured", action, gate_id, null, {})
	return _reject("rejected_unknown_action")


func _apply_to_target_node(target: Node, action: String, event_id: String) -> Dictionary:
	var path := str(target.get_path())
	match action:
		"toggle":
			var want_locked: Variant = null
			if target.has_method("is_locked"):
				want_locked = not bool(target.call("is_locked"))
			elif target.has_method("get_lock_state"):
				want_locked = String(target.call("get_lock_state")) != "locked"
			elif "locked" in target:
				want_locked = not bool(target.get("locked"))
			else:
				return _reject("rejected_missing_toggle_api")
			return _apply_locked_to_target(target, bool(want_locked), path, event_id, "toggle_locked")
		"lock", "close":
			return _apply_locked_to_target(target, true, path, event_id, "set_locked")
		"unlock", "open":
			return _apply_locked_to_target(target, false, path, event_id, "set_locked")
		"require_key", "require_code":
			return _door_success("configured", action, path, _read_lock_state(target), _physics_fields(target))
	return _reject("rejected_unknown_action")


func _apply_locked_to_target(
	target: Node,
	locked: bool,
	path: String,
	event_id: String,
	reason: String,
) -> Dictionary:
	if not _set_target_locked(target, locked):
		return _reject("rejected_missing_lock_api")
	var fields := _physics_fields(target)
	if not bool(fields.get("physics_matches_visual", true)):
		return _reject("rejected_physics_mismatch")
	var want_enabled := locked
	if bool(fields.get("collision_enabled", false)) != want_enabled:
		return _reject("rejected_collision_not_applied")
	var state_str := "locked" if locked else "unlocked"
	fields["event_id"] = event_id
	return _door_success(state_str, reason, path, locked, fields)


func _set_target_locked(target: Node, locked: bool) -> bool:
	if target.has_method("apply_locked_state"):
		target.call("apply_locked_state", locked)
		return true
	if target.has_method("set_locked"):
		target.call("set_locked", locked)
		return true
	if "locked" in target:
		target.set("locked", locked)
		return true
	return false


func _physics_fields(target: Node) -> Dictionary:
	if target != null and target.has_method("get_runtime_debug_state"):
		return target.call("get_runtime_debug_state") as Dictionary
	return {
		"collision_enabled": false,
		"collision_layer": 0,
		"physics_matches_visual": false,
	}


func _read_lock_state(target: Node) -> Variant:
	if target.has_method("get_lock_state"):
		var s: String = String(target.call("get_lock_state"))
		return s == "locked"
	if target.has_method("is_locked"):
		return bool(target.call("is_locked"))
	if "locked" in target:
		return bool(target.get("locked"))
	return null


func _door_success(
	result_key: String,
	reason: String,
	target_ref: String,
	lock_state: Variant,
	physics: Dictionary,
) -> Dictionary:
	var state_str := "unknown"
	if lock_state == true:
		state_str = "locked"
	elif lock_state == false:
		state_str = "unlocked"
	elif lock_state is String:
		state_str = String(lock_state)
	var extra := {
		"target_path": target_ref if target_ref.begins_with("/") else "",
		"target_gate_id": target_ref if not target_ref.begins_with("/") else "",
		"lock_action": String(lock_action),
		"lock_state": state_str,
		"collision_enabled": bool(physics.get("collision_enabled", false)),
		"collision_layer": int(physics.get("collision_layer", 0)),
		"physics_matches_visual": bool(physics.get("physics_matches_visual", true)),
	}
	return _success(result_key, reason, extra)
