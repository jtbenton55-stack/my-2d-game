class_name MissionCutsceneTriggerPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var lines: Array[Dictionary] = []


func _ready() -> void:
	# Cutscene Areas can sit on top of objectives/clues; keep E reserved for the
	# gameplay interactable and let these fire by proximity only.
	auto_trigger_on_enter = true
	super._ready()
	remove_from_group("interactable")


func _complete(_player: Node = null) -> void:
	if once_only and completed:
		return
	completed = true
	if not lines.is_empty():
		DialogueManager.start_simple_dialogue(lines)
	elif interaction_text != "":
		DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": interaction_text }])
	if objective_update != "":
		QuestManager.set_objective(objective_update, mission_id)
	placeholder_completed.emit(placeholder_id)
