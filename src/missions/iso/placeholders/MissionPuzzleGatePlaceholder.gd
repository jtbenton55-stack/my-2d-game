class_name MissionPuzzleGatePlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var gate_id: String = ""
@export var required_item_id: String = ""
@export var unlocks_on_interact := true
@export var unlocked := false
@export var locked_text := "Puzzle gate placeholder: locked."
@export var unlocked_text := "Puzzle gate placeholder: open."


func _complete(player: Node = null) -> void:
	if unlocked:
		interaction_text = unlocked_text
		super._complete(player)
		return
	if required_item_id != "" and not bool(GameState.dialogue_flags.get("mission_access_item:" + required_item_id, false)):
		QuestManager.set_objective(locked_text, mission_id)
		DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": locked_text }])
		return
	if unlocks_on_interact:
		unlocked = true
		interaction_text = unlocked_text
	super._complete(player)
