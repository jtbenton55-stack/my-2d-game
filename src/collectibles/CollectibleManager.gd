# CollectibleManager.gd
# Autoload singleton for managing all collectibles in Untitled Heist RPG
# Types: polaroids, trinkets, stationery, plants, diamonds

extends Node

# ===== ENUMS & CONSTANTS =====

enum CollectibleType {
	POLAROID,
	TRINKET,
	STATIONERY,
	PLANT,
	DIAMOND
}

const TYPE_NAMES: Dictionary = {
	CollectibleType.POLAROID: "polaroids",
	CollectibleType.TRINKET: "trinkets",
	CollectibleType.STATIONERY: "stationery",
	CollectibleType.PLANT: "plants",
	CollectibleType.DIAMOND: "diamonds"
}

# Polaroid metadata: { id: { title: String, description: String, mission: String, unlocked_after: String } }
var _polaroid_metadata: Dictionary = {}

# Trinket metadata: { id: { name: String, description: String, source: String } }
var _trinket_metadata: Dictionary = {}

# Stationery metadata: { id: { name: String, description: String, source: String } }
var _stationery_metadata: Dictionary = {}

# Plant metadata: { id: { name: String, description: String, source: String } }
var _plant_metadata: Dictionary = {}

# Diamond metadata: { id: { name: String, description: String, source: String } }
var _diamond_metadata: Dictionary = {}

# ===== SIGNALS =====

signal collectible_collected(type: int, id: String)
signal polaroid_wall_updated

# ===== LIFECYCLE =====

func _ready() -> void:
	_load_metadata()
	EventBus.debug("CollectibleManager loaded")

# ===== PUBLIC API =====

func add_collectible(type: int, id: String) -> bool:
	"""Add a collectible to the player's collection. Returns true if newly collected."""
	var game_state := _get_game_state()
	if not game_state:
		push_warning("CollectibleManager: GameState not found")
		return false

	var type_name := _type_to_name(type)
	var collection := _get_collection(game_state, type)

	if id in collection:
		EventBus.debug("Collectible already collected: " + type_name + "/" + id)
		return false

	collection.append(id)
	_sync_collection_to_game_state(game_state, type, collection)

	EventBus.debug("Collectible collected: " + type_name + "/" + id)
	collectible_collected.emit(type, id)

	if type == CollectibleType.POLAROID:
		EventBus.polaroid_collected.emit(id)
		polaroid_wall_updated.emit()
	elif type == CollectibleType.TRINKET:
		EventBus.trinket_collected.emit(id)
	elif type == CollectibleType.STATIONERY:
		EventBus.stationery_collected.emit(id)

	return true

func has_collectible(type: int, id: String) -> bool:
	"""Check if player has collected a specific item."""
	var game_state := _get_game_state()
	if not game_state:
		return false

	var collection := _get_collection(game_state, type)
	return id in collection

func get_collected_count(type: int) -> int:
	"""Get the number of collected items of a given type."""
	var game_state := _get_game_state()
	if not game_state:
		return 0

	return _get_collection(game_state, type).size()

func get_collected_ids(type: int) -> Array[String]:
	"""Get all collected IDs of a given type."""
	var game_state := _get_game_state()
	if not game_state:
		return []

	var collection := _get_collection(game_state, type)
	var result: Array[String] = []
	result.assign(collection)
	return result

func get_total_collected() -> int:
	"""Get total count of all collectibles."""
	var total := 0
	for type in TYPE_NAMES.keys():
		total += get_collected_count(type)
	return total

# ===== POLAROID WALL LOGIC =====

func get_polaroid_wall_data() -> Array[Dictionary]:
	"""Get data for displaying polaroids on the wall. Returns array of { id, title, description, mission, texture_path }."""
	var result: Array[Dictionary] = []
	var collected := get_collected_ids(CollectibleType.POLAROID)

	for id in collected:
		var meta := _polaroid_metadata.get(id, {})
		result.append({
			"id": id,
			"title": meta.get("title", id),
			"description": meta.get("description", ""),
			"mission": meta.get("mission", ""),
			"texture_path": meta.get("texture_path", "")
		})

	return result

func get_polaroid_metadata(id: String) -> Dictionary:
	"""Get metadata for a specific polaroid."""
	return _polaroid_metadata.get(id, {})

func is_polaroid_unlocked(id: String) -> bool:
	"""Check if a polaroid is collected."""
	return has_collectible(CollectibleType.POLAROID, id)

# ===== METADATA API =====

func get_collectible_name(type: int, id: String) -> String:
	"""Get display name for a collectible."""
	var meta := _get_metadata(type, id)
	return meta.get("name", meta.get("title", id))

func get_collectible_description(type: int, id: String) -> String:
	"""Get description for a collectible."""
	var meta := _get_metadata(type, id)
	return meta.get("description", "")

# ===== SAVE/LOAD =====

func to_dict() -> Dictionary:
	"""Export collectible metadata state (for any runtime metadata changes)."""
	return {
		"polaroid_metadata": _polaroid_metadata.duplicate(true),
		"trinket_metadata": _trinket_metadata.duplicate(true),
		"stationery_metadata": _stationery_metadata.duplicate(true),
		"plant_metadata": _plant_metadata.duplicate(true),
		"diamond_metadata": _diamond_metadata.duplicate(true)
	}

func from_dict(data: Dictionary) -> void:
	"""Import collectible metadata state."""
	if data.has("polaroid_metadata"):
		_polaroid_metadata = data["polaroid_metadata"].duplicate(true)
	if data.has("trinket_metadata"):
		_trinket_metadata = data["trinket_metadata"].duplicate(true)
	if data.has("stationery_metadata"):
		_stationery_metadata = data["stationery_metadata"].duplicate(true)
	if data.has("plant_metadata"):
		_plant_metadata = data["plant_metadata"].duplicate(true)
	if data.has("diamond_metadata"):
		_diamond_metadata = data["diamond_metadata"].duplicate(true)

# ===== INTERNAL HELPERS =====

func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _type_to_name(type: int) -> String:
	return TYPE_NAMES.get(type, "unknown")

func _get_collection(game_state: Node, type: int) -> Array:
	"""Get the appropriate collection array from GameState."""
	match type:
		CollectibleType.POLAROID:
			return game_state.collected_polaroids
		CollectibleType.TRINKET:
			return game_state.collected_trinkets
		CollectibleType.STATIONERY:
			return game_state.collected_stationery
		CollectibleType.PLANT:
			return game_state.collected_plants if game_state.get("collected_plants") != null else []
		CollectibleType.DIAMOND:
			return game_state.collected_diamonds if game_state.get("collected_diamonds") != null else []
		_:
			return []

func _sync_collection_to_game_state(game_state: Node, type: int, collection: Array) -> void:
	"""Sync a collection back to GameState."""
	match type:
		CollectibleType.POLAROID:
			game_state.collected_polaroids = collection
		CollectibleType.TRINKET:
			game_state.collected_trinkets = collection
		CollectibleType.STATIONERY:
			game_state.collected_stationery = collection
		CollectibleType.PLANT:
			if game_state.get("collected_plants") != null:
				game_state.collected_plants = collection
		CollectibleType.DIAMOND:
			if game_state.get("collected_diamonds") != null:
				game_state.collected_diamonds = collection

func _get_metadata(type: int, id: String) -> Dictionary:
	"""Get metadata dictionary for a collectible type."""
	match type:
		CollectibleType.POLAROID:
			return _polaroid_metadata.get(id, {})
		CollectibleType.TRINKET:
			return _trinket_metadata.get(id, {})
		CollectibleType.STATIONERY:
			return _stationery_metadata.get(id, {})
		CollectibleType.PLANT:
			return _plant_metadata.get(id, {})
		CollectibleType.DIAMOND:
			return _diamond_metadata.get(id, {})
		_:
			return {}

func _load_metadata() -> void:
	"""Load default collectible metadata. In a full game, this would load from JSON files."""
	# Polaroids — each tied to a mission or story moment
	_polaroid_metadata = {
		"taco_bell_drop_01": {
			"title": "The Drop",
			"description": "Louis handing off a bag that definitely isn't just tacos.",
			"mission": "taco_bell_drop",
			"texture_path": "res://assets/sprites/polaroids/taco_bell_drop_01.png"
		},
		"bentley_first_heist": {
			"title": "Bentley's Debut",
			"description": "His first heist. He was very judgmental about the plan.",
			"mission": "taco_bell_drop",
			"texture_path": "res://assets/sprites/polaroids/bentley_first_heist.png"
		},
		"jake_stitching": {
			"title": "3 AM Stitches",
			"description": "Jake patching you up after the rooftop incident.",
			"mission": "",
			"texture_path": "res://assets/sprites/polaroids/jake_stitching.png"
		},
		"rewrite_room": {
			"title": "The Rewrite Room",
			"description": "Sterling's law office. Those file cabinets hold more secrets than the city.",
			"mission": "rewrite_room",
			"texture_path": "res://assets/sprites/polaroids/rewrite_room.png"
		}
	}

	# Trinkets — small mementos from friends and missions
	_trinket_metadata = {
		"louis_hot_sauce": {
			"name": "Louis' Hot Sauce",
			"description": "A bottle of Diablo sauce. Louis says it's 'evidence.'",
			"source": "louis"
		},
		"mere_contract_pen": {
			"name": "Mere's Pen",
			"description": "A fountain pen that has signed more NDAs than treaties.",
			"source": "mere"
		},
		"bentley_chewed_slipper": {
			"name": "Chewed Slipper",
			"description": "Bentley's first victim. You kept it.",
			"source": "bentley"
		}
	}

	# Stationery — letters, notes, doodles
	_stationery_metadata = {
		"jake_lunch_note": {
			"name": "Lunch Note",
			"description": "'Don't get stabbed. —Jake' Written on a prescription pad.",
			"source": "jake"
		},
		"mere_legal_memo": {
			"name": "Legal Memo",
			"description": "A memo titled 'Why Your Plan Constitutes Conspiracy.' It's 47 pages.",
			"source": "mere"
		},
		"rewrite_memo": {
			"name": "Rewrite Room Memo",
			"description": "A sticky note from Sterling's assistant: 'Three fakes, one real. Prop house delivered.'",
			"source": "rewrite_room"
		},
		"redlined_contract": {
			"name": "Redlined Contract",
			"description": "A contract with aggressive red marks. Someone was very unhappy with these terms.",
			"source": "rewrite_room"
		}
	}

	# Plants — hideout decorations
	_plant_metadata = {
		"hideout_succulent": {
			"name": "Hideout Succulent",
			"description": "A small succulent. Jake says it has a better survival rate than you.",
			"source": "hideout"
		},
		"mere_fern": {
			"name": "Mere's Fern",
			"description": "A fern Mere brought to 'improve the working conditions.'",
			"source": "mere"
		}
	}

	# Diamonds — premium/heist rewards
	_diamond_metadata = {
		"taco_bell_diamond": {
			"name": "The Crunchwrap Diamond",
			"description": "A diamond shaped like a Crunchwrap. Louis is horrified and impressed.",
			"source": "taco_bell_drop"
		}
	}
