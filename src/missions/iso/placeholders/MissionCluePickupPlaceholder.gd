class_name MissionCluePickupPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var clue_id: String = ""
@export var category: String = "Mission Bible"
@export_multiline var clue_description: String = ""
@export var connects_to: String = "Sterling Tower"
@export var unlocks_or_modifies: String = ""
@export var final_tower_relevance: String = ""


func _complete(player: Node = null) -> void:
	var id := clue_id if clue_id != "" else placeholder_id
	if GameState.sterling_clues.has(id):
		var existing: Dictionary = GameState.sterling_clues.get(id, {})
		if existing.get("discovered", false) == true:
			DialogueManager.start_simple_dialogue([{ "speaker": "Evidence", "text": "Already logged: " + (display_name if display_name != "" else id) }])
			return
	GameState.ensure_and_discover_sterling_clue(id, {
		"title": display_name,
		"description": clue_description if clue_description != "" else interaction_text,
		"category": category,
		"mission_id": mission_id,
		"found_in_mission": mission_id,
		"clue_id": id,
		"display_name": display_name,
		"short_name": display_name,
		"clue_board_cluster": connects_to if connects_to != "" else "Sterling Tower",
		"connects_to": connects_to,
		"unlocks_or_modifies": unlocks_or_modifies,
		"final_tower_relevance": final_tower_relevance,
		"is_required_for_mission_completion": true,
		"discovered": true,
	})
	var line := "Clue recorded: " + (display_name if display_name != "" else id)
	DialogueManager.start_simple_dialogue([{ "speaker": "Evidence", "text": line }])
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("increment_attempt_counter"):
		mission.call("increment_attempt_counter", "clues", 1)
	super._complete(player)
