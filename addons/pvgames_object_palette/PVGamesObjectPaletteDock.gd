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
const PLACEMENT_ROUTE_LABELS := [
	"Fixed Behind Art",
	"Fixed Occludable Art",
	"Sortable 2.5D Prop",
	"Fixed Foreground Art",
	"Review",
]
const PLACEMENT_ROUTE_KEYS := [
	"fixed_behind",
	"fixed_occludable",
	"sortable_2d_prop",
	"fixed_foreground",
	"review",
]
const PLACEMENT_SHAPES := ["Stroke", "Rectangle Outline", "Rectangle Fill", "Scatter Rectangle"]
const MAX_SCATTER_COUNT := 500
const ROUTE_OBJECT_CONTAINER := {
	"fixed_behind": "BehindPlayerObjects",
	"fixed_occludable": "OccludableObjects",
	"fixed_foreground": "ForegroundObjects",
	"review": "ReviewObjects",
}
const ROUTE_ICON_CONTAINER := {
	"fixed_behind": "BehindPlayerIcons",
	"fixed_occludable": "OccludableIcons",
	"fixed_foreground": "ForegroundIcons",
	"review": "ReviewIcons",
}

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
var _use_z_override: CheckBox
var _select_after_stamp: CheckBox
var _use_undo_redo: CheckBox
var _brush_mode: CheckBox
var _brush_spacing_spin: SpinBox
var _brush_alignment: OptionButton
var _brush_auto_spacing: CheckBox
var _place_with_mouse_pending := false
var _consume_next_left_release := false
var _user_chose_route := false
var _brush_stroke_active := false
var _brush_container: Node2D
var _brush_scene_root: Node
var _brush_points: Array[Vector2] = []
var _brush_last_point: Vector2 = Vector2.INF
var _brush_anchor: Vector2 = Vector2.ZERO
var _brush_axis: String = ""
var _brush_axis_locked := false
var _brush_visible_size_cache: Dictionary = {}
var _placement_route: OptionButton
var _placement_shape: OptionButton
var _scatter_count_spin: SpinBox
var _jitter_enable: CheckBox
var _jitter_x: SpinBox
var _jitter_y: SpinBox
var _random_rotation_enable: CheckBox
var _rotation_min: SpinBox
var _rotation_max: SpinBox
var _random_scale_enable: CheckBox
var _scale_min: SpinBox
var _scale_max: SpinBox
var _deterministic_seed: CheckBox
var _random_seed_spin: SpinBox
var _shape_drag_active := false
var _shape_drag_start := Vector2.ZERO
var _shape_drag_container: Node2D
var _shape_drag_scene_root: Node
var _last_stamp_variation_summary := ""
var _active_placement_route_key := "fixed_occludable"
var _syncing_route_ui := false
var _ui_ready := false
var _erase_box_armed := false
var _erase_box_drag_active := false
var _erase_box_start := Vector2.ZERO

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()

func _ready() -> void:
	_build_ui()
	_load_indexes()
	_apply_filters()


func _build_ui() -> void:
	_ui_ready = false
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
	var help_section := _collapsible_section("Help / Status", false)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "TileMaps are for floors/repeats. Stamp objects and icons here when they need individual move/scale/rotation."
	help_section.add_child(help)
	var filters_section := _collapsible_section("Search / Filters", true)
	filters_section.add_child(_heading("Search / Filters"))
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search object/icon id, filename, category, source, use..."
	_search_box.text_changed.connect(func(_t: String) -> void: _apply_filters())
	filters_section.add_child(_search_box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters_section.add_child(grid)
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
	var results_section := _collapsible_section("Results", true)
	results_section.add_child(_heading("Results"))
	_result_count_label = Label.new()
	results_section.add_child(_result_count_label)
	_results = ItemList.new()
	_results.custom_minimum_size = Vector2(360, 320)
	_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results.select_mode = ItemList.SELECT_SINGLE
	_results.item_selected.connect(_on_result_selected)
	results_section.add_child(_results)
	var selected_section := _collapsible_section("Selected Asset", false)
	selected_section.add_child(_heading("Selected Asset"))
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(220, 120)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selected_section.add_child(_preview)
	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(360, 120)
	_details.fit_content = false
	selected_section.add_child(_details)
	var route_section := _collapsible_section("Placement Route", true)
	route_section.add_child(_heading("Placement Route"))
	var route_grid := GridContainer.new()
	route_grid.columns = 2
	route_section.add_child(route_grid)
	route_grid.add_child(_label("Route"))
	_placement_route = _option(PLACEMENT_ROUTE_LABELS)
	_placement_route.item_selected.connect(_on_placement_route_changed)
	route_grid.add_child(_placement_route)
	var route_help := Label.new()
	route_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_help.text = "Fixed routes use ArtRoot PVG_EditableObjects containers (scratch test scene). Sortable 2.5D Prop only works in scenes with VisualRoot/SortableWorld or EntityRoot y_sort_enabled — use Phase3JSortable2DPilot.tscn for sortable QA. Icons refuse Sortable route."
	route_section.add_child(route_help)
	var placement_section := _collapsible_section("Placement", true)
	placement_section.add_child(_heading("Placement"))
	var placement := GridContainer.new()
	placement.columns = 2
	placement_section.add_child(placement)
	placement.add_child(_label("Target Container"))
	_target_container = _option(OBJECT_CONTAINERS + ICON_CONTAINERS)
	_target_container.item_selected.connect(_on_target_container_changed)
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
	_z_index_override = _spin(-4096, 4096, 0, 1)
	placement.add_child(_z_index_override)
	_use_z_override = CheckBox.new()
	_use_z_override.text = "Use Z Override"
	_use_z_override.toggled.connect(_on_use_z_override_toggled)
	placement_section.add_child(_use_z_override)
	_select_after_stamp = CheckBox.new()
	_select_after_stamp.text = "Select new object after stamping"
	_select_after_stamp.button_pressed = true
	placement_section.add_child(_select_after_stamp)
	_use_undo_redo = CheckBox.new()
	_use_undo_redo.text = "Create UndoRedo action"
	_use_undo_redo.button_pressed = true
	placement_section.add_child(_use_undo_redo)
	var brush_section := _collapsible_section("Brush Placement", false)
	brush_section.add_child(_heading("Brush Placement"))
	_brush_mode = CheckBox.new()
	_brush_mode.text = "Brush Mode"
	_brush_mode.toggled.connect(_on_brush_mode_toggled)
	brush_section.add_child(_brush_mode)
	var brush_grid := GridContainer.new()
	brush_grid.columns = 2
	brush_section.add_child(brush_grid)
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
	brush_section.add_child(_brush_auto_spacing)
	var brush_help := Label.new()
	brush_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brush_help.text = "Brush Mode: left-drag to stamp. Auto Axis locks to horizontal/vertical strips. Auto Asset Spacing uses visible opaque bounds for edge-to-edge PVGames repeats. Release LMB commits one undo; RMB/Esc cancels. Non-Stroke shapes also use Brush Mode for click-drag rectangles."
	brush_section.add_child(brush_help)
	var shape_section := _collapsible_section("Placement Shape", false)
	shape_section.add_child(_heading("Placement Shape"))
	var shape_grid := GridContainer.new()
	shape_grid.columns = 2
	shape_section.add_child(shape_grid)
	shape_grid.add_child(_label("Shape"))
	_placement_shape = _option(PLACEMENT_SHAPES)
	shape_grid.add_child(_placement_shape)
	shape_grid.add_child(_label("Scatter Count"))
	_scatter_count_spin = _spin(1, MAX_SCATTER_COUNT, 24, 1)
	shape_grid.add_child(_scatter_count_spin)
	var shape_help := Label.new()
	shape_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shape_help.text = "Stroke = brush drag. Rectangle Outline/Fill click-drag in viewport. Scatter Rectangle places random points inside drag rect (count clamped to %d). One undo per rectangle/scatter operation." % MAX_SCATTER_COUNT
	shape_section.add_child(shape_help)
	var variation_section := _collapsible_section("Variation", false)
	variation_section.add_child(_heading("Variation"))
	var var_grid := GridContainer.new()
	var_grid.columns = 2
	variation_section.add_child(var_grid)
	_jitter_enable = CheckBox.new()
	_jitter_enable.text = "Enable Position Jitter"
	variation_section.add_child(_jitter_enable)
	var_grid.add_child(_label("Jitter X"))
	_jitter_x = _spin(0, 4096, 0, 1)
	var_grid.add_child(_jitter_x)
	var_grid.add_child(_label("Jitter Y"))
	_jitter_y = _spin(0, 4096, 0, 1)
	var_grid.add_child(_jitter_y)
	_random_rotation_enable = CheckBox.new()
	_random_rotation_enable.text = "Enable Random Rotation"
	variation_section.add_child(_random_rotation_enable)
	var_grid.add_child(_label("Rotation Min"))
	_rotation_min = _spin(-360, 360, 0, 1)
	var_grid.add_child(_rotation_min)
	var_grid.add_child(_label("Rotation Max"))
	_rotation_max = _spin(-360, 360, 0, 1)
	var_grid.add_child(_rotation_max)
	_random_scale_enable = CheckBox.new()
	_random_scale_enable.text = "Enable Random Scale"
	variation_section.add_child(_random_scale_enable)
	var_grid.add_child(_label("Scale Min"))
	_scale_min = _spin(0.01, 20, 1, 0.05)
	var_grid.add_child(_scale_min)
	var_grid.add_child(_label("Scale Max"))
	_scale_max = _spin(0.01, 20, 1, 0.05)
	var_grid.add_child(_scale_max)
	_deterministic_seed = CheckBox.new()
	_deterministic_seed.text = "Deterministic Random Seed"
	_deterministic_seed.button_pressed = true
	variation_section.add_child(_deterministic_seed)
	var_grid.add_child(_label("Random Seed"))
	_random_seed_spin = _spin(0, 2147483647, 1337, 1)
	var_grid.add_child(_random_seed_spin)
	var erase_section := _collapsible_section("Erase Palette Stamps", true)
	erase_section.add_child(_heading("Erase Palette Stamps"))
	var erase_help := Label.new()
	erase_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	erase_help.text = "Erases only nodes with created_by = PVGamesObjectPaletteDock. Refuses GameplayRoot and non-palette nodes."
	erase_section.add_child(erase_help)
	_button(erase_section, "Erase Selected Palette-Created Node", _erase_selected_palette_created_node)
	_button(erase_section, "Box Erase Palette Stamps", _begin_box_erase_palette_stamps)
	_button(erase_section, "Cancel Box Erase", _cancel_box_erase_palette_stamps)
	var actions_section := _collapsible_section("Actions", true)
	actions_section.add_child(_heading("Actions"))
	var buttons := GridContainer.new()
	buttons.columns = 1
	actions_section.add_child(buttons)
	_button(buttons, "Ensure Art Stamp Root", _ensure_art_stamp_root_action)
	_button(buttons, "Dry Run Stamp", _dry_run_stamp_selected)
	_button(buttons, "Stamp Selected at Typed Position", func() -> void: _stamp_selected_at_position(_typed_position()))
	_button(buttons, "Stamp Selected at Scene Origin", func() -> void: _stamp_selected_at_position(Vector2.ZERO))
	_button(buttons, "Place With Mouse", _begin_place_with_mouse)
	_button(buttons, "Copy Object ID", _copy_selected_id)
	_button(buttons, "Refresh Index", _refresh_index)
	_syncing_route_ui = true
	_set_placement_route("fixed_occludable")
	_set_target_container(ROUTE_OBJECT_CONTAINER["fixed_occludable"], true)
	_syncing_route_ui = false
	_ui_ready = true


func _on_use_z_override_toggled(enabled: bool) -> void:
	if not _ui_ready or _z_index_override == null:
		return
	if enabled:
		_status_label.text = "Z Override enabled -> %d." % int(_z_index_override.value)
	else:
		_status_label.text = "Z Override disabled (route defaults apply)."

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


func _collapsible_section(title: String, default_open: bool = true) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = title.replace(" ", "").replace("/", "")
	var header := Button.new()
	header.text = ("▼ " if default_open else "▶ ") + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.visible = default_open
	header.pressed.connect(func() -> void:
		body.visible = not body.visible
		header.text = ("▼ " if body.visible else "▶ ") + title
	)
	section.add_child(header)
	section.add_child(body)
	_content.add_child(section)
	return body

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
	if not _user_chose_route:
		_set_placement_route_from_container_name(String(entry.recommended_container))
	if _active_placement_route_key != "sortable_2d_prop":
		_set_target_container(entry.recommended_container, true)
	_scale_x.value = float(entry.default_scale)
	_scale_y.value = float(entry.default_scale)
	_z_index_override.value = int(entry.default_z_index)
	_use_z_override.button_pressed = false
	_preview.texture = _load_texture(entry.source_path)
	_details.text = "[b]%s[/b]\nType: %s\nFile: %s\nSource: %s\nCategory: %s\nQuality: %s\nUses: %s\nContainer: %s\nZ: %s | Scale: %s | Pivot: %s\nTexture: %s\nNotes: %s %s" % [entry.id, entry.entry_type, entry.display_name, entry.source_set, entry.category, entry.quality, JSON.stringify(entry.recommended_uses), entry.recommended_container, entry.default_z_index, entry.default_scale, entry.pivot_mode, _shorten_middle(entry.source_path, 78), entry.notes, entry.warnings]

func _dry_run_stamp_selected() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected entry."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	var target: Dictionary = _preview_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	var container_path := String(target.get("target_path", "?"))
	var route_key := String(target.get("route", ""))
	var report := {"changed": false, "mutates_scene": false, "entry_type": _selected_entry.entry_type, "id": _selected_entry.id, "source_texture": _selected_entry.source_path, "placement_route": route_key, "target_container": container_path, "container_exists": bool(target.get("container_exists", true)), "position": _typed_position(), "scale": _typed_scale(), "rotation": _rotation_degrees.value, "use_z_override": _use_z_override.button_pressed, "z_index": _selected_z_index_for_route(route_key), "would_add_collision": false, "would_touch_gameplayroot": false}
	_status_label.text = "Dry-run OK (no scene changes): %s -> route %s -> %s" % [_selected_entry.id, String(target.get("route_label", route_key)), container_path]
	print("[PVGames Object Palette] Dry-run stamp: ", JSON.stringify(report, "\t"))


func _begin_place_with_mouse() -> void:
	_cancel_box_erase_palette_stamps(false)
	_consume_next_left_release = false
	if _place_with_mouse_pending:
		_place_with_mouse_pending = false
		_notify_input_forwarding_changed()
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
	var route_key := _selected_placement_route()
	var target: Dictionary = _preview_stamp_target(scene_root, _selected_entry, route_key)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	_place_with_mouse_pending = true
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	_status_label.text = "Mouse placement armed (%s): left-click the 2D viewport to stamp, right-click/Esc to cancel." % String(target.get("route_label", _route_label_for_key(route_key)))


func should_forward_canvas_gui_input() -> bool:
	return _place_with_mouse_pending or _brush_stroke_active or _shape_drag_active or _erase_box_armed or _erase_box_drag_active or (_brush_mode != null and _brush_mode.button_pressed)


func is_mouse_placement_pending() -> bool:
	return _place_with_mouse_pending


func _notify_input_forwarding_changed() -> void:
	if not _ui_ready:
		return
	if _plugin != null and _plugin.has_method("notify_input_forwarding_changed"):
		_plugin.call("notify_input_forwarding_changed")


func _clear_mouse_placement_pending(status_text: String = "") -> void:
	if not _place_with_mouse_pending:
		if status_text != "":
			_status_label.text = status_text
		return
	_place_with_mouse_pending = false
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	if status_text != "":
		_status_label.text = status_text


func handle_canvas_gui_input(event: InputEvent) -> bool:
	if _erase_box_armed or _erase_box_drag_active:
		return _handle_erase_box_canvas_input(event)
	if _shape_drag_active:
		return _handle_shape_drag_input(event)
	if _brush_stroke_active:
		return _handle_brush_canvas_input(event)
	if _consume_next_left_release and event is InputEventMouseButton:
		var release_event := event as InputEventMouseButton
		if release_event.button_index == MOUSE_BUTTON_LEFT and not release_event.pressed:
			_consume_next_left_release = false
			return true
	if _place_with_mouse_pending:
		return _handle_place_with_mouse_canvas_input(event)
	if _brush_mode == null or not _brush_mode.button_pressed:
		return false
	if _selected_placement_shape() == "Stroke":
		return _handle_brush_canvas_input(event)
	return _handle_shape_drag_input(event)


func _handle_place_with_mouse_canvas_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_clear_mouse_placement_pending("Mouse placement cancelled.")
			return true
		return false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_clear_mouse_placement_pending("Mouse placement cancelled.")
			return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_consume_next_left_release = true
				_clear_mouse_placement_pending()
				_stamp_selected_from_mouse_event(mouse_event)
				call_deferred("_notify_input_forwarding_changed")
			return true
		return false
	if event is InputEventMouseMotion:
		return true
	return false


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
	if enabled:
		_cancel_box_erase_palette_stamps(false)
	if not enabled:
		if _brush_stroke_active:
			_cancel_brush_stroke()
		if _shape_drag_active:
			_cancel_shape_drag()
	elif enabled:
		_status_label.text = "Brush Mode on: left-drag in the 2D viewport to stamp; release to commit."
	_notify_input_forwarding_changed()


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
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return false
	return true


func _begin_brush_stroke(mouse_event: InputEventMouseButton) -> void:
	_cancel_box_erase_palette_stamps(false)
	var scene_root := _edited_scene_root()
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	_brush_scene_root = scene_root
	_brush_container = target["container"] as Node2D
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
	var route := _selected_placement_route()
	var y_path := ""
	if route == "sortable_2d_prop":
		var sort_res := _resolve_sortable_parent(scene_root)
		if sort_res.ok:
			y_path = sort_res.path
	_stamp_points_in_target(container, scene_root, points, route, y_path, "Brush Stamp PVGames Palette Entries", "Brush stamped")


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
	var route := _selected_placement_route()
	var y_path := ""
	if route == "sortable_2d_prop":
		var sort_res := _resolve_sortable_parent(scene_root)
		if sort_res.ok:
			y_path = sort_res.path
	_stamp_points_in_target(container, scene_root, points, route, y_path, "Brush Stamp PVGames Palette Entries", "Brush stamped")


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
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	var container: Node2D = target["container"] as Node2D
	var node_position: Vector2 = _event_position_in_container(mouse_event, container)
	_position_x.value = node_position.x
	_position_y.value = node_position.y
	_stamp_selected_in_container(container, scene_root, node_position, String(target.get("route", "")), String(target.get("y_sort_parent_path", "")))


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
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	var container: Node2D = target["container"] as Node2D
	var node_position: Vector2
	if position_is_scene_global:
		node_position = container.to_local(pos)
	else:
		node_position = pos
	_stamp_selected_in_container(container, scene_root, node_position, String(target.get("route", "")), String(target.get("y_sort_parent_path", "")))


func _stamp_selected_in_container(container: Node2D, scene_root: Node, node_position: Vector2, route: String = "", y_sort_path: String = "") -> void:
	if route == "":
		route = _selected_placement_route()
	var node := _create_stamped_node(_selected_entry, node_position, 0, route, y_sort_path)
	node.name = _unique_child_name(container, _node_name(_selected_entry))
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Stamp PVGames Palette Entry")
		ur.add_do_method(container, "add_child", node)
		ur.add_do_method(self, "_set_owner_recursive", node, scene_root)
		ur.add_do_method(self, "_select_created_object", node)
		ur.add_undo_method(self, "_undo_remove_palette_stamp", container, node, container)
		ur.commit_action()
	else:
		container.add_child(node)
		_set_owner_recursive(node, scene_root)
		_select_created_object(node)
	_status_label.text = "Stamped: route %s -> %s/%s%s" % [_route_label_for_key(route), container.get_path(), node.name, _variation_status_suffix()]


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
	if _use_z_override != null and _use_z_override.button_pressed:
		return int(_z_index_override.value)
	return int(_selected_entry.default_z_index) if not _selected_entry.is_empty() else 0


func _default_z_index_for_route(route: String) -> int:
	if route == "sortable_2d_prop":
		return 0
	var object_container := ROUTE_OBJECT_CONTAINER.get(route, "ReviewObjects")
	return _z_for_container(object_container)

func _set_target_container(container_name: String, block_signals: bool = false) -> void:
	if _target_container == null:
		return
	if block_signals:
		_target_container.set_block_signals(true)
	for i in range(_target_container.get_item_count()):
		if _target_container.get_item_text(i) == container_name:
			_target_container.select(i)
			break
	if block_signals:
		_target_container.set_block_signals(false)

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


func _undo_remove_palette_stamp(parent: Node, node: Node, safe_selection: Node = null) -> void:
	# Undo handler for single palette stamps. Plain remove_child leaves the editor
	# selection pointing at the now-orphaned stamp, which stalls 2D canvas input
	# forwarding so the next Place With Mouse click does nothing. Clear stale
	# placement state, drop the orphaned selection, remove the node, then re-select
	# a stable in-tree CanvasItem (the target container) so forwarding stays healthy.
	# This is selection-only cleanup; it does not mutate scene content beyond the
	# stamp removal that the undo already requires.
	_consume_next_left_release = false
	_place_with_mouse_pending = false
	if _editor_interface != null:
		var selection := _editor_interface.get_selection()
		if selection != null:
			selection.clear()
	if parent != null and node != null and is_instance_valid(node) and node.get_parent() == parent:
		parent.remove_child(node)
	if _editor_interface != null and safe_selection != null and is_instance_valid(safe_selection) and safe_selection is CanvasItem:
		var safe_sel := _editor_interface.get_selection()
		if safe_sel != null:
			safe_sel.add_node(safe_selection)
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")

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


func _selected_placement_route() -> String:
	return _active_placement_route_key


func _selected_placement_shape() -> String:
	return _selected(_placement_shape) if _placement_shape != null else "Stroke"


func _route_label_for_key(route_key: String) -> String:
	for i in range(PLACEMENT_ROUTE_KEYS.size()):
		if PLACEMENT_ROUTE_KEYS[i] == route_key:
			return PLACEMENT_ROUTE_LABELS[i]
	return route_key


func _container_name_for_route(route: String, entry: Dictionary) -> String:
	if entry.get("entry_type", "object") == "icon":
		return ROUTE_ICON_CONTAINER.get(route, "ReviewIcons")
	return ROUTE_OBJECT_CONTAINER.get(route, "ReviewObjects")


func _route_allows_entry(route: String, entry: Dictionary) -> Dictionary:
	if route == "sortable_2d_prop" and entry.get("entry_type", "") == "icon":
		return {"ok": false, "message": "Sortable 2.5D Prop route refuses icons. Choose a Fixed route or Review."}
	return {"ok": true}


func _resolve_sortable_parent(scene_root: Node) -> Dictionary:
	var sort_world := scene_root.get_node_or_null("VisualRoot/SortableWorld") as Node2D
	if sort_world != null and sort_world.y_sort_enabled:
		return {"ok": true, "parent": sort_world, "path": str(sort_world.get_path())}
	var entity := scene_root.get_node_or_null("EntityRoot") as Node2D
	if entity != null and entity.y_sort_enabled:
		return {"ok": true, "parent": entity, "path": str(entity.get_path())}
	return {"ok": false, "message": "Sortable route requires VisualRoot/SortableWorld or EntityRoot with y_sort_enabled = true. Use Phase3JSortable2DPilot.tscn for sortable QA."}


func _target_container_for_route(scene_root: Node, entry: Dictionary) -> Node2D:
	var resolved: Dictionary = _resolve_stamp_target(scene_root, entry)
	if not bool(resolved.get("ok", false)):
		return null
	return resolved["container"] as Node2D


func _preview_stamp_target(scene_root: Node, entry: Dictionary, route: String = "") -> Dictionary:
	if scene_root == null:
		return {"ok": false, "message": "Error: no open scene."}
	if entry.is_empty():
		return {"ok": false, "message": "Error: no selected entry."}
	if route == "":
		route = _selected_placement_route()
	var allow := _route_allows_entry(route, entry)
	if not bool(allow.get("ok", false)):
		return {"ok": false, "message": String(allow.get("message", "Route not allowed for entry."))}
	if route == "sortable_2d_prop":
		var sort_res := _resolve_sortable_parent(scene_root)
		if not bool(sort_res.get("ok", false)):
			return sort_res
		var sort_parent: Node = sort_res["parent"]
		if _node_is_under_gameplayroot(sort_parent):
			return {"ok": false, "message": "Error: sortable parent is under GameplayRoot."}
		return {"ok": true, "route": route, "route_label": _route_label_for_key(route), "target_path": String(sort_res.get("path", "")), "y_sort_parent_path": String(sort_res.get("path", "")), "container_exists": true, "mutates_scene": false}
	if _art_object_root(scene_root) == null:
		return {"ok": false, "message": "Error: ArtRoot not found."}
	var container_name := _container_name_for_route(route, entry)
	var relative_path := _target_path(entry, container_name, scene_root)
	var existing := scene_root.get_node_or_null(relative_path) as Node2D
	if existing != null and _node_is_under_gameplayroot(existing):
		return {"ok": false, "message": "Error: target container unsafe (GameplayRoot)."}
	var reported_path: String = relative_path
	if existing != null:
		reported_path = str(existing.get_path())
	return {"ok": true, "route": route, "route_label": _route_label_for_key(route), "target_path": reported_path, "y_sort_parent_path": "", "container_exists": existing != null, "mutates_scene": false}


func _resolve_stamp_target(scene_root: Node, entry: Dictionary, route: String = "") -> Dictionary:
	if scene_root == null:
		return {"ok": false, "message": "Error: no open scene."}
	if entry.is_empty():
		return {"ok": false, "message": "Error: no selected entry."}
	if route == "":
		route = _selected_placement_route()
	var allow := _route_allows_entry(route, entry)
	if not bool(allow.get("ok", false)):
		return {"ok": false, "message": String(allow.get("message", "Route not allowed for entry."))}
	if route == "sortable_2d_prop":
		var sort_res := _resolve_sortable_parent(scene_root)
		if not bool(sort_res.get("ok", false)):
			return sort_res
		var sort_parent: Node = sort_res["parent"]
		if _node_is_under_gameplayroot(sort_parent):
			return {"ok": false, "message": "Error: sortable parent is under GameplayRoot."}
		return {"ok": true, "container": sort_parent, "route": route, "route_label": _route_label_for_key(route), "y_sort_parent_path": String(sort_res.get("path", ""))}
	if _art_object_root(scene_root) == null:
		return {"ok": false, "message": "Error: ArtRoot not found."}
	var container_name := _container_name_for_route(route, entry)
	var container := _ensure_container(scene_root, entry, container_name)
	if container == null:
		return {"ok": false, "message": "Error: target container missing."}
	if _node_is_under_gameplayroot(container):
		return {"ok": false, "message": "Error: target container unsafe (GameplayRoot)."}
	return {"ok": true, "container": container, "route": route, "route_label": _route_label_for_key(route), "y_sort_parent_path": ""}


func _on_placement_route_changed(idx: int) -> void:
	if not _ui_ready or _syncing_route_ui:
		return
	_user_chose_route = true
	var route: String = _active_placement_route_key
	if idx >= 0 and idx < PLACEMENT_ROUTE_KEYS.size():
		route = String(PLACEMENT_ROUTE_KEYS[idx])
	_active_placement_route_key = route
	if route == "sortable_2d_prop":
		_status_label.text = "Placement route: Sortable 2.5D Prop (direct Y-sort parent). Use Phase3JSortable2DPilot.tscn for sortable QA."
		return
	if _target_container == null:
		return
	var entry: Dictionary = _selected_entry if not _selected_entry.is_empty() else {"entry_type": "object"}
	_set_target_container(_container_name_for_route(route, entry), true)
	_status_label.text = "Placement route: %s -> %s" % [_route_label_for_key(route), _container_name_for_route(route, entry)]


func _on_target_container_changed(_idx: int) -> void:
	if not _ui_ready or _syncing_route_ui:
		return
	if _active_placement_route_key == "sortable_2d_prop":
		return
	_set_placement_route_from_container_name(_selected(_target_container))


func _set_placement_route_from_container_name(container_name: String) -> void:
	var route := "review"
	if container_name in ["BehindPlayerObjects", "BehindPlayerIcons"]:
		route = "fixed_behind"
	elif container_name in ["OccludableObjects", "OccludableIcons"]:
		route = "fixed_occludable"
	elif container_name in ["ForegroundObjects", "ForegroundIcons"]:
		route = "fixed_foreground"
	_set_placement_route(route)


func _set_placement_route(route_key: String) -> void:
	_active_placement_route_key = route_key
	if _placement_route == null:
		return
	_syncing_route_ui = true
	for i in range(PLACEMENT_ROUTE_KEYS.size()):
		if PLACEMENT_ROUTE_KEYS[i] == route_key:
			_placement_route.select(i)
			break
	_syncing_route_ui = false


func _random_for_stamp(stamp_index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if _deterministic_seed != null and _deterministic_seed.button_pressed:
		var seed_base: int = 1337
		if _random_seed_spin != null:
			seed_base = int(_random_seed_spin.value)
		var entry_id := String(_selected_entry.get("id", ""))
		rng.seed = hash([seed_base, stamp_index, entry_id])
	else:
		rng.randomize()
	return rng


func _normalized_scale_range() -> Vector2:
	var lo: float = maxf(float(_scale_min.value) if _scale_min != null else 1.0, 0.01)
	var hi: float = maxf(float(_scale_max.value) if _scale_max != null else 1.0, 0.01)
	if lo > hi:
		var swap := lo
		lo = hi
		hi = swap
	return Vector2(lo, hi)


func _apply_variation_to_transform(base_pos: Vector2, base_scale: Vector2, base_rot: float, stamp_index: int) -> Dictionary:
	var pos := base_pos
	var scale := base_scale
	var rot := base_rot
	var rng := _random_for_stamp(stamp_index)
	if _jitter_enable != null and _jitter_enable.button_pressed:
		pos.x += rng.randf_range(-float(_jitter_x.value), float(_jitter_x.value))
		pos.y += rng.randf_range(-float(_jitter_y.value), float(_jitter_y.value))
	if _random_rotation_enable != null and _random_rotation_enable.button_pressed:
		rot += rng.randf_range(float(_rotation_min.value), float(_rotation_max.value))
	if _random_scale_enable != null and _random_scale_enable.button_pressed:
		var scale_range := _normalized_scale_range()
		var factor := rng.randf_range(scale_range.x, scale_range.y)
		scale *= Vector2(factor, factor)
	return {"position": pos, "scale": scale, "rotation": rot}


func _selected_z_index_for_route(route: String) -> int:
	if _use_z_override != null and _use_z_override.button_pressed:
		return int(_z_index_override.value)
	return _default_z_index_for_route(route)


func _create_stamped_node(entry: Dictionary, pos: Vector2, stamp_index: int, route: String, y_sort_path: String) -> Node2D:
	var xf := _apply_variation_to_transform(pos, _typed_scale(), _rotation_degrees.value, stamp_index)
	var node := _create_node(entry, xf.position, xf.scale, xf.rotation, _selected_z_index_for_route(route))
	node.set_meta("placement_route", route)
	if y_sort_path != "":
		node.set_meta("y_sort_parent_path", y_sort_path)
	return node


func _variation_status_suffix() -> String:
	var parts: Array[String] = []
	if _jitter_enable != null and _jitter_enable.button_pressed:
		parts.append("jitter")
	if _random_rotation_enable != null and _random_rotation_enable.button_pressed:
		parts.append("rotation")
	if _random_scale_enable != null and _random_scale_enable.button_pressed:
		parts.append("scale")
	if parts.is_empty():
		return ""
	return " | Variation: %s" % ", ".join(parts)


func _stamp_points_in_target(container: Node2D, scene_root: Node, points: Array[Vector2], route: String, y_sort_path: String, undo_label: String, operation_label: String = "Stamped") -> void:
	var nodes: Array[Node2D] = []
	var reserved_names: Array[String] = []
	for i in range(points.size()):
		var node := _create_stamped_node(_selected_entry, points[i], i, route, y_sort_path)
		var node_name := _unique_child_name_for_batch(container, _node_name(_selected_entry), reserved_names)
		reserved_names.append(node_name)
		node.name = node_name
		nodes.append(node)
	if nodes.is_empty():
		_status_label.text = "Placement produced no stamps."
		return
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action(undo_label)
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
	_status_label.text = "%s %d entries under %s (route %s)%s" % [operation_label, nodes.size(), container.get_path(), _route_label_for_key(route), _variation_status_suffix()]


func _build_stroke_points(from_points: Array[Vector2]) -> Array[Vector2]:
	return from_points.duplicate()


func _build_rectangle_outline_points(rect: Rect2, spacing: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var safe_spacing := maxf(spacing, 1.0)
	var normalized := _normalized_rect(rect)
	if normalized.size.length() <= 0.5:
		points.append(normalized.position)
		return points
	var top_left := normalized.position
	var top_right := Vector2(normalized.end.x, normalized.position.y)
	var bottom_right := normalized.end
	var bottom_left := Vector2(normalized.position.x, normalized.end.y)
	var corners: Array[Vector2] = [top_left, top_right, bottom_right, bottom_left, top_left]
	for edge_index in range(4):
		var a := corners[edge_index]
		var b := corners[edge_index + 1]
		var edge_length := a.distance_to(b)
		var steps := maxi(1, int(ceil(edge_length / safe_spacing)))
		for step in range(steps):
			var t := float(step) / float(steps)
			var p := a.lerp(b, t)
			if points.is_empty() or points[points.size() - 1].distance_to(p) >= safe_spacing * 0.45:
				points.append(p)
	return points


func _build_rectangle_fill_points(rect: Rect2, spacing: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var safe_spacing := maxf(spacing, 1.0)
	var normalized := _normalized_rect(rect)
	if normalized.size.length() <= 0.5:
		points.append(normalized.position)
		return points
	var y := normalized.position.y
	while y <= normalized.end.y + 0.001:
		var x := normalized.position.x
		while x <= normalized.end.x + 0.001:
			points.append(Vector2(x, y))
			x += safe_spacing
		y += safe_spacing
	return points


func _build_scatter_points(rect: Rect2, count: int, base_index: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var clamped := clampi(count, 1, MAX_SCATTER_COUNT)
	var normalized := _normalized_rect(rect)
	for i in range(clamped):
		var rng := _random_for_stamp(base_index + i)
		var px := normalized.position.x + rng.randf() * normalized.size.x
		var py := normalized.position.y + rng.randf() * normalized.size.y
		points.append(Vector2(px, py))
	return points


func _normalized_rect(rect: Rect2) -> Rect2:
	var out := rect
	if out.size.x < 0.0:
		out.position.x += out.size.x
		out.size.x = absf(out.size.x)
	if out.size.y < 0.0:
		out.position.y += out.size.y
		out.size.y = absf(out.size.y)
	return out


func _handle_shape_drag_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and _shape_drag_active:
			_cancel_shape_drag()
			return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if _shape_drag_active:
				_cancel_shape_drag()
				return true
			return false
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _shape_drag_active:
					if not _can_start_brush():
						return false
					_begin_shape_drag(mouse_event)
					return true
				return true
			if _shape_drag_active:
				_commit_shape_drag(mouse_event)
				return true
	if event is InputEventMouseMotion and _shape_drag_active:
		var motion_event := event as InputEventMouseMotion
		if _shape_drag_container != null:
			var end_pos := _event_position_in_container(motion_event, _shape_drag_container)
			var shape := _selected_placement_shape()
			_status_label.text = "%s drag: %s -> %s" % [shape, _shape_drag_start, end_pos]
		return true
	return _shape_drag_active


func _begin_shape_drag(mouse_event: InputEventMouseButton) -> void:
	_cancel_box_erase_palette_stamps(false)
	var scene_root := _edited_scene_root()
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	_shape_drag_scene_root = scene_root
	_shape_drag_container = target["container"] as Node2D
	_shape_drag_start = _event_position_in_container(mouse_event, _shape_drag_container)
	_shape_drag_active = true
	_status_label.text = "%s drag started. Release LMB to place; RMB/Esc cancels." % _selected_placement_shape()


func _commit_shape_drag(mouse_event: InputEventMouseButton) -> void:
	if not _shape_drag_active:
		return
	var container := _shape_drag_container
	var scene_root := _shape_drag_scene_root
	var end_pos := _event_position_in_container(mouse_event, container)
	var start_pos := _shape_drag_start
	_shape_drag_active = false
	_shape_drag_container = null
	_shape_drag_scene_root = null
	if container == null or scene_root == null:
		_status_label.text = "Shape placement cancelled."
		return
	var rect := Rect2(start_pos, end_pos - start_pos)
	var spacing := _effective_brush_spacing(BRUSH_AXIS_FREEFORM)
	var shape := _selected_placement_shape()
	var points: Array[Vector2] = []
	match shape:
		"Rectangle Outline":
			points = _build_rectangle_outline_points(rect, spacing)
		"Rectangle Fill":
			points = _build_rectangle_fill_points(rect, spacing)
		"Scatter Rectangle":
			points = _build_scatter_points(rect, int(_scatter_count_spin.value), 0)
		_:
			_status_label.text = "Shape placement cancelled (not a drag shape)."
			return
	if points.is_empty():
		_status_label.text = "%s produced no stamps." % shape
		return
	var target: Dictionary = _resolve_stamp_target(scene_root, _selected_entry)
	if not bool(target.get("ok", false)):
		_status_label.text = String(target.get("message", "Error: stamp target unresolved."))
		return
	_stamp_points_in_target(container, scene_root, points, String(target.get("route", "")), String(target.get("y_sort_parent_path", "")), "%s PVGames Palette Entries" % shape, shape)


func _cancel_shape_drag() -> void:
	_shape_drag_active = false
	_shape_drag_container = null
	_shape_drag_scene_root = null
	_status_label.text = "%s drag cancelled." % _selected_placement_shape()


func _node_is_palette_created(node: Node) -> bool:
	return node != null and node.has_meta("created_by") and String(node.get_meta("created_by")) == "PVGamesObjectPaletteDock"


func _node_is_erasable_palette_stamp(node: Node) -> bool:
	return _node_is_palette_created(node) and not _node_is_under_gameplayroot(node)


func _erase_selected_palette_created_node() -> void:
	if _editor_interface == null:
		_status_label.text = "Error: editor interface unavailable."
		return
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if selected.is_empty():
		_status_label.text = "Error: select a palette-created node to erase."
		return
	var node := selected[0]
	if _node_is_under_gameplayroot(node):
		_status_label.text = "Refused: cannot erase nodes under GameplayRoot."
		return
	if not _node_is_palette_created(node):
		_status_label.text = "Refused: selected node was not created by PVGames Object Palette."
		return
	var parent := node.get_parent()
	if parent == null:
		_status_label.text = "Refused: palette node has no parent."
		return
	var scene_root := _edited_scene_root()
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Erase PVGames Palette Stamp")
		ur.add_do_method(parent, "remove_child", node)
		ur.add_undo_method(parent, "add_child", node)
		ur.add_undo_method(self, "_set_owner_recursive", node, scene_root)
		ur.add_undo_method(self, "_select_created_object", node)
		ur.commit_action()
	else:
		parent.remove_child(node)
	_status_label.text = "Erased palette stamp: %s" % node.name


func _begin_box_erase_palette_stamps() -> void:
	_clear_mouse_placement_pending()
	_cancel_box_erase_palette_stamps(false)
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	_erase_box_armed = true
	_erase_box_drag_active = false
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	_status_label.text = "Box erase armed: drag in the 2D viewport to erase palette-created stamps only."


func _cancel_box_erase_palette_stamps(update_status: bool = true) -> void:
	if not _erase_box_armed and not _erase_box_drag_active:
		return
	_erase_box_armed = false
	_erase_box_drag_active = false
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	if update_status:
		_status_label.text = "Box erase cancelled."


func _handle_erase_box_canvas_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_cancel_box_erase_palette_stamps()
			return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_box_erase_palette_stamps()
			return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _erase_box_armed and not _erase_box_drag_active:
					return false
				_erase_box_drag_active = true
				_erase_box_start = _canvas_position_from_mouse_event(mouse_event)
				return true
			if _erase_box_drag_active:
				var end_pos := _canvas_position_from_mouse_event(mouse_event)
				_commit_box_erase_palette_stamps(_erase_box_start, end_pos)
				return true
	if event is InputEventMouseMotion and _erase_box_drag_active:
		return true
	return _erase_box_armed or _erase_box_drag_active


func _commit_box_erase_palette_stamps(start_pos: Vector2, end_pos: Vector2) -> void:
	_erase_box_armed = false
	_erase_box_drag_active = false
	_notify_input_forwarding_changed()
	call_deferred("_notify_input_forwarding_changed")
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Box erase cancelled."
		return
	var rect := _normalized_rect(Rect2(start_pos, end_pos - start_pos))
	var nodes := _collect_erasable_stamps_in_global_rect(scene_root, rect)
	if nodes.is_empty():
		_status_label.text = "No palette-created stamps found in rectangle."
		return
	if _use_undo_redo.button_pressed and _plugin != null:
		var ur := _plugin.get_undo_redo()
		ur.create_action("Box Erase PVGames Palette Stamps")
		for node in nodes:
			ur.add_do_method(node.get_parent(), "remove_child", node)
		for i in range(nodes.size() - 1, -1, -1):
			var node: Node = nodes[i]
			ur.add_undo_method(node.get_parent(), "add_child", node)
			ur.add_undo_method(self, "_set_owner_recursive", node, scene_root)
		ur.commit_action()
	else:
		for node in nodes:
			node.get_parent().remove_child(node)
	_status_label.text = "Erased %d palette stamps." % nodes.size()


func _collect_erasable_stamps_in_global_rect(scene_root: Node, rect: Rect2) -> Array[Node2D]:
	var found: Array[Node2D] = []
	_collect_erasable_stamps_recursive(scene_root, rect, found)
	return found


func _collect_erasable_stamps_recursive(node: Node, rect: Rect2, found: Array[Node2D]) -> void:
	if node is Node2D and _node_is_erasable_palette_stamp(node):
		var node2d := node as Node2D
		if rect.has_point(node2d.global_position):
			found.append(node2d)
	for child in node.get_children():
		_collect_erasable_stamps_recursive(child, rect, found)
