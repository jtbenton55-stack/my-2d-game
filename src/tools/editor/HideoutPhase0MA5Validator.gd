@tool
extends RefCounted
class_name HideoutPhase0MA5Validator

const SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")

const REQUIRED_STATIONS := [
	"entry_exit_door",
	"bentley_care_station",
	"loot_crate_drop_zone",
	"bentley",
	"jake",
	"mere",
	"mission_board",
	"evidence_board_big_case",
	"planning_table",
	"polaroid_wall",
	"glow_guy_shelf",
	"tiny_icon_shelf",
	"poop_bag_care_display",
	"store_terminal",
	"open_decor_zone",
	"heat_scanner",
	"louis",
	"test_interactable",
]

static func validate() -> Dictionary:
	var result := {
		"scene_exists": ResourceLoader.exists(SCENE_PATH),
		"scene_loads": false,
		"taco_bell_paths_exist": FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE),
		"scrollable_panel_exists": false,
		"scrollable_panel_has_open_panel": false,
		"scrollable_panel_has_close_panel": false,
		"hideout_manager_has_open_station": false,
		"station_catalog_exists": true,
		"all_required_station_content_non_empty": false,
		"mission_board_lists_11_missions": false,
		"mission_board_has_launch_action": false,
		"launch_path_exact": Catalog.TACO_BELL_SCENE == TACO_BELL_SCENE,
		"forbidden_labels_absent": _forbidden_labels_absent(),
		"unknown_station_fallback_exists": false,
		"reports_exist": FileAccess.file_exists("res://docs/reports/hideout_phase_0ma5_panel_content_binding.md") and FileAccess.file_exists("res://docs/reports/hideout_phase_0ma5_panel_content_binding.json"),
		"errors": [],
	}
	if not result.scene_exists:
		result.errors.append("HideoutHub.tscn is missing.")
		return result
	var packed := ResourceLoader.load(SCENE_PATH)
	if packed == null:
		result.errors.append("HideoutHub.tscn failed to load.")
		return result
	result.scene_loads = true
	var scene := packed.instantiate()
	if scene == null:
		result.errors.append("HideoutHub.tscn failed to instantiate.")
		return result
	result.scrollable_panel_exists = scene.has_node("UI/ScrollableStationPanel")
	if result.scrollable_panel_exists:
		var panel := scene.get_node("UI/ScrollableStationPanel")
		result.scrollable_panel_has_open_panel = panel.has_method("open_panel")
		result.scrollable_panel_has_close_panel = panel.has_method("close_panel")
	result.hideout_manager_has_open_station = scene.has_node("GameplayRoot/Managers/HideoutManager") and scene.get_node("GameplayRoot/Managers/HideoutManager").has_method("open_station")
	result.all_required_station_content_non_empty = _all_required_station_content_non_empty()
	result.mission_board_lists_11_missions = _mission_board_lists_11_missions()
	result.mission_board_has_launch_action = _mission_board_has_launch_action()
	result.unknown_station_fallback_exists = Catalog.get_panel_data("definitely_missing_station").get("title", "") == "Unknown Station"
	scene.free()
	return result

static func _all_required_station_content_non_empty() -> bool:
	for station_id in REQUIRED_STATIONS:
		var data := Catalog.get_panel_data(station_id)
		if String(data.get("title", "")).strip_edges() == "":
			return false
		if String(data.get("body", "")).strip_edges() == "":
			return false
		var buttons: Array = data.get("buttons", [])
		if buttons.is_empty():
			return false
	return true

static func _mission_board_lists_11_missions() -> bool:
	var body := String(Catalog.get_panel_data("mission_board").get("body", ""))
	for mission_name in [
		"The Taco Bell Drop",
		"Velvet Paw Jazz Club",
		"Rewrite Room",
		"Fast Family Getaway",
		"Clean Job",
		"Diamond a Year Job",
		"Arm-Wrestling Underground",
		"Persian Tea and Poison Ink",
		"Elephant in the Room",
		"Shadow Solo Contract",
		"The Final Job",
	]:
		if not body.contains(mission_name):
			return false
	return true

static func _mission_board_has_launch_action() -> bool:
	for button in Catalog.get_panel_data("mission_board").get("buttons", []):
		if button is Dictionary and String(button.get("action", "")) == "launch_taco_bell":
			return true
	return false

static func _forbidden_labels_absent() -> bool:
	for file_path in [
		SCENE_PATH,
		"res://src/hideout/HideoutStationCatalog.gd",
		"res://src/hideout/HideoutManager.gd",
		"res://src/hideout/HideoutMissionBoardController.gd",
	]:
		if not FileAccess.file_exists(file_path):
			continue
		var text := FileAccess.get_file_as_string(file_path)
		if text.contains("Sterling Tower Progression") or text.contains("Sterling Syndicate Progression"):
			return false
	return true
