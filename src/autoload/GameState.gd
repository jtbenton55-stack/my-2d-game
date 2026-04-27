# GameState.gd
# Global game state singleton - V2 architecture for Untitled Heist RPG
# Tracks missions, Scheme Cards, friend-favor flags, collectibles, and progression

extends Node

# Mission tracking
var completed_missions: Array[String] = []
var failed_attempts: Dictionary = {}  # mission_id -> int count
var available_missions: Array[String] = ["taco_bell_drop"]
var current_mission: String = ""

# Scheme Cards
var unlocked_cards: Array[String] = ["bentley_dental_boy", "fish_treat_focus", "jakes_resident_orders"]
var selected_cards: Array[String] = []  # up to 3 selected before mission

# Friend-favor flags
var friend_favors: Dictionary = {}  # friend_id -> {helped: bool, favors_owed: int, card_unlocked: String}

# Collectibles
var collected_polaroids: Array[String] = []
var collected_trinkets: Array[String] = []
var collected_stationery: Array[String] = []
var collected_plants: Array[String] = []
var collected_diamonds: Array[String] = []

# Bentley upgrades
var bentley_upgrades: Array[String] = []  # e.g. "raincoat", "loyalty_surge"

# Player upgrades
var player_upgrades: Array[String] = []

# Dialogue flags
var dialogue_flags: Dictionary = {}  # flag_name -> bool

# Intel/currency from failures
var intel_points: int = 0
var partial_clues: Dictionary = {}  # mission_id -> float (0.0 to 1.0)

# Player stats (from existing system)
var player_health: int = 100
var player_max_health: int = 100
var player_position: Vector2 = Vector2.ZERO
var player_current_scene: String = ""
var player_inventory: Array = []

# Settings (from existing system)
var settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 1.0,
		"sfx_volume": 1.0
	},
	"controls": {
		"mouse_sensitivity": 1.0,
		"gamepad_deadzone": 0.5
	},
	"display": {
		"fullscreen": false,
		"vsync": true
	}
}

# Current game state
var is_paused: bool = false
var is_in_combat: bool = false
var is_in_mission: bool = false

func _ready() -> void:
	EventBus.debug("GameState V2 loaded")
	EventBus.player_health_changed.connect(_on_player_health_changed)
	
	# Initialize friend_favors with default structure for known friends
	var known_friends = ["louis", "mere", "jake", "dom", "yordano", "bryce", "jc", "violet", "jinx", "eren", "kiro", "jin"]
	for friend in known_friends:
		if not friend_favors.has(friend):
			friend_favors[friend] = {
				"helped": false,
				"favors_owed": 0,
				"card_unlocked": ""
			}

# ===== MISSION HELPERS =====

func complete_mission(mission_id: String) -> void:
	"""Mark mission complete, unlock next, set friend flag"""
	if not mission_id in completed_missions:
		completed_missions.append(mission_id)
	
	# Remove from failed attempts if present
	if failed_attempts.has(mission_id):
		failed_attempts.erase(mission_id)
	
	# Unlock next mission if defined in mission data
	var mission_data = MissionData.get_mission(mission_id)
	if mission_data and mission_data.has("unlocks") and mission_data["unlocks"] != "":
		var next_mission = mission_data["unlocks"]
		if not next_mission in available_missions:
			available_missions.append(next_mission)
	
	# Set friend as helped if this mission helps a friend
	var friend_helped = MissionData.get_friend_for_mission(mission_id)
	if friend_helped and friend_favors.has(friend_helped):
		friend_favors[friend_helped]["helped"] = true
		friend_favors[friend_helped]["favors_owed"] += 1
	
	EventBus.mission_completed.emit(mission_id, true)

func fail_mission(mission_id: String, intel_gained: int = 10) -> void:
	"""Increment failures, give partial intel, check for auto-unlock"""
	var current_failures = failed_attempts.get(mission_id, 0)
	current_failures += 1
	failed_attempts[mission_id] = current_failures
	
	# Give intel points
	intel_points += intel_gained
	
	# Give partial clue progress
	var current_clue = partial_clues.get(mission_id, 0.0)
	current_clue += 0.25  # 25% progress per failure
	if current_clue > 1.0:
		current_clue = 1.0
	partial_clues[mission_id] = current_clue
	
	# Auto-unlock hint or card after 3 failures
	if current_failures >= 3:
		var mission_data = MissionData.get_mission(mission_id)
		if mission_data and mission_data.has("hint_card"):
			var hint_card = mission_data["hint_card"]
			if not hint_card in unlocked_cards:
				unlock_card(hint_card)
	
	EventBus.mission_completed.emit(mission_id, false)

func get_failure_count(mission_id: String) -> int:
	"""Get number of failures for a mission"""
	return failed_attempts.get(mission_id, 0)

# ===== SCHEME CARD HELPERS =====

func has_card(card_id: String) -> bool:
	"""Check if card is selected for current mission"""
	return card_id in selected_cards

func unlock_card(card_id: String) -> void:
	"""Add card to unlocked pool"""
	if not card_id in unlocked_cards:
		unlocked_cards.append(card_id)
		EventBus.card_unlocked.emit(card_id)

func select_cards(card_ids: Array[String]) -> void:
	"""Select up to 3 cards for current mission"""
	selected_cards.clear()
	for i in range(min(3, card_ids.size())):
		if card_ids[i] in unlocked_cards:
			selected_cards.append(card_ids[i])
	EventBus.cards_selected.emit(selected_cards)

func clear_selected_cards() -> void:
	"""Clear selected cards after mission"""
	selected_cards.clear()

# ===== FRIEND-FAVOR HELPERS =====

func set_friend_helped(friend_id: String, card_id: String = "") -> void:
	"""Set friend favor flag and optionally unlock their card"""
	if friend_favors.has(friend_id):
		friend_favors[friend_id]["helped"] = true
		friend_favors[friend_id]["favors_owed"] += 1
		if card_id != "":
			friend_favors[friend_id]["card_unlocked"] = card_id
			unlock_card(card_id)

func is_friend_helped(friend_id: String) -> bool:
	"""Check if friend has been helped"""
	return friend_favors.get(friend_id, {}).get("helped", false)

# ===== COLLECTIBLE HELPERS =====

func add_polaroid(polaroid_id: String) -> void:
	"""Add Polaroid to collection"""
	if not polaroid_id in collected_polaroids:
		collected_polaroids.append(polaroid_id)
		EventBus.polaroid_collected.emit(polaroid_id)

func add_trinket(trinket_id: String) -> void:
	"""Add trinket to collection"""
	if not trinket_id in collected_trinkets:
		collected_trinkets.append(trinket_id)
		EventBus.trinket_collected.emit(trinket_id)

func add_stationery(stationery_id: String) -> void:
	"""Add stationery to collection"""
	if not stationery_id in collected_stationery:
		collected_stationery.append(stationery_id)
		EventBus.stationery_collected.emit(stationery_id)

# ===== BENTLEY UPGRADE HELPERS =====

func add_bentley_upgrade(upgrade_id: String) -> void:
	"""Add Bentley upgrade"""
	if not upgrade_id in bentley_upgrades:
		bentley_upgrades.append(upgrade_id)
		EventBus.bentley_upgraded.emit(upgrade_id)

func has_bentley_upgrade(upgrade_id: String) -> bool:
	"""Check if Bentley has upgrade"""
	return upgrade_id in bentley_upgrades

# ===== PLAYER UPGRADE HELPERS =====

func add_player_upgrade(upgrade_id: String) -> void:
	"""Add player upgrade"""
	if not upgrade_id in player_upgrades:
		player_upgrades.append(upgrade_id)
		EventBus.player_upgraded.emit(upgrade_id)

func has_player_upgrade(upgrade_id: String) -> bool:
	"""Check if player has upgrade"""
	return upgrade_id in player_upgrades

# ===== DIALOGUE FLAG HELPERS =====

func set_dialogue_flag(flag: String, value: bool = true) -> void:
	"""Set dialogue flag"""
	dialogue_flags[flag] = value

func get_dialogue_flag(flag: String, default: bool = false) -> bool:
	"""Get dialogue flag"""
	return dialogue_flags.get(flag, default)

# ===== INTEL HELPERS =====

func add_intel_points(amount: int) -> void:
	"""Add intel points"""
	intel_points += amount
	EventBus.intel_changed.emit(intel_points)

func spend_intel_points(amount: int) -> bool:
	"""Spend intel points if enough available"""
	if intel_points >= amount:
		intel_points -= amount
		EventBus.intel_changed.emit(intel_points)
		return true
	return false

# ===== PLAYER STAT HELPERS (from existing system) =====

func set_player_health(health: int) -> void:
	player_health = clamp(health, 0, player_max_health)
	EventBus.player_health_changed.emit(player_health, player_max_health)
	
	if player_health <= 0:
		EventBus.player_died.emit()

func damage_player(amount: int) -> void:
	set_player_health(player_health - amount)

func heal_player(amount: int) -> void:
	set_player_health(player_health + amount)

func set_max_health(max: int) -> void:
	player_max_health = max
	if player_health > max:
		player_health = max
	EventBus.player_health_changed.emit(player_health, player_max_health)

# ===== MISSION STATE HELPERS =====

func start_mission(mission_id: String) -> void:
	if mission_id in available_missions:
		current_mission = mission_id
		is_in_mission = true
		EventBus.mission_started.emit(mission_id)
		EventBus.debug("Started mission: " + mission_id)

func end_mission() -> void:
	if current_mission != "":
		var mission_id = current_mission
		current_mission = ""
		is_in_mission = false
		EventBus.mission_ended.emit(mission_id)

# Signal handlers
func _on_player_health_changed(new_health: int, max_health: int) -> void:
	EventBus.debug("Player health: " + str(new_health) + "/" + str(max_health))

# ===== DATA PERSISTENCE =====

func to_dict() -> Dictionary:
	"""Convert GameState to dictionary for saving"""
	return {
		"completed_missions": completed_missions,
		"failed_attempts": failed_attempts,
		"available_missions": available_missions,
		"unlocked_cards": unlocked_cards,
		"selected_cards": selected_cards,
		"friend_favors": friend_favors,
		"collected_polaroids": collected_polaroids,
		"collected_trinkets": collected_trinkets,
		"collected_stationery": collected_stationery,
		"collected_plants": collected_plants,
		"collected_diamonds": collected_diamonds,
		"bentley_upgrades": bentley_upgrades,
		"player_upgrades": player_upgrades,
		"dialogue_flags": dialogue_flags,
		"intel_points": intel_points,
		"partial_clues": partial_clues,
		"player_health": player_health,
		"player_max_health": player_max_health,
		"player_position": player_position,
		"player_current_scene": player_current_scene,
		"player_inventory": player_inventory,
		"settings": settings
	}

func from_dict(data: Dictionary) -> void:
	"""Load GameState from dictionary"""
	completed_missions = data.get("completed_missions", [])
	failed_attempts = data.get("failed_attempts", {})
	available_missions = data.get("available_missions", ["taco_bell_drop"])
	unlocked_cards = data.get("unlocked_cards", ["bentley_dental_boy", "fish_treat_focus", "jakes_resident_orders"])
	selected_cards = data.get("selected_cards", [])
	friend_favors = data.get("friend_favors", {})
	collected_polaroids = data.get("collected_polaroids", [])
	collected_trinkets = data.get("collected_trinkets", [])
	collected_stationery = data.get("collected_stationery", [])
	collected_plants = data.get("collected_plants", [])
	collected_diamonds = data.get("collected_diamonds", [])
	bentley_upgrades = data.get("bentley_upgrades", [])
	player_upgrades = data.get("player_upgrades", [])
	dialogue_flags = data.get("dialogue_flags", {})
	intel_points = data.get("intel_points", 0)
	partial_clues = data.get("partial_clues", {})
	player_health = data.get("player_health", 100)
	player_max_health = data.get("player_max_health", 100)
	player_position = data.get("player_position", Vector2.ZERO)
	player_current_scene = data.get("player_current_scene", "")
	player_inventory = data.get("player_inventory", [])
	settings = data.get("settings", settings)
	
	# Ensure friend_favors has all known friends
	var known_friends = ["louis", "mere", "jake", "dom", "yordano", "bryce", "jc", "violet", "jinx", "eren", "kiro", "jin"]
	for friend in known_friends:
		if not friend_favors.has(friend):
			friend_favors[friend] = {
				"helped": false,
				"favors_owed": 0,
				"card_unlocked": ""
			}