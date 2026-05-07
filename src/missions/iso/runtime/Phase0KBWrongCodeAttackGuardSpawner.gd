@tool
class_name Phase0KBWrongCodeAttackGuardSpawner
extends Node

const GUARD_SCRIPT := preload("res://src/missions/iso/runtime/Phase0KGuardPatrol.gd")

@export var wrong_code_threshold := 2
@export var runtime_guard_parent_path: NodePath = NodePath("../../Phase0KRuntime/Guards")
@export var safe_code_marker_path: NodePath = NodePath("../../MarkerRoot/EditorOnlyPlaceholders/SAFE_CODE_INPUT_ZONE")
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")

var wrong_code_attempts := 0
var dispatched_guard_count := 0
var max_dispatched_guards := 1


func _ready() -> void:
	set_meta("generated_by", "Phase0K-B")
	set_meta("scene_local_only", true)


func register_wrong_code_attempt() -> Dictionary:
	wrong_code_attempts += 1
	if wrong_code_attempts < wrong_code_threshold:
		_show("Wrong code. Security heard the keypad.")
		return _result(false, "warning_only")
	if dispatched_guard_count >= max_dispatched_guards:
		_show("Wrong code again - guard already dispatched!")
		return _result(false, "guard_already_dispatched")
	var guard := spawn_attack_guard()
	var spawned := guard != null
	_show("Wrong code again - guard incoming!" if spawned else "Wrong code again - guard dispatch failed.")
	return _result(spawned, "guard_dispatched" if spawned else "spawn_failed")


func spawn_attack_guard() -> Node:
	var parent := _ensure_guard_parent()
	if parent == null:
		return null
	var guard := CharacterBody2D.new()
	guard.name = "WrongCodeAttackGuard_%d" % wrong_code_attempts
	guard.set_script(GUARD_SCRIPT)
	guard.set("guard_id", guard.name)
	guard.set("hostile", true)
	guard.set("chase_player", true)
	guard.set("patrol_speed", 125.0)
	var spawn_pos := _spawn_position()
	guard.set("patrol_points", [spawn_pos])
	guard.set_meta("generated_by", "Phase0K-B")
	guard.set_meta("spawn_reason", "wrong_code")
	guard.set_meta("wrong_code_attempt", wrong_code_attempts)
	guard.set_meta("hostile", true)
	parent.add_child(guard)
	guard.global_position = spawn_pos
	dispatched_guard_count += 1
	return guard


func _spawn_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var marker := get_node_or_null(safe_code_marker_path) as Node2D
	if player != null and marker != null:
		return marker.global_position.move_toward(player.global_position, 180.0)
	if marker != null:
		return marker.global_position + Vector2(-128, 64)
	if player != null:
		return player.global_position + Vector2(220, 0)
	return Vector2.ZERO


func _ensure_guard_parent() -> Node:
	var parent := get_node_or_null(runtime_guard_parent_path)
	if parent != null:
		return parent
	var runtime_root := get_node_or_null("../../Phase0KRuntime")
	if runtime_root == null:
		runtime_root = Node2D.new()
		runtime_root.name = "Phase0KRuntime"
		get_node("../..").add_child(runtime_root)
	parent = Node2D.new()
	parent.name = "Guards"
	runtime_root.add_child(parent)
	return parent


func _result(spawned: bool, status: String) -> Dictionary:
	return {
		"wrong_code_attempts": wrong_code_attempts,
		"threshold": wrong_code_threshold,
		"guard_spawned": spawned,
		"status": status,
		"dispatched_guard_count": dispatched_guard_count,
	}


func _show(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 4.0)
	if has_node("/root/EventBus"):
		EventBus.objective_updated.emit(text)
