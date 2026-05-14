extends RefCounted
class_name HideoutStationCatalog

const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"

const CLASS_FUNCTIONAL := "FUNCTIONAL"
const CLASS_PANEL_ONLY := "PANEL_ONLY"
const CLASS_DEBUG_STATE_VISUAL := "DEBUG_STATE_VISUAL"
const CLASS_FUTURE_PLACEHOLDER := "FUTURE_PLACEHOLDER"

const ALLOWED_BUTTON_ACTIONS := [
	"back",
	"close",
	"launch_taco_bell",
	"confirm_launch_taco_bell",
	"go_to_planning_table",
	"show_known_info",
	"show_scheme_cards",
	"show_active_slots",
	"show_evidence",
	"show_missing_evidence",
	"mark_evidence_reviewed",
	"view_missing_items",
	"search_missing_items",
	"lower_heat_run",
	"clean_getaway_attempt",
	"view_results",
	"replay_mission",
	"equip_scheme_card",
	"clear_scheme_slot",
	"clear_scheme_loadout",
	"clear_loadout",
	"care_wipe_paws",
	"care_give_treat",
	"care_brush",
	"care_restock_poop_bags",
	"care_view_poop_bags",
	"inspect",
	"show_collection",
	"show_store_category",
	"buy_store_placeholder",
	"store_view_category",
	"store_buy_item",
	"decor_select_item",
	"decor_place_selected",
	"decor_move_selected",
	"decor_remove_selected",
	"decor_clear_all",
	"greenhouse_take_breath",
	"greenhouse_water_plants",
	"greenhouse_inspect_skyline",
	"show_found_collection",
	"show_missing_collection",
	"arrange_later",
	"show_placement_zones",
	"view_heat",
	"talk",
	"unknown_placeholder",
]

const STATION_ALIASES := {
	"EntryExitDoor": "entry_exit_door",
	"BentleyCareStation": "bentley_care_station",
	"LootCrateDropZone": "loot_crate_drop_zone",
	"MissionBoard": "mission_board",
	"EvidenceBoard_TheBigCase": "evidence_board_big_case",
	"PlanningTable": "planning_table",
	"PolaroidWall": "polaroid_wall",
	"GlowGuyShelf": "glow_guy_shelf",
	"TinyIconShelf": "tiny_icon_shelf",
	"PoopBagCareDisplay": "poop_bag_care_display",
	"StoreTerminal": "store_terminal",
	"OpenDecorZone": "open_decor_zone",
	"HeatScanner": "heat_scanner",
	"GreenhouseAlcove": "greenhouse_alcove",
	"Louis": "louis",
	"Jake": "jake",
	"Mere": "mere",
	"Bentley": "bentley",
	"TestInteractable": "test_interactable",
}

static func stations() -> Array[Dictionary]:
	return [
		_station("entry_exit_door", "ENTRY / EXIT", "entry", "Leave the hideout or start moving toward the next job.", CLASS_PANEL_ONLY, Vector2(760, 430), Vector2(700, 390), "EntryExitDoor", "CareStationZone", ["door", "entry"], ["cyberpunk_city_entry", "industrial_door"]),
		_station("bentley_care_station", "BENTLEY CARE STATION", "care", "Wipe Bentley's paws, give a treat, brush him, and restock poop bags. No crime feet on the couch.", CLASS_FUNCTIONAL, Vector2(520, 330), Vector2(500, 390), "BentleyCareStation", "CareStationZone", ["care", "bentley"], ["house_interior_care", "cozy_props"]),
		_station("loot_crate_drop_zone", "LOOT CRATE DROP", "drop_zone", "Mission rewards, store deliveries, furniture, and suspicious packages appear here.", CLASS_DEBUG_STATE_VISUAL, Vector2(210, 350), Vector2(210, 300), "LootCrateDropZone", "StoreDeliveryZone", ["delivery", "loot"], ["cyberpunk_crate", "delivery_box"]),
		_station("bentley", "BENTLEY", "character", "Bentley accepts pets.\n\nBentley looks extremely innocent.\n\nBentley requires immediate paw-related legal defense.", CLASS_PANEL_ONLY, Vector2(-760, 350), Vector2(-720, 350), "Bentley", "BentleyZone", ["character", "dog"], ["house_interior_pet_bed", "cozy_pet_props"]),
		_station("jake", "JAKE", "character", "I'm not saying this is a healthy coping mechanism, but the cork board does have excellent diagnostic clarity.", CLASS_PANEL_ONLY, Vector2(-560, 300), Vector2(-520, 300), "Jake", "FloorZone_OpenDecor", ["character"], ["house_interior_character_corner"]),
		_station("mere", "MERE", "character", "This room is somewhere between detective office, dog daycare, and tax fraud.", CLASS_PANEL_ONLY, Vector2(-420, 300), Vector2(-380, 300), "Mere", "FloorZone_OpenDecor", ["character"], ["house_interior_lounge"]),
		_station("louis", "LOUIS", "character", "I know a guy who knows a guy who sells lamps. Crime lamps.", CLASS_DEBUG_STATE_VISUAL, Vector2(820, 130), Vector2(760, 130), "Louis", "StoreDeliveryZone", ["character", "hidden_until_louis_unlocked"], ["cyberpunk_store_vendor"]),
		_station("mission_board", "MISSION BOARD", "mission_board", "Choose the next mission, replay completed missions, review completion status, and check missing clues or collectibles.", CLASS_FUNCTIONAL, Vector2(520, -410), Vector2(500, -340), "MissionBoard", "WallZone_North", ["mission", "board"], ["cyberpunk_monitor_wall", "neon_panels"]),
		_station("evidence_board_big_case", "THE BIG CASE", "evidence_board", "Review clues, missing evidence, and the vague larger pattern connecting everything.", CLASS_FUNCTIONAL, Vector2(0, -405), Vector2(0, -330), "EvidenceBoard_TheBigCase", "WallZone_North", ["evidence", "board"], ["cyberpunk_corkboard", "detective_wall"]),
		_station("greenhouse_alcove", "GREENHOUSE ALCOVE", "greenhouse", "The greenhouse makes the whole operation feel almost emotionally sustainable.", CLASS_PANEL_ONLY, Vector2(0, -610), Vector2(0, -520), "GreenhouseAlcove", "WallZone_North", ["greenhouse", "quiet"], ["greenhouse_glass", "city_view"]),
		_station("planning_table", "PLANNING TABLE", "scheme_cards", "View and equip scheme cards before missions. Routes and mission choices belong here, not on the mission board.", CLASS_FUNCTIONAL, Vector2(0, 20), Vector2(0, 120), "PlanningTable", "TableZone_Planning", ["planning", "cards"], ["cyberpunk_table", "blueprint_table"]),
		_station("polaroid_wall", "POLAROID WALL", "collectibles", "View and eventually rearrange mission Polaroids.", CLASS_PANEL_ONLY, Vector2(-850, -230), Vector2(-760, -230), "PolaroidWall", "PolaroidWallZone", ["collectible", "wall_item"], ["house_interior_photo_wall"]),
		_station("glow_guy_shelf", "GLOW GUY SHELF", "collectibles", "View and eventually rearrange Glow Guy collectibles.", CLASS_PANEL_ONLY, Vector2(-880, -40), Vector2(-780, -40), "GlowGuyShelf", "ShelfZone_GlowGuys", ["collectible", "shelf_item"], ["house_interior_shelf", "neon_toys"]),
		_station("tiny_icon_shelf", "TINY ICON SHELF", "collectibles", "View and eventually rearrange Tiny Icon collectibles.", CLASS_PANEL_ONLY, Vector2(-880, 110), Vector2(-780, 110), "TinyIconShelf", "ShelfZone_TinyIcons", ["collectible", "shelf_item"], ["house_interior_small_shelf"]),
		_station("poop_bag_care_display", "POOP BAG DISPLAY", "care_collectibles", "View poop bag types, restock supplies, and manage Bentley care items.", CLASS_PANEL_ONLY, Vector2(-840, 250), Vector2(-750, 250), "PoopBagCareDisplay", "CareStationZone", ["care", "collectible"], ["house_interior_storage", "care_supplies"]),
		_station("store_terminal", "STORE TERMINAL", "store", "Purchase hideout furniture, decorations, Bentley items, care upgrades, and mission-themed trophies.", CLASS_FUNCTIONAL, Vector2(790, -80), Vector2(710, -80), "StoreTerminal", "StoreDeliveryZone", ["store", "terminal"], ["cyberpunk_store_terminal", "neon_kiosk"]),
		_station("open_decor_zone", "OPEN DECOR AREA", "placement", "Future decoration sandbox area. Furniture placement and Unpacking-style object arrangement will happen here.", CLASS_FUTURE_PLACEHOLDER, Vector2(470, 120), Vector2(470, 120), "OpenDecorZone", "FloorZone_OpenDecor", ["placement", "floor_item"], ["house_interior_rugs", "furniture_anchors"]),
		_station("heat_scanner", "HEAT SCANNER", "heat", "Heat is the room's bad feeling made visible. Completed missions can be replayed later to cool things down.", CLASS_DEBUG_STATE_VISUAL, Vector2(650, -260), Vector2(620, -220), "HeatScanner", "StoreDeliveryZone", ["heat", "monitor"], ["cyberpunk_security_tech", "warning_panel"]),
		_station("test_interactable", "TEST INTERACTABLE", "panel", "This generic station proves the reusable hideout interaction and scrollable panel path before specialized station content is considered.", CLASS_PANEL_ONLY, Vector2(320, 255), Vector2(320, 205), "TestInteractable", "FloorZone_OpenDecor", ["test", "generic_interactable"], ["graybox_only"]),
	]

static func missions() -> Array[Dictionary]:
	var ids := ["taco_bell_drop", "velvet_paw_jazz_club", "rewrite_room", "fast_family_getaway", "clean_job", "diamond_a_year_job", "arm_wrestling_underground", "persian_tea_and_poison_ink", "elephant_in_the_room", "shadow_solo_contract", "final_job"]
	var names := ["The Taco Bell Drop", "Velvet Paw Jazz Club", "Rewrite Room", "Fast Family Getaway", "Clean Job", "Diamond a Year Job", "Arm-Wrestling Underground", "Persian Tea and Poison Ink", "Elephant in the Room", "Shadow Solo Contract", "The Final Job"]
	var out: Array[Dictionary] = []
	for i in range(names.size()):
		out.append({
			"slot": i + 1,
			"mission_id": ids[i],
			"display_name": names[i],
			"state": "Fresh" if i == 0 else "Future",
			"scene_path": MissionSceneResolver.resolve_playable_scene_path(ids[i]) if i == 0 else "",
			"status_text": "Ready for delivery." if i == 0 else "Not on the cork board yet.",
		})
	return out

static func scheme_cards() -> Array[Dictionary]:
	return [
		_card("bentley_sniff_pass", "Bentley Sniff Pass", "plan", "fresh", "Reveals nearby scent trails for a short duration.", "Brief scent-trail reveal.", "starter", 1),
		_card("treat_based_negotiation", "Treat-Based Negotiation", "trick", "fresh", "Bentley distracts one nearby guard or NPC briefly.", "Short Bentley distraction.", "starter", 2),
		_card("definitely_normal_hoodie", "Definitely Normal Hoodie", "comfort_chaos", "fresh", "Slightly reduces detection buildup when walking, not running.", "Lower walking detection buildup.", "starter", 3),
		_card("poop_bag_protocol", "Poop Bag Protocol", "plan", "fresh", "Start the mission with one extra poop bag use.", "Extra poop bag use.", "starter", 4),
		_card("jakes_sleep_deprived_insight", "Jake's Sleep-Deprived Insight", "plan", "fresh", "Highlights one suspicious interactable or clue zone per mission.", "One suspicious clue hint.", "starter", 5),
		_card("meres_vibe_check", "Mere's Vibe Check", "comfort_chaos", "fresh", "Gives a subtle warning when entering a very risky area.", "Risk area warning.", "starter", 6),
		_card("fire_sauce_diversion", "Fire Sauce Diversion", "trick", "taco_bell_completed", "Drop a spicy distraction that pulls one guard or NPC away briefly.", "Spicy guard diversion.", "taco_bell_drop", 7),
		_card("drive_thru_timing_window", "Drive-Thru Timing Window", "plan", "taco_bell_completed", "Slows or offsets one patrol cycle near service counters or windows.", "Patrol timing offset.", "taco_bell_drop", 8),
		_card("security_booth_coupon", "Security Booth Coupon", "trick", "taco_bell_completed", "Temporarily loops one camera if activated near a camera node.", "Temporary camera loop.", "taco_bell_drop", 9),
		_card("baja_blast_nerves", "Baja Blast Nerves", "comfort_chaos", "taco_bell_completed", "Short speed boost after being detected, but increases noise slightly.", "Risky detection speed boost.", "taco_bell_drop", 10),
	]

static func _card(card_id: String, display_name: String, slot_type: String, unlock_condition: String, description: String, short_effect_summary: String, source_mission: String, sort_order: int) -> Dictionary:
	return {
		"card_id": card_id,
		"display_name": display_name,
		"name": display_name,
		"slot_type": slot_type,
		"unlock_condition": unlock_condition,
		"unlock": unlock_condition,
		"description": description,
		"short_effect_summary": short_effect_summary,
		"source_mission": source_mission,
		"sort_order": sort_order,
	}

static func normalize_station_id(raw_id: String) -> String:
	var cleaned := raw_id.strip_edges()
	if STATION_ALIASES.has(cleaned):
		return STATION_ALIASES[cleaned]
	var snake := cleaned.to_snake_case().to_lower()
	if STATION_ALIASES.has(snake):
		return STATION_ALIASES[snake]
	return snake

static func station_by_id(raw_id: String) -> Dictionary:
	var station_id := normalize_station_id(raw_id)
	for entry in stations():
		if String(entry.get("station_id", "")) == station_id:
			return entry
	return {}

static func get_panel_data(raw_id: String) -> Dictionary:
	var station_id := normalize_station_id(raw_id)
	var content := _panel_content()
	if content.has(station_id):
		var data := Dictionary(content[station_id]).duplicate(true)
		data["station_id"] = station_id
		if not data.has("classification"):
			data["classification"] = station_by_id(station_id).get("classification", CLASS_PANEL_ONLY)
		return data
	var fallback_title := "Unknown Station"
	return {
		"station_id": station_id,
		"title": fallback_title,
		"body": "Station '%s' is not registered in the HideoutStationCatalog." % station_id,
		"buttons": [_button("back", "Back", "close")],
		"classification": CLASS_FUTURE_PLACEHOLDER,
	}

static func _panel_content() -> Dictionary:
	return {
		"entry_exit_door": {
			"title": "Entry / Exit",
			"body": "Leave the hideout or start moving toward the next job.",
			"buttons": [_button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"bentley_care_station": {
			"title": "Bentley Care Station",
			"body": "Wipe Bentley's paws, give a treat, brush him, and restock poop bags. No crime feet on the couch.",
			"buttons": [
				_button("wipe_paws", "Wipe Paws", "care_wipe_paws"),
				_button("give_treat", "Give Treat", "care_give_treat"),
				_button("brush_bentley", "Brush Bentley", "care_brush"),
				_button("restock_poop_bags", "Restock Poop Bags", "care_restock_poop_bags"),
				_button("view_poop_bags", "View Poop Bag Collection", "care_view_poop_bags"),
				_button("back", "Back", "close"),
			],
			"classification": CLASS_FUNCTIONAL,
		},
		"loot_crate_drop_zone": {
			"title": "Loot Crate Drop Zone",
			"body": "Mission rewards, store deliveries, furniture, and suspicious packages appear here.",
			"buttons": [_button("inspect_crate", "Inspect Crate", "inspect"), _button("back", "Back", "close")],
			"classification": CLASS_DEBUG_STATE_VISUAL,
		},
		"bentley": {
			"title": "Bentley",
			"body": "Bentley accepts pets. Bentley looks extremely innocent. Bentley requires immediate paw-related legal defense.",
			"buttons": [_button("pet_bentley", "Pet Bentley", "talk"), _button("check_mood", "Check Mood", "inspect"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"jake": {
			"title": "Jake",
			"body": "I'm not saying this is a healthy coping mechanism, but the cork board does have excellent diagnostic clarity.",
			"buttons": [_button("talk", "Talk", "talk"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"mere": {
			"title": "Mere",
			"body": "This room is somewhere between detective office, dog daycare, and tax fraud.",
			"buttons": [_button("talk", "Talk", "talk"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"mission_board": {
			"title": "Mission Board",
			"body": "Choose the next mission, replay completed missions, review completion status, and check missing clues or collectibles.\n\nMissions:\n1. The Taco Bell Drop - Available - Ready for delivery.\n2. Velvet Paw Jazz Club - Locked\n3. Rewrite Room - Locked\n4. Fast Family Getaway - Locked\n5. Clean Job - Locked\n6. Diamond a Year Job - Locked\n7. Arm-Wrestling Underground - Locked\n8. Persian Tea and Poison Ink - Locked\n9. Elephant in the Room - Locked\n10. Shadow Solo Contract - Locked\n11. The Final Job - Locked\n\nFresh missions do not show route selection, assist selection, difficulty selection, or heat controls.",
			"buttons": [_button("start_taco_bell", "Start The Taco Bell Drop", "launch_taco_bell"), _button("known_info", "View Known Info", "show_known_info"), _button("back", "Back", "close")],
			"classification": CLASS_FUNCTIONAL,
		},
		"evidence_board_big_case": {
			"title": "The Big Case",
			"body": "A larger pattern is forming.\n\nMore pieces are connected.\n\nSomething bigger is behind this.\n\nThe map is becoming less comforting.\n\nTaco Bell Clue Placeholders:\n- Sauce packet residue\n- Route manifest half\n- Velvet Paw stamp\n- Delivery token",
			"buttons": [_button("review_taco_bell_clues", "Review Taco Bell Clues", "show_evidence"), _button("mark_reviewed", "Mark Board Reviewed", "mark_evidence_reviewed"), _button("missing_evidence", "View Missing Evidence", "show_missing_evidence"), _button("back", "Back", "close")],
			"classification": CLASS_FUNCTIONAL,
		},
		"planning_table": {
			"title": "Planning Table",
			"body": "View and equip scheme cards before missions. Routes and mission choices belong here, not on the mission board.\n\nStarter Scheme Cards:\n1. Bentley Sniff Pass - Reveals nearby scent trails for a short duration.\n2. Treat-Based Negotiation - Bentley distracts one nearby guard or NPC briefly.\n3. Definitely Normal Hoodie - Slightly reduces detection buildup when walking, not running.\n4. Poop Bag Protocol - Start the mission with one extra poop bag use.\n5. Jake's Sleep-Deprived Insight - Highlights one suspicious interactable or clue zone per mission.\n6. Mere's Vibe Check - Gives a subtle warning when entering a very risky area.\n7. Fire Sauce Diversion - Drop a spicy distraction that pulls one guard or NPC away briefly.\n8. Drive-Thru Timing Window - Slows or offsets one patrol cycle near service counters or windows.\n9. Security Booth Coupon - Temporarily loops one camera if activated near a camera node.\n10. Baja Blast Nerves - Short speed boost after being detected, but increases noise slightly.",
			"buttons": [_button("view_scheme_cards", "View Scheme Cards", "show_scheme_cards"), _button("view_active_slots", "View Active Slots", "show_active_slots"), _button("back", "Back", "close")],
			"classification": CLASS_FUNCTIONAL,
		},
		"greenhouse_alcove": {
			"title": "Greenhouse Alcove",
			"body": "The greenhouse makes the whole operation feel almost emotionally sustainable. The city looks beautiful from here, which is rude given the circumstances.",
			"buttons": [_button("take_breath", "Take a Breath", "greenhouse_take_breath"), _button("water_plants", "Water Suspicious Plants", "greenhouse_water_plants"), _button("inspect_skyline", "Inspect the Skyline", "greenhouse_inspect_skyline"), _button("close", "Close", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"polaroid_wall": {
			"title": "Polaroid Wall",
			"body": "View and eventually rearrange mission Polaroids. Some are proof. Some are memories. Some are probably both.\n\nCurrent placeholder:\n- Taco Bell Polaroid silhouette",
			"buttons": [_button("view_polaroids", "View Polaroids", "show_collection"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"glow_guy_shelf": {
			"title": "Glow Guy Shelf",
			"body": "View and eventually rearrange Glow Guy collectibles. The shelf hums with tiny suspicious importance.\n\nCurrent placeholder:\n- Taco Bell Glow Guy silhouette",
			"buttons": [_button("view_glow_guys", "View Glow Guys", "show_collection"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"tiny_icon_shelf": {
			"title": "Tiny Icon Shelf",
			"body": "View and eventually rearrange Tiny Icon collectibles.\n\nCurrent placeholders:\n- Sauce Packet\n- Drive-Thru Bell",
			"buttons": [_button("view_tiny_icons", "View Tiny Icons", "show_collection"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"poop_bag_care_display": {
			"title": "Poop Bag Display",
			"body": "View poop bag types, restock supplies, and manage Bentley care items.\n\nCurrent placeholder:\n- Fire Sauce Emergency Roll",
			"buttons": [_button("view_poop_bags", "View Poop Bag Types", "care_view_poop_bags"), _button("restock", "Restock", "care_restock_poop_bags"), _button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
		"store_terminal": {
			"title": "Store Terminal",
			"body": "Purchase hideout furniture, decorations, Bentley items, care upgrades, and mission-themed trophies.\n\nStore Categories:\n- Furniture\n- Wall Decor\n- Rugs\n- Lights\n- Bentley Items\n- Care Station Upgrades\n- Collectible Displays\n- Mission Trophies\n\nTaco Bell Decor Unlock Placeholders:\n- Drive-Thru Headset\n- Security Booth Monitor\n- Sauce Packet Rug\n- Taco Bell Stool\n- Neon Menu Panel\n- Employees Must Wash Paws Sign\n- Mild Sauce Throw Pillow\n- Suspicious Fry Basket",
			"buttons": [_button("furniture", "Furniture", "show_store_category"), _button("wall_decor", "Wall Decor", "show_store_category"), _button("rugs", "Rugs", "show_store_category"), _button("lights", "Lights", "show_store_category"), _button("bentley_items", "Bentley Items", "show_store_category"), _button("care_station_upgrades", "Care Station Upgrades", "show_store_category"), _button("mission_trophies", "Mission Trophies", "show_store_category"), _button("back", "Back", "close")],
			"classification": CLASS_FUNCTIONAL,
		},
		"open_decor_zone": {
			"title": "Open Decor Area",
			"body": "Future decoration sandbox area. Furniture placement and Unpacking-style object arrangement will happen here.\n\nThis area will eventually support placement zones, snap markers, furniture anchors, rugs, shelves, and mission trophies.",
			"buttons": [_button("show_placement_zones", "Show Placement Zones", "show_placement_zones"), _button("back", "Back", "close")],
			"classification": CLASS_FUTURE_PLACEHOLDER,
		},
		"heat_scanner": {
			"title": "Heat Scanner",
			"body": "Heat is the room's bad feeling made visible. Completed missions can be replayed later to cool things down.\n\nFresh missions do not have heat controls. Heat controls only appear for completed missions.",
			"buttons": [_button("view_heat", "View Heat", "view_heat"), _button("back", "Back", "close")],
			"classification": CLASS_DEBUG_STATE_VISUAL,
		},
		"louis": {
			"title": "Louis",
			"body": "I know a guy who knows a guy who sells lamps. Crime lamps.",
			"buttons": [_button("questionable_goods", "Browse Questionable Goods", "show_store_category"), _button("back", "Back", "close")],
			"classification": CLASS_DEBUG_STATE_VISUAL,
		},
		"test_interactable": {
			"title": "Test Interactable",
			"body": "This confirms the hideout interaction spine is working.",
			"buttons": [_button("back", "Back", "close")],
			"classification": CLASS_PANEL_ONLY,
		},
	}

static func _button(id: String, label: String, action: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"action": action if ALLOWED_BUTTON_ACTIONS.has(action) else "unknown_placeholder",
	}

static func _station(station_id: String, display_name: String, station_type: String, body: String, classification: String, position: Vector2, proxy_position: Vector2, node_name: String, placement_zone: String, tags: Array[String], monogon_tags: Array[String]) -> Dictionary:
	return {
		"station_id": station_id,
		"display_name": display_name,
		"station_type": station_type,
		"panel_title": get_panel_data(station_id).get("title", display_name),
		"panel_body": get_panel_data(station_id).get("body", body),
		"panel_buttons": get_panel_data(station_id).get("buttons", [_button("back", "Back", "close")]),
		"unlock_state": "fresh",
		"visible_in_states": ["fresh", "taco_bell_completed", "missing_items", "high_heat", "louis_unlocked"],
		"placement_zone": placement_zone,
		"node_path": "GameplayRoot/Stations/" + node_name,
		"node_name": node_name,
		"classification": classification,
		"position": position,
		"proxy_position": proxy_position,
		"tags": tags,
		"suggested_monogon_art_tags": monogon_tags,
	}
