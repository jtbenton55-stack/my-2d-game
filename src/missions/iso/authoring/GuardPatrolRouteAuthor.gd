@tool
extends Node2D

@export_group("Route Identity")
@export var route_id: StringName = &"patrol_route"
@export var enabled := true
@export var loop_route := true
@export var direction: StringName = &"clockwise"

@export_group("Preview")
@export var preview_color: Color = Color(0.55, 1.0, 0.35, 0.9)
@export var show_label := true
@export var waypoint_radius: float = 6.0

var _label: Label = null
var _editor_preview_sig: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		_ensure_label()
		_refresh_label()
		queue_redraw()
	else:
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var sig := _preview_signature()
	if sig != _editor_preview_sig:
		_editor_preview_sig = sig
		queue_redraw()
		_refresh_label()


func get_patrol_points() -> Array[Vector2]:
	return get_patrol_points_global()


func get_patrol_points_global() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for child in get_children():
		if child is Node2D and child.name != "AuthorLabel":
			pts.append((child as Node2D).global_position)
	if pts.is_empty():
		pts.append(global_position)
	return pts


func get_patrol_direction_sign() -> int:
	var d := String(direction).strip_edges().to_lower()
	if d == "counterclockwise" or d == "ccw" or d == "reverse":
		return -1
	if d == "ping_pong":
		return 0
	return 1


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var local_pts: PackedVector2Array = PackedVector2Array()
	var idx := 0
	for child in get_children():
		if child is Node2D and child.name != "AuthorLabel":
			local_pts.append((child as Node2D).position)
			var wp_col := Color(preview_color.r, preview_color.g, preview_color.b, 0.95)
			draw_circle((child as Node2D).position, maxf(3.0, waypoint_radius), wp_col)
			idx += 1
	if local_pts.is_empty():
		draw_circle(Vector2.ZERO, maxf(3.0, waypoint_radius), preview_color)
		return
	if local_pts.size() >= 2:
		draw_polyline(local_pts, preview_color, 2.0)


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size = Vector2(160.0, 22.0)
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)
		if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
			_label.owner = get_tree().edited_scene_root


func _refresh_label() -> void:
	_ensure_label()
	if _label == null:
		return
	_label.text = "ROUTE %s (%d wp)" % [String(route_id), maxi(0, get_patrol_points_global().size())]
	_label.position = Vector2(-80.0, -36.0)


func _preview_signature() -> String:
	return "%s|%s|%d" % [String(route_id), str(loop_route), get_child_count()]
