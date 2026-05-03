class_name MissionClueDefinition
extends Resource

@export var clue_id: String = ""
@export var display_name: String = ""
@export var mission_found: String = ""
@export var category: String = ""
@export_multiline var description: String = ""
@export var short_name: String = ""
@export var clue_board_cluster: String = ""
@export var connects_to: String = ""
@export var unlocks_or_modifies: String = ""
@export var final_tower_relevance: String = ""
@export var zone_id: String = ""
@export var marker_cell: Vector2i = Vector2i.ZERO
@export var required: bool = true


func to_game_state_data() -> Dictionary:
	return {
		"title": display_name,
		"display_name": display_name,
		"short_name": short_name if short_name != "" else display_name,
		"description": description,
		"category": category,
		"mission_id": mission_found,
		"found_in_mission": mission_found,
		"clue_board_cluster": clue_board_cluster if clue_board_cluster != "" else connects_to,
		"connects_to": connects_to,
		"unlocks_or_modifies": unlocks_or_modifies,
		"final_tower_relevance": final_tower_relevance,
		"is_required_for_mission_completion": required,
	}
