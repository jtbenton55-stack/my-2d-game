@tool
extends EditorScript
class_name PVGamesAssetLibraryValidator

const ASSET_ROOT := "res://assets/tilesets/cyber_city_core_tilesets"
const CATALOG_JSON := "res://docs/reports/pvgames_full_asset_catalog.json"
const CATALOG_CSV := "res://docs/reports/pvgames_full_asset_catalog.csv"
const PALETTES_DIR := "res://docs/reports/pvgames_palettes"
const CURATED_MD := "res://docs/reports/pvgames_birthday_build_curated_palette.md"
const CURATED_JSON := "res://docs/reports/pvgames_birthday_build_curated_palette.json"
const CURATED_SHEET := "res://docs/reports/pvgames_palettes/pvgames_birthday_build_curated_palette.png"
const PALETTE_BROWSER := "res://scenes/hideout/tools/PVGamesAssetPaletteBrowser.tscn"
const STAMPER := "res://src/tools/editor/PVGamesArtStamper.gd"
const SAMPLE_MANIFEST := "res://docs/reports/pvgames_sample_art_placement_manifest.json"
const CHARACTER_PLAN := "res://docs/reports/character_asset_support_plan.md"
const CHARACTER_SCHEMA := "res://docs/reports/character_asset_schema.json"
const ANIMATION_SCHEMA := "res://docs/reports/character_animation_profile_schema.json"
const QUICKSTART := "res://docs/reports/pvgames_art_library_quickstart.md"
const MAIN_REPORT_MD := "res://docs/reports/pvgames_asset_library_and_painting_tool.md"
const MAIN_REPORT_JSON := "res://docs/reports/pvgames_asset_library_and_painting_tool.json"

const REQUIRED_MAJOR_SHEETS := [
	"furniture",
	"wall_back",
	"wall_side",
	"door_window",
	"store_tech",
	"neon_sign",
	"greenhouse_plant",
	"display_shelf",
	"crate_storage",
	"floor_diamond",
	"floor_patch",
]


func _run() -> void:
	var result := validate()
	print(JSON.stringify(result, "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_check(DirAccess.dir_exists_absolute(ASSET_ROOT), "Asset root missing.", failures)
	_check(FileAccess.file_exists(CATALOG_JSON), "Catalog JSON missing.", failures)
	_check(FileAccess.file_exists(CATALOG_CSV), "Catalog CSV missing.", failures)
	_check(DirAccess.dir_exists_absolute(PALETTES_DIR), "Contact sheet folder missing.", failures)
	_check(FileAccess.file_exists(CURATED_MD), "Curated palette markdown missing.", failures)
	_check(FileAccess.file_exists(CURATED_JSON), "Curated palette JSON missing.", failures)
	_check(FileAccess.file_exists(CURATED_SHEET), "Curated contact sheet missing.", failures)
	_check(FileAccess.file_exists(PALETTE_BROWSER), "Palette browser scene missing.", failures)
	_check(FileAccess.file_exists(STAMPER), "Stamper tool missing.", failures)
	_check(FileAccess.file_exists(SAMPLE_MANIFEST), "Sample manifest missing.", failures)
	_check(FileAccess.file_exists(CHARACTER_PLAN), "Character support plan missing.", failures)
	_check(FileAccess.file_exists(CHARACTER_SCHEMA), "Character asset schema missing.", failures)
	_check(FileAccess.file_exists(ANIMATION_SCHEMA), "Character animation schema missing.", failures)
	_check(FileAccess.file_exists(QUICKSTART), "Quickstart guide missing.", failures)
	_check(FileAccess.file_exists(MAIN_REPORT_MD), "Main markdown report missing.", failures)
	_check(FileAccess.file_exists(MAIN_REPORT_JSON), "Main JSON report missing.", failures)

	var actual_png_count := _count_pngs(ASSET_ROOT)
	var catalog: Array = _read_json_array(CATALOG_JSON)
	_check(catalog.size() == actual_png_count, "Catalog count does not match actual PNG count.", failures)
	_check(catalog.size() >= 6478, "Catalog has fewer than expected PVGames PNGs.", failures)
	_check(_catalog_has_required_fields(catalog), "Catalog entries missing required fields.", failures)
	_check(_catalog_has_categories(catalog), "Catalog categories missing.", failures)
	_check(_catalog_has_layers_and_methods(catalog), "Catalog layer/method recommendations missing.", failures)

	var curated: Array = _read_json_array(CURATED_JSON)
	_check(curated.size() >= 75 and curated.size() <= 150, "Curated palette count must be 75-150.", failures)
	_check(_curated_has_required_fields(curated), "Curated palette entries missing required fields.", failures)

	for sheet_name in REQUIRED_MAJOR_SHEETS:
		if _find_palette_sheet(sheet_name).is_empty():
			failures.append("Missing major contact sheet for %s." % sheet_name)

	var stamper_text := FileAccess.get_file_as_string(STAMPER) if FileAccess.file_exists(STAMPER) else ""
	_check(stamper_text.contains("Sprite2D.new()"), "Stamper must create Sprite2D nodes.", failures)
	_check(not stamper_text.contains("CollisionShape2D.new()") and not stamper_text.contains("StaticBody2D.new()"), "Stamper must not create collision nodes.", failures)
	_check(stamper_text.contains("No output scene path provided"), "Stamper must refuse default production overwrite.", failures)

	var main_report := _read_json_dict(MAIN_REPORT_JSON)
	_check(bool(main_report.get("hideout_modified", true)) == false, "Main report says HideoutHub modified.", failures)
	_check(bool(main_report.get("taco_bell_scenes_modified", true)) == false, "Main report says Taco Bell scenes modified.", failures)
	_check(bool(main_report.get("gameplay_scripts_modified", true)) == false, "Main report says gameplay scripts modified.", failures)
	if String(main_report.get("visual_tileset_floor_subset", "")).begins_with("skipped"):
		warnings.append("Visual TileSet floor subset intentionally skipped; Sprite2D remains recommended.")

	return {
		"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL",
		"actual_png_count": actual_png_count,
		"catalog_count": catalog.size(),
		"curated_count": curated.size(),
		"failures": failures,
		"warnings": warnings,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _count_pngs(path: String) -> int:
	var count := 0
	var dir := DirAccess.open(path)
	if dir == null:
		return count
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := path.path_join(name)
			if dir.current_is_dir():
				count += _count_pngs(child)
			elif name.to_lower().ends_with(".png"):
				count += 1
		name = dir.get_next()
	return count


func _read_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _catalog_has_required_fields(catalog: Array) -> bool:
	var required := [
		"asset_id",
		"path",
		"filename",
		"width",
		"height",
		"has_alpha",
		"alpha_bbox_width",
		"alpha_bbox_height",
		"inferred_category",
		"recommended_placement_method",
		"recommended_target_layer",
	]
	for entry in catalog:
		if not entry is Dictionary:
			return false
		for field in required:
			if not (entry as Dictionary).has(field):
				return false
	return true


func _catalog_has_categories(catalog: Array) -> bool:
	for entry in catalog:
		if String((entry as Dictionary).get("inferred_category", "")).is_empty():
			return false
	return true


func _catalog_has_layers_and_methods(catalog: Array) -> bool:
	for entry in catalog:
		var dict := entry as Dictionary
		if String(dict.get("recommended_target_layer", "")).is_empty():
			return false
		if String(dict.get("recommended_placement_method", "")).is_empty():
			return false
	return true


func _curated_has_required_fields(curated: Array) -> bool:
	var required := [
		"curated_id",
		"source_asset_id",
		"path",
		"curated_palette_section",
		"best_use_case",
		"recommended_scene",
		"recommended_target_layer",
		"recommended_placement_method",
		"reason_selected",
		"gameplay_collision",
	]
	for entry in curated:
		if not entry is Dictionary:
			return false
		for field in required:
			if not (entry as Dictionary).has(field):
				return false
		if bool((entry as Dictionary).get("gameplay_collision", true)) != false:
			return false
	return true


func _find_palette_sheet(sheet_name: String) -> String:
	var dir := DirAccess.open(PALETTES_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("pvgames_palette_%s" % sheet_name) and name.ends_with(".png"):
			return PALETTES_DIR.path_join(name)
		name = dir.get_next()
	return ""
