extends Node

var active_quest_id := ""
var active_objective := ""
var objectives: Dictionary = {}
var objective_records: Dictionary = {}
var active_objectives: Dictionary = {}
var completed_objectives: Dictionary = {}

func _ready() -> void:
	EventBus.debug("QuestManager ready")

func set_objective(text: String, quest_id = "") -> void:
	active_quest_id = quest_id
	active_objective = text
	if quest_id != "":
		objectives[quest_id] = text
	EventBus.objective_updated.emit(text)


func add_objective(objective_id: String, text := "", status := "active", mission_id := "") -> Dictionary:
	if mission_id == "":
		mission_id = active_quest_id if active_quest_id != "" else "global"
	var objective_text := text if text != "" else objective_id.replace("_", " ").capitalize()
	if not objective_records.has(mission_id):
		objective_records[mission_id] = {}
	if not active_objectives.has(mission_id):
		active_objectives[mission_id] = {}
	objective_records[mission_id][objective_id] = {
		"id": objective_id,
		"text": objective_text,
		"status": status,
		"mission_id": mission_id,
	}
	if status != "completed" and status != "locked":
		active_objectives[mission_id][objective_id] = objective_records[mission_id][objective_id]
	if status == "active" or active_objective == "":
		active_quest_id = mission_id
		active_objective = objective_text
		objectives[mission_id] = objective_text
	EventBus.objective_updated.emit(objective_text)
	return objective_records[mission_id][objective_id]


func set_current_objective(objective_id: String, text := "", status := "active", mission_id := "") -> Dictionary:
	return add_objective(objective_id, text, status, mission_id)


func complete_objective_id(objective_id: String, text := "", mission_id := "") -> Dictionary:
	if mission_id == "":
		mission_id = active_quest_id if active_quest_id != "" else "global"
	var objective_text := text if text != "" else objective_id.replace("_", " ").capitalize()
	if not completed_objectives.has(mission_id):
		completed_objectives[mission_id] = []
	if active_objectives.has(mission_id):
		active_objectives[mission_id].erase(objective_id)
	var completed: Array = completed_objectives[mission_id]
	if not completed.has(objective_text):
		completed.append(objective_text)
	if not objective_records.has(mission_id):
		objective_records[mission_id] = {}
	objective_records[mission_id][objective_id] = {
		"id": objective_id,
		"text": objective_text,
		"status": "completed",
		"mission_id": mission_id,
	}
	if objectives.get(mission_id, "") == objective_text:
		objectives.erase(mission_id)
		active_objective = ""
	EventBus.objective_updated.emit("Objective complete: %s" % objective_text)
	return objective_records[mission_id][objective_id]


func get_current_objective(mission_id := "") -> String:
	if mission_id != "" and objectives.has(mission_id):
		return String(objectives[mission_id])
	return active_objective if active_objective != "" else "No active objective."


func get_completed_objectives(mission_id := "") -> Array:
	if mission_id != "" and completed_objectives.has(mission_id):
		return completed_objectives[mission_id].duplicate(true)
	if completed_objectives.has(active_quest_id):
		return completed_objectives[active_quest_id].duplicate(true)
	return []


func get_active_objectives(mission_id := "") -> Array:
	var mid := mission_id if mission_id != "" else active_quest_id
	var out: Array = []
	if mid != "" and active_objectives.has(mid):
		for objective_id in active_objectives[mid].keys():
			var record: Dictionary = active_objectives[mid][objective_id]
			out.append(String(record.get("text", objective_id)))
	if out.is_empty() and get_current_objective(mid) != "No active objective.":
		out.append(get_current_objective(mid))
	return out


func has_objective(objective_id: String, mission_id := "") -> bool:
	var mid := mission_id if mission_id != "" else active_quest_id
	return mid != "" and objective_records.has(mid) and objective_records[mid].has(objective_id)


func is_objective_completed(objective_id: String, mission_id := "") -> bool:
	var mid := mission_id if mission_id != "" else active_quest_id
	return mid != "" and objective_records.has(mid) and objective_records[mid].has(objective_id) and String(objective_records[mid][objective_id].get("status", "")) == "completed"

func clear_objective() -> void:
	active_objective = ""
	EventBus.objective_updated.emit("")

func complete_objective(quest_id = "") -> void:
	if quest_id == "":
		quest_id = active_quest_id
	if quest_id != "":
		if objectives.has(quest_id):
			complete_objective_id(String(objectives[quest_id]).to_snake_case(), String(objectives[quest_id]), quest_id)
		objectives.erase(quest_id)
	clear_objective()
