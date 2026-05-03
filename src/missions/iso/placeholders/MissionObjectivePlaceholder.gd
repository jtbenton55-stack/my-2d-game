class_name MissionObjectivePlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var required := true


func _complete(player: Node = null) -> void:
	super._complete(player)
	EventBus.objective_updated.emit(objective_update if objective_update != "" else display_name + " complete.")
