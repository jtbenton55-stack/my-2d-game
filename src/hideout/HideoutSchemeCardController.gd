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
		"- Plan Card: %s" % _equipped_name("plan", state_controller),
		"- Trick Card: %s" % _equipped_name("trick", state_controller),
		"- Comfort/Chaos Card: %s" % _equipped_name("comfort_chaos", state_controller),
		"",
		"Unlocked Plan Cards:",
		"",
	]
	_append_cards_for_slot(lines, "plan", state_controller, true)
	lines.append("")
	lines.append("Unlocked Trick Cards:")
	_append_cards_for_slot(lines, "trick", state_controller, true)
	lines.append("")
	lines.append("Unlocked Comfort/Chaos Cards:")
	_append_cards_for_slot(lines, "comfort_chaos", state_controller, true)
	lines.append("")
	lines.append("Locked Taco Bell Cards:")
	_append_locked_taco_bell_cards(lines, state_controller)
	lines.append("")
	lines.append("Equip actions update the hideout loadout state only. Real mission gameplay effects are intentionally deferred.")
	return "\n".join(lines)

func get_buttons(state_controller: Node = null) -> Array:
	var buttons: Array = []
	for card in Catalog.scheme_cards():
		var card_id := String(card.get("card_id", ""))
		if _unlocked_cards(state_controller).has(card_id):
			buttons.append({"id": "equip_%s" % card_id, "label": "Equip: %s" % String(card.get("display_name", card_id)), "action": "equip_scheme_card:%s" % card_id, "card_id": card_id})
	buttons.append({"id": "clear_plan", "label": "Clear Plan Slot", "action": "clear_scheme_slot:plan", "slot_type": "plan"})
	buttons.append({"id": "clear_trick", "label": "Clear Trick Slot", "action": "clear_scheme_slot:trick", "slot_type": "trick"})
	buttons.append({"id": "clear_comfort", "label": "Clear Comfort/Chaos Slot", "action": "clear_scheme_slot:comfort_chaos", "slot_type": "comfort_chaos"})
	buttons.append({"id": "clear_all", "label": "Clear All Slots", "action": "clear_scheme_loadout"})
	buttons.append({"id": "close", "label": "Close", "action": "close"})
	return buttons

func equip_card(card_id: String, state_controller: Node = null) -> String:
	for card in Catalog.scheme_cards():
		if String(card.get("card_id", "")) == card_id:
			var slot_type := String(card.get("slot_type", ""))
			if not _unlocked_cards(state_controller).has(card_id):
				return "%s is locked. Complete The Taco Bell Drop to unlock." % String(card.get("display_name", card_id))
			if state_controller != null and state_controller.has_method("equip_card") and state_controller.equip_card(card_id, slot_type):
				return "%s equipped to %s. Mission gameplay effects are still placeholders." % [String(card.get("display_name", card_id)), _slot_label(slot_type)]
			return "%s could not be equipped, but the action handled safely." % String(card.get("display_name", card_id))
	return "Unknown scheme card action was handled safely."

func clear_slot(slot_type: String, state_controller: Node = null) -> String:
	if state_controller != null and state_controller.has_method("clear_scheme_slot"):
		state_controller.clear_scheme_slot(slot_type)
	return "%s slot cleared." % _slot_label(slot_type)

func clear_loadout(state_controller: Node = null) -> String:
	if state_controller != null and state_controller.has_method("clear_loadout"):
		state_controller.clear_loadout()
	return "Scheme loadout cleared."

func card_name(card_id: String) -> String:
	for card in Catalog.scheme_cards():
		if String(card.get("card_id", "")) == card_id:
			return String(card.get("display_name", card_id))
	return "Empty" if card_id == "" else card_id

func _equipped_name(slot_type: String, state_controller: Node = null) -> String:
	if state_controller == null:
		return "Empty"
	var loadout: Dictionary = state_controller.get_current_scheme_loadout() if state_controller.has_method("get_current_scheme_loadout") else {}
	return card_name(String(loadout.get(slot_type, "")))

func _unlocked_cards(state_controller: Node = null) -> Array:
	if state_controller != null:
		return state_controller.get("unlocked_scheme_cards")
	return ["bentley_sniff_pass", "treat_based_negotiation", "definitely_normal_hoodie"]

func _append_cards_for_slot(lines: Array[String], slot_type: String, state_controller: Node, unlocked_only: bool) -> void:
	for card in Catalog.scheme_cards():
		if String(card.get("slot_type", "")) != slot_type:
			continue
		var card_id := String(card.get("card_id", ""))
		var unlocked := _unlocked_cards(state_controller).has(card_id)
		if unlocked_only and not unlocked:
			continue
		lines.append("- %s: %s" % [String(card.get("display_name", card_id)), String(card.get("description", ""))])
		lines.append("  Effect: %s" % String(card.get("short_effect_summary", "")))

func _append_locked_taco_bell_cards(lines: Array[String], state_controller: Node) -> void:
	var found := false
	for card in Catalog.scheme_cards():
		var card_id := String(card.get("card_id", ""))
		if String(card.get("unlock_condition", "")) != "taco_bell_completed" or _unlocked_cards(state_controller).has(card_id):
			continue
		found = true
		lines.append("- %s: Complete The Taco Bell Drop to unlock." % String(card.get("display_name", card_id)))
	if not found:
		lines.append("- None. Taco Bell scheme cards are unlocked.")

func _slot_label(slot_type: String) -> String:
	match slot_type:
		"plan":
			return "Plan Card"
		"trick":
			return "Trick Card"
		"comfort_chaos":
			return "Comfort/Chaos Card"
		_:
			return slot_type.capitalize()
