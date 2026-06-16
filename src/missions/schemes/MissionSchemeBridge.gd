class_name MissionSchemeBridge
extends RefCounted
## Scheme card snapshot via GameState + CardManager autoloads (0M-D2). Fixed 0M-D5-02A-FIX1: Godot 4 autoload detection + hideout loadout merge.


static func get_bridge_id() -> String:
	return "MissionSchemeBridge"


static func _card_dict_from_resource(card) -> Dictionary:
	if card == null:
		return {}
	return {
		"id": String(_card_property(card, "id", "")),
		"display_name": String(_card_property(card, "display_name", _card_property(card, "id", ""))),
		"effect_key": String(_card_property(card, "effect_key", "")),
		"effect_value": float(_card_property(card, "effect_value", 0.0)),
	}


static func _card_property(card, property_name: String, default_value: Variant = null) -> Variant:
	if card == null:
		return default_value
	var value: Variant = card.get(property_name)
	return default_value if value == null else value


static func _append_card_row(equipped: Array, seen: Dictionary, row: Dictionary) -> void:
	var cid := String(row.get("id", ""))
	if cid == "" or seen.has(cid):
		return
	seen[cid] = true
	equipped.append(row)


static func get_active_scheme_cards(mission_id: String = "") -> Array:
	var out: Array = []
	if not MissionAutoloadResolver.has_card_manager():
		return out
	var _mid := mission_id
	var seen: Dictionary = {}
	for card in CardManager.get_selected_cards():
		if card == null:
			continue
		var row := _card_dict_from_resource(card)
		var cid := String(row.get("id", ""))
		if cid != "" and not seen.has(cid):
			seen[cid] = true
			out.append(card)
	if not MissionAutoloadResolver.has_game_state():
		return out
	var loadout: Dictionary = GameState.get_current_scheme_loadout()
	for slot in ["plan", "trick", "comfort_chaos"]:
		var cid := String(loadout.get(slot, ""))
		if cid == "" or seen.has(cid):
			continue
		var res = CardManager.get_card(cid)
		if res != null:
			seen[cid] = true
			out.append(res)
	return out


static func get_scheme_snapshot(mission_id: String = "") -> Dictionary:
	var warnings: Array[String] = []
	var equipped: Array[Dictionary] = []
	var seen: Dictionary = {}
	if not MissionAutoloadResolver.has_game_state():
		warnings.append("GameState unavailable")
		return {
			"ok": false,
			"mission_id": mission_id,
			"equipped": equipped,
			"unlocked_ids": [],
			"loadout_slots": [],
			"legacy_selected_card_ids": [],
			"scheme_debug_note": "",
			"warnings": warnings,
		}
	var has_cm := MissionAutoloadResolver.has_card_manager()
	if not has_cm:
		warnings.append("CardManager unavailable")
	if has_cm:
		for card in CardManager.get_selected_cards():
			if card == null:
				continue
			_append_card_row(equipped, seen, _card_dict_from_resource(card))
	var loadout: Dictionary = GameState.get_current_scheme_loadout()
	var loadout_slots: Array[Dictionary] = []
	for slot in ["plan", "trick", "comfort_chaos"]:
		var cid := String(loadout.get(slot, ""))
		loadout_slots.append({"slot": slot, "card_id": cid})
		if cid == "" or seen.has(cid):
			continue
		var row: Dictionary
		if has_cm:
			var res = CardManager.get_card(cid)
			if res != null:
				row = _card_dict_from_resource(res)
			else:
				row = {"id": cid, "display_name": cid, "effect_key": "", "effect_value": 0.0}
		else:
			row = {"id": cid, "display_name": cid, "effect_key": "", "effect_value": 0.0}
		_append_card_row(equipped, seen, row)
	var legacy_selected: Array[String] = []
	for id in GameState.selected_cards:
		legacy_selected.append(String(id))
	var unlocked_merged: Array[String] = _merged_unlocked_scheme_ids()
	var scheme_debug_note := (
		"Developer notes (shown in F10 / IsoMissionDebugPanel):\n"
		+ "- Autoload loadout: GameState.current_scheme_loadout (synced from hideout on launch paths).\n"
		+ "- Mission card picker: GameState.selected_cards (CardEffects.gd and related hooks read this list).\n"
		+ "- Route gates / unlock checks: GameState.has_scheme_card() + unlock registry (separate from planning slots).\n"
		+ "- Planning-table cards are mostly narrative placeholders until a future pass wires effects into Taco."
	)
	return {
		"ok": true,
		"mission_id": mission_id,
		"equipped": equipped,
		"unlocked_ids": unlocked_merged,
		"loadout_slots": loadout_slots,
		"legacy_selected_card_ids": legacy_selected,
		"scheme_debug_note": scheme_debug_note,
		"warnings": warnings,
	}


static func _merged_unlocked_scheme_ids() -> Array[String]:
	var out: Array[String] = []
	var seen: Dictionary = {}
	for id in GameState.unlocked_cards:
		var sid := String(id)
		if sid != "" and not seen.has(sid):
			seen[sid] = true
			out.append(sid)
	for id in GameState.unlocked_scheme_cards.keys():
		var sid := String(id)
		if sid != "" and not seen.has(sid):
			seen[sid] = true
			out.append(sid)
	return out


static func has_scheme_effect(effect_id: String, mission_id: String = "") -> bool:
	var needle := effect_id.strip_edges()
	if needle == "" or not MissionAutoloadResolver.has_card_manager():
		return false
	for card in get_active_scheme_cards(mission_id):
		if card != null and String(_card_property(card, "effect_key", "")).strip_edges() == needle:
			return true
	return false
