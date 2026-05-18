@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Tiny Icon")
@export var icon_id: StringName = &"tiny_icon"


func _init() -> void:
	preview_color = Color(0.55, 0.65, 0.95, 0.92)
	display_name = "Tiny Icon"


func get_author_kind() -> String:
	return "tiny_icon"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	var iid := String(icon_id).strip_edges()
	if iid == "":
		iid = String(collectible_id).strip_edges()
	cfg["icon_id"] = iid
	cfg["collectible_id"] = iid if iid != "" else cfg["collectible_id"]
	return cfg
