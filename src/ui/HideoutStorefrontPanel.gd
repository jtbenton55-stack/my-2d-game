extends PanelContainer
class_name HideoutStorefrontPanel

signal closed

const PVGamesIconLibrary = preload("res://src/icons/PVGamesIconLibrary.gd")

var store_controller: Node = null
var state_controller: Node = null

var _icon_library: PVGamesIconLibrary = null
var _category_filter := "all"
var _content: GridContainer = null
var _currency_label: Label = null
var _status_label: Label = null
var _category_filter_button: OptionButton = null

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_icon_library = PVGamesIconLibrary.new()
	add_child(_icon_library)
	_icon_library.load_catalog()
	_build_ui()
	hide()

func set_store_context(store_node: Node, state_node: Node) -> void:
	store_controller = store_node
	state_controller = state_node
	if _content != null:
		refresh()

func open_store() -> void:
	add_to_group("blocking_ui")
	show()
	refresh()
	grab_focus()

func close_store() -> void:
	hide()
	remove_from_group("blocking_ui")
	closed.emit()

func refresh() -> void:
	if store_controller == null or _content == null:
		return
	_update_currency()
	_populate_categories()
	_populate_items()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_store()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	anchors_preset = Control.PRESET_CENTER
	offset_left = -520.0
	offset_top = -320.0
	offset_right = 520.0
	offset_bottom = 320.0
	custom_minimum_size = Vector2(960, 560)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "RootVBox"
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title := Label.new()
	title.text = "Neon Nook"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	header.add_child(title)

	_currency_label = Label.new()
	_currency_label.text = "Case Cash: --"
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_currency_label)

	var subheader := Label.new()
	subheader.text = "CyberCity furniture, cozy contraband, tiny gadgets, birthday-safe knick-knacks."
	subheader.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subheader)

	var controls := HBoxContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)

	var filter_label := Label.new()
	filter_label.text = "Category:"
	controls.add_child(filter_label)

	_category_filter_button = OptionButton.new()
	_category_filter_button.custom_minimum_size = Vector2(260, 0)
	_category_filter_button.item_selected.connect(_on_category_selected)
	controls.add_child(_category_filter_button)

	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_content = GridContainer.new()
	_content.name = "ItemGrid"
	_content.columns = 2
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("h_separation", 10)
	_content.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_content)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "Select an item to buy. Placement stays separate in decorating mode."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close Store"
	close_button.pressed.connect(close_store)
	root.add_child(close_button)

func _populate_categories() -> void:
	if _category_filter_button == null or store_controller == null:
		return
	var previous := _category_filter
	_category_filter_button.clear()
	_category_filter_button.add_item("All Items")
	_category_filter_button.set_item_metadata(0, "all")
	var selected_index := 0
	var categories: Array = []
	if store_controller.has_method("get_available_categories"):
		categories = store_controller.get_available_categories()
	var labels := {
		"furniture": "Furniture",
		"neon_signs": "Neon Signs",
		"wall_decor": "Wall Decor",
		"desk_gadgets": "Desk Gadgets",
		"plants_greenhouse": "Plants / Greenhouse",
		"bentley": "Bentley",
		"jake": "Jake",
		"parmida_mere": "Parmida / Mere",
		"louis": "Louis",
		"mission_room": "Mission Room",
		"knick_knacks": "Knick-Knacks",
	}
	for category in categories:
		var category_id := String(category)
		_category_filter_button.add_item(String(labels.get(category_id, category_id.capitalize())))
		var idx := _category_filter_button.get_item_count() - 1
		_category_filter_button.set_item_metadata(idx, category_id)
		if category_id == previous:
			selected_index = idx
	_category_filter_button.select(selected_index)
	_category_filter = String(_category_filter_button.get_item_metadata(selected_index))

func _populate_items() -> void:
	for child in _content.get_children():
		child.queue_free()
	var items: Array = []
	if store_controller != null and store_controller.has_method("get_storefront_items"):
		items = store_controller.get_storefront_items()
	for item in items:
		if not item is Dictionary:
			continue
		var category := String((item as Dictionary).get("category", ""))
		if _category_filter != "all" and category != _category_filter:
			continue
		_content.add_child(_create_item_card(item))

func _create_item_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(450, 150)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(86, 86)
	row.add_child(icon_frame)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_id := String(item.get("icon_id", ""))
	if _icon_library != null and icon_id != "":
		icon.texture = _icon_library.get_icon_texture(icon_id)
	icon_frame.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = String(item.get("display_name", item.get("item_id", "Store Item")))
	name_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	text_box.add_child(name_label)

	var meta := Label.new()
	meta.text = "%s - %d Case Cash" % [_pretty_category(String(item.get("category", ""))), _item_price(item)]
	meta.add_theme_color_override("font_color", Color(0.58, 0.82, 1.0))
	text_box.add_child(meta)

	var desc := Label.new()
	desc.text = String(item.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(260, 42)
	text_box.add_child(desc)

	var buy := Button.new()
	buy.text = _button_text(item)
	buy.disabled = _button_disabled(item)
	buy.pressed.connect(_buy_item.bind(String(item.get("item_id", ""))))
	text_box.add_child(buy)

	return card

func _button_text(item: Dictionary) -> String:
	var item_id := String(item.get("item_id", ""))
	if state_controller == null:
		return "Preview"
	if store_controller != null and store_controller.has_method("is_item_owned") and store_controller.is_item_owned(item_id, state_controller):
		return "Owned"
	if store_controller != null and store_controller.has_method("is_item_available") and not store_controller.is_item_available(item_id, state_controller):
		return "Locked"
	return "Buy"

func _button_disabled(item: Dictionary) -> bool:
	var item_id := String(item.get("item_id", ""))
	if state_controller == null:
		return true
	if store_controller != null and store_controller.has_method("is_item_owned") and store_controller.is_item_owned(item_id, state_controller):
		return true
	if store_controller != null and store_controller.has_method("is_item_available") and not store_controller.is_item_available(item_id, state_controller):
		return true
	return false

func _buy_item(item_id: String) -> void:
	if store_controller == null or state_controller == null:
		_status_label.text = "Preview only: full purchase state is only available inside HideoutHub."
		return
	var message := "Store purchase handler missing."
	if store_controller.has_method("purchase_placeholder"):
		message = String(store_controller.purchase_placeholder(item_id, state_controller))
	_status_label.text = message
	refresh()

func _on_category_selected(index: int) -> void:
	if _category_filter_button == null:
		return
	_category_filter = String(_category_filter_button.get_item_metadata(index))
	_populate_items()

func _update_currency() -> void:
	if _currency_label == null:
		return
	var cash := 0
	if store_controller != null and store_controller.has_method("get_case_cash"):
		cash = int(store_controller.get_case_cash(state_controller))
	_currency_label.text = "Case Cash: %d" % cash

func _item_price(item: Dictionary) -> int:
	if store_controller != null and store_controller.has_method("item_cost"):
		return int(store_controller.item_cost(item))
	return int(item.get("price", item.get("cost", 0)))

func _pretty_category(category_id: String) -> String:
	return category_id.replace("_", " ").capitalize()
