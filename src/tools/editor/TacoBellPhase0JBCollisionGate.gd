@tool
class_name TacoBellPhase0JBCollisionGate
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const WALLS_BITMASK := 4

## Phase 0J-B bounded helper.
##
## This helper is intentionally scene-local in scope. It exists so later reruns
## can regenerate only the Phase 0J-B collision subtrees:
## - GameplayRoot/GeneratedRuntimeCollision/WallCollision
## - GameplayRoot/GeneratedRuntimeCollision/BoundaryCollision
## - GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate
##
## It must not repaint TileMapLayer data or move MarkerRoot/manual nodes.


static func summarize_scene(root: Node) -> Dictionary:
	return {
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"walls_bitmask": WALLS_BITMASK,
		"generated_roots": {
			"wall_collision": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/WallCollision"),
			"boundary_collision": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/BoundaryCollision"),
			"gate_blocker": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate"),
		},
		"tile_layers": _tile_layer_summary(root),
		"source_md5": _file_md5(SOURCE_SCENE),
	}


static func _count_collision(root: Node, path: String) -> Dictionary:
	var node := root.get_node_or_null(path)
	var out := {"exists": node != null, "body_count": 0, "shape_count": 0, "walls_layer_body_count": 0}
	if node == null:
		return out
	_count_collision_recursive(node, out)
	return out


static func _count_collision_recursive(node: Node, out: Dictionary) -> void:
	if node is StaticBody2D:
		out.body_count += 1
		if int((node as StaticBody2D).collision_layer) & WALLS_BITMASK:
			out.walls_layer_body_count += 1
	if node is CollisionShape2D or node is CollisionPolygon2D:
		out.shape_count += 1
	for child in node.get_children():
		_count_collision_recursive(child, out)


static func _tile_layer_summary(root: Node) -> Array:
	var out: Array = []
	_walk_tile_layers(root, out)
	return out


static func _walk_tile_layers(node: Node, out: Array) -> void:
	if node is TileMapLayer:
		var layer := node as TileMapLayer
		out.append({
			"path": String(node.get_path()),
			"used_cell_count": layer.get_used_cells().size(),
			"used_rect": str(layer.get_used_rect()),
			"collision_enabled": bool(layer.collision_enabled),
			"visible": bool(layer.visible),
		})
	for child in node.get_children():
		_walk_tile_layers(child, out)


static func _file_md5(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_md5(path)
