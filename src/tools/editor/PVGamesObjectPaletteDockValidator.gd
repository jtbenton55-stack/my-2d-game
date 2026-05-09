@tool
extends EditorScript
class_name PVGamesObjectPaletteDockValidator

const PLUGIN_CFG := "res://addons/pvgames_object_palette/plugin.cfg"
const PLUGIN_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPalettePlugin.gd"
const DOCK_SCENE := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.tscn"
const DOCK_SCRIPT := "res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd"
const OBJECT_INDEX := "res://docs/reports/pvgames_editable_object_asset_index.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesObjectPaletteDockTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_how_to_use.md"
const REPORT_JSON := "res://docs/reports/pvgames_object_palette_dock/pvgames_object_palette_dock_creation.json"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(PLUGIN_CFG), "plugin.cfg missing.", failures)
	_require(FileAccess.file_exists(PLUGIN_SCRIPT), "plugin script missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCENE), "dock scene missing.", failures)
	_require(FileAccess.file_exists(DOCK_SCRIPT), "dock script missing.", failures)
	_require(FileAccess.file_exists(OBJECT_INDEX), "object index missing.", failures)
	_require(FileAccess.file_exists(EDITABLE_OBJECT_SCENE), "editable object scene missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "dock test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "how-to missing.", failures)
	var plugin_text := FileAccess.get_file_as_string(PLUGIN_SCRIPT) if FileAccess.file_exists(PLUGIN_SCRIPT) else ""
	var dock_scene_text := FileAccess.get_file_as_string(DOCK_SCENE) if FileAccess.file_exists(DOCK_SCENE) else ""
	var dock_text := FileAccess.get_file_as_string(DOCK_SCRIPT) if FileAccess.file_exists(DOCK_SCRIPT) else ""
	_require(plugin_text.contains("extends EditorPlugin"), "plugin does not extend EditorPlugin.", failures)
	_require(plugin_text.contains("add_control_to_dock"), "plugin does not add dock.", failures)
	_require(plugin_text.contains("remove_control_from_docks"), "plugin does not remove dock.", failures)
	_require(not plugin_text.contains("stamp_selected"), "plugin appears to stamp on load.", failures)
	_require(dock_scene_text.contains("size_flags_vertical") or dock_text.contains("size_flags_vertical"), "dock root does not expand vertically.", failures)
	_require(dock_text.contains("ScrollContainer.new") and dock_text.contains("MainScroll"), "dock lacks script-created ScrollContainer.", failures)
	_require(dock_text.contains("ContentVBox"), "dock lacks scroll content container.", failures)
	_require(dock_text.contains("\"Actions\""), "Actions section missing.", failures)
	_require(dock_text.contains("\"Dry Run Stamp\""), "Dry Run Stamp button missing.", failures)
	_require(dock_text.contains("\"Stamp Selected at Typed Position\""), "typed-position stamp button missing.", failures)
	_require(dock_text.contains("\"Stamp Selected at 2D View Center\""), "view-center stamp button missing.", failures)
	_require(dock_text.contains("\"Copy Object ID\""), "Copy Object ID button missing.", failures)
	_require(dock_text.contains("\"Refresh Index\""), "Refresh Index button missing.", failures)
	_require(dock_text.contains("custom_minimum_size = Vector2(360, 150)"), "result list height is not controlled.", failures)
	_require(dock_text.contains("_shorten_middle"), "source path overflow helper missing.", failures)
	_require(dock_text.contains("_load_object_index"), "dock index loader missing.", failures)
	_require(dock_text.contains("_apply_filters"), "dock filter function missing.", failures)
	_require(dock_text.contains("_dry_run_stamp_selected"), "dry-run function missing.", failures)
	_require(dock_text.contains("_stamp_selected_at_position"), "actual stamp function missing.", failures)
	_require(dock_text.contains("ArtRoot/World/PVG_EditableObjects") or dock_text.contains("PVG_EditableObjects"), "container target missing.", failures)
	_require(dock_text.contains("_node_is_under_gameplayroot"), "GameplayRoot rejection helper missing.", failures)
	_require(not dock_text.contains("CollisionShape2D.new") and not dock_text.contains("StaticBody2D.new"), "dock creates collision.", failures)
	var test_text := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test_text.contains("ArtRoot") and test_text.contains("World") and test_text.contains("PVG_EditableObjects"), "test scene missing required containers.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
