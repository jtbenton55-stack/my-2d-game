class_name MissionFriendAssistPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

@export var friend_id: String = ""


func _complete(player: Node = null) -> void:
	if friend_id != "":
		GameState.help_friend(friend_id)
	super._complete(player)
