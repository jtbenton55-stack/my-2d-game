class_name MissionPauseDataProvider
extends RefCounted
## Mission-agnostic pause payload builder (0M-D2). Not an autoload.


static func get_provider_id() -> String:
	return "MissionPauseDataProvider"


static func has_mission_context(mission_id: String = "", mission_node: Node = null) -> bool:
	var mid := _effective_mission_id(mission_id, mission_node)
	return mid != ""


static func get_objective_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var warnings: Array[String] = []
	var mid := _effective_mission_id(mission_id, mission_node)
	var items: Array[Dictionary] = []
	if mid == "":
		warnings.append("empty_mission_id")
		return {"ok": true, "mission_id": "", "items": items, "warnings": warnings}
	var snap := MissionObjectiveBridge.get_objective_snapshot(mid)
	for line in snap.get("quest_active_list", []):
		items.append({"kind": "active", "text": String(line)})
	for line in snap.get("quest_completed_list", []):
		items.append({"kind": "completed", "text": String(line)})
	return {"ok": true, "mission_id": mid, "items": items, "warnings": warnings, "raw": snap}


static func get_scheme_card_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var snap := MissionSchemeBridge.get_scheme_snapshot(mid)
	var items: Array[Dictionary] = []
	for row in snap.get("equipped", []):
		if row is Dictionary:
			items.append(row)
	return {
		"ok": snap.get("ok", false),
		"mission_id": mid,
		"items": items,
		"warnings": snap.get("warnings", []),
		"loadout_slots": snap.get("loadout_slots", []),
		"legacy_selected_card_ids": snap.get("legacy_selected_card_ids", []),
		"scheme_debug_note": snap.get("scheme_debug_note", ""),
		"unlocked_ids": snap.get("unlocked_ids", []),
	}


static func get_clue_snapshot(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var raw := MissionClueBridge.get_clue_snapshot(mid)
	var items: Array[Dictionary] = []
	for clue in raw.get("items", []):
		if clue is Dictionary and clue.get("discovered", false) == true:
			items.append(
				{
					"id": String(clue.get("clue_id", "")),
					"title": String(clue.get("title", "")),
					"description": String(clue.get("description", "")),
				}
			)
	return {"ok": raw.get("ok", false), "mission_id": mid, "items": items, "warnings": raw.get("warnings", [])}


## Plain-English heat line for pause (D6-01). No raw API identifiers in the string.
static func get_heat_security_pause_line(mission_id: String = "", mission_node: Node = null) -> String:
	var mid := _effective_mission_id(mission_id, mission_node)
	if mid == "" or not MissionAutoloadResolver.has_game_state():
		return ""
	var heat := GameState.get_mission_heat(mid)
	return "Heat: %d/5 — failed runs make this mission more guarded on replay. Current alarms affect only this attempt." % heat


static func get_pause_payload(mission_id: String = "", mission_node: Node = null) -> Dictionary:
	var mid := _effective_mission_id(mission_id, mission_node)
	var warnings: Array[String] = []
	var obj := get_objective_snapshot(mid, mission_node)
	var sch := get_scheme_card_snapshot(mid, mission_node)
	var clu := get_clue_snapshot(mid, mission_node)
	warnings.append_array(obj.get("warnings", []))
	warnings.append_array(sch.get("warnings", []))
	warnings.append_array(clu.get("warnings", []))
	return {
		"ok": true,
		"mission_id": mid,
		"objectives": obj.get("items", []),
		"scheme_cards": sch.get("items", []),
		"clues": clu.get("items", []),
		"warnings": warnings,
		"heat_security_line": get_heat_security_pause_line(mid, mission_node),
	}


static func _effective_mission_id(mission_id: String, mission_node: Node) -> String:
	if mission_id != "":
		return mission_id
	if mission_node != null and mission_node.has_method("get_mission_id"):
		return String(mission_node.call("get_mission_id"))
	if MissionAutoloadResolver.has_game_state():
		return String(GameState.current_mission_id)
	return ""
