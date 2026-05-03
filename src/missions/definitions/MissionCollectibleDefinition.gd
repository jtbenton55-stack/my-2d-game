class_name MissionCollectibleDefinition
extends Resource

enum CollectibleType {
	POLAROID,
	GLOW_GUY,
	DESK_SPIRIT,
	TINY_ICON,
	SHELF_GOBLIN,
	POOP_BAG,
	EVIDENCE_CLUE,
	INTEL
}

@export var collectible_id: String = ""
@export var display_name: String = ""
@export var type: CollectibleType = CollectibleType.POLAROID
@export var mission_id: String = ""
@export var zone_id: String = ""
@export var marker_cell: Vector2i = Vector2i.ZERO
@export var required: bool = false
@export var completion_text: String = ""
@export var global_state_key: String = ""
@export var hidden := false
@export var mastery_collectible := false
@export var reward_effect: String = ""
@export var collection_group: String = ""
