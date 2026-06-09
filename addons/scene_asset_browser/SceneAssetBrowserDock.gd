@tool
extends VBoxContainer

const MAX_INDEX_ENTRIES := 350
const MAX_REPORT_ENTRIES := 250

const CATEGORY_ALL := "All"
const STATUS_ALL := "All"

const PVGAMES_OBJECT_INDEXES: Array[String] = [
	"res://docs/reports/pvgames_editable_object_asset_index.json",
	"res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json",
]
const ICON_INDEX := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const LEGACY_PREVIEW := "res://resources/character_animation_maps/generated_preview/parmida_manual_preview_spriteframes.tres"

const AUTHORING_TEMPLATES: Array[String] = [
	"res://scenes/templates/IsoMissionTemplate.tscn",
	"res://scenes/missions_iso/authoring_templates/PoopBagAuthorTemplate.tscn",
	"res://scenes/missions_iso/authoring_templates/CaseCashAuthorTemplate.tscn",
	"res://scenes/missions_iso/authoring_templates/ClueAuthorTemplate.tscn",
	"res://scenes/missions_iso/authoring_templates/GlowGuyAuthorTemplate.tscn",
]

const SECURITY_TEMPLATES: Array[String] = [
	"res://scenes/missions_iso/security_authoring_templates/SecurityBeamAuthorTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/AmbushBeamAuthorTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/SecurityCameraAuthorTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/GuardSpawnAuthorTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/GuardPatrolRouteAuthorTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/PatrolWaypointTemplate.tscn",
	"res://scenes/missions_iso/security_authoring_templates/AreaTriggerAuthorTemplate.tscn",
]

const DEFERRED_NOTES: Array[Dictionary] = [
	{"id": "sequence_templates", "label": "Sequence templates", "reason": "No real sequence template resources found yet."},
	{"id": "mission_authoring_palette", "label": "Mission Authoring Palette", "reason": "Planned separately; not a real plugin category yet."},
	{"id": "mission_assist_browser", "label": "Mission Assist Browser", "reason": "Planned separately; not a real plugin category yet."},
	{"id": "idle_guard_template", "label": "Idle guard template", "reason": "Explicitly not implemented in the security guide."},
	{"id": "alarm_group_template", "label": "Alarm group template", "reason": "Explicitly not implemented in the security guide."},
	{"id": "door_keypad_template", "label": "Door/keypad template", "reason": "Audit-only today, not production-ready."},
]

var _plugin: EditorPlugin
var _editor_interface: EditorInterface
var _entries: Array[Dictionary] = []
var _filtered: Array[Dictionary] = []
var _selected_entry: Dictionary = {}

var _status_label: Label
var _search_box: LineEdit
var _category_filter: OptionButton
var _status_filter: OptionButton
var _result_count_label: Label
var _results: ItemList
var _details: RichTextLabel
var _preview_label: Label
var _preview_texture: TextureRect


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()


func _ready() -> void:
	_build_ui()
	_reload_entries()


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "Scene/Asset Browser"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(380, 48)
	add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.name = "MainScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "ContentVBox"
	content.custom_minimum_size = Vector2(380, 0)
	scroll.add_child(content)

	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Read-only Phase 3K browser. Search proven assets, templates, animation maps, dev scenes, and reports. Use focused tools for placement or editing."
	content.add_child(help)

	content.add_child(_heading("Search / Filters"))
	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search label, path, category, status, source, tags..."
	_search_box.text_changed.connect(func(_text: String) -> void: _apply_filters())
	content.add_child(_search_box)

	var grid := GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	grid.add_child(_label("Category"))
	_category_filter = OptionButton.new()
	_category_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_category_filter)
	grid.add_child(_label("Status"))
	_status_filter = OptionButton.new()
	_status_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_filter.item_selected.connect(func(_i: int) -> void: _apply_filters())
	grid.add_child(_status_filter)

	content.add_child(_heading("Results"))
	_result_count_label = Label.new()
	content.add_child(_result_count_label)
	_results = ItemList.new()
	_results.custom_minimum_size = Vector2(380, 180)
	_results.select_mode = ItemList.SELECT_SINGLE
	_results.item_selected.connect(_on_result_selected)
	content.add_child(_results)

	content.add_child(_heading("Selected Entry"))
	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(380, 180)
	_details.fit_content = false
	_details.scroll_active = true
	content.add_child(_details)

	content.add_child(_heading("Preview"))
	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_preview_label)
	_preview_texture = TextureRect.new()
	_preview_texture.custom_minimum_size = Vector2(380, 180)
	_preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(_preview_texture)
	_clear_preview("Select a PNG/WebP/JPG texture entry to preview it here.")

	content.add_child(_heading("Read-Only Actions"))
	var actions := GridContainer.new()
	actions.columns = 1
	content.add_child(actions)
	_button(actions, "Refresh", _reload_entries)
	_button(actions, "Copy res:// Path", _copy_selected_path)
	_button(actions, "Select In FileSystem", _select_selected_path)
	_button(actions, "Open Scene / Resource", _open_selected_resource)


func _reload_entries() -> void:
	_entries.clear()
	_selected_entry = {}
	_clear_preview("Select a PNG/WebP/JPG texture entry to preview it here.")
	_load_pvgames_objects()
	_load_icon_catalog()
	_load_templates("authoring_template", "ready", "mission authoring template", AUTHORING_TEMPLATES)
	_load_templates("security_template", "ready", "security template", SECURITY_TEMPLATES)
	_load_directory_files("animation_map", "ready", "animation map", "res://resources/character_animation_maps", ["json"], 120)
	_load_directory_files("spriteframes_preview", "review", "generated preview", "res://resources/character_animation_maps/generated_preview", ["tres"], 120)
	_load_directory_files("dev_scene", "ready", "dev validation scene", "res://scenes/dev", ["tscn"], 80)
	_load_directory_files("validation_report", "ready", "ai report", "res://reports/ai", ["md"], MAX_REPORT_ENTRIES)
	_load_directory_files("validation_report", "ready", "docs report", "res://docs/reports", ["md", "json"], MAX_REPORT_ENTRIES)
	_load_deferred_notes()
	_rebuild_filter_options()
	_apply_filters()
	_status_label.text = "Loaded %d read-only entries. Phase 3K skeleton does not place, generate, or modify assets." % _entries.size()


func _load_pvgames_objects() -> void:
	for index_path in PVGAMES_OBJECT_INDEXES:
		var records := _records_from_json(index_path)
		var count := 0
		for record in records:
			if count >= MAX_INDEX_ENTRIES:
				break
			_add_entry_from_record(record, "pvgames_object", "ready", index_path)
			count += 1


func _load_icon_catalog() -> void:
	var records := _records_from_json(ICON_INDEX)
	var count := 0
	for record in records:
		if count >= MAX_INDEX_ENTRIES:
			break
		_add_entry_from_record(record, "icon", "ready", ICON_INDEX)
		count += 1


func _load_templates(category: String, status: String, source: String, paths: Array[String]) -> void:
	for path in paths:
		if FileAccess.file_exists(path):
			_entries.append(_entry(path.get_file().get_basename(), path.get_file().get_basename(), category, status, path, source, ["template"]))


func _load_directory_files(category: String, status: String, source: String, root: String, extensions: Array[String], limit: int) -> void:
	var files := _collect_files_recursive(root, extensions, limit)
	for path in files:
		var entry_status := status
		var tags: Array[String] = []
		if path == LEGACY_PREVIEW:
			entry_status = "legacy"
			tags.append("legacy")
		_entries.append(_entry(path.get_file().get_basename(), path.get_file(), category, entry_status, path, source, tags))


func _load_deferred_notes() -> void:
	for note in DEFERRED_NOTES:
		_entries.append({
			"id": String(note.get("id", "deferred")),
			"label": String(note.get("label", "Deferred item")),
			"category": "deferred",
			"status": "deferred",
			"path": "",
			"source": "Phase 3K plan",
			"tags": ["planned"],
			"details": {"reason": String(note.get("reason", "Deferred."))},
		})


func _records_from_json(path: String) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return records
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_collect_records(parsed, records)
	return records


func _collect_records(value, records: Array[Dictionary]) -> void:
	if value is Array:
		for item in value:
			_collect_records(item, records)
	elif value is Dictionary:
		var dict := value as Dictionary
		if _looks_like_asset_record(dict):
			records.append(dict)
			return
		for key in dict.keys():
			_collect_records(dict[key], records)


func _looks_like_asset_record(record: Dictionary) -> bool:
	for key in ["path", "res_path", "resource_path", "filename", "source", "object", "original", "recommended", "quality"]:
		if record.has(key):
			return true
	return false


func _add_entry_from_record(record: Dictionary, category: String, status: String, source: String) -> void:
	var id := _first_string(record, ["id", "object_id", "icon_id", "object", "name", "filename", "source_filename", "original", "source"])
	var path := _first_string(record, ["path", "source_png_path", "res_path", "resource_path", "sprite_path"])
	if id.is_empty():
		id = path.get_file() if not path.is_empty() else category
	var label := id
	var tags: Array[String] = []
	for key in ["category", "object_category", "recommended_object_category", "quality", "quality_classification", "recommended", "recommended_container", "primary", "use", "container", "source", "source_set"]:
		if record.has(key):
			tags.append(str(record[key]))
	_entries.append({
		"id": id,
		"label": label,
		"category": category,
		"status": status,
		"path": path,
		"source": source,
		"tags": tags,
		"details": record,
	})


func _first_string(record: Dictionary, keys: Array[String]) -> String:
	for key in keys:
		if record.has(key):
			var value := str(record[key]).strip_edges()
			if not value.is_empty():
				return value
	return ""


func _entry(id: String, label: String, category: String, status: String, path: String, source: String, tags: Array[String]) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"category": category,
		"status": status,
		"path": path,
		"source": source,
		"tags": tags,
		"details": {},
	}


func _collect_files_recursive(root: String, extensions: Array[String], limit: int) -> Array[String]:
	var results: Array[String] = []
	_walk_files(root, extensions, results, limit)
	results.sort()
	return results


func _walk_files(root: String, extensions: Array[String], results: Array[String], limit: int) -> void:
	if results.size() >= limit:
		return
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if not name.begins_with("."):
			var path := root.path_join(name)
			if dir.current_is_dir():
				_walk_files(path, extensions, results, limit)
			elif extensions.has(path.get_extension().to_lower()) and not path.ends_with(".import"):
				results.append(path)
				if results.size() >= limit:
					break
		name = dir.get_next()
	dir.list_dir_end()


func _rebuild_filter_options() -> void:
	var categories: Array[String] = [CATEGORY_ALL]
	var statuses: Array[String] = [STATUS_ALL]
	for entry in _entries:
		var category := String(entry.get("category", "unknown"))
		var status := String(entry.get("status", "unknown"))
		if not categories.has(category):
			categories.append(category)
		if not statuses.has(status):
			statuses.append(status)
	categories.sort()
	statuses.sort()
	_set_option_items(_category_filter, categories)
	_set_option_items(_status_filter, statuses)


func _set_option_items(option: OptionButton, items: Array[String]) -> void:
	option.clear()
	for item in items:
		option.add_item(item)
	option.select(0)


func _apply_filters() -> void:
	_filtered.clear()
	var query := _search_box.text.strip_edges().to_lower()
	var category := _category_filter.get_item_text(_category_filter.selected) if _category_filter.get_item_count() > 0 else CATEGORY_ALL
	var status := _status_filter.get_item_text(_status_filter.selected) if _status_filter.get_item_count() > 0 else STATUS_ALL
	for entry in _entries:
		if category != CATEGORY_ALL and String(entry.get("category", "")) != category:
			continue
		if status != STATUS_ALL and String(entry.get("status", "")) != status:
			continue
		if not query.is_empty() and not _entry_matches_query(entry, query):
			continue
		_filtered.append(entry)
	_rebuild_results()


func _entry_matches_query(entry: Dictionary, query: String) -> bool:
	var haystack := "%s %s %s %s %s %s" % [
		String(entry.get("id", "")),
		String(entry.get("label", "")),
		String(entry.get("category", "")),
		String(entry.get("status", "")),
		String(entry.get("path", "")),
		String(entry.get("source", "")),
	]
	for tag in entry.get("tags", []):
		haystack += " " + str(tag)
	return haystack.to_lower().contains(query)


func _rebuild_results() -> void:
	_results.clear()
	for i in range(_filtered.size()):
		var entry := _filtered[i]
		var label := "[%s/%s] %s" % [String(entry.get("category", "")), String(entry.get("status", "")), String(entry.get("label", ""))]
		_results.add_item(label)
		_results.set_item_metadata(i, i)
	_result_count_label.text = "%d / %d entries" % [_filtered.size(), _entries.size()]
	if _filtered.is_empty():
		_details.text = "No matching entries."
		_clear_preview("No matching texture entry to preview.")


func _on_result_selected(index: int) -> void:
	var filtered_index := int(_results.get_item_metadata(index))
	if filtered_index < 0 or filtered_index >= _filtered.size():
		return
	_selected_entry = _filtered[filtered_index]
	_details.text = _details_text(_selected_entry)
	_update_preview(_selected_entry)


func _details_text(entry: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Label: " + String(entry.get("label", "")))
	lines.append("Category: " + String(entry.get("category", "")))
	lines.append("Status: " + String(entry.get("status", "")))
	lines.append("Path: " + String(entry.get("path", "")))
	lines.append("Source: " + String(entry.get("source", "")))
	var tags := entry.get("tags", [])
	if tags is Array and not tags.is_empty():
		lines.append("Tags: " + ", ".join(PackedStringArray(tags)))
	var details := entry.get("details", {})
	if details is Dictionary and not details.is_empty():
		lines.append("")
		lines.append("Details:")
		for key in details.keys():
			lines.append("- %s: %s" % [str(key), str(details[key])])
	return "\n".join(PackedStringArray(lines))


func _copy_selected_path() -> void:
	var path := String(_selected_entry.get("path", ""))
	if path.is_empty():
		_status_label.text = "No selected path to copy."
		return
	DisplayServer.clipboard_set(path)
	_status_label.text = "Copied path: " + path


func _select_selected_path() -> void:
	var path := String(_selected_entry.get("path", ""))
	if not _path_can_be_selected(path):
		_status_label.text = "No selectable res:// path for this entry. Copy the path/details instead."
		return
	if _editor_interface != null and _editor_interface.has_method("select_file"):
		_editor_interface.select_file(path)
		_status_label.text = "Selected in FileSystem: " + path + " (open the FileSystem dock if the highlight is not visible)."
	else:
		_status_label.text = "EditorInterface.select_file unavailable. Copy the path instead."


func _open_selected_resource() -> void:
	var path := String(_selected_entry.get("path", ""))
	if not _path_can_be_selected(path):
		_status_label.text = "No openable res:// path for this entry. Copy the path/details instead."
		return
	if _is_previewable_texture_path(path):
		if _show_texture_preview(path):
			_status_label.text = "Previewing texture in dock: " + path
		else:
			_status_label.text = "Could not load texture preview. Copy or select its path: " + path
		return
	if path.get_extension().to_lower() == "tscn" and _editor_interface != null and _editor_interface.has_method("open_scene_from_path"):
		_editor_interface.open_scene_from_path(path)
		_status_label.text = "Opened scene: " + path
		return
	if ResourceLoader.exists(path) and _editor_interface != null and _editor_interface.has_method("edit_resource"):
		var resource := ResourceLoader.load(path)
		if resource != null:
			_editor_interface.edit_resource(resource)
			_status_label.text = "Opened resource: " + path
			return
	_status_label.text = "Open not supported for this entry. Copy or select its path."


func _path_can_be_selected(path: String) -> bool:
	if path.is_empty() or not path.begins_with("res://"):
		return false
	return FileAccess.file_exists(path) or ResourceLoader.exists(path)


func _update_preview(entry: Dictionary) -> void:
	var path := String(entry.get("path", ""))
	if not _is_previewable_texture_path(path):
		_clear_preview("No texture preview for this entry.")
		return
	if not _show_texture_preview(path):
		_clear_preview("Texture path could not be loaded for preview: " + path)


func _show_texture_preview(path: String) -> bool:
	if not _path_can_be_selected(path):
		return false
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return false
	_preview_texture.texture = texture
	_preview_label.text = "Preview: %s (%dx%d)" % [path, texture.get_width(), texture.get_height()]
	return true


func _clear_preview(message: String) -> void:
	if _preview_texture != null:
		_preview_texture.texture = null
	if _preview_label != null:
		_preview_label.text = message


func _is_previewable_texture_path(path: String) -> bool:
	return path.get_extension().to_lower() in ["png", "webp", "jpg", "jpeg"]


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
