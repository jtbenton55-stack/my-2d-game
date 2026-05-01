extends Node

var polaroid_catalog: Dictionary = {
	"taco_bell_polaroid": {"title": "Bentley Judges the Bag", "description": "Completion shot — the Taco Bell drop was never just takeout."},
	"taco_bell_midnight_market_rain": {"title": "Midnight Market Rain", "description": "Neon halal cart glow through drizzle by a tired streetlight."},
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
	"taco_bell_glow_guys": {"title": "Glow Guys (Taco Run)", "description": "Tiny glow figures tucked behind the late-night loading gear."},
	"velvet_shelf_goblins": {"title": "Shelf Goblins (Velvet Paw)", "description": "Chunky shelf mascots tucked in the amp-rack shadows."},
	"velvet_bar_polaroid": {"title": "Last Call at the Bar", "description": "A candid from the rail before the house went loud."},
	"persian_tea_hidden": {"title": "Watercolor Conservatory", "description": "Hidden polaroid from the Persian tea conservatory."},
	"ellie_hidden_reunion": {"title": "Bentley Serious Mode", "description": "The moment Bentley stopped joking."},
	"shadow_solo_hidden_pose": {"title": "Shadow Trial Freeze Frame", "description": "A stylish pose from the solo contract trials."},
	"taco_bell_perfect_ambush": {"title": "Parking Garage Ambush", "description": "Perfect clean escape — no alarm, no spotlight chase."},
	"louis_tiny_icon_delivery_bag": {"title": "Louis Tiny Icon", "description": "Shelf trophy: Louis and a late-night delivery bag."},
	"jazz_club_hidden_bentley_stage": {"title": "Bentley at the Jazz Stage", "description": "Neon, sax smoke, and one judgmental Shiba."},
	"jazz_club_perfect_bass_blackout": {"title": "Bass Drop Blackout", "description": "You slipped out while the subs swallowed the alarms."},
	"velvet_bathroom_glow_guy": {"title": "Velvet Paw Glow Guy", "description": "A desk-spirit cousin hiding behind frosted tile."},
	"yordano_tiny_icon_headphones": {"title": "Yordano Tiny Icon", "description": "Shelf trophy: Yordano never skips the drop."},
}

func has_polaroid(polaroid_id: String) -> bool:
	return is_collected(polaroid_id)

func _ready() -> void:
	EventBus.debug("CollectibleManager ready")

func collect_polaroid(polaroid_id: String) -> bool:
	return GameState.collect_polaroid(polaroid_id)

func is_collected(polaroid_id: String) -> bool:
	var nid := GameState.normalize_polaroid_id(polaroid_id)
	return GameState.collected_polaroids.has(nid)

func get_polaroid_info(polaroid_id: String) -> Dictionary:
	var nid := GameState.normalize_polaroid_id(polaroid_id)
	if polaroid_catalog.has(nid):
		return polaroid_catalog[nid]
	return polaroid_catalog.get(polaroid_id, {"title": polaroid_id.capitalize(), "description": "A memory from the city."})

func get_collected_polaroids() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for polaroid_id in GameState.collected_polaroids:
		var info := get_polaroid_info(polaroid_id).duplicate()
		info["id"] = polaroid_id
		out.append(info)
	return out
