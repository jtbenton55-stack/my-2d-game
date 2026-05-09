@tool
extends EditorScript
class_name PVGamesIconLibraryValidator

func _run() -> void:
	print(JSON.stringify(validate(), "\t"))

func validate() -> Dictionary:
	var failures: Array[String] = []
	var required := [
		"res://docs/reports/pvgames_icon_library/icon_source_folder_discovery.json",
		"res://docs/reports/pvgames_icon_library/pvgames_icon_source_scan.json",
		"res://docs/reports/pvgames_icon_library/pvgames_icon_source_classification.json",
		"res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json",
		"res://src/icons/PVGamesIconLibrary.gd",
		"res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd",
		"res://src/tools/editor/PVGamesIconObjectStamperBridge.gd",
		"res://scenes/hideout/tools/PVGamesIconLibraryTest.tscn",
		"res://scenes/hideout/tools/PVGamesIconWorldStamperTest.tscn",
		"res://docs/reports/pvgames_icon_library/future_feature_queue_after_b9.md",
	]
	for path in required:
		if not FileAccess.file_exists(path):
			failures.append("Missing: %s" % path)
	var dock := FileAccess.get_file_as_string("res://addons/pvgames_object_palette/PVGamesObjectPaletteDock.gd")
	if not dock.contains("ICON_INDEX_PATH") or not dock.contains("Asset Type") or not dock.contains("Icon Quality"):
		failures.append("Dock icon integration missing.")
	if dock.contains("CollisionShape2D.new") or dock.contains("StaticBody2D.new"):
		failures.append("Dock creates collision.")
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"))
	if not catalog is Array or catalog.is_empty():
		failures.append("Catalog empty or invalid.")
	return {"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL", "failures": failures}
