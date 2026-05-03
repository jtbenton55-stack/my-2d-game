class_name MissionExitTriggerPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"


func _ready() -> void:
	auto_trigger_on_enter = true
	super._ready()


func _complete(_player: Node = null) -> void:
	var mission := get_tree().current_scene
	if mission != null and mission.has_method("complete_level"):
		mission.complete_level()
	else:
		super._complete(_player)
