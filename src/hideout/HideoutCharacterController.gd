extends Node
class_name HideoutCharacterController

var line_index := {}

const DIALOGUE := {
	"jake": {
		"fresh": ["I'm not saying this is a healthy coping mechanism, but the cork board does have excellent diagnostic clarity."],
		"taco_bell_completed": ["Bentley's paws smell like mild sauce and adrenaline. I'm documenting this as a new syndrome."],
		"taco_bell_missing_items": ["Clinically speaking, the room has the energy of an unfinished differential."],
		"high_heat": ["From a medical perspective, our stress level is elevated. From a crime perspective, I think the room glowing red is probably bad."],
		"louis_unlocked": ["I don't trust Louis's supply chain, but I respect the confidence."],
	},
	"mere": {
		"fresh": ["This room is somewhere between detective office, dog daycare, and tax fraud."],
		"taco_bell_completed": ["I love that we're calling this evidence when it is clearly stolen decor."],
		"taco_bell_missing_items": ["I feel like the board is silently judging us for missing something."],
		"high_heat": ["I feel like the red warning lights are trying to tell us something subtle."],
		"louis_unlocked": ["Louis has the energy of a man who sells lamps out of a duffel bag."],
	},
	"bentley": {
		"fresh": ["Bentley accepts pets."],
		"taco_bell_completed": ["Bentley looks extremely proud of surviving the sauce incident."],
		"taco_bell_missing_items": ["Bentley sniffs the air like the missing collectible is personally insulting."],
		"high_heat": ["Bentley looks innocent in a way that suggests legal counsel."],
		"louis_unlocked": ["Bentley is monitoring Louis with professional suspicion."],
	},
	"louis": {
		"louis_unlocked": [
			"I know a guy who knows a guy who sells lamps. Crime lamps.",
			"Everything fell off a truck. Emotionally.",
			"Do not ask where the rug came from. Do ask how good it looks.",
			"Bentley gets a discount because he has honest eyes.",
		],
	},
}

func get_panel_data(character_id: String, state_controller: Node = null) -> Dictionary:
	return {
		"title": character_id.capitalize(),
		"body": dialogue_for(character_id, state_controller),
		"buttons": [
			{"id": "talk", "label": "Talk", "action": "talk", "character_id": character_id},
			{"id": "back", "label": "Back", "action": "close"},
		],
	}

func dialogue_for(character_id: String, state_controller = null) -> String:
	var state := _state_for(character_id, state_controller)
	var lines := _lines(character_id, state)
	if character_id == "louis" and state != "louis_unlocked":
		return "Louis is not here in this debug state."
	return "%s\n\n%s" % [character_id.capitalize(), "\n".join(lines)]

func next_dialogue(character_id: String, state_controller: Node = null) -> String:
	var state := _state_for(character_id, state_controller)
	var lines := _lines(character_id, state)
	var key := "%s:%s" % [character_id, state]
	var index := int(line_index.get(key, -1)) + 1
	if index >= lines.size():
		index = 0
	line_index[key] = index
	return lines[index]

func _state_for(character_id: String, state_controller: Node = null) -> String:
	if state_controller != null and state_controller.has_method("get_character_state"):
		return String(state_controller.get_character_state(character_id).get("dialogue_state", "fresh"))
	return "fresh"

func _lines(character_id: String, state: String) -> Array:
	var character_table: Dictionary = DIALOGUE.get(character_id, {})
	if character_table.has(state):
		return character_table[state]
	if state == "missing_items" and character_table.has("taco_bell_missing_items"):
		return character_table["taco_bell_missing_items"]
	match character_id:
		"louis":
			return []
		_:
			return ["No dialogue written yet."]
