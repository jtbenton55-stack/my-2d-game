@tool
extends "res://src/missions/iso/authoring/MoneyPickupAuthor.gd"
## Authored Case Cash pickup — commits to HideoutHub spendable Case Cash on mission success.

@export_group("Case Cash")
@export var case_cash_amount: int = 10


func _init() -> void:
	preview_color = Color(0.95, 0.72, 0.2, 0.95)
	display_name = "Case Cash"


func get_author_kind() -> String:
	return "case_cash"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	cfg["collectible_type"] = "case_cash"
	cfg["amount"] = maxi(case_cash_amount, maxi(amount, 1))
	cfg["currency_type"] = "case_cash"
	if String(hideout_collection_key).strip_edges() == "":
		cfg["hideout_collection_key"] = "case_cash"
	return cfg
