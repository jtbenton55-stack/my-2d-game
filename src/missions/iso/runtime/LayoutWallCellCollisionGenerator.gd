@tool
class_name LayoutWallCellCollisionGenerator
extends StaticBody2D

const GENERATED_BY := "layout_wall_cell_collision_generator"

@export var wall_layer_path: NodePath = NodePath("../../../LayoutRoot/WallLayer")
@export_range(1.0, 1.5, 0.01) var expansion_factor := 1.08
@export_flags_2d_physics var walls_bitmask := 4
@export var regenerate_in_editor := false

var generated_shape_count := 0


func _ready() -> void:
	collision_layer = walls_bitmask
	collision_mask = 0
	if Engine.is_editor_hint() and not regenerate_in_editor:
		return
	call_deferred("regenerate")


func regenerate() -> void:
	var wall_layer := get_node_or_null(wall_layer_path) as TileMapLayer
	if wall_layer == null:
		push_warning("Layout wall collision: WallLayer not found at %s" % [wall_layer_path])
		return
	_cleanup_generated_shapes()
	var started_usec := Time.get_ticks_usec()
	var origin_global := wall_layer.to_global(wall_layer.map_to_local(Vector2i.ZERO))
	var origin := to_local(origin_global)
	var vx := to_local(wall_layer.to_global(wall_layer.map_to_local(Vector2i.RIGHT))) - origin
	var vy := to_local(wall_layer.to_global(wall_layer.map_to_local(Vector2i.DOWN))) - origin
	var cells: Array[Vector2i] = wall_layer.get_used_cells()
	var excluded_cells := _mission_excluded_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for cell: Vector2i in cells:
		if excluded_cells.has(cell):
			continue
		var center := to_local(wall_layer.to_global(wall_layer.map_to_local(cell)))
		var shape := CollisionPolygon2D.new()
		shape.name = "WallCell_%04d_%d_%d" % [generated_shape_count + 1, cell.x, cell.y]
		shape.polygon = _expanded_diamond(center, vx, vy)
		shape.set_meta("generated_by", GENERATED_BY)
		shape.set_meta("collision_type", "wall_cell_proxy")
		shape.set_meta("source_cell", PackedInt32Array([cell.x, cell.y]))
		add_child(shape)
		generated_shape_count += 1
	set_meta("generated_by", GENERATED_BY)
	set_meta("collision_strategy", "per_wall_cell_expanded_diamond")
	set_meta("source_wall_layer_path", wall_layer_path)
	set_meta("wall_cell_count", generated_shape_count)
	set_meta("shape_count", generated_shape_count)
	set_meta("tile_center_delta_x", vx)
	set_meta("tile_center_delta_y", vy)
	set_meta("generation_usec", Time.get_ticks_usec() - started_usec)


func _mission_excluded_cells() -> Dictionary:
	var excluded: Dictionary = {}
	var ancestor: Node = self
	while ancestor != null:
		var value: Variant = ancestor.get("layout_collision_excluded_cells")
		if value is Array:
			for cell: Variant in value:
				if cell is Vector2i:
					excluded[cell] = true
			return excluded
		ancestor = ancestor.get_parent()
	return excluded


func _cleanup_generated_shapes() -> void:
	for child: Node in get_children():
		if child is CollisionPolygon2D and String(child.get_meta("generated_by", "")) == GENERATED_BY:
			child.owner = null
			remove_child(child)
			child.free()
	generated_shape_count = 0


func _expanded_diamond(center: Vector2, vx: Vector2, vy: Vector2) -> PackedVector2Array:
	var raw := PackedVector2Array([
		center - (vx + vy) * 0.5,
		center + (vx - vy) * 0.5,
		center + (vx + vy) * 0.5,
		center + (-vx + vy) * 0.5,
	])
	var expanded := PackedVector2Array()
	for point: Vector2 in raw:
		expanded.append(center + (point - center) * expansion_factor)
	return expanded
