extends RefCounted
class_name HideoutPhase0MD3Validator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md3_true_decorating_mode.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md3_true_decorating_mode.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")
const StoreController = preload("res://src/hideout/HideoutStoreController.gd")
const PlacementValidator = preload("res://src/hideout/HideoutDecorPlacementValidator.gd")

static func validate() -> Dictionary:
	var result := {
		"phase": "0M-D3",
		"passed": true,
		"errors": [],
		"checks": {},
	}
	var checks: Dictionary = result["checks"]
	var scene_text := _read(HIDEOUT_SCENE)
	var manager_text := _read("res://src/hideout/HideoutManager.gd")
	var decor_text := _read("res://src/hideout/HideoutDecorationController.gd")
	var mode_text := _read("res://src/hideout/HideoutDecoratingModeController.gd")
	var store_text := _read("res://src/hideout/HideoutStoreController.gd")
	var placed_text := _read("res://src/hideout/HideoutPlacedDecorItem.gd")
	var grid_text := _read("res://src/hideout/HideoutDecorGridOverlay.gd")
	var validator_text := _read("res://src/hideout/HideoutDecorPlacementValidator.gd")
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	checks["hideout_scene_exists_and_loads"] = ResourceLoader.exists(HIDEOUT_SCENE) and load(HIDEOUT_SCENE) != null
	checks["taco_bell_scenes_exist"] = FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["decorating_mode_controller_exists"] = FileAccess.file_exists("res://src/hideout/HideoutDecoratingModeController.gd") and scene_text.contains("HideoutDecoratingModeController")
	checks["decorating_mode_hud_exists"] = mode_text.contains("DecoratingModeHUD") and mode_text.contains("Decorating Mode")
	checks["grid_overlay_exists"] = FileAccess.file_exists("res://src/hideout/HideoutDecorGridOverlay.gd") and grid_text.contains("_draw")
	checks["enter_click_action_exists"] = decor_text.contains("decor_enter_click_to_place_mode")
	checks["enter_click_routes_to_controller"] = manager_text.contains("decor_enter_click_to_place_mode") and manager_text.contains("enter_decorating_mode")
	checks["snap_grid_size_16"] = mode_text.contains("snap_grid_size := 16") and validator_text.contains("snap_world_position")
	checks["preview_ghost_code_exists"] = mode_text.contains("DecorPlacementPreview") and mode_text.contains("GhostPreviewPolygon")
	checks["rotation_increment_45"] = mode_text.contains("rotate_preview(45.0)") and mode_text.contains("rotate_preview(-45.0)")
	checks["placeable_metadata_exists"] = store_text.contains("footprint_width_px") and store_text.contains("blocks_player") and store_text.contains("\"snap_mode\"")
	checks["every_store_decor_item_has_footprint"] = _all_store_items_have(["footprint_width_px", "footprint_height_px", "blocks_player", "snap_mode", "placement_category"])
	checks["no_place_zones_exist"] = PlacementValidator.no_place_zones().size() >= 20
	checks["station_proxy_no_place_zones_exist"] = _zone_ids_have(["mission_board", "planning_table", "store_terminal", "open_decor_zone_proxy", "loot_crate_drop_zone", "bentley_care_station"])
	checks["door_player_boundary_corridor_zones_exist"] = _zone_ids_have(["entry_exit_door", "player_spawn", "boundary_margin_north", "central_planning_path", "east_store_access_path"])
	checks["overlap_prevention_exists"] = validator_text.contains("overlaps placed decor") and validator_text.contains("footprint.intersects")
	checks["nearest_open_spot_search_exists"] = validator_text.contains("find_nearest_valid_position") and validator_text.contains("nearest_open")
	checks["floor_standing_decor_collision_exists"] = placed_text.contains("StaticBody2D") and placed_text.contains("PlayerBlockingDecorCollision") and placed_text.contains("walls_layer_bitmask")
	checks["placed_item_selectable_script_exists"] = FileAccess.file_exists("res://src/hideout/HideoutPlacedDecorItem.gd") and placed_text.contains("decor_clicked")
	checks["placed_item_move_logic_exists"] = mode_text.contains("start_moving_placed_item") and mode_text.contains("_update_placed_item")
	checks["placed_item_remove_logic_exists"] = mode_text.contains("remove_selected_placed_item") and manager_text.contains("decor_remove_selected")
	checks["wall_snap_zones_exist"] = PlacementValidator.wall_snap_zones().size() >= 4 and validator_text.contains("wall_snap_west")
	checks["open_decor_area_still_opens"] = manager_text.contains("\"open_decor_zone\"") and decor_text.contains("Open Decor Area")
	checks["store_purchase_still_adds_inventory"] = store_text.contains("purchase_item") and store_text.contains("added to decor inventory")
	checks["station_interactions_remain_wired"] = Catalog.stations().size() >= 18
	checks["mission_board_launch_preserved"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["pause_exit_hideout_preserved"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["gameplay_art_separation_preserved"] = _scene_has_nodes(HIDEOUT_SCENE, ["GameplayRoot", "ArtRoot", "UI", "GameplayRoot/Managers/HideoutManager", "ArtRoot/World/DecorationLayer"])
	checks["monogon_readiness_preserved"] = scene_text.contains("GameplayRoot") and scene_text.contains("ArtRoot") and not scene_text.contains("Monogon")
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON)
	for key in checks.keys():
		if checks[key] != true:
			result["errors"].append("Check failed: %s" % key)
	result["passed"] = result["errors"].is_empty()
	return result

static func _all_store_items_have(keys: Array[String]) -> bool:
	for item in StoreController.ITEMS:
		for key in keys:
			if not item.has(key):
				return false
	return true

static func _zone_ids_have(ids: Array[String]) -> bool:
	var present := {}
	for zone in PlacementValidator.no_place_zones():
		present[String(zone.get("zone_id", ""))] = true
	for id in ids:
		if not present.has(id):
			return false
	return true

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
