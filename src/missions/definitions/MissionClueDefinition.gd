class_name MissionClueDefinition
extends Resource

@export var clue_id: String = ""
@export var display_name: String = ""
@export var mission_found: String = ""
@export var category: String = ""
@export_multiline var description: String = ""
@export var connects_to: String = ""
@export var unlocks_or_modifies: String = ""
@export var final_tower_relevance: String = ""
@export var zone_id: String = ""
@export var marker_cell: Vector2i = Vector2i.ZERO
@export var required: bool = true


func to_game_state_data() -> Dictionary:
	return {
		"title": display_name,
		"description": description,
		"category": category,
		"mission_id": mission_found,
		"connects_to": connects_to,
		"unlocks_or_modifies": unlocks_or_modifies,
		"final_tower_relevance": final_tower_relevance,
	}
