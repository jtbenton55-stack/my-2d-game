class_name MissionSchemeBridge
extends RefCounted
## Scheme card snapshot via GameState + CardManager autoloads (0M-D2).


static func get_bridge_id() -> String:
	return "MissionSchemeBridge"


static func get_active_scheme_cards(mission_id: String = "") -> Array:
	var out: Array = []
	if not Engine.has_singleton("CardManager"):
		return out
	var _mid := mission_id
	for card in CardManager.get_selected_cards():
		out.append(card)
	return out


static func get_scheme_snapshot(mission_id: String = "") -> Dictionary:
	var warnings: Array[String] = []
	var equipped: Array[Dictionary] = []
	if not Engine.has_singleton("GameState"):
		warnings.append("GameState missing")
		return {"ok": false, "mission_id": mission_id, "equipped": equipped, "unlocked_ids": [], "warnings": warnings}
	if not Engine.has_singleton("CardManager"):
		warnings.append("CardManager missing")
		return {
			"ok": false,
			"mission_id": mission_id,
			"equipped": equipped,
			"unlocked_ids": GameState.unlocked_cards.duplicate(),
			"warnings": warnings,
		}
	for card in CardManager.get_selected_cards():
		if card == null:
			continue
		equipped.append(
			{
				"id": String(card.get("id", "")),
				"display_name": String(card.get("display_name", card.get("id", ""))),
				"effect_key": String(card.get("effect_key", "")),
				"effect_value": float(card.get("effect_value", 0.0)),
			}
		)
	return {
		"ok": true,
		"mission_id": mission_id,
		"equipped": equipped,
		"unlocked_ids": GameState.unlocked_cards.duplicate(),
		"warnings": warnings,
	}


static func has_scheme_effect(effect_id: String, _mission_id: String = "") -> bool:
	if effect_id == "" or not Engine.has_singleton("CardManager"):
		return false
	for card in CardManager.get_selected_cards():
		if card != null and String(card.get("effect_key", "")) == effect_id:
			return true
	return false
