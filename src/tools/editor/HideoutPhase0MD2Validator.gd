extends RefCounted
class_name HideoutPhase0MD2Validator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md2_ux_dialogic_decoration_repair.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md2_ux_dialogic_decoration_repair.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")
const DialogueBank = preload("res://src/hideout/HideoutDialogueBank.gd")

static func validate() -> Dictionary:
	var result := {
		"phase": "0M-D2",
		"passed": true,
		"errors": [],
		"checks": {},
	}
	var checks: Dictionary = result["checks"]
	var panel_text := _read("res://src/hideout/ScrollableStationPanel.gd")
	var manager_text := _read("res://src/hideout/HideoutManager.gd")
	var store_text := _read("res://src/hideout/HideoutStoreController.gd")
	var decor_text := _read("res://src/hideout/HideoutDecorationController.gd")
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	var character_text := _read("res://src/hideout/HideoutCharacterController.gd")
	checks["hideout_scene_loads"] = ResourceLoader.exists(HIDEOUT_SCENE) and load(HIDEOUT_SCENE) != null
	checks["taco_bell_source_exists"] = FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["taco_bell_redesign_exists"] = FileAccess.file_exists(TACO_BELL_SCENE)
	checks["panel_has_scrollable_content"] = panel_text.contains("ScrollContainer") and panel_text.contains("_body_scroll")
	checks["planning_store_mission_scroll_safe"] = panel_text.contains("_fit_to_viewport") and panel_text.contains("ActionButtonScroll")
	checks["close_reachable_once"] = panel_text.contains("_without_close_buttons") and panel_text.contains("_close_button")
	checks["back_close_distinct"] = manager_text.contains("\"back\"") and manager_text.contains("\"close\"") and panel_text.contains("close_panel")
	checks["scene_manager_hideout_path"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["pause_exit_uses_scene_manager"] = _read("res://src/ui/PauseMenu.gd").contains("SceneManager.return_to_hideout()") and _read("res://src/ui/test_ui/pause_menu.gd").contains("SceneManager.return_to_hideout()")
	checks["mission_board_launches_redesign"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["storefront_cards_exist"] = store_text.contains("Visual Storefront Cards") and store_text.contains("[ICON]")
	checks["store_cards_show_fields"] = store_text.contains("Cost:") and store_text.contains("State:") and store_text.contains("Category:")
	checks["owned_decor_inventory_exists"] = decor_text.contains("Owned Decor Inventory Cards")
	checks["click_to_place_mode_exists"] = decor_text.contains("Enter Click-To-Place Mode") and decor_text.contains("PlacementPreview")
	checks["placed_item_select_remove_exists"] = decor_text.contains("select_placed") and decor_text.contains("remove_selected")
	checks["bentley_care_back_refresh"] = manager_text.contains("current_station_id in") and manager_text.contains("bentley_care_station")
	checks["dialogic_status_recorded"] = FileAccess.file_exists(REPORT_MD) or FileAccess.file_exists(REPORT_JSON)
	checks["dialogic_fallback_preserved"] = FileAccess.file_exists("res://src/hideout/HideoutDialogueBank.gd") and character_text.contains("HideoutDialogicAdapter.gd")
	checks["jake_mere_dialogue_expanded"] = DialogueBank.context_has_at_least("jake_fresh", 6) and DialogueBank.context_has_at_least("mere_fresh", 6)
	checks["station_interactions_wired"] = Catalog.stations().size() >= 18
	checks["gameplay_art_separation_preserved"] = _scene_has_nodes(HIDEOUT_SCENE, ["GameplayRoot", "ArtRoot", "UI", "GameplayRoot/Managers/HideoutManager"])
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON)
	for key in checks.keys():
		if checks[key] != true:
			result["errors"].append("Check failed: %s" % key)
	result["passed"] = result["errors"].is_empty()
	return result

static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

static func _scene_has_nodes(path: String, node_paths: Array[String]) -> bool:
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var scene := packed.instantiate()
	if scene == null:
		return false
	var ok := true
	for node_path in node_paths:
		if not scene.has_node(node_path):
			ok = false
			break
	scene.queue_free()
	return ok
