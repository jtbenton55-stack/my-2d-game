class_name MissionTransitionPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var transition_id: String = ""
@export var target_scene: String = ""
@export var target_subarea: String = ""
@export var target_spawn_id: String = ""
@export var return_spawn_id: String = ""
@export var required_access: String = ""
@export_multiline var locked_message: String = "Transition locked."
@export var is_placeholder := true


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	interaction_priority = 75
	allow_repeat_interaction = true
	available_when_completed = true
	super._ready()
	add_to_group("iso_transition_trigger")


func _complete(player: Node = null) -> void:
	if required_access != "" and not bool(GameState.dialogue_flags.get(required_access, false)):
		_show(locked_message)
		return
	var text := "Future transition: " + display_name
	if target_subarea != "":
		text += " -> " + target_subarea
	elif target_scene != "":
		text += " -> " + target_scene
	if is_placeholder:
		text += " (placeholder only)"
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("handle_transition_trigger") and target_spawn_id != "":
		var used := bool(mission.handle_transition_trigger(transition_id, target_spawn_id, return_spawn_id))
		if used:
			text += " Transitioned."
	_show(text)
	super._complete(player)


func _show(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": "Transition", "text": text }])
