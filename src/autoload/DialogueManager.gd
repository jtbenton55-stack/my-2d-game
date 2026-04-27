# DialogueManager.gd
# Manages dialogue for Untitled Heist RPG - V2 with JSON support, conditions, portraits, typewriter

extends Node

# Signals
signal dialogue_started(dialogue_resource, node_id)
signal dialogue_text_updated(text, speaker, portrait_path)
signal dialogue_choices_available(choices)
signal dialogue_choice_selected(choice_index, choice_data)
signal dialogue_ended
signal dialogue_flag_set(flag, value)
signal dialogue_quest_updated(quest_id, objective)
signal typewriter_tick
signal typewriter_finished

# Configuration
const DIALOGUE_DIR := "res://assets/dialogue/"
const DEFAULT_TYPEWRITER_SPEED := 0.03

# State
var _dialogue_resources: Dictionary = {}  # character_id -> DialogueResource
var _current_resource: DialogueResource = null
var _current_node_id: String = ""
var _is_in_dialogue: bool = false
var _is_typewriting: bool = false
var _typewriter_timer: Timer = null
var _current_full_text: String = ""
var _current_displayed_text: String = ""
var _typewriter_index: int = 0
var _typewriter_speed: float = DEFAULT_TYPEWRITER_SPEED
var _auto_advance: bool = false
var _auto_advance_timer: Timer = null
var _skip_requested: bool = false

func _ready() -> void:
	_setup_timers()
	_load_all_dialogues()
	EventBus.debug("DialogueManager V2 loaded")

func _setup_timers() -> void:
	# Typewriter timer
	_typewriter_timer = Timer.new()
	_typewriter_timer.one_shot = false
	_typewriter_timer.wait_time = DEFAULT_TYPEWRITER_SPEED
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)
	
	# Auto-advance timer
	_auto_advance_timer = Timer.new()
	_auto_advance_timer.one_shot = true
	_auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	add_child(_auto_advance_timer)

# ===== DIALOGUE LOADING =====

func _load_all_dialogues() -> void:
	"""Load all JSON dialogue files from the dialogue directory"""
	var dir := DirAccess.open(DIALOGUE_DIR)
	if dir == null:
		EventBus.debug("DialogueManager: Dialogue directory not found: " + DIALOGUE_DIR)
		# Load built-in fallback dialogues
		_load_fallback_dialogues()
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := DIALOGUE_DIR + file_name
			var resource := DialogueResource.load_from_file(path)
			if resource.character_id != "":
				_dialogue_resources[resource.character_id] = resource
				EventBus.debug("Loaded dialogue: " + resource.character_id + " (" + resource.character_name + ")")
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if _dialogue_resources.is_empty():
		EventBus.debug("DialogueManager: No JSON dialogues found, loading fallbacks")
		_load_fallback_dialogues()

func _load_fallback_dialogues() -> void:
	"""Load minimal inline dialogues as fallback"""
	# These are only used if no JSON files exist
	# In production, JSON files should always be present
	var louis_json := JSON.stringify({
		"character_id": "louis",
		"character_name": "Louis",
		"default_portrait": "",
		"nodes": {
			"intro": {
				"text": "I deliver tacos, secrets, and occasionally fugitives. Depends on the tip.",
				"choices": [
					{"text": "Tell me about the delivery route", "next": "route"},
					{"text": "I need help with a heist", "next": "heist"},
					{"text": "Just checking in", "next": "goodbye"}
				]
			},
			"route": {
				"text": "The city has three kinds of doors: locked, unlocked, and delivery entrance. I know all the delivery entrances.",
				"choices": [
					{"text": "That could be useful", "next": "intro"},
					{"text": "Thanks for the info", "next": "goodbye"}
				]
			},
			"heist": {
				"text": "Crunchwrap, no witnesses? What do you need?",
				"choices": [
					{"text": "Actually, never mind", "next": "intro"},
					{"text": "I'll be in touch", "next": "goodbye"}
				]
			},
			"goodbye": {
				"text": "Stay safe out there. And tip your delivery drivers.",
				"choices": []
			}
		}
	})
	var louis_res := DialogueResource.load_from_string(louis_json)
	_dialogue_resources["louis"] = louis_res

func reload_dialogues() -> void:
	"""Reload all dialogue files (useful for hot-reloading during development)"""
	_dialogue_resources.clear()
	_load_all_dialogues()

# ===== PUBLIC API =====

func start_dialogue(character_id: String, start_node: String = "") -> bool:
	"""Start a dialogue with a character"""
	if not _dialogue_resources.has(character_id):
		EventBus.debug("DialogueManager: Character not found: " + character_id)
		return false
	
	var resource: DialogueResource = _dialogue_resources[character_id]
	var node_id := start_node
	if node_id == "":
		node_id = resource.get_start_node()
	
	if not resource.has_node(node_id):
		EventBus.debug("DialogueManager: Node not found: " + node_id)
		return false
	
	# Check if node is accessible
	if not resource.is_node_accessible(node_id, get_node_or_null("/root/GameState")):
		EventBus.debug("DialogueManager: Node conditions not met: " + node_id)
		# Try to find an alternative start node
		node_id = _find_alternative_start(resource, node_id)
		if node_id == "":
			return false
	
	_current_resource = resource
	_current_node_id = node_id
	_is_in_dialogue = true
	_skip_requested = false
	
	var node := resource.get_node_data(node_id)
	dialogue_started.emit(resource, node_id)
	
	# Process any entry effects/flags
	_process_node_effects(node)
	
	# Start typewriter effect
	_start_typewriter(node)
	
	EventBus.debug("Dialogue started: " + character_id + " -> " + node_id)
	return true

func _find_alternative_start(resource: DialogueResource, preferred: String) -> String:
	"""Find an alternative start node when preferred is blocked by conditions"""
	# Try common alternatives
	var alternatives := ["intro", "start", "greeting", "default", "blocked"]
	for alt in alternatives:
		if resource.has_node(alt) and resource.is_node_accessible(alt, get_node_or_null("/root/GameState")):
			return alt
	
	# Return first accessible node
	for node_id in resource.get_all_node_ids():
		if resource.is_node_accessible(node_id, get_node_or_null("/root/GameState")):
			return node_id
	
	return ""

func advance_dialogue() -> void:
	"""Advance to next dialogue (skip typewriter or auto-choose if no choices)"""
	if not _is_in_dialogue:
		return
	
	if _is_typewriting:
		# Skip to end of typewriter
		_skip_typewriter()
		return
	
	# Get current node
	var node := _current_resource.get_node_data(_current_node_id)
	var choices := _current_resource.get_available_choices(_current_node_id, get_node_or_null("/root/GameState"))
	
	if choices.is_empty():
		# No choices - end dialogue
		end_dialogue()
	else:
		# Show choices
		dialogue_choices_available.emit(choices)

func select_choice(choice_index: int) -> void:
	"""Select a dialogue choice"""
	if not _is_in_dialogue:
		return
	
	var choices := _current_resource.get_available_choices(_current_node_id, get_node_or_null("/root/GameState"))
	if choice_index < 0 or choice_index >= choices.size():
		EventBus.debug("DialogueManager: Invalid choice index: " + str(choice_index))
		return
	
	var choice: Dictionary = choices[choice_index]
	dialogue_choice_selected.emit(choice_index, choice)
	
	# Process choice effects
	_process_choice_effects(choice)
	
	# Go to next node or end
	var next_id := choice.get("next", "")
	if next_id != "" and _current_resource.has_node(next_id):
		_current_node_id = next_id
		var node := _current_resource.get_node_data(next_id)
		_process_node_effects(node)
		_start_typewriter(node)
	else:
		end_dialogue()

func end_dialogue() -> void:
	"""End current dialogue"""
	if not _is_in_dialogue:
		return
	
	_stop_typewriter()
	_stop_auto_advance()
	_is_in_dialogue = false
	_current_node_id = ""
	_current_resource = null
	_current_full_text = ""
	_current_displayed_text = ""
	_skip_requested = false
	
	dialogue_ended.emit()
	EventBus.debug("Dialogue ended")

func is_in_dialogue() -> bool:
	"""Check if currently in dialogue"""
	return _is_in_dialogue

func is_typewriting() -> bool:
	"""Check if typewriter effect is active"""
	return _is_typewriting

# ===== TYPEWRITER EFFECT =====

func _start_typewriter(node: Dictionary) -> void:
	"""Start typewriter effect for a node"""
	_current_full_text = node.get("text", "")
	_current_displayed_text = ""
	_typewriter_index = 0
	_typewriter_speed = node.get("typewriter_speed", DEFAULT_TYPEWRITER_SPEED)
	_auto_advance = node.get("auto_advance", false)
	
	var speaker := node.get("speaker", _current_resource.character_name)
	var portrait_path := _current_resource.get_portrait_for_node(_current_node_id)
	
	dialogue_text_updated.emit(_current_displayed_text, speaker, portrait_path)
	
	if _current_full_text == "":
		# Empty text, just show choices or advance
		_is_typewriting = false
		typewriter_finished.emit()
		if _auto_advance:
			_start_auto_advance(node.get("auto_advance_delay", 2.0))
		else:
			advance_dialogue()
		return
	
	_is_typewriting = true
	_typewriter_timer.wait_time = _typewriter_speed
	_typewriter_timer.start()

func _on_typewriter_tick() -> void:
	"""Called on each typewriter timer tick"""
	if _skip_requested:
		_skip_typewriter()
		return
	
	if _typewriter_index >= _current_full_text.length():
		_stop_typewriter()
		return
	
	# Add next character
	_current_displayed_text += _current_full_text[_typewriter_index]
	_typewriter_index += 1
	
	var node := _current_resource.get_node_data(_current_node_id)
	var speaker := node.get("speaker", _current_resource.character_name)
	var portrait_path := _current_resource.get_portrait_for_node(_current_node_id)
	
	dialogue_text_updated.emit(_current_displayed_text, speaker, portrait_path)
	typewriter_tick.emit()
	
	# Check if complete
	if _typewriter_index >= _current_full_text.length():
		_stop_typewriter()

func _stop_typewriter() -> void:
	"""Stop the typewriter effect"""
	if not _is_typewriting:
		return
	
	_is_typewriting = false
	_typewriter_timer.stop()
	
	# Ensure full text is shown
	if _current_displayed_text != _current_full_text:
		_current_displayed_text = _current_full_text
		var node := _current_resource.get_node_data(_current_node_id)
		var speaker := node.get("speaker", _current_resource.character_name)
		var portrait_path := _current_resource.get_portrait_for_node(_current_node_id)
		dialogue_text_updated.emit(_current_displayed_text, speaker, portrait_path)
	
	typewriter_finished.emit()
	
	# Check for auto-advance
	if _auto_advance:
		var node := _current_resource.get_node_data(_current_node_id)
		_start_auto_advance(node.get("auto_advance_delay", 2.0))
	else:
		# Show choices after a brief delay (or immediately)
		var choices := _current_resource.get_available_choices(_current_node_id, get_node_or_null("/root/GameState"))
		if choices.size() > 0:
			dialogue_choices_available.emit(choices)

func _skip_typewriter() -> void:
	"""Skip typewriter to end"""
	_skip_requested = false
	_stop_typewriter()

func skip_typewriter() -> void:
	"""Public method to request typewriter skip"""
	if _is_typewriting:
		_skip_requested = true

# ===== AUTO-ADVANCE =====

func _start_auto_advance(delay: float) -> void:
	"""Start auto-advance timer"""
	_auto_advance_timer.wait_time = delay
	_auto_advance_timer.start()

func _stop_auto_advance() -> void:
	"""Stop auto-advance timer"""
	_auto_advance_timer.stop()

func _on_auto_advance_timeout() -> void:
	"""Called when auto-advance timer expires"""
	advance_dialogue()

func set_auto_advance(enabled: bool) -> void:
	"""Enable/disable auto-advance globally"""
	_auto_advance = enabled

# ===== EFFECTS & FLAGS =====

func _process_node_effects(node: Dictionary) -> void:
	"""Process effects when entering a node"""
	# Set flags
	var flags := node.get("set_flags", {}) as Dictionary
	for flag_name in flags:
		var value := flags[flag_name]
		set_dialogue_flag(flag_name, value)
	
	# Update quest progress
	var quest_updates := node.get("set_quest_progress", {}) as Dictionary
	for quest_id in quest_updates:
		var objective := quest_updates[quest_id]
		_update_quest_progress(quest_id, objective)
	
	# Process generic effects
	var effects := node.get("effects", []) as Array
	for effect in effects:
		_process_effect(effect)

func _process_choice_effects(choice: Dictionary) -> void:
	"""Process effects when selecting a choice"""
	# Set flags
	var flags := choice.get("set_flags", {}) as Dictionary
	for flag_name in flags:
		var value := flags[flag_name]
		set_dialogue_flag(flag_name, value)
	
	# Update quest progress
	var quest_updates := choice.get("set_quest_progress", {}) as Dictionary
	for quest_id in quest_updates:
		var objective := quest_updates[quest_id]
		_update_quest_progress(quest_id, objective)
	
	# Process generic effects
	var effects := choice.get("effects", []) as Array
	for effect in effects:
		_process_effect(effect)

func _process_effect(effect: Dictionary) -> void:
	"""Process a generic effect"""
	var effect_type := effect.get("type", "")
	match effect_type:
		"unlock_card":
			var card_id := effect.get("card_id", "")
			if card_id != "":
				var game_state = get_node_or_null("/root/GameState")
				if game_state:
					game_state.unlock_card(card_id)
		
		"add_intel":
			var amount := effect.get("amount", 0)
			var game_state = get_node_or_null("/root/GameState")
			if game_state:
				game_state.add_intel_points(amount)
		
		"start_quest":
			var quest_id := effect.get("quest_id", "")
			if quest_id != "":
				var quest_manager = get_node_or_null("/root/QuestManager")
				if quest_manager:
					quest_manager.start_quest(quest_id)
		
		"complete_objective":
			var quest_manager = get_node_or_null("/root/QuestManager")
			if quest_manager:
				quest_manager.complete_objective()
		
		"help_friend":
			var friend_id := effect.get("friend_id", "")
			var card_id := effect.get("card_id", "")
			if friend_id != "":
				var game_state = get_node_or_null("/root/GameState")
				if game_state:
					game_state.set_friend_helped(friend_id, card_id)
		
		"collect_polaroid":
			var polaroid_id := effect.get("polaroid_id", "")
			if polaroid_id != "":
				var game_state = get_node_or_null("/root/GameState")
				if game_state:
					game_state.add_polaroid(polaroid_id)
		
		"change_scene":
			var scene_path := effect.get("scene_path", "")
			if scene_path != "":
				var scene_manager = get_node_or_null("/root/SceneManager")
				if scene_manager:
					scene_manager.change_scene(scene_path)
		
		"emit_signal":
			var signal_name := effect.get("signal", "")
			var signal_args := effect.get("args", [])
			EventBus.debug("Dialogue effect: emit " + signal_name)
			# Use EventBus for generic signals
			match signal_name:
				"return_to_hideout":
					EventBus.request_return_to_hideout()
				"enter_city_hub":
					EventBus.enter_city_hub.emit()
				_:
					# Try to emit on EventBus dynamically
					if EventBus.has_signal(signal_name):
						EventBus.emit_signal(signal_name, signal_args)

func set_dialogue_flag(flag: String, value: bool = true) -> void:
	"""Set a dialogue flag in GameState"""
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_dialogue_flag(flag, value)
	dialogue_flag_set.emit(flag, value)
	EventBus.debug("Dialogue flag set: " + flag + " = " + str(value))

func get_dialogue_flag(flag: String, default: bool = false) -> bool:
	"""Get a dialogue flag from GameState"""
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		return game_state.get_dialogue_flag(flag, default)
	return default

func _update_quest_progress(quest_id: String, objective: String) -> void:
	"""Update quest progress"""
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		if quest_manager.get_current_quest_id() == quest_id:
			quest_manager.update_objective(objective)
		dialogue_quest_updated.emit(quest_id, objective)
		EventBus.debug("Quest progress updated: " + quest_id + " -> " + objective)

# ===== UTILITY =====

func get_current_resource() -> DialogueResource:
	"""Get current dialogue resource"""
	return _current_resource

func get_current_node_id() -> String:
	"""Get current node ID"""
	return _current_node_id

func get_current_text() -> String:
	"""Get current full text"""
	return _current_full_text

func get_current_displayed_text() -> String:
	"""Get currently displayed text (during typewriter)"""
	return _current_displayed_text

func get_current_speaker() -> String:
	"""Get current speaker name"""
	if _current_resource == null:
		return ""
	var node := _current_resource.get_node_data(_current_node_id)
	return node.get("speaker", _current_resource.character_name)

func get_current_portrait() -> String:
	"""Get current portrait path"""
	if _current_resource == null:
		return ""
	return _current_resource.get_portrait_for_node(_current_node_id)

func get_available_choices() -> Array:
	"""Get currently available choices for the active node"""
	if _current_resource == null or _current_node_id == "":
		return []
	return _current_resource.get_available_choices(_current_node_id, get_node_or_null("/root/GameState"))

func get_current_choices() -> Array:
	"""Alias for get_available_choices (backwards compat)"""
	return get_available_choices()

func has_dialogue(character_id: String) -> bool:
	"""Check if a character has dialogue loaded"""
	return _dialogue_resources.has(character_id)

func get_dialogue_resource(character_id: String) -> DialogueResource:
	"""Get dialogue resource for a character"""
	return _dialogue_resources.get(character_id, null)

# ===== NPC GREETINGS =====

func get_npc_greeting(npc_id: String) -> String:
	"""Get greeting dialogue start node for NPC"""
	if not _dialogue_resources.has(npc_id):
		return ""
	
	var resource: DialogueResource = _dialogue_resources[npc_id]
	var game_state = get_node_or_null("/root/GameState")
	
	# Try to find best greeting based on game state
	# Priority: post_mission > repeat > intro
	var mission_id := MissionData.get_mission_for_friend(npc_id)
	
	# Check for post-mission greeting
	if mission_id != "" and mission_id in game_state.completed_missions:
		if resource.has_node("post_mission") and resource.is_node_accessible("post_mission", game_state):
			return "post_mission"
	
	# Check for repeat greeting (player has talked before)
	if get_dialogue_flag("met_" + npc_id, false):
		if resource.has_node("repeat") and resource.is_node_accessible("repeat", game_state):
			return "repeat"
		if resource.has_node("greeting") and resource.is_node_accessible("greeting", game_state):
			return "greeting"
	
	# Default to intro
	if resource.has_node("intro") and resource.is_node_accessible("intro", game_state):
		return "intro"
	
	# Fallback to any accessible node
	return resource.get_start_node()

# ===== MISSION DIALOGUES =====

func get_mission_start_dialogue(mission_id: String) -> Dictionary:
	"""Get mission start dialogue info {character_id, node_id}"""
	var friend_id := MissionData.get_friend_for_mission(mission_id)
	if friend_id != "" and _dialogue_resources.has(friend_id):
		var resource: DialogueResource = _dialogue_resources[friend_id]
		if resource.has_node("mission_start"):
			return {"character_id": friend_id, "node_id": "mission_start"}
	
	# Fallback to generic mission start
	if _dialogue_resources.has("narrator"):
		return {"character_id": "narrator", "node_id": "mission_start_" + mission_id}
	
	return {}

func get_mission_end_dialogue(mission_id: String, success: bool) -> Dictionary:
	"""Get mission end dialogue info"""
	var friend_id := MissionData.get_friend_for_mission(mission_id)
	var node_id := "mission_success" if success else "mission_failure"
	
	if friend_id != "" and _dialogue_resources.has(friend_id):
		var resource: DialogueResource = _dialogue_resources[friend_id]
		if resource.has_node(node_id):
			return {"character_id": friend_id, "node_id": node_id}
	
	# Generic fallback
	if _dialogue_resources.has("narrator"):
		var generic_node := "generic_success" if success else "generic_failure"
		return {"character_id": "narrator", "node_id": generic_node}
	
	return {}

func get_failure_progression_dialogue(mission_id: String, failure_count: int) -> Dictionary:
	"""Get dialogue for failure progression (Bentley intervention, etc.)"""
	if failure_count >= 3:
		if _dialogue_resources.has("bentley"):
			return {"character_id": "bentley", "node_id": "intervention"}
	
	if _dialogue_resources.has("jake"):
		return {"character_id": "jake", "node_id": "patch_up"}
	
	return {}

func get_collectible_dialogue(collectible_type: String, collectible_id: String) -> Dictionary:
	"""Get dialogue for collectible pickup"""
	var character_id := ""
	var node_id := ""
	
	match collectible_type:
		"polaroid":
			character_id = "narrator"
			node_id = "polaroid_" + collectible_id
		"trinket":
			character_id = "bentley"
			node_id = "trinket_found"
		"stationery":
			character_id = "mere"
			node_id = "stationery_found"
		"scheme_card":
			character_id = "narrator"
			node_id = "card_unlocked"
		_:
			return {}
	
	if _dialogue_resources.has(character_id):
		var resource: DialogueResource = _dialogue_resources[character_id]
		if resource.has_node(node_id):
			return {"character_id": character_id, "node_id": node_id}
		# Fallback to generic pickup
		if resource.has_node("collectible_found"):
			return {"character_id": character_id, "node_id": "collectible_found"}
	
	return {}

# ===== SAVE/LOAD =====

func to_dict() -> Dictionary:
	"""Convert DialogueManager state to dictionary for saving"""
	return {
		"current_character_id": _current_resource.character_id if _current_resource else "",
		"current_node_id": _current_node_id,
		"is_in_dialogue": _is_in_dialogue
	}

func from_dict(data: Dictionary) -> void:
	"""Load DialogueManager state from dictionary"""
	# Don't restore mid-dialogue state - just end any active dialogue
	if _is_in_dialogue:
		end_dialogue()
