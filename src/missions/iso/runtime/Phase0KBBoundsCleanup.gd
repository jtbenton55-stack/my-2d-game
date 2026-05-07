@tool
class_name Phase0KBBoundsCleanup
extends Node

@export var floor_layer_path: NodePath = NodePath("../../LayoutRoot/FloorLayer")
@export var interactables_path: NodePath = NodePath("../../GeneratedRuntimeInteractables")
@export var labels_path: NodePath = NodePath("../../GeneratedRuntimeMarkerLabels")
@export var debug_interactables_path: NodePath = NodePath("../../GeneratedRuntimeMarkerDebugInteractables")

var moved_count := 0
var hidden_count := 0
var deferred_count := 0
var audited_count := 0
var reachable_floor_count := 0
var cleanup_table: Array[Dictionary] = []


func _ready() -> void:
	set_meta("generated_by", "Phase0K-B")
	set_meta("scene_local_only", true)
	call_deferred("run_cleanup")


func run_cleanup() -> void:
	if Engine.is_editor_hint():
		return
	var floor := get_node_or_null(floor_layer_path) as TileMapLayer
	if floor == null:
		return
	reachable_floor_count = _reachable_floor_count(floor)
	_repair_required_node("DeliveryBagObjective", Vector2i(250, 22), floor)
	_repair_required_node("Interactable_OBJ_bag_recovery", Vector2i(250, 22), floor)
	_repair_required_node("LouisExitToken", Vector2i(12, 52), floor)
	_repair_label("Label_OBJ_bag_recovery", Vector2i(250, 22), floor)
	_cleanup_generated_parent(get_node_or_null(interactables_path), floor)
	_cleanup_generated_parent(get_node_or_null(labels_path), floor)
	_cleanup_generated_parent(get_node_or_null(debug_interactables_path), floor)
	_hide_outside_debug_only(floor)


func _repair_required_node(node_name: String, target_cell: Vector2i, floor: TileMapLayer) -> void:
	var parent := get_node_or_null(interactables_path)
	if parent == null:
		return
	var node := parent.get_node_or_null(node_name) as Node2D
	if node == null:
		return
	var old := node.position
	var target := floor.map_to_local(target_cell)
	if floor.get_cell_tile_data(floor.local_to_map(node.position)) == null:
		node.position = target
		node.set_meta("phase0kb_moved_from", old)
		node.set_meta("phase0kb_reachable_cell", target_cell)
		moved_count += 1
		cleanup_table.append({"id": node_name, "old": old, "new": target, "action": "moved_to_reachable_floor"})


func _repair_label(node_name: String, target_cell: Vector2i, floor: TileMapLayer) -> void:
	var parent := get_node_or_null(labels_path)
	if parent == null:
		return
	var node := parent.get_node_or_null(node_name) as Node2D
	if node == null:
		return
	var target := floor.map_to_local(target_cell)
	node.position = target


func _hide_outside_debug_only(floor: TileMapLayer) -> void:
	var debug_parent := get_node_or_null(debug_interactables_path)
	if debug_parent != null:
		for node in debug_parent.get_children():
			if not (node is Node2D):
				continue
			var category := String(node.get_meta("category", node.get("category") if _has_property(node, "category") else ""))
			if _is_required_category(category):
				continue
			if floor.get_cell_tile_data(floor.local_to_map((node as Node2D).position)) == null:
				(node as Node2D).visible = false
				node.set_meta("phase0kb_hidden_runtime_debug_only", true)
				hidden_count += 1


func _cleanup_generated_parent(parent: Node, floor: TileMapLayer) -> void:
	if parent == null:
		return
	for node in parent.get_children():
		if not (node is Node2D):
			continue
		audited_count += 1
		var node2d := node as Node2D
		var category := String(node.get_meta("category", node.get("category") if _has_property(node, "category") else ""))
		var cell := floor.local_to_map(node2d.position)
		if floor.get_cell_tile_data(cell) != null:
			continue
		if _is_required_category(category):
			var target_cell := _nearest_floor_cell(floor, cell, 18)
			if target_cell != Vector2i(999999, 999999):
				var old := node2d.position
				node2d.position = floor.map_to_local(target_cell)
				node.set_meta("phase0kc_moved_from", old)
				node.set_meta("phase0kc_reachable_cell", target_cell)
				moved_count += 1
				cleanup_table.append({"id": node.name, "old": old, "new": node2d.position, "action": "moved_required_to_floor"})
			else:
				deferred_count += 1
				node.set_meta("phase0kc_deferred_bounds_reason", "no nearby floor cell")
		elif category != "CAM":
			node2d.visible = false
			node.set_meta("phase0kc_hidden_runtime_debug_only", true)
			hidden_count += 1


func _nearest_floor_cell(floor: TileMapLayer, start: Vector2i, radius: int) -> Vector2i:
	var best := Vector2i(999999, 999999)
	var best_dist := 999999
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var cell := start + Vector2i(dx, dy)
			if floor.get_cell_tile_data(cell) == null:
				continue
			var dist: int = abs(dx) + abs(dy)
			if dist < best_dist:
				best = cell
				best_dist = dist
	return best


func _reachable_floor_count(floor: TileMapLayer) -> int:
	var count := 0
	for cell in floor.get_used_cells():
		if floor.get_cell_tile_data(cell) != null:
			count += 1
	return count
	var label_parent := get_node_or_null(labels_path)
	if label_parent != null:
		for node in label_parent.get_children():
			if not (node is Node2D):
				continue
			var category := String(node.get_meta("category", node.get("category") if _has_property(node, "category") else ""))
			if _is_required_category(category) or category == "CAM":
				continue
			if floor.get_cell_tile_data(floor.local_to_map((node as Node2D).position)) == null:
				(node as Node2D).visible = false
				node.set_meta("phase0kb_hidden_runtime_debug_only", true)
				hidden_count += 1


func _is_required_category(category: String) -> bool:
	var cat := category.to_upper()
	return cat in ["OBJ", "EXIT", "CODE_INPUT", "BAG", "CLUE", "PHOTO", "GLOW", "TINY", "GUARD", "PATROL"]


func _has_property(node: Object, property_name: String) -> bool:
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false
