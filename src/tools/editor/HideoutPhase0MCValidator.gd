@tool
extends RefCounted
class_name HideoutPhase0MCValidator

const SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0mc_systems_depth_pass.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0mc_systems_depth_pass.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")
const EvidenceBoard = preload("res://src/hideout/HideoutEvidenceBoardController.gd")
const SchemeCards = preload("res://src/hideout/HideoutSchemeCardController.gd")
const Collectibles = preload("res://src/hideout/HideoutCollectibleController.gd")
const Care = preload("res://src/hideout/HideoutCareController.gd")
const Store = preload("res://src/hideout/HideoutStoreController.gd")
const Characters = preload("res://src/hideout/HideoutCharacterController.gd")
const DebugController = preload("res://src/hideout/HideoutDebugController.gd")
const StateController = preload("res://src/hideout/HideoutStateController.gd")

const REQUIRED_STATIONS := ["entry_exit_door", "bentley_care_station", "loot_crate_drop_zone", "bentley", "jake", "mere", "mission_board", "evidence_board_big_case", "planning_table", "polaroid_wall", "glow_guy_shelf", "tiny_icon_shelf", "poop_bag_care_display", "store_terminal", "open_decor_zone", "heat_scanner", "louis", "test_interactable"]

static func validate() -> Dictionary:
	var result := {
		"scene_exists": ResourceLoader.exists(SCENE_PATH),
		"scene_loads": false,
		"taco_bell_paths_exist": FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE),
		"state_controller_exists": ResourceLoader.exists("res://src/hideout/HideoutStateController.gd"),
		"mission_board_uses_state_data": false,
		"mission_board_has_11_missions": Catalog.missions().size() == 11,
		"taco_bell_launch_path_exact": MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE,
		"evidence_has_clue_entries": false,
		"evidence_forbidden_labels_absent": _forbidden_labels_absent(),
		"scheme_card_count": Catalog.scheme_cards().size(),
		"scheme_active_slots_exist": false,
		"collectible_entries_exist": false,
		"care_flags_actions_exist": false,
		"store_categories_items_exist": false,
		"character_state_dialogue_exists": false,
		"debug_state_triggers_exist": DebugController.STATES.size() == 5,
		"all_known_button_actions_have_handlers": _manager_has_action_handlers(),
		"required_station_panels_non_empty": _required_station_panels_non_empty(),
		"scrollable_panel_opens_closes": false,
		"gameplay_art_separation_preserved": false,
		"reports_exist": FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON),
		"errors": [],
	}
	var state := StateController.new()
	state.apply_debug_state("taco_bell_completed")
	var mission := MissionBoard.new()
	result.mission_board_uses_state_data = mission.get_panel_body(state).contains("Missing clues") and mission.get_buttons(state).size() >= 3
	var evidence := EvidenceBoard.new()
	result.evidence_has_clue_entries = evidence.get_panel_body(state).contains("Sauce Packet Residue") and evidence.get_panel_body(state).contains("Route Manifest Half")
	var scheme := SchemeCards.new()
	result.scheme_active_slots_exist = scheme.get_panel_body(state).contains("Plan Card") and scheme.get_panel_body(state).contains("Comfort/Chaos Card")
	var collectibles := Collectibles.new()
	result.collectible_entries_exist = collectibles.get_panel_body("polaroid_wall", state).contains("Taco Bell Polaroid")
	var care := Care.new()
	result.care_flags_actions_exist = care.has_method("wipe_paws") and care.has_method("restock_poop_bags") and care.get_panel_body(state).contains("Care Checklist")
	var store := Store.new()
	result.store_categories_items_exist = Store.CATEGORIES.size() == 8 and Store.ITEMS.size() == 8
	var chars := Characters.new()
	result.character_state_dialogue_exists = chars.dialogue_for("jake", state).contains("mild sauce")
	if result.scene_exists:
		var packed := ResourceLoader.load(SCENE_PATH)
		if packed != null:
			result.scene_loads = true
			var scene := packed.instantiate()
			if scene != null:
				result.scrollable_panel_opens_closes = scene.has_node("UI/ScrollableStationPanel") and scene.get_node("UI/ScrollableStationPanel").has_method("open_panel") and scene.get_node("UI/ScrollableStationPanel").has_method("close_panel")
				result.gameplay_art_separation_preserved = scene.has_node("GameplayRoot") and scene.has_node("ArtRoot") and scene.has_node("GameplayRoot/Managers/HideoutManager")
				scene.free()
		else:
			result.errors.append("HideoutHub.tscn failed to load.")
	return result

static func _required_station_panels_non_empty() -> bool:
	for station_id in REQUIRED_STATIONS:
		var data := Catalog.get_panel_data(station_id)
		if String(data.get("title", "")).strip_edges() == "" or String(data.get("body", "")).strip_edges() == "":
			return false
		if Array(data.get("buttons", [])).is_empty():
			return false
	return true

static func _forbidden_labels_absent() -> bool:
	for file_path in ["res://src/hideout/HideoutStationCatalog.gd", "res://src/hideout/HideoutMissionBoardController.gd", "res://src/hideout/HideoutEvidenceBoardController.gd", "res://src/hideout/HideoutManager.gd"]:
		if not FileAccess.file_exists(file_path):
			continue
		var text := FileAccess.get_file_as_string(file_path)
		for forbidden in ["Sterling Tower Progression", "Sterling Syndicate Progression", "Sterling Tower progress", "Sterling Syndicate progress"]:
			if text.contains(forbidden):
				return false
	return true

static func _manager_has_action_handlers() -> bool:
	var text := FileAccess.get_file_as_string("res://src/hideout/HideoutManager.gd")
	for action_id in Catalog.ALLOWED_BUTTON_ACTIONS:
		if not text.contains("\"%s\"" % action_id):
			return false
	return true
