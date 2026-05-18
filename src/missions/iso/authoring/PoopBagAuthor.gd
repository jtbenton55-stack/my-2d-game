@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Poop Bag")
@export var poop_count: int = 1


func _init() -> void:
	preview_color = Color(0.55, 0.85, 0.45, 0.9)
	display_name = "Bentley Poop Bag"


func get_author_kind() -> String:
	return "poop_bag"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	cfg["poop_count"] = maxi(poop_count, 1)
	return cfg
