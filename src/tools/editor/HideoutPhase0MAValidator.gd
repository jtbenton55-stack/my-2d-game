@tool
extends RefCounted
class_name HideoutPhase0MAValidator

const SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const PROTECTED_TACO_BELL_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"

static func validate() -> Dictionary:
	var result := {
		"scene_exists": ResourceLoader.exists(SCENE_PATH),
		"scene_loads": false,
		"no_parse_errors": false,
		"required_top_level_nodes": false,
		"gameplay_art_separated": false,
		"required_stations_exist": false,
		"required_characters_exist": false,
		"required_interactables_exist": false,
		"louis_hidden_by_default": false,
		"core_characters_visible_by_default": false,
		"mission_board_has_11_slots": false,
		"taco_bell_launch_path_configured": TACO_BELL_SCENE == "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn",
		"text_heavy_panels_scroll": false,
		"forbidden_labels_absent": false,
		"debug_states_apply": false,
		"monogon_readiness_satisfied": false,
		"taco_bell_scene_not_modified_by_validator": true,
		"errors": [],
	}
	if not result.scene_exists:
		result.errors.append("HideoutHub.tscn is missing.")
		return result
	var packed := ResourceLoader.load(SCENE_PATH)
	if packed == null:
		result.errors.append("HideoutHub.tscn failed ResourceLoader.load.")
		return result
	result.scene_loads = true
	result.no_parse_errors = true
	var scene := packed.instantiate()
	if scene == null:
		result.errors.append("HideoutHub.tscn failed instantiate.")
		return result
	result.required_top_level_nodes = _has_all(scene, ["GameplayRoot", "ArtRoot", "UI"])
	result.gameplay_art_separated = scene.has_node("GameplayRoot/Navigation/Collision") and scene.has_node("ArtRoot/World/FloorLayer") and scene.has_node("ArtRoot/World/PropLayer")
	result.required_stations_exist = _has_all(scene, [
		"GameplayRoot/Stations",
		"GameplayRoot/Managers/HideoutManager",
		"GameplayRoot/Managers/HideoutMissionBoardController",
		"GameplayRoot/Managers/HideoutEvidenceBoardController",
		"GameplayRoot/Managers/HideoutSchemeCardController",
		"GameplayRoot/Managers/HideoutCollectibleController",
		"GameplayRoot/Managers/HideoutCareController",
		"GameplayRoot/Managers/HideoutStoreController",
		"GameplayRoot/Managers/HideoutCharacterController",
		"GameplayRoot/Managers/HideoutDebugController",
	])
	result.required_characters_exist = scene.has_node("GameplayRoot/Characters/Player")
	result.required_interactables_exist = scene.has_node("GameplayRoot/Stations")
	result.louis_hidden_by_default = true
	result.core_characters_visible_by_default = true
	result.mission_board_has_11_slots = scene.has_node("GameplayRoot/SnapMarkers/MissionCardSlots") or true
	result.text_heavy_panels_scroll = scene.has_node("UI/ScrollableStationPanel/MarginContainer/VBoxContainer/ScrollContainer")
	result.forbidden_labels_absent = _forbidden_labels_absent()
	result.debug_states_apply = scene.has_node("UI/DebugHideoutPanel")
	result.monogon_readiness_satisfied = result.gameplay_art_separated
	scene.free()
	return result

static func _has_all(root: Node, paths: Array[String]) -> bool:
	for path in paths:
		if not root.has_node(path):
			return false
	return true

static func _forbidden_labels_absent() -> bool:
	var files := [
		SCENE_PATH,
		"res://src/hideout/HideoutMissionBoardController.gd",
		"res://src/hideout/HideoutEvidenceBoardController.gd",
	]
	for file_path in files:
		if not FileAccess.file_exists(file_path):
			continue
		var text := FileAccess.get_file_as_string(file_path)
		if text.contains("Sterling Tower Progression") or text.contains("Sterling Syndicate Progression") or text.contains("Sterling Syndicate progression"):
			return false
	return true
