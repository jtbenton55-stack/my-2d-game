extends Node

var polaroid_catalog: Dictionary = {
	"taco_bell_polaroid": {"title": "The Taco Bell Drop", "description": "Bentley judging a suspicious delivery bag."},
	"jazz_club_polaroid": {"title": "Velvet Paw", "description": "Noir lights, bass downstairs, secrets backstage."},
	"rewrite_room_polaroid": {"title": "The Rewrite Room", "description": "Creative proof recovered from predatory paperwork."},
	"car_chase_polaroid": {"title": "Fast Family Getaway", "description": "Rain, sirens, and a Shiba with opinions."},
	"final_crew_polaroid": {"title": "Friends Helping Friends", "description": "The whole crew showed up."},
	"clean_job_polaroid": {"title": "The Clean Job", "description": "A luxury showroom code revealed by spotless glass."},
	"diamond_vault_polaroid": {"title": "Diamond a Year", "description": "The tribute stones lined up by year, each one louder than the last."},
	"arm_wrestling_polaroid": {"title": "Arm-Wrestling Underground", "description": "Parmida at the table with Violet watching like a proud coach."},
	"persian_tea_polaroid": {"title": "Persian Tea and Poison Ink", "description": "Sour cherry tea, watercolor clues, and a conservatory saved."},
	"ellie_polaroid": {"title": "The Elephant in the Room", "description": "Bentley reunited with Ellie, the only creature he respects more than himself."},
	"shadow_solo_polaroid": {"title": "Shadow Solo Contract", "description": "Kiro, Jin, neon shadows, and Bentley being unimpressed."},
	"taco_bell_smiskis": {"title": "Hidden Smiskis", "description": "Tiny glow pals tucked behind the Taco Bell loading gear."},
	"velvet_smiskis": {"title": "Velvet Paw Smiskis", "description": "Micro mascots tucked in the amp rack shadows."},
	"velvet_bar_polaroid": {"title": "Last Call at the Bar", "description": "A candid from the rail before the house went loud."}
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
