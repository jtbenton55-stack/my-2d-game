class_name MissionExitTriggerPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

var _exit_completed := false


func _ready() -> void:
	auto_trigger_on_enter = true
	super._ready()
	monitoring = true
	monitorable = true


func _complete(_player: Node = null) -> void:
	if _exit_completed:
		return
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("request_exit_completion"):
		_exit_completed = bool(mission.request_exit_completion(_player))
	elif mission != null and mission.has_method("complete_level"):
		mission.complete_level()
		_exit_completed = true
	else:
		super._complete(_player)
