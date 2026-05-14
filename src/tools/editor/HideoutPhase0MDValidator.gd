@tool
extends RefCounted
class_name HideoutPhase0MDValidator

const SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md_progression_store_decoration_systems.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md_progression_store_decoration_systems.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")
const StateController = preload("res://src/hideout/HideoutStateController.gd")
const StoreController = preload("res://src/hideout/HideoutStoreController.gd")
const DecorationController = preload("res://src/hideout/HideoutDecorationController.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")

const REQUIRED_DIALOGUE_CONTEXTS := [
	"bentley_care_wipe_paws",
	"bentley_care_give_treat",
	"bentley_care_brush",
	"bentley_care_restock_poop_bags",
	"bentley_bed_fresh",
	"bentley_bed_taco_bell_completed",
	"bentley_bed_high_heat",
	"jake_fresh",
	"jake_taco_bell_completed",
	"jake_high_heat",
	"mere_fresh",
	"mere_taco_bell_completed",
	"mere_high_heat",
	"louis_unlocked",
	"store_purchase_success",
	"store_insufficient_funds",
	"greenhouse_interaction",
	"greenhouse_take_breath",
	"greenhouse_water_plants",
	"greenhouse_inspect_skyline",
	"mission_start_warning",
	"big_case_review",
	"open_decor_area",
	"decoration_place_success",
	"decoration_remove_success",
]

static func validate() -> Dictionary:
	var state := StateController.new()
	state.apply_debug_state("taco_bell_completed")
	var store := StoreController.new()
	var decor := DecorationController.new()
	var result := {
		"scene_exists": ResourceLoader.exists(SCENE_PATH),
		"scene_loads": false,
		"scheme_card_catalog_has_10": Catalog.scheme_cards().size() == 10,
		"all_unlocked_cards_have_equip_actions": false,
		"active_slot_state_exists": state.has_method("get_current_scheme_loadout"),
		"mission_start_confirmation_exists": FileAccess.get_file_as_string("res://src/hideout/HideoutManager.gd").contains("_mission_start_confirmation_data"),
		"mission_start_writes_loadout": FileAccess.get_file_as_string("res://src/hideout/HideoutManager.gd").contains("_write_scheme_loadout_to_game_state"),
		"panel_navigation_stack_exists": FileAccess.get_file_as_string("res://src/hideout/ScrollableStationPanel.gd").contains("panel_history"),
		"dialogue_bank_exists": ResourceLoader.exists("res://src/hideout/HideoutDialogueBank.gd"),
		"dialogue_contexts_have_three_lines": _dialogue_contexts_have_three_lines(),
		"case_cash_exists": state.has_method("get_case_cash") and state.get_case_cash() >= 75,
		"store_item_catalog_exists": StoreController.ITEMS.size() == 8,
		"store_purchase_spends_cash": false,
		"store_purchase_adds_inventory": false,
		"decoration_controller_exists": ResourceLoader.exists("res://src/hideout/HideoutDecorationController.gd"),
		"greenhouse_station_exists": Catalog.station_by_id("greenhouse_alcove").size() > 0,
		"taco_bell_completed_populates_displays": state.get_collectible_state().get("polaroid_taco_bell", {}).get("found", false) == true and state.get_collectible_state().get("trophy_taco_bell_drop", {}).get("found", false) == true,
		"mission_names_no_bracketed_ids": not MissionBoard.new().get_panel_body(state).contains("["),
		"gameplay_art_separation_preserved": false,
		"reports_exist": FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON),
	}
	var buttons := preload("res://src/hideout/HideoutSchemeCardController.gd").new().get_buttons(state)
	var equip_count := 0
	for button in buttons:
		if String(button.get("action", "")).begins_with("equip_scheme_card:"):
			equip_count += 1
	result.all_unlocked_cards_have_equip_actions = equip_count == state.get("unlocked_scheme_cards").size()
	var before_cash := state.get_case_cash()
	store.purchase_placeholder("taco_bell_stool", state)
	result.store_purchase_spends_cash = state.get_case_cash() < before_cash
	result.store_purchase_adds_inventory = state.get("owned_placeable_items").has("taco_bell_stool")
	if result.scene_exists:
		var packed := ResourceLoader.load(SCENE_PATH)
		if packed != null:
			result.scene_loads = true
			var scene: Node = packed.instantiate()
			if scene != null:
				result.gameplay_art_separation_preserved = scene.has_node("GameplayRoot") and scene.has_node("ArtRoot") and scene.has_node("ArtRoot/World/DecorationLayer/PlacedDecor")
				scene.free()
	return result

static func _dialogue_contexts_have_three_lines() -> bool:
	for context_id in REQUIRED_DIALOGUE_CONTEXTS:
		if not DialogueBank.context_has_three_lines(context_id):
			return false
	return true
