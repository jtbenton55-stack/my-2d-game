class_name MissionAccessItemPlaceholder
extends "res://src/missions/iso/placeholders/MissionCollectiblePickupPlaceholder.gd"

@export var access_item_id: String = ""


func _complete(player: Node = null) -> void:
	var id := access_item_id if access_item_id != "" else collectible_id
	if id == "":
		id = placeholder_id
	GameState.dialogue_flags["mission_access_item:" + id] = true
	collectible_id = id
	collectible_type = "intel"
	super._complete(player)
