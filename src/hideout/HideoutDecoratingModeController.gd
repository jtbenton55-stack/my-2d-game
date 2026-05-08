extends Node
class_name HideoutDecoratingModeController

const StoreController = preload("res://src/hideout/HideoutStoreController.gd")
const GridOverlayScript = preload("res://src/hideout/HideoutDecorGridOverlay.gd")
const PlacedDecorItemScript = preload("res://src/hideout/HideoutPlacedDecorItem.gd")
const PlacementValidator = preload("res://src/hideout/HideoutDecorPlacementValidator.gd")

const STATE_INACTIVE := "inactive"
const STATE_ACTIVE_IDLE := "active_idle"
const STATE_CARRYING_NEW := "carrying_new_item"
const STATE_CARRYING_EXISTING := "carrying_existing_item"
const STATE_SELECTED_PLACED := "selected_placed_item"
const STATE_PLACEMENT_INVALID := "placement_invalid"

var is_decorating_mode := false
var mode_state := STATE_INACTIVE
var selected_item_id := ""
var selected_placed_id := ""
var carrying_item_id := ""
var carrying_existing_placed_id := ""
var original_position_before_move := Vector2.ZERO
var original_rotation_before_move := 0.0
var current_rotation_degrees := 0.0
var current_preview_position := Vector2.ZERO
var current_snapped_position := Vector2.ZERO
var snap_grid_size := 16
var placement_valid := false
var placement_feedback := ""
var last_valid_position := Vector2.ZERO
var last_valid_rotation_degrees := 0.0
var no_place_zones: Array = []
var occupied_footprints: Array = []
var blocked_zone_margin_px := 24
var collision_padding_px := 8
var max_nearest_open_search_radius_px := 256
var preview_node: Node2D = null
var grid_overlay_node: Node = null
var hud_node: Control = null

var state_controller: Node = null
var placed_decor_container: Node2D = null
var panel: Node = null
var ui_root: CanvasLayer = null
var walls_layer_bitmask := 4
var _placed_counter := 0
var _panel_was_blocking_ui := false
var _hud_status_label: Label = null
var _hud_controls_label: Label = null
var _hud_item_list: VBoxContainer = null
var _hud_exit_button: Button = null
var _hud_cancel_button: Button = null
var _hud_remove_button: Button = null
var _hud_clear_selection_button: Button = null

func configure(p_state_controller: Node, p_placed_container: Node2D, p_panel: Node, p_ui_root: CanvasLayer) -> void:
	state_controller = p_state_controller
	placed_decor_container = p_placed_container
	panel = p_panel
	ui_root = p_ui_root
	no_place_zones = PlacementValidator.no_place_zones()
	_ensure_grid_overlay()
	_ensure_hud()
	rebuild_placed_visuals()

func enter_decorating_mode(item_id: String = "") -> void:
	is_decorating_mode = true
	mode_state = STATE_ACTIVE_IDLE
	if panel != null and panel.has_method("close_panel"):
		panel.close_panel()
	if panel != null and panel.is_in_group("blocking_ui"):
		_panel_was_blocking_ui = true
		panel.remove_from_group("blocking_ui")
	_show_hud_and_grid()
	selected_item_id = item_id if item_id != "" else _state_selected_item()
	if selected_item_id != "":
		start_placing_new_item(selected_item_id)
	else:
		placement_feedback = "Decorating Mode ready. Select a placed item or reopen Open Decor Area to choose new decor."
	_update_hud()

func exit_decorating_mode() -> void:
	cancel_current_placement()
	is_decorating_mode = false
	mode_state = STATE_INACTIVE
	selected_item_id = ""
	selected_placed_id = ""
	carrying_item_id = ""
	carrying_existing_placed_id = ""
	if state_controller != null:
		state_controller.set("selected_placed_id", "")
	if grid_overlay_node != null and grid_overlay_node.has_method("hide_grid"):
		grid_overlay_node.hide_grid()
	if hud_node != null:
		hud_node.hide()
	if _panel_was_blocking_ui and panel != null and not panel.is_in_group("blocking_ui"):
		panel.add_to_group("blocking_ui")
	_panel_was_blocking_ui = false
	_remove_preview()
	rebuild_placed_visuals()

func start_placing_new_item(item_id: String) -> void:
	if state_controller == null or not state_controller.get("owned_placeable_items").has(item_id):
		placement_feedback = "Select an owned decor item first."
		mode_state = STATE_ACTIVE_IDLE
		_update_hud()
		return
	for placed in state_controller.get("placed_items"):
		if String(placed.get("item_id", "")) == item_id:
			selected_placed_id = String(placed.get("placed_id", ""))
			state_controller.set("selected_placed_id", selected_placed_id)
			placement_feedback = "That owned item is already placed. Click or move the placed copy instead."
			mode_state = STATE_SELECTED_PLACED
			rebuild_placed_visuals()
			_update_hud()
			return
	selected_item_id = item_id
	carrying_item_id = item_id
	carrying_existing_placed_id = ""
	selected_placed_id = ""
	current_rotation_degrees = 0.0
	mode_state = STATE_CARRYING_NEW
	_ensure_preview()
	refresh_preview_from_mouse()

func start_moving_placed_item(placed_id: String) -> void:
	var placed := _placed_by_id(placed_id)
	if placed.is_empty():
		placement_feedback = "Placed item was not found."
		_update_hud()
		return
	selected_placed_id = placed_id
	carrying_existing_placed_id = placed_id
	carrying_item_id = String(placed.get("item_id", ""))
	selected_item_id = carrying_item_id
	original_position_before_move = placed.get("position", Vector2.ZERO)
	original_rotation_before_move = float(placed.get("rotation", 0.0))
	current_rotation_degrees = original_rotation_before_move
	mode_state = STATE_CARRYING_EXISTING
	_ensure_preview()
	rebuild_placed_visuals()
	refresh_preview_from_mouse()

func cancel_current_placement() -> void:
	if mode_state == STATE_CARRYING_EXISTING and carrying_existing_placed_id != "":
		_update_placed_item(carrying_existing_placed_id, original_position_before_move, original_rotation_before_move)
	_remove_preview()
	carrying_item_id = ""
	carrying_existing_placed_id = ""
	mode_state = STATE_ACTIVE_IDLE if is_decorating_mode else STATE_INACTIVE
	placement_feedback = "Placement cancelled." if is_decorating_mode else ""
	rebuild_placed_visuals()
	_update_hud()

func confirm_current_placement() -> void:
	if carrying_item_id == "":
		placement_feedback = "No decor item is being carried."
		_update_hud()
		return
	refresh_preview_from_mouse()
	if not placement_valid:
		var item := _item_with_rotation(carrying_item_id)
		var nearest := PlacementValidator.find_nearest_valid_position(current_snapped_position, item, _placed_items_with_item_data(), carrying_existing_placed_id, snap_grid_size)
		if bool(nearest.get("found", false)):
			current_snapped_position = nearest.get("position", current_snapped_position)
			placement_valid = true
			placement_feedback = "Snapped to nearest open spot."
		else:
			placement_feedback = "No open spot nearby."
			_update_preview_visual()
			_update_hud()
			return
	if carrying_existing_placed_id != "":
		_update_placed_item(carrying_existing_placed_id, current_snapped_position, current_rotation_degrees)
		selected_placed_id = carrying_existing_placed_id
	else:
		selected_placed_id = _create_placed_item(carrying_item_id, current_snapped_position, current_rotation_degrees)
	carrying_item_id = ""
	carrying_existing_placed_id = ""
	mode_state = STATE_ACTIVE_IDLE
	_remove_preview()
	rebuild_placed_visuals()
	if placement_feedback != "Snapped to nearest open spot.":
		placement_feedback = "Placed. Decorating Mode remains active."
	_update_hud()

func rotate_preview(delta_degrees: float) -> void:
	if not is_decorating_mode:
		return
	current_rotation_degrees = fposmod(current_rotation_degrees + delta_degrees, 360.0)
	if preview_node != null:
		preview_node.rotation_degrees = current_rotation_degrees
	refresh_preview_from_mouse()

func remove_selected_placed_item() -> void:
	if state_controller == null:
		return
	if selected_placed_id == "":
		placement_feedback = "No placed item selected."
		_update_hud()
		return
	remove_placed_item_by_id(selected_placed_id, "selected")

func remove_placed_item_by_id(placed_id: String, reason: String = "") -> void:
	if state_controller == null or placed_id == "":
		return
	var kept: Array[Dictionary] = []
	var removed := false
	var removed_item_id := ""
	for placed in state_controller.get("placed_items"):
		if String(placed.get("placed_id", "")) != placed_id:
			kept.append(placed)
		else:
			removed = true
			removed_item_id = String(placed.get("item_id", ""))
	if not removed:
		placement_feedback = "Selected decor was not found."
		_update_hud()
		return
	state_controller.set("placed_items", kept)
	if selected_placed_id == placed_id:
		selected_placed_id = ""
		state_controller.set("selected_placed_id", "")
	if carrying_existing_placed_id == placed_id:
		carrying_existing_placed_id = ""
		carrying_item_id = ""
		_remove_preview()
	mode_state = STATE_ACTIVE_IDLE
	rebuild_placed_visuals()
	var reason_suffix := " (%s)" % reason if reason != "" else ""
	placement_feedback = "Removed %s%s. Owned inventory unchanged." % [StoreController.new().item_display_name(removed_item_id), reason_suffix]
	_update_hud()

func clear_all_placed_decor() -> void:
	if state_controller != null:
		var ids: Array[String] = []
		for placed in state_controller.get("placed_items"):
			ids.append(String(placed.get("placed_id", "")))
		for placed_id in ids:
			remove_placed_item_by_id(placed_id, "clear_all")
	selected_placed_id = ""
	carrying_existing_placed_id = ""
	carrying_item_id = ""
	if state_controller != null:
		state_controller.set("selected_placed_id", "")
	_remove_preview()
	mode_state = STATE_ACTIVE_IDLE if is_decorating_mode else STATE_INACTIVE
	rebuild_placed_visuals()
	placement_feedback = "Placed decor cleared. Owned inventory unchanged."
	_update_hud()

func is_in_decorating_mode() -> bool:
	return is_decorating_mode

func get_selected_item_id() -> String:
	return selected_item_id

func get_selected_placed_id() -> String:
	return selected_placed_id

func refresh_preview_from_mouse() -> void:
	if not is_decorating_mode or carrying_item_id == "":
		return
	var world_pos := _mouse_world_position()
	current_preview_position = world_pos
	current_snapped_position = PlacementValidator.snap_world_position(world_pos, snap_grid_size)
	validate_current_preview_position()
	if preview_node != null:
		preview_node.position = current_snapped_position
		preview_node.rotation_degrees = current_rotation_degrees
		_update_preview_visual()

func validate_current_preview_position() -> bool:
	var item := _item_with_rotation(carrying_item_id)
	var placed_items := _placed_items_with_item_data()
	var moving_id := carrying_existing_placed_id
	var validation := PlacementValidator.validate_position(current_snapped_position, item, placed_items, moving_id)
	if bool(validation.get("valid", false)):
		placement_valid = true
		mode_state = STATE_CARRYING_EXISTING if carrying_existing_placed_id != "" else STATE_CARRYING_NEW
		last_valid_position = current_snapped_position
		last_valid_rotation_degrees = current_rotation_degrees
		placement_feedback = "Valid"
		return true
	placement_valid = false
	mode_state = STATE_PLACEMENT_INVALID
	placement_feedback = "Blocked: %s" % String(validation.get("reason", "Blocked"))
	return false

func rebuild_placed_visuals() -> void:
	if placed_decor_container == null:
		return
	for child in placed_decor_container.get_children():
		child.queue_free()
	if state_controller == null:
		return
	for placed in state_controller.get("placed_items"):
		if carrying_existing_placed_id != "" and String(placed.get("placed_id", "")) == carrying_existing_placed_id:
			continue
		var item := StoreController.new().item_by_id(String(placed.get("item_id", "")))
		var placed_item = PlacedDecorItemScript.new()
		placed_item.name = String(placed.get("placed_id", "PlacedDecor"))
		placed_item.setup(placed, item, String(placed.get("placed_id", "")) == selected_placed_id, walls_layer_bitmask)
		placed_item.decor_clicked.connect(_on_placed_decor_clicked)
		placed_decor_container.add_child(placed_item)

func _unhandled_input(event: InputEvent) -> void:
	if not is_decorating_mode:
		return
	if event is InputEventMouseMotion:
		refresh_preview_from_mouse()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if carrying_item_id != "":
				confirm_current_placement()
				get_viewport().set_input_as_handled()
			else:
				var hit_id := _hit_test_placed_item(_mouse_world_position())
				if hit_id != "":
					start_moving_placed_item(hit_id)
					get_viewport().set_input_as_handled()
				else:
					_clear_selection()
					get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if carrying_item_id != "":
				cancel_current_placement()
			else:
				placement_feedback = "Nothing carried. Press Esc to exit Decorating Mode."
				_update_hud()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_DOWN:
				rotate_preview(-45.0)
				get_viewport().set_input_as_handled()
			KEY_RIGHT, KEY_UP:
				rotate_preview(45.0)
				get_viewport().set_input_as_handled()
			KEY_R, KEY_DELETE:
				remove_selected_placed_item()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				if carrying_item_id != "":
					cancel_current_placement()
				else:
					exit_decorating_mode()
				get_viewport().set_input_as_handled()

func _on_placed_decor_clicked(placed_id: String) -> void:
	if not is_decorating_mode:
		return
	if carrying_item_id != "":
		return
	start_moving_placed_item(placed_id)

func _create_placed_item(item_id: String, pos: Vector2, rotation_degrees_value: float) -> String:
	_placed_counter += 1
	var item := StoreController.new().item_by_id(item_id)
	var placed_id := "placed_%s_%03d" % [item_id, _placed_counter]
	var placed := {
		"placed_id": placed_id,
		"item_id": item_id,
		"display_name": String(item.get("display_name", item_id)),
		"anchor_id": "",
		"position": pos,
		"rotation": rotation_degrees_value,
		"tags": item.get("placement_tags", []),
	}
	var placed_items: Array = state_controller.get("placed_items")
	placed_items.append(placed)
	state_controller.set("placed_items", placed_items)
	state_controller.set("selected_placed_id", placed_id)
	return placed_id

func _update_placed_item(placed_id: String, pos: Vector2, rotation_degrees_value: float) -> void:
	var placed_items: Array = state_controller.get("placed_items")
	for i in range(placed_items.size()):
		var existing: Dictionary = placed_items[i]
		if String(existing.get("placed_id", "")) != placed_id:
			continue
		var placed: Dictionary = existing.duplicate(true)
		placed["position"] = pos
		placed["rotation"] = rotation_degrees_value
		placed_items[i] = placed
		break
	state_controller.set("placed_items", placed_items)

func _placed_by_id(placed_id: String) -> Dictionary:
	if state_controller == null:
		return {}
	for placed in state_controller.get("placed_items"):
		if String(placed.get("placed_id", "")) == placed_id:
			return placed
	return {}

func _placed_items_with_item_data() -> Array:
	var out: Array = []
	if state_controller == null:
		return out
	var store := StoreController.new()
	for placed in state_controller.get("placed_items"):
		var placed_dict: Dictionary = placed
		var copy: Dictionary = placed_dict.duplicate(true)
		copy["item_data"] = store.item_by_id(String(placed_dict.get("item_id", "")))
		out.append(copy)
	return out

func _hit_test_placed_item(world_pos: Vector2) -> String:
	if state_controller == null:
		return ""
	var store := StoreController.new()
	var best_id := ""
	var best_distance := INF
	for placed in state_controller.get("placed_items"):
		var placed_id := String(placed.get("placed_id", ""))
		var item := store.item_by_id(String(placed.get("item_id", "")))
		var rect := PlacementValidator.footprint_rect(placed.get("position", Vector2.ZERO), item, float(placed.get("rotation", 0.0)))
		if rect.has_point(world_pos):
			var distance := world_pos.distance_to(placed.get("position", Vector2.ZERO))
			if distance < best_distance:
				best_distance = distance
				best_id = placed_id
	return best_id

func _clear_selection() -> void:
	selected_placed_id = ""
	if state_controller != null:
		state_controller.set("selected_placed_id", "")
	if carrying_item_id == "":
		mode_state = STATE_ACTIVE_IDLE
		placement_feedback = "Selection cleared."
	rebuild_placed_visuals()
	_update_hud()

func _available_owned_item_ids() -> Array[String]:
	var available: Array[String] = []
	if state_controller == null:
		return available
	var placed_lookup := {}
	for placed in state_controller.get("placed_items"):
		placed_lookup[String(placed.get("item_id", ""))] = true
	for item_id in state_controller.get("owned_placeable_items"):
		var id := String(item_id)
		if not placed_lookup.has(id):
			available.append(id)
	return available

func _on_hud_item_button_pressed(item_id: String) -> void:
	if not is_decorating_mode:
		return
	if carrying_item_id != "":
		cancel_current_placement()
	if state_controller != null:
		state_controller.set("selected_placeable_item_id", item_id)
	start_placing_new_item(item_id)

func _on_hud_exit_pressed() -> void:
	exit_decorating_mode()

func _on_hud_cancel_pressed() -> void:
	cancel_current_placement()

func _on_hud_remove_pressed() -> void:
	remove_selected_placed_item()

func _on_hud_clear_selection_pressed() -> void:
	_clear_selection()

func _item_with_rotation(item_id: String) -> Dictionary:
	var item := StoreController.new().item_by_id(item_id).duplicate(true)
	item["rotation_degrees"] = current_rotation_degrees
	return item

func _state_selected_item() -> String:
	return String(state_controller.get("selected_placeable_item_id")) if state_controller != null else ""

func _ensure_preview() -> void:
	if preview_node != null and is_instance_valid(preview_node):
		return
	preview_node = Node2D.new()
	preview_node.name = "DecorPlacementPreview"
	preview_node.z_index = 130
	placed_decor_container.add_child(preview_node)
	_rebuild_preview_children()

func _rebuild_preview_children() -> void:
	if preview_node == null:
		return
	for child in preview_node.get_children():
		child.queue_free()
	var item := StoreController.new().item_by_id(carrying_item_id)
	var footprint := Vector2(float(item.get("footprint_width_px", 48)), float(item.get("footprint_height_px", 48)))
	var half := footprint * 0.5
	var poly := Polygon2D.new()
	poly.name = "GhostPreviewPolygon"
	poly.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	poly.color = Color(0.2, 0.9, 1.0, 0.5)
	preview_node.add_child(poly)
	var label := Label.new()
	label.name = "PreviewLabel"
	label.text = String(item.get("display_name", carrying_item_id))
	label.position = Vector2(-half.x, -half.y - 30)
	label.add_theme_color_override("font_color", Color(0.8, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	preview_node.add_child(label)

func _update_preview_visual() -> void:
	if preview_node == null:
		return
	var poly := preview_node.get_node_or_null("GhostPreviewPolygon") as Polygon2D
	if poly != null:
		poly.color = Color(0.3, 1.0, 0.55, 0.55) if placement_valid else Color(1.0, 0.15, 0.15, 0.55)
	var label := preview_node.get_node_or_null("PreviewLabel") as Label
	if label != null:
		label.text = "%s\n%s\nRot %d" % [StoreController.new().item_display_name(carrying_item_id), "Valid" if placement_valid else "Blocked", int(current_rotation_degrees)]
	_update_hud()

func _remove_preview() -> void:
	if preview_node != null and is_instance_valid(preview_node):
		preview_node.queue_free()
	preview_node = null

func _ensure_grid_overlay() -> void:
	if grid_overlay_node != null or placed_decor_container == null:
		return
	grid_overlay_node = GridOverlayScript.new()
	grid_overlay_node.name = "DecorGridOverlay"
	placed_decor_container.get_parent().add_child(grid_overlay_node)
	grid_overlay_node.configure(snap_grid_size, PlacementValidator.VALID_BOUNDS)

func _ensure_hud() -> void:
	if hud_node != null or ui_root == null:
		return
	var hud_panel := PanelContainer.new()
	hud_panel.name = "DecoratingModeHUD"
	hud_panel.visible = false
	hud_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_panel.offset_left = 16
	hud_panel.offset_top = 16
	hud_panel.offset_right = 430
	hud_panel.offset_bottom = 420
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	hud_panel.add_child(margin)
	var root := VBoxContainer.new()
	root.name = "VBoxContainer"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	var title := Label.new()
	title.name = "Title"
	title.text = "Decorating Mode"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.35, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)
	_hud_status_label = Label.new()
	_hud_status_label.name = "StatusLabel"
	_hud_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_status_label.add_theme_color_override("font_color", Color(0.86, 1, 1, 1))
	_hud_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_hud_status_label.add_theme_constant_override("outline_size", 4)
	root.add_child(_hud_status_label)
	_hud_controls_label = Label.new()
	_hud_controls_label.name = "ControlsLabel"
	_hud_controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud_controls_label.text = "Left Click: place / select item\nRight Click or Esc: cancel placement\nArrow Keys: rotate 45 deg\nR/Delete: remove selected\nEsc with no item: exit Decorating Mode"
	_hud_controls_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1, 1))
	_hud_controls_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_hud_controls_label.add_theme_constant_override("outline_size", 4)
	root.add_child(_hud_controls_label)
	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(buttons)
	_hud_exit_button = _make_hud_button("Exit Decorating Mode", Callable(self, "_on_hud_exit_pressed"))
	buttons.add_child(_hud_exit_button)
	_hud_cancel_button = _make_hud_button("Cancel Placement", Callable(self, "_on_hud_cancel_pressed"))
	buttons.add_child(_hud_cancel_button)
	_hud_remove_button = _make_hud_button("Remove Selected", Callable(self, "_on_hud_remove_pressed"))
	buttons.add_child(_hud_remove_button)
	_hud_clear_selection_button = _make_hud_button("Clear Selection", Callable(self, "_on_hud_clear_selection_pressed"))
	buttons.add_child(_hud_clear_selection_button)
	var item_title := Label.new()
	item_title.name = "ItemPickerTitle"
	item_title.text = "Available Owned Items"
	item_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_title.add_theme_color_override("font_color", Color(1, 0.9, 0.65, 1))
	item_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	item_title.add_theme_constant_override("outline_size", 4)
	root.add_child(item_title)
	var item_scroll := ScrollContainer.new()
	item_scroll.name = "ItemPickerScroll"
	item_scroll.custom_minimum_size = Vector2(380, 94)
	item_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(item_scroll)
	_hud_item_list = VBoxContainer.new()
	_hud_item_list.name = "ItemList"
	_hud_item_list.mouse_filter = Control.MOUSE_FILTER_PASS
	item_scroll.add_child(_hud_item_list)
	ui_root.add_child(hud_panel)
	hud_node = hud_panel

func _show_hud_and_grid() -> void:
	if grid_overlay_node != null and grid_overlay_node.has_method("show_grid"):
		grid_overlay_node.show_grid()
	if hud_node != null:
		hud_node.show()

func _update_hud() -> void:
	if hud_node == null:
		return
	if _hud_status_label == null or _hud_item_list == null:
		return
	_hud_status_label.text = "Mode: %s\nSelected item: %s\nSelected placed item: %s\nRotation: %d degrees\nGrid: %d px\nStatus: %s" % [
		_mode_display_name(),
		StoreController.new().item_display_name(selected_item_id),
		selected_placed_id if selected_placed_id != "" else "none",
		int(current_rotation_degrees),
		snap_grid_size,
		placement_feedback,
	]
	_hud_cancel_button.visible = carrying_item_id != ""
	_hud_cancel_button.disabled = carrying_item_id == ""
	_hud_remove_button.visible = selected_placed_id != ""
	_hud_remove_button.disabled = selected_placed_id == ""
	_hud_clear_selection_button.visible = selected_placed_id != "" and carrying_item_id == ""
	_hud_clear_selection_button.disabled = not _hud_clear_selection_button.visible
	_rebuild_hud_item_picker()

func _mouse_world_position() -> Vector2:
	var viewport := get_viewport()
	var camera := viewport.get_camera_2d()
	if camera != null:
		return camera.get_global_mouse_position()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()

func _make_hud_button(text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callable)
	return button

func _rebuild_hud_item_picker() -> void:
	for child in _hud_item_list.get_children():
		child.queue_free()
	var available := _available_owned_item_ids()
	if available.is_empty():
		var empty := Label.new()
		empty.text = "No unplaced owned decor available."
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1))
		_hud_item_list.add_child(empty)
		return
	var store := StoreController.new()
	for item_id in available:
		var button_item_id := item_id
		var button := Button.new()
		button.text = "Place: %s" % store.item_display_name(button_item_id)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(func() -> void:
			_on_hud_item_button_pressed(button_item_id)
		)
		_hud_item_list.add_child(button)

func _mode_display_name() -> String:
	match mode_state:
		STATE_ACTIVE_IDLE:
			return "Idle"
		STATE_CARRYING_NEW:
			return "Placing New Item"
		STATE_CARRYING_EXISTING:
			return "Moving Existing Item"
		STATE_PLACEMENT_INVALID:
			return "Invalid Placement"
		STATE_SELECTED_PLACED:
			return "Selected Placed Item"
		_:
			return "Inactive"
