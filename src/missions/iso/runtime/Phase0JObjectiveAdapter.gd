@tool
class_name Phase0JObjectiveAdapter
extends Node

@export var mission_id := "taco_bell_drop"


func _ready() -> void:
	set_meta("generated_by", "Phase0J-C4")
	set_meta("scene_local_only", true)


func mark_delivery_bag_collected() -> Dictionary:
	var objective_id := "delivery_bag_recovered"
	var result := mark_objective_complete(objective_id, "Recover the delivery bag")
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		game_state.dialogue_flags["phase0j:delivery_bag_collected"] = true
		if game_state.has_method("record_mission_performance_event"):
			game_state.call("record_mission_performance_event", mission_id, "delivery_bag_collected", 1)
	result["delivery_bag_flag_set"] = true
	return result


func mark_objective_complete(objective_id: String, text: String = "") -> Dictionary:
	var manager_called := false
	if has_node("/root/QuestManager"):
		var quest_manager := get_node("/root/QuestManager")
		var objective_text := text if text != "" else "Objective updated: %s" % _pretty_id(objective_id)
		if quest_manager != null and quest_manager.has_method("complete_objective_id") and objective_id in ["delivery_bag_recovered", "recover_delivery_bag", "OBJ_bag_recovery"]:
			quest_manager.call("complete_objective_id", objective_id, objective_text, mission_id)
			manager_called = true
		elif quest_manager != null and quest_manager.has_method("add_objective"):
			quest_manager.call("add_objective", objective_id, objective_text, "inspected", mission_id)
			manager_called = true
		elif quest_manager != null and quest_manager.has_method("set_objective"):
			quest_manager.call("set_objective", objective_text, mission_id)
			manager_called = true
	return {
		"success": true,
		"objective_updated": manager_called,
		"clue_menu_updated": false,
		"manager_called": "QuestManager" if manager_called else "",
		"warning": "" if manager_called else "QuestManager objective API missing; local objective state only.",
	}


func set_current_objective(objective_id: String, text: String = "", status: String = "active") -> Dictionary:
	var manager_called := false
	var objective_text := text if text != "" else _pretty_id(objective_id)
	if has_node("/root/QuestManager"):
		var quest_manager := get_node("/root/QuestManager")
		if quest_manager != null and quest_manager.has_method("set_current_objective"):
			quest_manager.call("set_current_objective", objective_id, objective_text, status, mission_id)
			manager_called = true
		elif quest_manager != null and quest_manager.has_method("set_objective"):
			quest_manager.call("set_objective", objective_text, mission_id)
			manager_called = true
	return {
		"success": true,
		"objective_updated": manager_called,
		"manager_called": "QuestManager" if manager_called else "",
		"warning": "" if manager_called else "QuestManager current objective API missing.",
	}


func add_clue(clue_id: String, payload: Dictionary = {}) -> Dictionary:
	var data := payload.duplicate(true)
	data["title"] = String(data.get("title", data.get("display_name", _pretty_id(clue_id))))
	data["description"] = String(data.get("description", "Phase0J Taco Bell redesign clue."))
	data["category"] = String(data.get("category", "Mission Bible"))
	data["mission_id"] = String(data.get("mission_id", mission_id))
	data["connects_to"] = String(data.get("connects_to", "Sterling Tower"))
	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")
		if game_state != null and game_state.has_method("ensure_and_discover_sterling_clue"):
			game_state.call("ensure_and_discover_sterling_clue", clue_id, data)
			return {
				"success": true,
				"objective_updated": false,
				"clue_menu_updated": true,
				"manager_called": "GameState",
				"warning": "",
			}
	return {
		"success": true,
		"objective_updated": false,
		"clue_menu_updated": false,
		"manager_called": "",
		"warning": "GameState clue API missing; local clue state only.",
	}


func add_intel(intel_id: String, payload: Dictionary = {}) -> Dictionary:
	return add_clue(intel_id, payload)


func refresh_objective_ui_if_possible() -> Dictionary:
	return {
		"success": true,
		"objective_updated": false,
		"clue_menu_updated": false,
		"manager_called": "",
		"warning": "No explicit objective UI refresh API found; QuestManager emits objective_updated.",
	}


func _pretty_id(id: String) -> String:
	return id.replace("_", " ").capitalize()
