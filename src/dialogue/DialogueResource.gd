# DialogueResource.gd
# Loads and parses JSON dialogue files for Untitled Heist RPG
# Supports: branching, conditions, flags, portraits, typewriter text

class_name DialogueResource
extends Resource

# Parsed dialogue data
var character_id: String = ""
var character_name: String = ""
var default_portrait: String = ""
var nodes: Dictionary = {}
var metadata: Dictionary = {}

# Load dialogue from JSON file path
static func load_from_file(path: String) -> DialogueResource:
	var resource := DialogueResource.new()
	
	if not FileAccess.file_exists(path):
		push_error("DialogueResource: File not found: " + path)
		return resource
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DialogueResource: Failed to open file: " + path)
		return resource
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_error("DialogueResource: JSON parse error in " + path + ": " + json.get_error_message())
		return resource
	
	var data := json.get_data() as Dictionary
	resource._parse_data(data)
	return resource

# Load dialogue from JSON string (for inline/testing)
static func load_from_string(json_text: String) -> DialogueResource:
	var resource := DialogueResource.new()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	if parse_result != OK:
		push_error("DialogueResource: JSON parse error: " + json.get_error_message())
		return resource
	
	var data := json.get_data() as Dictionary
	resource._parse_data(data)
	return resource

# Parse the JSON data into structured format
func _parse_data(data: Dictionary) -> void:
	character_id = data.get("character_id", "")
	character_name = data.get("character_name", character_id)
	default_portrait = data.get("default_portrait", "")
	metadata = data.get("metadata", {})
	
	var raw_nodes = data.get("nodes", {})
	for node_id in raw_nodes:
		nodes[node_id] = _parse_node(raw_nodes[node_id], node_id)

# Parse a single dialogue node
func _parse_node(node_data: Dictionary, node_id: String) -> Dictionary:
	var node := {
		"id": node_id,
		"text": node_data.get("text", ""),
		"portrait": node_data.get("portrait", ""),
		"speaker": node_data.get("speaker", character_name),
		"choices": [],
		"conditions": [],
		"set_flags": {},
		"set_quest_progress": {},
		"effects": [],
		"auto_advance": node_data.get("auto_advance", false),
		"auto_advance_delay": node_data.get("auto_advance_delay", 2.0),
		"typewriter_speed": node_data.get("typewriter_speed", 0.03)
	}
	
	# Parse conditions
	if node_data.has("conditions"):
		for cond in node_data["conditions"]:
			node["conditions"].append(_parse_condition(cond))
	
	# Parse choices
	if node_data.has("choices"):
		for choice in node_data["choices"]:
			node["choices"].append(_parse_choice(choice))
	
	# Parse set_flags
	if node_data.has("set_flags"):
		node["set_flags"] = node_data["set_flags"]
	
	# Parse quest progress
	if node_data.has("set_quest_progress"):
		node["set_quest_progress"] = node_data["set_quest_progress"]
	
	# Parse effects
	if node_data.has("effects"):
		node["effects"] = node_data["effects"]
	
	return node

# Parse a choice option
func _parse_choice(choice_data: Dictionary) -> Dictionary:
	var choice := {
		"text": choice_data.get("text", "..."),
		"next": choice_data.get("next", ""),
		"conditions": [],
		"set_flags": {},
		"set_quest_progress": {},
		"effects": []
	}
	
	if choice_data.has("conditions"):
		for cond in choice_data["conditions"]:
			choice["conditions"].append(_parse_condition(cond))
	
	if choice_data.has("set_flags"):
		choice["set_flags"] = choice_data["set_flags"]
	
	if choice_data.has("set_quest_progress"):
		choice["set_quest_progress"] = choice_data["set_quest_progress"]
	
	if choice_data.has("effects"):
		choice["effects"] = choice_data["effects"]
	
	return choice

# Parse a condition
func _parse_condition(cond_data: Dictionary) -> Dictionary:
	return {
		"type": cond_data.get("type", "flag"),
		"key": cond_data.get("key", ""),
		"value": cond_data.get("value", true),
		"quest_id": cond_data.get("quest_id", ""),
		"status": cond_data.get("status", ""),
		"friend_id": cond_data.get("friend_id", ""),
		"helped": cond_data.get("helped", true),
		"mission_id": cond_data.get("mission_id", ""),
		"completed": cond_data.get("completed", true),
		"comparison": cond_data.get("comparison", "eq"),
		"intel_min": cond_data.get("intel_min", 0)
	}

# Get a node by ID
func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})

# Check if node exists
func has_node(node_id: String) -> bool:
	return nodes.has(node_id)

# Get portrait path for a node (falls back to default)
func get_portrait_for_node(node_id: String) -> String:
	var node := get_node_data(node_id)
	var portrait := node.get("portrait", "")
	if portrait != "":
		return portrait
	return default_portrait

# Get all available choices for a node (filtered by conditions)
func get_available_choices(node_id: String, game_state: Node = null) -> Array:
	var node := get_node_data(node_id)
	var choices := node.get("choices", []) as Array
	var available := []
	
	for choice in choices:
		if _check_conditions(choice.get("conditions", []), game_state):
			available.append(choice)
	
	return available

# Check if node is accessible (conditions met)
func is_node_accessible(node_id: String, game_state: Node = null) -> bool:
	var node := get_node_data(node_id)
	return _check_conditions(node.get("conditions", []), game_state)

# Evaluate conditions against game state
func _check_conditions(conditions: Array, game_state: Node = null) -> bool:
	if conditions.is_empty():
		return true
	
	if game_state == null:
		game_state = get_node_or_null("/root/GameState")
		if game_state == null:
			# No game state available, assume conditions pass if empty
			return true
	
	for cond in conditions:
		if not _evaluate_condition(cond, game_state):
			return false
	
	return true

# Evaluate a single condition
func _evaluate_condition(cond: Dictionary, game_state: Node) -> bool:
	var type := cond.get("type", "flag")
	
	match type:
		"flag":
			var key := cond.get("key", "")
			var expected := cond.get("value", true)
			var actual := game_state.get_dialogue_flag(key, false)
			return actual == expected
		
		"quest":
			var quest_id := cond.get("quest_id", "")
			var status := cond.get("status", "")
			var quest_manager := get_node_or_null("/root/QuestManager")
			if quest_manager == null:
				return false
			
			match status:
				"active":
					return quest_manager.get_current_quest_id() == quest_id
				"completed":
					return quest_id in game_state.completed_missions
				"available":
					return quest_id in game_state.available_missions
				"not_started":
					return not (quest_id in game_state.completed_missions) and quest_manager.get_current_quest_id() != quest_id
				_:
					return false
		
		"friend":
			var friend_id := cond.get("friend_id", "")
			var helped := cond.get("helped", true)
			if game_state.friend_favors.has(friend_id):
				return game_state.friend_favors[friend_id].get("helped", false) == helped
			return not helped
		
		"mission":
			var mission_id := cond.get("mission_id", "")
			var completed := cond.get("completed", true)
			var is_completed := mission_id in game_state.completed_missions
			return is_completed == completed
		
		"intel":
			var intel_min := cond.get("intel_min", 0)
			return game_state.intel_points >= intel_min
		
		"failure_count":
			var mission_id := cond.get("mission_id", "")
			var comparison := cond.get("comparison", "eq")
			var expected := cond.get("value", 0)
			var actual := game_state.get_failure_count(mission_id)
			match comparison:
				"eq": return actual == expected
				"lt": return actual < expected
				"lte": return actual <= expected
				"gt": return actual > expected
				"gte": return actual >= expected
				_: return false
		
		_:
			return true

# Get starting node (first node, or specified default)
func get_start_node(start_id: String = "") -> String:
	if start_id != "" and nodes.has(start_id):
		return start_id
	
	# Try common entry points
	for entry in ["intro", "start", "greeting", "default"]:
		if nodes.has(entry):
			return entry
	
	# Return first node
	if not nodes.is_empty():
		return nodes.keys()[0]
	
	return ""

# Get all node IDs
func get_all_node_ids() -> Array:
	return nodes.keys()

# Debug: print dialogue tree structure
func debug_print() -> void:
	print("=== DialogueResource: " + character_name + " ===")
	print("Character ID: " + character_id)
	print("Nodes: " + str(nodes.size()))
	for node_id in nodes:
		var node := nodes[node_id] as Dictionary
		print("  [" + node_id + "] " + node.get("speaker", "?") + ": " + node.get("text", "")[:50])
		var choices := node.get("choices", []) as Array
		for choice in choices:
			print("    -> " + choice.get("text", "...") + " [next: " + choice.get("next", "END") + "]")
