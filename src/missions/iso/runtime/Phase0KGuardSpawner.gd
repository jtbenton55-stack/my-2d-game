@tool
class_name Phase0KGuardSpawner
extends Node

const GUARD_SCRIPT := preload("res://src/missions/iso/runtime/Phase0KGuardPatrol.gd")

@export var marker_root_path: NodePath = NodePath("../../MarkerRoot/EditorOnlyPlaceholders")
@export var guard_parent_path: NodePath = NodePath("../../Phase0KRuntime/Guards")

var spawned_guard_count := 0
var guard_spawn_table: Array[Dictionary] = []


func _ready() -> void:
	set_meta("generated_by", "Phase0K")
	call_deferred("spawn_guards")


func spawn_guards() -> void:
	if Engine.is_editor_hint():
		return
	var marker_root := get_node_or_null(marker_root_path)
	var parent := _ensure_parent()
	if marker_root == null or parent == null:
		return
	_clear_phase0k_guards(parent)
	var patrols := _collect_patrol_points(marker_root)
	for marker in marker_root.get_children():
		if String(marker.get_meta("category", "")) != "GUARD" or not (marker is Node2D):
			continue
		var marker_id := String(marker.get_meta("manifest_id", marker.name))
		if parent.get_node_or_null(marker_id) != null:
			continue
		var guard := CharacterBody2D.new()
		guard.name = marker_id
		guard.set_script(GUARD_SCRIPT)
		guard.set("guard_id", marker_id)
		var marker_position := (marker as Node2D).global_position
		var points := _nearest_patrols(marker_position, patrols)
		if points.is_empty():
			points = _fallback_patrol(marker_position)
		guard.set("patrol_points", points)
		guard.set_meta("marker_id", marker_id)
		guard.set_meta("patrol_marker_ids", PackedStringArray(points.map(func(_p): return "nearest_or_fallback")))
		guard.set_meta("generated_by", "Phase0K-B")
		parent.add_child(guard)
		guard.global_position = marker_position
		spawned_guard_count += 1
		guard_spawn_table.append({
			"marker_id": marker_id,
			"position": guard.global_position,
			"patrol_points": points.size(),
			"action": "spawned_active_guard",
		})


func _collect_patrol_points(marker_root: Node) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for marker in marker_root.get_children():
		if String(marker.get_meta("category", "")) == "PATROL" and marker is Node2D:
			points.append((marker as Node2D).global_position)
	return points


func _nearest_patrols(origin: Vector2, patrols: Array[Vector2]) -> Array[Vector2]:
	var sorted := patrols.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2): return origin.distance_squared_to(a) < origin.distance_squared_to(b))
	var out: Array[Vector2] = []
	for point in sorted:
		if out.size() >= 4:
			break
		if origin.distance_to(point) <= 1800.0:
			out.append(point)
	return out


func _fallback_patrol(origin: Vector2) -> Array[Vector2]:
	return [origin + Vector2(-96, 0), origin + Vector2(96, 0), origin + Vector2(96, 96), origin + Vector2(-96, 96)]


func _ensure_parent() -> Node:
	var parent := get_node_or_null(guard_parent_path)
	if parent != null:
		return parent
	var root := get_node_or_null("../../Phase0KRuntime")
	if root == null:
		root = Node2D.new()
		root.name = "Phase0KRuntime"
		get_node("../..").add_child(root)
	parent = Node2D.new()
	parent.name = "Guards"
	root.add_child(parent)
	return parent


func _clear_phase0k_guards(parent: Node) -> void:
	for child in parent.get_children():
		if String(child.get_meta("generated_by", "")).begins_with("Phase0K") and String(child.get_meta("spawn_reason", "")) != "wrong_code":
			child.queue_free()
