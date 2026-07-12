class_name VelvetPawCollisionDebugOverlay
extends Node2D

const OUTLINE_COLOR := Color(1.0, 0.05, 0.05, 0.95)
const DISABLED_COLOR := Color(0.65, 0.15, 0.15, 0.72)
const LABEL_COLOR := Color(1.0, 0.25, 0.2, 1.0)
const GENERATED_WALL_ROOT := "GeneratedLayoutWallCellCollision"

@export var wall_layer_path := NodePath("../../../LayoutRoot/WallLayer")
@export var barrier_layer_path := NodePath("../../../LayoutRoot/CollisionBarrierLayer")
@export var cover_layer_path := NodePath("../../../LayoutRoot/CoverLayer")
@export var mission_root_path := NodePath("../../../..")

var _redraw_elapsed := 0.0


func _ready() -> void:
	name = "CollisionDebugOverlay"
	z_as_relative = false
	z_index = 3900
	visible = false
	set_process(false)


func set_overlay_enabled(enabled: bool) -> void:
	visible = enabled
	set_process(enabled)
	queue_redraw()


func is_overlay_enabled() -> bool:
	return visible


func _process(delta: float) -> void:
	_redraw_elapsed += delta
	if _redraw_elapsed >= 0.2:
		_redraw_elapsed = 0.0
		queue_redraw()


func _draw() -> void:
	if not visible:
		return
	_draw_tile_layer(get_node_or_null(wall_layer_path) as TileMapLayer, "WALLS")
	_draw_tile_layer(get_node_or_null(barrier_layer_path) as TileMapLayer, "COLLISION BARRIERS")
	_draw_tile_layer(get_node_or_null(cover_layer_path) as TileMapLayer, "COVER")
	var mission_root := get_node_or_null(mission_root_path)
	if mission_root != null:
		_draw_gameplay_nodes(mission_root)


func _draw_tile_layer(layer: TileMapLayer, label: String) -> void:
	if layer == null:
		return
	var used_cells := layer.get_used_cells()
	for cell: Vector2i in used_cells:
		var center := to_local(layer.to_global(layer.map_to_local(cell)))
		var points := PackedVector2Array([
			center + Vector2(0, -18),
			center + Vector2(36, 0),
			center + Vector2(0, 18),
			center + Vector2(-36, 0),
			center + Vector2(0, -18),
		])
		draw_polyline(points, OUTLINE_COLOR, 2.0, true)
	if not used_cells.is_empty():
		var rect := layer.get_used_rect()
		var center_cell := Vector2i(rect.position.x + rect.size.x / 2, rect.position.y + rect.size.y / 2)
		_draw_label(to_local(layer.to_global(layer.map_to_local(center_cell))), label)


func _draw_gameplay_nodes(root: Node) -> void:
	for node: Node in root.find_children("*", "", true, false):
		if not _is_overlay_subject(node):
			continue
		_draw_subject(node)


func _is_overlay_subject(node: Node) -> bool:
	if node == self or node is Camera2D or node is CollisionShape2D or node is CollisionPolygon2D or node is TileMapLayer:
		return false
	if _has_ancestor_named(node, GENERATED_WALL_ROOT):
		return false
	if _is_ignored_actor(node) or _has_actor_ancestor(node):
		return false
	if node.is_in_group("interactable") or node.is_in_group("mission_mechanic"):
		return true
	if node is CollisionObject2D:
		return true
	var node_name := String(node.name).to_lower()
	return "camera" in node_name or "guard" in node_name or "cover" in node_name


func _draw_subject(node: Node) -> void:
	var drew_shape := false
	for child: Node in node.find_children("*", "CollisionShape2D", true, false):
		var collision_shape := child as CollisionShape2D
		if collision_shape == null or collision_shape.shape == null:
			continue
		_draw_shape(collision_shape)
		drew_shape = true
	for child: Node in node.find_children("*", "CollisionPolygon2D", true, false):
		var collision_polygon := child as CollisionPolygon2D
		if collision_polygon == null or collision_polygon.polygon.is_empty():
			continue
		_draw_polygon(collision_polygon)
		drew_shape = true
	if not drew_shape and node is Node2D:
		var center := to_local((node as Node2D).global_position)
		draw_rect(Rect2(center - Vector2(12, 12), Vector2(24, 24)), OUTLINE_COLOR, false, 2.0)
	if node is Node2D:
		_draw_label(to_local((node as Node2D).global_position), "%s: %s" % [_category_for(node), node.name])


func _draw_shape(collision: CollisionShape2D) -> void:
	var color := DISABLED_COLOR if collision.disabled else OUTLINE_COLOR
	var shape := collision.shape
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		_draw_local_points(collision, PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y),
		]), color)
	elif shape is CircleShape2D:
		var points := PackedVector2Array()
		var radius := (shape as CircleShape2D).radius
		for index in range(25):
			points.append(Vector2.RIGHT.rotated(TAU * float(index) / 24.0) * radius)
		_draw_local_points(collision, points, color)
	elif shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		var half := Vector2(capsule.radius, capsule.height * 0.5)
		_draw_local_points(collision, PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y),
		]), color)
	elif shape is ConvexPolygonShape2D:
		var points := (shape as ConvexPolygonShape2D).points.duplicate()
		if not points.is_empty():
			points.append(points[0])
		_draw_local_points(collision, points, color)


func _draw_polygon(collision: CollisionPolygon2D) -> void:
	var points := collision.polygon.duplicate()
	if not points.is_empty():
		points.append(points[0])
	_draw_local_points(collision, points, DISABLED_COLOR if collision.disabled else OUTLINE_COLOR)


func _draw_local_points(source: Node2D, local_points: PackedVector2Array, color: Color) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in local_points:
		points.append(to_local(source.to_global(point)))
	if points.size() >= 2:
		draw_polyline(points, color, 2.5, true)


func _draw_label(position: Vector2, text: String) -> void:
	draw_string(ThemeDB.fallback_font, position + Vector2(8, -8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LABEL_COLOR)


func _category_for(node: Node) -> String:
	if node.is_in_group("mission_mechanic"):
		return "MECHANIC"
	if node.is_in_group("interactable"):
		return "INTERACTABLE"
	var node_name := String(node.name).to_lower()
	if "camera" in node_name:
		return "CAMERA"
	if "guard" in node_name:
		return "GUARD"
	if "cover" in node_name:
		return "COVER"
	if node is Area2D:
		return "ZONE"
	if node is StaticBody2D:
		return "BARRIER"
	if node is CharacterBody2D:
		return "ACTOR"
	return "OBJECT"


func _has_ancestor_named(node: Node, ancestor_name: String) -> bool:
	var current := node.get_parent()
	while current != null:
		if current.name == ancestor_name:
			return true
		current = current.get_parent()
	return false


func _has_actor_ancestor(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if _is_ignored_actor(current):
			return true
		current = current.get_parent()
	return false


func _is_ignored_actor(node: Node) -> bool:
	return node.is_in_group("player") or node.is_in_group("bentley")
