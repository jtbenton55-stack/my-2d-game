@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Polaroid")
@export var polaroid_id: StringName = &"polaroid"
@export var title: String = ""


func _init() -> void:
	preview_color = Color(0.92, 0.92, 0.98, 0.95)
	display_name = "Polaroid"


func get_author_kind() -> String:
	return "polaroid"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	var pid := String(polaroid_id).strip_edges()
	if pid == "":
		pid = String(collectible_id).strip_edges()
	cfg["polaroid_id"] = pid
	cfg["collectible_id"] = pid if pid != "" else cfg["collectible_id"]
	var t := title.strip_edges()
	if t != "":
		cfg["display_name"] = t
	return cfg
