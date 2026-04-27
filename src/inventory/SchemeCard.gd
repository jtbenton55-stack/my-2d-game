# SchemeCard.gd
# Resource class for Scheme Cards in Untitled Heist RPG

class_name SchemeCard
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D  # placeholder
@export var icon_path: String = ""  # path to icon texture
@export var effect_type: String = ""  # "stat_mod", "boolean", "special"
@export var effect_key: String = ""  # what it modifies
@export var effect_value: float = 0.0
@export var unlock_condition: String = ""  # mission_id or "default"
@export var rarity: String = "common"  # "common", "uncommon", "rare", "legendary"

# Create a SchemeCard resource with given parameters
static func create(id: String, display_name: String, description: String, effect_type: String, effect_key: String, effect_value: float = 0.0, unlock_condition: String = "default", rarity: String = "common", icon_path: String = "") -> SchemeCard:
	var card = SchemeCard.new()
	card.id = id
	card.display_name = display_name
	card.description = description
	card.effect_type = effect_type
	card.effect_key = effect_key
	card.effect_value = effect_value
	card.unlock_condition = unlock_condition
	card.rarity = rarity
	card.icon_path = icon_path
	return card