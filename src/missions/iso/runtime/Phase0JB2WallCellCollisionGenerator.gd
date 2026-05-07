@tool
class_name Phase0JB2WallCellCollisionGenerator
extends StaticBody2D

@export var wall_layer_path: NodePath = NodePath("../../../LayoutRoot/WallLayer")
@export var expansion_factor: float = 1.08
@export var walls_bitmask: int = 4
@export var regenerate_in_editor: bool = true

var generated_shape_count: int = 0


func _ready() -> void:
	collision_layer = walls_bitmask
	collision_mask = 0
	if Engine.is_editor_hint() and not regenerate_in_editor:
		return
	call_deferred("regenerate")


func regenerate() -> void:
	var wall_layer := get_node_or_null(wall_layer_path) as TileMapLayer
	if wall_layer == null:
		push_warning("Phase0JB2 wall collision: WallLayer not found at %s" % [str(wall_layer_path)])
		return
	for child in get_children():
		if child is CollisionPolygon2D and child.has_meta("generated_by") and String(child.get_meta("generated_by")) == "Phase0J-B2":
			child.queue_free()
	await get_tree().process_frame
	var cells := wall_layer.get_used_cells()
	var sample_center := wall_layer.map_to_local(Vector2i.ZERO)
	var vx := wall_layer.map_to_local(Vector2i(1, 0)) - sample_center
	var vy := wall_layer.map_to_local(Vector2i(0, 1)) - sample_center
	generated_shape_count = 0
	for cell in cells:
		var center_global := wall_layer.to_global(wall_layer.map_to_local(cell))
		var center := to_local(center_global)
		var poly := _expanded_diamond(center, vx, vy)
		var shape := CollisionPolygon2D.new()
		shape.name = "WallCell_%04d_%d_%d" % [generated_shape_count + 1, cell.x, cell.y]
		shape.polygon = poly
		shape.set_meta("generated_by", "Phase0J-B2")
		shape.set_meta("collision_type", "wall_cell_proxy")
		shape.set_meta("source_cell", PackedInt32Array([cell.x, cell.y]))
		add_child(shape)
		generated_shape_count += 1
	set_meta("generated_by", "Phase0J-B2")
	set_meta("collision_strategy", "per_wall_cell_expanded_diamond")
	set_meta("source", "current_duplicate_wall_layer_cells")
	set_meta("manual_edits_preserved", true)
	set_meta("wall_cell_count", cells.size())
	set_meta("shape_count", generated_shape_count)
	set_meta("tile_center_delta_x", vx)
	set_meta("tile_center_delta_y", vy)
	print("[Phase0JB2] Generated %d wall-cell collision polygons." % generated_shape_count)


func _expanded_diamond(center: Vector2, vx: Vector2, vy: Vector2) -> PackedVector2Array:
	var raw := PackedVector2Array([
		center - (vx + vy) * 0.5,
		center + (vx - vy) * 0.5,
		center + (vx + vy) * 0.5,
		center + (-vx + vy) * 0.5,
	])
	var expanded := PackedVector2Array()
	for p in raw:
		expanded.append(center + (p - center) * expansion_factor)
	return expanded
