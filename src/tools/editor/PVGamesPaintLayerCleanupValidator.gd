@tool
extends EditorScript
class_name PVGamesPaintLayerCleanupValidator

const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const TOOL := "res://src/tools/editor/PVGamesPaintLayerCleanupTool.gd"
const RUNNER := "res://src/tools/editor/PVGamesPaintLayerCleanupRunner.gd"
const INVENTORY_MD := "res://docs/reports/hideout_phase_0mb7_pvgames_paint_layer_inventory.md"
const INVENTORY_JSON := "res://docs/reports/hideout_phase_0mb7_pvgames_paint_layer_inventory.json"
const HOW_TO := "res://docs/reports/pvgames_paint_layer_cleanup_how_to.md"
const MAIN_MD := "res://docs/reports/hideout_phase_0mb7_paint_layer_cleanup_tool.md"
const MAIN_JSON := "res://docs/reports/hideout_phase_0mb7_paint_layer_cleanup_tool.json"
const SOURCE_TACO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const REDESIGN_TACO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	_require(FileAccess.file_exists(HIDEOUT), "HideoutHub missing.", failures)
	_require(FileAccess.file_exists(TOOL), "Cleanup tool missing.", failures)
	_require(FileAccess.file_exists(RUNNER), "Cleanup runner missing.", failures)
	_require(FileAccess.file_exists(INVENTORY_MD), "Inventory markdown report missing.", failures)
	_require(FileAccess.file_exists(INVENTORY_JSON), "Inventory JSON report missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to guide missing.", failures)
	_require(FileAccess.file_exists(MAIN_MD), "Main cleanup markdown report missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON), "Main cleanup JSON report missing.", failures)
	_require(FileAccess.file_exists(SOURCE_TACO), "Protected Taco Bell source scene missing.", failures)
	_require(FileAccess.file_exists(REDESIGN_TACO), "Protected Taco Bell redesign scene missing.", failures)

	var hideout_text := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	_require(hideout_text.contains("GameplayRoot"), "GameplayRoot missing.", failures)
	_require(hideout_text.contains("ArtRoot"), "ArtRoot missing.", failures)
	_require(hideout_text.contains("ArtRoot/World"), "ArtRoot/World missing.", failures)
	_require(hideout_text.contains("PVG_CatalogPaintLayers") or hideout_text.contains("PVG_CentralSecurityPaintLayers"), "PVGames paint layers not detectable.", failures)

	var tool_text := FileAccess.get_file_as_string(TOOL) if FileAccess.file_exists(TOOL) else ""
	_require(tool_text.contains("func print_inventory"), "Cleanup tool lacks print_inventory.", failures)
	_require(tool_text.contains("func dry_run_clear_layer"), "Cleanup tool lacks dry_run_clear_layer.", failures)
	_require(tool_text.contains("func dry_run_clear_group"), "Cleanup tool lacks dry_run_clear_group.", failures)
	_require(tool_text.contains("func clear_layer"), "Cleanup tool lacks clear_layer.", failures)
	_require(tool_text.contains("func clear_group"), "Cleanup tool lacks clear_group.", failures)
	_require(tool_text.contains("func backup_hideout"), "Cleanup tool lacks backup_hideout.", failures)
	_require(tool_text.contains("func get_pvgames_paint_layers"), "Cleanup tool lacks get_pvgames_paint_layers.", failures)
	_require(tool_text.contains("func is_safe_paint_layer"), "Cleanup tool lacks is_safe_paint_layer.", failures)
	_require(tool_text.contains("func clear_cells_on_layer"), "Cleanup tool lacks clear_cells_on_layer.", failures)
	_require(tool_text.contains("layer.clear()"), "Cleanup tool does not clear cells through TileMapLayer.clear().", failures)
	_require(not tool_text.contains("queue_free()"), "Cleanup tool should not queue_free paint layers.", failures)
	_require(not tool_text.contains("DirAccess.remove") and not tool_text.contains("OS.execute"), "Cleanup tool should not delete files or shell out.", failures)
	_require(tool_text.contains("ArtRoot/World/"), "Cleanup tool does not restrict to ArtRoot/World.", failures)
	_require(tool_text.contains("GameplayRoot"), "Cleanup tool lacks GameplayRoot exclusion.", failures)
	_require(tool_text.contains("pvgames_catalog_paintable") and tool_text.contains("pvgames_central_security_paintable"), "Cleanup tool lacks PVGames TileSet path checks.", failures)

	var runner_text := FileAccess.get_file_as_string(RUNNER) if FileAccess.file_exists(RUNNER) else ""
	_require(runner_text.contains('const MODE := "dry_run_inventory"'), "Runner default mode is not dry_run_inventory.", failures)

	var main := _read_dict(MAIN_JSON)
	_require(int(main.get("cells_actually_cleared_in_this_pass", -1)) == 0, "Main report says cells were cleared.", failures)
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Main report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Main report says gameplay scripts modified.", failures)
	_require(bool(main.get("backup_before_clear_implemented", false)), "Backup-before-clear not reported.", failures)

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
