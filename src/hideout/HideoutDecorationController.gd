extends Node
class_name HideoutDecorationController

const StoreController = preload("res://src/hideout/HideoutStoreController.gd")
const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")

var state_controller: Node = null
var placed_decor_container: Node = null
var anchors: Array[Dictionary] = []
var _placed_counter := 0

func configure(p_state_controller: Node, p_placed_decor_container: Node) -> void:
	state_controller = p_state_controller
	placed_decor_container = p_placed_decor_container
	anchors = _default_anchors()
	_rebuild_visuals()

func get_open_decor_panel_data() -> Dictionary:
	return {
		"title": "Open Decor Area",
		"body": _open_decor_body(),
		"buttons": _open_decor_buttons(),
	}

func get_loot_crate_panel_data() -> Dictionary:
	return {
		"title": "Loot Crate Drop Zone",
		"body": _loot_crate_body(),
		"buttons": [
			{"id": "open_decor_inventory", "label": "Open Decor Inventory", "action": "open_decor_inventory"},
			{"id": "back", "label": "Back", "action": "back"},
		],
	}

func select_item(item_id: String) -> String:
	if state_controller == null or not state_controller.get("owned_placeable_items").has(item_id):
		return "That item is not owned yet."
	state_controller.set("selected_placeable_item_id", item_id)
	_rebuild_visuals()
	return "%s selected for placement." % StoreController.new().item_display_name(item_id)

func select_placed(placed_id: String) -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	for placed in state_controller.get("placed_items"):
		if String(placed.get("placed_id", "")) == placed_id:
			state_controller.set("selected_placed_id", placed_id)
			state_controller.set("selected_placeable_item_id", String(placed.get("item_id", "")))
			_rebuild_visuals()
			return "%s selected. You can move or remove it now." % String(placed.get("display_name", "Decor"))
	return "Placed item was not found."

func enter_placement_mode() -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	var item_id := String(state_controller.get("selected_placeable_item_id"))
	if item_id == "":
		return "Select an owned decor card first."
	state_controller.set_meta("decor_placement_mode", true)
	_rebuild_visuals()
	return "Click-to-place mode armed for %s. Press Place Selected Item to drop it at the next valid anchor." % StoreController.new().item_display_name(item_id)

func place_selected() -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	var item_id := String(state_controller.get("selected_placeable_item_id"))
	if item_id == "":
		return "Select an owned item first."
	if not state_controller.get("owned_placeable_items").has(item_id):
		return "Only owned items can be placed."
	var item := StoreController.new().item_by_id(item_id)
	var anchor := _next_compatible_anchor(item, "")
	if anchor.is_empty():
		return "No compatible anchor is available for %s." % String(item.get("display_name", item_id))
	_placed_counter += 1
	var placed_id := "placed_%s_%03d" % [item_id, _placed_counter]
	var placed := {
		"placed_id": placed_id,
		"item_id": item_id,
		"display_name": String(item.get("display_name", item_id)),
		"anchor_id": String(anchor.get("anchor_id", "")),
		"position": anchor.get("position", Vector2.ZERO),
		"rotation": 0.0,
		"tags": item.get("placement_tags", []),
	}
	var placed_items: Array = state_controller.get("placed_items")
	placed_items.append(placed)
	state_controller.set("placed_items", placed_items)
	state_controller.set("selected_placed_id", placed_id)
	state_controller.set_meta("decor_placement_mode", false)
	_rebuild_visuals()
	return DialogueBank.get_random_line("decoration_place_success")

func move_selected() -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	var selected_id := String(state_controller.get("selected_placed_id"))
	if selected_id == "":
		return "No placed item is selected."
	var placed_items: Array = state_controller.get("placed_items")
	for i in range(placed_items.size()):
		var placed: Dictionary = placed_items[i]
		if String(placed.get("placed_id", "")) != selected_id:
			continue
		var item := StoreController.new().item_by_id(String(placed.get("item_id", "")))
		var anchor := _next_compatible_anchor(item, String(placed.get("anchor_id", "")))
		if anchor.is_empty():
			return "No alternate compatible anchor is available."
		placed["anchor_id"] = String(anchor.get("anchor_id", ""))
		placed["position"] = anchor.get("position", Vector2.ZERO)
		placed_items[i] = placed
		state_controller.set("placed_items", placed_items)
		_rebuild_visuals()
		return "%s moved to %s." % [String(placed.get("display_name", "Decor")), String(anchor.get("anchor_id", ""))]
	return "Selected placed item was not found."

func remove_selected() -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	var selected_id := String(state_controller.get("selected_placed_id"))
	if selected_id == "":
		return "No placed item is selected."
	return remove_placed_item_by_id(selected_id, "open_decor")

func remove_placed_item_by_id(placed_id: String, _reason: String = "") -> String:
	if state_controller == null:
		return "Decoration state is unavailable."
	if placed_id == "":
		return "No placed item is selected."
	var kept: Array[Dictionary] = []
	var removed := false
	for placed in state_controller.get("placed_items"):
		if String(placed.get("placed_id", "")) != placed_id:
			kept.append(placed)
		else:
			removed = true
	if not removed:
		return "Selected placed item was not found."
	state_controller.set("placed_items", kept)
	if String(state_controller.get("selected_placed_id")) == placed_id:
		state_controller.set("selected_placed_id", "")
	_rebuild_visuals()
	return DialogueBank.get_random_line("decoration_remove_success")

func clear_all() -> String:
	if state_controller != null:
		var ids: Array[String] = []
		for placed in state_controller.get("placed_items"):
			ids.append(String(placed.get("placed_id", "")))
		for placed_id in ids:
			remove_placed_item_by_id(placed_id, "clear_all")
		state_controller.set("selected_placed_id", "")
	_rebuild_visuals()
	return "Placed decor cleared."

func _open_decor_body() -> String:
	var lines: Array[String] = [
		"Open Decor Area",
		"",
		DialogueBank.get_random_line("open_decor_area"),
		"",
		"Case Cash: %d" % int(state_controller.get("case_cash") if state_controller != null else 0),
		"Selected item: %s" % StoreController.new().item_display_name(String(state_controller.get("selected_placeable_item_id") if state_controller != null else "")),
		"Decorating Mode status: use Enter Click-to-Place Mode for world-space placement. Anchor buttons below are fallback/debug tools.",
		"",
		"Owned Decor Inventory Cards:",
	]
	var owned: Array = state_controller.get("owned_placeable_items") if state_controller != null else []
	if owned.is_empty():
		lines.append("- None yet. Buy decor from the Store Terminal.")
	for item_id in owned:
		lines.append("- [CARD/ICON] %s" % StoreController.new().item_display_name(String(item_id)))
	lines.append("")
	lines.append("Placed Items:")
	var placed_items: Array = state_controller.get("placed_items") if state_controller != null else []
	if placed_items.is_empty():
		lines.append("- None placed yet.")
	var selected_placed := String(state_controller.get("selected_placed_id") if state_controller != null else "")
	for placed in placed_items:
		var selected_label := " (selected)" if String(placed.get("placed_id", "")) == selected_placed else ""
		lines.append("- [PLACED] %s at %s%s" % [String(placed.get("display_name", "")), String(placed.get("anchor_id", "")), selected_label])
	lines.append("")
	lines.append("True Decorating Mode: select an owned visual card, enter mode, use the mouse ghost preview, rotate with arrows, left-click to place, and R/Delete to remove selected placed decor.")
	var selected_item_id := String(state_controller.get("selected_placeable_item_id") if state_controller != null else "")
	if selected_item_id != "":
		lines.append("")
		lines.append("Compatible Anchors:")
		var item := StoreController.new().item_by_id(selected_item_id)
		for anchor in _compatible_anchors(item):
			lines.append("- %s" % String(anchor.get("anchor_id", "")))
	return "\n".join(lines)

func _open_decor_buttons() -> Array:
	var buttons: Array = []
	var owned: Array = state_controller.get("owned_placeable_items") if state_controller != null else []
	for item_id in owned:
		buttons.append({"id": "select_%s" % item_id, "label": "Select Item: %s" % StoreController.new().item_display_name(String(item_id)), "action": "decor_select_item:%s" % item_id, "item_id": String(item_id)})
	buttons.append({"id": "enter_click_to_place", "label": "Enter Click-To-Place Mode", "action": "decor_enter_click_to_place_mode"})
	buttons.append({"id": "enter_empty_decorating", "label": "Enter Decorating Mode Without Item", "action": "decor_enter_decorating_mode"})
	buttons.append({"id": "place_selected", "label": "Place Selected Item At Valid Anchor Point", "action": "decor_place_selected"})
	var placed_items: Array = state_controller.get("placed_items") if state_controller != null else []
	for placed in placed_items:
		buttons.append({"id": "select_placed_%s" % String(placed.get("placed_id", "")), "label": "Select Placed: %s" % String(placed.get("display_name", "")), "action": "decor_select_placed:%s" % String(placed.get("placed_id", ""))})
	buttons.append({"id": "move_selected", "label": "Move Selected Placed Item To Next Anchor", "action": "decor_move_selected"})
	buttons.append({"id": "remove_selected", "label": "Remove Selected Placed Item", "action": "decor_remove_selected"})
	buttons.append({"id": "clear_all", "label": "Clear Placed Decor", "action": "decor_clear_all"})
	return buttons

func _loot_crate_body() -> String:
	var lines: Array[String] = ["Loot Crate Drop Zone", "", "Purchased items can be placed from the Open Decor Area.", "", "Delivered / Purchased Items:", ""]
	var owned: Array = state_controller.get("owned_placeable_items") if state_controller != null else []
	if owned.is_empty():
		lines.append("- No purchased decor yet.")
	for item_id in owned:
		lines.append("- [CARD/ICON] %s" % StoreController.new().item_display_name(String(item_id)))
	lines.append("")
	lines.append("Owned decor summary: %d item(s)." % owned.size())
	return "\n".join(lines)

func _rebuild_visuals() -> void:
	if placed_decor_container == null:
		return
	for child in placed_decor_container.get_children():
		child.queue_free()
	if state_controller == null:
		return
	for placed in state_controller.get("placed_items"):
		var holder := Node2D.new()
		holder.name = String(placed.get("placed_id", "PlacedDecor"))
		holder.position = placed.get("position", Vector2.ZERO)
		placed_decor_container.add_child(holder)
		var selected := String(placed.get("placed_id", "")) == String(state_controller.get("selected_placed_id"))
		var box := Polygon2D.new()
		box.name = "PlaceholderDecorVisual"
		box.polygon = PackedVector2Array([Vector2(-44, -24), Vector2(44, -24), Vector2(44, 24), Vector2(-44, 24)])
		box.color = Color(1.0, 0.72, 0.20, 0.9) if selected else Color(0.5, 0.25, 0.85, 0.78)
		holder.add_child(box)
		var click_area := Area2D.new()
		click_area.name = "ClickableSelectArea"
		click_area.input_pickable = true
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(92, 56)
		shape.shape = rect
		click_area.add_child(shape)
		click_area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_viewport.set_input_as_handled()
				select_placed(String(placed.get("placed_id", "")))
		)
		holder.add_child(click_area)
		var label := Label.new()
		label.text = String(placed.get("display_name", "Decor"))
		label.position = Vector2(-58, -42)
		label.add_theme_color_override("font_color", Color(1, 0.95, 0.65, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		holder.add_child(label)
	var selected_item := String(state_controller.get("selected_placeable_item_id"))
	if selected_item != "" and state_controller.has_meta("decor_placement_mode") and bool(state_controller.get_meta("decor_placement_mode")):
		var preview := Node2D.new()
		preview.name = "PlacementPreview"
		preview.position = Vector2(470, 120)
		placed_decor_container.add_child(preview)
		var preview_box := Polygon2D.new()
		preview_box.name = "PlaceholderPlacementPreview"
		preview_box.polygon = PackedVector2Array([Vector2(-46, -26), Vector2(46, -26), Vector2(46, 26), Vector2(-46, 26)])
		preview_box.color = Color(0.2, 0.9, 1.0, 0.35)
		preview.add_child(preview_box)
		var preview_label := Label.new()
		preview_label.text = "Preview: %s" % StoreController.new().item_display_name(selected_item)
		preview_label.position = Vector2(-60, -48)
		preview_label.add_theme_color_override("font_color", Color(0.75, 1, 1, 1))
		preview_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		preview_label.add_theme_constant_override("outline_size", 4)
		preview.add_child(preview_label)

func _next_compatible_anchor(item: Dictionary, after_anchor_id: String) -> Dictionary:
	var compatible: Array[Dictionary] = []
	for anchor in _compatible_anchors(item):
		compatible.append(anchor)
	if compatible.is_empty():
		return {}
	if after_anchor_id == "":
		return compatible[0]
	for i in range(compatible.size()):
		if String(compatible[i].get("anchor_id", "")) == after_anchor_id:
			return compatible[(i + 1) % compatible.size()]
	return compatible[0]

func _compatible_anchors(item: Dictionary) -> Array[Dictionary]:
	var tags: Array = item.get("placement_tags", [])
	var compatible: Array[Dictionary] = []
	for anchor in anchors:
		for tag in tags:
			if Array(anchor.get("allowed_tags", [])).has(tag):
				compatible.append(anchor)
				break
	return compatible

func _default_anchors() -> Array[Dictionary]:
	return [
		{"anchor_id": "decor_anchor_furniture_01", "allowed_tags": ["floor_item", "furniture", "large_furniture"], "position": Vector2(470, 120)},
		{"anchor_id": "decor_anchor_furniture_02", "allowed_tags": ["floor_item", "furniture", "large_furniture"], "position": Vector2(-620, 330)},
		{"anchor_id": "decor_anchor_furniture_03", "allowed_tags": ["floor_item", "furniture", "large_furniture"], "position": Vector2(290, 260)},
		{"anchor_id": "decor_anchor_rug_01", "allowed_tags": ["rug", "floor_item"], "position": Vector2(0, 165)},
		{"anchor_id": "decor_anchor_wall_01", "allowed_tags": ["wall_item", "light"], "position": Vector2(-850, -330)},
		{"anchor_id": "decor_anchor_wall_02", "allowed_tags": ["wall_item", "light"], "position": Vector2(760, -210)},
		{"anchor_id": "decor_anchor_care_01", "allowed_tags": ["care_station_item", "bentley_item", "tabletop_item"], "position": Vector2(560, 370)},
		{"anchor_id": "decor_anchor_shelf_01", "allowed_tags": ["shelf_item", "tabletop_item", "mission_trophy", "collectible_display"], "position": Vector2(-860, 185)},
		{"anchor_id": "decor_anchor_tabletop_01", "allowed_tags": ["tabletop_item"], "position": Vector2(0, 55)},
		{"anchor_id": "decor_anchor_trophy_01", "allowed_tags": ["mission_trophy", "shelf_item"], "position": Vector2(-840, 250)},
	]
