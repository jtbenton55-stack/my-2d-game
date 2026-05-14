@tool
class_name Phase0KCameraSpawner
extends Node

const CAMERA_SCRIPT := preload("res://src/missions/iso/runtime/MissionSecurityCamera.gd")

@export var marker_root_path: NodePath = NodePath("../../MarkerRoot/EditorOnlyPlaceholders")
@export var camera_parent_path: NodePath = NodePath("../../EntityRoot/Cameras")

var spawned_camera_count := 0
var camera_spawn_table: Array[Dictionary] = []


func _ready() -> void:
	set_meta("generated_by", "Phase0K")
	call_deferred("spawn_cameras")


func spawn_cameras() -> void:
	if Engine.is_editor_hint():
		return
	var marker_root := get_node_or_null(marker_root_path)
	var parent := _ensure_parent()
	if marker_root == null or parent == null:
		return
	_clear_phase0k_cameras(parent)
	for marker in marker_root.get_children():
		if String(marker.get_meta("category", "")) != "CAM" or not (marker is Node2D):
			continue
		var marker_id := String(marker.get_meta("manifest_id", marker.name))
		if parent.get_node_or_null(marker_id) != null:
			continue
		var camera := Area2D.new()
		camera.name = marker_id
		camera.set_script(CAMERA_SCRIPT)
		camera.set("camera_id", marker_id)
		camera.set_meta("marker_id", marker_id)
		camera.set_meta("generated_by", "Phase0K-B")
		camera.set_meta("valid_camera", true)
		parent.add_child(camera)
		camera.global_position = (marker as Node2D).global_position
		if camera.has_method("refresh_sweep_basis_from_world"):
			camera.call_deferred("refresh_sweep_basis_from_world")
		spawned_camera_count += 1
		camera_spawn_table.append({
			"marker_id": marker_id,
			"position": camera.global_position,
			"action": "spawned_active_camera",
		})


func _ensure_parent() -> Node:
	var parent := get_node_or_null(camera_parent_path)
	if parent != null:
		return parent
	var root := get_node_or_null("../../Phase0KRuntime")
	if root == null:
		root = Node2D.new()
		root.name = "Phase0KRuntime"
		get_node("../..").add_child(root)
	parent = Node2D.new()
	parent.name = "Cameras"
	root.add_child(parent)
	return parent


func _clear_phase0k_cameras(parent: Node) -> void:
	for child in parent.get_children():
		if String(child.get_meta("generated_by", "")).begins_with("Phase0K"):
			child.queue_free()
