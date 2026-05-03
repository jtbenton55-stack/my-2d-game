class_name MissionCodeGatePlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var gate_id: String = ""
@export var objective_id: String = ""
@export var correct_code: String = "2174"
@export var required_clue_id: String = ""
@export var bypass_item_id: String = ""
@export_multiline var wrong_code_text: String = "Wrong code. The keypad chirps, but the garage stays locked."
@export_multiline var solved_text: String = "Correct code. Garage office route open."

var solved := false


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	super._ready()


func _complete(_player: Node = null) -> void:
	if solved:
		_show_feedback(solved_text)
		return
	if _has_bypass_item() or _has_required_clue():
		solved = true
		GameState.dialogue_flags["mission_gate:" + gate_id] = true
		if objective_id != "":
			placeholder_completed.emit(objective_id)
		var mission := get_tree().current_scene
		if mission != null and mission.has_method("set_iso_access_item"):
			mission.set_iso_access_item(gate_id)
		_show_feedback(solved_text + " Code: " + correct_code + ".")
		remove_from_group("interactable")
		set_deferred("monitoring", false)
		return
	_show_feedback(wrong_code_text + " Find the route logic before trying again.")


func _has_required_clue() -> bool:
	if required_clue_id == "":
		return true
	return GameState.sterling_clues.has(required_clue_id)


func _has_bypass_item() -> bool:
	return bypass_item_id != "" and bool(GameState.dialogue_flags.get("mission_access_item:" + bypass_item_id, false))


func _show_feedback(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": text }])
