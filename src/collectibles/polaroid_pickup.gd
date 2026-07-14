extends Area2D

@export var polaroid_id: String = ""

func _ready() -> void:
	add_to_group("interactable")


func is_interaction_available(_player: Node = null) -> bool:
	return visible and collision_layer != 0 and monitoring and not CollectibleManager.is_collected(polaroid_id)

func interact(_player: Node) -> void:
	if polaroid_id == "":
		return
	if CollectibleManager.collect_polaroid(polaroid_id):
		var info := CollectibleManager.get_polaroid_info(polaroid_id)
		MissionInventory.add_item(polaroid_id, 1, {
			"item_id": polaroid_id,
			"display_name": String(info.get("title", polaroid_id.capitalize())),
			"category": "evidence",
			"stackable": false,
			"max_stack": 1,
			"mission_only": true,
		})
		AudioManager.play_sfx("collect", global_position)
	queue_free()
