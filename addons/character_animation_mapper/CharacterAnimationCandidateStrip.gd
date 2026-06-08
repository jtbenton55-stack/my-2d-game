@tool
extends Control

signal frame_clicked(global_index: int)
signal frame_hovered(global_index: int, row: int, column: int)
signal frame_hover_cleared()

var sheet_texture: Texture2D
var frame_width: int = 200
var frame_height: int = 200
var columns: int = 50
var _frames: PackedInt32Array = PackedInt32Array()
var _thumb_size := Vector2(56, 56)
var _hover_thumb_index: int = -1


func _ready() -> void:
	custom_minimum_size = Vector2(0, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()


func configure(texture: Texture2D, fw: int, fh: int, cols: int) -> void:
	sheet_texture = texture
	frame_width = maxi(1, fw)
	frame_height = maxi(1, fh)
	columns = maxi(1, cols)
	queue_redraw()


func set_frames(frames: PackedInt32Array) -> void:
	_frames = frames
	_hover_thumb_index = -1
	var count := maxi(1, frames.size())
	custom_minimum_size = Vector2(minf(900.0, float(count) * (_thumb_size.x + 4.0) + 8.0), 72)
	queue_redraw()


func _thumb_index_at(local_pos: Vector2) -> int:
	if _frames.is_empty():
		return -1
	if local_pos.y < 0.0 or local_pos.y > size.y:
		return -1
	var idx := int(floor((local_pos.x - 4.0) / (_thumb_size.x + 4.0)))
	if idx < 0 or idx >= _frames.size():
		return -1
	var thumb_rect := Rect2(Vector2(4 + idx * (_thumb_size.x + 4.0), 6), _thumb_size)
	if not thumb_rect.has_point(local_pos):
		return -1
	return idx


func _emit_hover_for_index(idx: int) -> void:
	if idx < 0 or idx >= _frames.size():
		return
	if idx == _hover_thumb_index:
		return
	_hover_thumb_index = idx
	var g: int = _frames[idx]
	frame_hovered.emit(g, g / columns, g % columns)


func _clear_hover() -> void:
	if _hover_thumb_index < 0:
		return
	_hover_thumb_index = -1
	frame_hover_cleared.emit()
	queue_redraw()


func _on_mouse_exited() -> void:
	_clear_hover()


func _gui_input(event: InputEvent) -> void:
	if _frames.is_empty() or sheet_texture == null:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var idx := _thumb_index_at(mm.position)
		if idx >= 0:
			_emit_hover_for_index(idx)
			queue_redraw()
		else:
			_clear_hover()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var click_idx := _thumb_index_at(mb.position)
			if click_idx >= 0 and click_idx < _frames.size():
				frame_clicked.emit(_frames[click_idx])
				accept_event()


func _draw() -> void:
	if sheet_texture == null or _frames.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(8, 28), "Candidate strip: no frames.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		return
	var max_draw := mini(_frames.size(), 24)
	for i: int in range(max_draw):
		var g: int = _frames[i]
		var row: int = g / columns
		var col: int = g % columns
		var rect := Rect2(Vector2(4 + i * (_thumb_size.x + 4.0), 6), _thumb_size)
		var region := Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
		draw_texture_rect_region(sheet_texture, rect, region)
		var border := Color(0.7, 0.8, 0.95, 0.9)
		var border_w := 1.0
		if i == _hover_thumb_index:
			border = Color(0.85, 0.1, 0.1, 1.0)
			border_w = 2.0
		draw_rect(rect, border, false, border_w)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(2, 10), str(g), HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	if _frames.size() > max_draw:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(4 + max_draw * (_thumb_size.x + 4.0), 28),
			"+%d more" % (_frames.size() - max_draw),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11
		)
