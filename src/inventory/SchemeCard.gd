class_name SchemeCard
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var icon_path: String = ""
@export var effect_type: String = "boolean"
@export var effect_key: String = ""
@export var effect_value: float = 1.0
@export var unlock_condition: String = "default"
@export var rarity: String = "common"

static func create(card_id: String, card_name: String, card_description: String, card_effect_type = "boolean", card_effect_key = "", card_effect_value = 1.0, card_unlock_condition = "default", card_rarity = "common", card_icon_path = "") -> SchemeCard:
	var card := SchemeCard.new()
	card.id = card_id
	card.display_name = card_name
	card.description = card_description
	card.effect_type = card_effect_type
	card.effect_key = card_effect_key
	card.effect_value = card_effect_value
	card.unlock_condition = card_unlock_condition
	card.rarity = card_rarity
	card.icon_path = card_icon_path
	return card

func get_summary() -> String:
	return display_name + " — " + description
