@tool
extends VBoxContainer

const OBJECT_INDEX_PATH := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
const ICON_INDEX_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const EDITABLE_OBJECT_SCRIPT := "res://src/hideout/PVGEditableObject.gd"
const OBJECT_CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]
const ICON_CONTAINERS := ["BehindPlayerIcons", "OccludableIcons", "ForegroundIcons", "ReviewIcons"]
const CATEGORIES := ["wall", "barrier", "prop", "sign", "terminal", "furniture", "large_structure", "foreground", "review", "security", "hazard", "mission", "evidence", "store", "inventory", "scheme_card", "big_case", "map_pin", "keypad", "terminal", "door", "tech", "cyber", "doomsday", "decor"]
const ICON_QUALITIES := ["READY_UI_ICON", "READY_WORLD_DECAL", "READY_BOTH", "READY_UI_PANEL", "REVIEW_MANUALLY"]
const ICON_USES := ["store_terminal", "storefront_item", "mission_board", "scheme_card", "evidence_board", "big_case", "objective_marker", "warning_indicator", "security_indicator", "world_decal", "wall_sticker", "hologram_marker", "decor_shop_thumbnail"]
const MAX_RESULTS := 200
const BRUSH_ALIGNMENTS := ["Auto Axis", "Horizontal", "Vertical", "Freeform"]
const BRUSH_AXIS_HORIZONTAL := "horizontal"
const BRUSH_AXIS_VERTICAL := "vertical"
const BRUSH_AXIS_FREEFORM := "freeform"
const BRUSH_AXIS_AUTO_THRESHOLD := 12.0
const BRUSH_VISIBLE_ALPHA_THRESHOLD := 0.01

var _plugin: EditorPlugin
var _editor_interface: EditorInterface
var _entries: Array[Dictionary] = []
var _filtered: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _content: VBoxContainer
var _status_label: Label
var _search_box: LineEdit
var _asset_type_filter: OptionButton
var _container_filter: OptionButton
var _source_filter: OptionButton
var _category_filter: OptionButton
var _icon_quality_filter: OptionButton
var _icon_use_filter: OptionButton
var _result_count_label: Label
var _results: ItemList
var _preview: TextureRect
var _details: RichTextLabel
var _target_container: OptionButton
var _position_x: SpinBox
var _position_y: SpinBox
var _scale_x: SpinBox
var _scale_y: SpinBox
var _rotation_degrees: SpinBox
var _z_index_override: SpinBox
var _select_after_stamp: CheckBox
var _use_undo_redo: CheckBox
var _brush_mode: CheckBox
var _brush_spacing_spin: SpinBox
var _brush_alignment: OptionButton
var _brush_auto_spacing: CheckBox
var _place_with_mouse_pending := false
var _brush_stroke_active := false
var _brush_container: Node2D
var _brush_scene_root: Node
var _brush_points: Array[Vector2] = []
var _brush_last_point: Vector2 = Vector2.INF
var _brush_anchor: Vector2 = Vector2.ZERO
var _brush_axis: String = ""
var _brush_axis_locked := false
var _brush_visible_size_cache: Dictionary = {}

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()

func _ready() -> void:
	_build_ui()
	_load_indexes()
	_apply_filters()

func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "PVGames Object Palette"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(360, 42)
	add_child(_status_label)
	var scroll := ScrollContainer.new()
	scroll.name = "MainScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_content = VBoxContainer.new()
	_content.name = "ContentVBox"
	_content.custom_minimum_size = Vector2(360, 0)
	scroll.add_child(_content)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "TileMaps are for floors/repeats. Stamp objects and icons here when they need individual move/scale/rotation."
	_content.add_child(help)
	_content.add_child(_heading("Search / Filters"))
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search object/icon id, filename, category, source, use..."
	_search_box.text_changed.connect(func(_t: String) -> void: _apply_filters())
	_content.add_child(_search_box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(grid)
	grid.add_child(_label("Asset Type"))
	_asset_type_filter = _option(["All", "Objects", "Icons"])
	_asset_type_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_asset_type_filter)
	grid.add_child(_label("Container"))
	_container_filter = _option(["All"] + OBJECT_CONTAINERS + ICON_CONTAINERS)
	_container_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_container_filter)
	grid.add_child(_label("Source"))
	_source_filter = _option(["All", "core", "central_security", "cyber_city_icons", "doomsday_icons"])
	_source_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_source_filter)
	grid.add_child(_label("Category"))
	_category_filter = _option(["All"] + CATEGORIES)
	_category_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_category_filter)
	grid.add_child(_label("Icon Quality"))
	_icon_quality_filter = _option(["All"] + ICON_QUALITIES)
	_icon_quality_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_icon_quality_filter)
	grid.add_child(_label("Icon Use"))
	_icon_use_filter = _option(["All"] + ICON_USES)
	_icon_use_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_icon_use_filter)
	_content.add_child(_heading("Results"))
	_result_count_label = Label.new()
	_content.add_child(_result_count_label)
	_results = ItemList.new()
	_results.custom_minimum_size = Vector2(360, 150)
	_results.select_mode = ItemList.SELECT_SINGLE
	_results.item_selected.connect(_on_result_selected)
	_content.add_child(_results)
	_content.add_child(_heading("Selected Asset"))
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(220, 120)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_content.add_child(_preview)
	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(360, 120)
	_details.fit_content = false
	_content.add_child(_details)
	_content.add_child(_heading("Placement"))
	var placement := GridContainer.new()
	placement.columns = 2
	_content.add_child(placement)
	placement.add_child(_label("Target Container"))
	_target_container = _option(OBJECT_CONTAINERS + ICON_CONTAINERS)
	placement.add_child(_target_container)
	placement.add_child(_label("Position X"))
	_position_x = _spin(-100000, 100000, 0, 1)
	placement.add_child(_position_x)
	placement.add_child(_label("Position Y"))
	_position_y = _spin(-100000, 100000, 0, 1)
	placement.add_child(_position_y)
	placement.add_child(_label("Scale X"))
	_scale_x = _spin(-20, 20, 1, 0.05)
	placement.add_child(_scale_x)
	placement.add_child(_label("Scale Y"))
	_scale_y = _spin(-20, 20, 1, 0.05)
	placement.add_child(_scale_y)
	placement.add_child(_label("Rotation"))
	_rotation_degrees = _spin(-360, 360, 0, 1)
	placement.add_child(_rotation_degrees)
	placement.add_child(_label("Z Override"))
	_z_index_override = _spin(-4096, 4096, 999999, 1)
	placement.add_child(_z_index_override)
	_select_after_stamp = CheckBox.new()
	_select_after_stamp.text = "Select new object after stamping"
	_select_after_stamp.button_pressed = true
	_content.add_child(_select_after_stamp)
	_use_undo_redo = CheckBox.new()
	_use_undo_redo.text = "Create UndoRedo action"
	_use_undo_redo.button_pressed = true
	_content.add_child(_use_undo_redo)
	_content.add_child(_heading("Brush Placement"))
	_brush_mode = CheckBox.new()
	_brush_mode.text = "Brush Mode"
	_brush_mode.toggled.connect(_on_brush_mode_toggled)
	_content.add_child(_brush_mode)
	var brush_grid := GridContainer.new()
	brush_grid.columns = 2
	_content.add_child(brush_grid)
	brush_grid.add_child(_label("Brush Spacing"))
	_brush_spacing_spin = _spin(8, 4096, 96, 1)
	brush_grid.add_child(_brush_spacing_spin)
	brush_grid.add_child(_label("Brush Alignment"))
	_brush_alignment = _option(BRUSH_ALIGNMENTS)
	_brush_alignment.select(0)
	brush_grid.add_child(_brush_alignment)
	_brush_auto_spacing = CheckBox.new()
	_brush_auto_spacing.text = "Auto Asset Spacing"
	_brush_auto_spacing.button_pressed = true
	_content.add_child(_brush_auto_spacing)
	var brush_help := Label.new()
	brush_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brush_help.text = "Brush Mode: left-drag to stamp. Auto Axis locks to horizontal/vertical strips. Auto Asset Spacing uses visible opaque bounds for edge-to-edge PVGames repeats. Release LMB commits one undo; RMB/Esc cancels."
	_content.add_child(brush_help)
	_content.add_child(_heading("Actions"))
	var buttons := GridContainer.new()
	buttons.columns = 1
	_content.add_child(buttons)
	_button(buttons, "Ensure Art Stamp Root", _ensure_art_stamp_root_action)
	_button(buttons, "Dry Run Stamp", _dry_run_stamp_selected)
	_button(buttons, "Stamp Selected at Typed Position", func() -> void: _stamp_selected_at_position(_typed_position()))
	_button(buttons, "Stamp Selected at Scene Origin", func() -> void: _stamp_selected_at_position(Vector2.ZERO))
	_button(buttons, "Place With Mouse", _begin_place_with_mouse)
	_button(buttons, "Copy Object ID", _copy_selected_id)
	_button(buttons, "Refresh Index", _refresh_index)

func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l

func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.custom_minimum_size = Vector2(0, 26)
	return l

func _option(items: Array) -> OptionButton:
	var o := OptionButton.new()
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		o.add_item(String(item))
	return o

func _spin(min_value: float, max_value: float, value: float, step: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_value
	s.max_value = max_value
	s.allow_greater = true
	s.allow_lesser = true
	s.value = value
	s.step = step
	return s

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _load_indexes() -> void:
	_entries.clear()
	if FileAccess.file_exists(OBJECT_INDEX_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(OBJECT_INDEX_PATH))
		if parsed is Dictionary and parsed.has("objects"):
			for item in parsed["objects"]:
				if item is Dictionary:
					_entries.append(_normalize_object(item))
	if FileAccess.file_exists(ICON_INDEX_PATH):
		var icons = JSON.parse_string(FileAccess.get_file_as_string(ICON_INDEX_PATH))
		if icons is Array:
			for item in icons:
				if item is Dictionary:
					_entries.append(_normalize_icon(item))
	_status_label.text = "Loaded %d palette entries (objects + icons)." % _entries.size()

func _normalize_object(item: Dictionary) -> Dictionary:
	return {"entry_type": "object", "id": item.get("object_id", ""), "source_set": item.get("source_set", ""), "source_path": item.get("source_png_path", ""), "display_name": item.get("filename", ""), "category": item.get("object_category", "review"), "recommended_container": item.get("recommended_container", "ReviewObjects"), "recommended_uses": [], "quality": item.get("quality_classification", ""), "default_scale": item.get("recommended_default_scale", 1.0), "default_z_index": item.get("recommended_z_index", 0), "pivot_mode": item.get("pivot_mode", "VISIBLE_ALPHA_CENTER"), "notes": item.get("notes", ""), "warnings": item.get("palette_warning", "")}

func _normalize_icon(item: Dictionary) -> Dictionary:
	return {"entry_type": "icon", "id": item.get("icon_id", ""), "source_set": item.get("source_set", ""), "source_path": item.get("source_png_path", ""), "display_name": item.get("source_filename", ""), "category": item.get("primary_category", "unknown_review"), "recommended_container": item.get("recommended_world_container", "ReviewIcons"), "recommended_uses": item.get("recommended_uses", []), "quality": item.get("quality_classification", ""), "default_scale": item.get("recommended_default_world_scale", 1.0), "default_z_index": item.get("recommended_z_index_role", 0), "pivot_mode": "VISIBLE_ALPHA_CENTER", "notes": item.get("notes", ""), "warnings": item.get("warnings", ""), "atlas_region_rect": item.get("atlas_region_rect", null)}

func _apply_filters() -> void:
	_filtered.clear()
	_results.clear()
	var query := _search_box.text.to_lower()
	var asset_type := _selected(_asset_type_filter)
	var container := _selected(_container_filter)
	var source := _selected(_source_filter)
	var category := _selected(_category_filter)
	var icon_quality := _selected(_icon_quality_filter)
	var icon_use := _selected(_icon_use_filter)
	for entry in _entries:
		if asset_type == "Objects" and entry.entry_type != "object":
			continue
		if asset_type == "Icons" and entry.entry_type != "icon":
			continue
		if container != "All" and String(entry.recommended_container) != container:
			continue
		if source != "All" and String(entry.source_set) != source:
			continue
		if category != "All" and String(entry.category) != category:
			continue
		if icon_quality != "All" and entry.entry_type == "icon" and String(entry.quality) != icon_quality:
			continue
		if icon_use != "All" and entry.entry_type == "icon" and not (entry.recommended_uses as Array).has(icon_use):
			continue
		if query != "" and not JSON.stringify(entry).to_lower().contains(query):
			continue
		_filtered.append(entry)
	for i in range(min(_filtered.size(), MAX_RESULTS)):
		var entry := _filtered[i]
		_results.add_item("%s | %s | %s | %s" % [entry.entry_type, entry.id, entry.category, entry.source_set])
		_results.set_item_metadata(i, entry)
		var tex := _load_texture(entry.source_path)
		if tex != null:
			_results.set_item_icon(i, tex)
	_result_count_label.text = "Indexed: %d | Filtered: %d | Showing: %d" % [_entries.size(), _filtered.size(), min(_filtered.size(), MAX_RESULTS)]

func _on_result_selected(index: int) -> void:
	var data = _results.get_item_metadata(index)
	if data is Dictionary:
		_select_entry(data)

func _select_entry(entry: Dictionary) -> void:
	_selected_entry = entry
	_status_label.text = "Selected: %s" % entry.id
	_set_target_container(entry.recommended_container)
	_scale_x.value = float(entry.default_scale)
	_scale_y.value = float(entry.default_scale)
	_z_index_override.value = int(entry.default_z_index)
	_preview.texture = _load_texture(entry.source_path)
	_details.text = "[b]%s[/b]\nType: %s\nFile: %s\nSource: %s\nCategory: %s\nQuality: %s\nUses: %s\nContainer: %s\nZ: %s | Scale: %s | Pivot: %s\nTexture: %s\nNotes: %s %s" % [entry.id, entry.entry_type, entry.display_name, entry.source_set, entry.category, entry.quality, JSON.stringify(entry.recommended_uses), entry.recommended_container, entry.default_z_index, entry.default_scale, entry.pivot_mode, _shorten_middle(entry.source_path, 78), entry.notes, entry.warnings]

func _dry_run_stamp_selected() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	var scene_root := _edited_scene_root()
	var report := {"changed": false, "entry_type": _selected_entry.entry_type, "id": _selected_entry.id, "source_texture": _selected_entry.source_path, "target_container": _target_path(_selected_entry, _selected(_target_container), scene_root), "position": _typed_position(), "scale": _typed_scale(), "rotation": _rotation_degrees.value, "z_index": _selected_z_index(), "would_add_collision": false, "would_touch_gameplayroot": false}
	_status_label.text = "Dry-run OK: %s -> %s" % [_selected_entry.id, report.target_container]
	print("[PVGames Object Palette] Dry-run stamp: ", JSON.stringify(report, "\t"))


func _begin_place_with_mouse() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: select an object or icon before mouse placement."
		return
	if not ResourceLoader.exists(_selected_entry.source_path):
		_status_label.text = "Error: source texture missing."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	if _art_object_root(scene_root) == null:
		_status_label.text = "Error: ArtRoot not found."
		return
	_place_with_mouse_pending = true
	_status_label.text = "Mouse placement armed: left-click the 2D viewport to stamp, right-click/Esc to cancel."


func handle_canvas_gui_input(event: InputEvent) -> bool:
	if _brush_stroke_active:
		return _handle_brush_canvas_input(event)
	if _place_with_mouse_pending:
		return _handle_place_with_mouse_canvas_input(event)
	if _brush_mode == null or not _brush_mode.button_pressed:
		return false
	return _handle_brush_canvas_input(event)


func _handle_place_with_mouse_canvas_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_place_with_mouse_pending = false
			_status_label.text = "Mouse placement cancelled."
			return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return false
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_place_with_mouse_pending = false
			_status_label.text = "Mouse placement cancelled."
			return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_place_with_mouse_pending = false
			_stamp_selected_from_mouse_event(mouse_event)
			return true
	return true


func _handle_brush_canvas_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and _brush_stroke_active:
			_cancel_brush_stroke()
			return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if _brush_stroke_active:
				_cancel_brush_stroke()
				return true
			return false
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _brush_stroke_active:
					if not _can_start_brush():
						return false
					_begin_brush_stroke(mouse_event)
					return true
				return true
			if _brush_stroke_active:
				_commit_brush_stroke()
				return true
	if event is InputEventMouseMotion and _brush_stroke_active:
		var motion_event := event as InputEventMouseMotion
		if motion_event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if _brush_container != null:
				_update_brush_points_from_motion(_event_position_in_container(motion_event, _brush_container))
			return true
	return _brush_stroke_active


func _on_brush_mode_toggled(enabled: bool) -> void:
	if not enabled and _brush_stroke_active:
		_cancel_brush_stroke()
	elif enabled:
		_status_label.text = "Brush Mode on: left-drag in the 2D viewport to stamp; release to commit."


func _can_start_brush() -> bool:
	if _selected_entry.is_empty():
		_status_label.text = "Error: select an object or icon before brush placement."
		return false
	if not ResourceLoader.exists(_selected_entry.source_path):
		_status_label.text = "Error: source texture missing."
		return false
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return false
	if _art_object_root(scene_root) == null:
		_status_label.text = "Error: ArtRoot not found."
		return false
	var container := _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container unsafe."
		return false
	return true


func _begin_brush_stroke(mouse_event: InputEventMouseButton) -> void:
	var scene_root := _edited_scene_root()
	_brush_scene_root = scene_root
	_brush_container = _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	_brush_points.clear()
	_brush_last_point = Vector2.INF
	_brush_axis = ""
	_brush_axis_locked = false
	_brush_stroke_active = true
	_brush_anchor = _event_position_in_container(mouse_event, _brush_container)
	var alignment := _selected_brush_alignment()
	if alignment == "Horizontal":
		_brush_axis = BRUSH_AXIS_HORIZONTAL
		_brush_axis_locked = true
	elif alignment == "Vertical":
		_brush_axis = BRUSH_AXIS_VERTICAL
		_brush_axis_locked = true
	elif alignment == "Freeform":
		_brush_axis = BRUSH_AXIS_FREEFORM
	_update_brush_points_from_motion(_brush_anchor)
	_status_label.text = "Brush stroke started: drag to place stamps, release left mouse to commit."


func _update_brush_points_from_motion(current_point: Vector2) -> void:
	if _brush_axis == BRUSH_AXIS_FREEFORM or _selected_brush_alignment() == "Freeform":
		_append_brush_point_if_far_enough(current_point)
	else:
		_rebuild_axis_locked_brush_points(current_point)


func _append_brush_point_if_far_enough(pos: Vector2) -> void:
	var spacing := _effective_brush_spacing(BRUSH_AXIS_FREEFORM)
	if _brush_last_point == Vector2.INF or _brush_last_point.distance_to(pos) >= spacing:
		if _brush_points.is_empty() or not _points_equal_or_close(_brush_points[_brush_points.size() - 1], pos):
			_brush_points.append(pos)
			_brush_last_point = pos


func _rebuild_axis_locked_brush_points(current_point: Vector2) -> void:
	if not _brush_axis_locked:
		var resolved_axis := _resolve_brush_axis(current_point)
		if resolved_axis == "":
			_brush_points = [_brush_anchor]
			_brush_last_point = _brush_anchor
			return
		_brush_axis = resolved_axis
		_brush_axis_locked = true
	var projected := _project_point_to_brush_axis(current_point)
	var spacing := _effective_brush_spacing(_brush_axis)
	var new_points: Array[Vector2] = []
	if spacing <= 0.0:
		new_points.append(_brush_anchor)
	else:
		var signed_distance := projected.x - _brush_anchor.x
		if _brush_axis == BRUSH_AXIS_VERTICAL:
			signed_distance = projected.y - _brush_anchor.y
		var step_count := int(floor(absf(signed_distance) / spacing))
		var direction := -1.0 if signed_distance < 0.0 else 1.0
		for step in range(step_count + 1):
			var offset := direction * spacing * float(step)
			var stamp_pos := _brush_anchor
			if _brush_axis == BRUSH_AXIS_HORIZONTAL:
				stamp_pos.x += offset
			else:
				stamp_pos.y += offset
			new_points.append(stamp_pos)
	_brush_points = new_points
	if not new_points.is_empty():
		_brush_last_point = new_points[new_points.size() - 1]


func _resolve_brush_axis(current_point: Vector2) -> String:
	var alignment := _selected_brush_alignment()
	if alignment == "Horizontal":
		return BRUSH_AXIS_HORIZONTAL
	if alignment == "Vertical":
		return BRUSH_AXIS_VERTICAL
	if alignment == "Freeform":
		return BRUSH_AXIS_FREEFORM
	var delta := current_point - _brush_anchor
	if delta.length() < BRUSH_AXIS_AUTO_THRESHOLD:
		return _brush_axis
	if absf(delta.x) >= absf(delta.y):
		return BRUSH_AXIS_HORIZONTAL
	return BRUSH_AXIS_VERTICAL


func _project_point_to_brush_axis(point: Vector2) -> Vector2:
	if _brush_axis == BRUSH_AXIS_HORIZONTAL:
		return Vector2(point.x, _brush_anchor.y)
	if _brush_axis == BRUSH_AXIS_VERTICAL:
		return Vector2(_brush_anchor.x, point.y)
	return point


func _selected_asset_scaled_size() -> Vector2:
	if _selected_entry.is_empty():
		return Vector2.ZERO
	var texture := _load_texture(_selected_entry.source_path)
	if texture == null:
		return Vector2.ZERO
	var scale := _typed_scale()
	return texture.get_size() * Vector2(absf(scale.x), absf(scale.y))


func _selected_asset_scaled_visible_size() -> Vector2:
	if _selected_entry.is_empty():
		return Vector2.ZERO
	var source_path := String(_selected_entry.source_path)
	var texture := _load_texture(source_path)
	if texture == null:
		return Vector2.ZERO
	var visible_unscaled := _texture_visible_size(texture, source_path)
	var scale := _typed_scale()
	return visible_unscaled * Vector2(absf(scale.x), absf(scale.y))


func _texture_visible_size(texture: Texture2D, source_path: String) -> Vector2:
	if source_path != "" and _brush_visible_size_cache.has(source_path):
		return _brush_visible_size_cache[source_path]
	var fallback_size := texture.get_size()
	var image := texture.get_image()
	var visible_size := _compute_image_visible_size(image, fallback_size)
	if source_path != "":
		_brush_visible_size_cache[source_path] = visible_size
	return visible_size


func _compute_image_visible_size(image: Image, fallback_size: Vector2) -> Vector2:
	if image == null or image.is_empty():
		return fallback_size
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return fallback_size
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	var found_visible := false
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > BRUSH_VISIBLE_ALPHA_THRESHOLD:
				found_visible = true
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if not found_visible:
		return fallback_size
	return Vector2(max_x - min_x + 1, max_y - min_y + 1)


func _effective_brush_spacing(axis: String) -> float:
	if _brush_auto_spacing != null and _brush_auto_spacing.button_pressed:
		var asset_size := _selected_asset_scaled_visible_size()
		if asset_size != Vector2.ZERO:
			if axis == BRUSH_AXIS_HORIZONTAL and asset_size.x > 0.0:
				return asset_size.x
			if axis == BRUSH_AXIS_VERTICAL and asset_size.y > 0.0:
				return asset_size.y
			if axis == BRUSH_AXIS_FREEFORM:
				return maxf(asset_size.x, asset_size.y)
	return maxf(float(_brush_spacing_spin.value), 1.0)


func _selected_brush_alignment() -> String:
	return _selected(_brush_alignment) if _brush_alignment != null else "Auto Axis"


func _points_equal_or_close(a: Vector2, b: Vector2, epsilon: float = 0.5) -> bool:
	return a.distance_to(b) <= epsilon


func _commit_brush_stroke() -> void:
	if not _brush_stroke_active:
		return
	var container := _brush_container
	var scene_root := _brush_scene_root
	var points := _brush_points.duplicate()
	_brush_stroke_active = false
	_brush_container = null
	_brush_scene_root = null
	_brush_points.clear()
	_brush_last_point = Vector2.INF
	_brush_axis = ""
	_brush_axis_locked = false
	if container == null or scene_root == null or points.is_empty():
		_status_label.text = "Brush stroke cancelled (no points)."
		return
	_stamp_brush_points_in_container(container, scene_root, points)


func _cancel_brush_stroke() -> void:
	_brush_stroke_active = false
	_brush_container = null
	_brush_scene_root = null
	_brush_points.clear()
	_brush_last_point = Vector2.INF
	_brush_axis = ""
	_brush_axis_locked = false
	_status_label.text = "Brush stroke cancelled."


func _stamp_brush_points_in_container(container: Node2D, scene_root: Node, points: Array[Vector2]) -> void:
	var nodes: Array[Node2D] = []
	var reserved_names: Array[String] = []
	for pos in points:
		var node := _create_node(_selected_entry, pos, _typed_scale(), _rotation_degrees.value, _selected_z_index())
		var node_name := _unique_child_name_for_batch(container, _node_name(_selected_entry), reserved_names)
		reserved_names.append(node_name)
		node.name = node_name
		nodes.append(node)
	if nodes.is_empty():
		_status_label.text = "Brush stroke produced no stamps."
		return
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Brush Stamp PVGames Palette Entries")
		for node in nodes:
			ur.add_do_method(container, "add_child", node)
		for node in nodes:
			ur.add_do_method(self, "_set_owner_recursive", node, scene_root)
		for i in range(nodes.size() - 1, -1, -1):
			ur.add_undo_method(container, "remove_child", nodes[i])
		ur.commit_action()
		if _select_after_stamp.button_pressed:
			_select_created_object(nodes[nodes.size() - 1])
	else:
		for node in nodes:
			container.add_child(node)
			_set_owner_recursive(node, scene_root)
		if _select_after_stamp.button_pressed:
			_select_created_object(nodes[nodes.size() - 1])
	_status_label.text = "Brush stamped %d entries under %s" % [nodes.size(), container.get_path()]


func _stamp_selected_from_mouse_event(mouse_event: InputEventMouseButton) -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	if not ResourceLoader.exists(_selected_entry.source_path):
		_status_label.text = "Error: source texture missing."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	if _art_object_root(scene_root) == null:
		_status_label.text = "Error: ArtRoot not found."
		return
	var container := _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container unsafe."
		return
	var node_position := _event_position_in_container(mouse_event, container)
	_position_x.value = node_position.x
	_position_y.value = node_position.y
	_stamp_selected_in_container(container, scene_root, node_position)


func _stamp_selected_at_position(pos: Vector2, position_is_scene_global := false) -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	if not ResourceLoader.exists(_selected_entry.source_path):
		_status_label.text = "Error: source texture missing."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	if _art_object_root(scene_root) == null:
		_status_label.text = "Error: ArtRoot not found."
		return
	var container := _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container unsafe."
		return
	var node_position := container.to_local(pos) if position_is_scene_global else pos
	_stamp_selected_in_container(container, scene_root, node_position)


func _stamp_selected_in_container(container: Node2D, scene_root: Node, node_position: Vector2) -> void:
	var node := _create_node(_selected_entry, node_position, _typed_scale(), _rotation_degrees.value, _selected_z_index())
	node.name = _unique_child_name(container, _node_name(_selected_entry))
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Stamp PVGames Palette Entry")
		ur.add_do_method(container, "add_child", node)
		ur.add_do_method(self, "_set_owner_recursive", node, scene_root)
		ur.add_do_method(self, "_select_created_object", node)
		ur.add_undo_method(container, "remove_child", node)
		ur.commit_action()
	else:
		container.add_child(node)
		_set_owner_recursive(node, scene_root)
		_select_created_object(node)
	_status_label.text = "Stamped: %s/%s" % [container.get_path(), node.name]


func _ensure_art_stamp_root_action() -> void:
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	var base := _ensure_art_stamp_root(scene_root, true)
	if base == null:
		_status_label.text = "Error: ArtRoot not found."
		return
	_status_label.text = "Ensured art stamp root: %s" % base.get_path()


func _ensure_art_stamp_root(scene_root: Node, include_target_containers := false) -> Node2D:
	var art_target := _art_object_root(scene_root)
	if art_target == null:
		return null
	var base := art_target.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		art_target.add_child(base)
		_set_owner_recursive(base, scene_root)
	if include_target_containers:
		for object_container in OBJECT_CONTAINERS:
			_ensure_named_container(base, object_container, scene_root)
		var icons := _ensure_named_container(base, "IconObjects", scene_root)
		for icon_container in ICON_CONTAINERS:
			_ensure_named_container(icons, icon_container, scene_root)
	return base

func _ensure_container(scene_root: Node, entry: Dictionary, container_name: String) -> Node2D:
	var base := _ensure_art_stamp_root(scene_root)
	if base == null:
		return null
	if entry.entry_type == "icon":
		var icons := _ensure_named_container(base, "IconObjects", scene_root)
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		return _ensure_named_container(icons, container_name, scene_root)
	if not OBJECT_CONTAINERS.has(container_name):
		container_name = entry.recommended_container
	return _ensure_named_container(base, container_name, scene_root)


func _ensure_named_container(parent: Node, container_name: String, scene_root: Node) -> Node2D:
	var container := parent.get_node_or_null(container_name) as Node2D
	if container == null:
		container = Node2D.new()
		container.name = container_name
		container.z_index = _z_for_container(container_name)
		parent.add_child(container)
		_set_owner_recursive(container, scene_root)
	return container

func _create_node(entry: Dictionary, pos: Vector2, scale: Vector2, rot: float, z: int) -> Node2D:
	var editable_object_script := load(EDITABLE_OBJECT_SCRIPT) as Script
	var node := editable_object_script.new() as Node2D if editable_object_script != null else Node2D.new()
	if node.has_method("set_metadata_from_index_entry"):
		node.set_metadata_from_index_entry({"object_id": entry.id, "source_set": entry.source_set, "source_png_path": entry.source_path, "recommended_object_category": entry.category, "recommended_container": entry.recommended_container, "recommended_pivot_mode": entry.pivot_mode, "notes": "created_by=PVGamesObjectPaletteDock; entry_type=%s" % entry.entry_type, "recommended_z_index": z})
	node.position = pos
	node.scale = scale
	node.rotation_degrees = rot
	node.z_index = z
	node.set_meta("created_by", "PVGamesObjectPaletteDock")
	node.set_meta("entry_type", entry.entry_type)
	node.set_meta("id", entry.id)
	if entry.entry_type == "icon":
		node.set_meta("icon_id", entry.id)
		node.set_meta("quality", entry.quality)
		node.set_meta("recommended_uses", entry.recommended_uses)
		node.set_meta("atlas_region_rect", entry.get("atlas_region_rect", null))
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.centered = true
		sprite.texture = _load_texture(entry.source_path)
	return node

func _target_path(entry: Dictionary, container_name: String, scene_root: Node = null) -> String:
	var root_path := "ArtRoot/World"
	if scene_root != null and scene_root.get_node_or_null("ArtRoot/World") == null and scene_root.get_node_or_null("ArtRoot") != null:
		root_path = "ArtRoot"
	if entry.entry_type == "icon":
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		return "%s/PVG_EditableObjects/IconObjects/%s" % [root_path, container_name]
	return "%s/PVG_EditableObjects/%s" % [root_path, container_name]


func _art_object_root(scene_root: Node) -> Node2D:
	if scene_root == null:
		return null
	var art_root := scene_root.get_node_or_null("ArtRoot") as Node2D
	if art_root == null:
		return null
	var world := art_root.get_node_or_null("World") as Node2D
	if world != null:
		return world
	return art_root


func _selected(option: OptionButton) -> String:
	return option.get_item_text(option.selected) if option != null and option.selected >= 0 else "All"

func _typed_position() -> Vector2:
	return Vector2(_position_x.value, _position_y.value)

func _typed_scale() -> Vector2:
	return Vector2(_scale_x.value, _scale_y.value)

func _selected_z_index() -> int:
	return int(_selected_entry.default_z_index) if int(_z_index_override.value) == 999999 else int(_z_index_override.value)

func _set_target_container(container_name: String) -> void:
	for i in range(_target_container.get_item_count()):
		if _target_container.get_item_text(i) == container_name:
			_target_container.select(i)
			return

func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null

func _copy_selected_id() -> void:
	if _selected_entry.is_empty():
		return
	DisplayServer.clipboard_set(_selected_entry.id)
	_status_label.text = "Copied: %s" % _selected_entry.id

func _refresh_index() -> void:
	_brush_visible_size_cache.clear()
	_load_indexes()
	_apply_filters()

func _edited_scene_root() -> Node:
	return _editor_interface.get_edited_scene_root() if _editor_interface != null else null

func _select_created_object(node: Node) -> void:
	if _select_after_stamp.button_pressed and _editor_interface != null:
		_editor_interface.get_selection().clear()
		_editor_interface.get_selection().add_node(node)

func _node_name(entry: Dictionary) -> String:
	var prefix := "PVG_Icon" if entry.entry_type == "icon" else "PVG_Object"
	return "%s_%s_%s" % [prefix, String(entry.category).capitalize().replace(" ", ""), String(entry.id).right(8)]

func _unique_child_name(parent: Node, base: String) -> String:
	var name := base
	var i := 1
	while parent.get_node_or_null(name) != null:
		name = "%s_%04d" % [base, i]
		i += 1
	return name


func _unique_child_name_for_batch(parent: Node, base: String, reserved_names: Array[String]) -> String:
	var name := _unique_child_name(parent, base)
	var i := 1
	while reserved_names.has(name):
		name = "%s_%04d" % [base, i]
		i += 1
	return name


func _editor_viewport_2d() -> SubViewport:
	return _editor_interface.get_editor_viewport_2d() if _editor_interface != null else null


func _canvas_position_from_mouse_event(_event: InputEventMouse) -> Vector2:
	var viewport := _editor_viewport_2d()
	if viewport == null:
		return _event.position
	var viewport_mouse := viewport.get_mouse_position()
	return viewport.get_canvas_transform().affine_inverse() * viewport_mouse


func _event_position_in_container(event: InputEventMouse, container: Node2D) -> Vector2:
	var canvas_pos := _canvas_position_from_mouse_event(event)
	return container.get_global_transform().affine_inverse() * canvas_pos

func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)

func _node_is_under_gameplayroot(node: Node) -> bool:
	var current := node
	while current != null:
		if current.name == "GameplayRoot":
			return true
		current = current.get_parent()
	return false

func _z_for_container(container: String) -> int:
	if container in ["ForegroundObjects", "ForegroundIcons"]:
		return 160
	if container in ["OccludableObjects", "OccludableIcons"]:
		return 90
	if container in ["BehindPlayerObjects", "BehindPlayerIcons"]:
		return -120
	return -40

func _shorten_middle(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	var keep := int((max_length - 3) / 2)
	return text.left(keep) + "..." + text.right(keep)
