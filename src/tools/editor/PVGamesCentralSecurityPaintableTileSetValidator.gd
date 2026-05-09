@tool
extends EditorScript
class_name PVGamesCentralSecurityPaintableTileSetValidator

const SOURCE_ROOT := "res://assets/tilesets/cyber_city_core_tilesets/CyberCity_CentralSecurity_Tiles"
const EXPECTED_SUBFOLDERS := [
	"CyberCity_CentralSecurity_Tiles_1",
	"CyberCity_CentralSecurity_Tiles_2",
	"CyberCity_CentralSecurity_Tiles_3",
	"CyberCity_CentralSecurity_Tiles_4",
]
const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const SOURCE_TACO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REDESIGN_TACO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const ASSET_INSTALL := "res://docs/ASSET_INSTALLATION.md"
const REPORTS := [
	"res://docs/reports/pvgames_central_security_full_asset_catalog.json",
	"res://docs/reports/pvgames_central_security_full_asset_catalog.csv",
	"res://docs/reports/pvgames_central_security_paint_candidates.json",
	"res://docs/reports/pvgames_central_security_paint_candidates.csv",
	"res://docs/reports/pvgames_central_security_paint_classification.md",
	"res://docs/reports/pvgames_central_security_paint_classification.json",
	"res://docs/reports/pvgames_central_security_tile_verification.md",
	"res://docs/reports/pvgames_central_security_tile_verification.json",
	"res://docs/reports/pvgames_central_security_tile_verification.csv",
	"res://docs/reports/pvgames_central_security_assets_better_as_sprites_or_stamps.md",
	"res://docs/reports/pvgames_central_security_assets_better_as_sprites_or_stamps.json",
	"res://docs/reports/pvgames_central_security_paintable_tilesets_how_to_use.md",
	"res://docs/reports/pvgames_central_security_paintable_tileset_creation.md",
	"res://docs/reports/pvgames_central_security_paintable_tileset_creation.json",
]
const TILESETS := [
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityGroundRoadPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityWallPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityLargeStructurePaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityPropSignPaint.tres",
	"res://assets/tilesets/pvgames_central_security_paintable/PVGamesCentralSecurityReviewOnlyPaint.tres",
]
const CORE_B4_TILESETS := [
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogGroundRoadPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogWallPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogLargeStructurePaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogPropSignPaint.tres",
	"res://assets/tilesets/pvgames_catalog_paintable/PVGamesCatalogReviewOnlyPaint.tres",
]
const B5_REPORTS := [
	"res://docs/reports/hideout_phase_0mb5_runtime_graybox_cleanup_depth_sorting.md",
	"res://docs/reports/hideout_phase_0mb5_y_sort_origin_audit.md",
]
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesCentralSecurityPaintableTileSetTest.tscn"
const VERIFICATION_DIR := "res://docs/reports/pvgames_central_security_verification"
const SHEET_PREFIXES := [
	"pvgames_central_security_verified_ground_road_tiles",
	"pvgames_central_security_verified_wall_tiles",
	"pvgames_central_security_verified_large_structure_tiles",
	"pvgames_central_security_verified_prop_sign_tiles",
	"pvgames_central_security_verified_review_only_tiles",
]

func _run() -> void:
	print(JSON.stringify(validate(), "\t"))

func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SOURCE_ROOT)), "Central Security source root missing.", failures)
	for folder in EXPECTED_SUBFOLDERS:
		_require(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SOURCE_ROOT + "/" + folder)), "Central Security subfolder missing: %s" % folder, failures)
	for path in REPORTS:
		_require(FileAccess.file_exists(path), "Report missing: %s" % path, failures)
	for path in TILESETS:
		_require(FileAccess.file_exists(path), "Central Security TileSet missing: %s" % path, failures)
		if FileAccess.file_exists(path):
			var text := FileAccess.get_file_as_string(path)
			_require(not text.contains("physics_layer"), "TileSet contains physics layer: %s" % path, failures)
			_require(not text.contains("docs/reports"), "TileSet references report/contact sheet art: %s" % path, failures)
			_require(text.contains("CyberCity_CentralSecurity_Tiles"), "TileSet lacks Central Security source art: %s" % path, failures)
	for path in CORE_B4_TILESETS:
		_require(FileAccess.file_exists(path), "Original 0M-B4 TileSet missing: %s" % path, failures)
	for path in B5_REPORTS:
		_require(FileAccess.file_exists(path), "0M-B5 depth report missing: %s" % path, failures)
	for prefix in SHEET_PREFIXES:
		_require(_sheet_exists(prefix), "Verification sheet missing for prefix: %s" % prefix, failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Central Security test scene missing.", failures)
	if FileAccess.file_exists(TEST_SCENE):
		var test_text := FileAccess.get_file_as_string(TEST_SCENE)
		_require(not test_text.contains("GameplayRoot"), "Test scene contains gameplay systems.", failures)
		_require(not test_text.contains("CollisionShape2D"), "Test scene contains collision.", failures)
		_require(test_text.contains("PVGamesCentralSecurityGroundRoadPaint"), "Test scene does not use new TileSets.", failures)
	if FileAccess.file_exists(HIDEOUT):
		var hideout_text := FileAccess.get_file_as_string(HIDEOUT)
		_require(hideout_text.contains("PVG_CentralSecurityPaintLayers"), "Hideout Central Security paint layers missing.", failures)
		_require(hideout_text.contains("PVG_CentralSecurityDepthPaintLayers"), "Hideout Central Security depth layers missing.", failures)
		_require(not _central_security_under_gameplay(hideout_text), "Central Security art appears under GameplayRoot.", failures)
		_require(_central_security_layers_no_collision(hideout_text), "Central Security Hideout layers lack collision_enabled = false.", failures)
	var verification = _read_array("res://docs/reports/pvgames_central_security_tile_verification.json")
	_require(not verification.is_empty(), "Verification JSON has no tiles.", failures)
	for record in verification:
		if String(record.get("post_creation_quality_classification", "")) == "":
			failures.append("A generated tile lacks verification classification.")
			break
		if String(record.get("post_creation_quality_classification", "")) == "REJECT_JUNK" and String(record.get("palette", "")) != "rejected":
			failures.append("REJECT_JUNK appears in a generated palette.")
			break
	var install_text := FileAccess.get_file_as_string(ASSET_INSTALL) if FileAccess.file_exists(ASSET_INSTALL) else ""
	_require(install_text.contains("CyberCity_CentralSecurity_Tiles"), "Asset installation doc lacks Central Security path.", failures)
	var main := _read_dict("res://docs/reports/pvgames_central_security_paintable_tileset_creation.json")
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Main report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Main report says gameplay scripts modified.", failures)
	_require(bool(main.get("collision_added", true)) == false, "Main report says collision added.", failures)
	_require(bool(main.get("raw_central_security_pngs_staged", true)) == false, "Main report says raw PNGs staged.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures, "warnings": warnings}

func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

func _read_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []

func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _sheet_exists(prefix: String) -> bool:
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

func _central_security_under_gameplay(scene_text: String) -> bool:
	for line in scene_text.split("\n"):
		if line.begins_with("[node ") and line.contains("parent=\"GameplayRoot") and line.contains("CentralSecurity"):
			return true
	return false

func _central_security_layers_no_collision(scene_text: String) -> bool:
	var required := [
		"PVGamesCentralSecurityGroundRoadPaintLayer",
		"PVGamesCentralSecurityWallBackdropPaintLayer",
		"PVGamesCentralSecurityLargeStructureBackdropPaintLayer",
		"PVGamesCentralSecurityPropSignBackdropPaintLayer",
		"PVGamesCentralSecurityOccludableWallPaintLayer",
		"PVGamesCentralSecurityOccludablePropPaintLayer",
		"PVGamesCentralSecurityOccludableLargeStructurePaintLayer",
		"PVGamesCentralSecurityForegroundOverlayPaintLayer",
	]
	for layer_name in required:
		var start := scene_text.find("[node name=\"%s\"" % layer_name)
		if start < 0:
			return false
		var next := scene_text.find("\n[node ", start + 1)
		var block := scene_text.substr(start, scene_text.length() - start if next < 0 else next - start)
		if not block.contains("collision_enabled = false"):
			return false
	return true
