extends RefCounted
class_name HideoutPhase0MD3Fix2Validator

const HIDEOUT_SCENE := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REPORT_MD := "res://docs/reports/hideout_phase_0md3_fix2_runtime_stability.md"
const REPORT_JSON := "res://docs/reports/hideout_phase_0md3_fix2_runtime_stability.json"

const Catalog = preload("res://src/hideout/HideoutStationCatalog.gd")
const MissionBoard = preload("res://src/hideout/HideoutMissionBoardController.gd")
const PlacementValidator = preload("res://src/hideout/HideoutDecorPlacementValidator.gd")

static func validate() -> Dictionary:
	var result := {"phase": "0M-D3-FIX2", "passed": true, "errors": [], "checks": {}}
	var checks: Dictionary = result["checks"]
	var mode_text := _read("res://src/hideout/HideoutDecoratingModeController.gd")
	var validator_text := _read("res://src/hideout/HideoutDecorPlacementValidator.gd")
	var scene_manager_text := _read("res://src/autoload/SceneManager.gd")
	var hit_body := _function_body(mode_text, "_hit_test_placed_item")
	var update_body := _function_body(mode_text, "_update_placed_item")
	checks["hideout_scene_loads"] = ResourceLoader.exists(HIDEOUT_SCENE) and load(HIDEOUT_SCENE) != null
	checks["taco_bell_scenes_exist"] = FileAccess.file_exists(TACO_BELL_SCENE) and FileAccess.file_exists(PROTECTED_TACO_BELL_SCENE)
	checks["hit_test_exists"] = hit_body != ""
	checks["hit_test_no_dictionary_assignment"] = hit_body.find("[\"") == -1 and hit_body.find("] =") == -1
	checks["hit_test_returns_placed_id"] = hit_body.contains("return best_id") and hit_body.contains("var best_id")
	checks["no_temp_hit_fields"] = not hit_body.contains("_distance") and not hit_body.contains("hit_score") and not hit_body.contains("[\"rect\"") and not hit_body.contains("[\"selected\"")
	checks["updates_duplicate_then_assign"] = update_body.contains("placed_items[i] = placed") and update_body.contains("state_controller.set(\"placed_items\"")
	checks["start_moving_exists"] = mode_text.contains("func start_moving_placed_item")
	checks["move_preserves_placed_id"] = mode_text.contains("_update_placed_item(carrying_existing_placed_id")
	checks["move_ignores_own_footprint"] = mode_text.contains("moving_id := carrying_existing_placed_id") and validator_text.contains("moving_placed_id")
	checks["remove_selected_exists"] = mode_text.contains("func remove_selected_placed_item") and mode_text.contains("KEY_R, KEY_DELETE")
	checks["hud_text_buttons_exist"] = mode_text.contains("Decorating Mode") and mode_text.contains("Exit Decorating Mode") and mode_text.contains("Remove Selected")
	checks["cleanup_exists"] = mode_text.contains("hide_grid") and mode_text.contains("hud_node.hide") and mode_text.contains("_remove_preview") and mode_text.contains("selected_placed_id = \"\"")
	checks["display_audit_no_global_mutation"] = not _has_display_mutation(mode_text)
	checks["station_padding_reduced"] = int(PlacementValidator.BLOCKED_ZONE_MARGIN_PX) <= 12
	checks["critical_protection_preserved"] = int(PlacementValidator.CRITICAL_ZONE_MARGIN_PX) >= 20 and int(PlacementValidator.CORRIDOR_ZONE_MARGIN_PX) >= 16
	checks["station_interactions_remain_wired"] = Catalog.stations().size() >= 18
	checks["mission_board_launch_preserved"] = MissionBoard.TACO_BELL_SCENE == TACO_BELL_SCENE
	checks["pause_exit_hideout_path"] = scene_manager_text.contains("const HIDEOUT_SCENE := \"res://scenes/hideout/HideoutHub.tscn\"")
	checks["reports_exist"] = FileAccess.file_exists(REPORT_MD) and FileAccess.file_exists(REPORT_JSON)
	for key in checks.keys():
		if checks[key] != true:
			result["errors"].append("Check failed: %s" % key)
	result["passed"] = result["errors"].is_empty()
	return result

static func _has_display_mutation(text: String) -> bool:
	var forbidden := [
		"ProjectSettings.set_setting(\"display/window",
		"stretch_mode",
		"stretch_aspect",
		".zoom =",
		"content_scale",
		"global_canvas_transform =",
		"canvas_transform =",
		"texture_filter =",
	]
	for token in forbidden:
		if text.contains(token):
			return true
	return false

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
