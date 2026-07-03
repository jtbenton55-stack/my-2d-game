extends Node

const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const EncounterResultAdapterScript := preload("res://src/missions/iso/encounters/EncounterResultAdapter.gd")
const ReactiveNpcResultAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcResultAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")

const SAVE_VERSION := "0.4.0-bible"
const MAX_SELECTED_CARDS := 3
const TACO_SUCCESS_STERLING_CLUE_ID := "taco_bell_sterling_route_invoice"

var mission_catalog: Dictionary = {
	"iso_vertical_slice": {"name": "Iso Vertical Slice (Dev)", "description": "Internal isometric TileMapLayer prototype. Not part of story progression.", "scene_path": "res://scenes/dev/IsoVerticalSlice.tscn", "reward_cards": [], "reward_polaroids": [], "friend": ""},
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
var current_scheme_loadout: Dictionary = {"plan": "", "trick": "", "comfort_chaos": ""}
var is_in_mission: bool = false
var last_mission_result: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO
var next_spawn: String = "default"
var evidence_board_data: Dictionary = {}
var equipped_items: Array[String] = []

## Serialized when leaving JazzClubMission for the owner-suite boss arena; reapplied on return.
var velvet_paw_resume_data: Dictionary = {}

## Velvet Paw Jazz Club — multi-floor run state (basement + Phase 4 hostile / stealth).
var velvet_paw_club_hostile: bool = false
var velvet_paw_basement_shard_collected: bool = false
var velvet_paw_basement_keycard_collected: bool = false
var velvet_paw_stealth_run_broken: bool = false

## Mission Bible: heat is derived from failed_attempts (capped); mutations are rolled per mission and saved.
var mission_mutation_state: Dictionary = {}

## Structured Sterling clues for evidence board import; id -> {title, description, category, mission_id, connects_to, unlocks_or_modifies, discovered}
var sterling_clues: Dictionary = {}
## Typed clue board records (additive to sterling_clues for backward compatibility).
var evidence_clues: Dictionary = {}

## Mission rewards/loadout style cards with richer metadata (unlocked_cards remains canonical for old systems).
var unlocked_scheme_cards: Dictionary = {}

## Typed collectible records used by iso placeholder missions.
var typed_collectibles: Dictionary = {}

## Lightweight crew assist unlock records for route and hint checks.
var crew_assists: Dictionary = {}

## Mission heat snapshots for deterministic restart mutations.
var mission_heat_states: Dictionary = {}

## Mission runtime performance snapshots for mastery/replay hooks.
var mission_performance: Dictionary = {}

## Per-mission alert/suspicion state snapshots (normal/suspicious/alerted/resolved).
var mission_alert_states: Dictionary = {}

## Bentley poop bags — global inventory + per-attempt pickup count for Responsible Crime Lord bonus.
var poop_bag_count: int = 0
var poop_bags_this_mission_attempt: int = 0
var poop_bag_inventory: Dictionary = {"count": 0, "collected_this_mission": 0, "used_this_mission": 0}

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


func _as_bool_data(value: Variant) -> bool:
	if value == null:
		return false
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return absf(float(value)) > 0.00001
		TYPE_STRING:
			var text := String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes" or text == "y"
		_:
			return false


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


## Read-only summary for pause/F10; does not mutate save data.
func get_mission_heat_summary(mission_id: String) -> Dictionary:
	return {
		"mission_id": mission_id,
		"heat": get_mission_heat(mission_id),
		"failed_attempts": int(failed_attempts.get(mission_id, 0)),
		"max_heat": 5,
	}


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


func clear_mission_flags(mission_id: String) -> void:
	if mission_id.strip_edges() == "":
		return
	var prefix := "mission_flag:%s:" % mission_id
	for key in dialogue_flags.keys():
		if String(key).begins_with(prefix):
			dialogue_flags.erase(key)


func register_sterling_clue(clue_id: String, data: Dictionary) -> void:
	var d := data.duplicate(true)
	if not d.has("discovered"):
		d["discovered"] = false
	sterling_clues[clue_id] = d
	record_evidence_clue(clue_id, d)


func discover_sterling_clue(clue_id: String) -> void:
	if not sterling_clues.has(clue_id):
		return
	var d: Dictionary = sterling_clues[clue_id].duplicate(true)
	d["discovered"] = true
	sterling_clues[clue_id] = d
	record_evidence_clue(clue_id, d)
	EventBus.game_state_changed.emit()


func ensure_and_discover_sterling_clue(clue_id: String, data: Dictionary) -> void:
	if not sterling_clues.has(clue_id):
		register_sterling_clue(clue_id, data)
	discover_sterling_clue(clue_id)


func add_poop_bag() -> void:
	poop_bag_count += 1
	poop_bag_inventory["count"] = poop_bag_count
	poop_bag_inventory["collected_this_mission"] = int(poop_bag_inventory.get("collected_this_mission", 0)) + 1
	if is_in_mission:
		poop_bags_this_mission_attempt += 1
	EventBus.game_state_changed.emit()


func try_consume_poop_bag() -> bool:
	if poop_bag_count <= 0:
		return false
	poop_bag_count -= 1
	poop_bag_inventory["count"] = poop_bag_count
	poop_bag_inventory["used_this_mission"] = int(poop_bag_inventory.get("used_this_mission", 0)) + 1
	EventBus.game_state_changed.emit()
	return true


func get_poop_bag_count() -> int:
	return poop_bag_count


func get_poop_bag_bonus_status(mission_id: String = "") -> Dictionary:
	var target := 3
	var collected := poop_bags_this_mission_attempt
	var used := int(poop_bag_inventory.get("used_this_mission", 0))
	var status := "complete" if collected >= target else "pending"
	var line := "Bentley poop-bag bonus: %d/%d found" % [mini(collected, target), target]
	if used > 0:
		line += " (%d used)" % used
	if status == "complete":
		line += " - bonus secured."
	else:
		line += " - find all three before leaving."
	return {
		"mission_id": mission_id,
		"current_count": poop_bag_count,
		"collected_this_attempt": collected,
		"used_this_attempt": used,
		"target": target,
		"status": status,
		"complete": collected >= target,
		"line": line,
	}


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
	velvet_paw_club_hostile = false
	velvet_paw_basement_shard_collected = false
	velvet_paw_basement_keycard_collected = false
	velvet_paw_stealth_run_broken = false
	mission_mutation_state.clear()
	sterling_clues.clear()
	evidence_clues.clear()
	unlocked_scheme_cards.clear()
	typed_collectibles.clear()
	crew_assists.clear()
	mission_heat_states.clear()
	mission_performance.clear()
	mission_alert_states.clear()
	PaperTrailAdapterScript.clear_all()
	SocialStealthAdapterScript.clear_all()
	ReactiveNpcBrainAdapterScript.clear_all()
	MissionInventoryScript.clear_all()
	poop_bag_count = 0
	poop_bags_this_mission_attempt = 0
	poop_bag_inventory = {"count": 0, "collected_this_mission": 0, "used_this_mission": 0}
	_apply_debug_unlock_all_missions_if_enabled()
	if emit_change:
		EventBus.game_state_changed.emit()

func start_mission(mission_id: String) -> void:
	current_mission_id = mission_id
	is_in_mission = true
	clear_mission_flags(mission_id)
	PaperTrailAdapterScript.reset_mission(mission_id)
	SocialStealthAdapterScript.reset_mission(mission_id)
	ReactiveNpcBrainAdapterScript.reset_mission(mission_id)
	MissionInventoryScript.clear_mission_items()
	player_health = player_max_health
	poop_bags_this_mission_attempt = 0
	poop_bag_inventory["collected_this_mission"] = 0
	poop_bag_inventory["used_this_mission"] = 0
	dialogue_flags.erase("dental_boy_used")
	begin_mission_performance(mission_id)
	EventBus.mission_started.emit(mission_id)
	EventBus.debug("Mission started: " + mission_id)
	EventBus.game_state_changed.emit()

func set_current_scheme_loadout(loadout_dict: Dictionary) -> void:
	current_scheme_loadout = {
		"plan": String(loadout_dict.get("plan", "")),
		"trick": String(loadout_dict.get("trick", "")),
		"comfort_chaos": String(loadout_dict.get("comfort_chaos", "")),
	}
	EventBus.game_state_changed.emit()

func get_current_scheme_loadout() -> Dictionary:
	return current_scheme_loadout.duplicate(true)

func complete_mission(mission_id = "") -> Dictionary:
	if mission_id == "":
		mission_id = current_mission_id
	if mission_id == "":
		mission_id = "test_mission"
	is_in_mission = false
	current_mission_id = ""
	MissionInventoryScript.clear_mission_items()
	if mission_id == "velvet_paw_jazz_club":
		velvet_paw_club_hostile = false
		velvet_paw_basement_shard_collected = false
		velvet_paw_basement_keycard_collected = false
		velvet_paw_stealth_run_broken = false
	if not completed_missions.has(mission_id):
		completed_missions.append(mission_id)
	_finalize_mission_performance(mission_id, true)
	var rewards := _grant_success_rewards(mission_id)
	clear_mission_mutations(mission_id)
	var result_payload := {"success": true, "mission_id": mission_id, "title": "Clean Getaway", "subtitle": _mission_name(mission_id) + " complete.", "rank": _mission_rank(mission_id), "rewards": rewards}
	_annotate_player_facing_mission_result(result_payload, mission_id, true)
	last_mission_result = ReactiveNpcResultAdapterScript.annotate_mission_result(EncounterResultAdapterScript.annotate_mission_result(SocialStealthAdapterScript.annotate_mission_result(PaperTrailAdapterScript.annotate_mission_result(result_payload))))
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
	MissionInventoryScript.clear_mission_items()
	if mission_id == "velvet_paw_jazz_club":
		velvet_paw_club_hostile = false
		velvet_paw_basement_shard_collected = false
		velvet_paw_basement_keycard_collected = false
		velvet_paw_stealth_run_broken = false
	var attempt_count := int(failed_attempts.get(mission_id, 0)) + 1
	failed_attempts[mission_id] = attempt_count
	_log_security_mission_failure_heat(mission_id, attempt_count)
	_update_mission_heat_state(mission_id)
	_finalize_mission_performance(mission_id, false)
	intel_points += 1
	var rewards: Array[String] = ["+1 intel point", "Attempt %d logged for the crew board" % attempt_count]
	if attempt_count >= 2 and unlock_card("two_letters_away"):
		rewards.append("Unlocked card: Two Letters Away")
	if attempt_count >= 3 and not _as_bool_data(dialogue_flags.get("jake_failure_boost", false)):
		dialogue_flags["jake_failure_boost"] = true
		player_max_health += 10
		player_health = player_max_health
		rewards.append("Jake upgrade: +10 max health")
	var result_payload := {"success": false, "mission_id": mission_id, "title": _failure_title(attempt_count), "subtitle": _failure_subtitle(mission_id, reason), "rewards": rewards}
	_annotate_player_facing_mission_result(result_payload, mission_id, false)
	last_mission_result = ReactiveNpcResultAdapterScript.annotate_mission_result(EncounterResultAdapterScript.annotate_mission_result(SocialStealthAdapterScript.annotate_mission_result(PaperTrailAdapterScript.annotate_mission_result(result_payload))))
	EventBus.mission_failed.emit(mission_id, reason)
	EventBus.mission_result_ready.emit(last_mission_result)
	EventBus.game_state_changed.emit()
	return last_mission_result


func _log_security_mission_failure_heat(mission_id: String, failed_after: int) -> void:
	var ml := Engine.get_main_loop()
	if ml == null or not (ml is SceneTree):
		return
	var st := ml as SceneTree
	var ctrl := st.get_first_node_in_group("iso_alert_controller")
	if ctrl == null or not ctrl.has_method("get_security_event_adapter"):
		return
	var adapter: Variant = ctrl.call("get_security_event_adapter")
	if adapter != null and adapter.has_method("report_security_event"):
		adapter.call(
			"report_security_event",
			"mission_failure_heat",
			mission_id,
			4,
			{"failed_attempts_after": failed_after}
		)


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
	if mission_id == "taco_bell_drop":
		unlock_crew_assist("louis_delivery_route_assist", {
			"friend_name": "louis",
			"unlocked_by_mission": "taco_bell_drop",
			"effect_type": "delivery_route_access",
			"usable_in_missions": ["jazz_club", "rewrite_room", "sterling_tower_heist"],
			"cooldown_or_once_per_mission": "once_per_mission",
		})
	return rewards


func _annotate_player_facing_mission_result(result: Dictionary, mission_id: String, success: bool) -> void:
	result["mission_name"] = _mission_name(mission_id)
	result["return_destination"] = "Hideout"
	result["continue_label"] = "Return to Hideout"
	result["poop_bag_status"] = get_poop_bag_bonus_status(mission_id)
	if mission_id != "taco_bell_drop":
		return
	var next_steps: Array[String] = []
	if success:
		var clue := _ensure_taco_success_sterling_clue()
		result["evidence_clues"] = [clue]
		next_steps.append("Check the Evidence Board in the hideout for Louis's Sterling lead.")
		next_steps.append("The Clean Job and Velvet Paw routes are now available from the mission board.")
		var rewards: Array = Array(result.get("rewards", []))
		var clue_reward := "Evidence clue: " + String(clue.get("title", "Louis's Sterling lead"))
		if not rewards.has(clue_reward):
			rewards.append(clue_reward)
		result["rewards"] = rewards
	else:
		next_steps.append("Regroup at the hideout, then retry the Taco Bell drop with the route intel intact.")
	result["next_steps"] = next_steps


func _ensure_taco_success_sterling_clue() -> Dictionary:
	var was_discovered := sterling_clues.has(TACO_SUCCESS_STERLING_CLUE_ID) and _as_bool_data(sterling_clues[TACO_SUCCESS_STERLING_CLUE_ID].get("discovered", false))
	var clue_data := {
		"title": "Louis's Sterling Route Invoice",
		"description": "The recovered delivery bag points from Louis's route to a Sterling-controlled luxury showroom.",
		"category": "Sterling Clue",
		"mission_id": "taco_bell_drop",
		"connects_to": "Clean Job",
		"unlocks_or_modifies": "Unlocks the showroom cleanup lead and starts the Sterling evidence chain.",
		"final_tower_relevance": "First route-link tying Sterling to the crew's case.",
	}
	ensure_and_discover_sterling_clue(TACO_SUCCESS_STERLING_CLUE_ID, clue_data)
	var record: Dictionary = sterling_clues.get(TACO_SUCCESS_STERLING_CLUE_ID, clue_data).duplicate(true)
	record["clue_id"] = TACO_SUCCESS_STERLING_CLUE_ID
	record["was_new"] = not was_discovered
	return record

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
	unlock_scheme_card(card_id, {"display_name": _pretty_id(card_id), "effect_type": "legacy_card"})
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
		"velvet_paw_club_hostile": velvet_paw_club_hostile,
		"velvet_paw_basement_shard_collected": velvet_paw_basement_shard_collected,
		"velvet_paw_basement_keycard_collected": velvet_paw_basement_keycard_collected,
		"velvet_paw_stealth_run_broken": velvet_paw_stealth_run_broken,
		"mission_mutation_state": mission_mutation_state,
		"sterling_clues": sterling_clues,
		"evidence_clues": evidence_clues,
		"unlocked_scheme_cards": unlocked_scheme_cards,
		"typed_collectibles": typed_collectibles,
		"crew_assists": crew_assists,
		"mission_heat_states": mission_heat_states,
		"mission_performance": mission_performance,
		"mission_alert_states": mission_alert_states,
		"poop_bag_count": poop_bag_count,
		"poop_bag_inventory": poop_bag_inventory,
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
	velvet_paw_club_hostile = _as_bool_data(data.get("velvet_paw_club_hostile", false))
	velvet_paw_basement_shard_collected = _as_bool_data(data.get("velvet_paw_basement_shard_collected", false))
	velvet_paw_basement_keycard_collected = _as_bool_data(data.get("velvet_paw_basement_keycard_collected", false))
	velvet_paw_stealth_run_broken = _as_bool_data(data.get("velvet_paw_stealth_run_broken", false))
	mission_mutation_state = Dictionary(data.get("mission_mutation_state", {}))
	sterling_clues = Dictionary(data.get("sterling_clues", {}))
	evidence_clues = Dictionary(data.get("evidence_clues", {}))
	unlocked_scheme_cards = Dictionary(data.get("unlocked_scheme_cards", {}))
	typed_collectibles = Dictionary(data.get("typed_collectibles", {}))
	crew_assists = Dictionary(data.get("crew_assists", {}))
	mission_heat_states = Dictionary(data.get("mission_heat_states", {}))
	mission_performance = Dictionary(data.get("mission_performance", {}))
	mission_alert_states = Dictionary(data.get("mission_alert_states", {}))
	poop_bag_count = int(data.get("poop_bag_count", 0))
	poop_bag_inventory = Dictionary(data.get("poop_bag_inventory", {"count": poop_bag_count, "collected_this_mission": 0, "used_this_mission": 0}))
	if not poop_bag_inventory.has("count"):
		poop_bag_inventory["count"] = poop_bag_count
	else:
		poop_bag_count = int(poop_bag_inventory.get("count", poop_bag_count))
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


func unlock_scheme_card(card_id: String, data: Dictionary = {}) -> bool:
	if card_id == "":
		return false
	var record: Dictionary = unlocked_scheme_cards.get(card_id, {
		"card_id": card_id,
		"display_name": _pretty_id(card_id),
		"description": "",
		"unlocked_by_mission": "",
		"effect_type": "boolean",
		"effect_data": {},
		"is_unlocked": true,
		"is_equipped": false,
	})
	for key in data.keys():
		record[key] = data[key]
	record["is_unlocked"] = true
	unlocked_scheme_cards[card_id] = record
	if not unlocked_cards.has(card_id):
		unlocked_cards.append(card_id)
	return true


func has_scheme_card(card_id: String) -> bool:
	return unlocked_cards.has(card_id) or _as_bool_data(unlocked_scheme_cards.get(card_id, {}).get("is_unlocked", false))


func record_evidence_clue(clue_id: String, data: Dictionary) -> void:
	if clue_id == "":
		return
	var record: Dictionary = evidence_clues.get(clue_id, {
		"clue_id": clue_id,
		"display_name": data.get("title", _pretty_id(clue_id)),
		"short_name": data.get("title", _pretty_id(clue_id)),
		"description": data.get("description", ""),
		"category": data.get("category", "Mission Bible"),
		"found_in_mission": data.get("mission_id", ""),
		"clue_board_cluster": data.get("connects_to", "Sterling Tower"),
		"connects_to": data.get("connects_to", ""),
		"unlocks_or_modifies": data.get("unlocks_or_modifies", ""),
		"final_tower_relevance": data.get("final_tower_relevance", ""),
		"is_required_for_mission_completion": true,
		"discovered": false,
	})
	for key in data.keys():
		record[key] = data[key]
	if data.has("title"):
		record["display_name"] = data["title"]
		record["short_name"] = data["title"]
	evidence_clues[clue_id] = record


func has_evidence_clue(clue_id: String) -> bool:
	return evidence_clues.has(clue_id) or sterling_clues.has(clue_id)


func record_typed_collectible(collectible_id: String, collectible_type: String, data: Dictionary = {}) -> void:
	if collectible_id == "":
		return
	var record: Dictionary = typed_collectibles.get(collectible_id, {
		"collectible_id": collectible_id,
		"type": collectible_type,
		"mission_id": data.get("mission_id", current_mission_id),
		"display_name": data.get("display_name", _pretty_id(collectible_id)),
		"description": data.get("description", ""),
		"hidden": _as_bool_data(data.get("hidden", false)),
		"reward_effect": data.get("reward_effect", ""),
		"collection_group": data.get("collection_group", collectible_type),
		"found_state": "found",
	})
	for key in data.keys():
		record[key] = data[key]
	record["type"] = collectible_type
	record["found_state"] = "found"
	typed_collectibles[collectible_id] = record


func unlock_crew_assist(assist_id: String, data: Dictionary = {}) -> void:
	if assist_id == "":
		return
	var record: Dictionary = crew_assists.get(assist_id, {
		"assist_id": assist_id,
		"friend_name": data.get("friend_name", "crew"),
		"unlocked_by_mission": data.get("unlocked_by_mission", ""),
		"effect_type": data.get("effect_type", "route_access"),
		"usable_in_missions": data.get("usable_in_missions", []),
		"cooldown_or_once_per_mission": data.get("cooldown_or_once_per_mission", "once_per_mission"),
		"is_unlocked": true,
	})
	for key in data.keys():
		record[key] = data[key]
	record["is_unlocked"] = true
	crew_assists[assist_id] = record


func has_crew_assist(assist_id: String) -> bool:
	return _as_bool_data(crew_assists.get(assist_id, {}).get("is_unlocked", false))


func set_mission_alert_state(mission_id: String, state: String) -> void:
	if mission_id == "":
		return
	mission_alert_states[mission_id] = {
		"state": state,
		"updated_at": Time.get_unix_time_from_system(),
	}


func get_mission_alert_state(mission_id: String) -> String:
	if mission_id == "":
		return "normal"
	return String(mission_alert_states.get(mission_id, {}).get("state", "normal"))


func begin_mission_performance(mission_id: String) -> void:
	if mission_id == "":
		return
	mission_performance[mission_id] = {
		"mission_id": mission_id,
		"started_at": Time.get_unix_time_from_system(),
		"completed_at": 0,
		"alarms_triggered": 0,
		"cameras_triggered": 0,
		"guards_alerted": 0,
		"wrong_scent_trails_followed": 0,
		"wrong_code_attempts": 0,
		"damage_taken": 0,
		"poop_bags_collected": 0,
		"collectibles_found": 0,
		"optional_objectives_completed": 0,
		"combat_style_event_completed": false,
		"mission_time": 0.0,
		"perfect_moment_earned": false,
	}


func record_mission_performance_event(mission_id: String, key: String, delta: int = 1) -> void:
	if mission_id == "":
		return
	if not mission_performance.has(mission_id):
		begin_mission_performance(mission_id)
	var record: Dictionary = mission_performance[mission_id]
	record[key] = int(record.get(key, 0)) + delta
	mission_performance[mission_id] = record


func _finalize_mission_performance(mission_id: String, success: bool) -> void:
	if mission_id == "":
		return
	if not mission_performance.has(mission_id):
		return
	var record: Dictionary = mission_performance[mission_id]
	var now := Time.get_unix_time_from_system()
	record["completed_at"] = now
	record["mission_time"] = maxf(0.0, float(now) - float(record.get("started_at", now)))
	record["poop_bags_collected"] = poop_bags_this_mission_attempt
	record["perfect_moment_earned"] = success and int(record.get("alarms_triggered", 0)) == 0 and int(record.get("wrong_scent_trails_followed", 0)) == 0
	mission_performance[mission_id] = record


func _update_mission_heat_state(mission_id: String) -> void:
	if mission_id == "":
		return
	var failed := int(failed_attempts.get(mission_id, 0))
	mission_heat_states[mission_id] = {
		"mission_id": mission_id,
		"failed_attempts": failed,
		"heat_level": mini(5, failed),
		"selected_mutations": mission_mutation_state.get(mission_id, {}),
		"active_extra_guards": failed >= 2,
		"active_camera_state": "high_heat" if failed >= 2 else "normal",
		"moved_collectible_variant": String(mission_mutation_state.get(mission_id, {}).get("hidden_collectible_slot", "")),
		"friend_hint_level": mini(3, failed),
	}
