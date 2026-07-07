class_name MissionSceneResolver
extends RefCounted
## Single seam for playable vs legacy vs catalog mission paths (0M-D2). Not an autoload.

const TACO_BELL_MISSION_ID := "taco_bell_drop"
const CORNER_STORE_MISSION_ID := "corner_store_cashout"
const PLAYABLE_EXPANDED_TACO_ISO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PLAYABLE_CORNER_STORE_ISO := "res://scenes/missions_iso/CornerStoreCashout_Editable.tscn"
const LEGACY_BAKE_TACO_ISO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const CLASSIC_TACO_STORY_ROOM := "res://scenes/missions/TacoBellMission.tscn"


static func resolve_playable_scene_path(mission_id: String, _context: Dictionary = {}) -> String:
	var playable_iso_scene := _get_catalog_playable_iso_scene(mission_id)
	if playable_iso_scene != "":
		return playable_iso_scene
	return GameState.get_mission_scene_path(mission_id)


static func get_default_scene_path(mission_id: String) -> String:
	return GameState.get_mission_scene_path(mission_id)


static func get_debug_scene_path(mission_id: String) -> String:
	var playable_iso_scene := _get_catalog_playable_iso_scene(mission_id)
	if playable_iso_scene != "":
		return playable_iso_scene
	return get_default_scene_path(mission_id)


static func get_scene_roles(mission_id: String) -> Dictionary:
	var playable_iso_scene := _get_catalog_playable_iso_scene(mission_id)
	var roles: Dictionary = {
		"mission_id": mission_id,
		"playable_expanded_iso": playable_iso_scene,
		"legacy_bake_output": "",
		"classic_story_room": "",
	}
	if mission_id == TACO_BELL_MISSION_ID:
		roles["legacy_bake_output"] = LEGACY_BAKE_TACO_ISO
		roles["classic_story_room"] = CLASSIC_TACO_STORY_ROOM
	return roles


static func is_legacy_scene_path(path: String) -> bool:
	if path == LEGACY_BAKE_TACO_ISO:
		return true
	if path.contains("TacoBellIso_Editable.tscn") and not path.contains("RedesignTest"):
		return true
	return false


static func get_resolution_report(mission_id: String) -> Dictionary:
	var chosen := resolve_playable_scene_path(mission_id)
	var warnings: Array[String] = []
	if mission_id == TACO_BELL_MISSION_ID and chosen != PLAYABLE_EXPANDED_TACO_ISO:
		warnings.append("taco_bell_drop did not resolve to expanded RedesignTest scene")
	var playable_iso_scene := _get_catalog_playable_iso_scene(mission_id)
	if playable_iso_scene != "" and not ResourceLoader.exists(playable_iso_scene):
		warnings.append("catalog playable_iso_scene does not exist: %s" % playable_iso_scene)
	return {
		"ok": chosen != "",
		"mission_id": mission_id,
		"chosen_playable_path": chosen,
		"roles": get_scene_roles(mission_id),
		"default_catalog_path": get_default_scene_path(mission_id),
		"debug_path": get_debug_scene_path(mission_id),
		"warnings": warnings,
	}


static func _get_catalog_entry(mission_id: String) -> Dictionary:
	if not GameState.mission_catalog.has(mission_id):
		return {}
	var entry: Variant = GameState.mission_catalog.get(mission_id, {})
	return entry if entry is Dictionary else {}


static func _get_catalog_playable_iso_scene(mission_id: String) -> String:
	var entry := _get_catalog_entry(mission_id)
	return String(entry.get("playable_iso_scene", "")).strip_edges()
