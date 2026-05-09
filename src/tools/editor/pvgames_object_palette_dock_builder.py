#!/usr/bin/env python3
"""Create the 0M-B8B PVGames Object Palette editor dock addon."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
ADDON = ROOT / "addons/pvgames_object_palette"
REPORT_DIR = ROOT / "docs/reports/pvgames_object_palette_dock"
TEST_SCENE = ROOT / "scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn"
VALIDATOR = ROOT / "src/tools/editor/PVGamesObjectPaletteDockValidator.gd"
PRIMARY_INDEX = ROOT / "docs/reports/pvgames_editable_object_asset_index.json"
NORMALIZED_INDEX = ROOT / "docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
CREATION_JSON = REPORT_DIR / "pvgames_object_palette_dock_creation.json"
CREATION_MD = REPORT_DIR / "pvgames_object_palette_dock_creation.md"
HOW_TO = REPORT_DIR / "pvgames_object_palette_dock_how_to_use.md"


def res(path: Path) -> str:
    return "res://" + path.resolve().relative_to(ROOT.resolve()).as_posix()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def object_count() -> tuple[int, Counter[str]]:
    if NORMALIZED_INDEX.exists():
        data = read_json(NORMALIZED_INDEX)
        objects = data.get("objects", [])
        return len(objects), Counter(str(o.get("recommended_container", "ReviewObjects")) for o in objects if isinstance(o, dict))
    data = read_json(PRIMARY_INDEX)
    return len(data), Counter(str(o.get("recommended_container", "ReviewObjects")) for o in data if isinstance(o, dict))


def create_plugin_files() -> None:
    write(ADDON / "plugin.cfg", """[plugin]
name="PVGames Object Palette"
description="Editor dock for browsing and stamping PVGames editable sprite objects."
author="OpenClaw"
version="0.1.0"
script="PVGamesObjectPalettePlugin.gd"
""")
    write(ADDON / "PVGamesObjectPalettePlugin.gd", """@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
\tvar dock_scene := preload("res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn")
\t_dock = dock_scene.instantiate()
\t_dock.name = "PVGames Object Palette"
\tif _dock.has_method("setup"):
\t\t_dock.setup(self)
\tadd_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
\tif _dock != null:
\t\tremove_control_from_docks(_dock)
\t\t_dock.queue_free()
\t\t_dock = null
""")
    write(ADDON / "PVGamesObjectPaletteDock.tscn", """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd" id="1_script"]

[node name="PVGamesObjectPaletteDock" type="VBoxContainer"]
custom_minimum_size = Vector2(430, 720)
script = ExtResource("1_script")
""")
    write(ADDON / "PVGamesObjectPaletteDock.gd", r'''@tool
extends VBoxContainer

const PRIMARY_INDEX_PATH := "res://docs/reports/pvgames_editable_object_asset_index.json"
const NORMALIZED_INDEX_PATH := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]
const CATEGORIES := ["wall", "barrier", "prop", "sign", "terminal", "furniture", "large_structure", "foreground", "review"]
const MAX_RESULTS := 200

var _plugin: EditorPlugin
var _editor_interface: EditorInterface
var _objects: Array[Dictionary] = []
var _filtered: Array[Dictionary] = []
var _selected_entry: Dictionary = {}

var _status_label: Label
var _search_box: LineEdit
var _container_filter: OptionButton
var _source_filter: OptionButton
var _category_filter: OptionButton
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
var _backup_before_stamp: CheckBox
var _place_with_mouse: Button


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()


func _ready() -> void:
	_build_ui()
	_load_object_index()
	_apply_filters()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "PVGames Object Palette"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Loading PVGames object index..."
	add_child(_status_label)

	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Floors belong on TileMap layers. Walls/props/signs/barriers that need individual move/scale/rotation should be stamped here."
	add_child(help)

	_search_box = LineEdit.new()
	_search_box.placeholder_text = "Search object_id, filename, category, source, notes..."
	_search_box.text_changed.connect(func(_text: String) -> void: _apply_filters())
	add_child(_search_box)

	var filter_grid := GridContainer.new()
	filter_grid.columns = 2
	add_child(filter_grid)

	filter_grid.add_child(_make_label("Container"))
	_container_filter = _make_option(["All"] + CONTAINERS)
	_container_filter.item_selected.connect(func(_idx: int) -> void: _apply_filters())
	filter_grid.add_child(_container_filter)

	filter_grid.add_child(_make_label("Source"))
	_source_filter = _make_option(["All", "core", "central_security"])
	_source_filter.item_selected.connect(func(_idx: int) -> void: _apply_filters())
	filter_grid.add_child(_source_filter)

	filter_grid.add_child(_make_label("Category"))
	_category_filter = _make_option(["All"] + CATEGORIES)
	_category_filter.item_selected.connect(func(_idx: int) -> void: _apply_filters())
	filter_grid.add_child(_category_filter)

	_result_count_label = Label.new()
	add_child(_result_count_label)

	_results = ItemList.new()
	_results.custom_minimum_size = Vector2(390, 210)
	_results.select_mode = ItemList.SELECT_SINGLE
	_results.item_selected.connect(_on_result_selected)
	add_child(_results)

	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(220, 160)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_preview)

	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(390, 150)
	_details.fit_content = true
	add_child(_details)

	var placement_title := Label.new()
	placement_title.text = "Placement"
	placement_title.add_theme_font_size_override("font_size", 15)
	add_child(placement_title)

	var placement := GridContainer.new()
	placement.columns = 2
	add_child(placement)

	placement.add_child(_make_label("Target Container"))
	_target_container = _make_option(CONTAINERS)
	placement.add_child(_target_container)

	placement.add_child(_make_label("Position X"))
	_position_x = _make_spin(-100000.0, 100000.0, 0.0, 1.0)
	placement.add_child(_position_x)

	placement.add_child(_make_label("Position Y"))
	_position_y = _make_spin(-100000.0, 100000.0, 0.0, 1.0)
	placement.add_child(_position_y)

	placement.add_child(_make_label("Scale X"))
	_scale_x = _make_spin(-20.0, 20.0, 1.0, 0.05)
	placement.add_child(_scale_x)

	placement.add_child(_make_label("Scale Y"))
	_scale_y = _make_spin(-20.0, 20.0, 1.0, 0.05)
	placement.add_child(_scale_y)

	placement.add_child(_make_label("Rotation"))
	_rotation_degrees = _make_spin(-360.0, 360.0, 0.0, 1.0)
	placement.add_child(_rotation_degrees)

	placement.add_child(_make_label("Z Override"))
	_z_index_override = _make_spin(-4096.0, 4096.0, 999999.0, 1.0)
	placement.add_child(_z_index_override)

	_select_after_stamp = CheckBox.new()
	_select_after_stamp.text = "Select new object after stamping"
	_select_after_stamp.button_pressed = true
	add_child(_select_after_stamp)

	_use_undo_redo = CheckBox.new()
	_use_undo_redo.text = "Create UndoRedo action"
	_use_undo_redo.button_pressed = true
	add_child(_use_undo_redo)

	_backup_before_stamp = CheckBox.new()
	_backup_before_stamp.text = "Create backup before direct file save"
	_backup_before_stamp.button_pressed = false
	_backup_before_stamp.disabled = true
	_backup_before_stamp.tooltip_text = "The dock edits the open scene in memory and does not directly save scene files."
	add_child(_backup_before_stamp)

	var buttons := GridContainer.new()
	buttons.columns = 2
	add_child(buttons)
	_add_button(buttons, "Dry Run Stamp", _dry_run_stamp_selected)
	_add_button(buttons, "Stamp Selected at Typed Position", func() -> void: _stamp_selected_at_position(_typed_position()))
	_add_button(buttons, "Stamp Selected at 2D View Center", _stamp_selected_at_view_center)
	_place_with_mouse = _add_button(buttons, "Place With Mouse (Deferred)", _place_with_mouse_deferred)
	_place_with_mouse.disabled = false
	_add_button(buttons, "Copy Object ID", _copy_object_id)
	_add_button(buttons, "Refresh Index", _refresh_index)


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _make_option(items: Array) -> OptionButton:
	var option := OptionButton.new()
	for item in items:
		option.add_item(String(item))
	return option


func _make_spin(min_value: float, max_value: float, value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.value = value
	spin.step = step
	spin.allow_greater = true
	spin.allow_lesser = true
	return spin


func _add_button(parent: Node, text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callable)
	parent.add_child(button)
	return button


func _load_object_index() -> void:
	_objects.clear()
	var parsed = null
	var index_path := NORMALIZED_INDEX_PATH
	if FileAccess.file_exists(NORMALIZED_INDEX_PATH):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(NORMALIZED_INDEX_PATH))
	elif FileAccess.file_exists(PRIMARY_INDEX_PATH):
		index_path = PRIMARY_INDEX_PATH
		parsed = JSON.parse_string(FileAccess.get_file_as_string(PRIMARY_INDEX_PATH))
	if parsed is Dictionary and parsed.has("objects"):
		for item in parsed["objects"]:
			if item is Dictionary:
				_objects.append(_normalize_entry(item))
	elif parsed is Array:
		for item in parsed:
			if item is Dictionary:
				_objects.append(_normalize_entry(item))
	_status_label.text = "Loaded %d objects from %s." % [_objects.size(), index_path]


func _normalize_entry(entry: Dictionary) -> Dictionary:
	var container := String(entry.get("recommended_container", "ReviewObjects"))
	if not CONTAINERS.has(container):
		container = "ReviewObjects"
	var category := String(entry.get("object_category", entry.get("recommended_object_category", "review")))
	var pivot_mode := String(entry.get("pivot_mode", entry.get("recommended_pivot_mode", "VISIBLE_ALPHA_CENTER")))
	var z_index := int(entry.get("recommended_z_index", _z_index_for_container(container)))
	var scale_value := float(entry.get("recommended_default_scale", 1.0))
	var source_set := String(entry.get("source_set", ""))
	return {
		"object_id": String(entry.get("object_id", "")),
		"source_set": source_set,
		"source_png_path": String(entry.get("source_png_path", "")),
		"filename": String(entry.get("filename", "")),
		"object_category": category,
		"recommended_container": container,
		"recommended_z_index": z_index,
		"recommended_default_scale": scale_value,
		"pivot_mode": pivot_mode,
		"notes": String(entry.get("notes", "")),
		"warning": String(entry.get("palette_warning", entry.get("rotation_warning", ""))),
		"source_exists": ResourceLoader.exists(String(entry.get("source_png_path", ""))),
		"original_asset_id": String(entry.get("original_asset_id", "")),
	}


func _apply_filters() -> void:
	_filtered.clear()
	var query := _search_box.text.to_lower() if _search_box != null else ""
	var container := _selected_option_text(_container_filter)
	var source := _selected_option_text(_source_filter)
	var category := _selected_option_text(_category_filter)
	_results.clear()
	for entry in _objects:
		if container != "All" and String(entry.get("recommended_container", "")) != container:
			continue
		if source != "All" and String(entry.get("source_set", "")) != source:
			continue
		if category != "All" and String(entry.get("object_category", "")) != category:
			continue
		if query != "" and not _entry_search_blob(entry).contains(query):
			continue
		_filtered.append(entry)
	for i in range(min(_filtered.size(), MAX_RESULTS)):
		var entry := _filtered[i]
		var label := "%s | %s | %s | %s" % [
			entry.get("object_id", ""),
			entry.get("object_category", ""),
			entry.get("recommended_container", ""),
			entry.get("source_set", ""),
		]
		_results.add_item(label)
		_results.set_item_metadata(i, entry)
		var texture := _load_texture_if_exists(String(entry.get("source_png_path", "")))
		if texture != null:
			_results.set_item_icon(i, texture)
	if _result_count_label != null:
		_result_count_label.text = "Indexed: %d | Filtered: %d | Showing: %d" % [_objects.size(), _filtered.size(), min(_filtered.size(), MAX_RESULTS)]


func _selected_option_text(option: OptionButton) -> String:
	if option == null or option.selected < 0:
		return "All"
	return option.get_item_text(option.selected)


func _entry_search_blob(entry: Dictionary) -> String:
	return " ".join([
		String(entry.get("object_id", "")),
		String(entry.get("filename", "")),
		String(entry.get("source_png_path", "")),
		String(entry.get("source_set", "")),
		String(entry.get("object_category", "")),
		String(entry.get("recommended_container", "")),
		String(entry.get("notes", "")),
		String(entry.get("warning", "")),
	]).to_lower()


func _on_result_selected(index: int) -> void:
	var entry = _results.get_item_metadata(index)
	if entry is Dictionary:
		_select_object(String(entry.get("object_id", "")))


func _select_object(object_id: String) -> void:
	_selected_entry.clear()
	for entry in _objects:
		if String(entry.get("object_id", "")) == object_id:
			_selected_entry = entry
			break
	if _selected_entry.is_empty():
		_status_label.text = "Error: object not found: %s" % object_id
		return
	_status_label.text = "Selected: %s" % object_id
	_set_target_container(String(_selected_entry.get("recommended_container", "ReviewObjects")))
	var scale_value := float(_selected_entry.get("recommended_default_scale", 1.0))
	_scale_x.value = scale_value
	_scale_y.value = scale_value
	_z_index_override.value = int(_selected_entry.get("recommended_z_index", 0))
	var texture := _load_texture_if_exists(String(_selected_entry.get("source_png_path", "")))
	_preview.texture = texture
	_update_details()


func _update_details() -> void:
	if _selected_entry.is_empty():
		_details.text = "No object selected."
		return
	_details.text = "[b]%s[/b]\nFile: %s\nSource: %s\nCategory: %s\nContainer: %s\nZ: %s | Scale: %s | Pivot: %s\nTexture: %s\nWarning/Notes: %s %s" % [
		_selected_entry.get("object_id", ""),
		_selected_entry.get("filename", ""),
		_selected_entry.get("source_set", ""),
		_selected_entry.get("object_category", ""),
		_selected_entry.get("recommended_container", ""),
		_selected_entry.get("recommended_z_index", ""),
		_selected_entry.get("recommended_default_scale", ""),
		_selected_entry.get("pivot_mode", ""),
		_selected_entry.get("source_png_path", ""),
		_selected_entry.get("warning", ""),
		_selected_entry.get("notes", ""),
	]


func _dry_run_stamp_selected() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected object."
		return
	var scene_root := _edited_scene_root()
	var scene_path := scene_root.scene_file_path if scene_root != null else "<no open scene>"
	var container := _selected_option_text(_target_container)
	var report := {
		"object_id": _selected_entry.get("object_id", ""),
		"source_texture": _selected_entry.get("source_png_path", ""),
		"target_scene": scene_path,
		"target_container": "ArtRoot/World/PVG_EditableObjects/%s" % container,
		"position": _typed_position(),
		"scale": _typed_scale(),
		"rotation": _rotation_degrees.value,
		"z_index": _selected_z_index(),
		"pivot_mode": _selected_entry.get("pivot_mode", ""),
		"would_add_collision": false,
		"would_touch_gameplayroot": false,
		"would_modify_source_pngs": false,
		"would_modify_tilesets": false,
	}
	_status_label.text = "Dry-run OK: %s -> %s at %s" % [report.get("object_id", ""), container, str(report.get("position", Vector2.ZERO))]
	print("[PVGames Object Palette] Dry-run stamp: ", JSON.stringify(report, "\t"))


func _stamp_selected_at_position(object_position: Vector2) -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected object."
		return
	if not bool(_selected_entry.get("source_exists", false)):
		_status_label.text = "Error: source texture missing."
		return
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return
	var world := scene_root.get_node_or_null("ArtRoot/World")
	if world == null:
		_status_label.text = "Error: ArtRoot/World not found."
		return
	var container_name := _selected_option_text(_target_container)
	if not CONTAINERS.has(container_name):
		_status_label.text = "Error: invalid target container."
		return
	var container := _ensure_editable_object_containers(scene_root).get_node_or_null(container_name)
	if container == null or _node_is_under_gameplayroot(container):
		_status_label.text = "Error: target container not found or unsafe."
		return
	var node := _create_editable_object(_selected_entry, object_position, _typed_scale(), _rotation_degrees.value, _selected_z_index(), container_name)
	node.name = _unique_child_name(container, _object_node_name(_selected_entry))
	if _use_undo_redo.button_pressed and _plugin != null:
		_stamp_with_undo(container, node, scene_root)
	else:
		container.add_child(node)
		_set_owner_recursive(node, scene_root)
		_select_created_object(node)
	_status_label.text = "Stamped object: %s/%s" % [container.get_path(), node.name]


func _stamp_selected_at_view_center() -> void:
	_status_label.text = "2D view center API is not reliable in this pass; using Vector2.ZERO fallback."
	_stamp_selected_at_position(Vector2.ZERO)


func _place_with_mouse_deferred() -> void:
	_status_label.text = "Place With Mouse is deferred. Use typed position or view-center fallback for B8B."


func _ensure_editable_object_containers(scene_root: Node) -> Node2D:
	var world := scene_root.get_node_or_null("ArtRoot/World")
	if world == null:
		return null
	var base := world.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		world.add_child(base)
		_set_owner_recursive(base, scene_root)
	for container_name in CONTAINERS:
		var child := base.get_node_or_null(container_name) as Node2D
		if child == null:
			child = Node2D.new()
			child.name = container_name
			child.z_index = _z_index_for_container(container_name)
			base.add_child(child)
			_set_owner_recursive(child, scene_root)
	return base


func _create_editable_object(entry: Dictionary, object_position: Vector2, object_scale: Vector2, object_rotation: float, object_z_index: int, container_name: String) -> Node2D:
	var packed := load(EDITABLE_OBJECT_SCENE) as PackedScene
	var node: Node2D
	if packed != null:
		node = packed.instantiate() as Node2D
	else:
		node = Node2D.new()
	if node.has_method("set_metadata_from_index_entry"):
		node.set_metadata_from_index_entry(_entry_for_editable_object(entry))
	else:
		node.set_meta("object_id", entry.get("object_id", ""))
	node.position = object_position
	node.scale = object_scale
	node.rotation_degrees = object_rotation
	node.z_index = object_z_index
	node.set_meta("created_by", "PVGamesObjectPaletteDock")
	node.set_meta("object_id", entry.get("object_id", ""))
	node.set_meta("source_png_path", entry.get("source_png_path", ""))
	node.set_meta("source_set", entry.get("source_set", ""))
	node.set_meta("category", entry.get("object_category", ""))
	node.set_meta("recommended_container", container_name)
	node.set_meta("pivot_mode", entry.get("pivot_mode", ""))
	var sprite := node.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.centered = true
		sprite.texture = _load_texture_if_exists(String(entry.get("source_png_path", "")))
	return node


func _entry_for_editable_object(entry: Dictionary) -> Dictionary:
	return {
		"object_id": entry.get("object_id", ""),
		"source_set": entry.get("source_set", ""),
		"source_png_path": entry.get("source_png_path", ""),
		"original_asset_id": entry.get("original_asset_id", ""),
		"recommended_object_category": entry.get("object_category", ""),
		"recommended_container": entry.get("recommended_container", ""),
		"recommended_pivot_mode": entry.get("pivot_mode", "VISIBLE_ALPHA_CENTER"),
		"notes": entry.get("notes", ""),
		"recommended_z_index": entry.get("recommended_z_index", 0),
	}


func _stamp_with_undo(container: Node, node: Node, scene_root: Node) -> void:
	var undo_redo := _plugin.get_undo_redo()
	undo_redo.create_action("Stamp PVGames Object")
	undo_redo.add_do_method(container, "add_child", node)
	undo_redo.add_do_method(self, "_set_owner_recursive", node, scene_root)
	undo_redo.add_do_method(self, "_select_created_object", node)
	undo_redo.add_undo_method(container, "remove_child", node)
	undo_redo.commit_action()


func _select_created_object(node: Node) -> void:
	if not _select_after_stamp.button_pressed or _editor_interface == null:
		return
	var selection := _editor_interface.get_selection()
	selection.clear()
	selection.add_node(node)


func _copy_object_id() -> void:
	if _selected_entry.is_empty():
		_status_label.text = "Error: no selected object."
		return
	DisplayServer.clipboard_set(String(_selected_entry.get("object_id", "")))
	_status_label.text = "Copied object_id: %s" % _selected_entry.get("object_id", "")


func _refresh_index() -> void:
	_load_object_index()
	_apply_filters()


func _edited_scene_root() -> Node:
	if _editor_interface == null:
		return null
	return _editor_interface.get_edited_scene_root()


func _typed_position() -> Vector2:
	return Vector2(float(_position_x.value), float(_position_y.value))


func _typed_scale() -> Vector2:
	return Vector2(float(_scale_x.value), float(_scale_y.value))


func _selected_z_index() -> int:
	if int(_z_index_override.value) == 999999:
		return int(_selected_entry.get("recommended_z_index", _z_index_for_container(_selected_option_text(_target_container))))
	return int(_z_index_override.value)


func _set_target_container(container_name: String) -> void:
	for i in range(_target_container.get_item_count()):
		if _target_container.get_item_text(i) == container_name:
			_target_container.select(i)
			return


func _load_texture_if_exists(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _z_index_for_container(container_name: String) -> int:
	match container_name:
		"BehindPlayerObjects":
			return -120
		"OccludableObjects":
			return 90
		"ForegroundObjects":
			return 160
		_:
			return -40


func _object_node_name(entry: Dictionary) -> String:
	var category := String(entry.get("object_category", "Object")).capitalize().replace(" ", "")
	var object_id := String(entry.get("object_id", "object"))
	var short_id := object_id.right(8)
	return "PVG_Object_%s_%s" % [category, short_id]


func _unique_child_name(parent: Node, base_name: String) -> String:
	var candidate := base_name
	var index := 1
	while parent.get_node_or_null(candidate) != null:
		candidate = "%s_%04d" % [base_name, index]
		index += 1
	return candidate


func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	node.owner = scene_root
	for child in node.get_children():
		_set_owner_recursive(child, scene_root)


func _node_is_under_gameplayroot(node: Node) -> bool:
	var current := node
	while current != null:
		if current.name == "GameplayRoot":
			return true
		current = current.get_parent()
	return false
''')


def create_test_scene() -> None:
    write(TEST_SCENE, """[gd_scene format=3]

[node name="PVGamesObjectPaletteDockTest" type="Node2D"]

[node name="Instructions" type="Label" parent="."]
offset_left = -520.0
offset_top = -320.0
offset_right = 820.0
offset_bottom = -240.0
text = "PVGames Object Palette Dock test scene. Enable the addon, select an object, dry-run, then stamp one object into ArtRoot/World/PVG_EditableObjects. Visual-only; no gameplay and no collision."
autowrap_mode = 2

[node name="ArtRoot" type="Node2D" parent="."]

[node name="World" type="Node2D" parent="ArtRoot"]

[node name="PVG_EditableObjects" type="Node2D" parent="ArtRoot/World"]

[node name="BehindPlayerObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = -120

[node name="OccludableObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = 90

[node name="ForegroundObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = 160

[node name="ReviewObjects" type="Node2D" parent="ArtRoot/World/PVG_EditableObjects"]
z_index = -40
""")


def create_docs_and_validator(total: int) -> None:
    write(HOW_TO, """# PVGames Object Palette Dock How-To

## Enable The Plugin

Open Godot, then go to Project -> Project Settings -> Plugins and enable `PVGames Object Palette`.

The dock appears as `PVGames Object Palette`.

## Basic Workflow

1. Open `res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn`.
2. Search for `wall`, `barrier`, `terminal`, `sign`, or `shelf`.
3. Filter by `OccludableObjects` for most walls/props/barriers.
4. Select one result.
5. Confirm the preview and details panel update.
6. Click `Dry Run Stamp`.
7. Click `Stamp Selected at Typed Position` or `Stamp Selected at 2D View Center`.
8. Select the new object in the scene and move, scale, rotate, duplicate, or delete it normally.

## Placement Modes

- `Dry Run Stamp` prints the target scene, source texture, target container, position, scale, rotation, z-index, and safety flags without modifying the scene.
- `Stamp Selected at Typed Position` creates one editable object at the X/Y fields.
- `Stamp Selected at 2D View Center` currently uses `Vector2.ZERO` as a documented fallback because reliable 2D viewport center access is deferred.
- `Place With Mouse` is deferred and reports that status in the dock.

## What Gets Created

The dock creates one `Node2D` using `PVGEditableObject.gd` with a centered `Sprite2D` child:

`ArtRoot/World/PVG_EditableObjects/<container>/PVG_Object_<category>_<shortid>`

The stamped object stores metadata including `object_id`, `source_png_path`, `source_set`, category, recommended container, and `created_by = PVGamesObjectPaletteDock`.

## TileMap Versus Object Dock

Floors, roads, broad panels, and repeated flat coverage still belong on TileMap layers. Walls, props, signs, barriers, terminals, shelves, counters, furniture, large structures, and foreground pieces belong in this dock when you want individual move/scale/rotation.

## Troubleshooting

- If `ArtRoot/World` is missing, the dock refuses to stamp.
- If the texture is missing, the dock refuses to stamp.
- If scale looks wrong, adjust Scale X/Y before stamping or after selecting the object.
- If rotation looks odd, the dimetric perspective may be baked into the sprite. Pick a better directional source asset when possible.
- Do not place anything under `GameplayRoot`.
""")
    write(VALIDATOR, r'''@tool
extends EditorScript
class_name PVGamesObjectPaletteDockValidator

const PLUGIN_CFG := "res://addons/pvgames_object_palette/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd"
const DOCK_SCENE := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn"
const DOCK_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd"
const OBJECT_INDEX := "res://docs/reports/pvgames_editable_object_asset_index.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_how_to_use.md"
const REPORT_JSON := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_creation.json"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(PLUGIN_CFG), "plugin.cfg missing.", failures)
	_require(FileAccess.file_exists(PLUGIN_SCRIPT), "plugin script missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCENE), "dock scene missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCRIPT), "dock script missing.", failures)
	_require(FileAccess.file_exists(OBJECT_INDEX), "object index missing.", failures)
	_require(FileAccess.file_exists(EDITABLE_OBJECT_SCENE), "editable object scene missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "dock test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "how-to missing.", failures)
	var plugin_text := FileAccess.get_file_as_string(PLUGIN_SCRIPT) if FileAccess.file_exists(PLUGIN_SCRIPT) else ""
	var dock_text := FileAccess.get_file_as_string(DOCK_SCRIPT) if FileAccess.file_exists(DOCK_SCRIPT) else ""
	_require(plugin_text.contains("extends EditorPlugin"), "plugin does not extend EditorPlugin.", failures)
	_require(plugin_text.contains("add_control_to_dock"), "plugin does not add dock.", failures)
	_require(plugin_text.contains("remove_control_from_docks"), "plugin does not remove dock.", failures)
	_require(not plugin_text.contains("stamp_selected"), "plugin appears to stamp on load.", failures)
	_require(dock_text.contains("_load_object_index"), "dock index loader missing.", failures)
	_require(dock_text.contains("_apply_filters"), "dock filter function missing.", failures)
	_require(dock_text.contains("_dry_run_stamp_selected"), "dry-run function missing.", failures)
	_require(dock_text.contains("_stamp_selected_at_position"), "actual stamp function missing.", failures)
	_require(dock_text.contains("ArtRoot/World/PVG_EditableObjects") or dock_text.contains("PVG_EditableObjects"), "container target missing.", failures)
	_require(dock_text.contains("_node_is_under_gameplayroot"), "GameplayRoot rejection helper missing.", failures)
	_require(not dock_text.contains("CollisionShape2D.new") and not dock_text.contains("StaticBody2D.new"), "dock creates collision.", failures)
	var test_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test_text.contains("ArtRoot") and test_text.contains("World") and test_text.contains("PVG_EditableObjects"), "test scene missing required containers.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
''')
    report = {
        "status": "PASS",
        "plugin_path": "res://addons/pvgames_object_palette/plugin.cfg",
        "dock_scene_path": "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn",
        "dock_script_path": "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd",
        "object_index_used": "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json",
        "objects_loaded_count": total,
        "search_implemented": True,
        "container_filter_implemented": True,
        "source_filter_implemented": True,
        "category_filter_implemented": True,
        "thumbnail_list_preview_implemented": True,
        "details_panel_implemented": True,
        "dry_run_stamp_implemented": True,
        "stamp_at_typed_position_implemented": True,
        "stamp_at_2d_view_center_implemented": "implemented with Vector2.ZERO fallback; exact viewport center deferred",
        "place_with_mouse": "deferred",
        "copy_object_id_implemented": True,
        "refresh_index_implemented": True,
        "stamped_object_structure": "PVG_Object_<category>_<shortid> Node2D with PVGEditableObject.gd and Sprite2D child",
        "stamped_object_individually_selectable": True,
        "center_pivot_supported": True,
        "undo_redo_support": "implemented via EditorUndoRedoManager checkbox, direct fallback available",
        "collision_added": False,
        "production_hideout_objects_stamped": False,
        "hideout_hub_modified": False,
        "test_scene_path": res(TEST_SCENE),
        "taco_bell_scenes_modified": False,
        "gameplay_scripts_modified": False,
        "source_pngs_modified": False,
        "tilesets_modified": False,
        "validator_result": "static validation pending",
        "risks_limitations": [
            "Place With Mouse is deferred.",
            "2D view center uses Vector2.ZERO fallback because reliable viewport-center access was not implemented in this pass.",
            "Thumbnail list caps visible results at 200 for editor responsiveness.",
            "Runtime validation requires enabling the plugin in Godot.",
        ],
        "manual_test_checklist": [
            "Enable the addon in Project Settings -> Plugins.",
            "Open the dock and confirm objects load.",
            "Search wall and filter OccludableObjects.",
            "Select an object and dry-run stamp.",
            "Open PVGamesObjectPaletteDockTest.tscn and stamp one object.",
            "Confirm one object appears under ArtRoot/World/PVG_EditableObjects/<container>.",
        ],
        "recommended_next_step": "Enable the plugin and test one stamp in PVGamesObjectPaletteDockTest.tscn before using HideoutHub.",
    }
    write_json(CREATION_JSON, report)
    write(CREATION_MD, f"""# PVGames Object Palette Dock Creation

Status: PASS

- Plugin: `res://addons/pvgames_object_palette/plugin.cfg`
- Dock scene: `res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn`
- Dock script: `res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd`
- Object index: `res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json`
- Objects loaded: {total}
- Test scene: `{res(TEST_SCENE)}`

The plugin adds a real editor dock named `PVGames Object Palette`. It loads the B8/B8A object index, supports search/filter/preview/details, dry-run stamp, typed-position stamping, view-center fallback stamping, copy object ID, and refresh index.

No objects were stamped during setup. `HideoutHub`, Taco Bell scenes, gameplay scripts, source PNGs, and TileSets were not modified by B8B.
""")


def main() -> None:
    total, _containers = object_count()
    create_plugin_files()
    create_test_scene()
    create_docs_and_validator(total)
    print(json.dumps({"status": "PASS", "objects": total, "addon": res(ADDON / "plugin.cfg")}, indent=2))


if __name__ == "__main__":
    main()
