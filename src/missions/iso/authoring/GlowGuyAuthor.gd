@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Glow Guy")
@export var glow_guy_id: StringName = &"glow_guy"


func _init() -> void:
	preview_color = Color(0.35, 0.95, 0.75, 0.92)
	display_name = "Glow Guy"


func get_author_kind() -> String:
	return "glow_guy"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	var gid := String(glow_guy_id).strip_edges()
	if gid == "":
		gid = String(collectible_id).strip_edges()
	cfg["glow_guy_id"] = gid
	if gid != "":
		cfg["collectible_id"] = gid
	if String(hideout_collection_key).strip_edges() == "":
		cfg["hideout_collection_key"] = "glow_guy_taco_bell"
	return cfg
