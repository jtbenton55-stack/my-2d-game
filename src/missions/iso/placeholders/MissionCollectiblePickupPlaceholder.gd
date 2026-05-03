class_name MissionCollectiblePickupPlaceholder
extends "res://src/missions/iso/placeholders/MissionPlaceholderInteractable.gd"

const TypedMissionCollectibleHelper := preload("res://src/missions/iso/TypedMissionCollectible.gd")

@export_enum("polaroid", "glow_guy", "desk_spirit", "tiny_icon", "shelf_goblin", "poop_bag", "evidence_clue", "intel")
var collectible_type: String = "polaroid"
@export var collectible_id: String = ""
@export var required := false


func _complete(player: Node = null) -> void:
	var id := collectible_id if collectible_id != "" else placeholder_id
	if TypedMissionCollectibleHelper.collect(id, collectible_type, mission_id, display_name):
		AudioManager.play_sfx("item_pickup", global_position)
		_emit_collectible_feedback(id)
	super._complete(player)
	set_deferred("monitoring", false)
	visible = false


func _emit_collectible_feedback(id: String) -> void:
	var text := ""
	match collectible_type:
		"glow_guy":
			text = "Glow Guy collected: " + display_name
		"tiny_icon":
			text = "Tiny Icon collected: " + display_name
		"poop_bag":
			text = "Poop Bag collected. Count: " + str(GameState.get_poop_bag_count())
		"polaroid":
			text = "Polaroid collected: " + display_name
		_:
			text = "Collectible recorded: " + (display_name if display_name != "" else id)
	DialogueManager.start_simple_dialogue([{ "speaker": "Collectible", "text": text }])
