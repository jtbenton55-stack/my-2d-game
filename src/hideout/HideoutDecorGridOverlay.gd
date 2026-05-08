extends Node2D
class_name HideoutDecorGridOverlay

var grid_size := 16
var grid_bounds := Rect2(Vector2(-1040, -690), Vector2(2000, 1210))
var line_color := Color(0.45, 0.95, 1.0, 0.14)

func _ready() -> void:
	visible = false
	z_index = 120
	set_process(false)

func configure(p_grid_size: int, p_bounds: Rect2) -> void:
	grid_size = p_grid_size
	grid_bounds = p_bounds
	queue_redraw()

func show_grid() -> void:
	visible = true
	queue_redraw()

func hide_grid() -> void:
	visible = false

func _draw() -> void:
	if grid_size <= 0:
		return
	var grid_size_float := float(grid_size)
	var left: float = floorf(grid_bounds.position.x / grid_size_float) * grid_size_float
	var top: float = floorf(grid_bounds.position.y / grid_size_float) * grid_size_float
	var right: float = grid_bounds.position.x + grid_bounds.size.x
	var bottom: float = grid_bounds.position.y + grid_bounds.size.y
	var x: float = left
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), line_color, 1.0)
		x += grid_size_float
	var y: float = top
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), line_color, 1.0)
		y += grid_size_float
