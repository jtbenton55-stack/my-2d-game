@tool
extends Control

enum SelectionMode { REPLACE, ADD, REMOVE }

signal selection_changed(frames: PackedInt32Array)
signal hover_changed(frame_index: int, row: int, column: int)

const MIN_ZOOM := 0.02
const MAX_ZOOM := 12.0
const MAX_FULL_DRAW_CELLS := 10000
const CANVAS_BACKGROUND := Color(0.96, 0.96, 0.94, 1.0)
const GRID_LINE_COLOR := Color(1.0, 0.0, 0.0, 0.75)
const SELECTION_FILL := Color(1.0, 0.18, 0.18, 0.32)
const SELECTED_OUTLINE := Color(0.92, 0.0, 0.0, 1.0)
const DRAG_PREVIEW_FILL := Color(1.0, 0.78, 0.0, 0.38)
const HOVER_OUTLINE := Color(0.85, 0.05, 0.05, 1.0)
const FRAME_LABEL_COLOR := Color(0.12, 0.12, 0.15, 1.0)
const AXIS_LABEL_COLOR := Color(0.55, 0.0, 0.0, 0.9)
const AXIS_LABEL_STEP := 10

var sheet_texture: Texture2D
var frame_width: int = 200
var frame_height: int = 200
var columns: int = 50
var rows: int = 50
var zoom: float = 0.12
var selection_mode: SelectionMode = SelectionMode.REPLACE
var require_ctrl_for_wheel_zoom := false
var double_click_focuses_frame := false

var _selected: Dictionary = {}
var _drag_active := false
var _drag_start_frame: int = -1
var _drag_end_frame: int = -1
var _hover_frame: int = -1
var _pan_drag := false
var _scroll_hooks_bound := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	resized.connect(queue_redraw)
	queue_redraw()


func configure(texture: Texture2D, fw: int, fh: int, cols: int, row_count: int) -> void:
	sheet_texture = texture
	frame_width = maxi(1, fw)
	frame_height = maxi(1, fh)
	columns = maxi(1, cols)
	rows = maxi(1, row_count)
	_bind_scroll_redraw()
	_update_content_size()
	_reset_scroll_offset()
	queue_redraw()


func set_selected_frames(frames: PackedInt32Array) -> void:
	_selected.clear()
	for g: int in frames:
		if _is_valid_frame(g):
			_selected[g] = true
	_emit_selection()


func get_selected_frames() -> PackedInt32Array:
	var keys: Array = _selected.keys()
	keys.sort()
	var out := PackedInt32Array()
	for k in keys:
		out.append(int(k))
	return out


func clear_selection() -> void:
	_selected.clear()
	_drag_active = false
	_drag_start_frame = -1
	_drag_end_frame = -1
	_emit_selection()
	queue_redraw()


func get_total_frames() -> int:
	return columns * rows


func _content_size() -> Vector2:
	return Vector2(columns * frame_width, rows * frame_height) * zoom


func _update_content_size() -> void:
	var content_size := _content_size()
	custom_minimum_size = content_size
	size = content_size


func set_zoom_value(value: float, focal_canvas_pos: Vector2 = Vector2(-1, -1)) -> void:
	var old_zoom := zoom
	zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	if focal_canvas_pos.x >= 0.0 and old_zoom > 0.0:
		var sheet_pos := focal_canvas_pos / old_zoom
		var new_canvas_pos := sheet_pos * zoom
		var parent_scroll := _find_scroll_container()
		if parent_scroll != null:
			parent_scroll.scroll_horizontal = int(new_canvas_pos.x - focal_canvas_pos.x + parent_scroll.scroll_horizontal)
			parent_scroll.scroll_vertical = int(new_canvas_pos.y - focal_canvas_pos.y + parent_scroll.scroll_vertical)
	_update_content_size()
	queue_redraw()


func fit_zoom_to_viewport(viewport_size: Vector2) -> void:
	if columns <= 0 or rows <= 0:
		return
	var sheet_size := Vector2(columns * frame_width, rows * frame_height)
	if sheet_size.x <= 0.0 or sheet_size.y <= 0.0:
		return
	var margin := Vector2(8, 8)
	var fit := minf((viewport_size.x - margin.x) / sheet_size.x, (viewport_size.y - margin.y) / sheet_size.y)
	_reset_scroll_offset()
	set_zoom_value(clampf(fit, MIN_ZOOM, MAX_ZOOM))


func scroll_to_frame(global_index: int, center_in_viewport: bool = true) -> void:
	if not _is_valid_frame(global_index):
		return
	var rc := _global_to_row_col(global_index)
	scroll_to_cell(rc.x, rc.y, center_in_viewport)


func scroll_to_row(row: int, center_in_viewport: bool = true) -> void:
	if row < 0 or row >= rows:
		return
	var scroll := _find_scroll_container()
	if scroll == null:
		return
	var cell := Vector2(frame_width, frame_height) * zoom
	var row_pos_y := float(row) * cell.y
	var row_height := cell.y
	if center_in_viewport:
		scroll.scroll_vertical = int(row_pos_y + row_height * 0.5 - scroll.size.y * 0.5)
	else:
		scroll.scroll_vertical = int(row_pos_y)
	_clamp_scroll_to_bars(scroll)


func scroll_to_cell(row: int, column: int, center_in_viewport: bool = true) -> void:
	var scroll := _find_scroll_container()
	if scroll == null:
		return
	row = clampi(row, 0, rows - 1)
	column = clampi(column, 0, columns - 1)
	var cell := Vector2(frame_width, frame_height) * zoom
	var frame_pos := Vector2(column, row) * cell
	if center_in_viewport:
		scroll.scroll_horizontal = int(frame_pos.x + cell.x * 0.5 - scroll.size.x * 0.5)
		scroll.scroll_vertical = int(frame_pos.y + cell.y * 0.5 - scroll.size.y * 0.5)
	else:
		scroll.scroll_horizontal = int(frame_pos.x)
		scroll.scroll_vertical = int(frame_pos.y)
	_clamp_scroll_to_bars(scroll)
	queue_redraw()


func focus_selection() -> void:
	var frames := get_selected_frames()
	if frames.is_empty():
		return
	var first_rc := _global_to_row_col(frames[0])
	var last_rc := _global_to_row_col(frames[frames.size() - 1])
	var mid_row := (first_rc.x + last_rc.x) / 2
	var mid_col := (first_rc.y + last_rc.y) / 2
	scroll_to_cell(mid_row, mid_col, true)


func _clamp_scroll_to_bars(scroll: ScrollContainer) -> void:
	var h_bar := scroll.get_h_scroll_bar()
	var v_bar := scroll.get_v_scroll_bar()
	if h_bar != null:
		scroll.scroll_horizontal = clampi(scroll.scroll_horizontal, int(h_bar.min_value), int(h_bar.max_value))
	if v_bar != null:
		scroll.scroll_vertical = clampi(scroll.scroll_vertical, int(v_bar.min_value), int(v_bar.max_value))


func _reset_scroll_offset() -> void:
	var scroll := _find_scroll_container()
	if scroll != null:
		scroll.scroll_horizontal = 0
		scroll.scroll_vertical = 0


func _bind_scroll_redraw() -> void:
	if _scroll_hooks_bound:
		return
	var scroll := _find_scroll_container()
	if scroll == null:
		return
	if not scroll.scroll_started.is_connected(_on_scroll_changed):
		scroll.scroll_started.connect(_on_scroll_changed)
	if not scroll.scroll_ended.is_connected(_on_scroll_changed):
		scroll.scroll_ended.connect(_on_scroll_changed)
	var h_bar := scroll.get_h_scroll_bar()
	var v_bar := scroll.get_v_scroll_bar()
	if h_bar != null and not h_bar.value_changed.is_connected(_on_scroll_changed):
		h_bar.value_changed.connect(_on_scroll_changed)
	if v_bar != null and not v_bar.value_changed.is_connected(_on_scroll_changed):
		v_bar.value_changed.connect(_on_scroll_changed)
	_scroll_hooks_bound = true


func _on_scroll_changed(_value: float = 0.0) -> void:
	queue_redraw()


func _find_scroll_container() -> ScrollContainer:
	var n: Node = get_parent()
	while n != null:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null


func _is_valid_frame(global_index: int) -> bool:
	return global_index >= 0 and global_index < get_total_frames()


func _global_to_row_col(global_index: int) -> Vector2i:
	return Vector2i(global_index / columns, global_index % columns)


func _row_col_to_global(row: int, column: int) -> int:
	return row * columns + column


func _canvas_to_frame(canvas_pos: Vector2) -> int:
	if sheet_texture == null or zoom <= 0.0:
		return -1
	var sheet_pos := canvas_pos / zoom
	var col := clampi(int(sheet_pos.x) / frame_width, 0, columns - 1)
	var row := clampi(int(sheet_pos.y) / frame_height, 0, rows - 1)
	return _row_col_to_global(row, col)


func _linear_frames_between(a: int, b: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if a < 0 or b < 0:
		return out
	if a <= b:
		for i: int in range(a, b + 1):
			if _is_valid_frame(i):
				out.append(i)
	else:
		for i: int in range(a, b - 1, -1):
			if _is_valid_frame(i):
				out.append(i)
	return out


func _apply_frames_to_selection(frames: PackedInt32Array) -> void:
	match selection_mode:
		SelectionMode.REPLACE:
			_selected.clear()
			for g: int in frames:
				if _is_valid_frame(g):
					_selected[g] = true
		SelectionMode.ADD:
			for g: int in frames:
				if _is_valid_frame(g):
					_selected[g] = true
		SelectionMode.REMOVE:
			for g: int in frames:
				_selected.erase(g)
	_emit_selection()


func _emit_selection() -> void:
	selection_changed.emit(get_selected_frames())


func _emit_hover(frame_index: int) -> void:
	if frame_index < 0:
		hover_changed.emit(-1, -1, -1)
		return
	var rc := _global_to_row_col(frame_index)
	hover_changed.emit(frame_index, rc.x, rc.y)


func _gui_input(event: InputEvent) -> void:
	if sheet_texture == null:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var frame_index := _canvas_to_frame(event.position)
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		if require_ctrl_for_wheel_zoom and not event.ctrl_pressed:
			_pan_scroll_with_wheel(-1, event.shift_pressed)
			accept_event()
			return
		set_zoom_value(zoom * 1.12, event.position)
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		if require_ctrl_for_wheel_zoom and not event.ctrl_pressed:
			_pan_scroll_with_wheel(1, event.shift_pressed)
			accept_event()
			return
		set_zoom_value(zoom / 1.12, event.position)
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_pan_drag = event.pressed
		accept_event()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_pan_drag = true
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_pan_drag = false
		accept_event()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed and event.double_click and double_click_focuses_frame and frame_index >= 0:
		_drag_active = false
		_drag_start_frame = -1
		_drag_end_frame = -1
		_selected.clear()
		_selected[frame_index] = true
		_emit_selection()
		scroll_to_frame(frame_index, true)
		queue_redraw()
		accept_event()
		return
	if event.pressed:
		if frame_index >= 0:
			_drag_active = true
			_drag_start_frame = frame_index
			_drag_end_frame = frame_index
			_apply_frames_to_selection(_linear_frames_between(_drag_start_frame, _drag_end_frame))
			queue_redraw()
	else:
		if _drag_active:
			_drag_active = false
			queue_redraw()
	accept_event()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _pan_drag:
		var scroll := _find_scroll_container()
		if scroll != null:
			scroll.scroll_horizontal -= int(event.relative.x)
			scroll.scroll_vertical -= int(event.relative.y)
			queue_redraw()
		accept_event()
		return
	var frame_index := _canvas_to_frame(event.position)
	if frame_index != _hover_frame:
		_hover_frame = frame_index
		_emit_hover(frame_index)
	if _drag_active and frame_index >= 0:
		_drag_end_frame = frame_index
		_apply_frames_to_selection(_linear_frames_between(_drag_start_frame, _drag_end_frame))
		queue_redraw()


func _pan_scroll_with_wheel(direction: int, horizontal: bool) -> void:
	var scroll := _find_scroll_container()
	if scroll == null:
		return
	var step := maxi(24, int(48.0 * zoom))
	if horizontal:
		scroll.scroll_horizontal += direction * step
	else:
		scroll.scroll_vertical += direction * step
	_clamp_scroll_to_bars(scroll)
	queue_redraw()


func _outline_width() -> float:
	return clampf(1.5 + zoom * 2.5, 2.0, 5.0)


func _draw_cell_range(start_row: int, end_row: int, start_col: int, end_col: int, cell: Vector2, drag_frames: Dictionary) -> void:
	for row: int in range(start_row, end_row + 1):
		for col: int in range(start_col, end_col + 1):
			var g := _row_col_to_global(row, col)
			var rect := Rect2(Vector2(col, row) * cell, cell)
			var region := Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
			draw_texture_rect_region(sheet_texture, rect, region)
			if _selected.has(g):
				draw_rect(rect, SELECTION_FILL, true)
				draw_rect(rect, SELECTED_OUTLINE, false, _outline_width())
			elif drag_frames.has(g):
				draw_rect(rect, DRAG_PREVIEW_FILL, true)
			if g == _hover_frame:
				draw_rect(rect, HOVER_OUTLINE, false, _outline_width() + 1.0)


func _draw() -> void:
	if sheet_texture == null or columns <= 0 or rows <= 0:
		draw_string(ThemeDB.fallback_font, Vector2(12, 24), "No sheet loaded.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		return
	var cell := Vector2(frame_width, frame_height) * zoom
	var content := _content_size()
	draw_rect(Rect2(Vector2.ZERO, content), CANVAS_BACKGROUND, true)
	var drag_frames: Dictionary = {}
	if _drag_active and _drag_start_frame >= 0 and _drag_end_frame >= 0:
		for g: int in _linear_frames_between(_drag_start_frame, _drag_end_frame):
			drag_frames[g] = true
	var total_cells := columns * rows
	if total_cells <= MAX_FULL_DRAW_CELLS:
		_draw_cell_range(0, rows - 1, 0, columns - 1, cell, drag_frames)
	else:
		var scroll := _find_scroll_container()
		var visible := Rect2(Vector2.ZERO, size)
		if scroll != null:
			visible = Rect2(
				Vector2(scroll.scroll_horizontal, scroll.scroll_vertical),
				scroll.size
			)
		var start_row := clampi(int(floor(visible.position.y / cell.y)), 0, rows - 1)
		var end_row := clampi(int(ceil(visible.end.y / cell.y)) - 1, 0, rows - 1)
		var start_col := clampi(int(floor(visible.position.x / cell.x)), 0, columns - 1)
		var end_col := clampi(int(ceil(visible.end.x / cell.x)) - 1, 0, columns - 1)
		_draw_cell_range(start_row, end_row, start_col, end_col, cell, drag_frames)
	if zoom >= 0.22:
		var font_size := clampi(int(11.0 * zoom / 0.25), 8, 18)
		var label_start_row := 0
		var label_end_row := rows - 1
		var label_start_col := 0
		var label_end_col := columns - 1
		if total_cells > MAX_FULL_DRAW_CELLS:
			var scroll2 := _find_scroll_container()
			var visible2 := Rect2(Vector2.ZERO, size)
			if scroll2 != null:
				visible2 = Rect2(Vector2(scroll2.scroll_horizontal, scroll2.scroll_vertical), scroll2.size)
			label_start_row = clampi(int(floor(visible2.position.y / cell.y)), 0, rows - 1)
			label_end_row = clampi(int(ceil(visible2.end.y / cell.y)) - 1, 0, rows - 1)
			label_start_col = clampi(int(floor(visible2.position.x / cell.x)), 0, columns - 1)
			label_end_col = clampi(int(ceil(visible2.end.x / cell.x)) - 1, 0, columns - 1)
		for row: int in range(label_start_row, label_end_row + 1):
			for col: int in range(label_start_col, label_end_col + 1):
				var g := _row_col_to_global(row, col)
				var rect := Rect2(Vector2(col, row) * cell, cell)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, font_size + 2), str(g), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, FRAME_LABEL_COLOR)
	var grid_line_w := clampf(0.75 + zoom * 1.25, 1.0, 2.5)
	for col: int in range(columns + 1):
		var x := float(col) * cell.x
		draw_line(Vector2(x, 0.0), Vector2(x, content.y), GRID_LINE_COLOR, grid_line_w)
	for row: int in range(rows + 1):
		var y := float(row) * cell.y
		draw_line(Vector2(0.0, y), Vector2(content.x, y), GRID_LINE_COLOR, grid_line_w)
	if zoom >= 0.14:
		_draw_axis_labels(cell, content)


func _draw_axis_labels(cell: Vector2, _content: Vector2) -> void:
	var axis_font := clampi(int(10.0 + zoom * 8.0), 9, 16)
	for col: int in range(0, columns, AXIS_LABEL_STEP):
		var x := float(col) * cell.x + 2.0
		draw_string(ThemeDB.fallback_font, Vector2(x, axis_font + 1.0), "c%d" % col, HORIZONTAL_ALIGNMENT_LEFT, -1, axis_font, AXIS_LABEL_COLOR)
	for row: int in range(0, rows, AXIS_LABEL_STEP):
		var y := float(row) * cell.y + axis_font + 1.0
		draw_string(ThemeDB.fallback_font, Vector2(2.0, y), "r%d" % row, HORIZONTAL_ALIGNMENT_LEFT, -1, axis_font, AXIS_LABEL_COLOR)
