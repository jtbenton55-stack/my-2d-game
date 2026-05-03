class_name MissionPoopBagPlaceholder
extends "res://src/missions/iso/placeholders/MissionCollectiblePickupPlaceholder.gd"


func _ready() -> void:
	collectible_type = "poop_bag"
	display_name = "Bentley Poop Bag" if display_name == "Placeholder" else display_name
	super._ready()
