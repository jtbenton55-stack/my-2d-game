extends Window

const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const PANEL_BACKGROUND := Color(0.96, 0.96, 0.94, 1.0)
const PANEL_TEXT_COLOR := Color(0.12, 0.12, 0.15, 1.0)

signal range_focus_requested(start_frame: int, end_frame: int, select_frames: bool)

var _range_list: ItemList
var _detail_label: Label
var _thumb_scroll: ScrollContainer
var _thumb_strip: HBoxContainer
var _ranges: Array = []
var _sheet_texture: Texture2D
var _frame_width: int = 200
var _frame_height: int = 200
var _columns: int = 50


func _init() -> void:
	title = "Unassigned Frames Viewer"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	size = Vector2i(640, 520)
	min_size = Vector2i(480, 360)
	close_requested.connect(_on_close_requested)


func _ready() -> void:
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	shell.add_theme_stylebox_override("panel", style)
	add_child(shell)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(root)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	hint.text = "Read-only view of contiguous unassigned frame ranges from the current in-memory map."
	root.add_child(hint)
	_range_list = ItemList.new()
	_range_list.custom_minimum_size = Vector2(0, 180)
	_range_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_range_list.item_selected.connect(_on_range_selected)
	root.add_child(_range_list)
	var btn_row := HBoxContainer.new()
	root.add_child(btn_row)
	var focus_btn := Button.new()
	focus_btn.text = "Focus Range"
	focus_btn.pressed.connect(_on_focus_pressed)
	btn_row.add_child(focus_btn)
	var select_btn := Button.new()
	select_btn.text = "Select Range"
	select_btn.pressed.connect(_on_select_pressed)
	btn_row.add_child(select_btn)
	_detail_label = Label.new()
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_detail_label.text = "Select an unassigned range."
	root.add_child(_detail_label)
	root.add_child(_make_label("Range thumbnails (first up to 12 frames)"))
	_thumb_scroll = ScrollContainer.new()
	_thumb_scroll.custom_minimum_size = Vector2(0, 120)
	_thumb_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_thumb_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_thumb_scroll)
	_thumb_strip = HBoxContainer.new()
	_thumb_scroll.add_child(_thumb_strip)


func configure_sheet(texture: Texture2D, fw: int, fh: int, cols: int) -> void:
	_sheet_texture = texture
	_frame_width = maxi(1, fw)
	_frame_height = maxi(1, fh)
	_columns = maxi(1, cols)


func set_unassigned_ranges(ranges: Array) -> void:
	_ranges = ranges.duplicate(true)
	_refresh_list()


func _refresh_list() -> void:
	if _range_list == null:
		return
	_range_list.clear()
	for r in _ranges:
		if r is Dictionary:
			_range_list.add_item(MAPPER_HELPERS.format_unassigned_range_list_label(r))
	if _ranges.is_empty():
		_detail_label.text = "No unassigned frame ranges."
		_clear_thumbnails()
	else:
		_range_list.select(0)
		_on_range_selected(0)


func _on_range_selected(index: int) -> void:
	if index < 0 or index >= _ranges.size():
		return
	var range_dict: Dictionary = _ranges[index]
	_detail_label.text = MAPPER_HELPERS.format_unassigned_range_list_label(range_dict)
	_refresh_thumbnails(range_dict)


func _refresh_thumbnails(range_dict: Dictionary) -> void:
	_clear_thumbnails()
	if _sheet_texture == null:
		return
	var start_f := int(range_dict.get("start_frame", 0))
	var end_f := int(range_dict.get("end_frame", start_f))
	var shown := 0
	for frame_index: int in range(start_f, end_f + 1):
		if shown >= 12:
			break
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(72, 72)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = _atlas_for_frame(frame_index)
		_thumb_strip.add_child(tex_rect)
		shown += 1


func _clear_thumbnails() -> void:
	if _thumb_strip == null:
		return
	for child in _thumb_strip.get_children():
		child.queue_free()


func _atlas_for_frame(global_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet_texture
	var row: int = global_index / _columns
	var col: int = global_index % _columns
	atlas.region = Rect2(col * _frame_width, row * _frame_height, _frame_width, _frame_height)
	return atlas


func _current_range() -> Dictionary:
	var selected := _range_list.get_selected_items()
	if selected.is_empty():
		return {}
	var index: int = selected[0]
	if index < 0 or index >= _ranges.size():
		return {}
	return _ranges[index]


func _on_focus_pressed() -> void:
	var r := _current_range()
	if r.is_empty():
		return
	range_focus_requested.emit(int(r.get("start_frame", 0)), int(r.get("end_frame", 0)), false)


func _on_select_pressed() -> void:
	var r := _current_range()
	if r.is_empty():
		return
	range_focus_requested.emit(int(r.get("start_frame", 0)), int(r.get("end_frame", 0)), true)


func _on_close_requested() -> void:
	hide()


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	return label
