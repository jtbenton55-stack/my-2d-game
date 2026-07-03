class_name MissionObjectiveBridge
extends RefCounted
## Documents and centralizes the split between QuestManager (HUD/pause text) and mission gating (Iso dictionaries).

const DISPLAY_OWNER := "QuestManager — active_objective string + structured active_objectives for pause menu"
const GATING_OWNER := "IsoMissionBase — _required_objective_ids / _completed_objective_ids (plus clues/collectibles in mission runtime)"


static func get_bridge_id() -> String:
	return "MissionObjectiveBridge"


static func publish_primary_objective(mission_id: String, text: String) -> void:
	QuestManager.set_objective(text, mission_id)


static func seed_runtime_objectives_for_mission(mission_id: String, objective_rows: Array, clear_existing: bool = true) -> Dictionary:
	var mid := mission_id.strip_edges()
	if mid == "":
		return {"ok": false, "code": "mission_id_missing", "mission_id": mission_id, "seeded": 0}
	if clear_existing:
		reset_runtime_objectives_for_mission(mid)
	var seeded := 0
	for row_v in objective_rows:
		if not (row_v is Dictionary):
			continue
		var row := row_v as Dictionary
		var objective_id := String(row.get("id", "")).strip_edges()
		if objective_id == "":
			continue
		var text := String(row.get("text", objective_id.replace("_", " ").capitalize()))
		var status := String(row.get("status", "active"))
		QuestManager.add_objective(objective_id, text, status, mid)
		seeded += 1
	return {"ok": true, "code": "runtime_objectives_seeded", "mission_id": mid, "seeded": seeded}


static func get_objective_snapshot(mission_id: String) -> Dictionary:
	return {
		"display_owner": DISPLAY_OWNER,
		"gating_owner": GATING_OWNER,
		"mission_id": mission_id,
		"quest_active_line": QuestManager.get_current_objective(mission_id),
		"quest_active_list": QuestManager.get_active_objectives(mission_id),
		"quest_completed_list": QuestManager.get_completed_objectives(mission_id),
	}


static func reset_runtime_objectives_for_mission(mission_id: String) -> Dictionary:
	var mid := mission_id.strip_edges()
	if mid == "":
		return {"ok": false, "code": "mission_id_missing", "mission_id": mission_id}
	var cleared := {
		"objectives": QuestManager.objectives.has(mid),
		"objective_records": QuestManager.objective_records.has(mid),
		"active_objectives": QuestManager.active_objectives.has(mid),
		"completed_objectives": QuestManager.completed_objectives.has(mid),
		"active_line": QuestManager.active_quest_id == mid,
	}
	QuestManager.objectives.erase(mid)
	QuestManager.objective_records.erase(mid)
	QuestManager.active_objectives.erase(mid)
	QuestManager.completed_objectives.erase(mid)
	if QuestManager.active_quest_id == mid:
		QuestManager.active_quest_id = ""
		QuestManager.active_objective = ""
		EventBus.objective_updated.emit("")
	return {"ok": true, "code": "runtime_objectives_reset", "mission_id": mid, "cleared": cleared}
