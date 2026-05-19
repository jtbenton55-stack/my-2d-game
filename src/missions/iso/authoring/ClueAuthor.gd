@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Clue / Evidence")
@export var clue_id: StringName = &"clue"
@export var clue_title: String = ""
@export var clue_text: String = ""
@export var case_id: StringName = &"the_big_case"


func _init() -> void:
	preview_color = Color(0.75, 0.55, 0.95, 0.92)
	display_name = "Evidence Clue"


func get_author_kind() -> String:
	return "evidence_clue"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	var cid := String(clue_id).strip_edges()
	if cid == "":
		cid = String(collectible_id).strip_edges()
	cfg["clue_id"] = cid
	cfg["case_id"] = String(case_id).strip_edges()
	if cid != "":
		cfg["collectible_id"] = cid
	var title_s := clue_title.strip_edges()
	if title_s != "":
		cfg["display_name"] = title_s
		cfg["clue_title"] = title_s
	var body_s := clue_text.strip_edges()
	if body_s != "":
		cfg["clue_text"] = body_s
	if String(hideout_collection_key).strip_edges() == "":
		cfg["hideout_collection_key"] = "clue_sauce_packet"
	return cfg
