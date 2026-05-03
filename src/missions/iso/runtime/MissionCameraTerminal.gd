class_name MissionCameraTerminal
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var terminal_id: String = ""
@export var target_group: String = "iso_security_camera"
@export_multiline var success_text: String = "Security cameras disabled."


func _ready() -> void:
	auto_trigger_on_enter = false
	once_only = false
	super._ready()
	add_to_group("iso_camera_terminal")


func _complete(player: Node = null) -> void:
	for node in get_tree().get_nodes_in_group(target_group):
		if node.has_method("set_camera_enabled"):
			node.set_camera_enabled(false)
	var mid := mission_id if mission_id != "" else String(GameState.current_mission_id)
	if mid != "":
		GameState.record_mission_performance_event(mid, "alarms_triggered", 0)
		GameState.set_mission_alert_state(mid, "resolved")
	QuestManager.set_objective(success_text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": success_text }])
	super._complete(player)
