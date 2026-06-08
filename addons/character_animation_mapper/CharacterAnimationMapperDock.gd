@tool
extends VBoxContainer

const DEFAULT_SHEET := "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_01_parmida_reference_variant_sheet.png"
const MAPS_DIR := "res://resources/character_animation_maps/"
const PREVIEW_DIR := "res://resources/character_animation_maps/generated_preview/"
const DEFAULT_MAP_NAME := "character__working_manual_map.json"
const CANDIDATE_MAP_NAME := "parmida_review_candidates_v1.json"
const DEFAULT_PREVIEW_SPRITEFRAMES := "character_01_parmida_reference_variant_preview_spriteframes.tres"
const C2B_RECOMMENDED_CLIPS := "res://docs/reports/character_animation_c2b_fix1/recommended_animation_clips.json"
const C2B_ACTION_SEGMENTS := "res://docs/reports/character_animation_c2b_fix1/action_segments.json"
const SANDBOX_SCENE := "res://scenes/hideout/tools/CharacterAnimationMapperPreviewSandbox.tscn"
const LARGE_REVIEW_WINDOW_SCRIPT := preload("res://addons/character_animation_mapper/CharacterAnimationLargeReviewWindow.gd")
const MANUAL_MAPPING_WINDOW_SCRIPT := preload("res://addons/character_animation_mapper/CharacterAnimationManualMappingWindow.gd")
const COLLAPSIBLE_SECTION_SCRIPT := preload("res://addons/character_animation_mapper/CharacterAnimationCollapsibleSection.gd")
const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const SPRITEFRAMES_EXPORTER := preload("res://addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd")
const DIAGNOSTIC_GRID_COLUMNS := 50
const MANUAL_5PACK_METADATA := "res://assets/characters/generated_player_visuals/manual_5pack_20260521/manual_5pack_metadata.json"

const REVIEW_STATUSES: Array[String] = ["reviewed", "needs_review", "rejected"]

const _UNSAFE_OUTPUT_MARKERS: Array[String] = [
	"scenes/player",
	"src/player",
	"TacoBellIso",
	"pvgames_cyber_city_character_creator_kit",
	"c2b_full_animation/parmida_player_spriteframes_0mc2b.tres",
]

var _plugin: EditorPlugin
var _editor_interface: EditorInterface

var _status_label: Label
var _sheet_path_edit: LineEdit
var _frame_width_spin: SpinBox
var _frame_height_spin: SpinBox
var _columns_spin: SpinBox
var _rows_spin: SpinBox
var _total_frames_label: Label
var _start_frame_spin: SpinBox
var _end_frame_spin: SpinBox
var _start_row_spin: SpinBox
var _start_col_spin: SpinBox
var _end_row_spin: SpinBox
var _end_col_spin: SpinBox
var _anim_name_edit: LineEdit
var _fps_spin: SpinBox
var _loop_check: CheckBox
var _review_status_option: OptionButton
var _notes_edit: LineEdit
var _map_filename_edit: LineEdit
var _range_list: ItemList
var _sheet_scroll: ScrollContainer
var _sheet_rect: TextureRect
var _preview_rect: TextureRect
var _preview_info: Label
var _click_mode_option: OptionButton
var _export_readout_label: Label
var _map_output_path_label: Label
var _candidate_hint_label: Label

var _sheet_texture: Texture2D
var _sheet_image: Image
var _sheet_path: String = ""
var _columns: int = 0
var _rows: int = 0
var _total_frames: int = 0
var _animations: Array[Dictionary] = []
var _selected_anim_index: int = -1

var _preview_timer: Timer
var _preview_frames: PackedInt32Array = PackedInt32Array()
var _preview_index: int = 0
var _preview_playing := false

var _large_review_window: Window
var _manual_mapping_window: Window
var _current_selection_frames: PackedInt32Array = PackedInt32Array()


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()


func _ready() -> void:
	_build_ui()
	_ensure_output_dirs()
	_sheet_path_edit.text = DEFAULT_SHEET if ResourceLoader.exists(DEFAULT_SHEET) else ""
	_refresh_export_readout()
	_update_status("Ready. Load a res:// spritesheet to begin.")


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Character Animation Mapper"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(380, 56)
	add_child(_status_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(380, 0)
	scroll.add_child(content)
	var spritesheet_body := _begin_collapsible_section(content, "Spritesheet", true)
	var sheet_row := HBoxContainer.new()
	_sheet_path_edit = LineEdit.new()
	_sheet_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_path_edit.placeholder_text = "res://path/to/sheet.png"
	_sheet_path_edit.text = DEFAULT_SHEET
	sheet_row.add_child(_sheet_path_edit)
	var load_btn := Button.new()
	load_btn.text = "Load Sheet"
	load_btn.pressed.connect(_on_load_sheet_pressed)
	sheet_row.add_child(load_btn)
	spritesheet_body.add_child(sheet_row)
	var frame_grid_body := _begin_collapsible_section(content, "Frame Grid", true)
	var grid := GridContainer.new()
	grid.columns = 2
	frame_grid_body.add_child(grid)
	grid.add_child(_label("Frame Width"))
	_frame_width_spin = _spin(200, 1, 4096, 1)
	grid.add_child(_frame_width_spin)
	grid.add_child(_label("Frame Height"))
	_frame_height_spin = _spin(200, 1, 4096, 1)
	grid.add_child(_frame_height_spin)
	grid.add_child(_label("Columns"))
	_columns_spin = _spin(1, 1, 512, 1)
	_columns_spin.value_changed.connect(func(_v: float) -> void: _recalc_total_frames())
	grid.add_child(_columns_spin)
	grid.add_child(_label("Rows"))
	_rows_spin = _spin(1, 1, 512, 1)
	_rows_spin.value_changed.connect(func(_v: float) -> void: _recalc_total_frames())
	grid.add_child(_rows_spin)
	grid.add_child(_label("Total Frames"))
	_total_frames_label = Label.new()
	_total_frames_label.text = "0"
	grid.add_child(_total_frames_label)
	var range_body := _begin_collapsible_section(content, "Range Selection", true)
	var range_grid := GridContainer.new()
	range_grid.columns = 2
	range_body.add_child(range_grid)
	range_grid.add_child(_label("Start Frame"))
	_start_frame_spin = _spin(0, 0, 999999, 1)
	range_grid.add_child(_start_frame_spin)
	range_grid.add_child(_label("End Frame"))
	_end_frame_spin = _spin(0, 0, 999999, 1)
	range_grid.add_child(_end_frame_spin)
	range_grid.add_child(_label("Start Row"))
	_start_row_spin = _spin(0, 0, 999, 1)
	range_grid.add_child(_start_row_spin)
	range_grid.add_child(_label("Start Column"))
	_start_col_spin = _spin(0, 0, 999, 1)
	range_grid.add_child(_start_col_spin)
	range_grid.add_child(_label("End Row"))
	_end_row_spin = _spin(0, 0, 999, 1)
	range_grid.add_child(_end_row_spin)
	range_grid.add_child(_label("End Column"))
	_end_col_spin = _spin(0, 0, 999, 1)
	range_grid.add_child(_end_col_spin)
	var range_btns := HBoxContainer.new()
	var rc_btn := Button.new()
	rc_btn.text = "Row/Column -> Global Range"
	rc_btn.pressed.connect(_on_row_column_to_global)
	range_btns.add_child(rc_btn)
	var use_global_btn := Button.new()
	use_global_btn.text = "Use Current Global Range"
	use_global_btn.pressed.connect(_on_use_global_range)
	range_btns.add_child(use_global_btn)
	range_body.add_child(range_btns)
	var metadata_body := _begin_collapsible_section(content, "Animation Metadata", true)
	var meta_grid := GridContainer.new()
	meta_grid.columns = 2
	metadata_body.add_child(meta_grid)
	meta_grid.add_child(_label("Animation Name"))
	_anim_name_edit = LineEdit.new()
	_anim_name_edit.placeholder_text = "idle, walk, run, ..."
	meta_grid.add_child(_anim_name_edit)
	meta_grid.add_child(_label("FPS"))
	_fps_spin = _spin(10.0, 0.1, 120.0, 0.5)
	meta_grid.add_child(_fps_spin)
	meta_grid.add_child(_label("Loop"))
	_loop_check = CheckBox.new()
	_loop_check.button_pressed = true
	meta_grid.add_child(_loop_check)
	meta_grid.add_child(_label("Review Status"))
	_review_status_option = OptionButton.new()
	for s in REVIEW_STATUSES:
		_review_status_option.add_item(s)
	meta_grid.add_child(_review_status_option)
	meta_grid.add_child(_label("Notes"))
	_notes_edit = LineEdit.new()
	meta_grid.add_child(_notes_edit)
	var action_btns := GridContainer.new()
	action_btns.columns = 2
	metadata_body.add_child(action_btns)
	var add_btn := Button.new()
	add_btn.text = "Add / Update Animation Range"
	add_btn.pressed.connect(_on_add_update_range)
	action_btns.add_child(add_btn)
	var remove_btn := Button.new()
	remove_btn.text = "Remove Selected Range"
	remove_btn.pressed.connect(_on_remove_range)
	action_btns.add_child(remove_btn)
	var preview_btn := Button.new()
	preview_btn.text = "Preview Selected Range"
	preview_btn.pressed.connect(_on_preview_pressed)
	action_btns.add_child(preview_btn)
	var stop_btn := Button.new()
	stop_btn.text = "Stop Preview"
	stop_btn.pressed.connect(_on_stop_preview)
	action_btns.add_child(stop_btn)
	var c2b_body := _begin_collapsible_section(content, "C2B Diagnostic Import (needs_review only)", false)
	_candidate_hint_label = Label.new()
	_candidate_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_candidate_hint_label.text = "Imported classifier/diagnostic ranges are suggestions only. They are saved as needs_review, never reviewed."
	c2b_body.add_child(_candidate_hint_label)
	var import_btns := GridContainer.new()
	import_btns.columns = 2
	c2b_body.add_child(import_btns)
	var import_btn := Button.new()
	import_btn.text = "Import C2B Candidates as Needs Review"
	import_btn.pressed.connect(_on_import_c2b_candidates)
	import_btns.add_child(import_btn)
	var save_cand_btn := Button.new()
	save_cand_btn.text = "Save Candidate Map JSON"
	save_cand_btn.pressed.connect(_on_save_candidate_map)
	import_btns.add_child(save_cand_btn)
	var export_body := _begin_collapsible_section(content, "Export / Sandbox", false)
	_export_readout_label = Label.new()
	_export_readout_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_body.add_child(_export_readout_label)
	var sandbox_btns := HBoxContainer.new()
	export_body.add_child(sandbox_btns)
	var open_sandbox_btn := Button.new()
	open_sandbox_btn.text = "Open Preview Sandbox Scene"
	open_sandbox_btn.pressed.connect(_on_open_preview_sandbox)
	sandbox_btns.add_child(open_sandbox_btn)
	var saved_ranges_body := _begin_collapsible_section(content, "Saved Ranges", true)
	_range_list = ItemList.new()
	_range_list.custom_minimum_size = Vector2(360, 120)
	_range_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_range_list.item_selected.connect(_on_range_selected)
	saved_ranges_body.add_child(_range_list)
	var map_io_body := _begin_collapsible_section(content, "Map I/O", true)
	meta_grid = GridContainer.new()
	meta_grid.columns = 2
	map_io_body.add_child(meta_grid)
	meta_grid.add_child(_label("Map JSON Filename"))
	_map_filename_edit = LineEdit.new()
	_map_filename_edit.text = DEFAULT_MAP_NAME
	_map_filename_edit.text_changed.connect(func(_t: String) -> void: _refresh_map_output_path_readout())
	meta_grid.add_child(_map_filename_edit)
	_map_output_path_label = Label.new()
	_map_output_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_io_body.add_child(_map_output_path_label)
	_refresh_map_output_path_readout()
	var io_btns := GridContainer.new()
	io_btns.columns = 2
	map_io_body.add_child(io_btns)
	var save_btn := Button.new()
	save_btn.text = "Save Reviewed Map JSON"
	save_btn.pressed.connect(_on_save_map)
	io_btns.add_child(save_btn)
	var load_map_btn := Button.new()
	load_map_btn.text = "Load Existing Map JSON"
	load_map_btn.pressed.connect(_on_load_map)
	io_btns.add_child(load_map_btn)
	var gen_btn := Button.new()
	gen_btn.text = "Generate Validation SpriteFrames"
	gen_btn.pressed.connect(_on_generate_spriteframes)
	io_btns.add_child(gen_btn)
	var copy_btn := Button.new()
	copy_btn.text = "Copy Output Path"
	copy_btn.pressed.connect(_on_copy_output_path)
	io_btns.add_child(copy_btn)
	var canvas_row := HBoxContainer.new()
	map_io_body.add_child(canvas_row)
	var open_canvas_btn := Button.new()
	open_canvas_btn.text = "Open Large Review Canvas"
	open_canvas_btn.pressed.connect(_on_open_large_review_canvas)
	canvas_row.add_child(open_canvas_btn)
	var open_manual_btn := Button.new()
	open_manual_btn.text = "Open Manual Mapping Window"
	open_manual_btn.pressed.connect(_on_open_manual_mapping_window)
	canvas_row.add_child(open_manual_btn)
	var contact_body := _begin_collapsible_section(content, "Sheet Contact View (click sets frame)", false)
	var click_row := HBoxContainer.new()
	click_row.add_child(_label("Click sets"))
	_click_mode_option = OptionButton.new()
	_click_mode_option.add_item("Start Frame")
	_click_mode_option.add_item("End Frame")
	click_row.add_child(_click_mode_option)
	contact_body.add_child(click_row)
	_sheet_scroll = ScrollContainer.new()
	_sheet_scroll.custom_minimum_size = Vector2(360, 180)
	_sheet_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contact_body.add_child(_sheet_scroll)
	_sheet_rect = TextureRect.new()
	_sheet_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sheet_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sheet_rect.custom_minimum_size = Vector2(360, 180)
	_sheet_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_sheet_rect.gui_input.connect(_on_sheet_gui_input)
	_sheet_scroll.add_child(_sheet_rect)
	var preview_body := _begin_collapsible_section(content, "Frame Preview", false)
	_preview_rect = TextureRect.new()
	_preview_rect.custom_minimum_size = Vector2(200, 200)
	_preview_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_body.add_child(_preview_rect)
	_preview_info = Label.new()
	_preview_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_body.add_child(_preview_info)
	_preview_timer = Timer.new()
	_preview_timer.wait_time = 0.12
	_preview_timer.timeout.connect(_on_preview_tick)
	add_child(_preview_timer)


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	return l


func _begin_collapsible_section(parent: Node, title: String, expanded: bool = true) -> VBoxContainer:
	var sec := COLLAPSIBLE_SECTION_SCRIPT.new()
	sec.setup(title, expanded)
	parent.add_child(sec)
	return sec.get_content()


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _spin(default_value: float, min_v: float, max_v: float, step: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = default_value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


func _ensure_output_dirs() -> void:
	_ensure_dir(MAPS_DIR)
	_ensure_dir(PREVIEW_DIR)


func _ensure_dir(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs):
		DirAccess.make_dir_recursive_absolute(abs)


func get_map_output_path() -> String:
	return _map_output_path()


func _refresh_map_output_path_readout() -> void:
	if _map_output_path_label == null:
		return
	_map_output_path_label.text = "Map JSON output: %s" % _map_output_path()


func _load_sheet_image_from_disk(path: String) -> Image:
	var abs_path := ProjectSettings.globalize_path(path)
	if abs_path.is_empty() or not FileAccess.file_exists(abs_path):
		return null
	var img := Image.load_from_file(abs_path)
	if img == null or img.is_empty():
		return null
	return img


func _metadata_grid_for_sheet(path: String) -> Vector2i:
	if not FileAccess.file_exists(ProjectSettings.globalize_path(MANUAL_5PACK_METADATA)):
		return Vector2i.ZERO
	var file := FileAccess.open(ProjectSettings.globalize_path(MANUAL_5PACK_METADATA), FileAccess.READ)
	if file == null:
		return Vector2i.ZERO
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	var data: Dictionary = parsed
	for ch in data.get("characters", []):
		if ch is Dictionary and String(ch.get("sheet_path", "")) == path:
			return Vector2i(int(ch.get("columns", 0)), int(ch.get("rows", 0)))
	return Vector2i(int(data.get("columns", 0)), int(data.get("rows", 0)))


func _on_load_sheet_pressed() -> void:
	var path := _sheet_path_edit.text.strip_edges()
	if not _validate_res_path(path):
		return
	if not ResourceLoader.exists(path):
		_update_status("Sheet not found: %s" % path)
		return
	var fw := int(_frame_width_spin.value)
	var fh := int(_frame_height_spin.value)
	if fw <= 0 or fh <= 0:
		_update_status("Frame width/height must be > 0.")
		return
	var img := _load_sheet_image_from_disk(path)
	if img == null:
		_update_status("Failed to read sheet image from disk: %s" % path)
		return
	var src_w := img.get_width()
	var src_h := img.get_height()
	_sheet_image = img
	_sheet_texture = ImageTexture.create_from_image(img)
	_sheet_path = path
	_sheet_rect.texture = _sheet_texture
	_columns = maxi(1, src_w / fw)
	_rows = maxi(1, src_h / fh)
	var meta_grid := _metadata_grid_for_sheet(path)
	if meta_grid.x > 0 and meta_grid.y > 0:
		var expected_frames := meta_grid.x * meta_grid.y
		if _columns * _rows != expected_frames and src_w >= meta_grid.x * fw and src_h >= meta_grid.y * fh:
			_columns = meta_grid.x
			_rows = meta_grid.y
	_columns_spin.value = _columns
	_rows_spin.value = _rows
	_recalc_total_frames()
	var sheet_display_h := 180.0
	_sheet_rect.custom_minimum_size = Vector2(360.0, sheet_display_h)
	var import_note := ""
	var imported_tex := load(path) as Texture2D
	if imported_tex != null and (imported_tex.get_width() != src_w or imported_tex.get_height() != src_h):
		import_note = " Imported resource was %dx%d; using full disk image for mapping." % [
			imported_tex.get_width(), imported_tex.get_height()
		]
	_update_status(
		"Loaded %s (disk %dx%d). Grid %d columns x %d rows = %d frames.%s" % [
			path, src_w, src_h, _columns, _rows, _total_frames, import_note
		]
	)
	_show_frame_preview(int(_start_frame_spin.value))


func _recalc_total_frames() -> void:
	_columns = int(_columns_spin.value)
	_rows = int(_rows_spin.value)
	_total_frames = _columns * _rows
	_total_frames_label.text = str(_total_frames)
	_start_frame_spin.max_value = maxi(0, _total_frames - 1)
	_end_frame_spin.max_value = maxi(0, _total_frames - 1)
	_start_row_spin.max_value = maxi(0, _rows - 1)
	_end_row_spin.max_value = maxi(0, _rows - 1)
	_start_col_spin.max_value = maxi(0, _columns - 1)
	_end_col_spin.max_value = maxi(0, _columns - 1)


func _validate_res_path(path: String) -> bool:
	if path.is_empty() or not path.begins_with("res://"):
		_update_status("Path must start with res://")
		return false
	return true


func _is_safe_output_path(path: String) -> bool:
	if not path.begins_with("res://"):
		return false
	if not path.begins_with(MAPS_DIR) and not path.begins_with(PREVIEW_DIR):
		return false
	for marker in _UNSAFE_OUTPUT_MARKERS:
		if path.contains(marker):
			return false
	return true


func _global_to_row_col(global_index: int) -> Vector2i:
	if _columns <= 0:
		return Vector2i.ZERO
	return Vector2i(global_index / _columns, global_index % _columns)


func _row_col_to_global(row: int, column: int) -> int:
	return row * _columns + column


func _expand_frame_range(start_frame: int, end_frame: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if end_frame < start_frame:
		return out
	for i in range(start_frame, end_frame + 1):
		out.append(i)
	return out


func _on_open_manual_mapping_window() -> void:
	if _sheet_texture == null:
		_update_status("Load a sheet first, then open Manual Mapping Window.")
		return
	if _columns <= 0 or _rows <= 0:
		_update_status("Set valid columns and rows before opening Manual Mapping Window.")
		return
	if _manual_mapping_window == null or not is_instance_valid(_manual_mapping_window):
		_manual_mapping_window = MANUAL_MAPPING_WINDOW_SCRIPT.new()
		if _editor_interface != null:
			var base := _editor_interface.get_base_control()
			if base != null:
				base.add_child(_manual_mapping_window)
		else:
			add_child(_manual_mapping_window)
		if _manual_mapping_window.has_signal("animation_updated"):
			_manual_mapping_window.animation_updated.connect(_on_large_review_animation_updated)
	if _editor_interface != null:
		var vp_size := _editor_interface.get_base_control().get_viewport_rect().size
		var w := maxi(1200, int(vp_size.x * 0.92))
		var h := maxi(820, int(vp_size.y * 0.92))
		_manual_mapping_window.size = Vector2i(w, h)
	_manual_mapping_window.setup_from_dock(self)
	_manual_mapping_window.popup_centered_ratio(0.92)
	_update_status("Manual Mapping Window opened.")


func _on_open_large_review_canvas() -> void:
	if _sheet_texture == null:
		_update_status("Load a sheet first, then open Large Review Canvas.")
		return
	if _columns <= 0 or _rows <= 0:
		_update_status("Set valid columns and rows before opening Large Review Canvas.")
		return
	if _large_review_window == null or not is_instance_valid(_large_review_window):
		_large_review_window = LARGE_REVIEW_WINDOW_SCRIPT.new()
		if _editor_interface != null:
			var base := _editor_interface.get_base_control()
			if base != null:
				base.add_child(_large_review_window)
		else:
			add_child(_large_review_window)
		if _large_review_window.has_signal("animation_updated"):
			_large_review_window.animation_updated.connect(_on_large_review_animation_updated)
	if _editor_interface != null:
		var vp_size := _editor_interface.get_base_control().get_viewport_rect().size
		var w := maxi(1200, int(vp_size.x * 0.9))
		var h := maxi(800, int(vp_size.y * 0.9))
		_large_review_window.size = Vector2i(w, h)
	_large_review_window.setup_from_dock(self)
	_large_review_window.popup_centered_ratio(0.9)
	_update_status("Large Review Canvas opened.")


func _on_large_review_animation_updated(_entry: Dictionary) -> void:
	_refresh_range_list()
	_refresh_export_readout()


func get_large_review_state() -> Dictionary:
	var selection := _current_selection_frames
	if selection.is_empty():
		if _selected_anim_index >= 0 and _selected_anim_index < _animations.size():
			selection = _frames_from_entry(_animations[_selected_anim_index])
		else:
			selection = _expand_frame_range(int(_start_frame_spin.value), int(_end_frame_spin.value))
	return {
		"sheet_texture": _sheet_texture,
		"sheet_path": _sheet_path,
		"frame_width": int(_frame_width_spin.value),
		"frame_height": int(_frame_height_spin.value),
		"columns": _columns,
		"rows": _rows,
		"total_frames": _total_frames,
		"selection_frames": selection,
		"animation_name": _anim_name_edit.text,
		"fps": float(_fps_spin.value),
		"loop": _loop_check.button_pressed,
		"review_status": REVIEW_STATUSES[_review_status_option.selected],
		"notes": _notes_edit.text,
	}


func get_animation_entries_snapshot() -> Array:
	var out: Array = []
	for e in _animations:
		out.append(e.duplicate(true))
	return out


func get_animation_entry_at(index: int) -> Dictionary:
	if index < 0 or index >= _animations.size():
		return {}
	return _animations[index].duplicate(true)


func delete_animation_by_index(index: int) -> Dictionary:
	if index < 0 or index >= _animations.size():
		return {"ok": false, "message": "Invalid animation index."}
	var removed_name: String = String(_animations[index].get("animation_name", ""))
	_animations.remove_at(index)
	if _selected_anim_index == index:
		_selected_anim_index = -1
	elif _selected_anim_index > index:
		_selected_anim_index -= 1
	_refresh_range_list()
	_refresh_export_readout()
	return {
		"ok": true,
		"message": (
			"Removed '%s' from dock list only. Click Save Reviewed Map JSON in the main dock to persist."
			% removed_name
		),
		"animation_name": removed_name,
	}


func _notify_manual_mapping_list_changed() -> void:
	if _manual_mapping_window == null or not is_instance_valid(_manual_mapping_window):
		return
	if not _manual_mapping_window.visible:
		return
	if _manual_mapping_window.has_method("refresh_saved_animations_list"):
		_manual_mapping_window.refresh_saved_animations_list()


func get_dock_selection_frames() -> PackedInt32Array:
	if _current_selection_frames.size() > 0:
		return _current_selection_frames
	if _selected_anim_index >= 0 and _selected_anim_index < _animations.size():
		return _frames_from_entry(_animations[_selected_anim_index])
	return _expand_frame_range(int(_start_frame_spin.value), int(_end_frame_spin.value))


func apply_canvas_selection_to_dock(frames: PackedInt32Array) -> void:
	_current_selection_frames = MAPPER_HELPERS.sorted_frames_array(frames)
	if _current_selection_frames.is_empty():
		_update_status("Canvas selection empty.")
		return
	var first_g := _current_selection_frames[0]
	var last_g := _current_selection_frames[_current_selection_frames.size() - 1]
	_start_frame_spin.value = first_g
	_end_frame_spin.value = last_g
	var rc_start := _global_to_row_col(first_g)
	var rc_end := _global_to_row_col(last_g)
	_start_row_spin.value = rc_start.x
	_start_col_spin.value = rc_start.y
	_end_row_spin.value = rc_end.x
	_end_col_spin.value = rc_end.y
	_show_frame_preview(first_g)
	_update_status("Applied canvas selection: %s" % MAPPER_HELPERS.selection_summary(_current_selection_frames))


func get_sheet_image_for_detection() -> Image:
	return _sheet_image


func get_sheet_path() -> String:
	return _sheet_path


func get_reviewed_animation_names() -> Array[String]:
	var names: Array[String] = []
	for e in _animations:
		names.append(String(e.get("animation_name", "")))
	return names


func approve_reviewed_animation(entry: Dictionary) -> Dictionary:
	if entry.is_empty():
		return {"ok": false, "message": "Empty animation entry."}
	var name := String(entry.get("animation_name", ""))
	if name.is_empty() or name.begins_with("candidate_"):
		return {"ok": false, "message": "Approve requires a final structured name (not candidate_###)." }
	var copy: Dictionary = entry.duplicate(true)
	copy["review_status"] = "reviewed"
	var frames := MAPPER_HELPERS.frames_from_entry(copy)
	if frames.is_empty():
		return {"ok": false, "message": "Candidate has no frames."}
	var rebuilt := MAPPER_HELPERS.build_animation_entry(
		name,
		frames,
		float(copy.get("fps", 10.0)),
		bool(copy.get("loop", true)),
		"reviewed",
		String(copy.get("notes", "")),
		_columns
	)
	var replaced := false
	for i in range(_animations.size()):
		if String(_animations[i].get("animation_name", "")) == name:
			_animations[i] = rebuilt
			replaced = true
			_selected_anim_index = i
			break
	if not replaced:
		_animations.append(rebuilt)
		_selected_anim_index = _animations.size() - 1
	_refresh_range_list()
	_refresh_export_readout()
	var warn := ""
	if replaced:
		warn = "%s already existed. Approving replaced it in the reviewed list." % name
	return {
		"ok": true,
		"message": "Approved '%s' as reviewed in main dock list. %s" % [name, warn],
		"replaced": replaced,
		"entry": rebuilt,
	}


func upsert_animation_from_canvas(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var name := String(entry.get("animation_name", ""))
	if name.is_empty():
		return
	var replaced := false
	for i in range(_animations.size()):
		if String(_animations[i].get("animation_name", "")) == name:
			_animations[i] = entry
			replaced = true
			_selected_anim_index = i
			break
	if not replaced:
		_animations.append(entry)
		_selected_anim_index = _animations.size() - 1
	var raw: Array = entry.get("frames", [])
	_current_selection_frames = PackedInt32Array()
	for v in raw:
		_current_selection_frames.append(int(v))
	_anim_name_edit.text = name
	_start_frame_spin.value = int(entry.get("start_frame", 0))
	_end_frame_spin.value = int(entry.get("end_frame", 0))
	_fps_spin.value = float(entry.get("fps", 10.0))
	_loop_check.button_pressed = bool(entry.get("loop", true))
	var status: String = String(entry.get("review_status", "needs_review"))
	_review_status_option.select(REVIEW_STATUSES.find(status) if status in REVIEW_STATUSES else 1)
	_notes_edit.text = String(entry.get("notes", ""))
	var ranges: Array = entry.get("row_column_ranges", [])
	if not ranges.is_empty():
		var r: Dictionary = ranges[0]
		_start_row_spin.value = int(r.get("start_row", 0))
		_start_col_spin.value = int(r.get("start_column", 0))
		_end_row_spin.value = int(r.get("end_row", 0))
		_end_col_spin.value = int(r.get("end_column", 0))
	_refresh_range_list()
	_refresh_export_readout()
	_update_status("%s animation '%s' in dock list (save JSON to persist)." % ["Updated" if replaced else "Added", name])


func _on_row_column_to_global() -> void:
	_current_selection_frames = PackedInt32Array()
	if _columns <= 0:
		_update_status("Load sheet and set columns first.")
		return
	var sr := int(_start_row_spin.value)
	var sc := int(_start_col_spin.value)
	var er := int(_end_row_spin.value)
	var ec := int(_end_col_spin.value)
	if er < sr or (er == sr and ec < sc):
		_update_status("Invalid row/column range.")
		return
	var start_g := _row_col_to_global(sr, sc)
	var end_g := _row_col_to_global(er, ec)
	if start_g > end_g:
		var tmp := start_g
		start_g = end_g
		end_g = tmp
	_start_frame_spin.value = start_g
	_end_frame_spin.value = end_g
	_update_status("Global range %d..%d (row %d,%d -> %d,%d)." % [start_g, end_g, sr, sc, er, ec])


func _on_use_global_range() -> void:
	_current_selection_frames = PackedInt32Array()
	var g := int(_start_frame_spin.value)
	var rc := _global_to_row_col(g)
	_start_row_spin.value = rc.x
	_start_col_spin.value = rc.y
	_end_row_spin.value = rc.x
	_end_col_spin.value = rc.y
	_end_frame_spin.value = g
	_update_status("Row/column set from global frame %d." % g)


func _on_add_update_range() -> void:
	if _sheet_texture == null:
		_update_status("Load a sheet first.")
		return
	var name := _anim_name_edit.text.strip_edges()
	if name.is_empty():
		_update_status("Animation name required.")
		return
	var start_f := int(_start_frame_spin.value)
	var end_f := int(_end_frame_spin.value)
	if end_f < start_f:
		_update_status("End frame must be >= start frame.")
		return
	if end_f >= _total_frames:
		_update_status("Range outside sheet bounds (max frame %d)." % (_total_frames - 1))
		return
	var frames: PackedInt32Array
	if _current_selection_frames.size() > 0:
		frames = _current_selection_frames
	else:
		frames = _expand_frame_range(start_f, end_f)
	var entry: Dictionary = MAPPER_HELPERS.build_animation_entry(
		name,
		frames,
		float(_fps_spin.value),
		_loop_check.button_pressed,
		REVIEW_STATUSES[_review_status_option.selected],
		_notes_edit.text,
		_columns
	)
	if entry.is_empty():
		_update_status("Invalid frame selection.")
		return
	var replaced := false
	for i in range(_animations.size()):
		if String(_animations[i].get("animation_name", "")) == name:
			_animations[i] = entry
			replaced = true
			break
	if not replaced:
		_animations.append(entry)
	_refresh_range_list()
	_refresh_export_readout()
	_update_status("%s animation '%s' frames %d..%d." % ["Updated" if replaced else "Added", name, start_f, end_f])


func _on_remove_range() -> void:
	if _selected_anim_index < 0 or _selected_anim_index >= _animations.size():
		_update_status("Select a range to remove.")
		return
	var removed_name: String = _animations[_selected_anim_index].get("animation_name", "")
	_animations.remove_at(_selected_anim_index)
	_selected_anim_index = -1
	_refresh_range_list()
	_refresh_export_readout()
	_update_status("Removed '%s'." % removed_name)


func _on_range_selected(index: int) -> void:
	_selected_anim_index = index
	if index < 0 or index >= _animations.size():
		return
	var e: Dictionary = _animations[index]
	_anim_name_edit.text = String(e.get("animation_name", ""))
	_start_frame_spin.value = int(e.get("start_frame", 0))
	_end_frame_spin.value = int(e.get("end_frame", 0))
	_fps_spin.value = float(e.get("fps", 10.0))
	_loop_check.button_pressed = bool(e.get("loop", true))
	var status: String = String(e.get("review_status", "needs_review"))
	_review_status_option.select(REVIEW_STATUSES.find(status) if status in REVIEW_STATUSES else 1)
	_notes_edit.text = String(e.get("notes", ""))
	var ranges: Array = e.get("row_column_ranges", [])
	if not ranges.is_empty():
		var r: Dictionary = ranges[0]
		_start_row_spin.value = int(r.get("start_row", 0))
		_start_col_spin.value = int(r.get("start_column", 0))
		_end_row_spin.value = int(r.get("end_row", 0))
		_end_col_spin.value = int(r.get("end_column", 0))
	_current_selection_frames = _frames_from_entry(e)
	_preview_frames = _current_selection_frames
	_show_frame_preview(_preview_frames[0] if _preview_frames.size() > 0 else 0)
	if _large_review_window != null and is_instance_valid(_large_review_window) and _large_review_window.visible:
		_large_review_window.sync_selection_from_dock_animation(_current_selection_frames)
	if _manual_mapping_window != null and is_instance_valid(_manual_mapping_window) and _manual_mapping_window.visible:
		_manual_mapping_window.sync_selection_from_dock(_current_selection_frames)


func _frames_from_entry(entry: Dictionary) -> PackedInt32Array:
	var raw: Array = entry.get("frames", [])
	if not raw.is_empty():
		var out := PackedInt32Array()
		for v in raw:
			out.append(int(v))
		return out
	return _expand_frame_range(int(entry.get("start_frame", 0)), int(entry.get("end_frame", 0)))


func _refresh_range_list() -> void:
	_range_list.clear()
	for e in _animations:
		_range_list.add_item(MAPPER_HELPERS.format_animation_list_label(e))
	_refresh_export_readout()
	_notify_manual_mapping_list_changed()


func _count_ranges_by_status(status: String) -> int:
	var n := 0
	for e in _animations:
		if String(e.get("review_status", "")) == status:
			n += 1
	return n


func _refresh_export_readout() -> void:
	if _export_readout_label == null:
		return
	var reviewed := _count_ranges_by_status("reviewed")
	var needs := _count_ranges_by_status("needs_review")
	var rejected := _count_ranges_by_status("rejected")
	var out_path := PREVIEW_DIR.path_join(DEFAULT_PREVIEW_SPRITEFRAMES)
	var msg := "Export: %d reviewed (will generate small external-reference SpriteFrames), %d needs_review, %d rejected. Output: %s" % [
		reviewed, needs, rejected, out_path
	]
	if reviewed == 0 and not _animations.is_empty():
		msg += " Warning: no reviewed ranges — Generate Validation SpriteFrames will refuse export."
	_export_readout_label.text = msg


func _diagnostic_columns_for_import() -> int:
	if _columns > 0:
		return _columns
	return DIAGNOSTIC_GRID_COLUMNS


func _clip_to_candidate_entry(clip: Dictionary, diagnostic_label: String) -> Dictionary:
	var cols := _diagnostic_columns_for_import()
	var start_g := int(clip.get("start_global", -1))
	var end_g := int(clip.get("end_global", -1))
	if start_g < 0 or end_g < start_g:
		return {}
	var action_label := String(clip.get("action_label", clip.get("clip_name", "unknown")))
	var anim_name := "needs_review_%s" % action_label
	var start_rc := _global_to_row_col_with_cols(start_g, cols)
	var end_rc := _global_to_row_col_with_cols(end_g, cols)
	var frames := _expand_frame_range(start_g, end_g)
	var notes := "source=character_animation_c2b_fix1; diagnostic_label=%s; requires_manual_review" % diagnostic_label
	if float(clip.get("confidence", -1.0)) >= 0.0:
		notes += "; confidence=%.3f" % float(clip.get("confidence"))
	return {
		"animation_name": anim_name,
		"start_frame": start_g,
		"end_frame": end_g,
		"frames": Array(frames),
		"fps": _default_fps_for_action(action_label),
		"loop": _should_loop_action(action_label),
		"review_status": "needs_review",
		"notes": notes,
		"row_column_ranges": [{
			"start_row": start_rc.x,
			"start_column": start_rc.y,
			"end_row": end_rc.x,
			"end_column": end_rc.y,
		}],
	}


func _global_to_row_col_with_cols(global_index: int, cols: int) -> Vector2i:
	if cols <= 0:
		return Vector2i.ZERO
	return Vector2i(global_index / cols, global_index % cols)


func _default_fps_for_action(action_label: String) -> float:
	match action_label:
		"idle", "sit", "fight_stance":
			return 8.0
		"walk", "half_crouch_sneak", "full_crouch":
			return 10.0
		"run":
			return 12.0
		"jump", "fall", "dance":
			return 10.0
		_:
			return 10.0


func _should_loop_action(action_label: String) -> bool:
	return action_label in ["idle", "walk", "run", "half_crouch_sneak", "full_crouch", "sit", "fight_stance", "dance"]


func _parse_recommended_clips() -> Dictionary:
	var abs := ProjectSettings.globalize_path(C2B_RECOMMENDED_CLIPS)
	if not FileAccess.file_exists(abs):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(abs))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var clips: Variant = parsed.get("clips", {})
	if typeof(clips) != TYPE_DICTIONARY or clips.is_empty():
		return {}
	return clips


func _parse_action_segments() -> Array:
	var abs := ProjectSettings.globalize_path(C2B_ACTION_SEGMENTS)
	if not FileAccess.file_exists(abs):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(abs))
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var segs: Variant = parsed.get("segments", [])
	if typeof(segs) != TYPE_ARRAY:
		return []
	return segs


func _segment_to_candidate_entry(seg: Dictionary) -> Dictionary:
	var cols := _diagnostic_columns_for_import()
	var start_g := int(seg.get("start_global_frame_index", seg.get("start_global", -1)))
	var end_g := int(seg.get("end_global_frame_index", seg.get("end_global", -1)))
	if start_g < 0 or end_g < start_g:
		return {}
	var action_label := String(seg.get("action_label", "unknown"))
	var diagnostic_label := "%s_segment_%s" % [action_label, str(seg.get("segment_id", "?"))]
	var clip := {
		"action_label": action_label,
		"start_global": start_g,
		"end_global": end_g,
		"confidence": float(seg.get("confidence", 0.0)),
	}
	return _clip_to_candidate_entry(clip, diagnostic_label)


func _on_import_c2b_candidates() -> void:
	var cols := _diagnostic_columns_for_import()
	var clips := _parse_recommended_clips()
	var source := "recommended_animation_clips.json"
	var entries: Array[Dictionary] = []
	if not clips.is_empty():
		for diagnostic_label in clips.keys():
			var clip: Dictionary = clips[diagnostic_label]
			if typeof(clip) != TYPE_DICTIONARY:
				continue
			var entry := _clip_to_candidate_entry(clip, String(diagnostic_label))
			if entry.is_empty():
				continue
			entries.append(entry)
	else:
		var segs := _parse_action_segments()
		if segs.is_empty():
			_update_status("C2B candidate import failed: missing or unreadable recommended_animation_clips.json and action_segments.json.")
			return
		source = "action_segments.json"
		for seg_v in segs:
			if typeof(seg_v) != TYPE_DICTIONARY:
				continue
			var entry := _segment_to_candidate_entry(seg_v)
			if not entry.is_empty():
				entries.append(entry)
	if entries.is_empty():
		_update_status("C2B candidate import failed: no mappable clips/segments in diagnostic JSON.")
		return
	var max_frame := -1
	if _total_frames > 0:
		max_frame = _total_frames - 1
	var imported := 0
	var skipped := 0
	for entry in entries:
		if max_frame >= 0 and int(entry.get("end_frame", 0)) > max_frame:
			skipped += 1
			continue
		var anim_name: String = entry.get("animation_name", "")
		var replaced := false
		for i in range(_animations.size()):
			if String(_animations[i].get("animation_name", "")) == anim_name:
				_animations[i] = entry
				replaced = true
				break
		if not replaced:
			_animations.append(entry)
		imported += 1
	_refresh_range_list()
	var msg := "Imported %d C2B candidates from %s as needs_review (grid cols=%d)." % [imported, source, cols]
	if skipped > 0:
		msg += " Skipped %d (outside loaded sheet bounds)." % skipped
	msg += " Classifier labels are suggestions only."
	_update_status(msg)


func _build_candidate_map_dict() -> Dictionary:
	var base := _build_map_dict()
	base["map_kind"] = "review_candidates"
	base["imported_from"] = C2B_RECOMMENDED_CLIPS if FileAccess.file_exists(ProjectSettings.globalize_path(C2B_RECOMMENDED_CLIPS)) else C2B_ACTION_SEGMENTS
	for e in base.get("animations", []):
		if e is Dictionary:
			e["review_status"] = "needs_review"
	return base


func _on_save_candidate_map() -> void:
	if _animations.is_empty():
		_update_status("Import or add candidates before saving.")
		return
	_ensure_output_dirs()
	var out_path := MAPS_DIR.path_join(_sanitize_filename(CANDIDATE_MAP_NAME))
	if not out_path.begins_with(MAPS_DIR):
		_update_status("Refusing to write outside character_animation_maps.")
		return
	var data := _build_candidate_map_dict()
	for e in data.get("animations", []):
		if e is Dictionary and String(e.get("review_status", "")) == "reviewed":
			_update_status("Refusing candidate save: found reviewed entry (candidates must stay needs_review).")
			return
	var file := FileAccess.open(ProjectSettings.globalize_path(out_path), FileAccess.WRITE)
	if file == null:
		_update_status("Failed to write candidate map.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_map_filename_edit.text = CANDIDATE_MAP_NAME
	_update_status("Saved candidate map: %s" % out_path)


func _on_open_preview_sandbox() -> void:
	if _editor_interface == null:
		_update_status("Editor interface unavailable.")
		return
	if not ResourceLoader.exists(SANDBOX_SCENE):
		_update_status("Sandbox scene missing: %s" % SANDBOX_SCENE)
		return
	_editor_interface.open_scene_from_path(SANDBOX_SCENE)
	_update_status("Opened preview sandbox. Run scene (F6) after generating validation SpriteFrames.")


func _on_preview_pressed() -> void:
	if _sheet_texture == null:
		_update_status("Load a sheet first.")
		return
	if _selected_anim_index >= 0 and _selected_anim_index < _animations.size():
		_preview_frames = _frames_from_entry(_animations[_selected_anim_index])
	elif _start_frame_spin.value <= _end_frame_spin.value:
		_preview_frames = _expand_frame_range(int(_start_frame_spin.value), int(_end_frame_spin.value))
	else:
		_update_status("No frames to preview.")
		return
	if _preview_frames.is_empty():
		_update_status("No frames to preview.")
		return
	_preview_index = 0
	_preview_playing = true
	_preview_timer.start()
	_show_frame_preview(_preview_frames[0])
	_update_status("Previewing %d frames." % _preview_frames.size())


func _on_stop_preview() -> void:
	_preview_playing = false
	_preview_timer.stop()
	_update_status("Preview stopped.")


func _on_preview_tick() -> void:
	if not _preview_playing or _preview_frames.is_empty():
		return
	_preview_index += 1
	if _preview_index >= _preview_frames.size():
		var entry_loop := true
		if _selected_anim_index >= 0 and _selected_anim_index < _animations.size():
			entry_loop = bool(_animations[_selected_anim_index].get("loop", true))
		elif _loop_check.button_pressed:
			entry_loop = true
		else:
			entry_loop = false
		if entry_loop:
			_preview_index = 0
		else:
			_preview_index = _preview_frames.size() - 1
			_preview_playing = false
			_preview_timer.stop()
	_show_frame_preview(_preview_frames[_preview_index])


func _atlas_for_frame(global_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet_texture
	var rc := _global_to_row_col(global_index)
	var fw := int(_frame_width_spin.value)
	var fh := int(_frame_height_spin.value)
	atlas.region = Rect2(rc.y * fw, rc.x * fh, fw, fh)
	return atlas


func _show_frame_preview(global_index: int) -> void:
	if _sheet_texture == null or _columns <= 0:
		return
	global_index = clampi(global_index, 0, maxi(0, _total_frames - 1))
	_preview_rect.texture = _atlas_for_frame(global_index)
	var rc := _global_to_row_col(global_index)
	_preview_info.text = "Frame %d | row %d | col %d" % [global_index, rc.x, rc.y]


func _on_sheet_gui_input(event: InputEvent) -> void:
	if _sheet_texture == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var local := mb.position
		var rect_size := _sheet_rect.size
		if rect_size.x <= 0.0 or rect_size.y <= 0.0:
			return
		var img_w := float(_sheet_texture.get_width())
		var img_h := float(_sheet_texture.get_height())
		var px := int(clampf(local.x / rect_size.x, 0.0, 1.0) * img_w)
		var py := int(clampf(local.y / rect_size.y, 0.0, 1.0) * img_h)
		var fw := int(_frame_width_spin.value)
		var fh := int(_frame_height_spin.value)
		var col := clampi(px / fw, 0, _columns - 1)
		var row := clampi(py / fh, 0, _rows - 1)
		var g := _row_col_to_global(row, col)
		if _click_mode_option.selected == 0:
			_start_frame_spin.value = g
			_start_row_spin.value = row
			_start_col_spin.value = col
		else:
			_end_frame_spin.value = g
			_end_row_spin.value = row
			_end_col_spin.value = col
		_show_frame_preview(g)
		_update_status("Click set frame %d (row %d, col %d)." % [g, row, col])


func _build_map_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"tool": "CharacterAnimationMapperDock",
		"source_sheet": _sheet_path,
		"frame_width": int(_frame_width_spin.value),
		"frame_height": int(_frame_height_spin.value),
		"columns": _columns,
		"rows": _rows,
		"animations": _animations.duplicate(true),
	}


func _sanitize_filename(name: String) -> String:
	var base := name.strip_edges()
	if base.is_empty():
		base = DEFAULT_MAP_NAME
	if not base.ends_with(".json"):
		base += ".json"
	var safe := ""
	for c in base:
		if c.is_valid_identifier() or c == '.' or c == '-' or c == '_':
			safe += c
		elif c == ' ':
			safe += "_"
	if not safe.ends_with(".json"):
		safe += ".json"
	return safe


func _map_output_path() -> String:
	return MAPS_DIR.path_join(_sanitize_filename(_map_filename_edit.text))


func _on_save_map() -> void:
	if _sheet_path.is_empty():
		_update_status("Load sheet before saving map.")
		return
	if _animations.is_empty():
		_update_status("Add at least one animation range.")
		return
	_ensure_output_dirs()
	var out_path := _map_output_path()
	if not out_path.begins_with(MAPS_DIR):
		_update_status("Refusing to write outside character_animation_maps.")
		return
	var json_text := JSON.stringify(_build_map_dict(), "\t")
	var file := FileAccess.open(ProjectSettings.globalize_path(out_path), FileAccess.WRITE)
	if file == null:
		_update_status("Failed to open %s for write." % out_path)
		return
	file.store_string(json_text)
	file.close()
	_refresh_map_output_path_readout()
	_update_status("Saved Reviewed Map JSON: %s (%d animations)." % [out_path, _animations.size()])


func _on_load_map() -> void:
	var path := _map_output_path()
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		_update_status("Map not found: %s" % path)
		return
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if file == null:
		_update_status("Failed to read map.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_update_status("Invalid map JSON.")
		return
	var data: Dictionary = parsed
	_sheet_path_edit.text = String(data.get("source_sheet", DEFAULT_SHEET))
	_frame_width_spin.value = int(data.get("frame_width", 200))
	_frame_height_spin.value = int(data.get("frame_height", 200))
	_columns_spin.value = int(data.get("columns", 50))
	_rows_spin.value = int(data.get("rows", 50))
	_recalc_total_frames()
	var anims: Array = data.get("animations", [])
	_animations.clear()
	for a in anims:
		if a is Dictionary:
			_animations.append(a)
	_refresh_range_list()
	_refresh_export_readout()
	if ResourceLoader.exists(_sheet_path_edit.text):
		_on_load_sheet_pressed()
	_update_status("Loaded map %s (%d animations)." % [path, _animations.size()])


func _on_generate_spriteframes() -> void:
	if _sheet_texture == null:
		_update_status("Load sheet first.")
		return
	if _animations.is_empty():
		_update_status("No animations in map.")
		return
	var reviewed_count := _count_ranges_by_status("reviewed")
	if reviewed_count == 0:
		_update_status("Warning: 0 reviewed ranges. SpriteFrames export requires reviewed status. Mark ranges reviewed first.")
		return
	_ensure_dir(PREVIEW_DIR)
	var out_path := PREVIEW_DIR.path_join(DEFAULT_PREVIEW_SPRITEFRAMES)
	if not _is_safe_output_path(out_path):
		_update_status("Refusing unsafe output path.")
		return
	var built: Dictionary = SPRITEFRAMES_EXPORTER.build_spriteframes_from_map_data(_build_map_dict())
	if not bool(built.get("ok", false)):
		_update_status("SpriteFrames export failed: %s" % String(built.get("message", "unknown error")))
		return
	var sf := built.get("spriteframes") as SpriteFrames
	if sf == null:
		_update_status("SpriteFrames export failed: exporter did not return SpriteFrames.")
		return
	var err := ResourceSaver.save(sf, out_path)
	if err != OK:
		_update_status("SpriteFrames save failed: %s" % error_string(err))
		return
	_refresh_export_readout()
	_update_status("Validation SpriteFrames saved with external sheet refs (%d anims): %s" % [int(built.get("animation_count", 0)), out_path])


func _on_copy_output_path() -> void:
	DisplayServer.clipboard_set(_map_output_path())
	_update_status("Copied map path: %s" % _map_output_path())


func _update_status(message: String) -> void:
	if _status_label:
		_status_label.text = message
