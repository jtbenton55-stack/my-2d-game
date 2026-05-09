@tool
extends EditorScript
class_name PVGamesIconLibraryRunner

const MODE := "dry_run_summary"
const TAG := "warning"

func _run() -> void:
	match MODE:
		"dry_run_summary":
			print("PVGames Icon Library ready. Default mode is non-destructive.")
		"list_icons_by_tag":
			var lib := PVGamesIconLibrary.new()
			lib.load_catalog()
			print(JSON.stringify(lib.list_icons("", "", TAG), "\t"))
		"validate_icon_library":
			print(FileAccess.file_exists("res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"))
		_:
			print("Mode requires running the Python builder manually: ", MODE)
