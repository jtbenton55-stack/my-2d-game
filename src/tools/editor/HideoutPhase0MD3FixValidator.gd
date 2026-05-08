extends RefCounted
class_name HideoutPhase0MD3FixValidator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md3_fix_decorating_runtime.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md3_fix_decorating_runtime.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")

static func validate() -> Dictionary:
	var result := {
		"phase": "0M-D3-FIX",
		"passed": true,
		"errors": [],
		"checks": {},
	}
	var checks: Dictionary = result["checks"]
	var mode_text := _read("res://src/hideout/HideoutDecoratingModeController.gd")
	var manager_text := _read("res://src/hideout/HideoutManager.gd")
	var store_text := _read("res://src/hideout/HideoutStoreController.gd")
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	checks["hideout_scene_loads"] = ResourceLoader.exists(HIDEOUT_SCENE) and load(HIDEOUT_SCENE) != null
	checks["taco_bell_scenes_exist"] = FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["hud_readable_title"] = mode_text.contains("Decorating Mode") and mode_text.contains("Title")
	checks["hud_exit_button"] = mode_text.contains("Exit Decorating Mode") and mode_text.contains("_on_hud_exit_pressed")
	checks["hud_cancel_button"] = mode_text.contains("Cancel Placement") and mode_text.contains("_on_hud_cancel_pressed")
	checks["hud_remove_button"] = mode_text.contains("Remove Selected") and mode_text.contains("_on_hud_remove_pressed")
	checks["hud_item_picker"] = mode_text.contains("Available Owned Items") and mode_text.contains("_available_owned_item_ids") and mode_text.contains("_on_hud_item_button_pressed")
	checks["preview_direct_snapped_mouse"] = mode_text.contains("current_snapped_position = PlacementValidator.snap_world_position(world_pos, snap_grid_size)") and mode_text.contains("preview_node.position = current_snapped_position")
	checks["nearest_not_in_hover"] = _function_body(mode_text, "validate_current_preview_position").find("find_nearest_valid_position") == -1 and _function_body(mode_text, "refresh_preview_from_mouse").find("find_nearest_valid_position") == -1
	checks["nearest_only_in_confirm"] = _function_body(mode_text, "confirm_current_placement").find("find_nearest_valid_position") != -1
	checks["placed_item_hit_test"] = mode_text.contains("_hit_test_placed_item") and mode_text.contains("footprint_rect") and mode_text.contains("rect.has_point")
	checks["start_moving_exists"] = mode_text.contains("func start_moving_placed_item")
	checks["move_preserves_placed_id"] = mode_text.contains("_update_placed_item(carrying_existing_placed_id") and not _function_body(mode_text, "start_moving_placed_item").contains("_create_placed_item")
	checks["remove_selected_exists"] = mode_text.contains("func remove_selected_placed_item") and mode_text.contains("KEY_R, KEY_DELETE")
	checks["exit_cancel_paths_exist"] = mode_text.contains("func cancel_current_placement") and mode_text.contains("func exit_decorating_mode") and mode_text.contains("_on_hud_exit_pressed")
	checks["store_purchase_still_adds_inventory"] = store_text.contains("purchase_item") and store_text.contains("added to decor inventory")
	checks["station_interactions_remain_wired"] = Catalog.stations().size() >= 18
	checks["mission_board_launch_preserved"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["pause_exit_hideout_path"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["gameplay_art_separation_preserved"] = _scene_has_nodes(HIDEOUT_SCENE, ["GameplayRoot", "ArtRoot", "UI", "ArtRoot/World/DecorationLayer"])
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON)
	checks["manager_lazy_routes_to_controller"] = manager_text.contains("decor_enter_click_to_place_mode") and manager_text.contains("HideoutDecoratingModeController.gd")
	for key in checks.keys():
		if checks[key] != true:
			result["errors"].append("Check failed: %s" % key)
	result["passed"] = result["errors"].is_empty()
	return result

static func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

static func _function_body(text: String, func_name: String) -> String:
	var start := text.find("func %s" % func_name)
	if start == -1:
		return ""
	var next := text.find("\nfunc ", start + 6)
	if next == -1:
		return text.substr(start)
	return text.substr(start, next - start)

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
