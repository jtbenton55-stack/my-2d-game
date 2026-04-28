extends Node

var polaroid_catalog: Dictionary = {
	"taco_bell_polaroid": {"title": "The Taco Bell Drop", "description": "Bentley judging a suspicious delivery bag."},
	"jazz_club_polaroid": {"title": "Velvet Paw", "description": "Noir lights, bass downstairs, secrets backstage."},
	"rewrite_room_polaroid": {"title": "The Rewrite Room", "description": "Creative proof recovered from predatory paperwork."},
	"car_chase_polaroid": {"title": "Fast Family Getaway", "description": "Rain, sirens, and a Shiba with opinions."},
	"final_crew_polaroid": {"title": "Friends Helping Friends", "description": "The whole crew showed up."}
}

func _ready() -> void:
	EventBus.debug("CollectibleManager ready")

func collect_polaroid(polaroid_id: String) -> bool:
	return GameState.collect_polaroid(polaroid_id)

func is_collected(polaroid_id: String) -> bool:
	return GameState.collected_polaroids.has(polaroid_id)

func get_polaroid_info(polaroid_id: String) -> Dictionary:
	return polaroid_catalog.get(polaroid_id, {"title": polaroid_id.capitalize(), "description": "A memory from the city."})

func get_collected_polaroids() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for polaroid_id in GameState.collected_polaroids:
		var info := get_polaroid_info(polaroid_id).duplicate()
		info["id"] = polaroid_id
		out.append(info)
	return out
