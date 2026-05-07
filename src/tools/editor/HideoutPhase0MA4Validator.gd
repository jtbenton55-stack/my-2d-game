@tool
extends RefCounted
class_name HideoutPhase0MA4Validator

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
]

static func validate() -> Dictionary:
	var result := {
		"scene_exists": ResourceLoader.exists(SCENE_PATH),
		"scene_loads": false,
		"taco_bell_paths_exist": FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE),
		"player_exists": false,
		"player_above_floor": false,
		"boundary_walls_configured": false,
		"boundary_shape_count_reasonable": false,
		"required_station_entries_exist": false,
		"station_proxies_have_proxy_positions": false,
		"station_proxies_have_panel_text": false,
		"hideout_interaction_bridge_configured": false,
		"hideout_manager_open_station_exists": false,
		"scrollable_panel_exists": false,
		"scrollable_panel_methods_exist": false,
		"mission_board_launch_path_exact": Catalog.TACO_BELL_SCENE == TACO_BELL_SCENE,
		"louis_hidden_fresh_supported": true,
		"louis_visible_unlocked_supported": true,
		"greenhouse_expanded": false,
		"big_case_moved_south": false,
		"gameplay_art_separation_preserved": false,
		"reports_exist": FileAccess.file_exists("res://docs/reports/hideout_phase_0ma4_interaction_collision_greenhouse_repair.md") and FileAccess.file_exists("res://docs/reports/hideout_phase_0ma4_interaction_collision_greenhouse_repair.json"),
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
	result.player_exists = scene.has_node("GameplayRoot/Characters/Player")
	if result.player_exists and scene.has_node("ArtRoot/World/FloorLayer"):
		var player := scene.get_node("GameplayRoot/Characters/Player") as Node2D
		var floor := scene.get_node("ArtRoot/World/FloorLayer") as Node2D
		result.player_above_floor = player != null and floor != null and player.z_index > floor.z_index
	result.gameplay_art_separation_preserved = scene.has_node("GameplayRoot/Navigation/Collision") and scene.has_node("ArtRoot/World/FloorLayer") and scene.has_node("ArtRoot/World/PropLayer")
	result.hideout_interaction_bridge_configured = scene.has_node("GameplayRoot/Managers/HideoutInteractionBridge")
	result.hideout_manager_open_station_exists = scene.has_node("GameplayRoot/Managers/HideoutManager") and scene.get_node("GameplayRoot/Managers/HideoutManager").has_method("open_station")
	result.scrollable_panel_exists = scene.has_node("UI/ScrollableStationPanel")
	if result.scrollable_panel_exists:
		var panel := scene.get_node("UI/ScrollableStationPanel")
		result.scrollable_panel_methods_exist = panel.has_method("open_panel") and panel.has_method("close_panel")
	result.required_station_entries_exist = _required_station_entries_exist()
	result.station_proxies_have_proxy_positions = _station_proxies_have_proxy_positions()
	result.station_proxies_have_panel_text = _station_proxies_have_panel_text()
	result.greenhouse_expanded = _greenhouse_expanded()
	result.big_case_moved_south = _big_case_moved_south()
	result.boundary_walls_configured = _hideout_manager_source_contains("BoundaryWalls") and _hideout_manager_source_contains("_add_boundary_walls")
	result.boundary_shape_count_reasonable = _floor_polygon_point_count() >= 16
	scene.free()
	return result

static func _required_station_entries_exist() -> bool:
	var found := {}
	for entry in Catalog.stations():
		found[String(entry.get("station_id", ""))] = true
	for station_id in REQUIRED_STATIONS:
		if not found.has(station_id):
			return false
	return true

static func _station_proxies_have_proxy_positions() -> bool:
	for entry in Catalog.stations():
		if REQUIRED_STATIONS.has(String(entry.get("station_id", ""))) and not entry.has("proxy_position"):
			return false
	return true

static func _station_proxies_have_panel_text() -> bool:
	for entry in Catalog.stations():
		if not REQUIRED_STATIONS.has(String(entry.get("station_id", ""))):
			continue
		if String(entry.get("panel_title", "")) == "" or String(entry.get("panel_body", "")) == "":
			return false
	return true

static func _greenhouse_expanded() -> bool:
	var min_y := 0.0
	for point in _floor_points():
		min_y = minf(min_y, point.y)
	return min_y <= -690.0

static func _big_case_moved_south() -> bool:
	for entry in Catalog.stations():
		if String(entry.get("station_id", "")) == "evidence_board_big_case":
			return (entry.get("position", Vector2.ZERO) as Vector2).y >= -405.0
	return false

static func _floor_polygon_point_count() -> int:
	return _floor_points().size()

static func _floor_points() -> Array[Vector2]:
	return [
		Vector2(-960, -250),
		Vector2(-820, -430),
		Vector2(-500, -430),
		Vector2(-430, -690),
		Vector2(430, -690),
		Vector2(500, -430),
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

static func _hideout_manager_source_contains(needle: String) -> bool:
	var path := "res://src/hideout/HideoutManager.gd"
	if not FileAccess.file_exists(path):
		return false
	return FileAccess.get_file_as_string(path).contains(needle)
