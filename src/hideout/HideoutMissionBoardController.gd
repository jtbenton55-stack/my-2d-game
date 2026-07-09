extends Node
class_name HideoutMissionBoardController

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")

const CORNER_STORE_MISSION_ID := "corner_store_cashout"
const TACO_BELL_MISSION_ID := "taco_bell_drop"

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
		var mid := String(mission.get("mission_id", ""))
		var status := _mission_status_text(mid, state_controller)
		lines.append("%02d. %s - %s" % [slot, name, status])
	lines.append("")
	var selected := _selected_mission_id(state_controller)
	var selected_name := _mission_display_name(selected)
	var selected_status := _status_for(selected, state_controller)
	lines.append("Selected Mission: %s" % selected_name)
	lines.append("Mission ID: %s" % selected)
	lines.append("State: %s" % String(selected_status.get("state", "available")).capitalize())
	lines.append("Missing clues: %d" % int(selected_status.get("missing_clues", 0)))
	lines.append("Missing collectibles: %d" % int(selected_status.get("missing_collectibles", 0)))
	lines.append(_heat_briefing_line(selected))
	lines.append("")
	lines.append("No route selection, assist selection, difficulty selection, or fresh-mission heat controls are active in this scaffold.")
	return "\n".join(lines)

func get_buttons(state_controller: Node = null) -> Array:
	var taco_status := _status_for(TACO_BELL_MISSION_ID, state_controller)
	if not taco_status.get("completed", false):
		var buttons := [
			{"id": "start_taco_bell", "label": "Start The Taco Bell Drop", "action": "launch_taco_bell"},
			{"id": "known_info", "label": "View Known Info", "action": "show_known_info"},
			{"id": "back", "label": "Back", "action": "close"},
		]
		if OS.is_debug_build():
			buttons.insert(buttons.size() - 1, {"id": "dev_mark_taco_complete", "label": "DEV: Mark Taco Bell Complete", "action": "dev_mark_taco_bell_complete"})
			buttons.insert(buttons.size() - 1, {"id": "dev_start_corner_store", "label": "DEV: Start Corner Store Cashout", "action": "launch_corner_store_cashout"})
		return buttons
	var corner_status := _status_for(CORNER_STORE_MISSION_ID, state_controller)
	if not corner_status.get("completed", false):
		return [
			{"id": "start_corner_store", "label": "Start Corner Store Cashout", "action": "launch_corner_store_cashout"},
			{"id": "replay_taco_bell", "label": "Replay Taco Bell Drop", "action": "replay_mission"},
			{"id": "known_info_corner_store", "label": "View Corner Store Info", "action": "show_corner_store_info"},
			{"id": "back", "label": "Back", "action": "close"},
		]
	return [
		{"id": "replay_corner_store", "label": "Replay Corner Store Cashout", "action": "replay_corner_store_cashout"},
		{"id": "replay_taco_bell", "label": "Replay Taco Bell Drop", "action": "replay_mission"},
		{"id": "search_missing", "label": "Search for Missing Items", "action": "search_missing_items"},
		{"id": "view_results", "label": "View Results", "action": "view_results"},
		{"id": "back", "label": "Back", "action": "close"},
	]

func launch_taco_bell() -> void:
	_launch_mission(TACO_BELL_MISSION_ID)

func launch_corner_store_cashout() -> void:
	_launch_mission(CORNER_STORE_MISSION_ID)

func _launch_mission(mission_id: String) -> void:
	GameState.start_mission(mission_id)
	var scene_path := MissionSceneResolver.resolve_playable_scene_path(mission_id)
	if is_inside_tree() and get_tree().root.get_node_or_null("SceneManager") != null:
		SceneManager.change_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)

func _mission_status_text(mission_id: String, state_controller: Node = null) -> String:
	if mission_id == TACO_BELL_MISSION_ID:
		var status := _status_for(mission_id, state_controller)
		if status.get("completed", false):
			var suffix := "Perfect" if status.get("perfect", false) else "Completed / replayable"
			var missing := int(status.get("missing_clues", 0)) + int(status.get("missing_collectibles", 0))
			if missing > 0:
				suffix += " with %d missing item(s)" % missing
			return suffix
		return "Available. Ready for delivery."
	if mission_id == CORNER_STORE_MISSION_ID:
		var taco_done := bool(_status_for(TACO_BELL_MISSION_ID, state_controller).get("completed", false))
		if not taco_done and not OS.is_debug_build():
			return "Locked until Taco Bell is complete."
		var corner_status := _status_for(mission_id, state_controller)
		if corner_status.get("completed", false):
			return "Completed / replayable"
		return "Available. Neon convenience-store micro-heist."
	return "Locked. Future job scaffold."

func _selected_mission_id(state_controller: Node = null) -> String:
	var taco_status := _status_for(TACO_BELL_MISSION_ID, state_controller)
	if not taco_status.get("completed", false):
		return TACO_BELL_MISSION_ID
	var corner_status := _status_for(CORNER_STORE_MISSION_ID, state_controller)
	if not corner_status.get("completed", false):
		return CORNER_STORE_MISSION_ID
	return CORNER_STORE_MISSION_ID

func _mission_display_name(mission_id: String) -> String:
	for mission in Catalog.missions():
		if String(mission.get("mission_id", "")) == mission_id:
			return String(mission.get("display_name", mission_id))
	return mission_id

## Replan Packet 6: heat briefing line driven by Investigation Report venue heat.
func _heat_briefing_line(mission_id: String) -> String:
	var heat := GameState.get_mission_heat(mission_id)
	if heat <= 0:
		return "Heat: 0/5 - quiet venue. Standard security."
	var warnings: Array[String] = []
	if heat >= 1:
		warnings.append("jumpy staff")
	if heat >= 2:
		warnings.append("extra patrol pressure")
	if heat >= 4:
		warnings.append("detective on site")
	return "Heat: %d/5 - %s. Consider a cool-down shift at the Heat Scanner." % [heat, ", ".join(warnings)]


func _status_for(mission_id: String, state_controller: Node = null) -> Dictionary:
	if state_controller != null and state_controller.has_method("get_mission_status"):
		return state_controller.get_mission_status(mission_id)
	if mission_id == CORNER_STORE_MISSION_ID and GameState.has_completed(TACO_BELL_MISSION_ID):
		return {"state": "available", "completed": GameState.has_completed(mission_id), "missing_clues": 0, "missing_collectibles": 0, "heat_state": ""}
	return {"state": "available", "completed": false, "missing_clues": 5, "missing_collectibles": 6, "heat_state": ""}
