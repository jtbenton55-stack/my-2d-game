class_name MissionRouteAccessPoint
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var route_id: String = ""
@export var required_card: String = ""
@export var required_item: String = ""
@export var required_clue: String = ""
@export var required_crew_assist: String = ""
@export var target_spawn_id: String = ""
@export var return_spawn_id: String = ""
@export_multiline var locked_message: String = "Route locked."
@export_multiline var unlocked_message: String = "Route available."
@export var is_active := true
@export var is_future_placeholder := false


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	interaction_priority = 80
	allow_repeat_interaction = true
	available_when_completed = true
	super._ready()
	add_to_group("iso_route_access")


func _complete(player: Node = null) -> void:
	if not is_active:
		_show_text("Route is inactive.")
		return
	if not _requirements_met():
		_show_text(locked_message)
		return
	GameState.dialogue_flags["mission_route_access:" + route_id] = true
	var text := unlocked_message
	if is_future_placeholder:
		text += " (Placeholder route; structure is ready for future missions.)"
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("handle_route_access") and target_spawn_id != "":
		var used := bool(mission.handle_route_access(route_id, target_spawn_id, return_spawn_id))
		if used:
			text += " Transitioned to route test area."
	_show_text(text)
	super._complete(player)


func _requirements_met() -> bool:
	if required_card != "" and not GameState.has_scheme_card(required_card):
		return false
	if required_item != "" and not bool(GameState.dialogue_flags.get("mission_access_item:" + required_item, false)):
		return false
	if required_clue != "" and not GameState.has_evidence_clue(required_clue):
		return false
	if required_crew_assist != "" and not GameState.has_crew_assist(required_crew_assist):
		return false
	return true


func _show_text(text: String) -> void:
	QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": text }])
