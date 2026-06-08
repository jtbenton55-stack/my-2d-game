extends Window

const GridCanvasScript := preload("res://addons/character_animation_mapper/CharacterAnimationGridCanvas.gd")
const StripScript := preload("res://addons/character_animation_mapper/CharacterAnimationCandidateStrip.gd")
const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const CANDIDATE_DETECTOR := preload("res://addons/character_animation_mapper/CharacterAnimationCandidateDetector.gd")
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

var _candidate_index_label: Label
var _candidate_start_spin: SpinBox
var _candidate_end_spin: SpinBox
var _candidate_details_label: Label
var _updating_candidate_spins := false
var _candidate_map_path_label: Label
var _structured_name_label: Label
var _direction_preset_label: Label
var _variant_spin: SpinBox
var _custom_action_edit: LineEdit
var _candidate_strip_scroll: ScrollContainer
var _candidate_strip: Control
var _direction_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []

var _anim_name: LineEdit
var _fps_spin: SpinBox
var _loop_check: CheckBox
var _review_option: OptionButton
var _notes_edit: LineEdit
var _candidate_preview_rect: TextureRect
var _candidate_preview_info: Label
var _strip_hover_rect: TextureRect
var _strip_hover_label: Label
var _last_strip_hover_frame: int = -1
var _last_strip_hover_row: int = -1
var _last_strip_hover_col: int = -1
var _preview_timer: Timer

var _sheet_texture: Texture2D
var _sheet_path: String = ""
var _frame_width: int = 200
var _frame_height: int = 200
var _columns: int = 50
var _rows: int = 50
var _total_frames: int = 2500

var _candidates: Array[Dictionary] = []
var _candidate_index: int = -1
var _candidate_map_path: String = ""

var _left_split: VSplitContainer

var _selected_direction: String = "toward"
var _selected_action: String = "walk"

var _preview_frames: PackedInt32Array = PackedInt32Array()
var _preview_index: int = 0
var _preview_playing := false
var _preview_candidate_mode := false


func _init() -> void:
	title = "Large Review Canvas"
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	size = Vector2i(1400, 920)
	min_size = Vector2i(1100, 720)
	close_requested.connect(_on_close_requested)


func _ready() -> void:
	_build_ui()
	_preview_timer = Timer.new()
	_preview_timer.wait_time = 0.1
	_preview_timer.timeout.connect(_on_preview_tick)
	add_child(_preview_timer)


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
	_candidate_map_path = MAPPER_HELPERS.candidate_map_path_for_sheet(_sheet_path)
	_refresh_candidate_map_path_label()
	_grid.configure(_sheet_texture, _frame_width, _frame_height, _columns, _rows)
	_candidate_strip.call("configure", _sheet_texture, _frame_width, _frame_height, _columns)
	_configure_candidate_frame_spin_limits()
	call_deferred("_fit_initial_zoom")
	_apply_dock_fields_to_form(state)
	var initial_frames: PackedInt32Array = state.get("selection_frames", PackedInt32Array())
	if initial_frames.size() > 0:
		_grid.set_selected_frames(initial_frames)
	_set_status("Large Review Canvas ready. Use Candidate Review Queue to accelerate mapping.")


func _build_ui() -> void:
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_stylebox_override("panel", _light_panel_stylebox())
	add_child(shell)

	var root := HSplitContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_child(root)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.6
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(left)
	_apply_light_panel_to_control(left)

	_left_split = VSplitContainer.new()
	_left_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_left_split)

	var left_controls_scroll := ScrollContainer.new()
	left_controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_controls_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_apply_light_panel_to_control(left_controls_scroll)
	_left_split.add_child(left_controls_scroll)

	var left_controls := VBoxContainer.new()
	left_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_controls.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_controls_scroll.add_child(left_controls)

	_build_left_candidate_preview(left_controls)
	_build_candidate_queue_ui(left_controls)
	_build_left_candidate_strip_and_hover(left_controls)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_status_label.add_theme_font_size_override("font_size", 12)
	left_controls.add_child(_status_label)
	_build_zoom_and_selection_rows(left_controls)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_apply_light_panel_to_control(_scroll)
	_left_split.add_child(_scroll)
	_left_split.split_offset = 400
	_grid = GridCanvasScript.new()
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_scroll.add_child(_grid)
	_grid.selection_changed.connect(_on_grid_selection_changed)
	_grid.hover_changed.connect(_on_grid_hover_changed)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	right.custom_minimum_size = Vector2(320, 0)
	root.add_child(right)
	_apply_light_panel_to_control(right)

	_build_structured_naming_ui(right)
	_build_animation_fields_and_add_button(right)
	_build_optional_direction_helper(right)


func _build_zoom_and_selection_rows(parent: Node) -> void:
	var zoom_row := HBoxContainer.new()
	parent.add_child(zoom_row)
	zoom_row.add_child(_make_label("Zoom"))
	_zoom_spin = SpinBox.new()
	_zoom_spin.min_value = 2.0
	_zoom_spin.max_value = 400.0
	_zoom_spin.step = 1.0
	_zoom_spin.value = 12.0
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
	var mode_row := HBoxContainer.new()
	parent.add_child(mode_row)
	var mode_label := _make_label("Selection mode")
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_row.add_child(mode_label)
	_mode_option = OptionButton.new()
	_mode_option.add_item("Replace selection", 0)
	_mode_option.add_item("Add to selection", 1)
	_mode_option.add_item("Remove from selection", 2)
	_mode_option.item_selected.connect(_on_mode_changed)
	mode_row.add_child(_mode_option)
	var clear_row := HBoxContainer.new()
	parent.add_child(clear_row)
	var clear_btn := Button.new()
	clear_btn.text = "Clear Selection"
	clear_btn.pressed.connect(_on_clear_selection)
	clear_row.add_child(clear_btn)
	var sel_btns := HBoxContainer.new()
	parent.add_child(sel_btns)
	var dock_sel_btn := Button.new()
	dock_sel_btn.text = "Select Current Dock Range"
	dock_sel_btn.pressed.connect(_on_select_dock_range)
	sel_btns.add_child(dock_sel_btn)
	var apply_btn := Button.new()
	apply_btn.text = "Apply Selection To Dock"
	apply_btn.pressed.connect(_on_apply_to_dock)
	sel_btns.add_child(apply_btn)
	var status_row := HBoxContainer.new()
	parent.add_child(status_row)
	_selection_summary_label = Label.new()
	_selection_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_summary_label.text = "No frames selected."
	_selection_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_summary_label.add_theme_font_size_override("font_size", 12)
	_selection_summary_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	status_row.add_child(_selection_summary_label)
	_hover_label = Label.new()
	_hover_label.text = "Hover: —"
	_hover_label.add_theme_font_size_override("font_size", 12)
	_hover_label.add_theme_color_override("font_color", Color(0.2, 0.35, 0.65))
	status_row.add_child(_hover_label)


func _light_panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.set_content_margin_all(8)
	return style


func _apply_light_panel_to_control(control: Control) -> void:
	if control is PanelContainer or control is ScrollContainer:
		control.add_theme_stylebox_override("panel", _light_panel_stylebox())


func _build_candidate_queue_ui(parent: Node) -> void:
	parent.add_child(_make_heading("Candidate Review Queue"))
	_candidate_map_path_label = Label.new()
	_candidate_map_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_candidate_map_path_label.max_lines_visible = 2
	_candidate_map_path_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_candidate_map_path_label.add_theme_font_size_override("font_size", 12)
	parent.add_child(_candidate_map_path_label)
	var map_row := HBoxContainer.new()
	parent.add_child(map_row)
	_add_compact_button(map_row, "Detect Candidate Ranges", _on_detect_candidates)
	_add_compact_button(map_row, "Load Candidate Map", _on_load_candidate_map)
	_add_compact_button(map_row, "Save Candidate Map", _on_save_candidate_map)
	var nav_row := HBoxContainer.new()
	parent.add_child(nav_row)
	_add_compact_button(nav_row, "Previous Candidate", func() -> void: _navigate_candidate(-1))
	_add_compact_button(nav_row, "Next Candidate", func() -> void: _navigate_candidate(1))
	_add_compact_button(nav_row, "Preview Candidate", _on_preview_candidate)
	var review_row := HBoxContainer.new()
	parent.add_child(review_row)
	_add_compact_button(review_row, "Approve As Reviewed", _on_approve_candidate)
	_add_compact_button(review_row, "Reject Candidate", _on_reject_candidate)
	var action_row := HBoxContainer.new()
	parent.add_child(action_row)
	_add_compact_button(action_row, "Update Candidate Label", _on_update_candidate_label)
	_add_compact_button(action_row, "Apply Candidate To Canvas Selection", _on_apply_candidate_to_canvas)
	_candidate_index_label = Label.new()
	_candidate_index_label.add_theme_font_size_override("font_size", 12)
	_candidate_index_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_candidate_index_label.text = "Candidate — / —"
	parent.add_child(_candidate_index_label)
	var frame_range_row := HBoxContainer.new()
	parent.add_child(frame_range_row)
	var start_lbl := _make_label("Candidate Start Frame")
	start_lbl.add_theme_font_size_override("font_size", 12)
	frame_range_row.add_child(start_lbl)
	_candidate_start_spin = SpinBox.new()
	_candidate_start_spin.min_value = 0
	_candidate_start_spin.max_value = 2499
	_candidate_start_spin.step = 1
	_candidate_start_spin.rounded = true
	_candidate_start_spin.allow_greater = false
	_candidate_start_spin.allow_lesser = false
	_candidate_start_spin.value_changed.connect(_on_candidate_start_spin_changed)
	_candidate_start_spin.editable = false
	frame_range_row.add_child(_candidate_start_spin)
	var end_lbl := _make_label("Candidate End Frame")
	end_lbl.add_theme_font_size_override("font_size", 12)
	frame_range_row.add_child(end_lbl)
	_candidate_end_spin = SpinBox.new()
	_candidate_end_spin.min_value = 0
	_candidate_end_spin.max_value = 2499
	_candidate_end_spin.step = 1
	_candidate_end_spin.rounded = true
	_candidate_end_spin.allow_greater = false
	_candidate_end_spin.allow_lesser = false
	_candidate_end_spin.value_changed.connect(_on_candidate_end_spin_changed)
	_candidate_end_spin.editable = false
	frame_range_row.add_child(_candidate_end_spin)
	_candidate_details_label = Label.new()
	_candidate_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_candidate_details_label.max_lines_visible = 2
	_candidate_details_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_candidate_details_label.add_theme_font_size_override("font_size", 12)
	_candidate_details_label.text = "No candidate loaded."
	parent.add_child(_candidate_details_label)


func _build_left_candidate_strip_and_hover(parent: Node) -> void:
	var strip_hover_row := HBoxContainer.new()
	strip_hover_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(strip_hover_row)
	var strip_col := VBoxContainer.new()
	strip_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_col.size_flags_stretch_ratio = 1.4
	strip_hover_row.add_child(strip_col)
	strip_col.add_child(_make_label("Candidate strip"))
	_candidate_strip_scroll = ScrollContainer.new()
	_candidate_strip_scroll.custom_minimum_size = Vector2(0, 64)
	_candidate_strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_candidate_strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_col.add_child(_candidate_strip_scroll)
	_candidate_strip = StripScript.new()
	_candidate_strip_scroll.add_child(_candidate_strip)
	_candidate_strip.frame_clicked.connect(_on_strip_frame_clicked)
	_candidate_strip.frame_hovered.connect(_on_strip_frame_hovered)
	_candidate_strip.frame_hover_cleared.connect(_on_strip_frame_hover_cleared)
	var hover_col := VBoxContainer.new()
	hover_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	strip_hover_row.add_child(hover_col)
	hover_col.add_child(_make_label("Strip hover zoom"))
	_strip_hover_rect = TextureRect.new()
	_strip_hover_rect.custom_minimum_size = Vector2(126, 126)
	_strip_hover_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_strip_hover_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hover_col.add_child(_strip_hover_rect)
	_strip_hover_label = Label.new()
	_strip_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_strip_hover_label.max_lines_visible = 2
	_strip_hover_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_strip_hover_label.add_theme_font_size_override("font_size", 11)
	_strip_hover_label.text = "Hover strip thumbnail."
	hover_col.add_child(_strip_hover_label)


func _add_compact_button(parent: Node, label_text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _build_structured_naming_ui(parent: Node) -> void:
	parent.add_child(_make_heading("Structured Naming Panel"))
	_structured_name_label = Label.new()
	_structured_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_structured_name_label.text = "Auto-name: walk_toward_01"
	_structured_name_label.add_theme_font_size_override("font_size", 14)
	_structured_name_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	parent.add_child(_structured_name_label)
	parent.add_child(_make_label("Direction (one at a time)"))
	var dir_wrap := FlowContainer.new()
	parent.add_child(dir_wrap)
	for i: int in range(MAPPER_HELPERS.DIRECTIONS.size()):
		var dir: String = MAPPER_HELPERS.DIRECTIONS[i]
		var b := Button.new()
		b.text = dir
		b.toggle_mode = true
		b.pressed.connect(_on_direction_pressed.bind(dir, b))
		dir_wrap.add_child(b)
		_direction_buttons.append(b)
	if not _direction_buttons.is_empty():
		_direction_buttons[0].button_pressed = true
	parent.add_child(_make_label("Action"))
	var act_wrap := FlowContainer.new()
	parent.add_child(act_wrap)
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
	var variant_row := HBoxContainer.new()
	parent.add_child(variant_row)
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


func _build_left_candidate_preview(parent: Node) -> void:
	parent.add_child(_make_heading("Candidate Preview"))
	_candidate_preview_rect = TextureRect.new()
	_candidate_preview_rect.custom_minimum_size = Vector2(180, 180)
	_candidate_preview_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_candidate_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(_candidate_preview_rect)
	_candidate_preview_info = Label.new()
	_candidate_preview_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_candidate_preview_info.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_candidate_preview_info.text = "Select frames or click Preview Candidate to animate here."
	parent.add_child(_candidate_preview_info)
	var prev_row := HBoxContainer.new()
	parent.add_child(prev_row)
	var play_btn := Button.new()
	play_btn.text = "Play Preview"
	play_btn.pressed.connect(_on_play_preview)
	prev_row.add_child(play_btn)
	var stop_btn := Button.new()
	stop_btn.text = "Stop Preview"
	stop_btn.pressed.connect(_on_stop_preview)
	prev_row.add_child(stop_btn)


func _build_animation_fields_and_add_button(parent: Node) -> void:
	var form := GridContainer.new()
	form.columns = 2
	parent.add_child(form)
	form.add_child(_make_label("Name"))
	_anim_name = LineEdit.new()
	form.add_child(_anim_name)
	form.add_child(_make_label("FPS"))
	_fps_spin = SpinBox.new()
	_fps_spin.min_value = 0.1
	_fps_spin.max_value = 120.0
	_fps_spin.step = 0.5
	_fps_spin.value = 10.0
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
	var add_btn := Button.new()
	add_btn.text = "Add / Update Animation From Selection"
	add_btn.pressed.connect(_on_add_update_animation)
	parent.add_child(add_btn)
	var add_hint := Label.new()
	add_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_hint.max_lines_visible = 2
	add_hint.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	add_hint.add_theme_font_size_override("font_size", 11)
	add_hint.text = "Dock list only — Save Reviewed Map JSON in main dock to persist."
	parent.add_child(add_hint)


func _build_optional_direction_helper(parent: Node) -> void:
	parent.add_child(_make_heading("Optional Direction Pattern Helper"))
	var helper := Label.new()
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	helper.text = (
		"Optional helper: uses the current action/direction naming to create 8 directional needs_review "
		+ "placeholder candidates with empty frames. It does not mark anything reviewed — map frames manually."
	)
	parent.add_child(helper)
	_direction_preset_label = Label.new()
	_direction_preset_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_direction_preset_label.add_theme_color_override("font_color", PANEL_TEXT_COLOR)
	_direction_preset_label.text = MAPPER_HELPERS.PVGAMES_8DIR_ORDER
	parent.add_child(_direction_preset_label)
	var suggest_btn := Button.new()
	suggest_btn.text = "Suggest 8 Direction Candidates"
	suggest_btn.pressed.connect(_on_suggest_8dir_patterns)
	parent.add_child(suggest_btn)


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


func _set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func _refresh_candidate_map_path_label() -> void:
	if _candidate_map_path_label:
		var short_path := _candidate_map_path.get_file()
		if short_path.is_empty():
			short_path = _candidate_map_path
		_candidate_map_path_label.text = "Map: %s" % short_path
		_candidate_map_path_label.tooltip_text = _candidate_map_path


func _refresh_structured_name() -> void:
	var name := MAPPER_HELPERS.build_structured_name(
		_selected_action,
		_selected_direction,
		int(_variant_spin.value),
		_custom_action_edit.text
	)
	if _structured_name_label:
		_structured_name_label.text = "Auto-name: %s" % (name if not name.is_empty() else "(invalid)")
	_anim_name.text = name


func _on_direction_pressed(direction: String, button: Button) -> void:
	_selected_direction = direction
	for b in _direction_buttons:
		b.button_pressed = b == button
	_refresh_structured_name()


func _on_action_pressed(action: String, button: Button) -> void:
	_selected_action = action
	for b in _action_buttons:
		b.button_pressed = b == button
	var defaults: Dictionary = MAPPER_HELPERS.action_defaults(action)
	if action != "custom":
		_fps_spin.value = float(defaults.get("fps", 10.0))
		_loop_check.button_pressed = bool(defaults.get("loop", true))
	_refresh_structured_name()


func _current_structured_name() -> String:
	return MAPPER_HELPERS.build_structured_name(
		_selected_action,
		_selected_direction,
		int(_variant_spin.value),
		_custom_action_edit.text
	)


func _on_detect_candidates() -> void:
	if dock == null or _sheet_texture == null:
		_set_status("Load a sheet in the dock first.")
		return
	var img: Image = dock.call("get_sheet_image_for_detection")
	if img == null or img.is_empty():
		_set_status("Sheet image unavailable for detection.")
		return
	_set_status("Detecting candidate ranges…")
	var raw: Array = CANDIDATE_DETECTOR.detect_from_image(img, _frame_width, _frame_height, _columns, _rows)
	_candidates.clear()
	for entry in MAPPER_HELPERS.finalize_candidate_entries(raw, _columns):
		if entry is Dictionary:
			_candidates.append(entry)
	_candidate_index = 0 if not _candidates.is_empty() else -1
	_candidate_map_path = MAPPER_HELPERS.candidate_map_path_for_sheet(_sheet_path)
	_refresh_candidate_map_path_label()
	if _candidates.is_empty():
		_set_status("Detection found no candidate ranges.")
		_refresh_candidate_labels()
		return
	_load_candidate_at(_candidate_index)
	_set_status("Detected %d candidate ranges (all needs_review). Save Candidate Map to persist." % _candidates.size())


func _on_load_candidate_map() -> void:
	var path := _candidate_map_path
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		_set_status("Candidate map not found: %s" % path)
		return
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if file == null:
		_set_status("Failed to read candidate map.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		_set_status("Invalid candidate map JSON.")
		return
	var data: Dictionary = parsed
	_candidates.clear()
	for a in data.get("animations", []):
		if a is Dictionary:
			var copy: Dictionary = a.duplicate(true)
			if String(copy.get("review_status", "")) == "reviewed":
				copy["review_status"] = "needs_review"
			_candidates.append(copy)
	_candidate_index = 0 if not _candidates.is_empty() else -1
	if _candidates.is_empty():
		_set_status("Candidate map loaded but empty.")
		_refresh_candidate_labels()
		return
	_load_candidate_at(_candidate_index)
	_set_status("Loaded %d candidates from %s" % [_candidates.size(), path])


func _on_save_candidate_map() -> void:
	if _candidates.is_empty():
		_set_status("Detect or load candidates before saving.")
		return
	for e in _candidates:
		if String(e.get("review_status", "")) == "reviewed":
			_set_status("Refusing save: candidates must not be reviewed in candidate map.")
			return
	var path := _candidate_map_path
	if not path.begins_with(MAPS_DIR):
		_set_status("Refusing unsafe candidate path.")
		return
	var data := MAPPER_HELPERS.build_candidate_map_dict(
		_sheet_path, _frame_width, _frame_height, _columns, _rows, _candidates
	)
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		_set_status("Failed to write candidate map.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_set_status("Saved candidate map: %s (%d candidates)" % [path, _candidates.size()])


func _navigate_candidate(delta: int) -> void:
	if _candidates.is_empty():
		_set_status("No candidates in queue.")
		return
	var count := _candidates.size()
	_candidate_index = (_candidate_index + delta + count) % count
	_load_candidate_at(_candidate_index)


func _load_candidate_at(index: int) -> void:
	if index < 0 or index >= _candidates.size():
		_set_candidate_frame_spins_enabled(false)
		_refresh_candidate_labels()
		return
	_candidate_index = index
	_present_candidate_entry(_candidates[index])


func _configure_candidate_frame_spin_limits() -> void:
	if _candidate_start_spin == null or _candidate_end_spin == null:
		return
	var max_g := maxi(0, _total_frames - 1)
	_candidate_start_spin.min_value = 0
	_candidate_end_spin.min_value = 0
	_candidate_start_spin.max_value = max_g
	_candidate_end_spin.max_value = max_g


func _set_candidate_frame_spins_enabled(enabled: bool) -> void:
	if _candidate_start_spin:
		_candidate_start_spin.editable = enabled
	if _candidate_end_spin:
		_candidate_end_spin.editable = enabled


func _sync_candidate_frame_spins(entry: Dictionary) -> void:
	if _candidate_start_spin == null or _candidate_end_spin == null:
		return
	_updating_candidate_spins = true
	_candidate_start_spin.value = int(entry.get("start_frame", 0))
	_candidate_end_spin.value = int(entry.get("end_frame", entry.get("start_frame", 0)))
	_updating_candidate_spins = false


func _present_candidate_entry(entry: Dictionary) -> void:
	var frames := MAPPER_HELPERS.frames_from_entry(entry)
	_grid.call("set_selected_frames", frames)
	_candidate_strip.call("set_frames", frames)
	_selection_summary_label.text = MAPPER_HELPERS.selection_summary(frames)
	_fps_spin.value = float(entry.get("fps", 10.0))
	_loop_check.button_pressed = bool(entry.get("loop", true))
	_notes_edit.text = String(entry.get("notes", ""))
	_set_candidate_frame_spins_enabled(true)
	_sync_candidate_frame_spins(entry)
	_refresh_candidate_labels()
	if frames.size() > 0:
		_show_preview_frame(frames[0])
	else:
		_candidate_preview_rect.texture = null
		_candidate_preview_info.text = "Candidate has no frames."


func _on_candidate_start_spin_changed(value: float) -> void:
	if _updating_candidate_spins:
		return
	_apply_candidate_frame_range_edit(int(value), int(_candidate_end_spin.value), true)


func _on_candidate_end_spin_changed(value: float) -> void:
	if _updating_candidate_spins:
		return
	_apply_candidate_frame_range_edit(int(_candidate_start_spin.value), int(value), false)


func _apply_candidate_frame_range_edit(start_g: int, end_g: int, edited_start: bool) -> void:
	if _candidate_index < 0 or _candidate_index >= _candidates.size():
		return
	var entry: Dictionary = _candidates[_candidate_index]
	var updated := MAPPER_HELPERS.update_candidate_contiguous_range(
		entry, start_g, end_g, _columns, _total_frames, edited_start
	)
	if updated.is_empty():
		_set_status("Could not update candidate frame range.")
		return
	_candidates[_candidate_index] = updated
	_present_candidate_entry(updated)
	_set_status(
		"Candidate range updated: frames %d..%d (%d). Save Candidate Map to persist."
		% [updated.get("start_frame", 0), updated.get("end_frame", 0), int((updated.get("frames", []) as Array).size())]
	)


func _refresh_candidate_labels() -> void:
	if _candidate_index_label:
		if _candidates.is_empty():
			_candidate_index_label.text = "Candidate — / —"
		else:
			_candidate_index_label.text = "Candidate %d / %d" % [_candidate_index + 1, _candidates.size()]
	if _candidate_index < 0 or _candidate_index >= _candidates.size():
		_set_candidate_frame_spins_enabled(false)
	if _candidate_details_label:
		if _candidate_index < 0 or _candidate_index >= _candidates.size():
			_candidate_details_label.text = "No candidate loaded."
		else:
			_candidate_details_label.text = MAPPER_HELPERS.candidate_detail_text(_candidates[_candidate_index], _columns)


func _current_candidate() -> Dictionary:
	if _candidate_index < 0 or _candidate_index >= _candidates.size():
		return {}
	return _candidates[_candidate_index]


func _on_preview_candidate() -> void:
	var entry := _current_candidate()
	if entry.is_empty():
		_set_status("Select a candidate first.")
		return
	_preview_frames = MAPPER_HELPERS.frames_from_entry(entry)
	if _preview_frames.is_empty():
		_set_status("Candidate has no frames.")
		return
	_preview_candidate_mode = true
	_preview_index = 0
	_preview_playing = true
	_fps_spin.value = float(entry.get("fps", 10.0))
	_loop_check.button_pressed = bool(entry.get("loop", true))
	_preview_timer.wait_time = 1.0 / maxf(0.1, float(entry.get("fps", 10.0)))
	_preview_timer.start()
	_show_preview_frame(_preview_frames[0])
	_set_status("Previewing candidate %d (%d frames)." % [_candidate_index + 1, _preview_frames.size()])


func _on_approve_candidate() -> void:
	var entry := _current_candidate()
	if entry.is_empty():
		_set_status("Select a candidate first.")
		return
	var final_name := _current_structured_name()
	if final_name.is_empty():
		_set_status("Structured name invalid. Set action, direction, and variant.")
		return
	if dock != null and dock.has_method("get_reviewed_animation_names"):
		var names: Array = dock.call("get_reviewed_animation_names")
		if final_name in names:
			_set_status("%s already exists. Approving will replace it in the reviewed list." % final_name)
	var frames := MAPPER_HELPERS.frames_from_entry(entry)
	var notes := String(entry.get("notes", ""))
	if not notes.contains("approved_from="):
		notes = "%s; approved_from=%s" % [notes, entry.get("animation_name", "")]
	var reviewed_entry := MAPPER_HELPERS.build_animation_entry(
		final_name,
		frames,
		float(_fps_spin.value),
		_loop_check.button_pressed,
		"reviewed",
		notes,
		_columns
	)
	if dock == null or not dock.has_method("approve_reviewed_animation"):
		_set_status("Dock approve API unavailable.")
		return
	var result: Dictionary = dock.call("approve_reviewed_animation", reviewed_entry)
	_set_status(String(result.get("message", "Approve failed.")))
	if bool(result.get("ok", false)):
		entry["review_status"] = "rejected"
		entry["notes"] = notes + "; rejected_reason=approved_elsewhere"
		_candidates[_candidate_index] = entry
		animation_updated.emit(reviewed_entry)
		_refresh_candidate_labels()
		var map_path := String(dock.call("get_map_output_path")) if dock.has_method("get_map_output_path") else MAPS_DIR
		_set_status(
			"%s Save Reviewed Map JSON in the main dock to write %s"
			% [String(result.get("message", "")), map_path]
		)


func _on_reject_candidate() -> void:
	var entry := _current_candidate()
	if entry.is_empty():
		_set_status("Select a candidate first.")
		return
	entry["review_status"] = "rejected"
	var notes := String(entry.get("notes", ""))
	if not notes.contains("rejected_by=user"):
		entry["notes"] = "%s; rejected_by=user" % notes
	_candidates[_candidate_index] = entry
	_refresh_candidate_labels()
	_set_status("Rejected candidate %d (kept in candidate map for traceability)." % (_candidate_index + 1))


func _on_update_candidate_label() -> void:
	var entry := _current_candidate()
	if entry.is_empty():
		_set_status("Select a candidate first.")
		return
	var frames := MAPPER_HELPERS.frames_from_entry(entry)
	var updated := MAPPER_HELPERS.build_animation_entry(
		String(entry.get("animation_name", "candidate_001")),
		frames,
		float(_fps_spin.value),
		_loop_check.button_pressed,
		String(entry.get("review_status", "needs_review")),
		_notes_edit.text,
		_columns
	)
	_candidates[_candidate_index] = updated
	_refresh_candidate_labels()
	_set_status("Updated candidate label/metadata in queue (not reviewed).")


func _on_apply_candidate_to_canvas() -> void:
	var entry := _current_candidate()
	if entry.is_empty():
		_set_status("Select a candidate first.")
		return
	var frames := MAPPER_HELPERS.frames_from_entry(entry)
	_grid.call("set_selected_frames", frames)
	if dock != null and dock.has_method("apply_canvas_selection_to_dock"):
		dock.call("apply_canvas_selection_to_dock", frames)
	_set_status("Applied candidate frames to canvas and dock fields.")


func _on_suggest_8dir_patterns() -> void:
	var base_notes := "detected_by=direction_pattern_assist; reason=needs_review_suggestion; not_auto_reviewed"
	var added := 0
	for dir: String in MAPPER_HELPERS.DIRECTIONS:
		var name := "candidate_%s_%s" % [_selected_action, dir]
		var entry := MAPPER_HELPERS.build_animation_entry(
			name,
			PackedInt32Array([0]),
			float(MAPPER_HELPERS.action_defaults(_selected_action).get("fps", 10.0)),
			bool(MAPPER_HELPERS.action_defaults(_selected_action).get("loop", true)),
			"needs_review",
			"%s; direction=%s" % [base_notes, dir],
			_columns
		)
		entry["start_frame"] = 0
		entry["end_frame"] = 0
		entry["frames"] = []
		_candidates.append(entry)
		added += 1
	_candidate_index = _candidates.size() - added
	_load_candidate_at(_candidate_index)
	_set_status(
		"Added %d needs_review direction placeholders (empty frames). Map manually; nothing was auto-reviewed."
		% added
	)


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
			_strip_hover_label.text = "Hover a strip thumbnail to inspect enlarged."


func _on_strip_frame_clicked(global_index: int) -> void:
	_show_preview_frame(global_index)
	_hover_label.text = "Strip click: Frame %d" % global_index


func _unhandled_input(event: InputEvent) -> void:
	if _is_text_field_focused():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		match key.keycode:
			KEY_SPACE:
				if _preview_playing:
					_on_stop_preview()
				elif _preview_candidate_mode:
					_on_preview_candidate()
				else:
					_on_play_preview()
				get_viewport().set_input_as_handled()
			KEY_N:
				_navigate_candidate(1)
				get_viewport().set_input_as_handled()
			KEY_P:
				_navigate_candidate(-1)
				get_viewport().set_input_as_handled()
			KEY_A:
				_on_approve_candidate()
				get_viewport().set_input_as_handled()
			KEY_R:
				_on_reject_candidate()
				get_viewport().set_input_as_handled()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
				var idx := int(key.keycode - KEY_1)
				if idx >= 0 and idx < _direction_buttons.size():
					_direction_buttons[idx].emit_signal("pressed")
				get_viewport().set_input_as_handled()


func _is_text_field_focused() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null:
		return false
	return focus is LineEdit or focus is SpinBox or focus is TextEdit


func _fit_initial_zoom() -> void:
	if _grid == null or _scroll == null:
		return
	_scroll.scroll_horizontal = 0
	_scroll.scroll_vertical = 0
	_grid.fit_zoom_to_viewport(_scroll.size)
	if _zoom_spin:
		_zoom_spin.set_value_no_signal(float(_grid.get("zoom")) * 100.0)


func _apply_dock_fields_to_form(state: Dictionary) -> void:
	_anim_name.text = String(state.get("animation_name", ""))
	_fps_spin.value = float(state.get("fps", 10.0))
	_loop_check.button_pressed = bool(state.get("loop", true))
	var status: String = String(state.get("review_status", "needs_review"))
	for i: int in range(_review_option.item_count):
		if _review_option.get_item_text(i) == status:
			_review_option.select(i)
			break
	_notes_edit.text = String(state.get("notes", ""))


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


func _on_grid_selection_changed(frames: PackedInt32Array) -> void:
	_selection_summary_label.text = MAPPER_HELPERS.selection_summary(frames)
	if frames.is_empty():
		_candidate_preview_info.text = "No frames selected for preview."
		_candidate_preview_rect.texture = null
	else:
		_show_preview_frame(frames[0])


func _on_grid_hover_changed(frame_index: int, row: int, column: int) -> void:
	if frame_index < 0:
		_hover_label.text = "Hover: —"
	else:
		_hover_label.text = "Hover: Frame %d | row %d | col %d" % [frame_index, row, column]


func _on_clear_selection() -> void:
	if _grid:
		_grid.clear_selection()


func _on_select_dock_range() -> void:
	if dock == null or not dock.has_method("get_dock_selection_frames"):
		return
	var dock_frames: Variant = dock.call("get_dock_selection_frames")
	var frames: PackedInt32Array = dock_frames if dock_frames is PackedInt32Array else PackedInt32Array()
	_grid.call("set_selected_frames", frames)
	_set_status("Loaded dock range into canvas (%d frames)." % frames.size())


func _on_apply_to_dock() -> void:
	if dock == null or not dock.has_method("apply_canvas_selection_to_dock"):
		return
	var frames: PackedInt32Array = _grid.call("get_selected_frames")
	dock.call("apply_canvas_selection_to_dock", frames)
	_set_status("Applied %d frames to dock fields." % frames.size())


func _on_add_update_animation() -> void:
	if dock == null or not dock.has_method("upsert_animation_from_canvas"):
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
	var atlas := _atlas_for_frame(global_index)
	if _candidate_preview_rect:
		_candidate_preview_rect.texture = atlas
	if _candidate_preview_info:
		_candidate_preview_info.text = "Frame %d | row %d | col %d" % [global_index, row, col]


func _on_play_preview() -> void:
	_preview_candidate_mode = false
	_preview_frames = _grid.call("get_selected_frames") if _grid else PackedInt32Array()
	if _preview_frames.is_empty():
		_candidate_preview_info.text = "No frames selected for preview."
		return
	_preview_index = 0
	_preview_playing = true
	_preview_timer.wait_time = 1.0 / maxf(0.1, float(_fps_spin.value))
	_preview_timer.start()
	_show_preview_frame(_preview_frames[0])


func _on_stop_preview() -> void:
	_preview_playing = false
	_preview_candidate_mode = false
	_preview_timer.stop()


func _on_preview_tick() -> void:
	if not _preview_playing or _preview_frames.is_empty():
		return
	_preview_index += 1
	if _preview_index >= _preview_frames.size():
		var loop := _loop_check.button_pressed
		if loop:
			_preview_index = 0
		else:
			_preview_index = _preview_frames.size() - 1
			_preview_playing = false
			_preview_timer.stop()
	var fps: float = maxf(0.1, float(_fps_spin.value))
	_preview_timer.wait_time = 1.0 / fps
	_show_preview_frame(_preview_frames[_preview_index])


func sync_selection_from_dock_animation(frames: PackedInt32Array) -> void:
	if _grid:
		_grid.set_selected_frames(frames)


func _on_close_requested() -> void:
	_on_stop_preview()
	hide()
