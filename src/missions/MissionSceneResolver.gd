class_name MissionSceneResolver
extends RefCounted
## Single seam for playable vs legacy vs catalog mission paths (0M-D2). Not an autoload.

const TACO_BELL_MISSION_ID := "taco_bell_drop"
const PLAYABLE_EXPANDED_TACO_ISO := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const LEGACY_BAKE_TACO_ISO := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const CLASSIC_TACO_STORY_ROOM := "res://scenes/missions/TacoBellMission.tscn"


static func resolve_playable_scene_path(mission_id: String, _context: Dictionary = {}) -> String:
	if mission_id == TACO_BELL_MISSION_ID:
		return PLAYABLE_EXPANDED_TACO_ISO
	return GameState.get_mission_scene_path(mission_id)


static func get_default_scene_path(mission_id: String) -> String:
	return GameState.get_mission_scene_path(mission_id)


static func get_debug_scene_path(mission_id: String) -> String:
	if mission_id == TACO_BELL_MISSION_ID:
		return PLAYABLE_EXPANDED_TACO_ISO
	return get_default_scene_path(mission_id)


static func get_scene_roles(mission_id: String) -> Dictionary:
	var roles: Dictionary = {
		"mission_id": mission_id,
		"playable_expanded_iso": "",
		"legacy_bake_output": "",
		"classic_story_room": "",
	}
	if mission_id == TACO_BELL_MISSION_ID:
		roles["playable_expanded_iso"] = PLAYABLE_EXPANDED_TACO_ISO
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
	return {
		"ok": chosen != "",
		"mission_id": mission_id,
		"chosen_playable_path": chosen,
		"roles": get_scene_roles(mission_id),
		"default_catalog_path": get_default_scene_path(mission_id),
		"debug_path": get_debug_scene_path(mission_id),
		"warnings": warnings,
	}
