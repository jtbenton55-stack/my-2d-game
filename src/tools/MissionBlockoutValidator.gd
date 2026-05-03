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
	_validate_reachability(definition, scene_root, report)
	_validate_boundary_integrity(definition, scene_root, report)
	_validate_exit_setup(definition, scene_root, report)


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
	debug["internal_transition_blocker_count"] = _internal_transition_blocker_count(definition, collision_layer)
	debug["outside_escape_risk_cells"] = _outside_escape_risk_cells(definition, floor_cells)
	debug["required_targets_inside_boundary_collision"] = _targets_inside_boundary_collision(definition, scene_root, floor_layer)
	debug["collectibles_inside_boundary_collision"] = _collectibles_inside_boundary_collision(definition, scene_root, floor_layer)
	report["debug"] = debug
	if not boundary_ok:
		_add_error(report, "GameplayRoot/BoundaryColliders must exist with generated edge colliders.")
	if not bool(debug["outer_collision_surrounds_floor"]):
		_add_error(report, "GameplayCollisionLayer does not surround the playable floor footprint.")
	var outside_targets: Array = debug["required_targets_outside_floor"]
	if not outside_targets.is_empty():
		_add_error(report, "Required targets outside playable floor: " + ", ".join(outside_targets))
	if int(debug["internal_transition_blocker_count"]) > 0:
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
	var bounds := _floor_bounds_from_set(floor_cells)
	if bounds.size == Vector2i.ZERO:
		return false
	var min_x := bounds.position.x
	var min_y := bounds.position.y
	var max_x := bounds.end.x - 1
	var max_y := bounds.end.y - 1
	for x in range(min_x, max_x + 1):
		if not blocked_cells.has(Vector2i(x, min_y - 1)):
			return false
		if not blocked_cells.has(Vector2i(x, max_y + 1)):
			return false
	for y in range(min_y, max_y + 1):
		if not blocked_cells.has(Vector2i(min_x - 1, y)):
			return false
		if not blocked_cells.has(Vector2i(max_x + 1, y)):
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
	print("  required targets outside floor: " + str(debug.get("required_targets_outside_floor", [])))
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


static func _add_error(report: Dictionary, message: String) -> void:
	report["ok"] = false
	report["errors"].append(message)


static func _add_warning(report: Dictionary, message: String) -> void:
	report["warnings"].append(message)
