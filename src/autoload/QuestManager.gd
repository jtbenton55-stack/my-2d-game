extends Node

var active_quest_id := ""
var active_objective := ""
var objectives: Dictionary = {}

func _ready() -> void:
	EventBus.debug("QuestManager ready")

func set_objective(text: String, quest_id = "") -> void:
	active_quest_id = quest_id
	active_objective = text
	if quest_id != "":
		objectives[quest_id] = text
	EventBus.objective_updated.emit(text)

func clear_objective() -> void:
	active_objective = ""
	EventBus.objective_updated.emit("")

func complete_objective(quest_id = "") -> void:
	if quest_id == "":
		quest_id = active_quest_id
	if quest_id != "":
		objectives.erase(quest_id)
	clear_objective()
