class_name MissionBlockoutValidator
extends RefCounted

const REQUIRED_LAYER_PATHS: Array[String] = [
	"GameplayRoot",
	"GameplayRoot/GameplayFloorLayer",
	"GameplayRoot/GameplayCollisionLayer",
	"GameplayRoot/GameplayMarkersLayer",
	"GameplayRoot/ObjectiveAreas",
	"GameplayRoot/ExitAreas",
	"GameplayRoot/SpawnPoints",
	"GameplayRoot/EnemyPaths",
	"ArtRoot",
	"ArtRoot/GroundArtLayer",
	"ArtRoot/WallArtLayer",
	"ArtRoot/PropArtLayer",
	"ArtRoot/DecorBelowLayer",
	"ArtRoot/DecorAboveLayer",
	"ArtRoot/LightingLayer",
	"EntityRoot",
	"EntityRoot/Enemies",
	"EntityRoot/Interactables",
	"Camera2D",
	"MissionController",
]


static func validate(definition: Resource, scene_root: Node = null) -> Dictionary:
	var report := {
		"mission_id": definition.mission_id if definition != null else "",
		"ok": true,
		"errors": [],
		"warnings": [],
	}
	if definition == null:
		_add_error(report, "MissionDefinition is null.")
		return report
	_validate_definition(definition, report)
	if scene_root != null:
		_validate_scene(definition, scene_root, report)
	return report


static func print_report(report: Dictionary) -> void:
	var status := "PASS" if bool(report.get("ok", false)) else "FAIL"
	print("[MissionBlockoutValidator] " + status + " " + String(report.get("mission_id", "")))
	for err in report.get("errors", []):
		push_error("[MissionBlockoutValidator] " + String(err))
	for warning in report.get("warnings", []):
		push_warning("[MissionBlockoutValidator] " + String(warning))


static func write_markdown_report(report: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("MissionBlockoutValidator: failed to write report: " + path)
		return
	file.store_line("# Mission Blockout Validation")
	file.store_line("")
	file.store_line("- Mission: `" + String(report.get("mission_id", "")) + "`")
	file.store_line("- Status: **" + ("PASS" if bool(report.get("ok", false)) else "FAIL") + "**")
	file.store_line("")
	file.store_line("## Errors")
	for err in report.get("errors", []):
		file.store_line("- " + String(err))
	if report.get("errors", []).is_empty():
		file.store_line("- None")
	file.store_line("")
	file.store_line("## Warnings")
	for warning in report.get("warnings", []):
		file.store_line("- " + String(warning))
	if report.get("warnings", []).is_empty():
		file.store_line("- None")
	file.close()


static func _validate_definition(definition: Resource, report: Dictionary) -> void:
	if definition.mission_id == "":
		_add_error(report, "mission_id is required.")
	if definition.display_name == "":
		_add_warning(report, "display_name is empty.")
	if definition.primary_objectives.is_empty():
		_add_error(report, "At least one primary objective is required.")
	if definition.evidence_clues.is_empty():
		_add_error(report, "At least one evidence clue is required.")
	if definition.scheme_card_rewards.is_empty():
		_add_error(report, "At least one reward is required.")
	if definition.collectibles.is_empty():
		_add_error(report, "At least one collectible is required.")
	var has_polaroid := false
	var has_poop := 0
	for collectible in definition.collectibles:
		if collectible == null:
			continue
		if int(collectible.type) == 0:
			has_polaroid = true
		if int(collectible.type) == 5:
			has_poop += 1
	if not has_polaroid:
		_add_warning(report, "Mission has no Polaroid collectible.")
	if has_poop < 3:
		_add_warning(report, "Mission has fewer than three Bentley poop bags.")
	for connection in definition.final_tower_connections:
		if connection.strip_edges() == "":
			_add_error(report, "Empty final tower connection entry.")


static func _validate_scene(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	for path in REQUIRED_LAYER_PATHS:
		if scene_root.get_node_or_null(path) == null:
			_add_error(report, "Missing required node: " + path)
	var spawn_points := scene_root.get_node_or_null("GameplayRoot/SpawnPoints")
	if spawn_points != null and spawn_points.get_child_count() != 1:
		_add_warning(report, "Expected one generated player spawn marker; found " + str(spawn_points.get_child_count()) + ".")
	var exit_areas := scene_root.get_node_or_null("GameplayRoot/ExitAreas")
	if exit_areas == null or exit_areas.get_child_count() < 1:
		_add_error(report, "At least one exit area is required.")
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if collision_layer == null or collision_layer.get_used_cells().is_empty():
		_add_error(report, "GameplayCollisionLayer has no blocking boundary cells.")
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	if floor_layer == null or floor_layer.get_used_cells().is_empty():
		_add_error(report, "GameplayFloorLayer has no walkable floor cells.")
	var camera := scene_root.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		_add_error(report, "Camera2D missing.")
	elif camera.limit_right <= camera.limit_left or camera.limit_bottom <= camera.limit_top:
		_add_error(report, "Camera2D bounds are invalid.")
	_validate_named_references(definition, scene_root, report)


static func _validate_named_references(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var objective_parent := scene_root.get_node_or_null("GameplayRoot/ObjectiveAreas")
	if objective_parent:
		for objective in definition.primary_objectives:
			if objective == null:
				continue
			if objective_parent.get_node_or_null("Objective_" + objective.objective_id) == null:
				_add_warning(report, "Primary objective node not generated: " + objective.objective_id)
	var interactables := scene_root.get_node_or_null("EntityRoot/Interactables")
	if interactables:
		for clue in definition.evidence_clues:
			if clue != null and interactables.get_node_or_null("Clue_" + clue.clue_id) == null:
				_add_warning(report, "Clue node not generated: " + clue.clue_id)
	for reward in definition.scheme_card_rewards:
		if reward == null:
			continue
		var info := GameState.get_mission_info(definition.mission_id)
		var catalog_rewards: Array = info.get("reward_cards", [])
		if int(reward.type) == 0 and not catalog_rewards.has(reward.reward_id):
			_add_warning(report, "Reward not currently in GameState.mission_catalog: " + reward.reward_id)


static func _add_error(report: Dictionary, message: String) -> void:
	report["ok"] = false
	report["errors"].append(message)


static func _add_warning(report: Dictionary, message: String) -> void:
	report["warnings"].append(message)
