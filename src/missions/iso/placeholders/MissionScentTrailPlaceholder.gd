class_name MissionScentTrailPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

const TacoBellDialogue := preload("res://src/missions/iso/runtime/TacoBellDialogue.gd")

@export var trail_id: String = ""
@export var real_trail_id: String = "parking_garage"
@export var objective_id: String = ""
@export_multiline var real_text: String = "Bentley locks onto the Sterling chemical scent."
@export_multiline var fake_text: String = "Bentley sneezes. This smells wrong."


func _ready() -> void:
	set("auto_trigger_on_enter", false)
	set("once_only", false)
	set("allow_repeat_interaction", true)
	set("available_when_completed", false)
	set("interaction_text", "Click to ask Bentley to sniff this trail.")
	set("interaction_priority", 85 if trail_id == real_trail_id else 65)
	super._ready()


func _complete(_player: Node = null) -> void:
	var is_real := trail_id == real_trail_id
	var scent_tracking := GameState.has_scheme_card("bentley_scent_tracking")
	var real_dialogue := TacoBellDialogue.line("scent_real_001", real_text, "Bentley")
	var fake_dialogue := TacoBellDialogue.line("scent_fake_001", fake_text, "Bentley")
	var text := String(real_dialogue.get("text")) if is_real else String(fake_dialogue.get("text"))
	var speaker := String(real_dialogue.get("speaker")) if is_real else String(fake_dialogue.get("speaker"))
	if scent_tracking and is_real:
		text += " Good boy protocol confirms this direction."
	elif scent_tracking and not is_real:
		text += " Bentley flags this as a decoy trail."
	DialogueManager.start_simple_dialogue([{ "speaker": speaker, "text": text }])
	if mission_id != "":
		if not is_real:
			var penalty := 1
			var mission := get_tree().current_scene
			if mission != null and mission.has_method("get_fake_scent_penalty"):
				penalty = int(mission.call("get_fake_scent_penalty"))
			GameState.record_mission_performance_event(mission_id, "wrong_scent_trails_followed", penalty)
			if mission != null and mission.has_method("increment_attempt_counter"):
				mission.call("increment_attempt_counter", "wrong_scent", penalty)
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
		QuestManager.set_objective("Bentley is unsure. Check another trail before committing.", mission_id)
