extends Node2D
class_name HideoutPlacedDecorItem

signal decor_clicked(placed_id: String)

var placed_id := ""
var item_id := ""
var display_name := ""
var footprint := Vector2(48, 48)
var blocks_player := false
var current_rotation_degrees := 0.0
var selected := false

func setup(placed: Dictionary, item: Dictionary, is_selected: bool, walls_layer_bitmask: int = 4) -> void:
	placed_id = String(placed.get("placed_id", ""))
	item_id = String(placed.get("item_id", ""))
	display_name = String(placed.get("display_name", item.get("display_name", item_id)))
	footprint = Vector2(float(item.get("footprint_width_px", 48)), float(item.get("footprint_height_px", 48)))
	blocks_player = bool(item.get("blocks_player", false))
	current_rotation_degrees = float(placed.get("rotation", placed.get("rotation_degrees", 0.0)))
	selected = is_selected
	position = placed.get("position", Vector2.ZERO)
	rotation_degrees = current_rotation_degrees
	_build_visual(walls_layer_bitmask)

func _build_visual(walls_layer_bitmask: int) -> void:
	for child in get_children():
		child.queue_free()
	var half := footprint * 0.5
	var box := Polygon2D.new()
	box.name = "PlaceholderDecorVisual"
	box.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	box.color = Color(1.0, 0.72, 0.20, 0.92) if selected else Color(0.5, 0.25, 0.85, 0.82)
	add_child(box)
	if selected:
		var outline := Line2D.new()
		outline.name = "SelectedOutline"
		outline.width = 3.0
		outline.default_color = Color(1, 0.95, 0.25, 1)
		outline.closed = true
		outline.points = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
		add_child(outline)
	var click_area := Area2D.new()
	click_area.name = "ClickableSelectArea"
	click_area.input_pickable = true
	var click_shape := CollisionShape2D.new()
	var click_rect := RectangleShape2D.new()
	click_rect.size = footprint + Vector2(16, 16)
	click_shape.shape = click_rect
	click_area.add_child(click_shape)
	click_area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			decor_clicked.emit(placed_id)
	)
	add_child(click_area)
	if blocks_player:
		var body := StaticBody2D.new()
		body.name = "PlayerBlockingDecorCollision"
		body.collision_layer = walls_layer_bitmask
		body.collision_mask = 0
		body.set_meta("item_id", item_id)
		body.set_meta("placed_id", placed_id)
		body.set_meta("blocks_player", true)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint
		shape.shape = rect
		body.add_child(shape)
		add_child(body)
	var label := Label.new()
	label.name = "DecorLabel"
	label.text = display_name if not selected else "%s\nSelected" % display_name
	label.position = Vector2(-half.x, -half.y - 28)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.65, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
