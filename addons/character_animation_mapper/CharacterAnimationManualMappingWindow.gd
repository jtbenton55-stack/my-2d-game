extends Window

const GridCanvasScript := preload("res://addons/character_animation_mapper/CharacterAnimationGridCanvas.gd")
const StripScript := preload("res://addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd")
const COLLAPSIBLE_SECTION_SCRIPT := preload("res://addons/character_animation_mapper/CharacterAnimationCollapsibleSection.gd")
const UNASSIGNED_VIEWER_SCRIPT := preload("res://addons/character_animation_mapper/CharacterAnimationUnassignedFramesViewer.gd")
const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const MAPS_DIR := "res://resources/character_animation_maps/"
const PANEL_BACKGROUND := Color(0.96, 0.96, 0.94, 1.0)
const PANEL_TEXT_COLOR := Color(0.12, 0.12, 0.15, 1.0)

signal animation_updated(entry: Dictionary)

var dock: Node = null

var _grid: Control
var _scroll: ScrollContainer
var _status_label: Label
var _selection_summary_label: Label
var _hover_label: Label
var _zoom_spin: SpinBox
var _mode_option: OptionButton
var _jump_frame_spin: SpinBox
var _jump_row_spin: SpinBox
var _start_frame_spin: SpinBox
var _end_frame_spin: SpinBox
var _updating_frame_spins := false

var _structured_name_label: Label
var _variant_spin: SpinBox
var _custom_action_edit: LineEdit
var _direction_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []

var _anim_name: LineEdit
var _action_search_edit: LineEdit
var _action_pick_list: ItemList
var _fps_spin: SpinBox
var _loop_check: CheckBox
var _review_option: OptionButton
var _notes_edit: LineEdit

var _saved_anim_list: ItemList
var _saved_anim_entries: Array = []
var _selected_saved_anim_index: int = -1
var _delete_anim_btn: Button
var _delete_confirm_dialog: ConfirmationDialog
var _refreshing_saved_list := false
var _loading_saved_entry := false

var _frame_strip_scroll: ScrollContainer
var _frame_strip: Control
var _strip_hover_rect: TextureRect
var _strip_hover_label: Label
var _last_strip_hover_frame: int = -1
var _last_strip_hover_row: int = -1
var _last_strip_hover_col: int = -1

var _preview_rect: TextureRect
var _preview_info: Label
var _preview_timer: Timer
var _preview_frames: PackedInt32Array = PackedInt32Array()
var _preview_index: int = 0
var _preview_playing := false

var _qa_review_list: ItemList
var _qa_detail_label: Label
var _qa_review_items: Array = []
var _qa_review_index: int = -1
var _unassigned_viewer: Window = null

var _sheet_texture: Texture2D
var _sheet_path: String = ""
var _frame_width: int = 200
var _frame_height: int = 200
var _columns: int = 50
var _rows: int = 50
var _total_frames: int = 2500

var _selected_direction: String = "toward"
var _selected_action: String = "walk"


const GRID_VIEWPORT_MIN := Vector2(720, 540)

func _init() -> void:
	title = "Manual Animation Mapping"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	size = Vector2i(1440, 920)
	min_size = Vector2i(1120, 720)
	close_requested.connect(_on_close_requested)


func _ready() -> void:
	_build_ui()
	_preview_timer = Timer.new()
	_preview_timer.wait_time = 0.1
	_preview_timer.timeout.connect(_on_preview_tick)
	add_child(_preview_timer)
	_delete_confirm_dialog = ConfirmationDialog.new()
	_delete_confirm_dialog.title = "Delete Animation"
	_delete_confirm_dialog.ok_button_text = "Delete"
	_delete_confirm_dialog.cancel_button_text = "Cancel"
	_delete_confirm_dialog.confirmed.connect(_on_delete_animation_confirmed)
	add_child(_delete_confirm_dialog)


func setup_from_dock(dock_node: Node) -> void:
	dock = dock_node
	if dock == null or not dock.has_method("get_large_review_state"):
		_set_status("Dock integration unavailable.")
		return
	var state: Dictionary = dock.call("get_large_review_state")
	_sheet_texture = state.get("sheet_texture", null)
	_sheet_path = String(state.get("sheet_path", ""))
	_frame_width = int(state.get("frame_width", 200))
	_frame_height = int(state.get("frame_height", 200))
	_columns = int(state.get("columns", 50))
	_rows = int(state.get("rows", 50))
	_total_frames = int(state.get("total_frames", _columns * _rows))
	if _sheet_texture == null:
		_set_status("Load a sheet in the Character Animation Mapper dock first.")
		return
	_grid.configure(_sheet_texture, _frame_width, _frame_height, _columns, _rows)
	_grid.require_ctrl_for_wheel_zoom = true
	_grid.double_click_focuses_frame = true
	_frame_strip.call("configure", _sheet_texture, _frame_width, _frame_height, _columns)
	_configure_frame_spin_limits()
	_configure_jump_spin_limits()
	call_deferred("_fit_initial_zoom")
	_apply_dock_fields_to_form(state)
	var initial_frames: PackedInt32Array = state.get("selection_frames", PackedInt32Array())
	if initial_frames.size() > 0:
		_grid.set_selected_frames(initial_frames)
		_present_selection(initial_frames)
	refresh_saved_animations_list()
	_refresh_qa_from_current_map()
	_set_status("Manual mapping ready. Select frames on the grid, name the clip, then Add / Update.")


func sync_selection_from_dock(frames: PackedInt32Array) -> void:
	if _grid == null:
		return
	_grid.set_selected_frames(frames)
	_present_selection(frames)


func _build_ui() -> void:
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_stylebox_override("panel", _light_panel_stylebox())
	add_child(shell)

	var root := HSplitContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.split_offset = 980
	shell.add_child(root)

	var grid_column := VBoxContainer.new()
	grid_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_column.size_flags_stretch_ratio = 4.0
	grid_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid_column)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.max_lines_visible = 2
	_status_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	grid_column.add_child(_status_label)
	_build_zoom_and_navigation_rows(grid_column)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = GRID_VIEWPORT_MIN
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_apply_light_panel_to_control(_scroll)
	grid_column.add_child(_scroll)
	_grid = GridCanvasScript.new()
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_scroll.add_child(_grid)
	_grid.selection_changed.connect(_on_grid_selection_changed)
	_grid.hover_changed.connect(_on_grid_hover_changed)

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_stretch_ratio = 1.0
	right_scroll.custom_minimum_size = Vector2(320, 0)
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_light_panel_to_control(right_scroll)
	root.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(300, 0)
	right_scroll.add_child(right)

	_build_saved_animations_list(right)
	_build_add_update_button(right)
	_build_structured_naming_ui(right)
	_build_animation_fields_form(right)
	_build_frame_range_controls(right)
	_build_selected_frame_strip_and_hover(right)
	_build_animation_preview(right)
	_build_mapping_qa_section(right)


func _build_zoom_and_navigation_rows(parent: Node) -> void:
	var zoom_row := HBoxContainer.new()
	parent.add_child(zoom_row)
	zoom_row.add_child(_make_label("Zoom %"))
	_zoom_spin = SpinBox.new()
	_zoom_spin.min_value = 2.0
	_zoom_spin.max_value = 1200.0
	_zoom_spin.step = 1.0
	_zoom_spin.value = 25.0
	_zoom_spin.custom_minimum_size = Vector2(72, 0)
	_zoom_spin.value_changed.connect(_on_zoom_spin_changed)
	zoom_row.add_child(_zoom_spin)
	for spec: Dictionary in [
		{"text": "Zoom Out", "fn": func() -> void: _adjust_zoom(1.0 / 1.15)},
		{"text": "Zoom In", "fn": func() -> void: _adjust_zoom(1.15)},
		{"text": "Fit", "fn": _on_fit_pressed},
		{"text": "100%", "fn": _on_100_pressed},
	]:
		var b := Button.new()
		b.text = spec.text
		b.pressed.connect(spec.fn)
		zoom_row.add_child(b)
	var preset_row := HBoxContainer.new()
	parent.add_child(preset_row)
	preset_row.add_child(_make_label("Presets"))
	for mult: float in [2.0, 4.0, 8.0, 12.0]:
		var label := "%dx" % int(mult)
		var pb := Button.new()
		pb.text = label
		pb.pressed.connect(_on_preset_zoom_pressed.bind(mult))
		preset_row.add_child(pb)
	var nav_row := HBoxContainer.new()
	parent.add_child(nav_row)
	nav_row.add_child(_make_label("Jump Frame"))
	_jump_frame_spin = SpinBox.new()
	_jump_frame_spin.rounded = true
	_jump_frame_spin.custom_minimum_size = Vector2(88, 0)
	nav_row.add_child(_jump_frame_spin)
	var jump_frame_btn := Button.new()
	jump_frame_btn.text = "Go"
	jump_frame_btn.pressed.connect(_on_jump_to_frame_pressed)
	nav_row.add_child(jump_frame_btn)
	nav_row.add_child(_make_label("Jump Row"))
	_jump_row_spin = SpinBox.new()
	_jump_row_spin.rounded = true
	_jump_row_spin.custom_minimum_size = Vector2(72, 0)
	nav_row.add_child(_jump_row_spin)
	var jump_row_btn := Button.new()
	jump_row_btn.text = "Go"
	jump_row_btn.pressed.connect(_on_jump_to_row_pressed)
	nav_row.add_child(jump_row_btn)
	var focus_btn := Button.new()
	focus_btn.text = "Focus Selection"
	focus_btn.pressed.connect(_on_focus_selection_pressed)
	nav_row.add_child(focus_btn)
	var mode_row := HBoxContainer.new()
	parent.add_child(mode_row)
	mode_row.add_child(_make_label("Selection mode"))
	_mode_option = OptionButton.new()
	_mode_option.add_item("Replace selection", 0)
	_mode_option.add_item("Add to selection", 1)
	_mode_option.add_item("Remove from selection", 2)
	_mode_option.item_selected.connect(_on_mode_changed)
	mode_row.add_child(_mode_option)
	var clear_btn := Button.new()
	clear_btn.text = "Clear Selection"
	clear_btn.pressed.connect(_on_clear_selection)
	mode_row.add_child(clear_btn)
	_selection_summary_label = Label.new()
	_selection_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_summary_label.text = "No frames selected."
	_selection_summary_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	parent.add_child(_selection_summary_label)
	_hover_label = Label.new()
	_hover_label.text = "Hover: —  |  Wheel pans, Ctrl+Wheel zooms, middle/right drag pans"
	_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hover_label.add_theme_color_override("font_color", Color(0.2, 0.35, 0.65))
	parent.add_child(_hover_label)


func _build_frame_range_controls(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Frame Range", true)
	var frame_row := HBoxContainer.new()
	body.add_child(frame_row)
	frame_row.add_child(_make_label("Start"))
	_start_frame_spin = SpinBox.new()
	_start_frame_spin.rounded = true
	_start_frame_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_frame_spin.value_changed.connect(_on_start_frame_spin_changed)
	frame_row.add_child(_start_frame_spin)
	frame_row.add_child(_make_label("End"))
	_end_frame_spin = SpinBox.new()
	_end_frame_spin.rounded = true
	_end_frame_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_frame_spin.value_changed.connect(_on_end_frame_spin_changed)
	frame_row.add_child(_end_frame_spin)


func _build_saved_animations_list(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Saved Animations", true)
	_saved_anim_list = ItemList.new()
	_saved_anim_list.custom_minimum_size = Vector2(0, 140)
	_saved_anim_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_saved_anim_list.allow_reselect = true
	_saved_anim_list.item_selected.connect(_on_saved_animation_selected)
	body.add_child(_saved_anim_list)
	_delete_anim_btn = Button.new()
	_delete_anim_btn.text = "Delete Selected Animation"
	_delete_anim_btn.visible = false
	_delete_anim_btn.disabled = true
	_delete_anim_btn.pressed.connect(_on_delete_selected_animation_pressed)
	body.add_child(_delete_anim_btn)
	var saved_hint := Label.new()
	saved_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	saved_hint.max_lines_visible = 2
	saved_hint.add_theme_font_size_override("font_size", 11)
	saved_hint.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	saved_hint.text = "Load an existing in-memory animation to edit its frames and fields."
	body.add_child(saved_hint)


func _build_selected_frame_strip_and_hover(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Selected Frame Strip", true)
	_frame_strip_scroll = ScrollContainer.new()
	_frame_strip_scroll.custom_minimum_size = Vector2(0, 56)
	_frame_strip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_frame_strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_frame_strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_frame_strip_scroll)
	_frame_strip = StripScript.new()
	_frame_strip_scroll.add_child(_frame_strip)
	_frame_strip.frame_clicked.connect(_on_strip_frame_clicked)
	_frame_strip.frame_hovered.connect(_on_strip_frame_hovered)
	_frame_strip.frame_hover_cleared.connect(_on_strip_frame_hover_cleared)
	body.add_child(_make_label("Strip hover zoom"))
	_strip_hover_rect = TextureRect.new()
	_strip_hover_rect.custom_minimum_size = Vector2(112, 112)
	_strip_hover_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_strip_hover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(_strip_hover_rect)
	_strip_hover_label = Label.new()
	_strip_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_strip_hover_label.max_lines_visible = 2
	_strip_hover_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_strip_hover_label.text = "Hover strip thumbnail."
	body.add_child(_strip_hover_label)


func _build_animation_preview(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Animation Preview", true)
	_preview_rect = TextureRect.new()
	_preview_rect.custom_minimum_size = Vector2(140, 140)
	_preview_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(_preview_rect)
	_preview_info = Label.new()
	_preview_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_info.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_preview_info.text = "Select frames, then Play Preview."
	body.add_child(_preview_info)
	var prev_row := HBoxContainer.new()
	body.add_child(prev_row)
	var play_btn := Button.new()
	play_btn.text = "Play Preview"
	play_btn.pressed.connect(_on_play_preview)
	prev_row.add_child(play_btn)
	var stop_btn := Button.new()
	stop_btn.text = "Stop Preview"
	stop_btn.pressed.connect(_on_stop_preview)
	prev_row.add_child(stop_btn)


func _build_mapping_qa_section(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Mapping QA / Review", false)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.max_lines_visible = 3
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	hint.text = "Visual review only. Does not save JSON or mutate animations."
	body.add_child(hint)
	var refresh_btn := Button.new()
	refresh_btn.text = "Refresh QA From Current Map"
	refresh_btn.pressed.connect(_refresh_qa_from_current_map)
	body.add_child(refresh_btn)
	_qa_review_list = ItemList.new()
	_qa_review_list.custom_minimum_size = Vector2(0, 120)
	_qa_review_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qa_review_list.item_selected.connect(_on_qa_review_item_selected)
	body.add_child(_qa_review_list)
	var nav_row := HBoxContainer.new()
	body.add_child(nav_row)
	var prev_btn := Button.new()
	prev_btn.text = "Previous Review Item"
	prev_btn.pressed.connect(_on_qa_previous_item)
	nav_row.add_child(prev_btn)
	var next_btn := Button.new()
	next_btn.text = "Next Review Item"
	next_btn.pressed.connect(_on_qa_next_item)
	nav_row.add_child(next_btn)
	var action_row := HBoxContainer.new()
	body.add_child(action_row)
	var focus_btn := Button.new()
	focus_btn.text = "Focus Review Item"
	focus_btn.pressed.connect(_on_qa_focus_item)
	action_row.add_child(focus_btn)
	var select_btn := Button.new()
	select_btn.text = "Select Review Frames"
	select_btn.pressed.connect(_on_qa_select_frames)
	action_row.add_child(select_btn)
	var unassigned_btn := Button.new()
	unassigned_btn.text = "Show Unassigned Frames"
	unassigned_btn.pressed.connect(_on_show_unassigned_frames)
	action_row.add_child(unassigned_btn)
	_qa_detail_label = Label.new()
	_qa_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_qa_detail_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_qa_detail_label.text = "Refresh QA to load suspicious groups, duplicate warnings, and unassigned ranges."
	body.add_child(_qa_detail_label)


func _refresh_qa_from_current_map() -> void:
	var animations := _get_animation_entries_from_dock()
	_qa_review_items = MAPPER_HELPERS.build_mapping_qa_review_items(animations, _columns, _total_frames)
	if _qa_review_list != null:
		_qa_review_list.clear()
		for item in _qa_review_items:
			if item is Dictionary:
				_qa_review_list.add_item(MAPPER_HELPERS.format_qa_item_list_label(item))
	_qa_review_index = -1
	if _qa_review_items.is_empty():
		if _qa_detail_label:
			_qa_detail_label.text = "No QA review items."
	else:
		_select_qa_review_index(0)
	if _unassigned_viewer != null and _unassigned_viewer.visible:
		_refresh_unassigned_viewer_ranges()


func _select_qa_review_index(index: int) -> void:
	if _qa_review_items.is_empty():
		_qa_review_index = -1
		return
	_qa_review_index = clampi(index, 0, _qa_review_items.size() - 1)
	if _qa_review_list != null:
		_qa_review_list.select(_qa_review_index)
	_on_qa_review_item_selected(_qa_review_index)


func _current_qa_item() -> Dictionary:
	if _qa_review_index < 0 or _qa_review_index >= _qa_review_items.size():
		return {}
	var raw = _qa_review_items[_qa_review_index]
	return raw if raw is Dictionary else {}


func _on_qa_review_item_selected(index: int) -> void:
	_qa_review_index = index
	if _qa_detail_label == null:
		return
	_qa_detail_label.text = MAPPER_HELPERS.format_qa_item_detail(_current_qa_item())


func _on_qa_previous_item() -> void:
	if _qa_review_items.is_empty():
		return
	var next_index := _qa_review_index - 1 if _qa_review_index >= 0 else _qa_review_items.size() - 1
	_select_qa_review_index(next_index)


func _on_qa_next_item() -> void:
	if _qa_review_items.is_empty():
		return
	var next_index := _qa_review_index + 1 if _qa_review_index >= 0 else 0
	_select_qa_review_index(next_index)


func _focus_qa_frames(select_frames: bool) -> void:
	var item := _current_qa_item()
	if item.is_empty() or _grid == null:
		return
	var frames := MAPPER_HELPERS.frames_from_qa_item(item)
	if frames.is_empty():
		return
	if select_frames:
		_grid.set_selected_frames(frames)
		_present_selection(frames)
	else:
		_grid.scroll_to_frame(frames[0], true)
	if _jump_frame_spin != null:
		_jump_frame_spin.set_value_no_signal(float(frames[0]))
	if _jump_row_spin != null:
		_jump_row_spin.set_value_no_signal(float(frames[0] / _columns))


func _on_qa_focus_item() -> void:
	_focus_qa_frames(false)


func _on_qa_select_frames() -> void:
	_focus_qa_frames(true)


func _ensure_unassigned_viewer() -> void:
	if _unassigned_viewer != null:
		return
	_unassigned_viewer = UNASSIGNED_VIEWER_SCRIPT.new()
	add_child(_unassigned_viewer)
	_unassigned_viewer.range_focus_requested.connect(_on_unassigned_range_focus_requested)


func _refresh_unassigned_viewer_ranges() -> void:
	if _unassigned_viewer == null:
		return
	var animations := _get_animation_entries_from_dock()
	var ranges := MAPPER_HELPERS.build_unassigned_frame_ranges(animations, _columns, _total_frames)
	_unassigned_viewer.configure_sheet(_sheet_texture, _frame_width, _frame_height, _columns)
	_unassigned_viewer.set_unassigned_ranges(ranges)


func _on_show_unassigned_frames() -> void:
	_ensure_unassigned_viewer()
	_refresh_unassigned_viewer_ranges()
	_unassigned_viewer.popup_centered()


func _on_unassigned_range_focus_requested(start_frame: int, end_frame: int, select_frames: bool) -> void:
	if _grid == null:
		return
	if select_frames:
		var frames := MAPPER_HELPERS.expand_contiguous_range(start_frame, end_frame)
		_grid.set_selected_frames(frames)
		_present_selection(frames)
		_grid.focus_selection()
	else:
		_grid.scroll_to_frame(start_frame, true)
	if _jump_frame_spin != null:
		_jump_frame_spin.set_value_no_signal(float(start_frame))
	if _jump_row_spin != null:
		_jump_row_spin.set_value_no_signal(float(start_frame / _columns))


func _build_animation_fields_form(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Animation Metadata", true)
	body.add_child(_make_label("Name"))
	_anim_name = LineEdit.new()
	_anim_name.placeholder_text = "Final animation name"
	body.add_child(_anim_name)
	var form := GridContainer.new()
	form.columns = 2
	body.add_child(form)
	form.add_child(_make_label("FPS"))
	_fps_spin = SpinBox.new()
	_fps_spin.min_value = 0.1
	_fps_spin.max_value = 120.0
	_fps_spin.step = 0.1
	_fps_spin.value = 10.0
	_fps_spin.value_changed.connect(_on_fps_spin_changed)
	form.add_child(_fps_spin)
	form.add_child(_make_label("Loop"))
	_loop_check = CheckBox.new()
	_loop_check.button_pressed = true
	form.add_child(_loop_check)
	form.add_child(_make_label("Review"))
	_review_option = OptionButton.new()
	_review_option.add_item("reviewed")
	_review_option.add_item("needs_review")
	_review_option.add_item("rejected")
	_review_option.select(1)
	form.add_child(_review_option)
	form.add_child(_make_label("Notes"))
	_notes_edit = LineEdit.new()
	form.add_child(_notes_edit)
	var fps_quick_row := FlowContainer.new()
	body.add_child(_make_label("FPS quick"))
	body.add_child(fps_quick_row)
	for fps: float in [6.0, 8.0, 10.0, 10.1, 12.0, 15.0, 24.0]:
		var fps_btn := Button.new()
		fps_btn.text = "10.1" if is_equal_approx(fps, 10.1) else str(int(fps) if fps == floor(fps) else fps)
		fps_btn.pressed.connect(_on_fps_quick_pressed.bind(fps))
		fps_quick_row.add_child(fps_btn)


func _build_add_update_button(parent: Node) -> void:
	var add_btn := Button.new()
	add_btn.text = "Add / Update Animation From Selection"
	add_btn.pressed.connect(_on_add_update_animation)
	parent.add_child(add_btn)
	var add_hint := Label.new()
	add_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_hint.max_lines_visible = 3
	add_hint.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	add_hint.add_theme_font_size_override("font_size", 11)
	add_hint.text = "Updates the dock animation list only — Save Reviewed Map JSON in the main dock to persist."
	parent.add_child(add_hint)


func _build_structured_naming_ui(parent: Node) -> void:
	var body := _begin_collapsible_section(parent, "Structured Naming Panel", true)
	_structured_name_label = Label.new()
	_structured_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_structured_name_label.text = "Auto-name: walk_toward_01"
	_structured_name_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	body.add_child(_structured_name_label)
	body.add_child(_make_label("Direction (one at a time)"))
	var dir_wrap := FlowContainer.new()
	body.add_child(dir_wrap)
	for dir: String in MAPPER_HELPERS.DIRECTIONS:
		var b := Button.new()
		b.text = dir
		b.toggle_mode = true
		b.pressed.connect(_on_direction_pressed.bind(dir, b))
		dir_wrap.add_child(b)
		_direction_buttons.append(b)
	if not _direction_buttons.is_empty():
		_direction_buttons[0].button_pressed = true
	body.add_child(_make_label("Action"))
	var act_wrap := FlowContainer.new()
	body.add_child(act_wrap)
	for action: String in MAPPER_HELPERS.ACTIONS:
		var b := Button.new()
		b.text = action
		b.toggle_mode = true
		b.pressed.connect(_on_action_pressed.bind(action, b))
		act_wrap.add_child(b)
		_action_buttons.append(b)
	for b in _action_buttons:
		if b.text == "walk":
			b.button_pressed = true
			break
	body.add_child(_make_label("Search common actions"))
	_action_search_edit = LineEdit.new()
	_action_search_edit.placeholder_text = "Filter land, idle, attack_light..."
	_action_search_edit.text_changed.connect(_on_action_search_text_changed)
	body.add_child(_action_search_edit)
	_action_pick_list = ItemList.new()
	_action_pick_list.custom_minimum_size = Vector2(0, 108)
	_action_pick_list.max_columns = 3
	_action_pick_list.fixed_column_width = 98
	_action_pick_list.same_column_width = true
	_action_pick_list.item_selected.connect(_on_common_action_selected)
	body.add_child(_action_pick_list)
	_refresh_action_pick_list("")
	var variant_row := HBoxContainer.new()
	body.add_child(variant_row)
	variant_row.add_child(_make_label("Variant"))
	_variant_spin = SpinBox.new()
	_variant_spin.min_value = 1
	_variant_spin.max_value = 99
	_variant_spin.value = 1
	_variant_spin.value_changed.connect(func(_v: float) -> void: _refresh_structured_name())
	variant_row.add_child(_variant_spin)
	variant_row.add_child(_make_label("Custom action stem"))
	_custom_action_edit = LineEdit.new()
	_custom_action_edit.placeholder_text = "used when action=custom"
	_custom_action_edit.text_changed.connect(func(_t: String) -> void: _refresh_structured_name())
	variant_row.add_child(_custom_action_edit)
	_refresh_structured_name()


func _configure_jump_spin_limits() -> void:
	if _jump_frame_spin == null or _jump_row_spin == null:
		return
	var max_g := maxi(0, _total_frames - 1)
	_jump_frame_spin.min_value = 0
	_jump_frame_spin.max_value = max_g
	_jump_row_spin.min_value = 0
	_jump_row_spin.max_value = maxi(0, _rows - 1)


func _light_panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.set_content_margin_all(8)
	return style


func _apply_light_panel_to_control(control: Control) -> void:
	if control is PanelContainer or control is ScrollContainer:
		control.add_theme_stylebox_override("panel", _light_panel_stylebox())


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	return l


func _make_heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	return l


func _begin_collapsible_section(parent: Node, title: String, expanded: bool = true) -> VBoxContainer:
	var sec := COLLAPSIBLE_SECTION_SCRIPT.new()
	sec.setup(title, expanded)
	parent.add_child(sec)
	return sec.get_content()


func _set_anim_name_text(text: String) -> void:
	if _anim_name == null:
		return
	_anim_name.text = text


func _refresh_action_pick_list(query: String) -> void:
	if _action_pick_list == null:
		return
	_action_pick_list.clear()
	for name: String in MAPPER_HELPERS.filter_common_animation_names(query, 100):
		_action_pick_list.add_item(name)


func _on_action_search_text_changed(new_text: String) -> void:
	_refresh_action_pick_list(new_text)


func _on_common_action_selected(index: int) -> void:
	if _action_pick_list == null or index < 0:
		return
	var stem := _action_pick_list.get_item_text(index)
	_apply_action_stem_from_picker(stem)


func _current_action_stem() -> String:
	if _selected_action == "custom":
		return _custom_action_edit.text.strip_edges()
	return _selected_action


func _apply_action_stem_from_picker(stem: String) -> void:
	var stem_l := stem.strip_edges()
	if stem_l.is_empty():
		return
	if stem_l in MAPPER_HELPERS.ACTIONS:
		_selected_action = stem_l
		for b in _action_buttons:
			b.button_pressed = b.text == stem_l
	else:
		_selected_action = "custom"
		for b in _action_buttons:
			b.button_pressed = b.text == "custom"
		_custom_action_edit.text = stem_l
	_apply_next_variant_for_current_stem()
	_refresh_structured_name()


func _apply_next_variant_for_current_stem() -> void:
	var stem := _current_action_stem()
	if stem.is_empty() or _selected_direction.is_empty():
		_variant_spin.set_value_no_signal(1.0)
		return
	var next_v: int = MAPPER_HELPERS.next_variant_for_action_direction(
		_get_animation_entries_from_dock(),
		stem,
		_selected_direction
	)
	_variant_spin.set_value_no_signal(float(next_v))


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func _refresh_structured_name() -> void:
	_update_auto_name_label()
	if _loading_saved_entry or _anim_name == null:
		return
	var name := MAPPER_HELPERS.build_structured_name(
		_selected_action,
		_selected_direction,
		int(_variant_spin.value),
		_custom_action_edit.text
	)
	_set_anim_name_text(name)


func _update_auto_name_label() -> void:
	var name := MAPPER_HELPERS.build_structured_name(
		_selected_action,
		_selected_direction,
		int(_variant_spin.value),
		_custom_action_edit.text
	)
	if _structured_name_label:
		_structured_name_label.text = "Auto-name: %s" % (name if not name.is_empty() else "(invalid)")


func refresh_saved_animations_list() -> void:
	if _saved_anim_list == null:
		return
	_refreshing_saved_list = true
	_selected_saved_anim_index = -1
	_update_delete_button_state()
	_saved_anim_list.clear()
	_saved_anim_entries.clear()
	for raw in _get_animation_entries_from_dock():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate(true)
		_saved_anim_entries.append(entry)
		_saved_anim_list.add_item(MAPPER_HELPERS.format_animation_list_label(entry))
	_refreshing_saved_list = false


func _get_animation_entries_from_dock() -> Array:
	if dock != null and dock.has_method("get_animation_entries_snapshot"):
		return dock.call("get_animation_entries_snapshot")
	return []


func _on_saved_animation_selected(index: int) -> void:
	if _refreshing_saved_list or index < 0 or index >= _saved_anim_entries.size():
		return
	_selected_saved_anim_index = index
	_update_delete_button_state()
	_load_animation_entry(_saved_anim_entries[index])


func _update_delete_button_state() -> void:
	if _delete_anim_btn == null:
		return
	var has_selection := _selected_saved_anim_index >= 0
	_delete_anim_btn.visible = has_selection
	_delete_anim_btn.disabled = not has_selection


func _on_delete_selected_animation_pressed() -> void:
	if _selected_saved_anim_index < 0 or _selected_saved_anim_index >= _saved_anim_entries.size():
		return
	if _delete_confirm_dialog == null:
		return
	var entry: Dictionary = _saved_anim_entries[_selected_saved_anim_index]
	var anim_name := String(entry.get("animation_name", ""))
	_delete_confirm_dialog.dialog_text = (
		("Delete animation '%s' from the current map?\n\n" % anim_name)
		+ "This will be written to JSON only after Save Reviewed Map JSON."
	)
	_delete_confirm_dialog.popup_centered()


func _on_delete_animation_confirmed() -> void:
	if dock == null or not dock.has_method("delete_animation_by_index"):
		_set_status("Dock delete API unavailable.")
		return
	if _selected_saved_anim_index < 0:
		_set_status("No saved animation selected to delete.")
		return
	var result: Variant = dock.call("delete_animation_by_index", _selected_saved_anim_index)
	if typeof(result) != TYPE_DICTIONARY:
		_set_status("Delete failed.")
		return
	var payload: Dictionary = result
	if not bool(payload.get("ok", false)):
		_set_status(String(payload.get("message", "Delete failed.")))
		return
	_clear_fields_after_delete()
	refresh_saved_animations_list()
	_refresh_qa_from_current_map()
	_set_status(String(payload.get("message", "Animation deleted from dock list.")))


func _clear_fields_after_delete() -> void:
	_selected_saved_anim_index = -1
	_update_delete_button_state()
	_on_stop_preview()
	if _grid:
		_grid.clear_selection()
	if _anim_name:
		_anim_name.text = ""
	if _notes_edit:
		_notes_edit.text = ""
	if _selection_summary_label:
		_selection_summary_label.text = "No frames selected."
	if _frame_strip:
		_frame_strip.call("set_frames", PackedInt32Array())
	if _preview_rect:
		_preview_rect.texture = null
	if _preview_info:
		_preview_info.text = "Select frames, then Play Preview."
	if _strip_hover_rect:
		_strip_hover_rect.texture = null
	if _strip_hover_label:
		_strip_hover_label.text = "Hover strip thumbnail."


func _load_animation_entry(entry: Dictionary) -> void:
	if entry.is_empty() or _grid == null:
		return
	_loading_saved_entry = true
	_on_stop_preview()
	var frames := MAPPER_HELPERS.frames_from_entry(entry)
	_grid.set_selected_frames(frames)
	_present_selection(frames)
	_grid.focus_selection()
	_set_anim_name_text(String(entry.get("animation_name", "")))
	_fps_spin.value = float(entry.get("fps", 10.0))
	_loop_check.button_pressed = bool(entry.get("loop", true))
	var status: String = String(entry.get("review_status", "needs_review"))
	for i: int in range(_review_option.item_count):
		if _review_option.get_item_text(i) == status:
			_review_option.select(i)
			break
	_notes_edit.text = String(entry.get("notes", ""))
	_apply_parsed_name_to_naming_controls(String(entry.get("animation_name", "")))
	_loading_saved_entry = false
	_update_auto_name_label()
	_set_status("Loaded '%s' from saved animations." % entry.get("animation_name", ""))


func _apply_parsed_name_to_naming_controls(animation_name: String) -> void:
	var parsed: Dictionary = MAPPER_HELPERS.parse_structured_animation_name(animation_name)
	if parsed.is_empty():
		return
	var action: String = String(parsed.get("action", ""))
	var direction: String = String(parsed.get("direction", ""))
	if not direction.is_empty():
		_selected_direction = direction
		for b in _direction_buttons:
			b.button_pressed = b.text == direction
	if not action.is_empty():
		_selected_action = action
		for b in _action_buttons:
			b.button_pressed = b.text == action
		if action == "custom":
			_custom_action_edit.text = String(parsed.get("custom_stem", parsed.get("action_stem", "")))
	_variant_spin.set_value_no_signal(float(int(parsed.get("variant", 1))))


func _on_fps_quick_pressed(fps: float) -> void:
	if _fps_spin == null:
		return
	_fps_spin.value = fps


func _on_fps_spin_changed(value: float) -> void:
	if _preview_playing and _preview_timer != null:
		_preview_timer.wait_time = 1.0 / maxf(0.1, value)


func _on_direction_pressed(direction: String, button: Button) -> void:
	_selected_direction = direction
	for b in _direction_buttons:
		b.button_pressed = b == button
	_apply_next_variant_for_current_stem()
	_refresh_structured_name()


func _on_action_pressed(action: String, button: Button) -> void:
	_selected_action = action
	for b in _action_buttons:
		b.button_pressed = b == button
	if action != "custom":
		var defaults: Dictionary = MAPPER_HELPERS.action_defaults(action)
		_fps_spin.value = float(defaults.get("fps", 10.0))
		_loop_check.button_pressed = bool(defaults.get("loop", true))
	_apply_next_variant_for_current_stem()
	_refresh_structured_name()


func _configure_frame_spin_limits() -> void:
	if _start_frame_spin == null or _end_frame_spin == null:
		return
	var max_g := maxi(0, _total_frames - 1)
	_start_frame_spin.min_value = 0
	_end_frame_spin.min_value = 0
	_start_frame_spin.max_value = max_g
	_end_frame_spin.max_value = max_g


func _sync_frame_spins_from_selection(frames: PackedInt32Array) -> void:
	if _start_frame_spin == null or _end_frame_spin == null:
		return
	_updating_frame_spins = true
	if frames.is_empty():
		_start_frame_spin.value = 0
		_end_frame_spin.value = 0
	else:
		var sorted := MAPPER_HELPERS.sorted_frames_array(frames)
		_start_frame_spin.value = sorted[0]
		_end_frame_spin.value = sorted[sorted.size() - 1]
	_updating_frame_spins = false


func _present_selection(frames: PackedInt32Array) -> void:
	_selection_summary_label.text = MAPPER_HELPERS.selection_summary(frames)
	_frame_strip.call("set_frames", frames)
	_sync_frame_spins_from_selection(frames)
	if frames.is_empty():
		_preview_info.text = "No frames selected for preview."
		_preview_rect.texture = null
	elif not _preview_playing:
		_show_preview_frame(frames[0])


func _apply_frame_range_from_spins(start_g: int, end_g: int, edited_start: bool) -> void:
	var clamped := MAPPER_HELPERS.clamp_contiguous_frame_range(start_g, end_g, _total_frames, edited_start)
	var start_v := clamped.x
	var end_v := clamped.y
	var frames := MAPPER_HELPERS.expand_contiguous_range(start_v, end_v)
	_grid.call("set_selected_frames", frames)
	_present_selection(frames)
	_set_status("Selection updated: frames %d..%d (%d)." % [start_v, end_v, frames.size()])


func _on_start_frame_spin_changed(value: float) -> void:
	if _updating_frame_spins:
		return
	_apply_frame_range_from_spins(int(value), int(_end_frame_spin.value), true)


func _on_end_frame_spin_changed(value: float) -> void:
	if _updating_frame_spins:
		return
	_apply_frame_range_from_spins(int(_start_frame_spin.value), int(value), false)


func _on_preset_zoom_pressed(multiplier: float) -> void:
	if _grid == null:
		return
	_grid.set_zoom_value(multiplier)
	_zoom_spin.value = float(_grid.get("zoom")) * 100.0


func _on_jump_to_frame_pressed() -> void:
	if _grid == null:
		return
	var frame_g := int(_jump_frame_spin.value)
	_grid.scroll_to_frame(frame_g, true)
	_set_status("Jumped to frame %d." % frame_g)


func _on_jump_to_row_pressed() -> void:
	if _grid == null:
		return
	var row := int(_jump_row_spin.value)
	_grid.scroll_to_row(row, true)
	_set_status("Jumped to row %d." % row)


func _on_focus_selection_pressed() -> void:
	if _grid == null:
		return
	var frames: PackedInt32Array = _grid.get_selected_frames()
	if frames.is_empty():
		_set_status("No selection to focus.")
		return
	_grid.focus_selection()
	_set_status("Focused viewport on selection (%d frames)." % frames.size())


func _on_grid_selection_changed(frames: PackedInt32Array) -> void:
	_present_selection(frames)
	if not frames.is_empty() and _jump_frame_spin != null:
		_jump_frame_spin.set_value_no_signal(float(frames[0]))


func _on_grid_hover_changed(frame_index: int, row: int, column: int) -> void:
	if frame_index < 0:
		_hover_label.text = "Hover: —  |  Wheel pans, Ctrl+Wheel zooms, middle/right drag pans"
	else:
		_hover_label.text = (
			"Hover: Frame %d | row %d | col %d  |  Wheel pans, Ctrl+Wheel zooms"
			% [frame_index, row, column]
		)
		if _jump_frame_spin != null:
			_jump_frame_spin.set_value_no_signal(float(frame_index))
		if _jump_row_spin != null:
			_jump_row_spin.set_value_no_signal(float(row))


func _on_strip_frame_hovered(global_index: int, row: int, column: int) -> void:
	_last_strip_hover_frame = global_index
	_last_strip_hover_row = row
	_last_strip_hover_col = column
	if _sheet_texture != null and _strip_hover_rect != null:
		_strip_hover_rect.texture = _atlas_for_frame(global_index)
	if _strip_hover_label:
		_strip_hover_label.text = "Hover: Frame %d | row %d | col %d" % [global_index, row, column]


func _on_strip_frame_hover_cleared() -> void:
	if _strip_hover_label:
		if _last_strip_hover_frame >= 0:
			_strip_hover_label.text = (
				"Last hovered: Frame %d | row %d | col %d"
				% [_last_strip_hover_frame, _last_strip_hover_row, _last_strip_hover_col]
			)
		else:
			_strip_hover_label.text = "Hover strip thumbnail."


func _on_strip_frame_clicked(global_index: int) -> void:
	_show_preview_frame(global_index)


func _apply_dock_fields_to_form(state: Dictionary) -> void:
	_set_anim_name_text(String(state.get("animation_name", "")))
	_fps_spin.value = float(state.get("fps", 10.0))
	_loop_check.button_pressed = bool(state.get("loop", true))
	var status: String = String(state.get("review_status", "needs_review"))
	for i: int in range(_review_option.item_count):
		if _review_option.get_item_text(i) == status:
			_review_option.select(i)
			break
	_notes_edit.text = String(state.get("notes", ""))


func _fit_initial_zoom() -> void:
	if _grid == null or _scroll == null:
		return
	_scroll.scroll_horizontal = 0
	_scroll.scroll_vertical = 0
	_grid.fit_zoom_to_viewport(_scroll.size)
	var readable_min := 0.22
	if float(_grid.get("zoom")) < readable_min:
		_grid.set_zoom_value(readable_min)
	if _zoom_spin:
		_zoom_spin.set_value_no_signal(float(_grid.get("zoom")) * 100.0)
	if _grid.get_selected_frames().size() > 0:
		call_deferred("_on_focus_selection_pressed")


func _on_zoom_spin_changed(value: float) -> void:
	if _grid:
		_grid.set_zoom_value(value / 100.0)


func _adjust_zoom(multiplier: float) -> void:
	if _grid:
		var z: float = float(_grid.get("zoom"))
		_grid.set_zoom_value(z * multiplier)
		_zoom_spin.value = float(_grid.get("zoom")) * 100.0


func _on_fit_pressed() -> void:
	if _grid and _scroll:
		_scroll.scroll_horizontal = 0
		_scroll.scroll_vertical = 0
		_grid.fit_zoom_to_viewport(_scroll.size)
		_zoom_spin.value = float(_grid.get("zoom")) * 100.0


func _on_100_pressed() -> void:
	if _grid:
		if _scroll:
			_scroll.scroll_horizontal = 0
			_scroll.scroll_vertical = 0
		_grid.set_zoom_value(1.0)
		_zoom_spin.value = 100.0


func _on_mode_changed(index: int) -> void:
	if _grid:
		_grid.set("selection_mode", index)


func _on_clear_selection() -> void:
	if _grid:
		_grid.clear_selection()


func _on_add_update_animation() -> void:
	if dock == null or not dock.has_method("upsert_animation_from_canvas"):
		_set_status("Dock upsert API unavailable.")
		return
	var frames: PackedInt32Array = _grid.call("get_selected_frames")
	if frames.is_empty():
		_set_status("Select frames before adding/updating animation.")
		return
	var entry: Dictionary = MAPPER_HELPERS.build_animation_entry(
		_anim_name.text.strip_edges(),
		frames,
		float(_fps_spin.value),
		_loop_check.button_pressed,
		_review_option.get_item_text(_review_option.selected),
		_notes_edit.text,
		_columns
	)
	if entry.is_empty():
		_set_status("Animation name required.")
		return
	dock.call("upsert_animation_from_canvas", entry)
	animation_updated.emit(entry)
	refresh_saved_animations_list()
	_refresh_qa_from_current_map()
	var map_path := MAPS_DIR
	if dock.has_method("get_map_output_path"):
		map_path = String(dock.call("get_map_output_path"))
	_set_status(
		"Updated animation '%s' in dock list only. Click Save Reviewed Map JSON in the main dock to write %s"
		% [entry.get("animation_name", ""), map_path]
	)


func _atlas_for_frame(global_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _sheet_texture
	var row: int = global_index / _columns
	var col: int = global_index % _columns
	atlas.region = Rect2(col * _frame_width, row * _frame_height, _frame_width, _frame_height)
	return atlas


func _show_preview_frame(global_index: int) -> void:
	if _sheet_texture == null:
		return
	var row: int = global_index / _columns
	var col: int = global_index % _columns
	if _preview_rect:
		_preview_rect.texture = _atlas_for_frame(global_index)
	if _preview_info:
		_preview_info.text = "Frame %d | row %d | col %d" % [global_index, row, col]


func _on_play_preview() -> void:
	_preview_frames = _grid.call("get_selected_frames") if _grid else PackedInt32Array()
	if _preview_frames.is_empty():
		_preview_info.text = "No frames selected for preview."
		return
	_preview_index = 0
	_preview_playing = true
	_preview_timer.wait_time = 1.0 / maxf(0.1, float(_fps_spin.value))
	_preview_timer.start()
	_show_preview_frame(_preview_frames[0])


func _on_stop_preview() -> void:
	_preview_playing = false
	_preview_timer.stop()


func _on_preview_tick() -> void:
	if not _preview_playing or _preview_frames.is_empty():
		return
	_preview_index += 1
	if _preview_index >= _preview_frames.size():
		if _loop_check.button_pressed:
			_preview_index = 0
		else:
			_preview_index = _preview_frames.size() - 1
			_preview_playing = false
			_preview_timer.stop()
	_preview_timer.wait_time = 1.0 / maxf(0.1, float(_fps_spin.value))
	_show_preview_frame(_preview_frames[_preview_index])


func _on_close_requested() -> void:
	_on_stop_preview()
	hide()
