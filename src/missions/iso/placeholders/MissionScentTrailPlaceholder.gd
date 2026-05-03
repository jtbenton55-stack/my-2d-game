class_name MissionScentTrailPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var trail_id: String = ""
@export var real_trail_id: String = "parking_garage"
@export var objective_id: String = ""
@export_multiline var real_text: String = "Bentley locks onto the Sterling chemical scent."
@export_multiline var fake_text: String = "Bentley sneezes. This smells wrong."


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	allow_repeat_interaction = true
	available_when_completed = false
	interaction_text = "Press E: Ask Bentley to sniff this trail."
	interaction_priority = 85 if trail_id == real_trail_id else 65
	super._ready()


func _complete(_player: Node = null) -> void:
	var is_real := trail_id == real_trail_id
	var text := real_text if is_real else fake_text
	DialogueManager.start_simple_dialogue([{ "speaker": "Bentley", "text": text }])
	if mission_id != "":
		if is_real:
			GameState.record_mission_performance_event(mission_id, "wrong_scent_trails_followed", 0)
		else:
			GameState.record_mission_performance_event(mission_id, "wrong_scent_trails_followed", 1)
	if is_real:
		if objective_id != "":
			placeholder_completed.emit(objective_id)
		var mission := get_tree().current_scene
		if mission != null and mission.has_method("set_iso_access_item"):
			mission.set_iso_access_item("real_scent_trail")
		if objective_update != "":
			QuestManager.set_objective(objective_update, mission_id)
		remove_from_group("interactable")
		set_deferred("monitoring", false)
	else:
		QuestManager.set_objective("Wrong scent trail. Use Bentley to sniff the other trails.", mission_id)
