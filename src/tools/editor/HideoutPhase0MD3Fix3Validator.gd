extends RefCounted
class_name HideoutPhase0MD3Fix3Validator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md3_fix3_click_move_no_place_tuning.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md3_fix3_click_move_no_place_tuning.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")
const PlacementValidator = preload("res://src/hideout/HideoutDecorPlacementValidator.gd")

static func validate() -> Dictionary:
	var result := {"phase": "0M-D3-FIX3", "passed": true, "errors": [], "checks": {}}
	var checks: Dictionary = result["checks"]
	var mode_text := _read("res://src/hideout/HideoutDecoratingModeController.gd")
	var item_text := _read("res://src/hideout/HideoutPlacedDecorItem.gd")
	var decor_text := _read("res://src/hideout/HideoutDecorationController.gd")
	var validator_text := _read("res://src/hideout/HideoutDecorPlacementValidator.gd")
	var scene_text := _read(HIDEOUT_SCENE)
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	var unhandled_body := _function_body(mode_text, "_unhandled_input")
	var click_body := _function_body(mode_text, "_on_placed_decor_clicked")
	var move_body := _function_body(mode_text, "start_moving_placed_item")
	var confirm_body := _function_body(mode_text, "confirm_current_placement")
	var remove_selected_body := _function_body(mode_text, "remove_selected_placed_item")
	var remove_by_id_body := _function_body(mode_text, "remove_placed_item_by_id")
	var clear_body := _function_body(mode_text, "clear_all_placed_decor")
	var decor_remove_body := _function_body(decor_text, "remove_selected")
	var decor_clear_body := _function_body(decor_text, "clear_all")

	checks["hideout_scene_loads"] = ResourceLoader.exists(HIDEOUT_SCENE) and load(HIDEOUT_SCENE) != null
	checks["taco_bell_scenes_exist"] = FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["left_click_routes_to_move"] = unhandled_body.contains("MOUSE_BUTTON_LEFT") and unhandled_body.contains("start_moving_placed_item(hit_id)") and click_body.contains("start_moving_placed_item(placed_id)")
	checks["placed_item_click_consumes_event"] = item_text.contains("set_input_as_handled()") and item_text.contains("decor_clicked.emit(placed_id)")
	checks["placed_item_click_not_remove"] = not click_body.contains("remove") and not click_body.contains("delete") and not click_body.contains("clear_all")
	checks["click_ignored_while_carrying"] = click_body.contains("carrying_item_id != \"\"") and click_body.contains("return")
	checks["start_moving_preserves_placed_id"] = move_body.contains("carrying_existing_placed_id = placed_id") and move_body.contains("selected_placed_id = placed_id") and move_body.contains("original_position_before_move") and move_body.contains("original_rotation_before_move")
	checks["confirm_move_updates_existing"] = confirm_body.contains("_update_placed_item(carrying_existing_placed_id") and confirm_body.contains("else:") and confirm_body.contains("_create_placed_item")
	checks["moving_ignores_own_footprint"] = mode_text.contains("moving_id := carrying_existing_placed_id") and validator_text.contains("moving_placed_id") and validator_text.contains("continue")
	checks["canonical_remove_method_exists"] = remove_by_id_body != "" and remove_by_id_body.contains("state_controller.set(\"placed_items\"") and remove_by_id_body.contains("_update_hud()")
	checks["remove_selected_uses_canonical"] = remove_selected_body.contains("remove_placed_item_by_id(selected_placed_id")
	checks["r_delete_hud_remove_use_canonical"] = unhandled_body.contains("KEY_R, KEY_DELETE") and unhandled_body.contains("remove_selected_placed_item()") and mode_text.contains("func _on_hud_remove_pressed") and mode_text.contains("remove_selected_placed_item()")
	checks["open_decor_remove_uses_canonical"] = decor_remove_body.contains("remove_placed_item_by_id(selected_id")
	checks["clear_decor_uses_canonical"] = clear_body.contains("remove_placed_item_by_id(placed_id") and decor_clear_body.contains("remove_placed_item_by_id(placed_id")
	checks["remove_keeps_owned_inventory"] = not remove_by_id_body.contains("owned_placeable_items") and not decor_text.contains("owned_placeable_items.erase")
	checks["remove_refreshes_available_hud"] = remove_by_id_body.contains("rebuild_placed_visuals()") and remove_by_id_body.contains("_update_hud()") and mode_text.contains("_available_owned_item_ids")
	checks["broad_access_rules_removed"] = not validator_text.contains("CORRIDOR_ZONE_MARGIN_PX") and not validator_text.contains("walking path") and not validator_text.contains("_access_path") and not validator_text.contains("access\"")
	checks["station_zones_are_direct_proxy"] = validator_text.contains("DIRECT_PROXY_MARGIN_PX := 6") and validator_text.contains("Mission Board direct proxy") and validator_text.contains("Open Decor Area direct proxy")
	checks["hard_safety_preserved"] = validator_text.contains("entry_exit_door") and validator_text.contains("player_spawn") and validator_text.contains("boundary_margin")
	checks["placed_item_overlap_preserved"] = validator_text.contains("overlaps placed decor")
	checks["wall_snap_rules_preserved"] = validator_text.contains("wall_snap_zones") and validator_text.contains("_wall_rect_contains")
	checks["station_interactions_remain_wired"] = Catalog.stations().size() >= 18
	checks["mission_board_launch_preserved"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["pause_exit_hideout_path"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["gameplay_art_separation_preserved"] = scene_text.contains("GameplayRoot") and scene_text.contains("ArtRoot")
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON)

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
