@tool
extends EditorScript
class_name HideoutDepthSorting0MB5Validator

const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const SOURCE_TACO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REDESIGN_TACO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const HIDEOUT_MANAGER := "res://src/hideout/HideoutManager.gd"
const EDITOR_GUIDE_SCRIPT := "res://src/tools/editor/HideoutEditorGuideLayer.gd"
const VISUAL_HELPER := "res://src/hideout/HideoutPVGamesVisualHelper.gd"
const MAIN_MD := "res://docs/reports/hideout_phase_0mb5_runtime_graybox_cleanup_depth_sorting.md"
const MAIN_JSON := "res://docs/reports/hideout_phase_0mb5_runtime_graybox_cleanup_depth_sorting.json"
const QUARANTINE_MD := "res://docs/reports/hideout_phase_0mb5_quarantined_visuals.md"
const QUARANTINE_JSON := "res://docs/reports/hideout_phase_0mb5_quarantined_visuals.json"
const Y_SORT_AUDIT := "res://docs/reports/hideout_phase_0mb5_y_sort_origin_audit.md"
const TEST_SCENE := "res://scenes/hideout/tools/HideoutDepthSortTest_0MB5.tscn"

const REQUIRED_PAINT_LAYERS := [
	"PVGamesCatalogGroundRoadPaintLayer",
	"PVGamesCatalogWallPaintLayer",
	"PVGamesCatalogLargeStructurePaintLayer",
	"PVGamesCatalogPropSignPaintLayer",
]

const REQUIRED_DEPTH_LAYERS := [
	"PVGamesBehindGroundPaintLayer",
	"PVGamesBehindWallBackdropPaintLayer",
	"PVGamesOccludableWallPaintLayer",
	"PVGamesOccludablePropPaintLayer",
	"PVGamesForegroundOverlayPaintLayer",
]


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(FileAccess.file_exists(HIDEOUT), "HideoutHub scene missing.", failures)
	_require(FileAccess.file_exists(SOURCE_TACO), "Protected Taco Bell source scene missing.", failures)
	_require(FileAccess.file_exists(REDESIGN_TACO), "Protected Taco Bell redesign scene missing.", failures)
	_require(FileAccess.file_exists(HIDEOUT_MANAGER), "HideoutManager missing.", failures)
	_require(FileAccess.file_exists(EDITOR_GUIDE_SCRIPT), "EditorGuideLayer script missing.", failures)
	_require(FileAccess.file_exists(VISUAL_HELPER), "PVGames visual helper missing.", failures)
	_require(FileAccess.file_exists(MAIN_MD), "Main markdown report missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON), "Main JSON report missing.", failures)
	_require(FileAccess.file_exists(QUARANTINE_MD), "Quarantine markdown report missing.", failures)
	_require(FileAccess.file_exists(QUARANTINE_JSON), "Quarantine JSON report missing.", failures)
	_require(FileAccess.file_exists(Y_SORT_AUDIT), "Y-sort audit missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Depth sort test scene missing.", failures)

	var hideout_text := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	var manager_text := FileAccess.get_file_as_string(HIDEOUT_MANAGER) if FileAccess.file_exists(HIDEOUT_MANAGER) else ""
	var guide_text := FileAccess.get_file_as_string(EDITOR_GUIDE_SCRIPT) if FileAccess.file_exists(EDITOR_GUIDE_SCRIPT) else ""
	var helper_text := FileAccess.get_file_as_string(VISUAL_HELPER) if FileAccess.file_exists(VISUAL_HELPER) else ""
	var test_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""

	_require(hideout_text.contains("HideoutHubRoot"), "Hideout root missing.", failures)
	_require(hideout_text.contains("GameplayRoot"), "GameplayRoot missing.", failures)
	_require(hideout_text.contains("ArtRoot"), "ArtRoot missing.", failures)
	_require(hideout_text.contains("ArtRoot/World"), "ArtRoot/World missing.", failures)
	_require(hideout_text.contains("EditorGuideLayer"), "EditorGuideLayer missing.", failures)
	_require(hideout_text.contains("PVG_CatalogPaintLayers"), "0M-B4 catalog paint container missing.", failures)
	for layer_name in REQUIRED_PAINT_LAYERS:
		_require(hideout_text.contains(layer_name), "0M-B4 paint layer missing: %s" % layer_name, failures)
	for layer_name in REQUIRED_DEPTH_LAYERS:
		_require(hideout_text.contains(layer_name), "0M-B5 depth paint layer missing: %s" % layer_name, failures)

	_require(hideout_text.contains("QuarantinedOldPVGamesVisuals_0MB5"), "Old PVGames quarantine container missing.", failures)
	_require(hideout_text.contains("parent=\"ArtRoot/World/QuarantinedOldPVGamesVisuals_0MB5\""), "PVGames helper not under quarantine.", failures)
	_require(hideout_text.contains("enabled = false"), "Quarantined PVGames helper is not disabled in scene.", failures)
	_require(helper_text.contains("@export var enabled := false"), "PVGames helper default is not disabled.", failures)
	_require(manager_text.contains("show_runtime_graybox_debug := false"), "Runtime graybox debug flag missing or not false.", failures)
	_require(manager_text.contains("show_station_proxy_debug_labels := false"), "Station proxy debug label flag missing or not false.", failures)
	_require(manager_text.contains("if not show_runtime_graybox_debug:"), "Graybox build path is not gated.", failures)
	_require(manager_text.contains("proxy_label.visible = show_station_proxy_debug_labels"), "Proxy label visibility is not gated.", failures)
	_require(guide_text.contains("Engine.is_editor_hint()") and guide_text.contains("visible = false"), "EditorGuideLayer script does not hide on play.", failures)

	_require(not _gameplayroot_contains_pvgames_art(hideout_text), "PVGames art appears under GameplayRoot.", failures)
	_require(_depth_layers_under_artroot(hideout_text), "Depth paint layers are not under ArtRoot/World.", failures)
	_require(_all_depth_layers_collision_disabled(hideout_text), "Depth paint layer collision is not explicitly disabled.", failures)
	_require(hideout_text.contains("[node name=\"Player\" parent=\"GameplayRoot/Characters\""), "Player was moved from GameplayRoot/Characters.", failures)
	_require(hideout_text.contains("[node name=\"Stations\" type=\"Node2D\" parent=\"GameplayRoot\""), "Stations node missing or moved.", failures)
	_require(hideout_text.contains("[node name=\"InteractionAreas\" type=\"Node2D\" parent=\"GameplayRoot/Navigation\""), "InteractionAreas node missing or moved.", failures)
	_require(hideout_text.contains("[node name=\"InteractionPrompt\" type=\"Label\" parent=\"UI\""), "Interaction prompt missing.", failures)
	_require(hideout_text.contains("[node name=\"ScrollableStationPanel\" type=\"PanelContainer\" parent=\"UI\""), "Station panel missing.", failures)
	_require(hideout_text.contains("z_index = 80") and hideout_text.contains("z_index = 90"), "Occludable layer z-indexes are not above player.", failures)
	_require(hideout_text.contains("z_index = -300") and hideout_text.contains("z_index = 160"), "Behind/foreground layer z-indexes missing.", failures)

	_require(not test_text.contains("CollisionShape2D"), "Depth test scene contains collision.", failures)
	_require(not test_text.contains("GameplayRoot"), "Depth test scene contains gameplay root.", failures)
	_require(test_text.contains("OccludableWallPaintLayer"), "Depth test scene missing occludable layer.", failures)

	var main_report := _read_dict(MAIN_JSON)
	_require(String(main_report.get("status", "")) in ["PASS", "PARTIAL"], "Main JSON report status missing.", failures)
	_require(bool(main_report.get("taco_bell_scenes_modified", true)) == false, "Report says Taco Bell scenes modified.", failures)
	_require(bool(main_report.get("collision_added", true)) == false, "Report says collision was added.", failures)
	_require(String(main_report.get("chosen_depth_sorting_solution", "")).contains("occludable"), "Depth sorting solution is not documented.", failures)

	if not manager_text.contains("_clear_runtime_graybox_visuals"):
		warnings.append("Runtime graybox cleanup helper not found by name.")

	return {
		"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL",
		"failures": failures,
		"warnings": warnings,
	}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _gameplayroot_contains_pvgames_art(scene_text: String) -> bool:
	for line in scene_text.split("\n"):
		if line.begins_with("[node ") and line.contains("parent=\"GameplayRoot") and (line.contains("PVGames") or line.contains("PVG_") or line.contains("HideoutPVGamesVisual")):
			return true
	return false


func _depth_layers_under_artroot(scene_text: String) -> bool:
	for layer_name in REQUIRED_DEPTH_LAYERS:
		if not scene_text.contains("[node name=\"%s\" type=\"TileMapLayer\" parent=\"ArtRoot/World/PVG_DepthPaintLayers\"]" % layer_name):
			return false
	return true


func _all_depth_layers_collision_disabled(scene_text: String) -> bool:
	for layer_name in REQUIRED_DEPTH_LAYERS:
		var start := scene_text.find("[node name=\"%s\"" % layer_name)
		if start < 0:
			return false
		var next := scene_text.find("\n[node ", start + 1)
		var block := scene_text.substr(start, scene_text.length() - start if next < 0 else next - start)
		if not block.contains("collision_enabled = false"):
			return false
	return true
