@tool
extends EditorScript

## Phase 0M-C1 editor validator.
## Run inside Godot when available. The Python report builder also performs
## equivalent static validation for environments without Godot CLI.

const ITEM_CATALOG := "res://data/store/birthday_store_items.json"
const ICON_CATALOG := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const REPORT_DIR := "res://docs/reports/hideout_storefront_icons/"

const REQUIRED_REPORTS := [
	"phase0mc1_store_system_audit.md",
	"phase0mc1_store_system_audit.json",
	"phase0mc1_curated_store_icons.md",
	"phase0mc1_curated_store_icons.json",
	"phase0mc1_hideout_storefront_icons.md",
	"phase0mc1_hideout_storefront_icons.json",
	"phase0mc1_static_validator.json",
]

const REQUIRED_FILES := [
	"res://src/hideout/HideoutStoreController.gd",
	"res://src/ui/HideoutStorefrontPanel.gd",
	"res://scenes/ui/HideoutStorefrontPanel.tscn",
	"res://src/hideout/HideoutManager.gd",
	"res://src/icons/PVGamesIconLibrary.gd",
	"res://src/dialogue/HideoutCharacterDialogueBank.gd",
	"res://src/dialogue/DialoguePortraitRegistry.gd",
	"res://scenes/hideout/tools/HideoutStorefrontIconTest.tscn",
	"res://scenes/missions_iso/TacoBellIso_Editable.tscn",
	"res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
]

const THEME_RULES := {
	"furniture_cozy": {"minimum": 5, "tags": ["furniture", "cozy_hideout"]},
	"neon_wall": {"minimum": 5, "tags": ["neon_signs", "wall_decor", "lights"]},
	"desk_gadgets": {"minimum": 4, "tags": ["desk_gadgets", "terminal", "screens"]},
	"plants": {"minimum": 3, "tags": ["plants_greenhouse"]},
	"bentley": {"minimum": 4, "tags": ["bentley"]},
	"jake": {"minimum": 4, "tags": ["jake", "sweet_tooth", "poop_bags"]},
	"parmida": {"minimum": 4, "tags": ["parmida_mere", "birthday"]},
	"louis": {"minimum": 3, "tags": ["louis"]},
	"mission_room": {"minimum": 3, "tags": ["mission_room", "collectible"]},
}

func _run() -> void:
	var failures: Array = []
	for path in REQUIRED_FILES:
		_assert(failures, ResourceLoader.exists(path), "Required file exists: %s" % path)
	for report in REQUIRED_REPORTS:
		_assert(failures, FileAccess.file_exists(REPORT_DIR + report), "Required report exists: %s" % report)
	_assert(failures, FileAccess.file_exists(ITEM_CATALOG), "Store item catalog exists")
	_assert(failures, FileAccess.file_exists(ICON_CATALOG), "B9 icon catalog exists")

	var icon_by_id := {}
	if FileAccess.file_exists(ICON_CATALOG):
		var parsed_icons = JSON.parse_string(FileAccess.get_file_as_string(ICON_CATALOG))
		if parsed_icons is Array:
			for entry in parsed_icons:
				if entry is Dictionary:
					icon_by_id[String(entry.get("icon_id", ""))] = entry

	var items: Array = []
	if FileAccess.file_exists(ITEM_CATALOG):
		var parsed_items = JSON.parse_string(FileAccess.get_file_as_string(ITEM_CATALOG))
		if parsed_items is Dictionary:
			items = (parsed_items as Dictionary).get("items", [])

	_assert(failures, items.size() >= 25, "Item count >= 25")
	_assert(failures, items.size() <= 40, "Item count <= 40")
	var ids := {}
	var doomsday_used := 0
	var reject_junk_used := 0
	for raw_item in items:
		if not raw_item is Dictionary:
			continue
		var item := raw_item as Dictionary
		var item_id := String(item.get("item_id", ""))
		_assert(failures, item_id != "" and not ids.has(item_id), "Unique item id: %s" % item_id)
		ids[item_id] = true
		var icon_id := String(item.get("icon_id", ""))
		_assert(failures, icon_by_id.has(icon_id), "Valid icon id for %s" % item_id)
		if icon_by_id.has(icon_id):
			var icon := icon_by_id[icon_id] as Dictionary
			if String(icon.get("source_set", "")) == "doomsday_icons":
				doomsday_used += 1
			if String(icon.get("quality_classification", "")) == "REJECT_JUNK":
				reject_junk_used += 1
	_assert(failures, doomsday_used == 0, "No Doomsday icons used")
	_assert(failures, reject_junk_used == 0, "No REJECT_JUNK icons used")

	for rule_id in THEME_RULES.keys():
		var rule := THEME_RULES[rule_id] as Dictionary
		var count := _count_theme(items, rule.get("tags", []))
		_assert(failures, count >= int(rule.get("minimum", 0)), "Theme %s covered (%d)" % [rule_id, count])

	var storefront_script := FileAccess.get_file_as_string("res://src/ui/HideoutStorefrontPanel.gd")
	_assert(failures, storefront_script.contains("PVGamesIconLibrary"), "Storefront loads PVGamesIconLibrary")
	_assert(failures, storefront_script.contains("ScrollContainer"), "Storefront is scrollable")
	_assert(failures, storefront_script.contains("TextureRect"), "Storefront displays item icons")
	_assert(failures, storefront_script.contains("_status_label"), "Storefront has status feedback")

	var manager_script := FileAccess.get_file_as_string("res://src/hideout/HideoutManager.gd")
	_assert(failures, manager_script.contains("normalized_id == \"store_terminal\""), "Store station wired")
	_assert(failures, manager_script.contains("_PORTRAIT_DIALOGUE_CHARACTER_IDS"), "C3 portrait dialogue route preserved")

	if failures.is_empty():
		print("0M-C1 storefront icon validator: PASS")
	else:
		printerr("0M-C1 storefront icon validator: FAIL")
		for failure in failures:
			printerr(" - " + String(failure))

func _count_theme(items: Array, tags: Array) -> int:
	var count := 0
	for raw_item in items:
		if not raw_item is Dictionary:
			continue
		var item := raw_item as Dictionary
		var item_tags: Array = item.get("store_tag", [])
		item_tags.append(String(item.get("category", "")))
		for tag in tags:
			if item_tags.has(tag):
				count += 1
				break
	return count

func _assert(failures: Array, ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
