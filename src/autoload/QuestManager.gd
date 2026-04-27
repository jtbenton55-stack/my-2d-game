# QuestManager.gd
# Manages quests and objectives for Untitled Heist RPG

extends Node

# Signals
signal quest_started(quest_id, objective)
signal quest_updated(objective_text)
signal quest_completed(quest_id)

# Quest data
var _current_quest_id: String = ""
var _current_objective: String = ""
var _quests: Dictionary = {}

func _ready() -> void:
	_load_quests()
	EventBus.debug("QuestManager loaded")
	
	# Connect to mission events
	EventBus.mission_started.connect(_on_mission_started)
	EventBus.mission_completed.connect(_on_mission_completed)

func _load_quests() -> void:
	# Define quests inline
	_quests = {
		# Mission quests
		"taco_bell_drop": {
			"name": "The Taco Bell Drop",
			"description": "Help Louis recover his delivery bag",
			"objectives": [
				"Talk to Louis in the city hub",
				"Follow Bentley's scent trail",
				"Recover the delivery bag",
				"Return to Louis"
			],
			"reward": "Louis Delivery Route Scheme Card",
			"friend": "louis"
		},
		"velvet_paw_jazz_club": {
			"name": "The Velvet Paw Jazz Club",
			"description": "Steal the Sterling blackmail ledger",
			"objectives": [
				"Infiltrate the jazz club",
				"Avoid or distract bouncers",
				"Solve the music puzzle",
				"Retrieve the blackmail ledger",
				"Escape through the backstage"
			],
			"reward": "Yordano Bass Drop Scheme Card",
			"friend": "yordano"
		},
		"rewrite_room": {
			"name": "The Rewrite Room",
			"description": "Recover stolen screenplay documents",
			"objectives": [
				"Infiltrate the law firm",
				"Find the screenplay documents",
				"Solve the screenwriting puzzle",
				"Identify the real ownership document",
				"Escape with the evidence"
			],
			"reward": "Stationery Queen Scheme Card",
			"friend": "mere"
		},
		"fast_family_getaway": {
			"name": "The Fast Family Getaway",
			"description": "Help Dom escape with evidence",
			"objectives": [
				"Meet Dom at the garage",
				"Steal back the evidence",
				"Escape through the city",
				"Avoid police and Sterling goons",
				"Reach the safehouse"
			],
			"reward": "Dom's Getaway Keys Scheme Card",
			"friend": "dom"
		},
		"sterling_tower_heist": {
			"name": "The Sterling Tower Heist",
			"description": "The final job. Take down Victor Sterling.",
			"objectives": [
				"Infiltrate Sterling Tower",
				"Use friend favors to bypass security",
				"Confront Victor Sterling",
				"Expose the Sterling Syndicate",
				"Escape with the evidence"
			],
			"reward": "City's gratitude and safety",
			"friend": "all"
		},
		
		# Tutorial quest
		"tutorial": {
			"name": "Learn the Ropes",
			"description": "Learn basic controls and mechanics",
			"objectives": [
				"Move around the hideout",
				"Talk to Jake",
				"Interact with the mission board",
				"Complete the tutorial heist"
			],
			"reward": "Basic understanding of the game",
			"friend": ""
		}
	}

# ===== PUBLIC API =====

func start_quest(quest_id: String, objective_index: int = 0) -> void:
	"""Start a quest"""
	if not _quests.has(quest_id):
		EventBus.debug("QuestManager: Quest not found: " + quest_id)
		return
	
	_current_quest_id = quest_id
	var quest = _quests[quest_id]
	
	if objective_index < quest["objectives"].size():
		_current_objective = quest["objectives"][objective_index]
	else:
		_current_objective = quest["objectives"][0] if quest["objectives"].size() > 0 else ""
	
	quest_started.emit(quest_id, _current_objective)
	EventBus.debug("Quest started: " + quest_id + " - " + _current_objective)

func update_objective(new_objective: String) -> void:
	"""Update current objective"""
	_current_objective = new_objective
	quest_updated.emit(_current_objective)
	EventBus.debug("Quest objective updated: " + _current_objective)

func complete_objective() -> void:
	"""Complete current objective and move to next"""
	if _current_quest_id == "":
		return
	
	var quest = _quests.get(_current_quest_id, {})
	var objectives = quest.get("objectives", [])
	
	# Find current objective index
	var current_index = objectives.find(_current_objective)
	if current_index == -1:
		EventBus.debug("QuestManager: Current objective not found in quest")
		return
	
	# If this was the last objective, complete the quest
	if current_index >= objectives.size() - 1:
		complete_quest()
	else:
		# Move to next objective
		var next_objective = objectives[current_index + 1]
		update_objective(next_objective)

func complete_quest() -> void:
	"""Complete current quest"""
	if _current_quest_id == "":
		return
	
	EventBus.debug("Quest completed: " + _current_quest_id)
	quest_completed.emit(_current_quest_id)
	
	# Clear current quest
	_current_quest_id = ""
	_current_objective = ""

func fail_quest() -> void:
	"""Fail current quest (return to hideout with partial progress)"""
	if _current_quest_id == "":
		return
	
	EventBus.debug("Quest failed: " + _current_quest_id)
	
	# For now, just clear the quest
	# In a full implementation, we might track partial progress
	_current_quest_id = ""
	_current_objective = ""

func get_current_quest() -> Dictionary:
	"""Get current quest data"""
	if _current_quest_id == "" or not _quests.has(_current_quest_id):
		return {}
	
	var quest = _quests[_current_quest_id].duplicate()
	quest["current_objective"] = _current_objective
	return quest

func get_current_quest_id() -> String:
	"""Get current quest ID"""
	return _current_quest_id

func get_current_objective() -> String:
	"""Get current objective text"""
	return _current_objective

func has_active_quest() -> bool:
	"""Check if there's an active quest"""
	return _current_quest_id != ""

func get_quest(quest_id: String) -> Dictionary:
	"""Get quest data by ID"""
	return _quests.get(quest_id, {})

func add_quest(quest_id: String, quest_data: Dictionary) -> void:
	"""Add or update a quest"""
	_quests[quest_id] = quest_data

# ===== MISSION INTEGRATION =====

func _on_mission_started(mission_id: String) -> void:
	"""Start quest when mission starts"""
	# Mission IDs match quest IDs for simplicity
	if _quests.has(mission_id):
		start_quest(mission_id)
	else:
		# Start a generic mission quest
		start_quest("tutorial")

func _on_mission_completed(mission_id: String, success: bool) -> void:
	"""Handle mission completion"""
	if not has_active_quest() or _current_quest_id != mission_id:
		return
	
	if success:
		complete_quest()
	else:
		fail_quest()

# ===== QUEST PROGRESSION =====

func get_next_mission_quest(completed_missions: Array[String]) -> String:
	"""Get next mission quest ID based on completed missions"""
	# Check mission order
	var mission_order = [
		"taco_bell_drop",
		"velvet_paw_jazz_club",
		"rewrite_room",
		"fast_family_getaway",
		"sterling_tower_heist"
	]
	
	# First mission is always available if not completed
	if "taco_bell_drop" not in completed_missions:
		return "taco_bell_drop"
	
	# Find first mission in order that's not completed
	for mission_id in mission_order:
		if mission_id not in completed_missions:
			# Check if previous mission is completed
			var mission_index = mission_order.find(mission_id)
			if mission_index > 0:
				var prev_mission = mission_order[mission_index - 1]
				if prev_mission in completed_missions:
					return mission_id
	
	return ""

func get_available_quests(completed_missions: Array[String]) -> Array[String]:
	"""Get all available quests based on completed missions"""
	var available = []
	
	# Always include tutorial
	available.append("tutorial")
	
	# Add mission quests that are available
	var next_mission = get_next_mission_quest(completed_missions)
	if next_mission != "":
		available.append(next_mission)
	
	return available

# ===== SAVE/LOAD =====

func to_dict() -> Dictionary:
	"""Convert QuestManager state to dictionary for saving"""
	return {
		"current_quest_id": _current_quest_id,
		"current_objective": _current_objective,
		"quests": _quests  # Could be large, but needed for custom quests
	}

func from_dict(data: Dictionary) -> void:
	"""Load QuestManager state from dictionary"""
	_current_quest_id = data.get("current_quest_id", "")
	_current_objective = data.get("current_objective", "")
	
	# Merge loaded quests with defaults
	var loaded_quests = data.get("quests", {})
	for key in loaded_quests:
		_quests[key] = loaded_quests[key]