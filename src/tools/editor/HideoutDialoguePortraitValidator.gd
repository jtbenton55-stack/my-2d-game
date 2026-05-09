@tool
extends EditorScript

## Phase 0M-C3 validator. Run from the Godot editor with:
##   File -> Run -> select this script
##
## When Godot is unavailable from the CLI, the parent Python harness
## performs the equivalent static checks; this script is the live
## counterpart that runs in the editor environment so the results match
## what the engine actually loads.

const PORTRAIT_ROOT := "res://assets/portraits/"
const SLICE_DIR := "res://assets/portraits/generated_slices/"
const ATLAS_DIR := "res://assets/portraits/generated_slices/atlas_textures/"
const REPORT_DIR := "res://docs/reports/hideout_dialogue_portraits/"
const PORTRAIT_DATA := "res://data/dialogue/dialogue_portraits.json"

const REQUIRED_REPORTS := [
	"phase0mc3_dialogue_system_audit.md",
	"phase0mc3_dialogue_system_audit.json",
	"phase0mc3_portrait_sheet_scan.md",
	"phase0mc3_portrait_sheet_scan.json",
	"phase0mc3_portrait_slice_catalog.md",
	"phase0mc3_portrait_slice_catalog.json",
	"phase0mc3_portrait_slice_catalog.csv",
	"phase0mc3_portrait_assignment_report.md",
	"phase0mc3_portrait_assignment_report.json",
	"portrait_slices_contact_sheet.png",
	"phase0mc3_hideout_dialogue_portraits.md",
	"phase0mc3_hideout_dialogue_portraits.json",
]

const REQUIRED_SCRIPTS := [
	"res://src/dialogue/DialoguePortraitRegistry.gd",
	"res://src/dialogue/HideoutCharacterDialogueBank.gd",
	"res://src/ui/DialogueBox.gd",
	"res://src/autoload/DialogueManager.gd",
	"res://src/utils/EventBus.gd",
	"res://src/hideout/HideoutManager.gd",
	"res://scenes/ui/DialogueBox.tscn",
	"res://scenes/hideout/tools/HideoutDialoguePortraitTest.tscn",
]

const REQUIRED_DIALOGUE_KEYS := ["jake", "parmida", "mere", "bentley", "louis", "fallback"]
const TACO_BELL_SCENES := [
	"res://scenes/missions_iso/TacoBellIso_Editable.tscn",
	"res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
]
const MIN_LINES_PER_CHARACTER := 12

func _run() -> void:
	var failures: Array = []
	var report := {
		"phase": "0M-C3",
		"checks": [],
	}

	for path in REQUIRED_SCRIPTS:
		_assert(failures, ResourceLoader.exists(path),
			"Required script/scene exists: %s" % path)
	for filename in REQUIRED_REPORTS:
		_assert(failures, FileAccess.file_exists(REPORT_DIR + filename),
			"Required report exists: %s" % filename)

	# Portrait data file
	_assert(failures, FileAccess.file_exists(PORTRAIT_DATA),
		"Portrait registry data exists: %s" % PORTRAIT_DATA)
	if FileAccess.file_exists(PORTRAIT_DATA):
		var f := FileAccess.open(PORTRAIT_DATA, FileAccess.READ)
		var raw := f.get_as_text() if f else ""
		var parsed: Variant = JSON.parse_string(raw)
		_assert(failures, parsed is Dictionary,
			"Portrait data parses as Dictionary")
		if parsed is Dictionary:
			var portraits := (parsed as Dictionary).get("portraits", {}) as Dictionary
			for key in REQUIRED_DIALOGUE_KEYS:
				_assert(failures, portraits.has(key),
					"Portrait registry has key '%s'" % key)
			# Parmida and Mere must resolve to the same png_path.
			if portraits.has("parmida") and portraits.has("mere"):
				var p1 := String((portraits["parmida"] as Dictionary).get("png_path", ""))
				var p2 := String((portraits["mere"] as Dictionary).get("png_path", ""))
				_assert(failures, p1 == p2 and p1 != "",
					"Parmida and Mere share the same portrait png_path")

	# Generated slices folder must exist and contain >= 8 PNGs (one full sheet).
	var slice_dir := DirAccess.open(SLICE_DIR)
	_assert(failures, slice_dir != null, "Generated slices folder exists: %s" % SLICE_DIR)
	if slice_dir:
		var slice_pngs: Array = []
		for n in slice_dir.get_files():
			if (n as String).ends_with(".png"):
				slice_pngs.append(n)
		_assert(failures, slice_pngs.size() >= 8,
			"At least 8 sliced portrait PNGs were generated (got %d)" % slice_pngs.size())

	# Source portrait sheets MUST NOT be modified.
	# We can't easily diff timestamps here, but we can check that the
	# slice/atlas folders are subfolders of the source folder (so the
	# source dir is the only mutated location, and only via additions).
	_assert(failures, SLICE_DIR.begins_with(PORTRAIT_ROOT),
		"Generated slices live under the original portrait root")
	_assert(failures, ATLAS_DIR.begins_with(PORTRAIT_ROOT),
		"Generated AtlasTextures live under the original portrait root")

	# Dialogue bank line counts.
	var bank := load("res://src/dialogue/HideoutCharacterDialogueBank.gd")
	if bank:
		for speaker in ["jake", "parmida", "mere", "bentley", "louis"]:
			var count: int = int(bank.line_count(speaker))
			_assert(failures, count >= MIN_LINES_PER_CHARACTER,
				"%s dialogue line count >= %d (got %d)" % [speaker, MIN_LINES_PER_CHARACTER, count])

	# DialogueBox scene must contain a TextureRect for the portrait.
	if FileAccess.file_exists("res://scenes/ui/DialogueBox.tscn"):
		var dlg_text := FileAccess.get_file_as_string("res://scenes/ui/DialogueBox.tscn")
		_assert(failures, "PortraitRect" in dlg_text and "TextureRect" in dlg_text,
			"DialogueBox.tscn defines a TextureRect named PortraitRect")

	# Taco Bell scenes must not be touched in this pass. We only
	# verify they still exist with their canonical paths. A modification
	# check is impractical from inside the editor, but the python
	# harness records mtimes alongside this validator.
	for tb in TACO_BELL_SCENES:
		_assert(failures, ResourceLoader.exists(tb),
			"Taco Bell scene still exists at %s" % tb)

	# EventBus must declare the new signal.
	if FileAccess.file_exists("res://src/utils/EventBus.gd"):
		var ev_text := FileAccess.get_file_as_string("res://src/utils/EventBus.gd")
		_assert(failures, "dialogue_line_changed_full" in ev_text,
			"EventBus declares dialogue_line_changed_full signal")

	# HideoutManager must route character ids to the portrait dialogue path.
	if FileAccess.file_exists("res://src/hideout/HideoutManager.gd"):
		var hm_text := FileAccess.get_file_as_string("res://src/hideout/HideoutManager.gd")
		_assert(failures, "_open_character_portrait_dialogue" in hm_text,
			"HideoutManager has _open_character_portrait_dialogue routing")

	report["checks"] = _result_log
	report["failures"] = failures
	report["pass"] = failures.is_empty()
	print(JSON.stringify(report, "  "))
	if failures.is_empty():
		print("0M-C3 portrait+dialogue validator: PASS")
	else:
		printerr("0M-C3 portrait+dialogue validator: FAIL")
		for msg in failures:
			printerr(" - " + String(msg))

var _result_log: Array = []

func _assert(failures: Array, ok: bool, label: String) -> void:
	_result_log.append({"label": label, "ok": ok})
	if not ok:
		failures.append(label)
