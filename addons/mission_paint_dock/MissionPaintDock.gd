@tool
extends VBoxContainer

const MODE_VISUAL := "Visual Paint"
const MODE_LAYOUT := "Layout Blockout"
const MODE_COLLISION := "Collision Barrier"

const BLOCKOUT_TILESET := "res://assets/tilesets/iso_blockout_clean/IsoBlockoutTileset_Clean.tres"
const MARKER_TILESET := "res://assets/tilesets/marker_authoring/MarkerAuthoringTileset.tres"

const LAYOUT_LAYER_PRESETS: Array[Dictionary] = [
	{"id": "floor", "label": "FloorLayer (white floor)", "path": "GameplayRoot/LayoutRoot/FloorLayer", "mode": MODE_LAYOUT},
	{"id": "wall", "label": "WallLayer (black wall)", "path": "GameplayRoot/LayoutRoot/WallLayer", "mode": MODE_LAYOUT},
	{"id": "cover", "label": "CoverLayer (cover hint)", "path": "GameplayRoot/LayoutRoot/CoverLayer", "mode": MODE_LAYOUT},
	{"id": "marker", "label": "MarkerTileLayer (markers)", "path": "GameplayRoot/LayoutRoot/MarkerTileLayer", "mode": MODE_LAYOUT},
	{"id": "collision_barrier", "label": "CollisionBarrierLayer", "path": "GameplayRoot/LayoutRoot/CollisionBarrierLayer", "mode": MODE_COLLISION},
]

const FORBIDDEN_TARGET_FRAGMENTS: Array[String] = [
	"GeneratedRuntimeCollision",
	"GameplayCollisionLayer",
	"GameplayFloorLayer",
	"GameplayMarkersLayer",
	"DebugLabelLayer",
]

var _plugin: EditorPlugin
var _editor_interface: EditorInterface

var _status_label: Label
var _mode_option: OptionButton
var _unlock_layout: CheckBox
var _unlock_collision: CheckBox
var _collision_warning: Label
var _target_layer_option: OptionButton
var _tile_preset_option: OptionButton
var _operation_option: OptionButton
var _arm_paint: CheckBox
var _brush_size_spin: SpinBox
var _debug_readout: Label

var _visual_layer_paths: Array[String] = []
var _tile_presets: Array[Dictionary] = []
var _stroke_active := false
var _stroke_changes: Array[Dictionary] = []
var _stroke_touched_cells: Dictionary = {}
var _stroke_erase := false
var _stroke_mouse_button: int = -1


func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_editor_interface = plugin.get_editor_interface()


func _ready() -> void:
	_build_ui()
	_rebuild_tile_presets()
	_refresh_scene_layers()


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Mission Paint Dock"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(360, 48)
	add_child(_status_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(360, 0)
	scroll.add_child(content)
	content.add_child(_heading("Mode"))
	_mode_option = _option([MODE_VISUAL, MODE_LAYOUT, MODE_COLLISION])
	_mode_option.item_selected.connect(func(_i: int) -> void: _on_mode_changed())
	content.add_child(_mode_option)
	_unlock_layout = CheckBox.new()
	_unlock_layout.text = "Unlock Layout Blockout Painting"
	_unlock_layout.toggled.connect(func(_e: bool) -> void: _update_status())
	content.add_child(_unlock_layout)
	_unlock_collision = CheckBox.new()
	_unlock_collision.text = "Unlock Collision Barrier Painting"
	_unlock_collision.toggled.connect(func(_e: bool) -> void: _update_status())
	content.add_child(_unlock_collision)
	_collision_warning = Label.new()
	_collision_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_collision_warning.text = "Collision barrier painting can affect runtime blockers and movement. Validate after edits."
	content.add_child(_collision_warning)
	content.add_child(_heading("Target / Tile"))
	var grid := GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	grid.add_child(_label("Target Layer"))
	_target_layer_option = OptionButton.new()
	_target_layer_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_layer_option.item_selected.connect(func(_i: int) -> void: _update_status())
	grid.add_child(_target_layer_option)
	grid.add_child(_label("Tile Preset"))
	_tile_preset_option = OptionButton.new()
	_tile_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tile_preset_option.item_selected.connect(func(_i: int) -> void: _update_status())
	grid.add_child(_tile_preset_option)
	grid.add_child(_label("Operation"))
	_operation_option = _option(["Paint", "Erase"])
	grid.add_child(_operation_option)
	grid.add_child(_label("Brush Size"))
	_brush_size_spin = _spin(1, 8, 1, 1)
	grid.add_child(_brush_size_spin)
	_arm_paint = CheckBox.new()
	_arm_paint.text = "Arm Paint Tool"
	_arm_paint.toggled.connect(_on_arm_paint_toggled)
	content.add_child(_arm_paint)
	_debug_readout = Label.new()
	_debug_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_debug_readout)
	content.add_child(_heading("Actions"))
	var buttons := GridContainer.new()
	buttons.columns = 1
	content.add_child(buttons)
	_button(buttons, "Refresh Scene Layers", _refresh_scene_layers)
	_button(buttons, "Dry Run Target", _dry_run_target)
	_button(buttons, "Select Target Layer", _select_target_layer)
	_button(buttons, "Disarm", _disarm_paint_tool)
	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = "Visual Paint is the safe default for ArtRoot TileMapLayers. Layout Blockout edits GameplayRoot/LayoutRoot floor/wall/cover/marker layers. Collision Barrier mode can affect movement; no StaticBody2D/Area2D nodes are created. One UndoRedo action per stroke."
	content.add_child(help)
	_update_status()


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _option(items: Array) -> OptionButton:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in items:
		option.add_item(String(item))
	return option


func _spin(min_value: float, max_value: float, value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.value = value
	spin.step = step
	return spin


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _on_mode_changed() -> void:
	_refresh_target_layer_options()
	_update_status()


func _on_arm_paint_toggled(armed: bool) -> void:
	if not armed:
		_cancel_stroke()
	_update_status()


func _disarm_paint_tool() -> void:
	_arm_paint.button_pressed = false


func _rebuild_tile_presets() -> void:
	_tile_presets = [
		{"id": "floor_white", "label": "Floor (white)", "tileset_path": BLOCKOUT_TILESET, "source_id": 0, "atlas": Vector2i(0, 0), "alternative": 0, "verified": true},
		{"id": "wall_black", "label": "Wall (black)", "tileset_path": BLOCKOUT_TILESET, "source_id": 0, "atlas": Vector2i(1, 0), "alternative": 0, "verified": true},
		{"id": "cover", "label": "Cover", "tileset_path": BLOCKOUT_TILESET, "source_id": 0, "atlas": Vector2i(2, 0), "alternative": 0, "verified": true},
		{"id": "collision_barrier", "label": "Collision Barrier", "tileset_path": BLOCKOUT_TILESET, "source_id": 0, "atlas": Vector2i(1, 0), "alternative": 0, "verified": true},
		{"id": "marker_obj", "label": "Marker OBJ", "tileset_path": MARKER_TILESET, "source_id": 0, "atlas": Vector2i(0, 0), "alternative": 0, "verified": true},
		{"id": "eraser", "label": "Eraser", "tileset_path": "", "source_id": -1, "atlas": Vector2i(-1, -1), "alternative": 0, "verified": true},
	]
	_refresh_tile_preset_options()


func _refresh_tile_preset_options() -> void:
	_tile_preset_option.clear()
	for preset in _tile_presets:
		_tile_preset_option.add_item(String(preset.label))
		_tile_preset_option.set_item_metadata(_tile_preset_option.item_count - 1, preset)


func _refresh_scene_layers() -> void:
	_visual_layer_paths.clear()
	var scene_root := _edited_scene_root()
	if scene_root != null:
		var art_root := scene_root.get_node_or_null("ArtRoot")
		if art_root != null:
			_collect_visual_tilemap_layers(art_root, "ArtRoot")
	_refresh_target_layer_options()
	_update_status()


func _collect_visual_tilemap_layers(node: Node, prefix: String) -> void:
	for child in node.get_children():
		var child_path := "%s/%s" % [prefix, child.name]
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			if not layer.collision_enabled and not _path_is_forbidden(child_path):
				_visual_layer_paths.append(child_path)
		_collect_visual_tilemap_layers(child, child_path)


func _refresh_target_layer_options() -> void:
	_target_layer_option.clear()
	var mode := _selected_mode()
	if mode == MODE_VISUAL:
		for path in _visual_layer_paths:
			_target_layer_option.add_item(path)
			_target_layer_option.set_item_metadata(_target_layer_option.item_count - 1, {"path": path, "mode": MODE_VISUAL})
	elif mode == MODE_LAYOUT:
		for preset in LAYOUT_LAYER_PRESETS:
			if preset.mode == MODE_LAYOUT:
				_target_layer_option.add_item(String(preset.label))
				_target_layer_option.set_item_metadata(_target_layer_option.item_count - 1, preset)
	elif mode == MODE_COLLISION:
		for preset in LAYOUT_LAYER_PRESETS:
			if preset.mode == MODE_COLLISION:
				_target_layer_option.add_item(String(preset.label))
				_target_layer_option.set_item_metadata(_target_layer_option.item_count - 1, preset)


func _dry_run_target() -> void:
	var layer := _resolve_target_layer()
	if layer == null:
		return
	var preset := _selected_tile_preset()
	var ok_preset := _tile_preset_valid_for_layer(layer, preset)
	_status_label.text = "Dry-run OK: %s | tile %s | preset valid=%s" % [layer.get_path(), preset.get("label", "?"), ok_preset]
	_update_debug_readout(layer, preset)


func _select_target_layer() -> void:
	var layer := _resolve_target_layer()
	if layer == null:
		return
	if _editor_interface != null:
		_editor_interface.get_selection().clear()
		_editor_interface.get_selection().add_node(layer)
	_status_label.text = "Selected: %s" % layer.get_path()


func handle_canvas_gui_input(event: InputEvent) -> bool:
	if not _arm_paint.button_pressed:
		return false
	if _stroke_active:
		return _handle_stroke_input(event)
	if not _can_paint(false):
		return false
	return _handle_stroke_input(event)


func _handle_stroke_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and _stroke_active:
			_cancel_stroke()
			return true
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				if not _stroke_active:
					if not _can_paint(true):
						return false
					_begin_stroke(true, MOUSE_BUTTON_RIGHT)
					_apply_paint_at_mouse(mouse_event)
					return true
				return _stroke_active
			if _stroke_active and _stroke_mouse_button == MOUSE_BUTTON_RIGHT:
				_commit_stroke()
				return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				if not _stroke_active:
					var erase := _selected_operation() == "Erase"
					if not _can_paint(erase):
						return false
					_begin_stroke(erase, MOUSE_BUTTON_LEFT)
					_apply_paint_at_mouse(mouse_event)
					return true
				return true
			if _stroke_active and _stroke_mouse_button == MOUSE_BUTTON_LEFT:
				_commit_stroke()
				return true
	if event is InputEventMouseMotion and _stroke_active:
		var motion := event as InputEventMouseMotion
		if _stroke_button_mask_held(motion):
			_apply_paint_at_mouse(motion)
			return true
	return _stroke_active


func _begin_stroke(erase: bool, mouse_button: MouseButton) -> void:
	_stroke_active = true
	_stroke_erase = erase
	_stroke_mouse_button = mouse_button
	_stroke_changes.clear()
	_stroke_touched_cells.clear()


func _stroke_button_mask_held(motion: InputEventMouseMotion) -> bool:
	if _stroke_mouse_button == MOUSE_BUTTON_LEFT:
		return (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if _stroke_mouse_button == MOUSE_BUTTON_RIGHT:
		return (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
	return false


func _clear_stroke_state(revert_live_changes: bool) -> void:
	if revert_live_changes and _stroke_active:
		for change in _stroke_changes:
			var layer: TileMapLayer = change["layer"]
			var cell: Vector2i = change["cell"]
			if int(change["prev_source"]) < 0:
				layer.erase_cell(cell)
			else:
				layer.set_cell(cell, int(change["prev_source"]), change["prev_atlas"], int(change["prev_alt"]))
	_stroke_active = false
	_stroke_erase = false
	_stroke_mouse_button = -1
	_stroke_changes.clear()
	_stroke_touched_cells.clear()


func _cancel_stroke() -> void:
	_clear_stroke_state(true)
	_status_label.text = "Paint stroke cancelled."


func _commit_stroke() -> void:
	if not _stroke_active:
		return
	var changes := _stroke_changes.duplicate()
	var operation := "Erase" if _stroke_erase else "Paint"
	_clear_stroke_state(false)
	if changes.is_empty():
		_status_label.text = "Paint stroke empty (no changes)."
		return
	if _plugin == null:
		_status_label.text = "Error: UndoRedo unavailable."
		return
	var ur := _plugin.get_undo_redo()
	ur.create_action("Mission Paint Stroke")
	for change in changes:
		var layer: TileMapLayer = change["layer"]
		var cell: Vector2i = change["cell"]
		var prev_source: int = int(change["prev_source"])
		var prev_atlas: Vector2i = change["prev_atlas"]
		var prev_alt: int = int(change["prev_alt"])
		var new_source: int = int(change["new_source"])
		var new_atlas: Vector2i = change["new_atlas"]
		var new_alt: int = int(change["new_alt"])
		if bool(change["new_empty"]):
			ur.add_do_method(layer, "erase_cell", cell)
		else:
			ur.add_do_method(layer, "set_cell", cell, new_source, new_atlas, new_alt)
		if prev_source < 0:
			ur.add_undo_method(layer, "erase_cell", cell)
		else:
			ur.add_undo_method(layer, "set_cell", cell, prev_source, prev_atlas, prev_alt)
	ur.commit_action()
	var layer_path := String(changes[0]["layer"].get_path()) if not changes.is_empty() else "?"
	_status_label.text = "Committed %s stroke on %s (%d cells)." % [operation, layer_path, changes.size()]


func _apply_paint_at_mouse(event: InputEventMouse) -> void:
	var layer := _resolve_target_layer()
	if layer == null:
		return
	var preset := _selected_tile_preset()
	if not _stroke_erase and not _tile_preset_valid_for_layer(layer, preset):
		_status_label.text = "Error: tile preset invalid for target layer."
		return
	var center_cell := _cell_from_mouse_event(event, layer)
	var brush_size := maxi(int(_brush_size_spin.value), 1)
	var half := brush_size / 2
	for dy in range(-half, brush_size - half):
		for dx in range(-half, brush_size - half):
			var cell := center_cell + Vector2i(dx, dy)
			_apply_cell_change(layer, cell, _stroke_erase)
	_update_stroke_status(layer, center_cell)


func _update_stroke_status(layer: TileMapLayer, cell: Vector2i) -> void:
	if layer == null:
		return
	var operation := "Erase" if _stroke_erase else "Paint"
	_debug_readout.text = "Stroke %s | %s | cell %s | cells=%d" % [
		operation,
		layer.get_path(),
		str(cell),
		_stroke_changes.size(),
	]


func _apply_cell_change(layer: TileMapLayer, cell: Vector2i, erase: bool) -> void:
	var key := "%s|%s,%s" % [layer.get_path(), cell.x, cell.y]
	if _stroke_touched_cells.has(key):
		return
	_stroke_touched_cells[key] = true
	var prev_source := layer.get_cell_source_id(cell)
	var prev_atlas := layer.get_cell_atlas_coords(cell) if prev_source >= 0 else Vector2i(-1, -1)
	var prev_alt := layer.get_cell_alternative_tile(cell) if prev_source >= 0 else 0
	var new_source := -1
	var new_atlas := Vector2i(-1, -1)
	var new_alt := 0
	var new_empty := erase
	if not erase:
		var preset := _selected_tile_preset()
		if String(preset.get("id", "")) == "eraser":
			new_empty = true
		else:
			new_source = int(preset.source_id)
			new_atlas = preset.atlas
			new_alt = int(preset.alternative)
	if not erase and not new_empty:
		if prev_source == new_source and prev_atlas == new_atlas and prev_alt == new_alt:
			return
	if erase or new_empty:
		if prev_source < 0:
			return
		layer.erase_cell(cell)
	else:
		layer.set_cell(cell, new_source, new_atlas, new_alt)
	_stroke_changes.append({
		"layer": layer,
		"cell": cell,
		"prev_source": prev_source,
		"prev_atlas": prev_atlas,
		"prev_alt": prev_alt,
		"new_source": new_source,
		"new_atlas": new_atlas,
		"new_alt": new_alt,
		"new_empty": new_empty,
	})


func _can_paint(erase: bool) -> bool:
	var layer := _resolve_target_layer()
	if layer == null:
		_status_label.text = "Error: target layer missing."
		return false
	if not erase:
		var preset := _selected_tile_preset()
		if not _tile_preset_valid_for_layer(layer, preset) and String(preset.get("id", "")) != "eraser":
			_status_label.text = "Error: tile preset not valid for layer."
			return false
	return _mode_allows_target(_target_metadata(), layer.get_path())


func _mode_allows_target(meta: Dictionary, path: String) -> bool:
	var mode := _selected_mode()
	if _path_is_forbidden(path):
		_status_label.text = "Error: forbidden runtime/generated target."
		return false
	if path.begins_with("GameplayRoot") and mode == MODE_VISUAL:
		_status_label.text = "Error: Visual Paint cannot target GameplayRoot."
		return false
	if path.begins_with("ArtRoot") and mode != MODE_VISUAL:
		_status_label.text = "Error: layout/collision modes cannot target ArtRoot."
		return false
	if mode == MODE_VISUAL:
		return true
	if mode == MODE_LAYOUT:
		if not _unlock_layout.button_pressed:
			_status_label.text = "Error: unlock Layout Blockout Painting first."
			return false
		return String(meta.get("mode", "")) == MODE_LAYOUT
	if mode == MODE_COLLISION:
		if not _unlock_layout.button_pressed:
			_status_label.text = "Error: unlock Layout Blockout Painting first."
			return false
		if not _unlock_collision.button_pressed:
			_status_label.text = "Error: unlock Collision Barrier Painting first."
			return false
		return String(meta.get("mode", "")) == MODE_COLLISION
	return false


func _resolve_target_layer() -> TileMapLayer:
	var scene_root := _edited_scene_root()
	if scene_root == null:
		_status_label.text = "Error: no open scene."
		return null
	var meta := _target_metadata()
	var path := String(meta.get("path", ""))
	if path == "":
		_status_label.text = "Error: no target layer selected."
		return null
	var layer := scene_root.get_node_or_null(path) as TileMapLayer
	if layer == null:
		_status_label.text = "Error: target is not a TileMapLayer: %s" % path
		return null
	return layer


func _target_metadata() -> Dictionary:
	var index := _target_layer_option.selected
	if index < 0:
		return {}
	var meta = _target_layer_option.get_item_metadata(index)
	return meta if meta is Dictionary else {}


func _selected_tile_preset() -> Dictionary:
	var index := _tile_preset_option.selected
	if index < 0:
		return {}
	var meta = _tile_preset_option.get_item_metadata(index)
	return meta if meta is Dictionary else {}


func _selected_mode() -> String:
	return _mode_option.get_item_text(_mode_option.selected) if _mode_option.selected >= 0 else MODE_VISUAL


func _selected_operation() -> String:
	return _operation_option.get_item_text(_operation_option.selected) if _operation_option.selected >= 0 else "Paint"


func _tile_preset_valid_for_layer(layer: TileMapLayer, preset: Dictionary) -> bool:
	if String(preset.get("id", "")) == "eraser":
		return true
	var tileset_path := String(preset.get("tileset_path", ""))
	if tileset_path == "":
		return false
	var layer_tileset := layer.tile_set
	if layer_tileset == null:
		return false
	if layer_tileset.resource_path != tileset_path:
		return false
	var source_id := int(preset.source_id)
	if source_id < 0 or source_id >= layer_tileset.get_source_count():
		return false
	var source := layer_tileset.get_source(source_id)
	if source is TileSetAtlasSource:
		return (source as TileSetAtlasSource).has_tile(preset.atlas)
	return false


func _path_is_forbidden(path: String) -> bool:
	if path.contains("GeneratedRuntimeCollision"):
		return true
	var exact_forbidden := [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayCollisionLayer",
		"GameplayRoot/GameplayMarkersLayer",
		"GameplayRoot/LayoutRoot/DebugLabelLayer",
	]
	for forbidden_path in exact_forbidden:
		if path == forbidden_path:
			return true
	for fragment in FORBIDDEN_TARGET_FRAGMENTS:
		if path.contains(fragment) and not path.begins_with("GameplayRoot/LayoutRoot/"):
			return true
	return false


func _cell_from_mouse_event(event: InputEventMouse, layer: TileMapLayer) -> Vector2i:
	var local_pos := _event_local_position_on_layer(event, layer)
	return layer.local_to_map(local_pos)


func _event_local_position_on_layer(event: InputEventMouse, layer: TileMapLayer) -> Vector2:
	var canvas_pos := _canvas_position_from_mouse_event(event)
	return layer.get_global_transform().affine_inverse() * canvas_pos


func _canvas_position_from_mouse_event(_event: InputEventMouse) -> Vector2:
	var viewport := _editor_viewport_2d()
	if viewport == null:
		return _event.position
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()


func _editor_viewport_2d() -> SubViewport:
	return _editor_interface.get_editor_viewport_2d() if _editor_interface != null else null


func _edited_scene_root() -> Node:
	return _editor_interface.get_edited_scene_root() if _editor_interface != null else null


func _update_debug_readout(layer: TileMapLayer, preset: Dictionary) -> void:
	if layer == null:
		_debug_readout.text = ""
		return
	_debug_readout.text = "Layer: %s | TileSet: %s | Preset source=%s atlas=%s" % [
		layer.get_path(),
		layer.tile_set.resource_path if layer.tile_set != null else "(none)",
		str(preset.get("source_id", "?")),
		str(preset.get("atlas", "?")),
	]


func _update_status() -> void:
	var mode := _selected_mode()
	var locks := "layout=%s collision=%s armed=%s" % [
		_unlock_layout.button_pressed,
		_unlock_collision.button_pressed,
		_arm_paint.button_pressed,
	]
	_status_label.text = "Mode: %s | %s | Select target and arm to paint." % [mode, locks]
