@tool
extends EditorScript
class_name Manual5PackCharacterAnimationBatchValidator

const SOURCE_MAP := "res://resources/character_animation_maps/character__working_manual_map.json"
const PREVIEW_DIR := "res://resources/character_animation_maps/generated_preview/"
const EXPORTER_SCRIPT := "res://addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd"
const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const EXPORTER := preload("res://addons/character_animation_mapper/CharacterAnimationSpriteFramesExporter.gd")

const TARGETS: Array[Dictionary] = [
	{
		"character_id": "character_02_neon_runner",
		"sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_02_neon_runner_sheet.png",
		"map": "res://resources/character_animation_maps/character_02_neon_runner_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_02_neon_runner_preview_spriteframes.tres",
	},
	{
		"character_id": "character_03_cyber_tech",
		"sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_03_cyber_tech_sheet.png",
		"map": "res://resources/character_animation_maps/character_03_cyber_tech_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_03_cyber_tech_preview_spriteframes.tres",
	},
	{
		"character_id": "character_04_street_bruiser",
		"sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_04_street_bruiser_sheet.png",
		"map": "res://resources/character_animation_maps/character_04_street_bruiser_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_04_street_bruiser_preview_spriteframes.tres",
	},
	{
		"character_id": "character_05_nocturne_guard",
		"sheet": "res://assets/characters/generated_player_visuals/manual_5pack_20260521/character_05_nocturne_guard_sheet.png",
		"map": "res://resources/character_animation_maps/character_05_nocturne_guard_manual_animation_map.json",
		"spriteframes": PREVIEW_DIR + "character_05_nocturne_guard_preview_spriteframes.tres",
	},
]

const REPRESENTATIVE: Array[String] = [
	"idle_toward_01",
	"walk_toward_01",
	"run_toward_01",
	"jump_toward_01",
	"fall_toward_01",
	"land_toward_01",
	"death_toward_01",
	"dodge_toward_01",
	"punch_toward_01",
	"stab_toward_01",
]


func _run() -> void:
	print(JSON.stringify(validate(), "\t"))


static func validate() -> Dictionary:
	var failures: Array[String] = []
	var per_character: Array[Dictionary] = []
	var source := EXPORTER.load_map_from_path(SOURCE_MAP)
	_require(not source.is_empty(), "source map missing or invalid.", failures)
	var source_anims: Array = source.get("animations", [])
	_require(source_anims.size() == 591, "source map animation count != 591.", failures)
	_require(
		not _has_spear_stab(source_anims),
		"source map still contains spear_stab_* entries.",
		failures
	)
	for target in TARGETS:
		var report := _validate_target(source, target, failures)
		per_character.append(report)
	return {
		"pass_fail_partial": "PASS" if failures.is_empty() else "FAIL",
		"failures": failures,
		"characters": per_character,
	}


static func _validate_target(source: Dictionary, target: Dictionary, failures: Array[String]) -> Dictionary:
	var cid := String(target.get("character_id", "?"))
	var sheet_path := String(target.get("sheet", ""))
	var map_path := String(target.get("map", ""))
	var sf_path := String(target.get("spriteframes", ""))
	var report := {
		"character_id": cid,
		"sheet_path": sheet_path,
		"map_path": map_path,
		"spriteframes_path": sf_path,
	}
	_require(ResourceLoader.exists(sheet_path), "%s sheet missing." % cid, failures)
	_require(FileAccess.file_exists(ProjectSettings.globalize_path(map_path)), "%s map missing." % cid, failures)
	var map_data := EXPORTER.load_map_from_path(map_path)
	_require(not map_data.is_empty(), "%s map invalid." % cid, failures)
	var anims: Array = map_data.get("animations", [])
	report["animation_count"] = anims.size()
	_require(anims.size() == int(source.get("animations", []).size()), "%s animation count mismatch." % cid, failures)
	_require(String(map_data.get("source_sheet", "")) == sheet_path, "%s source_sheet mismatch." % cid, failures)
	_require(not _has_spear_stab(anims), "%s has spear_stab entries." % cid, failures)
	_require(_all_reviewed(anims), "%s has non-reviewed entries." % cid, failures)
	_require(_unique_names(anims), "%s has duplicate animation names." % cid, failures)
	_require(_frames_in_bounds(map_data, anims), "%s has out-of-range frames." % cid, failures)
	_require(ResourceLoader.exists(sf_path), "%s spriteframes missing." % cid, failures)
	var sf: Resource = load(sf_path)
	_require(sf is SpriteFrames, "%s spriteframes not SpriteFrames." % cid, failures)
	if sf is SpriteFrames:
		var spriteframes := sf as SpriteFrames
		var names := spriteframes.get_animation_names()
		var usable := 0
		for nm in names:
			if nm == "default":
				continue
			if spriteframes.get_frame_count(nm) > 0:
				usable += 1
		report["spriteframes_animation_count"] = usable
		_require(usable == anims.size(), "%s spriteframes animation count mismatch." % cid, failures)
		for rep in REPRESENTATIVE:
			if not _map_has_animation(anims, rep):
				continue
			_require(spriteframes.has_animation(rep), "%s missing representative anim %s." % [cid, rep], failures)
			var entry := _map_entry(anims, rep)
			_require(
				spriteframes.get_frame_count(rep) == MAPPER_HELPERS.frames_from_entry(entry).size(),
				"%s frame count mismatch for %s." % [cid, rep],
				failures
			)
			_require(
				is_equal_approx(spriteframes.get_animation_speed(rep), float(entry.get("fps", 10.0))),
				"%s fps mismatch for %s." % [cid, rep],
				failures
			)
			_require(
				spriteframes.get_animation_loop(rep) == bool(entry.get("loop", true)),
				"%s loop mismatch for %s." % [cid, rep],
				failures
			)
	return report


static func _has_spear_stab(anims: Array) -> bool:
	for raw in anims:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if String(raw.get("animation_name", "")).begins_with("spear_stab_"):
			return true
	return false


static func _all_reviewed(anims: Array) -> bool:
	for raw in anims:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		if String(raw.get("review_status", "")) != "reviewed":
			return false
	return true


static func _unique_names(anims: Array) -> bool:
	var seen := {}
	for raw in anims:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var name := String(raw.get("animation_name", ""))
		if seen.has(name):
			return false
		seen[name] = true
	return true


static func _frames_in_bounds(map_data: Dictionary, anims: Array) -> bool:
	var max_frame := int(map_data.get("columns", 50)) * int(map_data.get("rows", 50)) - 1
	for raw in anims:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		for g: int in MAPPER_HELPERS.frames_from_entry(raw):
			if g < 0 or g > max_frame:
				return false
	return true


static func _map_has_animation(anims: Array, anim_name: String) -> bool:
	for raw in anims:
		if typeof(raw) == TYPE_DICTIONARY and String(raw.get("animation_name", "")) == anim_name:
			return true
	return false


static func _map_entry(anims: Array, anim_name: String) -> Dictionary:
	for raw in anims:
		if typeof(raw) == TYPE_DICTIONARY and String(raw.get("animation_name", "")) == anim_name:
			return raw
	return {}


static func _require(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
