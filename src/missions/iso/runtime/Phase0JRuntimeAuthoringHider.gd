@tool
class_name Phase0JRuntimeAuthoringHider
extends Node

@export var target_paths: Array[String] = []
@export var hide_reason: String = "phase_0ja_runtime_authoring_visual_cleanup"
@export var force_low_z_index: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_apply_runtime_hide")


func _apply_runtime_hide() -> void:
	var root := _scene_root()
	if root == null:
		return
	for path in target_paths:
		var target := _resolve_target(root, path)
		if target == null:
			continue
		_hide_visual_subtree(target)


func _hide_visual_subtree(node: Node) -> void:
	if node is CanvasItem:
		var item := node as CanvasItem
		item.visible = false
		if force_low_z_index:
			item.z_index = -4096
	node.set_meta("phase_0ja_hidden_at_runtime", true)
	node.set_meta("phase_0ja_hide_reason", hide_reason)


func _resolve_target(root: Node, path: String) -> Node:
	if path.strip_edges() == "":
		return null
	var node := get_node_or_null(NodePath(path))
	if node != null:
		return node
	node = root.get_node_or_null(NodePath(path))
	if node != null:
		return node
	return null


func _scene_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	if tree.current_scene != null:
		return tree.current_scene
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != tree.root:
		node = node.get_parent()
	return node
