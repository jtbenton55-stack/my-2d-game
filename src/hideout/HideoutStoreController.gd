extends Node
class_name HideoutStoreController

const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")

const BIRTHDAY_STORE_ITEMS_PATH := "res://data/store/birthday_store_items.json"

const CATEGORIES := {
	"furniture": "Furniture",
	"neon_signs": "Neon Signs",
	"wall_decor": "Wall Decor",
	"rugs": "Rugs",
	"lights": "Lights",
	"bentley_items": "Bentley Items",
	"bentley": "Bentley",
	"jake": "Jake's Emergency Shelf",
	"parmida_mere": "Parmida / Mere",
	"louis": "Louis Delivery Nonsense",
	"desk_gadgets": "Desk Gadgets",
	"plants_greenhouse": "Plants / Greenhouse",
	"mission_room": "Mission Room",
	"knick_knacks": "Knick-Knacks",
	"care_station_upgrades": "Care Station Upgrades",
	"collectible_displays": "Collectible Displays",
	"mission_trophies": "Mission Trophies",
}

const ITEMS := [
	{"item_id": "taco_bell_stool", "display_name": "Taco Bell Stool", "category": "furniture", "cost": 35, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["floor_item", "furniture"], "footprint_width_px": 48, "footprint_height_px": 48, "blocks_player": true, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "floor_furniture", "description": "A stool with the confidence of a drive-thru receipt.", "monogon_future_art_hint": "house/cyberpunk interior stool/chair prop"},
	{"item_id": "employees_must_wash_paws_sign", "display_name": "Employees Must Wash Paws Sign", "category": "wall_decor", "cost": 20, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["wall_item"], "footprint_width_px": 64, "footprint_height_px": 24, "blocks_player": false, "can_rotate": true, "snap_mode": "wall_row", "wall_only": true, "placement_category": "wall_decor", "description": "A sign for a workplace that does not exist and yet feels legally necessary.", "monogon_future_art_hint": "wall sign/poster prop"},
	{"item_id": "sauce_packet_rug", "display_name": "Sauce Packet Rug", "category": "rugs", "cost": 45, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["rug", "floor_item"], "footprint_width_px": 96, "footprint_height_px": 64, "blocks_player": false, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "rug", "description": "A rug that makes the floor look mildly guilty.", "monogon_future_art_hint": "rug/floor decal prop"},
	{"item_id": "neon_menu_panel", "display_name": "Neon Menu Panel", "category": "lights", "cost": 60, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["wall_item", "light"], "footprint_width_px": 80, "footprint_height_px": 32, "blocks_player": false, "can_rotate": true, "snap_mode": "wall_row", "wall_only": true, "placement_category": "wall_light", "description": "Glows with the exact energy of a bad plan becoming tradition.", "monogon_future_art_hint": "neon/cyberpunk sign or monitor prop"},
	{"item_id": "mild_sauce_throw_pillow", "display_name": "Mild Sauce Throw Pillow", "category": "bentley_items", "cost": 25, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["bentley_item", "tabletop_item"], "footprint_width_px": 32, "footprint_height_px": 32, "blocks_player": false, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "soft_decor", "description": "Bentley does not understand branding. Bentley understands pillows.", "monogon_future_art_hint": "pillow/soft prop"},
	{"item_id": "drive_thru_headset", "display_name": "Drive-Thru Headset", "category": "care_station_upgrades", "cost": 30, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["care_station_item", "tabletop_item"], "footprint_width_px": 32, "footprint_height_px": 32, "blocks_player": false, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "care_tabletop", "description": "For hearing crimes before they reach the window.", "monogon_future_art_hint": "small tabletop tech prop"},
	{"item_id": "security_booth_monitor", "display_name": "Security Booth Monitor", "category": "collectible_displays", "cost": 50, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["tabletop_item", "shelf_item"], "footprint_width_px": 48, "footprint_height_px": 32, "blocks_player": true, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "monitor", "description": "Shows static, suspicious dots, and occasionally your reflection.", "monogon_future_art_hint": "monitor/security screen prop"},
	{"item_id": "suspicious_fry_basket", "display_name": "Suspicious Fry Basket", "category": "mission_trophies", "cost": 40, "unlock_condition": "taco_bell_completed", "placeable": true, "placement_tags": ["mission_trophy", "shelf_item", "tabletop_item"], "footprint_width_px": 40, "footprint_height_px": 32, "blocks_player": false, "can_rotate": true, "snap_mode": "world_grid", "wall_only": false, "placement_category": "mission_trophy", "description": "Nobody knows why it is suspicious. That is what makes it suspicious.", "monogon_future_art_hint": "small trophy/tabletop prop"},
]

var _birthday_catalog_loaded := false
var _birthday_items: Array = []
var _birthday_items_by_id: Dictionary = {}

func get_panel_data(state_controller: Node = null, category_id: String = "") -> Dictionary:
	return {
		"title": "Neon Nook",
		"body": get_panel_body(state_controller, category_id),
		"buttons": get_buttons(category_id, state_controller),
	}

func get_panel_body(state_controller = null, category_id: String = "") -> String:
	var louis := state_controller != null and bool(state_controller.get("louis_unlocked"))
	var store := _store_state(state_controller)
	var lines: Array[String] = [
		"Neon Nook",
		"",
		"Vendor: %s" % ("Louis's suspicious lamp network" if louis else "Anonymous catalog terminal"),
		"Case Cash: %d" % int(store.get("case_cash", store.get("currency_debug_amount", 0))),
		"Furniture, cozy contraband, little birthday-safe CyberCity objects.",
		"",
	]
	if category_id == "":
		lines.append("Categories:")
		for key in get_available_categories():
			lines.append("- %s" % CATEGORIES.get(key, key.capitalize()))
		lines.append("")
		lines.append("Icon Storefront Preview:")
		for item in get_storefront_items():
			lines.append(_store_card_text(item, state_controller))
	else:
		lines.append("%s Visual Item Cards:" % CATEGORIES.get(category_id, "Store Category"))
		for item in get_storefront_items():
			if String(item.get("category", "")) != category_id:
				continue
			lines.append(_store_card_text(item, state_controller))
	if louis:
		lines.append("")
		lines.append("Louis flavor: everything fell off a truck. Emotionally.")
	lines.append("")
	lines.append("Purchases use the existing Case Cash + owned item state.")
	return "\n".join(lines)

func get_buttons(category_id: String = "", state_controller: Node = null) -> Array:
	if category_id == "":
		var category_buttons: Array = []
		for category_id_key in get_available_categories():
			category_buttons.append({
				"id": category_id_key,
				"label": "View %s" % CATEGORIES.get(category_id_key, category_id_key.capitalize()),
				"action": "store_view_category:%s" % category_id_key,
				"category_id": category_id_key,
			})
		category_buttons.append({"id": "close", "label": "Close", "action": "close"})
		return category_buttons
	var buttons: Array = []
	for item in get_storefront_items():
		if String(item.get("category", "")) == category_id:
			var item_id := String(item.get("item_id", ""))
			var store := _store_state(state_controller)
			if _is_available(item_id, state_controller) and not store.get("purchased_store_items", []).has(item_id):
				buttons.append({"id": "buy_%s" % item_id, "label": "Buy: %s" % String(item.get("display_name", item_id)), "action": "store_buy_item:%s" % item_id, "item_id": item_id, "category_id": category_id})
	buttons.append({"id": "back", "label": "Back", "action": "back"})
	buttons.append({"id": "close", "label": "Close", "action": "close"})
	return buttons

func purchase_placeholder(item_id: String, state_controller: Node = null) -> String:
	var item := _item(item_id)
	if item.is_empty():
		return "No store item selected, but the placeholder action handled safely."
	if not _is_available(item_id, state_controller):
		return "Locked. Complete The Taco Bell Drop to unlock."
	if state_controller != null and state_controller.get("purchased_store_items").has(item_id):
		return "Already owned."
	var cost := item_cost(item)
	if state_controller != null and state_controller.has_method("can_spend_case_cash") and not state_controller.can_spend_case_cash(cost):
		return DialogueBank.get_random_line("store_insufficient_funds")
	_ensure_available_for_purchase(item_id, state_controller)
	if state_controller != null and state_controller.has_method("purchase_item") and state_controller.purchase_item(item_id, cost):
		return "%s\n%s added to decor inventory." % [DialogueBank.get_random_line("store_purchase_success"), String(item.get("display_name", item_id))]
	return "Purchase handled safely, but the item was not added."

func item_by_id(item_id: String) -> Dictionary:
	return _item(item_id)

func item_display_name(item_id: String) -> String:
	var item := _item(item_id)
	return String(item.get("display_name", item_id))

func get_storefront_items() -> Array:
	_ensure_birthday_catalog_loaded()
	var out: Array = []
	for item in _birthday_items:
		if item is Dictionary and bool((item as Dictionary).get("enabled", true)):
			out.append((item as Dictionary).duplicate(true))
	# Keep older Taco Bell placeholder items available to the text fallback and
	# owned-state logic, but the polished storefront intentionally uses the
	# curated birthday catalog above.
	return out

func get_available_categories() -> Array:
	var seen := {}
	var categories: Array = []
	for item in get_storefront_items():
		var category := String((item as Dictionary).get("category", "knick_knacks"))
		if seen.has(category):
			continue
		seen[category] = true
		categories.append(category)
	return categories

func get_case_cash(state_controller: Node = null) -> int:
	var store := _store_state(state_controller)
	return int(store.get("case_cash", store.get("currency_debug_amount", 0)))

func is_item_owned(item_id: String, state_controller: Node = null) -> bool:
	var store := _store_state(state_controller)
	return store.get("purchased_store_items", []).has(item_id)

func is_item_available(item_id: String, state_controller: Node = null) -> bool:
	return _is_available(item_id, state_controller)

func item_cost(item: Dictionary) -> int:
	if item.has("price"):
		return int(item.get("price", 0))
	return int(item.get("cost", 0))

func item_icon_id(item: Dictionary) -> String:
	return String(item.get("icon_id", ""))

func _store_state(state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_store_state"):
		return state_controller.get_store_state()
	return {"available_store_items": [], "purchased_store_items": [], "currency_debug_amount": 0}

func _is_available(item_id: String, state_controller: Node = null) -> bool:
	var item := _item(item_id)
	if item.is_empty():
		return false
	if String(item.get("unlock_condition", "")) == "" and bool(item.get("enabled", true)):
		return true
	if state_controller == null:
		return false
	if String(item.get("unlock_condition", "")) == "taco_bell_completed" and bool(state_controller.get("taco_bell_completed")):
		return true
	return state_controller.get("available_store_items").has(item_id)

func _item(item_id: String) -> Dictionary:
	_ensure_birthday_catalog_loaded()
	if _birthday_items_by_id.has(item_id):
		return (_birthday_items_by_id[item_id] as Dictionary).duplicate(true)
	for item in ITEMS:
		if String(item.get("item_id", "")) == item_id:
			return item
	return {}

func _ensure_birthday_catalog_loaded() -> void:
	if _birthday_catalog_loaded:
		return
	_birthday_catalog_loaded = true
	_birthday_items.clear()
	_birthday_items_by_id.clear()
	if not FileAccess.file_exists(BIRTHDAY_STORE_ITEMS_PATH):
		push_warning("[HideoutStoreController] Birthday store catalog missing: %s" % BIRTHDAY_STORE_ITEMS_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BIRTHDAY_STORE_ITEMS_PATH))
	if not parsed is Dictionary:
		push_warning("[HideoutStoreController] Birthday store catalog did not parse as Dictionary.")
		return
	for raw_item in (parsed as Dictionary).get("items", []):
		if not raw_item is Dictionary:
			continue
		var item := (raw_item as Dictionary).duplicate(true)
		var item_id := String(item.get("item_id", ""))
		if item_id == "":
			continue
		_birthday_items.append(item)
		_birthday_items_by_id[item_id] = item

func _ensure_available_for_purchase(item_id: String, state_controller: Node = null) -> void:
	if state_controller == null or not _has_property(state_controller, "available_store_items"):
		return
	var available: Array = state_controller.get("available_store_items")
	if not available.has(item_id):
		available.append(item_id)
		state_controller.set("available_store_items", available)

func _has_property(node: Object, property_name: String) -> bool:
	if node == null:
		return false
	for property in node.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false

func _store_card_text(item: Dictionary, state_controller: Node = null) -> String:
	var item_id := String(item.get("item_id", ""))
	var store := _store_state(state_controller)
	var unlocked: bool = _is_available(item_id, state_controller)
	var owned: bool = store.get("purchased_store_items", []).has(item_id)
	var state_text: String = "Owned" if owned else ("Unlocked" if unlocked else "Locked")
	var lines: Array[String] = [
		"",
		"+--------------------------------------------------+",
		"| [ICON] %s" % String(item.get("display_name", item_id)),
		"| Category: %s" % CATEGORIES.get(String(item.get("category", "")), "Store"),
		"| Cost: %d Case Cash" % item_cost(item),
		"| State: %s" % state_text,
		"| %s" % String(item.get("description", "")),
	]
	if owned:
		lines.append("| Owned - already delivered to decor inventory.")
	elif unlocked:
		lines.append("| Click Buy Card below to purchase.")
	else:
		lines.append("| Complete The Taco Bell Drop to unlock.")
	lines.append("+--------------------------------------------------+")
	return "\n".join(lines)
