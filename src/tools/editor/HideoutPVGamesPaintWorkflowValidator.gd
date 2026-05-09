@tool
extends EditorScript
class_name HideoutPVGamesPaintWorkflowValidator

const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const SOURCE_TACO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REDESIGN_TACO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const GUIDE_SCRIPT := "res://src/tools/editor/HideoutEditorGuideLayer.gd"
const FLOOR_TILESET := "res://assets/tilesets/pvgames_paintable/PVGamesFloorPaintVisualTileset.tres"
const WALL_TILESET := "res://assets/tilesets/pvgames_paintable/PVGamesWallPaintVisualTileset.tres"
const HOW_TO := "res://docs/reports/pvgames_how_to_paint_and_place_art_now.md"
const INVENTORY_JSON := "res://docs/reports/hideout_existing_pvgames_visual_nodes_inventory.json"
const ATLAS_JSON := "res://docs/reports/pvgames_paintable_atlas_candidates.json"
const MAIN_JSON := "res://docs/reports/hideout_phase_0mb3_pvgames_paintable_atlas_and_editor_guide.json"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(FileAccess.file_exists(HIDEOUT), "HideoutHub scene missing.", failures)
	_require(FileAccess.file_exists(SOURCE_TACO), "Protected Taco Bell source scene missing.", failures)
	_require(FileAccess.file_exists(REDESIGN_TACO), "Protected Taco Bell redesign scene missing.", failures)
	_require(FileAccess.file_exists(GUIDE_SCRIPT), "Editor guide script missing.", failures)
	_require(FileAccess.file_exists(FLOOR_TILESET), "Floor paint TileSet missing.", failures)
	_require(FileAccess.file_exists(WALL_TILESET), "Wall paint TileSet missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to guide missing.", failures)
	_require(FileAccess.file_exists(INVENTORY_JSON), "PVGames visual inventory missing.", failures)
	_require(FileAccess.file_exists(ATLAS_JSON), "Atlas candidates report missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON), "Main report JSON missing.", failures)

	var hideout_text := FileAccess.get_file_as_string(HIDEOUT)
	_require(hideout_text.contains("EditorGuideLayer"), "EditorGuideLayer missing from HideoutHub.", failures)
	_require(hideout_text.contains("PlayableFloorFootprint"), "Floor footprint guide missing.", failures)
	_require(hideout_text.contains("PlayableBoundaryOutline"), "Boundary outline guide missing.", failures)
	_require(hideout_text.contains("GuideLabel_MissionBoard"), "Station labels missing.", failures)
	_require(hideout_text.contains("PVGamesFloorPaintLayer"), "Floor paint layer missing.", failures)
	_require(hideout_text.contains("PVGamesWallPaintLayer"), "Wall paint layer missing.", failures)
	_require(not _guide_block_contains_collision(hideout_text), "EditorGuideLayer contains collision/gameplay nodes.", failures)
	_require(not _gameplayroot_contains_pvgames_art(hideout_text), "PVGames art appears under GameplayRoot.", failures)
	_require(not _visible_contact_sheet_texture_in_hideout(hideout_text), "Visible contact-sheet texture is referenced by HideoutHub.", failures)
	_require(hideout_text.contains("collision_enabled = false"), "TileMap paint layer collision is not explicitly disabled.", failures)

	var floor_text := FileAccess.get_file_as_string(FLOOR_TILESET)
	var wall_text := FileAccess.get_file_as_string(WALL_TILESET)
	_require(not floor_text.contains("docs/reports/pvgames_palettes"), "Floor TileSet uses contact sheet source.", failures)
	_require(not wall_text.contains("docs/reports/pvgames_palettes"), "Wall TileSet uses contact sheet source.", failures)
	_require(floor_text.contains("assets/tilesets/cyber_city_core_tilesets"), "Floor TileSet does not use real PVGames sources.", failures)
	_require(wall_text.contains("assets/tilesets/cyber_city_core_tilesets"), "Wall TileSet does not use real PVGames sources.", failures)
	if floor_text.contains("physics_layer") or wall_text.contains("physics_layer"):
		warnings.append("TileSet contains physics layer text; inspect to ensure visual-only.")

	var main := _read_json_dict(MAIN_JSON)
	_require(bool(main.get("contact_sheets_used_as_sources", true)) == false, "Main report says contact sheets were used as sources.", failures)
	_require(bool(main.get("gameplayroot_touched", true)) == false, "Main report says GameplayRoot was touched.", failures)
	_require(bool(main.get("station_proxies_touched", true)) == false, "Main report says station proxies were touched.", failures)

	return {
		"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL",
		"failures": failures,
		"warnings": warnings,
	}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _guide_block_contains_collision(scene_text: String) -> bool:
	var start := scene_text.find("[node name=\"EditorGuideLayer\"")
	if start < 0:
		return false
	var end := scene_text.find("[node name=\"PVGamesFloorPaintLayer\"", start)
	if end < 0:
		end = scene_text.length()
	var guide_block := scene_text.substr(start, end - start)
	return guide_block.contains("CollisionShape2D") or guide_block.contains("CollisionPolygon2D") or guide_block.contains("StaticBody2D") or guide_block.contains("Area2D")


func _gameplayroot_contains_pvgames_art(scene_text: String) -> bool:
	var lines := scene_text.split("\n")
	for line in lines:
		if line.begins_with("[node ") and line.contains("parent=\"GameplayRoot") and (line.contains("PVGames") or line.contains("PVG_") or line.contains("EditorGuide")):
			return true
	return false


func _visible_contact_sheet_texture_in_hideout(scene_text: String) -> bool:
	return scene_text.contains("res://docs/reports/pvgames_palettes/") or scene_text.contains("pvgames_birthday_build_curated_palette.png")
