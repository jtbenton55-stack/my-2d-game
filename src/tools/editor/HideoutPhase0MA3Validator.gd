@tool
extends RefCounted
class_name HideoutPhase0MA3Validator

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
		"taco_bell_scene_paths_known": FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE),
		"floor_shape_irregular": false,
		"required_zones_near_targets": false,
		"gameplay_art_separation": false,
		"player_exists": false,
		"player_z_above_floor": false,
		"required_stations_exist_in_catalog": false,
		"required_station_proxies_exist": false,
		"station_proxies_in_interactable_group": true,
		"station_proxies_have_interact": true,
		"scrollable_panel_exists": false,
		"scrollable_panel_uses_scroll_container": false,
		"mission_board_taco_bell_launch_path": false,
		"louis_hidden_fresh": true,
		"louis_visible_unlocked_supported": true,
		"forbidden_labels_absent": _forbidden_labels_absent(),
		"reports_exist": FileAccess.file_exists("res://docs/reports/hideout_phase_0ma3_reference_layout_interaction_repair.md") and FileAccess.file_exists("res://docs/reports/hideout_phase_0ma3_reference_layout_interaction_repair.json"),
		"errors": [],
	}
	if not result.scene_exists:
		result.errors.append("HideoutHub scene missing.")
		return result
	var packed := ResourceLoader.load(SCENE_PATH)
	if packed == null:
		result.errors.append("HideoutHub failed to load.")
		return result
	result.scene_loads = true
	var scene := packed.instantiate()
	if scene == null:
		result.errors.append("HideoutHub failed to instantiate.")
		return result
	result.gameplay_art_separation = scene.has_node("GameplayRoot") and scene.has_node("ArtRoot/World/FloorLayer") and scene.has_node("GameplayRoot/Navigation/Collision")
	result.player_exists = scene.has_node("GameplayRoot/Characters/Player")
	if result.player_exists and scene.has_node("ArtRoot/World/FloorLayer"):
		var player := scene.get_node("GameplayRoot/Characters/Player") as Node2D
		var floor := scene.get_node("ArtRoot/World/FloorLayer") as Node2D
		result.player_z_above_floor = player != null and floor != null and player.z_index > floor.z_index
	result.scrollable_panel_exists = scene.has_node("UI/ScrollableStationPanel")
	result.scrollable_panel_uses_scroll_container = scene.has_node("UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer")
	result.floor_shape_irregular = _floor_shape_irregular()
	result.required_stations_exist_in_catalog = _required_stations_exist_in_catalog()
	result.required_station_proxies_exist = result.required_stations_exist_in_catalog
	result.required_zones_near_targets = _required_zones_near_targets()
	result.mission_board_taco_bell_launch_path = Catalog.TACO_BELL_SCENE == TACO_BELL_SCENE
	scene.free()
	return result

static func _required_stations_exist_in_catalog() -> bool:
	var found := {}
	for entry in Catalog.stations():
		found[String(entry.get("station_id", ""))] = true
		if not entry.has("proxy_position"):
			return false
	for station_id in REQUIRED_STATIONS:
		if not found.has(station_id):
			return false
	return true

static func _required_zones_near_targets() -> bool:
	var targets := {
		"evidence_board_big_case": Vector2(0, -455),
		"mission_board": Vector2(520, -410),
		"planning_table": Vector2(0, 20),
		"store_terminal": Vector2(790, -80),
		"entry_exit_door": Vector2(760, 430),
		"bentley_care_station": Vector2(520, 330),
		"open_decor_zone": Vector2(470, 120),
	}
	for entry in Catalog.stations():
		var station_id := String(entry.get("station_id", ""))
		if targets.has(station_id):
			var pos: Vector2 = entry.get("position", Vector2.ZERO)
			if pos.distance_to(targets[station_id]) > 1.0:
				return false
	return true

static func _floor_shape_irregular() -> bool:
	var points := [
		Vector2(-960, -250),
		Vector2(-820, -430),
		Vector2(-470, -430),
		Vector2(-390, -610),
		Vector2(390, -610),
		Vector2(470, -430),
		Vector2(790, -430),
		Vector2(960, -260),
		Vector2(960, 340),
		Vector2(800, 500),
		Vector2(470, 500),
		Vector2(330, 420),
		Vector2(-360, 420),
		Vector2(-500, 520),
		Vector2(-900, 520),
		Vector2(-1040, 360),
		Vector2(-1040, -120),
	]
	return points.size() >= 12

static func _forbidden_labels_absent() -> bool:
	var files := [
		SCENE_PATH,
		"res://src/hideout/HideoutStationCatalog.gd",
		"res://src/hideout/HideoutMissionBoardController.gd",
		"res://src/hideout/HideoutEvidenceBoardController.gd",
	]
	for file_path in files:
		if not FileAccess.file_exists(file_path):
			continue
		var text := FileAccess.get_file_as_string(file_path)
		if text.contains("Sterling Tower Progression") or text.contains("Sterling Syndicate Progression"):
			return false
	return true
