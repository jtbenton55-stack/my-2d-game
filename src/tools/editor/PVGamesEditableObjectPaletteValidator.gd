@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteValidator

const INDEX := "res://docs/reports/pvgames_editable_object_asset_index.json"
const NORMALIZED := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"
const MASTER := "res://scenes/hideout/tools/PVGamesEditableObjectMasterPalette.tscn"
const RUNNER := "res://src/tools/editor/PVGamesEditableObjectPaletteRunner.gd"
const HELPER := "res://src/tools/editor/PVGamesEditableObjectPaletteBrowserHelper.gd"
const HOW_TO := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_how_to_use.md"
const HIDEOUT := "res://scenes/hideout/HideoutHub.tscn"
const CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


func validate() -> Dictionary:
	var failures: Array[String] = []
	_require(FileAccess.file_exists(INDEX), "B8 source index missing.", failures)
	_require(FileAccess.file_exists(NORMALIZED), "Normalized palette index missing.", failures)
	_require(FileAccess.file_exists(MASTER), "Master palette scene missing.", failures)
	_require(FileAccess.file_exists(RUNNER), "Palette runner missing.", failures)
	_require(FileAccess.file_exists(HELPER), "Palette helper missing.", failures)
	_require(FileAccess.file_exists(HOW_TO), "How-to missing.", failures)
	for container in CONTAINERS:
		_require(FileAccess.file_exists("res://scenes/hideout/tools/PVGamesEditableObjectPalette_%s.tscn" % container), "%s palette scene missing." % container, failures)
	var data := _read_dict(NORMALIZED)
	var objects: Array = data.get("objects", [])
	for item in objects:
		if item is Dictionary:
			var container := String(item.get("recommended_container", ""))
			if not CONTAINERS.has(container):
				failures.append("Ungrouped object: %s" % item.get("object_id", ""))
	var runner_text := FileAccess.get_file_as_string(RUNNER) if FileAccess.file_exists(RUNNER) else ""
	_require(runner_text.contains("const MODE := \"dry_run_list_palette\""), "Runner default is not dry_run_list_palette.", failures)
	var master_text := FileAccess.get_file_as_string(MASTER) if FileAccess.file_exists(MASTER) else ""
	_require(master_text.contains("BehindPlayerObjects") and master_text.contains("OccludableObjects") and master_text.contains("ForegroundObjects") and master_text.contains("ReviewObjects"), "Master scene does not list all containers.", failures)
	_require(not master_text.contains("GameplayRoot"), "Palette scene references GameplayRoot.", failures)
	_require(not master_text.contains("CollisionShape2D") and not master_text.contains("StaticBody2D"), "Collision found in master scene.", failures)
	var hideout := FileAccess.get_file_as_string(HIDEOUT) if FileAccess.file_exists(HIDEOUT) else ""
	_require(hideout.contains("PVG_EditableObjects"), "Hideout editable containers missing.", failures)
	_require(not hideout.contains("PVGamesEditableObjectPalette"), "Palette previews appear to be in production Hideout.", failures)
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}


func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
