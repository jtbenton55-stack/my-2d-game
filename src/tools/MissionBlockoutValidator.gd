class_name MissionBlockoutValidator
extends RefCounted

const REQUIRED_LAYER_PATHS: Array[String] = [
	"GameplayRoot",
	"GameplayRoot/GameplayFloorLayer",
	"GameplayRoot/GameplayCollisionLayer",
	"GameplayRoot/GameplayMarkersLayer",
	"GameplayRoot/BoundaryColliders",
	"GameplayRoot/ObjectiveAreas",
	"GameplayRoot/ExitAreas",
	"GameplayRoot/SpawnPoints",
	"GameplayRoot/EnemyPaths",
	"GameplayRoot/AuthoringMarkers",
	"GameplayRoot/Subareas",
	"GameplayRoot/RuntimeSystems",
	"GameplayRoot/RuntimeSystems/SpawnedGuards",
	"GameplayRoot/RuntimeSystems/SpawnedCameras",
	"GameplayRoot/RuntimeSystems/LightZones",
	"GameplayRoot/RuntimeSystems/DetectionZones",
	"GameplayRoot/RuntimeSystems/AlarmZones",
	"GameplayRoot/RuntimeSystems/EncounterZones",
	"GameplayRoot/RuntimeSystems/RouteAccessPoints",
	"GameplayRoot/RuntimeSystems/TransitionTriggers",
	"GameplayRoot/RuntimeSystems/DebugLabels",
	"GameplayRoot/RuntimeSystems/DebugUI",
	"ArtRoot",
	"ArtRoot/GroundArtLayer",
	"ArtRoot/WallArtLayer",
	"ArtRoot/PropArtLayer",
	"ArtRoot/DecorBelowLayer",
	"ArtRoot/DecorAboveLayer",
	"ArtRoot/LightingLayer",
	"ArtRoot/LightingArtLayer",
	"EntityRoot",
	"EntityRoot/Enemies",
	"EntityRoot/Cameras",
	"EntityRoot/Interactables",
	"EntityRoot/DynamicProps",
	"Camera2D",
	"MissionController",
]

const TILE_WALL := Vector2i(1, 0)
const TILE_COVER := Vector2i(2, 0)
const MIN_REQUIRED_PASSAGE_WIDTH_CELLS := 3
const MIN_OPTIONAL_PASSAGE_WIDTH_CELLS := 2
const MIN_EXIT_APPROACH_WIDTH_CELLS := 3
const PLAYER_CLEARANCE_PADDING_PX := 4.0
const ISO_PLAYER_COLLISION_TARGET_SIZE := Vector2(24, 24)


static func validate(definition: Resource, scene_root: Node = null) -> Dictionary:
	var report := {
		"mission_id": definition.mission_id if definition != null else "",
		"ok": true,
		"errors": [],
		"warnings": [],
		"debug": {},
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
	if not _has_final_tower_logistics_connection(definition):
		_add_error(report, "Mission must include a final tower delivery/logistics dependency connection.")
	if String(definition.implementation_status).strip_edges() == "":
		_add_warning(report, "implementation_status is empty.")
	var mode := "generated"
	if definition.has_method("get"):
		var mode_value = definition.get("authoring_mode")
		if mode_value != null and String(mode_value).strip_edges() != "":
			mode = String(mode_value)
	if not ["generated", "scene_authored", "hybrid"].has(mode):
		_add_error(report, "authoring_mode must be generated, scene_authored, or hybrid.")


static func _has_final_tower_logistics_connection(definition: Resource) -> bool:
	for connection in definition.final_tower_connections:
		var text := String(connection).to_lower()
		if text.contains("delivery") or text.contains("logistics"):
			return true
	return false


static func _validate_scene(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	debug["scene_path"] = String(scene_root.scene_file_path)
	report["debug"] = debug
	for path in REQUIRED_LAYER_PATHS:
		if scene_root.get_node_or_null(path) == null:
			_add_error(report, "Missing required node: " + path)
	var spawn_points := scene_root.get_node_or_null("GameplayRoot/SpawnPoints")
	if spawn_points != null and spawn_points.get_child_count() < 1:
		_add_error(report, "Expected at least one spawn marker in GameplayRoot/SpawnPoints.")
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
	_validate_reachability(definition, scene_root, report)
	_validate_boundary_integrity(definition, scene_root, report)
	_validate_spawn_clearance(definition, scene_root, report)
	_validate_passage_clearance(definition, scene_root, report)
	_validate_exit_setup(definition, scene_root, report)
	_validate_interactable_setup(definition, scene_root, report)
	_validate_interactable_spacing(definition, report)
	_validate_authoring_contract(definition, scene_root, report)
	_validate_interaction_runtime_priority(scene_root, report)
	_validate_runtime_systems(definition, scene_root, report)
	_validate_typed_system_data(definition, report)
	_validate_cover_collision(scene_root, report)
	if definition.mission_id == "taco_bell_drop":
		_validate_taco_bell_layout(definition, scene_root, report)


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


static func _validate_reachability(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var marker_layer := scene_root.get_node_or_null("GameplayRoot/GameplayMarkersLayer") as TileMapLayer
	if floor_layer == null or collision_layer == null:
		return
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	var blocked_cells := _cell_set(collision_layer.get_used_cells())
	var reachable := _reachable_cells(_spawn_cell(definition), floor_cells, blocked_cells)
	var debug: Dictionary = report.get("debug", {})
	debug["floor_cell_count"] = floor_cells.size()
	debug["collision_cell_count"] = blocked_cells.size()
	debug["marker_cell_count"] = marker_layer.get_used_cells().size() if marker_layer != null else 0
	debug["non_wall_tiles_with_collision"] = _non_wall_tiles_with_collision(scene_root)
	var required_objectives := _required_target_ids_and_cells(definition.primary_objectives, "objective_id")
	var required_clues := _required_target_ids_and_cells(definition.evidence_clues, "clue_id")
	var required_collectibles := _required_target_ids_and_cells(definition.collectibles, "collectible_id")
	var unreachable_objectives := _unreachable_ids(required_objectives, reachable)
	var unreachable_clues := _unreachable_ids(required_clues, reachable)
	var unreachable_collectibles := _unreachable_ids(required_collectibles, reachable)
	var exit_cell := _exit_cell(definition)
	var reachable_exit := reachable.has(exit_cell)
	debug["reachable_required_objective_count"] = required_objectives.size() - unreachable_objectives.size()
	debug["unreachable_required_objective_ids"] = unreachable_objectives
	debug["reachable_exit"] = reachable_exit
	debug["reachable_clue_count"] = required_clues.size() - unreachable_clues.size()
	debug["unreachable_clue_ids"] = unreachable_clues
	debug["reachable_required_collectible_count"] = required_collectibles.size() - unreachable_collectibles.size()
	debug["unreachable_required_collectible_ids"] = unreachable_collectibles
	report["debug"] = debug
	if not reachable_exit:
		_add_error(report, "Player spawn cannot reach exit cell " + str(exit_cell) + ".")
	if not unreachable_objectives.is_empty():
		_add_error(report, "Unreachable required objectives: " + ", ".join(unreachable_objectives))
	if not unreachable_clues.is_empty():
		_add_error(report, "Unreachable required clues: " + ", ".join(unreachable_clues))
	if not unreachable_collectibles.is_empty():
		_add_error(report, "Unreachable required collectibles: " + ", ".join(unreachable_collectibles))
	var non_wall_collision: Array = debug["non_wall_tiles_with_collision"]
	if not non_wall_collision.is_empty():
		_add_error(report, "Non-wall marker/floor tiles have collision: " + str(non_wall_collision))


static func _validate_boundary_integrity(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var boundary := scene_root.get_node_or_null("GameplayRoot/BoundaryColliders") as Node2D
	if floor_layer == null or collision_layer == null:
		return
	var debug: Dictionary = report.get("debug", {})
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	var boundary_ok := boundary != null and boundary.get_child_count() >= 4
	debug["boundary_colliders_exist"] = boundary != null
	debug["boundary_collider_count"] = boundary.get_child_count() if boundary != null else 0
	debug["outer_collision_surrounds_floor"] = _outer_collision_surrounds_floor(floor_cells, _cell_set(collision_layer.get_used_cells()))
	debug["required_targets_outside_floor"] = _required_targets_outside_floor(definition, floor_cells)
	debug["all_markers_outside_floor"] = _all_markers_outside_floor(definition, floor_cells)
	debug["internal_transition_blocker_count"] = _internal_transition_blocker_count(definition, collision_layer)
	debug["outside_escape_risk_cells"] = _outside_escape_risk_cells(definition, floor_cells)
	debug["required_targets_inside_boundary_collision"] = _targets_inside_boundary_collision(definition, scene_root, floor_layer)
	debug["collectibles_inside_boundary_collision"] = _collectibles_inside_boundary_collision(definition, scene_root, floor_layer)
	report["debug"] = debug
	if not boundary_ok:
		_add_error(report, "GameplayRoot/BoundaryColliders must exist with generated edge colliders.")
	if not bool(debug["outer_collision_surrounds_floor"]):
		if _is_editable_scene(scene_root):
			_add_warning(report, "GameplayCollisionLayer does not fully surround the editable scene footprint (verify subareas).")
		else:
			_add_error(report, "GameplayCollisionLayer does not surround the playable floor footprint.")
	var outside_targets: Array = debug["required_targets_outside_floor"]
	if not outside_targets.is_empty():
		_add_error(report, "Required targets outside playable floor: " + ", ".join(outside_targets))
	var outside_markers: Array = debug["all_markers_outside_floor"]
	if not outside_markers.is_empty():
		_add_error(report, "Mission markers outside playable floor: " + ", ".join(outside_markers))
	if int(debug["internal_transition_blocker_count"]) > 0:
		if _is_editable_scene(scene_root):
			_add_warning(report, "Internal zone transitions contain collision blockers in editable scene.")
		else:
			_add_error(report, "Internal zone transitions contain collision blockers.")
	var escape_risk: Array = debug["outside_escape_risk_cells"]
	if not escape_risk.is_empty():
		_add_error(report, "Outside test cells are marked floor/reachable risk: " + str(escape_risk))
	var target_overlaps: Array = debug["required_targets_inside_boundary_collision"]
	if not target_overlaps.is_empty():
		_add_warning(report, "Required targets may overlap BoundaryColliders: " + ", ".join(target_overlaps))
	var collectible_overlaps: Array = debug["collectibles_inside_boundary_collision"]
	if not collectible_overlaps.is_empty():
		_add_warning(report, "Collectibles may overlap BoundaryColliders: " + ", ".join(collectible_overlaps))


static func _validate_spawn_clearance(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if floor_layer == null or collision_layer == null:
		return
	var debug: Dictionary = report.get("debug", {})
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	var blocked_cells := _cell_set(collision_layer.get_used_cells())
	var spawn := _spawn_cell(definition)
	var clearance_missing: Array[Vector2i] = []
	var clearance_blocked: Array[Vector2i] = []
	for x in range(spawn.x - 1, spawn.x + 2):
		for y in range(spawn.y - 1, spawn.y + 2):
			var cell := Vector2i(x, y)
			if not floor_cells.has(cell):
				clearance_missing.append(cell)
			elif blocked_cells.has(cell):
				clearance_blocked.append(cell)
	var start_zone := _zone_by_id(definition, "city_hub_entrance")
	var market_zone := _zone_by_id(definition, "midnight_market_street")
	var start_floor_count := _zone_floor_count(start_zone, floor_cells)
	var start_market_width := _zone_shared_edge_width(start_zone, market_zone, floor_cells, blocked_cells)
	var nearby_blocking_areas := _blocking_collision_objects_near(scene_root, floor_layer.to_global(floor_layer.map_to_local(spawn)), 48.0)
	debug["spawn_cell"] = spawn
	debug["spawn_clearance_missing_floor"] = clearance_missing
	debug["spawn_clearance_blocked_cells"] = clearance_blocked
	debug["start_zone_floor_cell_count"] = start_floor_count
	debug["start_market_entrance_width"] = start_market_width
	debug["blocking_collision_objects_near_spawn"] = nearby_blocking_areas
	report["debug"] = debug
	if not floor_cells.has(spawn):
		_add_error(report, "Player spawn is not on playable floor: " + str(spawn))
	if blocked_cells.has(spawn):
		_add_error(report, "Player spawn is inside a wall/cover collision cell: " + str(spawn))
	if not clearance_missing.is_empty():
		_add_error(report, "Player spawn lacks 3x3 floor clearance: " + str(clearance_missing))
	if not clearance_blocked.is_empty():
		_add_error(report, "Player spawn 3x3 clearance contains blocking cells: " + str(clearance_blocked))
	if start_floor_count < 35:
		_add_error(report, "Start/Louis area is too small; expected at least 35 floor cells, found " + str(start_floor_count) + ".")
	if start_market_width < 2:
		_add_error(report, "Start-to-Market entrance must be at least 2 open cells wide; found " + str(start_market_width) + ".")
	if not nearby_blocking_areas.is_empty():
		_add_error(report, "Blocking CollisionObject2D nodes are too close to spawn: " + ", ".join(nearby_blocking_areas))


static func _validate_passage_clearance(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if floor_layer == null or collision_layer == null:
		return
	var floor_cells := _cell_set(floor_layer.get_used_cells())
	var blocked_cells := _cell_set(collision_layer.get_used_cells())
	var debug: Dictionary = report.get("debug", {})
	var required_pairs := [
		["city_hub_entrance", "midnight_market_street"],
		["midnight_market_street", "delivery_alley"],
		["delivery_alley", "real_scent_trail_parking_garage"],
		["real_scent_trail_parking_garage", "parking_garage_floor_1"],
		["parking_garage_floor_1", "garage_office"],
		["garage_office", "garage_floor_2_ambush"],
		["garage_floor_2_ambush", "bag_recovery_room"],
		["bag_recovery_room", "south_return_drop"],
		["south_return_drop", "south_return_corridor"],
		["south_return_corridor", "escape_return_to_louis"],
	]
	var narrow_required: Array[String] = []
	var min_width := 999999
	for pair in required_pairs:
		var width := _zone_connection_width(_zone_by_id(definition, pair[0]), _zone_by_id(definition, pair[1]), floor_cells, blocked_cells)
		min_width = mini(min_width, width)
		if width < MIN_REQUIRED_PASSAGE_WIDTH_CELLS:
			narrow_required.append(pair[0] + " -> " + pair[1] + " width " + str(width))
	var return_zone := _zone_by_id(definition, "south_return_corridor")
	var return_width := _zone_short_axis_width(return_zone)
	var exit_width := _zone_connection_width(return_zone, _zone_by_id(definition, "escape_return_to_louis"), floor_cells, blocked_cells)
	var narrow_return: Array[String] = []
	if return_width < MIN_REQUIRED_PASSAGE_WIDTH_CELLS:
		narrow_return.append("south_return_corridor short axis " + str(return_width))
	if exit_width < MIN_EXIT_APPROACH_WIDTH_CELLS:
		narrow_return.append("south_return_corridor -> escape_return_to_louis width " + str(exit_width))
	var player_info := _player_clearance_info(scene_root)
	debug["narrow_required_passages"] = narrow_required
	debug["narrow_exit_approach_cells"] = [] if exit_width >= MIN_EXIT_APPROACH_WIDTH_CELLS else ["escape_return_to_louis"]
	debug["narrow_return_corridor_cells"] = narrow_return
	debug["min_required_route_width_found"] = min_width if min_width != 999999 else 0
	debug["player_clearance_radius_px"] = player_info.get("clearance_radius_px", 0.0)
	debug["iso_player_collision_override_active"] = player_info.get("iso_collision_override_active", false)
	debug["iso_player_collision_size"] = player_info.get("collision_size", Vector2.ZERO)
	report["debug"] = debug
	if not narrow_required.is_empty():
		_add_error(report, "Required route passages are narrower than " + str(MIN_REQUIRED_PASSAGE_WIDTH_CELLS) + " cells: " + "; ".join(narrow_required))
	if not narrow_return.is_empty():
		_add_error(report, "South return / exit approach clearance failed: " + "; ".join(narrow_return))
	if not bool(player_info.get("iso_collision_override_active", false)):
		_add_warning(report, "Iso player collision override is not active; physical passage checks may be too optimistic.")


static func _validate_exit_setup(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var exits := scene_root.get_node_or_null("GameplayRoot/ExitAreas")
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var exit_area_count := 0
	var exit_shape_count := 0
	var exit_interactable_count := 0
	var exit_body_entered_connected_count := 0
	var exit_overlaps_expected_cell := false
	var exit_has_player_mask := false
	if exits != null:
		for child in exits.get_children():
			if not child is Area2D:
				continue
			exit_area_count += 1
			var area := child as Area2D
			if _area_has_collision_shape(area):
				exit_shape_count += 1
			if area.is_in_group("interactable") and area.has_method("interact"):
				exit_interactable_count += 1
			if area.body_entered.get_connections().size() > 0:
				exit_body_entered_connected_count += 1
			if (area.collision_mask & 1) != 0:
				exit_has_player_mask = true
			if floor_layer != null:
				var expected_pos := floor_layer.to_global(floor_layer.map_to_local(_exit_cell(definition)))
				var marker_root := scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
				var exit_marker := _find_scene_marker(marker_root, "exit_return_to_louis")
				if exit_marker == null:
					exit_marker = _find_scene_marker(marker_root, "exit")
				if exit_marker != null and exit_marker is Node2D:
					expected_pos = (exit_marker as Node2D).global_position
				if area.global_position.distance_to(expected_pos) <= 8.0:
					exit_overlaps_expected_cell = true
			if not area.monitoring:
				_add_error(report, "Exit Area2D monitoring must be enabled.")
			if not area.monitorable:
				_add_warning(report, "Exit Area2D monitorable is disabled; enable it unless intentionally trigger-only.")
	debug["exit_area_count"] = exit_area_count
	debug["exit_collision_shape_count"] = exit_shape_count
	debug["exit_interactable_count"] = exit_interactable_count
	debug["exit_body_entered_connected_count"] = exit_body_entered_connected_count
	debug["exit_overlaps_expected_cell"] = exit_overlaps_expected_cell
	debug["exit_has_player_collision_mask"] = exit_has_player_mask
	debug["exit_uses_real_completion_path"] = scene_root.has_method("request_exit_completion") or scene_root.has_method("complete_level")
	report["debug"] = debug
	if exit_area_count < 1:
		_add_error(report, "Exit must generate at least one Area2D.")
	if exit_shape_count < 1:
		_add_error(report, "Exit Area2D must include a CollisionShape2D.")
	if exit_interactable_count < 1:
		_add_error(report, "Exit must be in group \"interactable\" and implement interact(player) for E support.")
	if exit_body_entered_connected_count < 1:
		_add_error(report, "Exit body_entered must be connected for walk-in completion.")
	if not exit_overlaps_expected_cell:
		_add_error(report, "Exit trigger does not overlap the expected exit marker cell.")
	if not exit_has_player_mask:
		_add_error(report, "Exit collision_mask must include the Player layer.")
	if not bool(debug["exit_uses_real_completion_path"]):
		_add_error(report, "Exit cannot call a real mission completion path.")


static func _validate_interactable_setup(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var missing: Array[String] = []
	var missing_shape: Array[String] = []
	var missing_label: Array[String] = []
	var checks: Dictionary = {}
	var objective_parent := scene_root.get_node_or_null("GameplayRoot/ObjectiveAreas")
	if objective_parent != null:
		for objective in definition.primary_objectives:
			if objective == null:
				continue
			checks[String(objective.objective_id)] = _find_interactable_by_property(objective_parent, "objective_id", String(objective.objective_id))
	var interactables := scene_root.get_node_or_null("EntityRoot/Interactables")
	var route_access_points := scene_root.get_node_or_null("GameplayRoot/RuntimeSystems/RouteAccessPoints")
	if interactables != null:
		for clue in definition.evidence_clues:
			if clue != null:
				checks[String(clue.clue_id)] = _find_interactable_by_property(interactables, "clue_id", String(clue.clue_id))
		for collectible in definition.collectibles:
			if collectible != null:
				checks[String(collectible.collectible_id)] = _find_interactable_by_property(interactables, "collectible_id", String(collectible.collectible_id))
		for gate in definition.puzzle_gates:
			if gate == null:
				continue
			var gate_id := String(gate.gate_id)
			if gate_id == "garage_office_code":
				continue
			if gate_id.contains("vent_route") or gate_id.contains("future_shortcut"):
				var route_node := _find_interactable_by_property(route_access_points, "route_id", gate_id) if route_access_points != null else null
				checks[gate_id] = route_node
			else:
				checks[gate_id] = interactables.get_node_or_null("Gate_" + gate_id)
	var exit_parent := scene_root.get_node_or_null("GameplayRoot/ExitAreas")
	if exit_parent != null:
		checks["exit"] = _find_interactable_by_property(exit_parent, "placeholder_id", "exit")
	for id in checks.keys():
		var node := checks[id] as Node
		if node == null or not node.is_in_group("interactable") or not node.has_method("interact"):
			missing.append(String(id))
			continue
		if node is Area2D and not _area_has_collision_shape(node as Area2D):
			missing_shape.append(String(id))
		if node.get_node_or_null("Label") == null and String(id) != "exit":
			missing_label.append(String(id))
	debug["required_interactables_checked"] = checks.size()
	debug["required_interactables_missing_support"] = missing
	debug["required_interactables_missing_shape"] = missing_shape
	debug["required_interactables_missing_debug_label"] = missing_label
	report["debug"] = debug
	if not missing.is_empty():
		_add_error(report, "Required interactables missing group/interact support: " + ", ".join(missing))
	if not missing_shape.is_empty():
		_add_error(report, "Required interactables missing Area2D collision/debug radius: " + ", ".join(missing_shape))
	if not missing_label.is_empty():
		_add_warning(report, "Required interactables missing debug label: " + ", ".join(missing_label))


static func _validate_interactable_spacing(definition: Resource, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var interactables := {}
	for item in definition.primary_objectives:
		if item != null:
			interactables["objective:" + String(item.objective_id)] = item.marker_cell
	for item in definition.evidence_clues:
		if item != null:
			interactables["clue:" + String(item.clue_id)] = item.marker_cell
	for item in definition.collectibles:
		if item != null:
			interactables["collectible:" + String(item.collectible_id)] = item.marker_cell
	for item in definition.puzzle_gates:
		if item != null:
			interactables["gate:" + String(item.gate_id)] = item.marker_cell
	var overlaps: Array[String] = []
	var keys := interactables.keys()
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			var a_id := String(keys[i])
			var b_id := String(keys[j])
			if a_id == "objective:solve_garage_office_code" and b_id == "gate:garage_office_code":
				continue
			if a_id == "gate:garage_office_code" and b_id == "objective:solve_garage_office_code":
				continue
			if interactables[a_id] == interactables[b_id]:
				overlaps.append(a_id + " overlaps " + b_id)
	debug["interactable_marker_overlaps"] = overlaps
	report["debug"] = debug
	if not overlaps.is_empty():
		_add_warning(report, "Interactable markers share cells and may shadow E interaction: " + "; ".join(overlaps))


static func _validate_cover_collision(scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var collision_layer := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	if collision_layer == null:
		return
	var cover_cells: Array[Vector2i] = []
	for cell in collision_layer.get_used_cells():
		if collision_layer.get_cell_atlas_coords(cell) == TILE_COVER:
			cover_cells.append(cell)
	debug["cover_cell_count"] = cover_cells.size()
	debug["cover_tile_has_collision"] = _tile_has_collision(collision_layer, TILE_COVER) if cover_cells.size() > 0 else true
	report["debug"] = debug
	if cover_cells.is_empty():
		_add_warning(report, "No intentional cover cells found in GameplayCollisionLayer.")
	elif not bool(debug["cover_tile_has_collision"]):
		_add_error(report, "Cover cells exist but the cover tile has no collision polygon.")


static func _validate_runtime_systems(_definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var runtime := scene_root.get_node_or_null("GameplayRoot/RuntimeSystems")
	if runtime == null:
		_add_error(report, "RuntimeSystems root missing under GameplayRoot.")
		return
	var spawned_guards := scene_root.get_node_or_null("EntityRoot/Enemies")
	var spawned_cameras := scene_root.get_node_or_null("EntityRoot/Cameras")
	var light_zones := runtime.get_node_or_null("LightZones")
	var detection_zones := runtime.get_node_or_null("DetectionZones")
	var alarm_zones := runtime.get_node_or_null("AlarmZones")
	var encounters := runtime.get_node_or_null("EncounterZones")
	var route_access := runtime.get_node_or_null("RouteAccessPoints")
	var transitions := runtime.get_node_or_null("TransitionTriggers")
	var debug_ui := runtime.get_node_or_null("DebugUI")
	var meta_debug: Dictionary = scene_root.get_meta("iso_runtime_debug", {})
	var enemy_iso_scale_ok := true
	var expected_scale := 0.86
	var expected_collision := Vector2(24, 24)
	var actual_scale := 0.0
	var actual_collision := Vector2.ZERO
	if spawned_guards != null and spawned_guards.get_child_count() > 0:
		for child in spawned_guards.get_children():
			var guard := child as Node2D
			if guard == null:
				continue
			var sprite := guard.get_node_or_null("AnimatedSprite2D") as Node2D
			var body := guard.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if sprite != null:
				actual_scale = maxf(actual_scale, sprite.scale.x)
				if absf(sprite.scale.x - expected_scale) > 0.03:
					enemy_iso_scale_ok = false
			if body != null and body.shape is RectangleShape2D:
				var size := (body.shape as RectangleShape2D).size
				actual_collision = size
				if absf(size.x - expected_collision.x) > 0.2 or absf(size.y - expected_collision.y) > 0.2:
					enemy_iso_scale_ok = false
	debug["runtime_marker_to_object_counts"] = meta_debug.get("marker_to_runtime_counts", {})
	debug["runtime_spawned_ids"] = meta_debug.get("spawned_runtime_ids", [])
	debug["authoring_mode"] = meta_debug.get("authoring_mode", "")
	debug["layout_source"] = meta_debug.get("layout_source", "")
	debug["marker_source"] = meta_debug.get("marker_source", "")
	debug["scene_markers_found"] = meta_debug.get("scene_markers_found", 0)
	debug["generated_markers_found"] = meta_debug.get("generated_markers_found", 0)
	debug["runtime_spawned_guard_count"] = spawned_guards.get_child_count() if spawned_guards != null else 0
	debug["runtime_spawned_camera_count"] = spawned_cameras.get_child_count() if spawned_cameras != null else 0
	debug["runtime_light_zone_count"] = light_zones.get_child_count() if light_zones != null else 0
	debug["runtime_detection_zone_count"] = detection_zones.get_child_count() if detection_zones != null else 0
	debug["runtime_alarm_zone_count"] = alarm_zones.get_child_count() if alarm_zones != null else 0
	debug["runtime_encounter_zone_count"] = encounters.get_child_count() if encounters != null else 0
	debug["runtime_route_access_count"] = route_access.get_child_count() if route_access != null else 0
	debug["runtime_transition_count"] = transitions.get_child_count() if transitions != null else 0
	debug["runtime_debug_ui_count"] = debug_ui.get_child_count() if debug_ui != null else 0
	debug["enemy_iso_scale_ok"] = enemy_iso_scale_ok
	debug["enemy_iso_expected_scale"] = expected_scale
	debug["enemy_iso_actual_scale"] = actual_scale
	debug["enemy_iso_expected_collision_size"] = expected_collision
	debug["enemy_iso_actual_collision_size"] = actual_collision
	debug["position_resolutions"] = meta_debug.get("position_resolutions", [])
	report["debug"] = debug
	if int(debug["runtime_spawned_guard_count"]) < 1:
		_add_error(report, "Expected at least one spawned guard runtime object.")
	if int(debug["runtime_spawned_camera_count"]) < 1:
		_add_error(report, "Expected at least one spawned security camera runtime object.")
	if int(debug["runtime_light_zone_count"]) < 3:
		_add_warning(report, "Expected at least three light zones (shadow/flicker/bright) for Taco Bell proof target.")
	if int(debug["runtime_encounter_zone_count"]) < 1:
		_add_error(report, "Expected at least one encounter/ambush trigger runtime object.")
	if int(debug["runtime_route_access_count"]) < 2:
		_add_warning(report, "Expected route access runtime points (keycard/vent/future shortcut).")
	if int(debug["runtime_transition_count"]) < 1:
		_add_warning(report, "Expected at least one transition placeholder runtime trigger.")
	if not bool(debug["enemy_iso_scale_ok"]):
		_add_error(report, "Runtime guard does not match expected iso enemy profile (scale/collision).")


static func _validate_authoring_contract(definition: Resource, scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var marker_root := scene_root.get_node_or_null("GameplayRoot/AuthoringMarkers")
	var modern_marker_root := scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	var mode := "generated"
	if definition.has_method("get"):
		var mode_value = definition.get("authoring_mode")
		if mode_value != null and String(mode_value).strip_edges() != "":
			mode = String(mode_value)
	var approved := {
		"floor": true, "wall": true, "cover": true, "collision_barrier": true, "hazard": true, "decor_placeholder": true,
		"player_spawn": true, "bentley_spawn": true, "guard_spawn": true, "ambush_guard_spawn": true, "extra_heat_guard_spawn": true,
		"patrol_point": true, "security_camera": true, "camera_cone": true, "camera_terminal": true, "alarm_zone": true, "detection_zone": true,
		"shadow_zone": true, "bright_zone": true, "flicker_zone": true, "louis": true, "objective": true, "clue": true, "keycard": true,
		"code_gate": true, "route_access": true, "transition": true, "exit": true, "polaroid_hidden": true, "polaroid_completion": true,
		"polaroid_perfect": true, "glow_guy": true, "tiny_icon": true, "poop_bag": true, "scent_trail_real": true, "scent_trail_fake": true,
		"bentley_sniff_zone": true, "bentley_vent_route": true, "bentley_exit": true, "ambush_trigger": true, "camera_shake_trigger": true,
		"alarm_trigger": true, "dialogue_trigger": true, "subarea_spawn": true, "transition_entry": true, "transition_exit": true, "return_spawn": true
	}
	var unknown: Array[String] = []
	var duplicate_ids: Array[String] = []
	var id_seen := {}
	var duplicate_seen := {}
	var required_missing: Array[String] = []
	var markers_outside_floor: Array[String] = []
	var markers_inside_blocking: Array[String] = []
	var found := 0
	var floor_layer := scene_root.get_node_or_null("GameplayRoot/GameplayFloorLayer") as TileMapLayer
	var collision := scene_root.get_node_or_null("GameplayRoot/GameplayCollisionLayer") as TileMapLayer
	var marker_nodes := _collect_scene_marker_nodes(modern_marker_root if modern_marker_root != null else marker_root)
	if marker_nodes.size() > 0:
		for marker in marker_nodes:
			if not marker.has_method("get"):
				continue
			var marker_type := String(marker.get("marker_type")).to_lower()
			if marker_type == "":
				continue
			found += 1
			if not approved.has(marker_type):
				unknown.append(marker_type)
			var marker_id := _safe_marker_string(marker.get("marker_id"))
			if marker_id != "":
				if id_seen.has(marker_id):
					if not duplicate_seen.has(marker_id):
						duplicate_seen[marker_id] = true
						duplicate_ids.append(marker_id)
				id_seen[marker_id] = true
			if floor_layer != null and marker is Node2D:
				var cell := floor_layer.local_to_map(floor_layer.to_local((marker as Node2D).global_position))
				if not _cell_set(floor_layer.get_used_cells()).has(cell):
					markers_outside_floor.append(marker_id if marker_id != "" else _safe_marker_string(marker.name))
				if _cell_set(collision.get_used_cells()).has(cell):
					markers_inside_blocking.append(marker_id if marker_id != "" else _safe_marker_string(marker.name))
	var required_ids := ["player_spawn_main", "bentley_spawn_main", "exit_return_to_louis", "clue_velvet_paw_stamp", "code_gate_garage_office", "route_bentley_vent", "scent_real_parking_garage", "poop_bag_dog_station"]
	for rid in required_ids:
		if not id_seen.has(rid):
			required_missing.append(rid)
	var layout_floor := scene_root.get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer") as TileMapLayer
	var layout_wall := scene_root.get_node_or_null("GameplayRoot/LayoutRoot/WallLayer") as TileMapLayer
	var layout_cover := scene_root.get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer") as TileMapLayer
	var layout_barrier := scene_root.get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer") as TileMapLayer
	debug["authoring_mode"] = mode
	debug["authoring_marker_count"] = found
	debug["unknown_marker_types"] = unknown
	debug["duplicate_marker_ids"] = duplicate_ids
	debug["required_missing_markers"] = required_missing
	debug["markers_outside_floor"] = markers_outside_floor
	debug["markers_inside_blocking_collision"] = markers_inside_blocking
	debug["floor_cell_count"] = layout_floor.get_used_cells().size() if layout_floor != null else 0
	debug["wall_cell_count"] = layout_wall.get_used_cells().size() if layout_wall != null else 0
	debug["cover_cell_count"] = layout_cover.get_used_cells().size() if layout_cover != null else 0
	debug["barrier_cell_count"] = layout_barrier.get_used_cells().size() if layout_barrier != null else 0
	debug["player_spawn_found"] = id_seen.has("player_spawn_main") or id_seen.has("start_main")
	debug["bentley_spawn_found"] = id_seen.has("bentley_spawn_main")
	debug["required_clue_count"] = _count_markers_by_type(marker_nodes, "clue")
	debug["collectible_count"] = _count_collectible_markers(marker_nodes)
	debug["guard_spawn_count"] = _count_markers_by_type(marker_nodes, "guard_spawn")
	debug["patrol_point_count"] = _count_markers_by_type(marker_nodes, "patrol_point")
	debug["route_access_count"] = _count_markers_by_type(marker_nodes, "route_access")
	debug["transition_count"] = _count_markers_by_type(marker_nodes, "transition")
	debug["exit_found"] = _count_markers_by_type(marker_nodes, "exit") > 0
	report["debug"] = debug
	if mode != "generated" and found <= 0:
		_add_warning(report, "authoring_mode is %s but no scene authoring markers were found." % mode)
	if not unknown.is_empty():
		_add_warning(report, "Unknown authoring marker types: " + ", ".join(unknown))
	if not duplicate_ids.is_empty():
		_add_error(report, "Duplicate marker_id values found: " + ", ".join(duplicate_ids))
	if not required_missing.is_empty():
		_add_error(report, "Required scene markers missing: " + ", ".join(required_missing))
	if not markers_outside_floor.is_empty():
		_add_error(report, "Markers placed outside floor cells: " + ", ".join(markers_outside_floor))
	if not markers_inside_blocking.is_empty():
		_add_error(report, "Markers placed inside blocking collision cells: " + ", ".join(markers_inside_blocking))


static func _validate_interaction_runtime_priority(scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var interactables := _collect_interactable_nodes(scene_root)
	var overlap_ids: Array[String] = []
	var conflicts: Array[String] = []
	for i in range(interactables.size()):
		for j in range(i + 1, interactables.size()):
			var a: Node = interactables[i]
			var b: Node = interactables[j]
			if not (a is Node2D and b is Node2D):
				continue
			var d := (a as Node2D).global_position.distance_to((b as Node2D).global_position)
			if d > 72.0:
				continue
			overlap_ids.append(String(a.name) + " <-> " + String(b.name))
			var ap := int(a.call("get_interaction_priority", null)) if a.has_method("get_interaction_priority") else 0
			var bp := int(b.call("get_interaction_priority", null)) if b.has_method("get_interaction_priority") else 0
			if ap == bp:
				conflicts.append(String(a.name) + " vs " + String(b.name) + " equal priority")
	debug["overlapping_interactables"] = overlap_ids
	debug["interaction_priority_conflicts"] = conflicts
	report["debug"] = debug
	if overlap_ids.size() > 0:
		_add_warning(report, "Interactables overlap within 72px and may compete for input: " + str(overlap_ids.slice(0, min(8, overlap_ids.size()))))
	var mismatches := _runtime_position_mismatches(scene_root)
	var ignored := _hybrid_scene_marker_ignored(scene_root, debug.get("position_resolutions", []))
	debug["runtime_position_mismatches"] = mismatches
	debug["hybrid_ignored_scene_markers"] = ignored
	report["debug"] = debug
	if not mismatches.is_empty():
		_add_error(report, "Runtime position mismatch vs marker nodes: " + ", ".join(mismatches))
	if not ignored.is_empty():
		_add_error(report, "Hybrid mode ignored scene marker for: " + ", ".join(ignored))


static func _collect_interactable_nodes(root: Node) -> Array:
	var out: Array = []
	_collect_interactable_nodes_recursive(root, out)
	return out


static func _collect_interactable_nodes_recursive(node: Node, out: Array) -> void:
	if node.is_in_group("interactable"):
		out.append(node)
	for child in node.get_children():
		_collect_interactable_nodes_recursive(child, out)


static func _collect_scene_marker_nodes(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	_collect_scene_marker_nodes_recursive(root, out)
	return out


static func _collect_scene_marker_nodes_recursive(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child.has_method("get") and child.get("marker_type") != null:
			out.append(child)
		_collect_scene_marker_nodes_recursive(child, out)


static func _count_markers_by_type(nodes: Array, marker_type: String) -> int:
	var count := 0
	for node in nodes:
		if String(node.get("marker_type")).to_lower() == marker_type:
			count += 1
	return count


static func _count_collectible_markers(nodes: Array) -> int:
	var collect_types := {"polaroid_hidden": true, "polaroid_completion": true, "polaroid_perfect": true, "glow_guy": true, "tiny_icon": true, "poop_bag": true}
	var count := 0
	for node in nodes:
		if collect_types.has(String(node.get("marker_type")).to_lower()):
			count += 1
	return count


static func _runtime_position_mismatches(scene_root: Node) -> Array[String]:
	var out: Array[String] = []
	var meta_debug: Dictionary = scene_root.get_meta("iso_runtime_debug", {})
	for entry in meta_debug.get("position_resolutions", []):
		if not (entry is Dictionary):
			continue
		var source := _safe_marker_string(entry.get("resolved_from"))
		var object_id := _safe_marker_string(entry.get("object_id"))
		var delta: Variant = entry.get("position_delta")
		if source != "scene_marker" or object_id == "":
			continue
		if delta is Vector2 and (delta as Vector2).length() > 6.0:
			out.append(object_id)
	return out


static func _hybrid_scene_marker_ignored(scene_root: Node, resolutions: Array) -> Array[String]:
	var out: Array[String] = []
	var mode := _safe_marker_string(scene_root.get_meta("iso_runtime_debug", {}).get("authoring_mode"))
	if mode != "hybrid":
		return out
	for entry in resolutions:
		if not (entry is Dictionary):
			continue
		var source := _safe_marker_string(entry.get("resolved_from"))
		var marker_id := _safe_marker_string(entry.get("marker_id"))
		if marker_id != "" and source == "definition_fallback":
			out.append(_safe_marker_string(entry.get("object_id")))
	return out


static func _find_interactable_by_property(root: Node, property_name: String, value: String) -> Node:
	if root == null or value == "":
		return null
	for child in root.get_children():
		if child.has_method("get"):
			var prop := _safe_marker_string(child.get(property_name))
			var placeholder := _safe_marker_string(child.get("placeholder_id"))
			if prop == value or placeholder == value:
				return child
		var nested := _find_interactable_by_property(child, property_name, value)
		if nested != null:
			return nested
	return null


static func _find_scene_marker(root: Node, marker_id: String) -> Node:
	if root == null:
		return null
	for child in root.get_children():
		if child.has_method("get") and _safe_marker_string(child.get("marker_id")) == marker_id:
			return child
		var nested := _find_scene_marker(child, marker_id)
		if nested != null:
			return nested
	return null


static func _is_editable_scene(scene_root: Node) -> bool:
	var scene_path := String(scene_root.scene_file_path)
	return scene_path.contains("TacoBellIso_Editable")


static func _safe_marker_string(value: Variant) -> String:
	if value == null:
		return ""
	var text := String(value).strip_edges()
	if text == "<null>":
		return ""
	return text


static func _validate_typed_system_data(definition: Resource, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var missing_clue_meta: Array[String] = []
	for clue in definition.evidence_clues:
		if clue == null:
			continue
		if String(clue.clue_board_cluster).strip_edges() == "" and String(clue.connects_to).strip_edges() == "":
			missing_clue_meta.append(String(clue.clue_id))
	var missing_collectible_groups: Array[String] = []
	for collectible in definition.collectibles:
		if collectible == null:
			continue
		if String(collectible.collection_group).strip_edges() == "":
			missing_collectible_groups.append(String(collectible.collectible_id))
	var missing_route_messages: Array[String] = []
	for route in definition.routes:
		if route == null:
			continue
		if String(route.locked_message).strip_edges() == "" or String(route.unlocked_message).strip_edges() == "":
			missing_route_messages.append(String(route.route_id))
	debug["typed_missing_clue_meta"] = missing_clue_meta
	debug["typed_missing_collectible_groups"] = missing_collectible_groups
	debug["typed_missing_route_messages"] = missing_route_messages
	debug["typed_scheme_cards_unlocked"] = GameState.unlocked_scheme_cards.keys()
	debug["typed_evidence_clues_recorded"] = GameState.evidence_clues.keys()
	debug["typed_collectibles_recorded"] = GameState.typed_collectibles.keys()
	debug["typed_crew_assists"] = GameState.crew_assists.keys()
	report["debug"] = debug
	if not missing_clue_meta.is_empty():
		_add_warning(report, "Evidence clues missing clue_board_cluster/connects_to metadata: " + ", ".join(missing_clue_meta))
	if not missing_collectible_groups.is_empty():
		_add_warning(report, "Collectibles missing collection_group metadata: " + ", ".join(missing_collectible_groups))
	if not missing_route_messages.is_empty():
		_add_warning(report, "Route definitions missing locked/unlocked messages: " + ", ".join(missing_route_messages))


static func _validate_taco_bell_layout(definition: Resource, _scene_root: Node, report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	var zone_by_id := _zone_map(definition)
	var required_zones: Array[String] = [
		"city_hub_entrance",
		"midnight_market_street",
		"dog_station_alley",
		"delivery_alley",
		"fake_scent_trail_a_trash_area",
		"fake_scent_trail_b_loading_dock",
		"real_scent_trail_parking_garage",
		"parking_garage_floor_1",
		"security_booth_keycard_room",
		"garage_office",
		"garage_floor_2_ambush",
		"bag_recovery_room",
		"south_return_corridor",
		"escape_return_to_louis",
	]
	var missing_zones: Array[String] = []
	for zone_id in required_zones:
		if not zone_by_id.has(zone_id):
			missing_zones.append(zone_id)
	var connections := [
		["city_hub_entrance", "midnight_market_street"],
		["midnight_market_street", "dog_station_alley"],
		["midnight_market_street", "delivery_alley"],
		["delivery_alley", "fake_scent_trail_a_trash_area"],
		["delivery_alley", "fake_scent_trail_b_loading_dock"],
		["delivery_alley", "real_scent_trail_parking_garage"],
		["real_scent_trail_parking_garage", "parking_garage_floor_1"],
		["parking_garage_floor_1", "security_booth_keycard_room"],
		["parking_garage_floor_1", "garage_office"],
		["garage_office", "garage_floor_2_ambush"],
		["garage_floor_2_ambush", "bag_recovery_room"],
		["bag_recovery_room", "south_return_drop"],
		["south_return_drop", "south_return_corridor"],
		["south_return_corridor", "escape_return_to_louis"],
	]
	var missing_connections: Array[String] = []
	for pair in connections:
		if not zone_by_id.has(pair[0]) or not zone_by_id.has(pair[1]):
			continue
		if not _zones_touch_or_overlap(zone_by_id[pair[0]], zone_by_id[pair[1]]):
			missing_connections.append(pair[0] + " -> " + pair[1])
	var exit_west := false
	var return_loop := false
	var major_widths_ok := true
	if zone_by_id.has("escape_return_to_louis") and zone_by_id.has("bag_recovery_room"):
		exit_west = zone_by_id["escape_return_to_louis"].origin.x < zone_by_id["bag_recovery_room"].origin.x
	if zone_by_id.has("south_return_corridor") and zone_by_id.has("bag_recovery_room") and zone_by_id.has("city_hub_entrance"):
		var return_zone = zone_by_id["south_return_corridor"]
		return_loop = return_zone.origin.x <= zone_by_id["city_hub_entrance"].origin.x + zone_by_id["city_hub_entrance"].size.x and return_zone.origin.x + return_zone.size.x >= zone_by_id["bag_recovery_room"].origin.x
	for zone_id in ["midnight_market_street", "delivery_alley", "parking_garage_floor_1", "garage_floor_2_ambush", "bag_recovery_room"]:
		if zone_by_id.has(zone_id):
			var zone = zone_by_id[zone_id]
			if mini(zone.size.x, zone.size.y) < 4:
				major_widths_ok = false
	debug["taco_bell_missing_layout_zones"] = missing_zones
	debug["taco_bell_missing_zone_connections"] = missing_connections
	debug["taco_bell_exit_west_of_bag_room"] = exit_west
	debug["taco_bell_return_corridor_loops_west"] = return_loop
	debug["taco_bell_major_zone_widths_ok"] = major_widths_ok
	report["debug"] = debug
	if not missing_zones.is_empty():
		_add_error(report, "Taco Bell layout missing required zones: " + ", ".join(missing_zones))
	if not missing_connections.is_empty():
		_add_error(report, "Taco Bell layout missing required zone connections: " + ", ".join(missing_connections))
	if not exit_west:
		_add_error(report, "Taco Bell exit must be west of the bag recovery room.")
	if not return_loop:
		_add_error(report, "Taco Bell south return corridor must loop from bag recovery toward the west/start side.")
	if not major_widths_ok:
		_add_error(report, "Taco Bell major zones must be room-like, not one-tile corridors.")


static func _area_has_collision_shape(area: Area2D) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape := (child as CollisionShape2D).shape
			if shape != null and not (child as CollisionShape2D).disabled:
				return true
		if child is CollisionPolygon2D and not (child as CollisionPolygon2D).disabled:
			return true
	return false


static func _cell_set(cells: Array[Vector2i]) -> Dictionary:
	var out := {}
	for cell in cells:
		out[cell] = true
	return out


static func _zone_map(definition: Resource) -> Dictionary:
	var out := {}
	for zone in definition.zones:
		if zone == null:
			continue
		out[String(zone.zone_id)] = zone
	return out


static func _zone_by_id(definition: Resource, zone_id: String) -> Resource:
	for zone in definition.zones:
		if zone != null and String(zone.zone_id) == zone_id:
			return zone
	return null


static func _zone_floor_count(zone: Resource, floor_cells: Dictionary) -> int:
	if zone == null:
		return 0
	var count := 0
	for x in range(zone.origin.x, zone.origin.x + zone.size.x):
		for y in range(zone.origin.y, zone.origin.y + zone.size.y):
			if floor_cells.has(Vector2i(x, y)):
				count += 1
	return count


static func _zone_shared_edge_width(a: Resource, b: Resource, floor_cells: Dictionary, blocked_cells: Dictionary) -> int:
	return _zone_connection_width(a, b, floor_cells, blocked_cells)


static func _zone_connection_width(a: Resource, b: Resource, floor_cells: Dictionary, blocked_cells: Dictionary) -> int:
	if a == null or b == null:
		return 0
	var a_rect := Rect2i(a.origin, a.size)
	var b_rect := Rect2i(b.origin, b.size)
	var overlap_pos := Vector2i(maxi(a_rect.position.x, b_rect.position.x), maxi(a_rect.position.y, b_rect.position.y))
	var overlap_end := Vector2i(mini(a_rect.end.x, b_rect.end.x), mini(a_rect.end.y, b_rect.end.y))
	if overlap_end.x > overlap_pos.x and overlap_end.y > overlap_pos.y:
		var a_center := Vector2(a.origin) + Vector2(a.size) * 0.5
		var b_center := Vector2(b.origin) + Vector2(b.size) * 0.5
		var overlap_width := 0
		if absf(a_center.x - b_center.x) >= absf(a_center.y - b_center.y):
			for y in range(overlap_pos.y, overlap_end.y):
				if _has_open_cell_in_overlap_column_or_row(overlap_pos.x, overlap_end.x, y, true, floor_cells, blocked_cells):
					overlap_width += 1
		else:
			for x in range(overlap_pos.x, overlap_end.x):
				if _has_open_cell_in_overlap_column_or_row(overlap_pos.y, overlap_end.y, x, false, floor_cells, blocked_cells):
					overlap_width += 1
		return overlap_width
	var width := 0
	if a.origin.x + a.size.x == b.origin.x:
		var y0: int = maxi(a.origin.y, b.origin.y)
		var y1: int = mini(a.origin.y + a.size.y - 1, b.origin.y + b.size.y - 1)
		for y in range(y0, y1 + 1):
			var a_cell := Vector2i(a.origin.x + a.size.x - 1, y)
			var b_cell := Vector2i(b.origin.x, y)
			if floor_cells.has(a_cell) and floor_cells.has(b_cell) and not blocked_cells.has(a_cell) and not blocked_cells.has(b_cell):
				width += 1
	elif b.origin.x + b.size.x == a.origin.x:
		width = _zone_shared_edge_width(b, a, floor_cells, blocked_cells)
	elif a.origin.y + a.size.y == b.origin.y:
		var x0: int = maxi(a.origin.x, b.origin.x)
		var x1: int = mini(a.origin.x + a.size.x - 1, b.origin.x + b.size.x - 1)
		for x in range(x0, x1 + 1):
			var a_cell := Vector2i(x, a.origin.y + a.size.y - 1)
			var b_cell := Vector2i(x, b.origin.y)
			if floor_cells.has(a_cell) and floor_cells.has(b_cell) and not blocked_cells.has(a_cell) and not blocked_cells.has(b_cell):
				width += 1
	elif b.origin.y + b.size.y == a.origin.y:
		width = _zone_shared_edge_width(b, a, floor_cells, blocked_cells)
	return width


static func _has_open_cell_in_overlap_column_or_row(start: int, end: int, fixed: int, horizontal: bool, floor_cells: Dictionary, blocked_cells: Dictionary) -> bool:
	if horizontal:
		for x in range(start, end):
			var cell := Vector2i(x, fixed)
			if floor_cells.has(cell) and not blocked_cells.has(cell):
				return true
	else:
		for y in range(start, end):
			var cell := Vector2i(fixed, y)
			if floor_cells.has(cell) and not blocked_cells.has(cell):
				return true
	return false


static func _zone_short_axis_width(zone: Resource) -> int:
	if zone == null:
		return 0
	return mini(zone.size.x, zone.size.y)


static func _player_clearance_info(scene_root: Node) -> Dictionary:
	var out := {
		"collision_size": Vector2.ZERO,
		"clearance_radius_px": 0.0,
		"iso_collision_override_active": false,
	}
	var player := scene_root.get_tree().get_first_node_in_group("player")
	if player == null:
		return out
	var shape_node := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return out
	var size := (shape_node.shape as RectangleShape2D).size
	out["collision_size"] = size
	out["clearance_radius_px"] = maxf(size.x, size.y) * 0.5 + PLAYER_CLEARANCE_PADDING_PX
	out["iso_collision_override_active"] = size.x <= ISO_PLAYER_COLLISION_TARGET_SIZE.x and size.y <= ISO_PLAYER_COLLISION_TARGET_SIZE.y
	return out


static func _zones_touch_or_overlap(a: Resource, b: Resource) -> bool:
	var a_rect := Rect2i(a.origin, a.size)
	var b_rect := Rect2i(b.origin, b.size)
	var expanded := Rect2i(a_rect.position - Vector2i.ONE, a_rect.size + Vector2i(2, 2))
	return expanded.intersects(b_rect)


static func _tile_has_collision(layer: TileMapLayer, atlas_coords: Vector2i) -> bool:
	if layer.tile_set == null:
		return false
	var source := layer.tile_set.get_source(0) as TileSetAtlasSource
	if source == null:
		return false
	var tile_data := source.get_tile_data(atlas_coords, 0)
	if tile_data == null:
		return false
	return tile_data.get_collision_polygons_count(0) > 0


static func _blocking_collision_objects_near(root: Node, point: Vector2, radius: float) -> Array[String]:
	var out: Array[String] = []
	_collect_blocking_collision_objects_near(root, point, radius, out)
	return out


static func _collect_blocking_collision_objects_near(node: Node, point: Vector2, radius: float, out: Array[String]) -> void:
	if node is StaticBody2D or node is RigidBody2D or node is CharacterBody2D:
		var collision := node as CollisionObject2D
		if collision.collision_layer != 0 and collision.global_position.distance_to(point) <= radius:
			if not node is TileMapLayer and not node.is_in_group("player"):
				out.append(String(node.get_path()))
	for child in node.get_children():
		_collect_blocking_collision_objects_near(child, point, radius, out)


static func _reachable_cells(start: Vector2i, floor_cells: Dictionary, blocked_cells: Dictionary) -> Dictionary:
	var reachable := {}
	if not floor_cells.has(start) or blocked_cells.has(start):
		return reachable
	var queue: Array[Vector2i] = [start]
	reachable[start] = true
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + offset
			if reachable.has(next) or blocked_cells.has(next) or not floor_cells.has(next):
				continue
			reachable[next] = true
			queue.append(next)
	return reachable


static func _spawn_cell(definition: Resource) -> Vector2i:
	for spawn_def in definition.enemies:
		if spawn_def != null and int(spawn_def.type) == 0:
			return spawn_def.marker_cell
	return Vector2i.ZERO


static func _exit_cell(definition: Resource) -> Vector2i:
	if not definition.zones.is_empty() and definition.zones[-1] != null:
		var zone = definition.zones[-1]
		return zone.origin + Vector2i(zone.size.x - 2, int(zone.size.y / 2))
	return Vector2i(5, 0)


static func _required_target_ids_and_cells(items: Array, id_property: String) -> Dictionary:
	var out := {}
	for item in items:
		if item == null or not bool(item.get("required")):
			continue
		out[String(item.get(id_property))] = item.marker_cell
	return out


static func _unreachable_ids(targets: Dictionary, reachable: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id in targets.keys():
		var cell: Vector2i = targets[id]
		if not reachable.has(cell):
			out.append(String(id))
	return out


static func _non_wall_tiles_with_collision(scene_root: Node) -> Array:
	var out: Array = []
	for layer_path in [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayMarkersLayer",
		"ArtRoot/GroundArtLayer",
		"ArtRoot/WallArtLayer",
		"ArtRoot/PropArtLayer",
		"ArtRoot/DecorBelowLayer",
		"ArtRoot/DecorAboveLayer",
		"ArtRoot/LightingLayer",
	]:
		var layer := scene_root.get_node_or_null(layer_path) as TileMapLayer
		if layer != null and layer.collision_enabled:
			out.append(layer_path)
	return out


static func _floor_bounds_from_set(floor_cells: Dictionary) -> Rect2i:
	if floor_cells.is_empty():
		return Rect2i()
	var keys := floor_cells.keys()
	var first: Vector2i = keys[0]
	var min_x := first.x
	var max_x := first.x
	var min_y := first.y
	var max_y := first.y
	for cell in keys:
		var c: Vector2i = cell
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_y = mini(min_y, c.y)
		max_y = maxi(max_y, c.y)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


static func _outer_collision_surrounds_floor(floor_cells: Dictionary, blocked_cells: Dictionary) -> bool:
	if floor_cells.is_empty():
		return false
	for cell in floor_cells.keys():
		var c: Vector2i = cell
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = c + offset
			if not floor_cells.has(neighbor) and not blocked_cells.has(neighbor):
				return false
	return true


static func _required_targets_outside_floor(definition: Resource, floor_cells: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for targets in [
		_required_target_ids_and_cells(definition.primary_objectives, "objective_id"),
		_required_target_ids_and_cells(definition.evidence_clues, "clue_id"),
		_required_target_ids_and_cells(definition.collectibles, "collectible_id"),
		{"exit": _exit_cell(definition)},
	]:
		for id in targets.keys():
			var cell: Vector2i = targets[id]
			if not floor_cells.has(cell):
				out.append(String(id))
	return out


static func _all_markers_outside_floor(definition: Resource, floor_cells: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for item in definition.primary_objectives:
		_append_marker_outside_floor(out, "objective:", item, "objective_id", floor_cells)
	for item in definition.optional_objectives:
		_append_marker_outside_floor(out, "optional_objective:", item, "objective_id", floor_cells)
	for item in definition.evidence_clues:
		_append_marker_outside_floor(out, "clue:", item, "clue_id", floor_cells)
	for item in definition.collectibles:
		_append_marker_outside_floor(out, "collectible:", item, "collectible_id", floor_cells)
	for item in definition.puzzle_gates:
		_append_marker_outside_floor(out, "gate:", item, "gate_id", floor_cells)
	for item in definition.enemies:
		_append_marker_outside_floor(out, "spawn:", item, "spawn_id", floor_cells)
	return out


static func _append_marker_outside_floor(out: Array[String], prefix: String, item: Resource, id_property: String, floor_cells: Dictionary) -> void:
	if item == null:
		return
	if not floor_cells.has(item.marker_cell):
		out.append(prefix + String(item.get(id_property)))


static func _internal_transition_blocker_count(definition: Resource, collision_layer: TileMapLayer) -> int:
	var blocked := _cell_set(collision_layer.get_used_cells())
	var count := 0
	for a in definition.zones:
		if a == null:
			continue
		for b in definition.zones:
			if b == null or a == b:
				continue
			if a.origin.x + a.size.x == b.origin.x:
				var y0: int = maxi(a.origin.y, b.origin.y)
				var y1: int = mini(a.origin.y + a.size.y - 1, b.origin.y + b.size.y - 1)
				for y in range(y0, y1 + 1):
					if blocked.has(Vector2i(a.origin.x + a.size.x - 1, y)) or blocked.has(Vector2i(b.origin.x, y)):
						count += 1
			if a.origin.y + a.size.y == b.origin.y:
				var x0: int = maxi(a.origin.x, b.origin.x)
				var x1: int = mini(a.origin.x + a.size.x - 1, b.origin.x + b.size.x - 1)
				for x in range(x0, x1 + 1):
					if blocked.has(Vector2i(x, a.origin.y + a.size.y - 1)) or blocked.has(Vector2i(x, b.origin.y)):
						count += 1
	return count


static func _outside_escape_risk_cells(definition: Resource, floor_cells: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var bounds := _floor_bounds_from_set(floor_cells)
	if bounds.size == Vector2i.ZERO:
		return out
	var tests: Array[Vector2i] = [
		Vector2i(bounds.position.x - 2, _spawn_cell(definition).y),
		Vector2i(bounds.end.x + 1, _exit_cell(definition).y),
		Vector2i(_spawn_cell(definition).x, bounds.position.y - 2),
		Vector2i(_exit_cell(definition).x, bounds.end.y + 1),
	]
	for cell in tests:
		if floor_cells.has(cell):
			out.append(cell)
	return out


static func _targets_inside_boundary_collision(definition: Resource, scene_root: Node, floor_layer: TileMapLayer) -> Array[String]:
	var out: Array[String] = []
	var boundary := scene_root.get_node_or_null("GameplayRoot/BoundaryColliders")
	if boundary == null:
		return out
	var targets := _required_target_ids_and_cells(definition.primary_objectives, "objective_id")
	for id in _required_target_ids_and_cells(definition.evidence_clues, "clue_id").keys():
		targets[id] = _required_target_ids_and_cells(definition.evidence_clues, "clue_id")[id]
	for id in _required_target_ids_and_cells(definition.collectibles, "collectible_id").keys():
		targets[id] = _required_target_ids_and_cells(definition.collectibles, "collectible_id")[id]
	targets["exit"] = _exit_cell(definition)
	var space := scene_root.get_tree().root.world_2d.direct_space_state
	for id in targets.keys():
		var world_pos := floor_layer.to_global(floor_layer.map_to_local(targets[id]))
		var params := PhysicsPointQueryParameters2D.new()
		params.position = world_pos
		params.collision_mask = 4
		params.collide_with_areas = false
		params.collide_with_bodies = true
		var hits := space.intersect_point(params, 8)
		for hit in hits:
			var collider := hit.get("collider") as Node
			if collider != null and boundary.is_ancestor_of(collider):
				out.append(String(id))
				break
	return out


static func _collectibles_inside_boundary_collision(definition: Resource, scene_root: Node, floor_layer: TileMapLayer) -> Array[String]:
	var targets := {}
	for collectible in definition.collectibles:
		if collectible == null:
			continue
		targets[String(collectible.collectible_id)] = collectible.marker_cell
	return _target_cells_inside_boundary_collision(targets, scene_root, floor_layer)


static func _target_cells_inside_boundary_collision(targets: Dictionary, scene_root: Node, floor_layer: TileMapLayer) -> Array[String]:
	var out: Array[String] = []
	var boundary := scene_root.get_node_or_null("GameplayRoot/BoundaryColliders")
	if boundary == null:
		return out
	var space := scene_root.get_tree().root.world_2d.direct_space_state
	for id in targets.keys():
		var world_pos := floor_layer.to_global(floor_layer.map_to_local(targets[id]))
		var params := PhysicsPointQueryParameters2D.new()
		params.position = world_pos
		params.collision_mask = 4
		params.collide_with_areas = false
		params.collide_with_bodies = true
		var hits := space.intersect_point(params, 8)
		for hit in hits:
			var collider := hit.get("collider") as Node
			if collider != null and boundary.is_ancestor_of(collider):
				out.append(String(id))
				break
	return out


static func print_debug_report(report: Dictionary) -> void:
	var debug: Dictionary = report.get("debug", {})
	print("[MissionBlockoutValidator] Debug report for " + String(report.get("mission_id", "")))
	print("  floor cell count: " + str(debug.get("floor_cell_count", 0)))
	print("  collision cell count: " + str(debug.get("collision_cell_count", 0)))
	print("  marker cell count: " + str(debug.get("marker_cell_count", 0)))
	print("  reachable required objective count: " + str(debug.get("reachable_required_objective_count", 0)))
	print("  unreachable required objective ids: " + str(debug.get("unreachable_required_objective_ids", [])))
	print("  reachable exit: " + str(debug.get("reachable_exit", false)))
	print("  reachable clue count: " + str(debug.get("reachable_clue_count", 0)))
	print("  unreachable clue ids: " + str(debug.get("unreachable_clue_ids", [])))
	print("  reachable required collectible count: " + str(debug.get("reachable_required_collectible_count", 0)))
	print("  unreachable required collectible ids: " + str(debug.get("unreachable_required_collectible_ids", [])))
	print("  non-wall tiles with collision: " + str(debug.get("non_wall_tiles_with_collision", [])))
	print("  boundary colliders exist: " + str(debug.get("boundary_colliders_exist", false)))
	print("  boundary collider count: " + str(debug.get("boundary_collider_count", 0)))
	print("  outer collision surrounds floor: " + str(debug.get("outer_collision_surrounds_floor", false)))
	print("  spawn cell: " + str(debug.get("spawn_cell", Vector2i.ZERO)))
	print("  spawn clearance missing floor: " + str(debug.get("spawn_clearance_missing_floor", [])))
	print("  spawn clearance blocked cells: " + str(debug.get("spawn_clearance_blocked_cells", [])))
	print("  start zone floor cell count: " + str(debug.get("start_zone_floor_cell_count", 0)))
	print("  start-market entrance width: " + str(debug.get("start_market_entrance_width", 0)))
	print("  blocking collision objects near spawn: " + str(debug.get("blocking_collision_objects_near_spawn", [])))
	print("  narrow required passages: " + str(debug.get("narrow_required_passages", [])))
	print("  narrow exit approach cells: " + str(debug.get("narrow_exit_approach_cells", [])))
	print("  narrow return corridor cells: " + str(debug.get("narrow_return_corridor_cells", [])))
	print("  min required route width found: " + str(debug.get("min_required_route_width_found", 0)))
	print("  player clearance radius px: " + str(debug.get("player_clearance_radius_px", 0.0)))
	print("  iso player collision override active: " + str(debug.get("iso_player_collision_override_active", false)))
	print("  required targets outside floor: " + str(debug.get("required_targets_outside_floor", [])))
	print("  all markers outside floor: " + str(debug.get("all_markers_outside_floor", [])))
	print("  internal transition blocker count: " + str(debug.get("internal_transition_blocker_count", 0)))
	print("  outside escape risk cells: " + str(debug.get("outside_escape_risk_cells", [])))
	print("  required targets inside boundary collision: " + str(debug.get("required_targets_inside_boundary_collision", [])))
	print("  collectibles inside boundary collision: " + str(debug.get("collectibles_inside_boundary_collision", [])))
	print("  exit area count: " + str(debug.get("exit_area_count", 0)))
	print("  exit collision shape count: " + str(debug.get("exit_collision_shape_count", 0)))
	print("  exit interactable count: " + str(debug.get("exit_interactable_count", 0)))
	print("  exit body_entered connected count: " + str(debug.get("exit_body_entered_connected_count", 0)))
	print("  exit overlaps expected cell: " + str(debug.get("exit_overlaps_expected_cell", false)))
	print("  exit has player collision mask: " + str(debug.get("exit_has_player_collision_mask", false)))
	print("  exit uses real completion path: " + str(debug.get("exit_uses_real_completion_path", false)))
	print("  required interactables checked: " + str(debug.get("required_interactables_checked", 0)))
	print("  required interactables missing support: " + str(debug.get("required_interactables_missing_support", [])))
	print("  required interactables missing shape: " + str(debug.get("required_interactables_missing_shape", [])))
	print("  interactable marker overlaps: " + str(debug.get("interactable_marker_overlaps", [])))
	print("  cover cell count: " + str(debug.get("cover_cell_count", 0)))
	print("  cover tile has collision: " + str(debug.get("cover_tile_has_collision", false)))
	print("  runtime marker->object counts: " + str(debug.get("runtime_marker_to_object_counts", {})))
	print("  runtime spawned guard count: " + str(debug.get("runtime_spawned_guard_count", 0)))
	print("  runtime spawned camera count: " + str(debug.get("runtime_spawned_camera_count", 0)))
	print("  runtime light zone count: " + str(debug.get("runtime_light_zone_count", 0)))
	print("  runtime detection zone count: " + str(debug.get("runtime_detection_zone_count", 0)))
	print("  runtime alarm zone count: " + str(debug.get("runtime_alarm_zone_count", 0)))
	print("  runtime encounter zone count: " + str(debug.get("runtime_encounter_zone_count", 0)))
	print("  runtime route access count: " + str(debug.get("runtime_route_access_count", 0)))
	print("  runtime transition count: " + str(debug.get("runtime_transition_count", 0)))
	print("  runtime debug ui count: " + str(debug.get("runtime_debug_ui_count", 0)))
	print("  authoring mode: " + str(debug.get("authoring_mode", "")))
	print("  layout source: " + str(debug.get("layout_source", "")))
	print("  marker source: " + str(debug.get("marker_source", "")))
	print("  scene markers found: " + str(debug.get("scene_markers_found", 0)))
	print("  generated markers found: " + str(debug.get("generated_markers_found", 0)))
	print("  enemy iso scale ok: " + str(debug.get("enemy_iso_scale_ok", false)))
	print("  unknown marker types: " + str(debug.get("unknown_marker_types", [])))
	print("  overlapping interactables: " + str(debug.get("overlapping_interactables", [])))
	print("  interaction priority conflicts: " + str(debug.get("interaction_priority_conflicts", [])))
	print("  typed missing clue meta: " + str(debug.get("typed_missing_clue_meta", [])))
	print("  typed missing collectible groups: " + str(debug.get("typed_missing_collectible_groups", [])))
	print("  typed missing route messages: " + str(debug.get("typed_missing_route_messages", [])))
	print("  Taco Bell missing layout zones: " + str(debug.get("taco_bell_missing_layout_zones", [])))
	print("  Taco Bell missing zone connections: " + str(debug.get("taco_bell_missing_zone_connections", [])))
	print("  Taco Bell exit west of bag room: " + str(debug.get("taco_bell_exit_west_of_bag_room", false)))
	print("  Taco Bell return corridor loops west: " + str(debug.get("taco_bell_return_corridor_loops_west", false)))


static func _add_error(report: Dictionary, message: String) -> void:
	report["ok"] = false
	report["errors"].append(message)


static func _add_warning(report: Dictionary, message: String) -> void:
	report["warnings"].append(message)
