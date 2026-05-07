@tool
class_name TacoBellPhase0JB2CollisionRepair
extends RefCounted

const TARGET_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const CLEAN_PRE_0JB_BACKUP := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0jb_backup.20260506_063114.tscn"
const WALLS_BITMASK := 4
const COLLISION_STRATEGY := "per_wall_cell_expanded_diamond"

## Phase 0J-B2 repair helper.
##
## Design rule: do not generate broad strips. The intended repair is one small
## expanded-diamond wall proxy per current WallLayer cell, with source-cell
## metadata. This helper is documentation/runtime support for the generated
## scene data and can be extended into a headless runner when Godot script
## execution is stable in the toolchain.


static func build_wall_cell_polygon(center: Vector2, tile_size: Vector2 = Vector2(64, 32), expansion: float = 1.08) -> PackedVector2Array:
	var half := Vector2(tile_size.x * 0.5 * expansion, tile_size.y * 0.5 * expansion)
	return PackedVector2Array([
		center + Vector2(0, -half.y),
		center + Vector2(half.x, 0),
		center + Vector2(0, half.y),
		center + Vector2(-half.x, 0),
	])


static func summarize_collision(root: Node) -> Dictionary:
	return {
		"target_scene": TARGET_SCENE,
		"source_scene": SOURCE_SCENE,
		"clean_pre_0jb_backup": CLEAN_PRE_0JB_BACKUP,
		"walls_bitmask": WALLS_BITMASK,
		"collision_strategy": COLLISION_STRATEGY,
		"wall_collision": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/WallCollision"),
		"boundary_collision": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/BoundaryCollision"),
		"code_gate": _count_collision(root, "GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate"),
	}


static func _count_collision(root: Node, path: String) -> Dictionary:
	var node := root.get_node_or_null(path)
	var out := {
		"exists": node != null,
		"body_count": 0,
		"shape_count": 0,
		"walls_layer_body_count": 0,
		"wall_shapes_without_source_metadata": 0,
	}
	if node == null:
		return out
	_count_recursive(node, out)
	return out


static func _count_recursive(node: Node, out: Dictionary) -> void:
	if node is StaticBody2D:
		out.body_count += 1
		if int((node as StaticBody2D).collision_layer) & WALLS_BITMASK:
			out.walls_layer_body_count += 1
	if node is CollisionPolygon2D or node is CollisionShape2D:
		out.shape_count += 1
		if node.has_meta("collision_type") and String(node.get_meta("collision_type")) == "wall_cell_proxy" and not node.has_meta("source_cell"):
			out.wall_shapes_without_source_metadata += 1
	for child in node.get_children():
		_count_recursive(child, out)
