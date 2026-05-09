extends RefCounted
class_name HideoutPhase0MBValidator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const PVGAMES_ROOT := "res://assets/tilesets/cyber_city_core_tilesets"
const CORE_1 := PVGAMES_ROOT + "/CyberCity_Core_Tiles_1/CyberCity_Core_Tiles_1"
const CORE_2 := PVGAMES_ROOT + "/CyberCity_Core_Tiles_2/CyberCity_Core_Tiles_2"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0mb_pvgames_visual_dressing.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0mb_pvgames_visual_dressing.json"
const ASSET_REPORT := "res://docs/reports/hideout_phase_0mb_pvgames_asset_selection.md"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")

static func validate() -> Dictionary:
	var result := {"phase": "0M-B", "passed": true, "errors": [], "checks": {}}
	var checks: Dictionary = result["checks"]
	var scene_text := _read(HIDEOUT_SCENE)
	var helper_text := _read("res://src/hideout/HideoutPVGamesVisualHelper.gd")
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	var scene := load(HIDEOUT_SCENE) as PackedScene
	var root := scene.instantiate() if scene != null else null

	checks["hideout_scene_loads"] = scene != null and root != null
	checks["artroot_exists"] = _has_node(root, "ArtRoot")
	checks["world_exists"] = _has_node(root, "ArtRoot/World")
	checks["floor_layer_exists"] = _has_node(root, "ArtRoot/World/FloorLayer")
	checks["wall_layer_exists"] = _has_node(root, "ArtRoot/World/WallLayer")
	checks["prop_layer_exists"] = _has_node(root, "ArtRoot/World/PropLayer")
	checks["decoration_layer_exists"] = _has_node(root, "ArtRoot/World/DecorationLayer")
	checks["collectible_layer_exists"] = _has_node(root, "ArtRoot/World/CollectibleLayer")
	checks["foreground_layer_exists"] = _has_node(root, "ArtRoot/World/ForegroundLayer")
	checks["lighting_layer_exists"] = _has_node(root, "ArtRoot/World/LightingLayer")
	checks["pvgames_root_exists"] = DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(PVGAMES_ROOT))
	checks["pvgames_helper_under_world"] = _has_node(root, "ArtRoot/World/HideoutPVGamesVisualHelper") and scene_text.contains("HideoutPVGamesVisualHelper.gd")
	checks["curated_assets_exist"] = _curated_assets_exist(helper_text)
	checks["pvgames_collision_disabled"] = not helper_text.contains("CollisionShape2D") and not helper_text.contains("StaticBody2D") and not helper_text.contains("Area2D") and not helper_text.contains("TileMap")
	checks["gameplayroot_exists"] = _has_node(root, "GameplayRoot")
	checks["player_exists"] = _has_node(root, "GameplayRoot/Characters/Player")
	checks["collision_nodes_exist"] = _has_node(root, "GameplayRoot/Navigation/Collision")
	checks["stations_root_exists"] = _has_node(root, "GameplayRoot/Stations")
	checks["required_station_ids_catalogued"] = _required_station_ids_present()
	checks["missionboard_launch_preserved"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["pause_exit_path_preserved"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["decorating_mode_controller_script_exists"] = FileAccess.file_exists("res://src/hideout/HideoutDecoratingModeController.gd")
	checks["open_decor_zone_catalogued"] = not Catalog.station_by_id("open_decor_zone").is_empty()
	checks["store_terminal_catalogued"] = not Catalog.station_by_id("store_terminal").is_empty()
	checks["store_controller_exists"] = _has_node(root, "GameplayRoot/Managers/HideoutStoreController")
	checks["taco_bell_scenes_exist"] = FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON) and FileAccess.file_exists(ASSET_REPORT)

	for key in checks.keys():
		if checks[key] != true:
			result["errors"].append("Check failed: %s" % key)
	result["passed"] = result["errors"].is_empty()
	if root != null:
		root.free()
	return result

static func _has_node(root: Node, path: String) -> bool:
	return root != null and root.get_node_or_null(path) != null

static func _required_station_ids_present() -> bool:
	var required := [
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
		"greenhouse_alcove",
	]
	for station_id in required:
		if Catalog.station_by_id(station_id).is_empty():
			return false
	return Catalog.stations().size() >= 18

static func _curated_assets_exist(helper_text: String) -> bool:
	var regex := RegEx.new()
	regex.compile("(CORE_[12]) \\+ \"([^\"]+\\.png)\"")
	var matches := regex.search_all(helper_text)
	if matches.size() < 25:
		return false
	for match_result in matches:
		var core_name := String(match_result.get_string(1))
		var suffix := String(match_result.get_string(2))
		var core := CORE_1 if core_name == "CORE_1" else CORE_2
		var full_path := core + suffix
		if not FileAccess.file_exists(full_path):
			return false
	return true

static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
