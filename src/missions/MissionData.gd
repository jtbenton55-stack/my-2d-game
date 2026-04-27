# MissionData.gd
# Static mission data definitions for Untitled Heist RPG

class_name MissionData

# Mission definitions
const MISSIONS = {
	"taco_bell_drop": {
		"name": "The Taco Bell Drop",
		"desc": "Help Louis recover his delivery bag",
		"scene": "res://scenes/missions/TacoBellMission.tscn",
		"unlocks": "velvet_paw_jazz_club",
		"friend": "louis",
		"reward_card": "louis_delivery_route",
		"reward_polaroid": "taco_bell",
		"hint_card": "bentley_dental_boy",
		"intel_reward": 25,
		"difficulty": 1
	},
	"velvet_paw_jazz_club": {
		"name": "The Velvet Paw Jazz Club",
		"desc": "Steal the Sterling blackmail ledger",
		"scene": "res://scenes/missions/JazzClubMission.tscn",
		"unlocks": "rewrite_room",
		"friend": "yordano",
		"reward_card": "yordano_bass_drop",
		"reward_polaroid": "jazz_club",
		"hint_card": "mere_legal_eyes",
		"intel_reward": 35,
		"difficulty": 2
	},
	"rewrite_room": {
		"name": "The Rewrite Room",
		"desc": "Recover stolen screenplay documents",
		"scene": "res://scenes/missions/RewriteRoomMission.tscn",
		"unlocks": "fast_family_getaway",
		"friend": "mere",
		"reward_card": "stationery_queen",
		"reward_polaroid": "rewrite_room",
		"hint_card": "doms_getaway_keys",
		"intel_reward": 40,
		"difficulty": 3
	},
	"fast_family_getaway": {
		"name": "The Fast Family Getaway",
		"desc": "Help Dom escape with evidence",
		"scene": "res://scenes/missions/CarChaseMission.tscn",
		"unlocks": "sterling_tower_heist",
		"friend": "dom",
		"reward_card": "doms_getaway_keys",
		"reward_polaroid": "car_chase",
		"hint_card": "jakes_resident_orders",
		"intel_reward": 45,
		"difficulty": 3
	},
	"sterling_tower_heist": {
		"name": "The Sterling Tower Heist",
		"desc": "The final job. Take down Victor Sterling.",
		"scene": "res://scenes/missions/SterlingTowerMission.tscn",
		"unlocks": "",
		"friend": "",  # All friends help in final mission
		"reward_card": "",
		"reward_polaroid": "sterling_tower",
		"hint_card": "",
		"intel_reward": 100,
		"difficulty": 5
	}
}

# Friend-to-mission mapping
const FRIEND_MISSIONS = {
	"louis": "taco_bell_drop",
	"yordano": "velvet_paw_jazz_club",
	"mere": "rewrite_room",
	"dom": "fast_family_getaway"
}

# Mission order for progression
const MISSION_ORDER = [
	"taco_bell_drop",
	"velvet_paw_jazz_club",
	"rewrite_room",
	"fast_family_getaway",
	"sterling_tower_heist"
]

static func get_mission(mission_id: String) -> Dictionary:
	"""Get mission data by ID"""
	return MISSIONS.get(mission_id, {})

static func get_mission_name(mission_id: String) -> String:
	"""Get mission name by ID"""
	return MISSIONS.get(mission_id, {}).get("name", "Unknown Mission")

static func get_mission_description(mission_id: String) -> String:
	"""Get mission description by ID"""
	return MISSIONS.get(mission_id, {}).get("desc", "")

static func get_mission_scene(mission_id: String) -> String:
	"""Get mission scene path by ID"""
	return MISSIONS.get(mission_id, {}).get("scene", "")

static func get_next_mission(mission_id: String) -> String:
	"""Get next mission ID in progression"""
	var mission = get_mission(mission_id)
	return mission.get("unlocks", "")

static func get_friend_for_mission(mission_id: String) -> String:
	"""Get friend ID associated with mission"""
	return MISSIONS.get(mission_id, {}).get("friend", "")

static func get_mission_for_friend(friend_id: String) -> String:
	"""Get mission ID associated with friend"""
	return FRIEND_MISSIONS.get(friend_id, "")

static func get_reward_card(mission_id: String) -> String:
	"""Get card unlocked by completing mission"""
	return MISSIONS.get(mission_id, {}).get("reward_card", "")

static func get_reward_polaroid(mission_id: String) -> String:
	"""Get Polaroid earned by completing mission"""
	return MISSIONS.get(mission_id, {}).get("reward_polaroid", "")

static func get_hint_card(mission_id: String) -> String:
	"""Get card unlocked after 3 failures"""
	return MISSIONS.get(mission_id, {}).get("hint_card", "")

static func get_intel_reward(mission_id: String) -> int:
	"""Get intel points reward for mission"""
	return MISSIONS.get(mission_id, {}).get("intel_reward", 0)

static func get_difficulty(mission_id: String) -> int:
	"""Get mission difficulty (1-5)"""
	return MISSIONS.get(mission_id, {}).get("difficulty", 1)

static func get_all_missions() -> Array[String]:
	"""Get all mission IDs"""
	return MISSIONS.keys()

static func get_available_missions(completed: Array[String]) -> Array[String]:
	"""Get missions available based on completed missions"""
	var available = []
	
	# First mission is always available
	if "taco_bell_drop" not in completed:
		available.append("taco_bell_drop")
		return available
	
	# Check each mission in order
	for mission_id in MISSION_ORDER:
		# If mission is completed, check if it unlocks next
		if mission_id in completed:
			var next_mission = get_next_mission(mission_id)
			if next_mission != "" and next_mission not in completed:
				available.append(next_mission)
		# If mission is not completed and previous mission is completed, it's available
		elif mission_id != "taco_bell_drop":
			var prev_index = MISSION_ORDER.find(mission_id) - 1
			if prev_index >= 0:
				var prev_mission = MISSION_ORDER[prev_index]
				if prev_mission in completed:
					available.append(mission_id)
	
	return available

static func is_final_mission(mission_id: String) -> bool:
	"""Check if mission is the final mission"""
	return mission_id == "sterling_tower_heist"