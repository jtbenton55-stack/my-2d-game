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
	_content.add_child(_heading("Actions"))
	var buttons := GridContainer.new()
	buttons.columns = 1
	_content.add_child(buttons)
	_button(buttons, "Dry Run Stamp", _dry_run_stamp_selected)
	_button(buttons, "Stamp Selected at Typed Position", func() -> void: _stamp_selected_at_position(_typed_position()))
	_button(buttons, "Stamp Selected at 2D View Center", func() -> void: _stamp_selected_at_position(Vector2.ZERO))
	_button(buttons, "Place With Mouse (Deferred)", func() -> void: _status_label.text = "Place With Mouse is deferred.")
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
	var report := {"changed": false, "entry_type": _selected_entry.entry_type, "id": _selected_entry.id, "source_texture": _selected_entry.source_path, "target_container": _target_path(_selected_entry, _selected(_target_container)), "position": _typed_position(), "scale": _typed_scale(), "rotation": _rotation_degrees.value, "z_index": _selected_z_index(), "would_add_collision": false, "would_touch_gameplayroot": false}
	_status_label.text = "Dry-run OK: %s -> %s" % [_selected_entry.id, report.target_container]
	print("[PVGames Object Palette] Dry-run stamp: ", JSON.stringify(report, "\t"))

func _stamp_selected_at_position(pos: Vector2) -> void:
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
	if scene_root.get_node_or_null("ArtRoot/World") == null:
		_status_label.text = "Error: ArtRoot/World not found."
		return
	var container := _ensure_container(scene_root, _selected_entry, _selected(_target_container))
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container unsafe."
		return
	var node := _create_node(_selected_entry, pos, _typed_scale(), _rotation_degrees.value, _selected_z_index())
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

func _ensure_container(scene_root: Node, entry: Dictionary, container_name: String) -> Node2D:
	var world := scene_root.get_node_or_null("ArtRoot/World")
	if world == null:
		return null
	var base := world.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		world.add_child(base)
		_set_owner_recursive(base, scene_root)
	if entry.entry_type == "icon":
		var icons := base.get_node_or_null("IconObjects") as Node2D
		if icons == null:
			icons = Node2D.new()
			icons.name = "IconObjects"
			base.add_child(icons)
			_set_owner_recursive(icons, scene_root)
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		var c := icons.get_node_or_null(container_name) as Node2D
		if c == null:
			c = Node2D.new()
			c.name = container_name
			c.z_index = _z_for_container(container_name)
			icons.add_child(c)
			_set_owner_recursive(c, scene_root)
		return c
	if not OBJECT_CONTAINERS.has(container_name):
		container_name = entry.recommended_container
	var obj := base.get_node_or_null(container_name) as Node2D
	if obj == null:
		obj = Node2D.new()
		obj.name = container_name
		obj.z_index = _z_for_container(container_name)
		base.add_child(obj)
		_set_owner_recursive(obj, scene_root)
	return obj

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

func _target_path(entry: Dictionary, container_name: String) -> String:
	if entry.entry_type == "icon":
		if not ICON_CONTAINERS.has(container_name):
			container_name = entry.recommended_container
		return "ArtRoot/World/PVG_EditableObjects/IconObjects/%s" % container_name
	return "ArtRoot/World/PVG_EditableObjects/%s" % container_name

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
