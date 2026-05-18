@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"

@export_group("Money (proof)")
@export var amount: int = 5
@export var currency_type: StringName = &"cash"


func _init() -> void:
	preview_color = Color(0.95, 0.82, 0.15, 0.92)
	display_name = "Money Pickup"


func get_author_kind() -> String:
	return "money"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	cfg["amount"] = maxi(amount, 1)
	cfg["currency_type"] = String(currency_type).strip_edges()
	if cfg["currency_type"] == "":
		cfg["currency_type"] = "cash"
	return cfg
