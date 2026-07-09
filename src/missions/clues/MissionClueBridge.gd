class_name MissionClueBridge
extends RefCounted
## Read-only + safe mutations for Sterling / evidence clues via GameState (0M-D2).


static func get_bridge_id() -> String:
	return "MissionClueBridge"


static func get_clue_snapshot(mission_id: String = "") -> Dictionary:
	var warnings: Array[String] = []
	var items: Array[Dictionary] = []
	if not MissionAutoloadResolver.has_game_state():
		warnings.append("GameState unavailable")
		return {"ok": false, "mission_id": mission_id, "items": items, "warnings": warnings}
	var filter_mid := mission_id
	var seen: Dictionary = {}
	for clue_id in GameState.sterling_clues.keys():
		var clue: Dictionary = GameState.sterling_clues[clue_id].duplicate(true)
		var cmid := String(clue.get("mission_id", ""))
		if filter_mid != "" and cmid != "" and cmid != filter_mid:
			continue
		clue["clue_id"] = clue_id
		if not clue.has("title"):
			clue["title"] = String(clue.get("display_name", clue_id))
		if not clue.has("description"):
			clue["description"] = String(clue.get("clue_text", ""))
		items.append(clue)
		seen[String(clue_id)] = true
	for clue_id in GameState.evidence_clues.keys():
		if seen.has(String(clue_id)):
			continue
		var clue: Dictionary = GameState.evidence_clues[clue_id].duplicate(true)
		var cmid := String(clue.get("mission_id", clue.get("found_in_mission", "")))
		if filter_mid != "" and cmid != "" and cmid != filter_mid:
			continue
		clue["clue_id"] = clue_id
		if not clue.has("title"):
			clue["title"] = String(clue.get("display_name", clue.get("short_name", clue_id)))
		if not clue.has("description"):
			clue["description"] = String(clue.get("clue_text", clue.get("text", "")))
		if not clue.has("discovered"):
			clue["discovered"] = String(clue.get("found_state", "")).strip_edges().to_lower() == "found"
		items.append(clue)
	return {"ok": true, "mission_id": filter_mid, "items": items, "warnings": warnings}


static func mark_clue_collected(clue_id: String, _mission_id: String = "") -> void:
	if clue_id == "" or not MissionAutoloadResolver.has_game_state():
		return
	if GameState.sterling_clues.has(clue_id):
		GameState.discover_sterling_clue(clue_id)
	elif GameState.has_method("ensure_and_discover_sterling_clue"):
		GameState.ensure_and_discover_sterling_clue(clue_id, {"title": clue_id, "mission_id": _mission_id})


static func reset_runtime_clues(_mission_id: String = "") -> void:
	## No-op: clearing persisted clues would change save semantics; missions reset via mission runtime.
	pass
