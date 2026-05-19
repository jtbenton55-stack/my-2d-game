@tool
extends "res://src/missions/iso/authoring/CollectibleAuthorBase.gd"
## DEPRECATED: compatibility alias for legacy scene nodes.
## Forward-looking mission currency authoring should use CaseCashAuthor.

@export_group("Money / Case Cash (proof)")
@export var amount: int = 5
@export var currency_type: StringName = &"cash"
## When true, pending pickup commits to HideoutHub Case Cash (same as CaseCashAuthor).
@export var commits_as_case_cash := true


func _init() -> void:
	preview_color = Color(0.95, 0.82, 0.15, 0.92)
	display_name = "Case Cash (Legacy Alias)"


func get_author_kind() -> String:
	# Keep old script path usable while forcing the unified case_cash path.
	return "case_cash"


func build_runtime_config() -> Dictionary:
	var cfg := super.build_runtime_config()
	cfg["collectible_type"] = "case_cash"
	cfg["amount"] = maxi(amount, 1)
	cfg["currency_type"] = String(currency_type).strip_edges()
	if cfg["currency_type"] == "":
		cfg["currency_type"] = "case_cash"
	if cfg["currency_type"] != "case_cash":
		cfg["currency_type"] = "case_cash"
	if commits_as_case_cash:
		cfg["commits_as_case_cash"] = true
	cfg["is_legacy_money_alias"] = true
	if String(hideout_collection_key).strip_edges() == "":
		cfg["hideout_collection_key"] = "case_cash"
	return cfg
