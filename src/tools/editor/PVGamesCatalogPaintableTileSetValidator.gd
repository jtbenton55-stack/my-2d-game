@tool
extends EditorScript
class_name PVGamesCatalogPaintableTileSetValidator

const CATALOG_JSON := "res://docs/reports/pvgames_full_asset_catalog.json"
const CANDIDATES_JSON := "res://docs/reports/pvgames_catalog_derived_paint_candidates.json"
const CLASSIFICATION_JSON := "res://docs/reports/pvgames_catalog_derived_paint_classification.json"
const VERIFICATION_JSON := "res://docs/reports/pvgames_catalog_paintable_tile_verification.json"
const VERIFICATION_CSV := "res://docs/reports/pvgames_catalog_paintable_tile_verification.csv"
const VERIFICATION_MD := "res://docs/reports/pvgames_catalog_paintable_tile_verification.md"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesCatalogPaintableTileSetTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_catalog_paintable_tilesets_how_to_use.md"
const SPRITE_STAMP_MD := "res://docs/reports/pvgames_catalog_assets_better_as_sprites_or_stamps.md"
const MAIN_JSON := "res://docs/reports/pvgames_catalog_paintable_tileset_creation.json"
const MAIN_MD := "res://docs/reports/pvgames_catalog_paintable_tileset_creation.md"
const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"

const TILESETS := [
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres",
]

const REQUIRED_SHEET_PREFIXES := [
	"pvgames_verified_ground_road_tiles",
	"pvgames_verified_wall_tiles",
	"pvgames_verified_large_structure_tiles",
	"pvgames_verified_prop_sign_tiles",
]
const VERIFICATION_DIR := "res://docs/reports/pvgames_catalog_paintable_verification"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(FileAccess.file_exists(CATALOG_JSON), "Catalog JSON missing.", failures)
	_require(FileAccess.file_exists(CANDIDATES_JSON), "Catalog-derived candidates missing.", failures)
	_require(FileAccess.file_exists(CLASSIFICATION_JSON), "Classification JSON missing.", failures)
	_require(FileAccess.file_exists(VERIFICATION_JSON), "Tile verification JSON missing.", failures)
	_require(FileAccess.file_exists(VERIFICATION_CSV), "Tile verification CSV missing.", failures)
	_require(FileAccess.file_exists(VERIFICATION_MD), "Tile verification MD missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to guide missing.", failures)
	_require(FileAccess.file_exists(SPRITE_STAMP_MD), "Sprite/stamper recommendation report missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON), "Main JSON report missing.", failures)
	_require(FileAccess.file_exists(MAIN_MD), "Main markdown report missing.", failures)
	for path in TILESETS:
		_require(FileAccess.file_exists(path), "TileSet missing: %s" % path, failures)
		if FileAccess.file_exists(path):
			var text := FileAccess.get_file_as_string(path)
			_require(not text.contains("docs/reports/pvgames_palettes"), "TileSet uses contact sheet: %s" % path, failures)
			_require(text.contains("assets/tilesets/cyber_city_core_tilesets"), "TileSet lacks real PVGames sources: %s" % path, failures)
			_require(not text.contains("physics_layer"), "TileSet contains physics layer text: %s" % path, failures)
	for sheet_prefix in REQUIRED_SHEET_PREFIXES:
		_require(_verification_sheet_exists(sheet_prefix), "Verification sheet missing for prefix: %s" % sheet_prefix, failures)

	var candidates := _read_dict(CANDIDATES_JSON)
	_require(bool(candidates.get("candidate_list_derived_from_catalog", false)), "Candidate list not marked catalog-derived.", failures)
	_require(int(candidates.get("candidate_count", 0)) > 0, "No candidates derived.", failures)
	var verification := _read_array(VERIFICATION_JSON)
	_require(not verification.is_empty(), "No verified tiles.", failures)
	for entry in verification:
		var dict := entry as Dictionary
		if String(dict.get("post_creation_quality_classification", "")).is_empty():
			failures.append("Verified tile missing quality classification.")
			break
		if String(dict.get("path", "")).contains("docs/reports/pvgames_palettes"):
			failures.append("Verified tile uses contact sheet.")
			break

	var test_scene_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test_scene_text.contains("GroundRoadTileMapLayer"), "Test scene missing ground layer.", failures)
	_require(test_scene_text.contains("WallTileMapLayer"), "Test scene missing wall layer.", failures)
	_require(not test_scene_text.contains("GameplayRoot"), "Test scene should not contain gameplay systems.", failures)
	_require(not test_scene_text.contains("CollisionShape2D"), "Test scene should not contain collision.", failures)

	if FileAccess.file_exists(HIDEOUT):
		var hideout_text := FileAccess.get_file_as_string(HIDEOUT)
		if hideout_text.contains("PVG_CatalogPaintLayers"):
			_require(hideout_text.contains("parent=\"ArtRoot/World/PVG_CatalogPaintLayers\""), "Hideout paint layers not under ArtRoot/World.", failures)
			_require(not _catalog_layers_under_gameplay(hideout_text), "Catalog paint layer appears under GameplayRoot.", failures)
			_require(hideout_text.contains("collision_enabled = false"), "Hideout paint layers lack explicit collision disabled.", failures)
		else:
			warnings.append("Hideout catalog paint layers were not created.")

	var main := _read_dict(MAIN_JSON)
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Main report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Main report says gameplay scripts modified.", failures)
	_require(String(main.get("collision_status", "")).contains("No collision"), "Main report collision status unclear.", failures)

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


func _read_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []


func _catalog_layers_under_gameplay(text: String) -> bool:
	for line in text.split("\n"):
		if line.contains("PVGamesCatalog") and line.contains("parent=\"GameplayRoot"):
			return true
	return false


func _verification_sheet_exists(prefix: String) -> bool:
	var dir := DirAccess.open(VERIFICATION_DIR)
	if dir == null:
		return false
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with(prefix) and name.ends_with(".png"):
			return true
		name = dir.get_next()
	return false
