class_name MissionObjectiveBridge
extends RefCounted
## Documents and centralizes the split between QuestManager (HUD/pause text) and mission gating (Iso dictionaries).

const DISPLAY_OWNER := "QuestManager — active_objective string + structured active_objectives for pause menu"
const GATING_OWNER := "IsoMissionBase — _required_objective_ids / _completed_objective_ids (plus clues/collectibles in mission runtime)"


static func get_bridge_id() -> String:
	return "MissionObjectiveBridge"


static func publish_primary_objective(mission_id: String, text: String) -> void:
	QuestManager.set_objective(text, mission_id)


static func get_objective_snapshot(mission_id: String) -> Dictionary:
	return {
		"display_owner": DISPLAY_OWNER,
		"gating_owner": GATING_OWNER,
		"mission_id": mission_id,
		"quest_active_line": QuestManager.get_current_objective(mission_id),
		"quest_active_list": QuestManager.get_active_objectives(mission_id),
		"quest_completed_list": QuestManager.get_completed_objectives(mission_id),
	}


static func reset_runtime_objectives_for_mission(_mission_id: String) -> void:
	## Reserved for future explicit reset without touching persistent save data.
	pass
