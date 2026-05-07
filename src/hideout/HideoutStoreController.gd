extends Node
class_name HideoutStoreController

const CATEGORIES := {
	"furniture": "Furniture",
	"wall_decor": "Wall Decor",
	"rugs": "Rugs",
	"lights": "Lights",
	"bentley_items": "Bentley Items",
	"care_station_upgrades": "Care Station Upgrades",
	"collectible_displays": "Collectible Displays",
	"mission_trophies": "Mission Trophies",
}

const ITEMS := [
	{"item_id": "taco_bell_stool", "category": "furniture", "display": "Taco Bell Stool", "cost": 35, "description": "A stool with the confidence of a drive-thru receipt."},
	{"item_id": "employees_must_wash_paws_sign", "category": "wall_decor", "display": "Employees Must Wash Paws Sign", "cost": 20, "description": "A sign for a workplace that does not exist and yet feels legally necessary."},
	{"item_id": "sauce_packet_rug", "category": "rugs", "display": "Sauce Packet Rug", "cost": 45, "description": "A rug that makes the floor look mildly guilty."},
	{"item_id": "neon_menu_panel", "category": "lights", "display": "Neon Menu Panel", "cost": 60, "description": "Glows with the exact energy of a bad plan becoming tradition."},
	{"item_id": "mild_sauce_throw_pillow", "category": "bentley_items", "display": "Mild Sauce Throw Pillow", "cost": 25, "description": "Bentley does not understand branding. Bentley understands pillows."},
	{"item_id": "drive_thru_headset", "category": "care_station_upgrades", "display": "Drive-Thru Headset", "cost": 30, "description": "For hearing crimes before they reach the window."},
	{"item_id": "security_booth_monitor", "category": "collectible_displays", "display": "Security Booth Monitor", "cost": 50, "description": "Shows static, suspicious dots, and occasionally your reflection."},
	{"item_id": "suspicious_fry_basket", "category": "mission_trophies", "display": "Suspicious Fry Basket", "cost": 40, "description": "Nobody knows why it is suspicious. That is what makes it suspicious."},
]

func get_panel_data(state_controller: Node = null, category_id: String = "") -> Dictionary:
	return {
		"title": "Store Terminal",
		"body": get_panel_body(state_controller, category_id),
		"buttons": get_buttons(category_id),
	}

func get_panel_body(state_controller = null, category_id: String = "") -> String:
	var louis := state_controller != null and bool(state_controller.get("louis_unlocked"))
	var store := _store_state(state_controller)
	var lines: Array[String] = [
		"Store Terminal",
		"",
		"Vendor: %s" % ("Louis's suspicious lamp network" if louis else "Anonymous catalog terminal"),
		"Debug currency: %d" % int(store.get("currency_debug_amount", 0)),
		"",
	]
	if category_id == "":
		lines.append("Categories:")
		for key in CATEGORIES.keys():
			lines.append("- %s" % CATEGORIES[key])
	else:
		lines.append("%s:" % CATEGORIES.get(category_id, "Store Category"))
		for item in ITEMS:
			if String(item.get("category", "")) != category_id:
				continue
			var unlocked: bool = _is_available(String(item.get("item_id", "")), state_controller)
			var purchased: bool = store.get("purchased_store_items", []).has(String(item.get("item_id", "")))
			lines.append("- %s [%s] - %d coins" % [String(item.get("display", "")), "Purchased" if purchased else ("Unlocked" if unlocked else "Locked"), int(item.get("cost", 0))])
			lines.append("  %s" % String(item.get("description", "")))
	if louis:
		lines.append("")
		lines.append("Louis flavor: everything fell off a truck. Emotionally.")
	lines.append("")
	lines.append("Purchases are placeholder/local state only; no final economy is active yet.")
	return "\n".join(lines)

func get_buttons(category_id: String = "") -> Array:
	if category_id == "":
		return [
			{"id": "furniture", "label": "View Furniture", "action": "show_store_category", "category_id": "furniture"},
			{"id": "wall_decor", "label": "View Wall Decor", "action": "show_store_category", "category_id": "wall_decor"},
			{"id": "rugs", "label": "View Rugs", "action": "show_store_category", "category_id": "rugs"},
			{"id": "lights", "label": "View Lights", "action": "show_store_category", "category_id": "lights"},
			{"id": "bentley_items", "label": "View Bentley Items", "action": "show_store_category", "category_id": "bentley_items"},
			{"id": "care_station_upgrades", "label": "View Care Upgrades", "action": "show_store_category", "category_id": "care_station_upgrades"},
			{"id": "mission_trophies", "label": "View Mission Trophies", "action": "show_store_category", "category_id": "mission_trophies"},
			{"id": "back", "label": "Back", "action": "close"},
		]
	var first_item := ""
	for item in ITEMS:
		if String(item.get("category", "")) == category_id:
			first_item = String(item.get("item_id", ""))
			break
	return [
		{"id": "buy_selected_placeholder", "label": "Buy Selected Placeholder", "action": "buy_store_placeholder", "item_id": first_item, "category_id": category_id},
		{"id": "back_categories", "label": "Back To Categories", "action": "show_store_category", "category_id": ""},
		{"id": "back", "label": "Back", "action": "close"},
	]

func purchase_placeholder(item_id: String, state_controller: Node = null) -> String:
	var item := _item(item_id)
	if item.is_empty():
		return "No store item selected, but the placeholder action handled safely."
	if not _is_available(item_id, state_controller):
		return "%s is still locked. Finish the right debug state first." % String(item.get("display", item_id))
	if state_controller != null and state_controller.has_method("purchase_item"):
		state_controller.purchase_item(item_id)
	return "%s purchased as a local placeholder. Delivery/placement comes in a later pass." % String(item.get("display", item_id))

func _store_state(state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_store_state"):
		return state_controller.get_store_state()
	return {"available_store_items": [], "purchased_store_items": [], "currency_debug_amount": 0}

func _is_available(item_id: String, state_controller: Node = null) -> bool:
	if state_controller == null:
		return false
	return state_controller.get("available_store_items").has(item_id)

func _item(item_id: String) -> Dictionary:
	for item in ITEMS:
		if String(item.get("item_id", "")) == item_id:
			return item
	return {}
