extends Node
class_name HideoutStateController

const HEAT_LOW := "low"
const HEAT_MEDIUM := "medium"
const HEAT_HIGH := "high"

var taco_bell_available := true
var taco_bell_completed := false
var taco_bell_perfect := false
var taco_bell_missing_items := false
var taco_bell_heat := 0
var taco_bell_lower_heat_available := false

var clue_sauce_packet_found := false
var clue_route_manifest_found := false
var clue_velvet_paw_stamp_found := false
var clue_delivery_token_found := false
var clue_security_memo_found := false
var clue_connections_reviewed := false

var polaroid_taco_bell_found := false
var glow_guy_taco_bell_found := false
var tiny_icon_sauce_packet_found := false
var tiny_icon_drive_thru_bell_found := false
var poop_bag_fire_sauce_roll_found := false
var trophy_taco_bell_found := false

var unlocked_scheme_cards: Array[String] = []
var equipped_plan_card := ""
var equipped_trick_card := ""
var equipped_comfort_chaos_card := ""

var bentley_wiped := false
var bentley_brushed := false
var treat_packed := false
var poop_bags_stocked := false
var sauce_paw_cleanup_available := false
var bentley_mood := "curious"

var available_store_items: Array[String] = []
var purchased_store_items: Array[String] = []
var delivered_store_items: Array[String] = []
var currency_debug_amount := 150

var louis_unlocked := false
var jake_dialogue_state := "fresh"
var mere_dialogue_state := "fresh"
var bentley_dialogue_state := "fresh"
var heat_state := HEAT_LOW
var current_debug_state := "fresh"

func _ready() -> void:
	apply_debug_state("fresh")

func apply_debug_state(state_id: String) -> void:
	current_debug_state = _normalize_debug_state(state_id)
	_reset_base()
	match current_debug_state:
		"taco_bell_completed":
			_apply_taco_bell_completed(false)
		"taco_bell_missing_items":
			_apply_taco_bell_completed(true)
		"high_heat":
			_apply_taco_bell_completed(false)
			heat_state = HEAT_HIGH
			taco_bell_heat = 3
			taco_bell_lower_heat_available = true
		"louis_unlocked":
			louis_unlocked = true
		_:
			pass
	_update_dialogue_states()

func is_mission_completed(mission_id: String) -> bool:
	return mission_id == "taco_bell_drop" and taco_bell_completed

func get_mission_status(mission_id: String) -> Dictionary:
	if mission_id != "taco_bell_drop":
		return {
			"mission_id": mission_id,
			"state": "locked",
			"missing_clues": 0,
			"missing_collectibles": 0,
			"heat_state": "",
			"available": false,
			"completed": false,
			"perfect": false,
		}
	var missing_clues := 0
	for clue in get_evidence_state().values():
		if String(clue.get("state", "")) in ["unknown", "known_missing", "missing"]:
			missing_clues += 1
	var missing_collectibles := 0
	for item in get_collectible_state().values():
		if item.get("found", false) != true:
			missing_collectibles += 1
	return {
		"mission_id": mission_id,
		"state": "completed" if taco_bell_completed else "available",
		"missing_clues": missing_clues,
		"missing_collectibles": missing_collectibles,
		"heat_state": heat_state if taco_bell_completed else "",
		"available": taco_bell_available,
		"completed": taco_bell_completed,
		"perfect": taco_bell_perfect,
		"lower_heat_available": taco_bell_lower_heat_available,
	}

func get_evidence_state() -> Dictionary:
	return {
		"clue_sauce_packet": _clue("Sauce Packet Residue", "found" if clue_sauce_packet_found else "unknown", "A packet that should not matter this much. It does."),
		"clue_route_manifest": _clue("Route Manifest Half", "found" if clue_route_manifest_found else "unknown", "Half a route list. Enough to prove somebody else planned the path."),
		"clue_velvet_paw_stamp": _clue("Velvet Paw Stamp", "connected" if clue_velvet_paw_stamp_found and not taco_bell_missing_items else ("known_missing" if taco_bell_missing_items else "unknown"), "A stamped mark that points toward a club that should probably not have stamps."),
		"clue_delivery_token": _clue("Delivery Token", "connected" if clue_delivery_token_found else "unknown", "A small token with too much confidence."),
		"clue_security_memo": _clue("Security Memo", "found" if clue_security_memo_found else ("missing" if taco_bell_missing_items else "unknown"), "Somebody wrote down the part they should have whispered."),
	}

func get_collectible_state() -> Dictionary:
	return {
		"polaroid_taco_bell": _collectible("Taco Bell Polaroid", polaroid_taco_bell_found, "A blank space labeled with suspicious confidence.", "A photo from the job. Somehow the lighting is worse than the crime."),
		"glow_guy_taco_bell": _collectible("Taco Bell Glow Guy", glow_guy_taco_bell_found, "A tiny empty shelf with enormous expectations.", "A glowing little guy who has seen too much."),
		"tiny_icon_sauce_packet": _collectible("Sauce Packet", tiny_icon_sauce_packet_found, "A tiny silhouette of future sauce.", "A tiny sauce packet icon. Legally distinct and emotionally present."),
		"tiny_icon_drive_thru_bell": _collectible("Drive-Thru Bell", tiny_icon_drive_thru_bell_found, "A little bell-shaped absence.", "A tiny bell from a place that should have had better security."),
		"poop_bag_fire_sauce_roll": _collectible("Fire Sauce Emergency Roll", poop_bag_fire_sauce_roll_found, "A roll-shaped void in Bentley logistics.", "For emergencies involving fire sauce, guilt, or both."),
		"trophy_taco_bell_drop": _collectible("The Taco Bell Drop Trophy", trophy_taco_bell_found, "A blank trophy stand waiting for a bad idea to become history.", "Proof that delivery logistics can escalate into a full operation."),
	}

func get_scheme_card_state() -> Dictionary:
	return {
		"unlocked_scheme_cards": unlocked_scheme_cards.duplicate(),
		"equipped_plan_card": equipped_plan_card,
		"equipped_trick_card": equipped_trick_card,
		"equipped_comfort_chaos_card": equipped_comfort_chaos_card,
	}

func get_care_state() -> Dictionary:
	return {
		"bentley_wiped": bentley_wiped,
		"bentley_brushed": bentley_brushed,
		"treat_packed": treat_packed,
		"poop_bags_stocked": poop_bags_stocked,
		"sauce_paw_cleanup_available": sauce_paw_cleanup_available,
		"bentley_mood": bentley_mood,
	}

func get_store_state() -> Dictionary:
	return {
		"available_store_items": available_store_items.duplicate(),
		"purchased_store_items": purchased_store_items.duplicate(),
		"delivered_store_items": delivered_store_items.duplicate(),
		"currency_debug_amount": currency_debug_amount,
	}

func get_character_state(character_id: String) -> Dictionary:
	var state := current_debug_state
	match character_id:
		"jake":
			state = jake_dialogue_state
		"mere":
			state = mere_dialogue_state
		"bentley":
			state = bentley_dialogue_state
		"louis":
			state = "louis_unlocked" if louis_unlocked else "fresh"
	return {"character_id": character_id, "dialogue_state": state, "visible": character_id != "louis" or louis_unlocked}

func equip_card(card_id: String, slot_type: String) -> void:
	if not unlocked_scheme_cards.has(card_id):
		return
	match slot_type:
		"Plan":
			equipped_plan_card = card_id
		"Trick":
			equipped_trick_card = card_id
		"Comfort/Chaos":
			equipped_comfort_chaos_card = card_id

func clear_loadout() -> void:
	equipped_plan_card = ""
	equipped_trick_card = ""
	equipped_comfort_chaos_card = ""

func purchase_item(item_id: String) -> bool:
	if not available_store_items.has(item_id) or purchased_store_items.has(item_id):
		return false
	purchased_store_items.append(item_id)
	return true

func _reset_base() -> void:
	taco_bell_available = true
	taco_bell_completed = false
	taco_bell_perfect = false
	taco_bell_missing_items = false
	taco_bell_heat = 0
	taco_bell_lower_heat_available = false
	clue_sauce_packet_found = false
	clue_route_manifest_found = false
	clue_velvet_paw_stamp_found = false
	clue_delivery_token_found = false
	clue_security_memo_found = false
	clue_connections_reviewed = false
	polaroid_taco_bell_found = false
	glow_guy_taco_bell_found = false
	tiny_icon_sauce_packet_found = false
	tiny_icon_drive_thru_bell_found = false
	poop_bag_fire_sauce_roll_found = false
	trophy_taco_bell_found = false
	unlocked_scheme_cards = ["bentley_sniff_pass", "treat_based_negotiation", "definitely_normal_hoodie", "poop_bag_protocol", "jakes_sleep_deprived_insight", "meres_vibe_check"]
	equipped_plan_card = ""
	equipped_trick_card = ""
	equipped_comfort_chaos_card = ""
	bentley_wiped = false
	bentley_brushed = false
	treat_packed = false
	poop_bags_stocked = false
	sauce_paw_cleanup_available = false
	bentley_mood = "curious"
	available_store_items = []
	purchased_store_items = []
	delivered_store_items = []
	currency_debug_amount = 150
	louis_unlocked = false
	heat_state = HEAT_LOW

func _apply_taco_bell_completed(missing_items: bool) -> void:
	taco_bell_completed = true
	taco_bell_missing_items = missing_items
	taco_bell_heat = 1 if not missing_items else 2
	heat_state = HEAT_MEDIUM if missing_items else HEAT_LOW
	taco_bell_lower_heat_available = true
	clue_sauce_packet_found = true
	clue_route_manifest_found = true
	clue_delivery_token_found = true
	clue_velvet_paw_stamp_found = not missing_items
	clue_security_memo_found = not missing_items
	polaroid_taco_bell_found = true
	glow_guy_taco_bell_found = true
	tiny_icon_sauce_packet_found = true
	tiny_icon_drive_thru_bell_found = not missing_items
	poop_bag_fire_sauce_roll_found = true
	trophy_taco_bell_found = not missing_items
	sauce_paw_cleanup_available = true
	for card_id in ["fire_sauce_diversion", "drive_thru_timing_window", "security_booth_coupon", "baja_blast_nerves"]:
		if not unlocked_scheme_cards.has(card_id):
			unlocked_scheme_cards.append(card_id)
	available_store_items = ["taco_bell_stool", "employees_must_wash_paws_sign", "sauce_packet_rug", "neon_menu_panel", "mild_sauce_throw_pillow", "drive_thru_headset", "security_booth_monitor", "suspicious_fry_basket"]

func _update_dialogue_states() -> void:
	jake_dialogue_state = current_debug_state
	mere_dialogue_state = current_debug_state
	bentley_dialogue_state = current_debug_state

func _normalize_debug_state(state_id: String) -> String:
	return "taco_bell_missing_items" if state_id == "missing_items" else state_id

func _clue(display: String, state: String, description: String) -> Dictionary:
	return {"display": display, "state": state, "description": description}

func _collectible(display: String, found: bool, missing_text: String, found_text: String) -> Dictionary:
	return {"display": display, "found": found, "missing_text": missing_text, "found_text": found_text}
