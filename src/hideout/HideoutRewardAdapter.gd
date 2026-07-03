class_name HideoutRewardAdapter
extends RefCounted

const TACO_BELL_MISSION_ID := "taco_bell_drop"

const POLAROID_DISPLAY_KEYS := {
	"taco_bell_polaroid": "polaroid_taco_bell",
}

const TYPED_COLLECTIBLE_DISPLAY_KEYS := {
	"taco_bell_glow_guy": "glow_guy_taco_bell",
	"taco_bell_glow_guys": "glow_guy_taco_bell",
	"taco_bell_tiny_icon_sauce_packet": "tiny_icon_sauce_packet",
	"taco_bell_tiny_icon_drive_thru_bell": "tiny_icon_drive_thru_bell",
	"taco_bell_poop_bag_fire_sauce_roll": "poop_bag_fire_sauce_roll",
}

const TACO_BELL_STORE_UNLOCKS := [
	"taco_bell_stool",
	"employees_must_wash_paws_sign",
	"sauce_packet_rug",
	"neon_menu_panel",
	"mild_sauce_throw_pillow",
	"drive_thru_headset",
	"security_booth_monitor",
	"suspicious_fry_basket",
]


static func build_contract(mission_id: String) -> Dictionary:
	var clean_id := mission_id.strip_edges()
	var info: Dictionary = GameState.get_mission_info(clean_id) if GameState.has_method("get_mission_info") else {}
	var completed := GameState.has_completed(clean_id) if GameState.has_method("has_completed") else GameState.completed_missions.has(clean_id)
	var contract := {
		"mission_id": clean_id,
		"completed": completed,
		"mission_name": String(info.get("name", clean_id)),
		"scheme_cards": _string_array(info.get("reward_cards", [])),
		"polaroids": _string_array(info.get("reward_polaroids", [])),
		"crew_friend": String(info.get("friend", "")),
		"collectible_displays": [],
		"store_unlocks": [],
		"care_unlocks": [],
		"case_cash_floor": 0,
		"cozy_lines": [],
	}
	if clean_id == TACO_BELL_MISSION_ID:
		contract["store_unlocks"] = TACO_BELL_STORE_UNLOCKS.duplicate()
		contract["care_unlocks"] = ["sauce_paw_cleanup_available"]
		contract["case_cash_floor"] = 150
		contract["cozy_lines"] = [
			"Louis can now appear in the hideout after the Taco Bell Drop.",
			"Taco Bell decor cards are available through the Store Terminal.",
			"Bentley's sauce-paw cleanup station is available.",
		]
		(contract["collectible_displays"] as Array).append("trophy_taco_bell_drop")
	for polaroid_id in contract.get("polaroids", []):
		var display_id := _display_id_for_polaroid(String(polaroid_id))
		if display_id != "":
			_add_unique(contract["collectible_displays"], display_id)
	for collectible_id in GameState.typed_collectibles.keys():
		var record: Dictionary = GameState.typed_collectibles.get(collectible_id, {})
		if String(record.get("mission_id", clean_id)) != clean_id:
			continue
		var display_key := String(record.get("hideout_display_key", ""))
		if display_key == "":
			display_key = String(TYPED_COLLECTIBLE_DISPLAY_KEYS.get(String(collectible_id), ""))
		if display_key != "":
			_add_unique(contract["collectible_displays"], display_key)
	return contract


static func apply_completed_mission_rewards_to_state(state: Node, mission_id: String) -> Dictionary:
	if state == null:
		return _result(false, "state_missing", "Hideout state controller is missing.")
	var contract := build_contract(mission_id)
	if not bool(contract.get("completed", false)):
		return _result(true, "mission_not_completed", "Mission has not been completed; no hideout reward state applied.", {"mission_id": mission_id})
	if not state.has_method("apply_mission_reward_contract"):
		return _result(false, "state_contract_missing", "Hideout state controller cannot apply reward contracts.", {"mission_id": mission_id})
	var applied: Dictionary = state.call("apply_mission_reward_contract", contract)
	return _result(true, "hideout_rewards_applied", "Hideout reward state applied.", {"mission_id": mission_id, "contract": contract, "applied": applied})


static func apply_all_completed_rewards_to_state(state: Node) -> Dictionary:
	if state == null:
		return _result(false, "state_missing", "Hideout state controller is missing.")
	var applied: Array = []
	for mission_id in GameState.completed_missions:
		var result := apply_completed_mission_rewards_to_state(state, String(mission_id))
		applied.append(result)
	return _result(true, "completed_rewards_synced", "Completed mission hideout rewards synced.", {"applied": applied})


static func _display_id_for_polaroid(polaroid_id: String) -> String:
	var normalized := GameState.normalize_polaroid_id(polaroid_id) if GameState.has_method("normalize_polaroid_id") else polaroid_id
	return String(POLAROID_DISPLAY_KEYS.get(normalized, ""))


static func _add_unique(target: Array, value: String) -> void:
	if value == "" or target.has(value):
		return
	target.append(value)


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(String(item))
	return out


static func _result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": "HideoutRewardAdapter",
		"details": details,
	}
