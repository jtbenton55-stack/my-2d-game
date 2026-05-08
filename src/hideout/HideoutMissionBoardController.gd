extends Node
class_name HideoutMissionBoardController

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

func get_panel_data(state_controller: Node = null) -> Dictionary:
	return {
		"title": "Mission Board",
		"body": get_panel_body(state_controller),
		"buttons": get_buttons(state_controller),
	}

func get_panel_body(state_controller = null) -> String:
	var lines: Array[String] = [
		"Mission Board",
		"",
		"Mission status / launch / replay board.",
		"Fresh missions show launch and info only. Completed missions show replay, missing-item, and heat cleanup options.",
		"",
		"Missions:",
	]
	for mission in Catalog.missions():
		var slot := int(mission.get("slot", 0))
		var name := String(mission.get("display_name", "Mission"))
		var status := _mission_status_text(String(mission.get("mission_id", "")), state_controller)
		lines.append("%02d. %s - %s" % [slot, name, status])
	lines.append("")
	var taco_status := _status_for("taco_bell_drop", state_controller)
	lines.append("Selected Mission: The Taco Bell Drop")
	lines.append("Mission ID: taco_bell_drop")
	lines.append("State: %s" % String(taco_status.get("state", "available")).capitalize())
	lines.append("Missing clues: %d" % int(taco_status.get("missing_clues", 0)))
	lines.append("Missing collectibles: %d" % int(taco_status.get("missing_collectibles", 0)))
	if taco_status.get("completed", false):
		lines.append("Heat: %s" % String(taco_status.get("heat_state", "low")).capitalize())
	else:
		lines.append("Heat: hidden until this mission is completed and replayable.")
	lines.append("")
	lines.append("No route selection, assist selection, difficulty selection, or fresh-mission heat controls are active in this scaffold.")
	return "\n".join(lines)

func get_buttons(state_controller: Node = null) -> Array:
	var status := _status_for("taco_bell_drop", state_controller)
	if not status.get("completed", false):
		return [
			{"id": "start_taco_bell", "label": "Start The Taco Bell Drop", "action": "launch_taco_bell"},
			{"id": "known_info", "label": "View Known Info", "action": "show_known_info"},
			{"id": "back", "label": "Back", "action": "close"},
		]
	if int(status.get("missing_clues", 0)) > 0 or int(status.get("missing_collectibles", 0)) > 0:
		return [
			{"id": "search_missing", "label": "Search for Missing Items", "action": "search_missing_items"},
			{"id": "replay_taco_bell", "label": "Replay Mission", "action": "replay_mission"},
			{"id": "view_missing", "label": "View Missing Items", "action": "view_missing_items"},
			{"id": "back", "label": "Back", "action": "close"},
		]
	return [
		{"id": "replay_taco_bell", "label": "Replay Mission", "action": "replay_mission"},
		{"id": "search_missing", "label": "Search for Missing Items", "action": "search_missing_items"},
		{"id": "lower_heat", "label": "Lower Heat Run", "action": "lower_heat_run"},
		{"id": "clean_getaway", "label": "Clean Getaway Attempt", "action": "clean_getaway_attempt"},
		{"id": "view_results", "label": "View Results", "action": "view_results"},
		{"id": "back", "label": "Back", "action": "close"},
	]

func launch_taco_bell() -> void:
	GameState.start_mission("taco_bell_drop")
	if get_node_or_null("/root/SceneManager") != null:
		SceneManager.change_scene(TACO_BELL_SCENE)
	else:
		get_tree().change_scene_to_file(TACO_BELL_SCENE)

func _mission_status_text(mission_id: String, state_controller: Node = null) -> String:
	if mission_id != "taco_bell_drop":
		return "Locked. Future job scaffold."
	var status := _status_for(mission_id, state_controller)
	if status.get("completed", false):
		var suffix := "Perfect" if status.get("perfect", false) else "Completed / replayable"
		var missing := int(status.get("missing_clues", 0)) + int(status.get("missing_collectibles", 0))
		if missing > 0:
			suffix += " with %d missing item(s)" % missing
		return suffix
	return "Available. Ready for delivery."

func _status_for(mission_id: String, state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_mission_status"):
		return state_controller.get_mission_status(mission_id)
	return {"state": "available", "completed": false, "missing_clues": 5, "missing_collectibles": 6, "heat_state": ""}
