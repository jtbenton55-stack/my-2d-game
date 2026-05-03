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
	super._complete(player)
