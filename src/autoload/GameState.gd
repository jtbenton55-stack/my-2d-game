extends Node

const SAVE_VERSION := "0.3.0-rescue"
const MAX_SELECTED_CARDS := 3

var mission_catalog: Dictionary = {
	"test_mission": {"name": "Test Mission Room", "description": "A tiny safe room for proving the full heist loop works.", "scene_path": "res://scenes/missions/TestMissionRoom.tscn", "reward_cards": [], "reward_polaroids": [], "friend": ""},
	"taco_bell_drop": {"name": "The Taco Bell Drop", "description": "Recover Louis's bag and the first Sterling clue.", "scene_path": "res://scenes/missions/TacoBellMission.tscn", "reward_cards": ["louis_delivery_route"], "reward_polaroids": ["taco_bell_polaroid"], "friend": "louis"},
	"velvet_paw_jazz_club": {"name": "The Velvet Paw Jazz Club", "description": "Steal the blackmail ledger hidden in the setlist.", "scene_path": "res://scenes/missions/JazzClubMission.tscn", "reward_cards": ["yordano_bass_drop", "two_letters_away"], "reward_polaroids": ["jazz_club_polaroid"], "friend": "yordano"},
	"rewrite_room": {"name": "The Rewrite Room", "description": "Recover stolen creative documents from Sterling's lawyers.", "scene_path": "res://scenes/missions/RewriteRoomMission.tscn", "reward_cards": ["stationery_queen", "mere_legal_eyes"], "reward_polaroids": ["rewrite_room_polaroid"], "friend": "mere"},
	"fast_family_getaway": {"name": "The Fast Family Getaway", "description": "Help Dom escape with the evidence through a rainy city chase.", "scene_path": "res://scenes/missions/CarChaseMission.tscn", "reward_cards": ["doms_getaway_keys"], "reward_polaroids": ["car_chase_polaroid"], "friend": "dom"},
	"sterling_tower_heist": {"name": "The Sterling Tower Heist", "description": "The final job: every favor comes due.", "scene_path": "res://scenes/missions/SterlingTowerMission.tscn", "reward_cards": [], "reward_polaroids": ["final_crew_polaroid"], "friend": "crew"}
}

var settings: Dictionary = {"audio": {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 0.9}, "accessibility": {"screenshake": true, "typewriter": true}}
var available_missions: Array[String] = []
var completed_missions: Array[String] = []
var failed_attempts: Dictionary = {}
var unlocked_cards: Array[String] = []
var selected_cards: Array[String] = []
var collected_polaroids: Array[String] = []
var crew_members: Array[String] = []
var friend_favors: Dictionary = {}
var player_upgrades: Dictionary = {}
var bentley_upgrades: Dictionary = {}
var dialogue_flags: Dictionary = {}
var intel_points: int = 0
var player_max_health: int = 100
var player_health: int = 100
var current_mission_id: String = ""
var pending_mission_id: String = ""
var is_in_mission: bool = false
var last_mission_result: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	reset_for_new_game(false)
	EventBus.debug("GameState ready")

func reset_for_new_game(emit_change = true) -> void:
	available_missions = ["test_mission", "taco_bell_drop"]
	completed_missions = []
	failed_attempts = {}
	unlocked_cards = ["bentley_dental_boy", "fish_treat_focus", "jakes_resident_orders"]
	selected_cards = []
	collected_polaroids = []
	crew_members = ["jake", "bentley"]
	friend_favors = {}
	for friend_id in ["louis", "mere", "jake", "dom", "yordano", "bryce", "jc", "violet", "jinx", "eren", "kiro", "jin", "crew"]:
		friend_favors[friend_id] = {"helped": false, "favors_owed": 0, "card_unlocked": ""}
	player_upgrades = {}
	bentley_upgrades = {}
	dialogue_flags = {}
	intel_points = 0
	player_max_health = 100
	player_health = player_max_health
	current_mission_id = ""
	pending_mission_id = ""
	is_in_mission = false
	last_mission_result = {}
	player_position = Vector2.ZERO
	if emit_change:
		EventBus.game_state_changed.emit()

func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	pending_mission_id = ""
	is_in_mission = true
	player_health = player_max_health
	dialogue_flags.erase("dental_boy_used")
	EventBus.mission_started.emit(mission_id)
	EventBus.debug("Mission started: " + mission_id)
	EventBus.game_state_changed.emit()

func complete_mission(mission_id = "") -> Dictionary:
	if mission_id == "":
		mission_id = current_mission_id
	if mission_id == "":
		mission_id = "test_mission"
	is_in_mission = false
	current_mission_id = ""
	if not completed_missions.has(mission_id):
		completed_missions.append(mission_id)
	var rewards := _grant_success_rewards(mission_id)
	last_mission_result = {"success": true, "mission_id": mission_id, "title": "Clean Getaway", "subtitle": _mission_name(mission_id) + " complete.", "rewards": rewards}
	EventBus.mission_completed.emit(mission_id, rewards)
	EventBus.mission_result_ready.emit(last_mission_result)
	EventBus.game_state_changed.emit()
	return last_mission_result

func fail_mission(mission_id = "", reason = "The job went sideways.") -> Dictionary:
	if mission_id == "":
		mission_id = current_mission_id
	if mission_id == "":
		mission_id = "test_mission"
	is_in_mission = false
	current_mission_id = ""
	failed_attempts[mission_id] = int(failed_attempts.get(mission_id, 0)) + 1
	intel_points += 1
	var rewards: Array[String] = ["+1 intel point"]
	last_mission_result = {"success": false, "mission_id": mission_id, "title": "The Job Went Sideways", "subtitle": reason, "rewards": rewards}
	EventBus.mission_failed.emit(mission_id, reason)
	EventBus.mission_result_ready.emit(last_mission_result)
	EventBus.game_state_changed.emit()
	return last_mission_result

func _grant_success_rewards(mission_id: String) -> Array[String]:
	var rewards: Array[String] = []
	var info := get_mission_info(mission_id)
	for card_id in info.get("reward_cards", []):
		if unlock_card(String(card_id)):
			rewards.append("Unlocked card: " + _pretty_id(String(card_id)))
	for polaroid_id in info.get("reward_polaroids", []):
		if collect_polaroid(String(polaroid_id)):
			rewards.append("Polaroid: " + _pretty_id(String(polaroid_id)))
	var friend_id := String(info.get("friend", ""))
	if friend_id != "":
		help_friend(friend_id)
		rewards.append("Crew favor: " + _pretty_id(friend_id))
	_unlock_next_missions(mission_id)
	intel_points += 3
	rewards.append("+3 intel points")
	return rewards

func _unlock_next_missions(mission_id: String) -> void:
	match mission_id:
		"taco_bell_drop":
			unlock_mission("velvet_paw_jazz_club")
			unlock_mission("rewrite_room")
		"velvet_paw_jazz_club":
			unlock_mission("fast_family_getaway")
		"rewrite_room":
			unlock_mission("fast_family_getaway")
		"fast_family_getaway":
			unlock_mission("sterling_tower_heist")
		_:
			pass

func unlock_mission(mission_id: String) -> bool:
	if not mission_catalog.has(mission_id):
		return false
	if available_missions.has(mission_id):
		return false
	available_missions.append(mission_id)
	return true

func unlock_card(card_id: String) -> bool:
	if unlocked_cards.has(card_id):
		return false
	unlocked_cards.append(card_id)
	EventBus.card_unlocked.emit(card_id)
	return true

func collect_polaroid(polaroid_id: String) -> bool:
	if collected_polaroids.has(polaroid_id):
		return false
	collected_polaroids.append(polaroid_id)
	EventBus.polaroid_collected.emit(polaroid_id)
	return true

func help_friend(friend_id: String) -> void:
	if not crew_members.has(friend_id):
		crew_members.append(friend_id)
	var data: Dictionary = friend_favors.get(friend_id, {"helped": false, "favors_owed": 0, "card_unlocked": ""})
	data["helped"] = true
	data["favors_owed"] = int(data.get("favors_owed", 0)) + 1
	friend_favors[friend_id] = data
	EventBus.friend_helped.emit(friend_id)

func set_pending_mission(mission_id: String) -> void:
	pending_mission_id = mission_id

func set_selected_cards(cards: Array) -> void:
	selected_cards = []
	for card_id in cards:
		var id := String(card_id)
		if unlocked_cards.has(id) and selected_cards.size() < MAX_SELECTED_CARDS:
			selected_cards.append(id)
	EventBus.card_selection_changed.emit(selected_cards)
	EventBus.game_state_changed.emit()

func clear_selected_cards() -> void:
	selected_cards.clear()
	EventBus.card_selection_changed.emit(selected_cards)

func has_selected_card(card_id: String) -> bool:
	return selected_cards.has(card_id)

func has_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)

func get_mission_info(mission_id: String) -> Dictionary:
	return mission_catalog.get(mission_id, {"name": _pretty_id(mission_id), "description": "Mission data missing.", "scene_path": "res://scenes/missions/TestMissionRoom.tscn", "reward_cards": [], "reward_polaroids": [], "friend": ""})

func get_available_mission_ids() -> Array[String]:
	var ids: Array[String] = []
	for mission_id in available_missions:
		if mission_catalog.has(mission_id):
			ids.append(mission_id)
	return ids

func get_mission_scene_path(mission_id: String) -> String:
	return String(get_mission_info(mission_id).get("scene_path", "res://scenes/missions/TestMissionRoom.tscn"))

func damage_player(amount: int) -> void:
	player_health = max(0, player_health - amount)
	EventBus.player_health_changed.emit(player_health, player_max_health)
	EventBus.player_damaged.emit(amount, player_health)
	if player_health <= 0:
		EventBus.player_died.emit()

func heal_player(amount: int) -> void:
	player_health = min(player_max_health, player_health + amount)
	EventBus.player_health_changed.emit(player_health, player_max_health)

func _mission_name(mission_id: String) -> String:
	return String(get_mission_info(mission_id).get("name", _pretty_id(mission_id)))

func _pretty_id(id: String) -> String:
	var parts := id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)

func to_dict() -> Dictionary:
	return {"save_version": SAVE_VERSION, "available_missions": available_missions, "completed_missions": completed_missions, "failed_attempts": failed_attempts, "unlocked_cards": unlocked_cards, "selected_cards": selected_cards, "collected_polaroids": collected_polaroids, "crew_members": crew_members, "friend_favors": friend_favors, "player_upgrades": player_upgrades, "bentley_upgrades": bentley_upgrades, "dialogue_flags": dialogue_flags, "intel_points": intel_points, "player_max_health": player_max_health, "player_health": player_health, "settings": settings}

func from_dict(data: Dictionary) -> void:
	available_missions = _as_string_array(data.get("available_missions", available_missions))
	completed_missions = _as_string_array(data.get("completed_missions", []))
	failed_attempts = Dictionary(data.get("failed_attempts", {}))
	unlocked_cards = _as_string_array(data.get("unlocked_cards", unlocked_cards))
	selected_cards = _as_string_array(data.get("selected_cards", []))
	collected_polaroids = _as_string_array(data.get("collected_polaroids", []))
	crew_members = _as_string_array(data.get("crew_members", crew_members))
	friend_favors = Dictionary(data.get("friend_favors", friend_favors))
	player_upgrades = Dictionary(data.get("player_upgrades", {}))
	bentley_upgrades = Dictionary(data.get("bentley_upgrades", {}))
	dialogue_flags = Dictionary(data.get("dialogue_flags", {}))
	intel_points = int(data.get("intel_points", 0))
	player_max_health = int(data.get("player_max_health", 100))
	player_health = int(data.get("player_health", player_max_health))
	settings = Dictionary(data.get("settings", settings))
	is_in_mission = false
	current_mission_id = ""
	pending_mission_id = ""
	EventBus.game_state_changed.emit()

func _as_string_array(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out
