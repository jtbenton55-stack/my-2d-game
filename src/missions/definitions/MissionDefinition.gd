class_name MissionDefinition
extends Resource

@export var mission_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var genre_feel: String = ""
@export var player_mindset: String = ""
@export var signature_mechanic: String = ""
@export var signature_emotion: String = ""

@export var zones: Array[Resource] = []
@export var primary_objectives: Array[Resource] = []
@export var optional_objectives: Array[Resource] = []
@export var access_items: Array[String] = []
@export var puzzle_gates: Array[Resource] = []
@export var unique_mechanics: Array[String] = []
@export var enemies: Array[Resource] = []
@export var stealth_opportunities: Array[String] = []
@export var combat_opportunities: Array[String] = []
@export var collectibles: Array[Resource] = []
@export var evidence_clues: Array[Resource] = []
@export var scheme_card_rewards: Array[Resource] = []
@export var cutscenes: Array[Resource] = []
@export var live_restart_mutations: Array[Resource] = []
@export var final_tower_connections: Array[String] = []
@export var required_prior_clues_or_rewards: Array[String] = []
@export var routes: Array[Resource] = []
@export_multiline var art_notes: String = ""
@export var implementation_status: String = "stub"


func mutation_pool() -> Dictionary:
	var out := {}
	for mutation in live_restart_mutations:
		if mutation != null and not mutation.options.is_empty():
			out[mutation.mutation_id] = mutation.as_pool_entry()
	return out


func required_collectibles() -> Array[Resource]:
	var out: Array[Resource] = []
	for item in collectibles:
		if item != null and item.required:
			out.append(item)
	return out


func required_clues() -> Array[Resource]:
	var out: Array[Resource] = []
	for clue in evidence_clues:
		if clue != null and clue.required:
			out.append(clue)
	return out
