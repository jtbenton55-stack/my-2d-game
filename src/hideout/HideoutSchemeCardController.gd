extends Node
class_name HideoutSchemeCardController

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")

func get_panel_data(state_controller: Node = null) -> Dictionary:
	return {
		"title": "Planning Table",
		"body": get_panel_body(state_controller),
		"buttons": get_buttons(state_controller),
	}

func get_panel_body(state_controller = null) -> String:
	var lines: Array[String] = [
		"Planning Table / Scheme Cards",
		"",
		"Active Slots:",
		"- Plan Card: %s" % _equipped_name("equipped_plan_card", state_controller),
		"- Trick Card: %s" % _equipped_name("equipped_trick_card", state_controller),
		"- Comfort/Chaos Card: %s" % _equipped_name("equipped_comfort_chaos_card", state_controller),
		"",
		"Unlocked / Locked Cards:",
		"",
	]
	for card in Catalog.scheme_cards():
		var card_id := String(card.get("card_id", ""))
		var unlocked := _unlocked_cards(state_controller).has(card_id)
		lines.append("- %s [%s] (%s): %s" % [String(card.get("name", "")), "Unlocked" if unlocked else "Locked", String(card.get("slot_type", "")), String(card.get("description", ""))])
	lines.append("")
	lines.append("Equip actions update the hideout loadout state only. Real mission gameplay effects are intentionally deferred.")
	return "\n".join(lines)

func get_buttons(_state_controller: Node = null) -> Array:
	return [
		{"id": "view_scheme_cards", "label": "View Scheme Cards", "action": "show_scheme_cards"},
		{"id": "equip_bentley_sniff_pass", "label": "Equip Bentley Sniff Pass", "action": "equip_scheme_card", "card_id": "bentley_sniff_pass"},
		{"id": "equip_treat_based_negotiation", "label": "Equip Treat-Based Negotiation", "action": "equip_scheme_card", "card_id": "treat_based_negotiation"},
		{"id": "equip_definitely_normal_hoodie", "label": "Equip Definitely Normal Hoodie", "action": "equip_scheme_card", "card_id": "definitely_normal_hoodie"},
		{"id": "clear_loadout", "label": "Clear Loadout", "action": "clear_loadout"},
		{"id": "back", "label": "Back", "action": "close"},
	]

func equip_card(card_id: String, state_controller: Node = null) -> String:
	for card in Catalog.scheme_cards():
		if String(card.get("card_id", "")) == card_id:
			var slot_type := String(card.get("slot_type", ""))
			if state_controller != null and state_controller.has_method("equip_card"):
				state_controller.equip_card(card_id, slot_type)
			return "%s equipped to %s. Mission gameplay effects are still placeholders." % [String(card.get("name", card_id)), slot_type]
	return "Unknown scheme card action was handled safely."

func clear_loadout(state_controller: Node = null) -> String:
	if state_controller != null and state_controller.has_method("clear_loadout"):
		state_controller.clear_loadout()
	return "Scheme loadout cleared."

func card_name(card_id: String) -> String:
	for card in Catalog.scheme_cards():
		if String(card.get("card_id", "")) == card_id:
			return String(card.get("name", card_id))
	return "None" if card_id == "" else card_id

func _equipped_name(field_name: String, state_controller: Node = null) -> String:
	if state_controller == null:
		return "None"
	return card_name(String(state_controller.get(field_name)))

func _unlocked_cards(state_controller: Node = null) -> Array:
	if state_controller != null:
		return state_controller.get("unlocked_scheme_cards")
	return ["bentley_sniff_pass", "treat_based_negotiation", "definitely_normal_hoodie"]
