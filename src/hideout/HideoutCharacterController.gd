extends Node
class_name HideoutCharacterController

const DialogicAdapter = preload("res://src/hideout/HideoutDialogicAdapter.gd")

var line_index := {}

func get_panel_data(character_id: String, state_controller: Node = null) -> Dictionary:
	return {
		"title": character_id.capitalize(),
		"body": dialogue_for(character_id, state_controller),
		"buttons": [
			{"id": "talk", "label": "Talk Again", "action": "talk", "character_id": character_id},
		],
	}

func dialogue_for(character_id: String, state_controller = null) -> String:
	var state := _state_for(character_id, state_controller)
	if character_id == "louis" and state != "louis_unlocked":
		return "Louis is not here in this debug state."
	return "%s\nState: %s\n\n%s" % [character_id.capitalize(), state.replace("_", " ").capitalize(), next_dialogue(character_id, state_controller)]

func next_dialogue(character_id: String, state_controller: Node = null) -> String:
	var state := _state_for(character_id, state_controller)
	var context := _context_for(character_id, state, state_controller)
	return DialogicAdapter.line_for(context, "", get_tree())

func _state_for(character_id: String, state_controller: Node = null) -> String:
	if state_controller != null and state_controller.has_method("get_character_state"):
		return String(state_controller.get_character_state(character_id).get("dialogue_state", "fresh"))
	return "fresh"

func _context_for(character_id: String, state: String, state_controller: Node = null) -> String:
	match character_id:
		"bentley":
			if _has_any_care_done(state_controller):
				return "bentley_bed_after_care"
			if _has_any_store_purchase(state_controller):
				return "bentley_bed_after_store_purchase"
			if state == "high_heat":
				return "bentley_bed_high_heat"
			if state in ["taco_bell_completed", "taco_bell_missing_items", "louis_unlocked"]:
				return "bentley_bed_taco_bell_completed"
			return "bentley_bed_fresh"
		"jake":
			return "jake_%s" % state
		"mere":
			return "mere_%s" % state
		"louis":
			return "louis_unlocked"
		_:
			return character_id

func _has_any_care_done(state_controller: Node = null) -> bool:
	if state_controller == null or not state_controller.has_method("get_care_state"):
		return false
	var care: Dictionary = state_controller.get_care_state()
	return bool(care.get("bentley_wiped", false)) or bool(care.get("bentley_brushed", false)) or bool(care.get("treat_packed", false)) or bool(care.get("poop_bags_stocked", false))

func _has_any_store_purchase(state_controller: Node = null) -> bool:
	if state_controller == null:
		return false
	return state_controller.get("purchased_store_items").size() > 0
