@tool
class_name Phase0JRuntimeAuthoringHider
extends Node

@export_group("Legacy Targets")
@export var target_paths: Array[String] = []
@export var hide_reason: String = "phase_0ja_runtime_authoring_visual_cleanup"
@export var force_low_z_index: bool = true

@export_group("Runtime Debug Labels")
@export var hide_generated_runtime_marker_labels: bool = false
@export var hide_security_author_labels: bool = false
@export var hide_security_label_residue: bool = false
@export var hide_security_proof_and_door_labels: bool = false
@export var generated_runtime_marker_labels_path: NodePath = NodePath("../../GeneratedRuntimeMarkerLabels")
@export var security_authoring_root_path: NodePath = NodePath("../../SecurityAuthoringRoot")


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_apply_runtime_hide")


func _apply_runtime_hide() -> void:
	var root := _scene_root()
	if root == null:
		return
	for path: String in target_paths:
		var target := _resolve_target(root, path)
		if target == null:
			continue
		_hide_visual_subtree(target)
	if hide_generated_runtime_marker_labels:
		var labels_target := _resolve_target(root, generated_runtime_marker_labels_path)
		if labels_target != null:
			_hide_visual_subtree(labels_target)
	if hide_security_author_labels or hide_security_label_residue:
		_hide_security_debug_labels(root)
	if hide_security_proof_and_door_labels:
		_hide_security_proof_and_door_labels(root)


func _hide_security_debug_labels(root: Node) -> void:
	var security_root := _resolve_target(root, security_authoring_root_path)
	if security_root == null:
		return
	var stack: Array[Node] = [security_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
			if _should_hide_security_label(child) and child is CanvasItem:
				_hide_visual_subtree(child)


func _should_hide_security_label(node: Node) -> bool:
	if not (node is Label):
		return false
	var label_name := String(node.name)
	if hide_security_author_labels and label_name == "AuthorLabel":
		return true
	if hide_security_label_residue and (label_name.begins_with("@Label@") or label_name.find("@Label@") >= 0):
		return true
	return false


func _hide_security_proof_and_door_labels(root: Node) -> void:
	var security_root := _resolve_target(root, security_authoring_root_path)
	if security_root == null:
		return
	var stack: Array[Node] = [security_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
			if not (child is Label):
				continue
			var label_name := String(child.name)
			if label_name == "ProofLabel" or label_name == "DoorLabel":
				_hide_visual_subtree(child)


func _hide_visual_subtree(node: Node) -> void:
	if node is CanvasItem:
		var item := node as CanvasItem
		item.visible = false
		if force_low_z_index:
			item.z_index = -4096
	node.set_meta("phase_0ja_hidden_at_runtime", true)
	node.set_meta("phase_0ja_hide_reason", hide_reason)


func _resolve_target(root: Node, path: Variant) -> Node:
	var path_text := ""
	match typeof(path):
		TYPE_NODE_PATH:
			path_text = String(path)
		TYPE_STRING:
			path_text = String(path).strip_edges()
		_:
			return null
	if path_text == "":
		return null
	var node := get_node_or_null(NodePath(path_text))
	if node != null:
		return node
	node = root.get_node_or_null(NodePath(path_text))
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
