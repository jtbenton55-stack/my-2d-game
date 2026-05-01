extends Node

const SAVE_VERSION := "0.4.0-bible"
const MAX_SELECTED_CARDS := 3

var mission_catalog: Dictionary = {
	"test_mission": {"name": "Test Mission Room", "description": "A tiny safe room for proving the full heist loop works.", "scene_path": "res://scenes/missions/TestMissionRoom.tscn", "reward_cards": [], "reward_polaroids": [], "friend": ""},
	"taco_bell_drop": {"name": "The Taco Bell Drop", "description": "Recover Louis's bag and the first Sterling clue.", "scene_path": "res://scenes/missions/TacoBellMission.tscn", "reward_cards": ["louis_delivery_route"], "reward_polaroids": ["taco_bell_polaroid"], "friend": "louis"},
	"velvet_paw_jazz_club": {"name": "The Velvet Paw Jazz Club", "description": "Yordano's bass drops hide more than beats. His setlist contains blackmail names from Sterling's network.", "scene_path": "res://scenes/missions/JazzClubMission.tscn", "reward_cards": ["yordano_bass_drop", "two_letters_away"], "reward_polaroids": ["jazz_club_polaroid"], "friend": "yordano"},
	"rewrite_room": {"name": "The Rewrite Room", "description": "The showroom fingerprints matched Mere's legal files. Sterling's lawyers stole creative works - time to rewrite the contracts.", "scene_path": "res://scenes/missions/RewriteRoomMission.tscn", "reward_cards": ["stationery_queen", "mere_legal_eyes"], "reward_polaroids": ["rewrite_room_polaroid"], "friend": "mere"},
	"fast_family_getaway": {"name": "The Fast Family Getaway", "description": "Dom's family chased the evidence. Now Sterling's men chase Dom. The tea ceremony holds the final clue.", "scene_path": "res://scenes/missions/CarChaseMission.tscn", "reward_cards": ["doms_getaway_keys"], "reward_polaroids": ["car_chase_polaroid"], "friend": "dom"},
	"sterling_tower_heist": {"name": "The Sterling Tower Heist", "description": "Every clue gathered. Every friend helped. The tower awaits - and Victor Sterling with it.", "scene_path": "res://scenes/missions/SterlingTowerMission.tscn", "reward_cards": [], "reward_polaroids": ["final_crew_polaroid"], "friend": "crew"},
	"clean_job": {"name": "The Clean Job", "description": "Louis's bag contained a cleaning invoice from Sterling's luxury showroom. The code is hidden in the fingerprints.", "scene_path": "res://scenes/missions/CleanJobMission.tscn", "reward_cards": ["clorox_wipe_protocol"], "reward_polaroids": ["clean_job_polaroid"], "friend": "jinx"},
	"diamond_a_year_job": {"name": "The Diamond a Year Job", "description": "The legal documents revealed Sterling's vault tribute - fifteen diamonds, one for each year of stolen work.", "scene_path": "res://scenes/missions/DiamondVaultMission.tscn", "reward_cards": ["diamond_a_year", "bryce_swiss_timing"], "reward_polaroids": ["diamond_vault_polaroid"], "friend": "bryce"},
	"arm_wrestling_underground": {"name": "The Arm-Wrestling Underground", "description": "Win Violet's strength-club challenge and earn a counterpunch.", "scene_path": "res://scenes/missions/ArmWrestlingMission.tscn", "reward_cards": ["violet_counterpunch"], "reward_polaroids": ["arm_wrestling_polaroid"], "friend": "violet"},
	"persian_tea_poison_ink": {"name": "Persian Tea and Poison Ink", "description": "JC's conservatory hides poison ink - the correspondence that links Sterling to the shadow arena.", "scene_path": "res://scenes/missions/PersianTeaMission.tscn", "reward_cards": ["persian_tea_focus"], "reward_polaroids": ["persian_tea_polaroid"], "friend": "jc"},
	"elephant_in_the_room": {"name": "The Elephant in the Room", "description": "Bentley lost Ellie years ago. The shadow arena contract mentions a pink elephant in storage.", "scene_path": "res://scenes/missions/ElephantRoomMission.tscn", "reward_cards": ["polaroid_proof"], "reward_polaroids": ["ellie_polaroid"], "friend": "bentley"},
	"shadow_solo_contract": {"name": "The Shadow Solo Contract", "description": "Kiro and Jin's arena guards Sterling Tower's back entrance. Clear the contract, reach the tower.", "scene_path": "res://scenes/missions/ShadowSoloMission.tscn", "reward_cards": ["jc_london_contact"], "reward_polaroids": ["shadow_solo_polaroid"], "friend": "jin"}
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
var next_spawn: String = "default"
var evidence_board_data: Dictionary = {}
var equipped_items: Array[String] = []

## Serialized when leaving JazzClubMission for the owner-suite boss arena; reapplied on return.
var velvet_paw_resume_data: Dictionary = {}

## Mission Bible: heat is derived from failed_attempts (capped); mutations are rolled per mission and saved.
var mission_mutation_state: Dictionary = {}

## Structured Sterling clues for evidence board import; id -> {title, description, category, mission_id, connects_to, unlocks_or_modifies, discovered}
var sterling_clues: Dictionary = {}

## Bentley poop bags — global inventory + per-attempt pickup count for Responsible Crime Lord bonus.
var poop_bag_count: int = 0
var poop_bags_this_mission_attempt: int = 0

## If true, every mission in mission_catalog is added to available_missions after reset (local QA only).
## Default false so release/story order stay intact. Tests force off during runs.
var debug_unlock_all_missions: bool = false

## Legacy polaroid IDs (pre legal-safe rename) map to canonical IDs for saves and pickups.
const POLAROID_LEGACY_IDS: Dictionary = {
	"taco_bell_smiskis": "taco_bell_glow_guys",
	"velvet_smiskis": "velvet_shelf_goblins",
	"rewrite_room_proof": "rewrite_room_polaroid",
	"conservatory_serenity": "persian_tea_hidden",
	"ellie_rescue": "ellie_hidden_reunion",
	"shadow_solo_pose": "shadow_solo_hidden_pose",
}


func normalize_polaroid_id(polaroid_id: String) -> String:
	return String(POLAROID_LEGACY_IDS.get(polaroid_id, polaroid_id))


func _migrate_polaroid_ids_inplace() -> void:
	var out: Array[String] = []
	var seen: Dictionary = {}
	for id in collected_polaroids:
		var nid := normalize_polaroid_id(String(id))
		if seen.has(nid):
			continue
		seen[nid] = true
		out.append(nid)
	collected_polaroids = out


func get_mission_heat(mission_id: String) -> int:
	return mini(5, int(failed_attempts.get(mission_id, 0)))


func get_or_roll_mission_mutations(mission_id: String, pool: Dictionary) -> Dictionary:
	if mission_mutation_state.has(mission_id):
		return mission_mutation_state[mission_id].duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash(str(mission_id) + "_" + str(int(failed_attempts.get(mission_id, 0))))))
	var out: Dictionary = {}
	for key in pool.keys():
		var choices = pool[key]
		if choices is Array and choices.size() > 0:
			out[key] = choices[rng.randi() % choices.size()]
	mission_mutation_state[mission_id] = out.duplicate(true)
	return out.duplicate(true)


func clear_mission_mutations(mission_id: String) -> void:
	mission_mutation_state.erase(mission_id)


func register_sterling_clue(clue_id: String, data: Dictionary) -> void:
	var d := data.duplicate(true)
	if not d.has("discovered"):
		d["discovered"] = false
	sterling_clues[clue_id] = d


func discover_sterling_clue(clue_id: String) -> void:
	if not sterling_clues.has(clue_id):
		return
	var d: Dictionary = sterling_clues[clue_id].duplicate(true)
	d["discovered"] = true
	sterling_clues[clue_id] = d
	EventBus.game_state_changed.emit()


func ensure_and_discover_sterling_clue(clue_id: String, data: Dictionary) -> void:
	if not sterling_clues.has(clue_id):
		register_sterling_clue(clue_id, data)
	discover_sterling_clue(clue_id)


func add_poop_bag() -> void:
	poop_bag_count += 1
	if is_in_mission:
		poop_bags_this_mission_attempt += 1
	EventBus.game_state_changed.emit()


func try_consume_poop_bag() -> bool:
	if poop_bag_count <= 0:
		return false
	poop_bag_count -= 1
	EventBus.game_state_changed.emit()
	return true


func get_poop_bag_count() -> int:
	return poop_bag_count


func set_velvet_paw_resume_data(data: Dictionary) -> void:
	velvet_paw_resume_data = data.duplicate(true)

func clear_velvet_paw_resume_data() -> void:
	velvet_paw_resume_data.clear()

func has_velvet_paw_resume_data() -> bool:
	return velvet_paw_resume_data.size() > 0

func take_velvet_paw_resume_data() -> Dictionary:
	var d := velvet_paw_resume_data.duplicate(true)
	velvet_paw_resume_data.clear()
	return d


func _apply_debug_unlock_all_missions_if_enabled() -> void:
	if not debug_unlock_all_missions:
		return
	for mission_id in mission_catalog.keys():
		if not available_missions.has(mission_id):
			available_missions.append(mission_id)


func _ready() -> void:
	reset_for_new_game(false)
	EventBus.debug("GameState ready")

func reset_for_new_game(emit_change = true) -> void:
	available_missions = ["taco_bell_drop"]
	completed_missions = []
	failed_attempts = {}
	unlocked_cards = ["bentley_dental_boy", "fish_treat_focus", "jakes_resident_orders"]
	selected_cards = []
	collected_polaroids = []
	crew_members = ["jake", "bentley"]
	friend_favors = {}
	for friend_id in ["louis", "mere", "jake", "dom", "yordano", "bryce", "jc", "violet", "jinx", "eren", "kiro", "jin", "bentley", "crew"]:
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
	next_spawn = "default"
	evidence_board_data = {}
	equipped_items = []
	velvet_paw_resume_data.clear()
	mission_mutation_state.clear()
	sterling_clues.clear()
	poop_bag_count = 0
	poop_bags_this_mission_attempt = 0
	_apply_debug_unlock_all_missions_if_enabled()
	if emit_change:
		EventBus.game_state_changed.emit()

func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	is_in_mission = true
	player_health = player_max_health
	poop_bags_this_mission_attempt = 0
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
	clear_mission_mutations(mission_id)
	last_mission_result = {"success": true, "mission_id": mission_id, "title": "Clean Getaway", "subtitle": _mission_name(mission_id) + " complete.", "rank": _mission_rank(mission_id), "rewards": rewards}
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
	var attempt_count := int(failed_attempts.get(mission_id, 0)) + 1
	failed_attempts[mission_id] = attempt_count
	intel_points += 1
	var rewards: Array[String] = ["+1 intel point", "Attempt %d logged for the crew board" % attempt_count]
	if attempt_count >= 2 and unlock_card("two_letters_away"):
		rewards.append("Unlocked card: Two Letters Away")
	if attempt_count >= 3 and not bool(dialogue_flags.get("jake_failure_boost", false)):
		dialogue_flags["jake_failure_boost"] = true
		player_max_health += 10
		player_health = player_max_health
		rewards.append("Jake upgrade: +10 max health")
	last_mission_result = {"success": false, "mission_id": mission_id, "title": _failure_title(attempt_count), "subtitle": _failure_subtitle(mission_id, reason), "rewards": rewards}
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
	if has_selected_card("polaroid_proof"):
		intel_points += 1
		rewards.append("Polaroid Proof bonus: +1 intel")
	if mission_id == "diamond_a_year_job" and has_selected_card("diamond_a_year"):
		intel_points += 2
		rewards.append("Diamond a Year bonus: +2 intel")
	if poop_bags_this_mission_attempt >= 3:
		intel_points += 1
		rewards.append("Responsible Crime Lord: +1 intel (3 poop bags this run)")
	return rewards

func _unlock_next_missions(mission_id: String) -> void:
	match mission_id:
		"taco_bell_drop":
			# Starting mission - unlocks two parallel branches
			unlock_mission("clean_job")
			unlock_mission("velvet_paw_jazz_club")
		"clean_job":
			# Jinx's cleaning protocol leads to Mere's story
			unlock_mission("rewrite_room")
		"velvet_paw_jazz_club":
			# Yordano's jazz club leads to Violet's underground
			unlock_mission("arm_wrestling_underground")
		"rewrite_room":
			# Emotional centerpiece - unlocks two branching paths
			unlock_mission("diamond_a_year_job")
			unlock_mission("fast_family_getaway")
		"arm_wrestling_underground":
			# Violet's club supports later confrontations (no new unlocks, crew favor granted)
			pass
		"diamond_a_year_job":
			# Bryce's vault opens path to JC's tea house
			unlock_mission("persian_tea_poison_ink")
		"fast_family_getaway":
			# Dom's chase opens path to Bentley's emotional mission
			unlock_mission("elephant_in_the_room")
		"persian_tea_poison_ink":
			# JC's tea house opens path to shadow arena
			unlock_mission("shadow_solo_contract")
		"elephant_in_the_room":
			# Bentley's emotional mission - check if Sterling Tower unlocks
			_try_unlock_sterling_tower()
		"shadow_solo_contract":
			# Final preparation - check if Sterling Tower unlocks
			_try_unlock_sterling_tower()
		_:
			pass

# Check if all story prerequisites are met for Sterling Tower
func _can_unlock_sterling_tower() -> bool:
	var required_missions := [
		"taco_bell_drop",
		"clean_job",
		"velvet_paw_jazz_club",
		"rewrite_room",
		"fast_family_getaway",
		"diamond_a_year_job",
		"persian_tea_poison_ink",
		"elephant_in_the_room",
		"shadow_solo_contract"
	]
	for req_mission_id in required_missions:
		if not completed_missions.has(req_mission_id):
			return false
	return true

# Attempt to unlock sterling tower if all prerequisites met
func _try_unlock_sterling_tower() -> void:
	if _can_unlock_sterling_tower():
		unlock_mission("sterling_tower_heist")
		EventBus.debug("All evidence gathered. Sterling Tower unlocked.")

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
	var nid := normalize_polaroid_id(polaroid_id)
	if collected_polaroids.has(nid):
		return false
	collected_polaroids.append(nid)
	EventBus.polaroid_collected.emit(nid)
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

func _failure_title(attempt_count: int) -> String:
	var titles: Array[String] = ["The Job Went Sideways", "Not the Cleanest Getaway", "Bentley Refuses to Discuss It", "Back to the Hideout"]
	return titles[(attempt_count - 1) % titles.size()]

func _failure_subtitle(mission_id: String, fallback: String) -> String:
	match mission_id:
		"taco_bell_drop":
			return "Louis still has the route. Bentley still has the scent. The city gave up one more clue."
		"velvet_paw_jazz_club":
			return "The bass cut out, but Yordano heard enough to point toward the next door."
		"rewrite_room":
			return "The paperwork fought back. Mere marked the dangerous language for next time."
		"fast_family_getaway":
			return "The rain won this round. Dom kept the engine warm."
		"sterling_tower_heist":
			return "Sterling thinks friendship is a weakness. The crew is proving him wrong one favor at a time."
		"clean_job":
			return "The showroom stayed smug, but the next fingerprint will not."
		"diamond_a_year_job":
			return "The vault kept its timing. Bryce has notes."
		"arm_wrestling_underground":
			return "The table won this round. Violet says wrists recover faster than pride."
		"persian_tea_poison_ink":
			return "The blend was off. Bentley blames the sweet cup."
		"elephant_in_the_room":
			return "Ellie is still out there. Bentley is not taking questions."
		"shadow_solo_contract":
			return "The shadows held the arena. Kiro and Jin are waiting."
		_:
			return fallback

func _mission_rank(mission_id: String) -> String:
	var attempts := int(failed_attempts.get(mission_id, 0))
	if attempts == 0:
		return "S"
	if attempts == 1:
		return "A"
	if attempts == 2:
		return "B"
	return "C"

func _pretty_id(id: String) -> String:
	var parts := id.split("_")
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)

func to_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"available_missions": available_missions,
		"completed_missions": completed_missions,
		"failed_attempts": failed_attempts,
		"unlocked_cards": unlocked_cards,
		"selected_cards": selected_cards,
		"collected_polaroids": collected_polaroids,
		"crew_members": crew_members,
		"friend_favors": friend_favors,
		"player_upgrades": player_upgrades,
		"bentley_upgrades": bentley_upgrades,
		"dialogue_flags": dialogue_flags,
		"intel_points": intel_points,
		"player_max_health": player_max_health,
		"player_health": player_health,
		"settings": settings,
		"next_spawn": next_spawn,
		"evidence_board_data": evidence_board_data,
		"equipped_items": equipped_items,
		"velvet_paw_resume_data": velvet_paw_resume_data,
		"mission_mutation_state": mission_mutation_state,
		"sterling_clues": sterling_clues,
		"poop_bag_count": poop_bag_count,
	}

func from_dict(data: Dictionary) -> void:
	var loaded_version := String(data.get("save_version", ""))
	if loaded_version == "":
		EventBus.warn("Loading save without version metadata. Save migration may be needed.")
	elif loaded_version != SAVE_VERSION:
		EventBus.debug("Save version mismatch: %s -> %s" % [loaded_version, SAVE_VERSION])
	
	available_missions = _as_string_array(data.get("available_missions", available_missions))
	completed_missions = _as_string_array(data.get("completed_missions", []))
	failed_attempts = Dictionary(data.get("failed_attempts", {}))
	unlocked_cards = _as_string_array(data.get("unlocked_cards", unlocked_cards))
	selected_cards = _as_string_array(data.get("selected_cards", []))
	collected_polaroids = _as_string_array(data.get("collected_polaroids", []))
	_migrate_polaroid_ids_inplace()
	crew_members = _as_string_array(data.get("crew_members", crew_members))
	friend_favors = Dictionary(data.get("friend_favors", friend_favors))
	player_upgrades = Dictionary(data.get("player_upgrades", {}))
	bentley_upgrades = Dictionary(data.get("bentley_upgrades", {}))
	dialogue_flags = Dictionary(data.get("dialogue_flags", {}))
	intel_points = int(data.get("intel_points", 0))
	player_max_health = int(data.get("player_max_health", 100))
	player_health = int(data.get("player_health", player_max_health))
	settings = Dictionary(data.get("settings", settings))
	next_spawn = String(data.get("next_spawn", "default"))
	evidence_board_data = Dictionary(data.get("evidence_board_data", {}))
	equipped_items = _as_string_array(data.get("equipped_items", []))
	velvet_paw_resume_data = Dictionary(data.get("velvet_paw_resume_data", {}))
	mission_mutation_state = Dictionary(data.get("mission_mutation_state", {}))
	sterling_clues = Dictionary(data.get("sterling_clues", {}))
	poop_bag_count = int(data.get("poop_bag_count", 0))
	is_in_mission = false
	current_mission_id = ""
	pending_mission_id = ""
	
	_validate_and_fix_mission_unlocks()
	EventBus.game_state_changed.emit()

func _validate_and_fix_mission_unlocks() -> void:
	var missing_unlocks: Array[String] = []
	var original_available := available_missions.duplicate()
	
	for mission_id in completed_missions:
		_unlock_next_missions(mission_id)
	
	_try_unlock_sterling_tower()
	
	for mission_id in available_missions:
		if not original_available.has(mission_id):
			missing_unlocks.append(mission_id)
	
	if missing_unlocks.size() > 0:
		EventBus.debug("Save validation: restored %d missing mission unlocks" % missing_unlocks.size())
		for mission_id in missing_unlocks:
			EventBus.debug("  - %s is now available" % mission_id)

func _as_string_array(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out
