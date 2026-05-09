@tool
extends EditorScript
class_name PVGamesObjectStamperValidator

const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const INDEX_JSON := "res://docs/reports/pvgames_editable_object_asset_index.json"
const STAMPER := "res://src/tools/editor/PVGamesObjectStamperTool.gd"
const RUNNER := "res://src/tools/editor/PVGamesObjectStamperRunner.gd"
const EDITABLE_SCRIPT := "res://src/hideout/PVGEditableObject.gd"
const TEST_SCENE := "res://scenes/hideout/tools/PVGamesObjectStamperTest.tscn"
const HOW_TO := "res://docs/reports/pvgames_editable_object_stamper_how_to.md"
const MAIN_JSON := "res://docs/reports/hideout_phase_0mb8_editable_object_stamper.json"
const MAIN_MD := "res://docs/reports/hideout_phase_0mb8_editable_object_stamper.md"


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(HIDEOUT), "Hideout missing.", failures)
	_require(FileAccess.file_exists(INDEX_JSON), "Object index missing.", failures)
	_require(FileAccess.file_exists(STAMPER), "Stamper tool missing.", failures)
	_require(FileAccess.file_exists(RUNNER), "Runner missing.", failures)
	_require(FileAccess.file_exists(EDITABLE_SCRIPT), "Editable object script missing.", failures)
	_require(FileAccess.file_exists(TEST_SCENE), "Test scene missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to missing.", failures)
	_require(FileAccess.file_exists(MAIN_JSON) and FileAccess.file_exists(MAIN_MD), "Main reports missing.", failures)
	var hideout := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	_require(hideout.contains("GameplayRoot"), "GameplayRoot missing.", failures)
	_require(hideout.contains("ArtRoot/World"), "ArtRoot/World missing.", failures)
	_require(hideout.contains("PVG_EditableObjects"), "PVG_EditableObjects missing.", failures)
	_require(hideout.contains("BehindPlayerObjects"), "BehindPlayerObjects missing.", failures)
	_require(hideout.contains("OccludableObjects"), "OccludableObjects missing.", failures)
	_require(hideout.contains("ForegroundObjects"), "ForegroundObjects missing.", failures)
	_require(hideout.contains("ReviewObjects"), "ReviewObjects missing.", failures)
	for line in hideout.split("\n"):
		if line.contains("PVG_EditableObjects") and line.contains("parent=\"GameplayRoot"):
			failures.append("Editable object container appears under GameplayRoot.")
	var runner := FileAccess.get_file_as_string(RUNNER) if FileAccess.file_exists(RUNNER) else ""
	_require(runner.contains("const MODE := \"dry_run_list\""), "Runner default is not dry_run_list.", failures)
	var script := FileAccess.get_file_as_string(EDITABLE_SCRIPT) if FileAccess.file_exists(EDITABLE_SCRIPT) else ""
	_require(script.contains("Sprite2D") and script.contains("centered = true"), "Editable object script lacks centered Sprite2D setup.", failures)
	_require(not script.contains("CollisionShape2D.new") and not script.contains("StaticBody2D.new"), "Editable object script creates collision.", failures)
	var test := FileAccess.get_file_as_string(TEST_SCENE) if FileAccess.file_exists(TEST_SCENE) else ""
	_require(test.contains("Sample_") and test.contains("Sprite2D"), "Test scene sample objects missing.", failures)
	_require(not test.contains("CollisionShape2D") and not test.contains("StaticBody2D"), "Test scene contains collision.", failures)
	var main := _read_dict(MAIN_JSON)
	_require(bool(main.get("taco_bell_scenes_modified", true)) == false, "Report says Taco Bell scenes modified.", failures)
	_require(bool(main.get("gameplay_scripts_modified", true)) == false, "Report says gameplay scripts modified.", failures)
	_require(bool(main.get("source_pngs_modified", true)) == false, "Report says source PNGs modified.", failures)
	_require(bool(main.get("tilesets_modified", true)) == false, "Report says TileSets modified.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
