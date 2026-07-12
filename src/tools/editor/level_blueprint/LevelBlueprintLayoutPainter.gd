@tool
class_name LevelBlueprintLayoutPainter
extends RefCounted
## Deterministic, editor-only layout analysis and guarded ignored-candidate save.

const BlueprintSpec := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")

const DEFAULT_SCENE_PATH := ""
const DEFAULT_BLUEPRINT_PATH := ""
const SOURCE_ID := 0
const TILE_BY_KIND := {"floor": Vector2i(0, 0), "wall": Vector2i(1, 0), "cover": Vector2i(2, 0), "collision_barrier": Vector2i(1, 0)}


static func run(options: Dictionary = {}) -> Dictionary:
	var scene_path := String(options.get("scene_path", DEFAULT_SCENE_PATH)).strip_edges()
	var blueprint_path := String(options.get("blueprint_path", DEFAULT_BLUEPRINT_PATH)).strip_edges()
	var dry_run := bool(options.get("dry_run", true))
	var result := _empty_result(scene_path, blueprint_path, dry_run)
	if scene_path == "":
		result.errors.append("scene_path is required.")
	if blueprint_path == "":
		result.errors.append("blueprint_path is required.")
	if not dry_run:
		_validate_apply_request(options, result)
	if not result.errors.is_empty():
		_finalize_hashes(result)
		return result

	var loaded_spec: Dictionary = BlueprintSpec.load_spec(blueprint_path)
	if not bool(loaded_spec.get("ok", false)):
		result.errors.append_array(loaded_spec.get("errors", []))
		_finalize_hashes(result)
		return result
	var spec: Dictionary = loaded_spec.get("spec", {})
	var collision_contract: Variant = spec.get("collision_contract", {})
	if not (collision_contract is Dictionary):
		result.errors.append("Blueprint collision_contract must be an object.")
		_finalize_hashes(result)
		return result

	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		result.errors.append("Scene could not be loaded cache-safely: %s" % scene_path)
		_finalize_hashes(result)
		return result
	var scene_root := packed.instantiate()
	if scene_root == null:
		result.errors.append("Scene could not be instantiated in memory: %s" % scene_path)
		_finalize_hashes(result)
		return result

	var layers := _resolve_layers(scene_root, result)
	if result.errors.is_empty():
		var used_before := _used_cell_counts(layers)
		var cells_by_kind := _analyze(spec, collision_contract as Dictionary, layers, result)
		if not dry_run:
			_apply_and_save(scene_root, layers, cells_by_kind, options, result)
		var used_after := _used_cell_counts(layers)
		result["in_memory_layer_cell_counts"] = {"before": used_before, "after": used_after}
		if dry_run and used_before != used_after:
			result.errors.append("Dry-run unexpectedly changed in-memory TileMapLayer cell counts.")
			result.mutation_flags.in_memory_tiles_changed = true
	scene_root.free()
	_finalize_hashes(result)
	result.ok = result.errors.is_empty()
	return result


static func _empty_result(scene_path: String, blueprint_path: String, dry_run: bool) -> Dictionary:
	return {
		"ok": false,
		"dry_run": dry_run,
		"errors": [],
		"warnings": [],
		"scene_path": scene_path,
		"blueprint_path": blueprint_path,
		"target_scene_path": "",
		"source_hashes": {
			"scene": {"before": _sha256(scene_path), "after": ""},
			"blueprint": {"before": _sha256(blueprint_path), "after": ""},
			"target": {"before": "", "after": ""},
		},
		"layer_paths": {},
		"per_kind_cell_counts": {},
		"per_region": [],
		"opening_analysis": [],
		"closed_island_analysis": [],
		"cover_analysis": {
			"safe_non_solid_labels": [],
			"solid_labels": [],
			"regions": [],
		},
		"blocking_overlap_analysis": {},
		"representative_data": [],
		"painted_cell_counts": {},
		"mutation_flags": {
			"scene_mutated": false,
			"blueprint_mutated": false,
			"in_memory_tiles_changed": false,
			"tiles_written": false,
			"nodes_added": false,
			"nodes_removed": false,
		},
		"save_flags": {
			"any_save_called": false,
			"scene_pack_called": false,
			"pack_validated": false,
			"pack_result": -1,
			"save_result": -1,
			"packed_scene_saved": false,
			"resource_saved": false,
		},
	}


static func _resolve_layers(scene_root: Node, result: Dictionary) -> Dictionary:
	var layers := {}
	for kind: String in BlueprintSpec.REGION_KINDS:
		var path := String(BlueprintSpec.PAINT_LAYER_BY_KIND.get(kind, ""))
		result.layer_paths[kind] = path
		var layer := scene_root.get_node_or_null(path) as TileMapLayer
		if layer == null:
			result.errors.append("Approved TileMapLayer is missing or has the wrong type: %s" % path)
		else:
			layers[kind] = layer
	return layers


static func _analyze(spec: Dictionary, contract: Dictionary, layers: Dictionary, result: Dictionary) -> Dictionary:
	var cells_by_kind := {}
	for kind: String in BlueprintSpec.REGION_KINDS:
		cells_by_kind[kind] = {}
	var solid_cover_cells := {}
	var wall_thickness := float((contract.get("wall_guidance", {}) as Dictionary).get("nominal_thickness_px", BlueprintSpec.grid_size(spec)))
	var region_index := 0
	for entry: Variant in BlueprintSpec.regions(spec):
		if not (entry is Dictionary):
			region_index += 1
			continue
		var region := entry as Dictionary
		var kind := String(region.get("kind", ""))
		var layer := layers.get(kind) as TileMapLayer
		var region_cells := {}
		if kind != "cover" or bool(region.get("blocks_movement", false)):
			match String(region.get("shape", "")):
				"rect":
					region_cells = _rect_cells(layer, _rect_from_array(region.get("rect", [])))
				"polyline":
					region_cells = _polyline_cells(layer, _points_from_array(region.get("points", [])), wall_thickness)
		for cell: Vector2i in region_cells.keys():
			(cells_by_kind[kind] as Dictionary)[cell] = true
		if kind == "cover" and bool(region.get("blocks_movement", false)):
			for cell: Vector2i in region_cells.keys():
				solid_cover_cells[cell] = true
		result.per_region.append({
			"index": region_index,
			"kind": kind,
			"label": String(region.get("label", "")),
			"blocks_movement": bool(region.get("blocks_movement", false)),
			"cell_count": region_cells.size(),
			"cells": _sorted_cell_arrays(region_cells),
		})
		region_index += 1

	for kind: String in BlueprintSpec.REGION_KINDS:
		result.per_kind_cell_counts[kind] = (cells_by_kind[kind] as Dictionary).size()
	result.cover_analysis = _analyze_cover(spec, contract, solid_cover_cells)
	result.blocking_overlap_analysis = _blocking_overlaps(cells_by_kind.wall, cells_by_kind.collision_barrier, solid_cover_cells)
	result.opening_analysis = _analyze_openings(contract, layers, cells_by_kind.wall, cells_by_kind.collision_barrier, solid_cover_cells)
	result.closed_island_analysis = _analyze_closed_islands(contract, layers.wall, layers.floor, cells_by_kind.wall, cells_by_kind.floor, wall_thickness)
	result.representative_data = _representative_data(layers, cells_by_kind)
	return cells_by_kind


static func _blocking_overlaps(wall: Dictionary, barrier: Dictionary, cover: Dictionary) -> Dictionary:
	var wall_barrier := _intersection(wall, barrier)
	var wall_cover := _intersection(wall, cover)
	var barrier_cover := _intersection(barrier, cover)
	var triple := _intersection(wall_barrier, cover)
	var blocking_union := wall.duplicate()
	for cell: Vector2i in cover:
		blocking_union[cell] = true
	for cell: Vector2i in barrier:
		blocking_union[cell] = true
	return {"wall_barrier_cells": _sorted_cell_arrays(wall_barrier), "wall_cover_cells": _sorted_cell_arrays(wall_cover), "barrier_cover_cells": _sorted_cell_arrays(barrier_cover), "triple_intersection_cells": _sorted_cell_arrays(triple), "unique_blocking_union_cells": _sorted_cell_arrays(blocking_union), "unique_blocking_union_count": blocking_union.size()}


static func _intersection(first: Dictionary, second: Dictionary) -> Dictionary:
	var intersection := {}
	for cell: Vector2i in first:
		if second.has(cell):
			intersection[cell] = true
	return intersection


static func _validate_apply_request(options: Dictionary, result: Dictionary) -> void:
	if not bool(options.get("allow_apply", false)):
		result.errors.append("Non-dry apply requires allow_apply=true.")
	var expected_hash := String(options.get("expected_source_sha256", "")).to_lower()
	if expected_hash == "" or expected_hash != String(result.source_hashes.scene.before):
		result.errors.append("expected_source_sha256 must exactly match the current source scene.")
	var target_path := String(options.get("target_scene_path", "")).strip_edges()
	result.target_scene_path = target_path
	if not target_path.begins_with("res://reports/godot_ignored_backups/") or not target_path.ends_with(".tscn"):
		result.errors.append("Candidate target must be an ignored recovery .tscn path.")
	result.source_hashes.target.before = _sha256(target_path)


static func _apply_and_save(scene_root: Node, layers: Dictionary, cells_by_kind: Dictionary, options: Dictionary, result: Dictionary) -> void:
	for kind: String in TILE_BY_KIND:
		var layer := layers.get(kind) as TileMapLayer
		var tile_set := layer.tile_set if layer != null else null
		var atlas := tile_set.get_source(SOURCE_ID) as TileSetAtlasSource if tile_set != null and tile_set.has_source(SOURCE_ID) else null
		if atlas == null or not atlas.has_tile(TILE_BY_KIND[kind]):
			result.errors.append("Approved tile unavailable for %s." % kind)
	if not bool(options.get("replace_existing_layout", false)):
		for kind: String in BlueprintSpec.REGION_KINDS:
			if not (layers[kind] as TileMapLayer).get_used_cells().is_empty():
				result.errors.append("Approved layout layers must be empty.")
				break
	if not result.errors.is_empty():
		return
	for kind: String in TILE_BY_KIND:
		var layer := layers[kind] as TileMapLayer
		var cells := cells_by_kind[kind] as Dictionary
		for cell: Vector2i in _sorted_cells(cells):
			layer.set_cell(cell, SOURCE_ID, TILE_BY_KIND[kind])
		result.painted_cell_counts[kind] = cells.size()
	result.painted_cell_counts.marker = 0
	result.mutation_flags.in_memory_tiles_changed = true
	result.mutation_flags.tiles_written = true
	var packed := PackedScene.new()
	result.save_flags.scene_pack_called = true
	var pack_result := packed.pack(scene_root)
	result.save_flags.pack_result = pack_result
	if pack_result != OK:
		result.errors.append("PackedScene.pack failed: %d" % pack_result)
		return
	result.save_flags.pack_validated = true
	result.save_flags.any_save_called = true
	var save_result := ResourceSaver.save(packed, String(result.target_scene_path))
	result.save_flags.save_result = save_result
	if save_result != OK:
		result.errors.append("Candidate save failed: %d" % save_result)
		return
	result.save_flags.packed_scene_saved = true
	result.save_flags.resource_saved = true


static func _rect_cells(layer: TileMapLayer, world_rect: Rect2) -> Dictionary:
	var cells := {}
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return cells
	var inset := Vector2(0.001, 0.001)
	var corners := [
		world_rect.position + inset,
		Vector2(world_rect.end.x - inset.x, world_rect.position.y + inset.y),
		world_rect.end - inset,
		Vector2(world_rect.position.x + inset.x, world_rect.end.y - inset.y),
	]
	var mapped: Array[Vector2i] = []
	for world_point: Vector2 in corners:
		mapped.append(layer.local_to_map(layer.to_local(world_point)))
	var min_cell := mapped[0]
	var max_cell := mapped[0]
	for cell: Vector2i in mapped:
		min_cell = Vector2i(min(min_cell.x, cell.x), min(min_cell.y, cell.y))
		max_cell = Vector2i(max(max_cell.x, cell.x), max(max_cell.y, cell.y))
	for y in range(min_cell.y - 1, max_cell.y + 2):
		for x in range(min_cell.x - 1, max_cell.x + 2):
			var cell := Vector2i(x, y)
			var world_center := layer.to_global(layer.map_to_local(cell))
			if world_rect.has_point(world_center):
				cells[cell] = true
	return cells


static func _polyline_cells(layer: TileMapLayer, points: Array[Vector2], thickness: float) -> Dictionary:
	var cells := {}
	if points.size() < 2:
		return cells
	var cell_span := _minimum_world_cell_span(layer)
	var stripe_count: int = max(1, int(ceil(maxf(thickness, 0.001) / cell_span)))
	for point_index in range(points.size() - 1):
		var start := points[point_index]
		var finish := points[point_index + 1]
		var direction := finish - start
		var normal := Vector2.ZERO if direction.is_zero_approx() else direction.normalized().orthogonal()
		for stripe_index in range(stripe_count):
			var offset := ((float(stripe_index) + 0.5) / float(stripe_count) - 0.5) * thickness
			var from_cell := layer.local_to_map(layer.to_local(start + normal * offset))
			var to_cell := layer.local_to_map(layer.to_local(finish + normal * offset))
			for cell: Vector2i in _raster_line(from_cell, to_cell):
				cells[cell] = true
	return cells


static func _raster_line(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x := start.x
	var y := start.y
	var dx: int = absi(finish.x - start.x)
	var sx: int = 1 if start.x < finish.x else -1
	var dy: int = -absi(finish.y - start.y)
	var sy: int = 1 if start.y < finish.y else -1
	var error: int = dx + dy
	while true:
		cells.append(Vector2i(x, y))
		if x == finish.x and y == finish.y:
			break
		var twice_error: int = 2 * error
		if twice_error >= dy:
			error += dy
			x += sx
		if twice_error <= dx:
			error += dx
			y += sy
	return cells


static func _minimum_world_cell_span(layer: TileMapLayer) -> float:
	var origin := layer.to_global(layer.map_to_local(Vector2i.ZERO))
	var x_neighbor := layer.to_global(layer.map_to_local(Vector2i.RIGHT))
	var y_neighbor := layer.to_global(layer.map_to_local(Vector2i.DOWN))
	var spans := [origin.distance_to(x_neighbor), origin.distance_to(y_neighbor)]
	var minimum: float = minf(float(spans[0]), float(spans[1]))
	return minimum if minimum > 0.001 else 1.0


static func _analyze_cover(spec: Dictionary, contract: Dictionary, cover_cells: Dictionary) -> Dictionary:
	var safe_labels := _sorted_strings(contract.get("safe_non_solid_cover_labels", []))
	var solid_labels := _sorted_strings(contract.get("solid_cover_labels", []))
	var rows: Array = []
	for entry: Variant in BlueprintSpec.regions(spec):
		if not (entry is Dictionary) or String((entry as Dictionary).get("kind", "")) != "cover":
			continue
		var region := entry as Dictionary
		var contract_label := _contract_label(String(region.get("label", "")), safe_labels + solid_labels)
		rows.append({
			"label": contract_label,
			"blocks_movement": bool(region.get("blocks_movement", false)),
			"classification": "solid" if contract_label in solid_labels else "safe_non_solid",
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.label) < String(b.label))
	return {
		"safe_non_solid_labels": safe_labels,
		"solid_labels": solid_labels,
		"safe_non_solid_count": safe_labels.size(),
		"solid_count": solid_labels.size(),
		"painted_solid_cell_count": cover_cells.size(),
		"regions": rows,
	}


static func _analyze_openings(contract: Dictionary, layers: Dictionary, wall_cells: Dictionary, barrier_cells: Dictionary, solid_cover_cells: Dictionary) -> Array:
	var rows: Array = []
	var openings: Variant = contract.get("openings", [])
	if not (openings is Array):
		return rows
	for entry: Variant in openings:
		if not (entry is Dictionary):
			continue
		var opening := entry as Dictionary
		var opening_rect := _rect_from_array(opening.get("rect", []))
		var floor_candidates := _rect_cells(layers.floor, opening_rect)
		var clear_cells := {}
		var blocked_by_wall := {}
		var blocked_by_barrier := {}
		var blocked_by_solid_cover := {}
		for floor_cell: Vector2i in floor_candidates.keys():
			var world_point := (layers.floor as TileMapLayer).to_global((layers.floor as TileMapLayer).map_to_local(floor_cell))
			var wall_cell := (layers.wall as TileMapLayer).local_to_map((layers.wall as TileMapLayer).to_local(world_point))
			var barrier_cell := (layers.collision_barrier as TileMapLayer).local_to_map((layers.collision_barrier as TileMapLayer).to_local(world_point))
			var cover_cell := (layers.cover as TileMapLayer).local_to_map((layers.cover as TileMapLayer).to_local(world_point))
			var blocked := false
			if wall_cells.has(wall_cell):
				blocked_by_wall[floor_cell] = true
				blocked = true
			if barrier_cells.has(barrier_cell):
				blocked_by_barrier[floor_cell] = true
				blocked = true
			if solid_cover_cells.has(cover_cell):
				blocked_by_solid_cover[floor_cell] = true
				blocked = true
			if not blocked:
				clear_cells[floor_cell] = true
		var state := String(opening.get("state", ""))
		rows.append({
			"opening_id": String(opening.get("opening_id", "")),
			"state": state,
			"classification": String(opening.get("classification", "")),
			"candidate_cells": _sorted_cell_arrays(floor_candidates),
			"candidate_cell_count": floor_candidates.size(),
			"clear_candidate_cells": _sorted_cell_arrays(clear_cells),
			"clear_candidate_cell_count": clear_cells.size(),
			"blocked_by_wall_cells": _sorted_cell_arrays(blocked_by_wall),
			"blocked_by_barrier_cells": _sorted_cell_arrays(blocked_by_barrier),
			"blocked_by_solid_cover_cells": _sorted_cell_arrays(blocked_by_solid_cover),
			"continuous_clear_candidate_lane": state == "fixed_open" and _has_continuous_clear_lane(layers.floor, clear_cells, opening_rect),
			"blocked_by_current_barrier": not blocked_by_barrier.is_empty(),
			"future_blocker_painted": false,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.opening_id) < String(b.opening_id))
	return rows


static func _has_continuous_clear_lane(layer: TileMapLayer, clear_cells: Dictionary, world_rect: Rect2) -> bool:
	if clear_cells.is_empty():
		return false
	var passage_axis_is_x: bool = world_rect.size.x < world_rect.size.y
	var origin: Vector2 = layer.to_global(layer.map_to_local(Vector2i.ZERO))
	var right: Vector2 = layer.to_global(layer.map_to_local(Vector2i.RIGHT))
	var down: Vector2 = layer.to_global(layer.map_to_local(Vector2i.DOWN))
	var tolerance: float = maxf(absf((right - origin).x if passage_axis_is_x else (right - origin).y), absf((down - origin).x if passage_axis_is_x else (down - origin).y))
	var required_min: float = world_rect.position.x if passage_axis_is_x else world_rect.position.y
	var required_max: float = world_rect.end.x if passage_axis_is_x else world_rect.end.y
	var unvisited: Dictionary = clear_cells.duplicate()
	while not unvisited.is_empty():
		var seed: Vector2i = unvisited.keys()[0]
		var pending: Array[Vector2i] = [seed]
		unvisited.erase(seed)
		var component_min: float = INF
		var component_max: float = -INF
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			var world_point: Vector2 = layer.to_global(layer.map_to_local(cell))
			var axis_value: float = world_point.x if passage_axis_is_x else world_point.y
			component_min = minf(component_min, axis_value)
			component_max = maxf(component_max, axis_value)
			for neighbor in [cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN]:
				if unvisited.has(neighbor):
					unvisited.erase(neighbor)
					pending.append(neighbor)
		if component_min - tolerance <= required_min and component_max + tolerance >= required_max:
			return true
	return false


static func _analyze_closed_islands(contract: Dictionary, wall_layer: TileMapLayer, floor_layer: TileMapLayer, wall_cells: Dictionary, floor_cells: Dictionary, wall_thickness: float) -> Array:
	var rows: Array = []
	var islands: Variant = contract.get("closed_teleport_islands", [])
	if not (islands is Array):
		return rows
	for entry: Variant in islands:
		if not (entry is Dictionary):
			continue
		var island := entry as Dictionary
		var rect := _rect_from_array(island.get("perimeter", []))
		var perimeter_points: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
		var expected_perimeter := _polyline_cells(wall_layer, perimeter_points, wall_thickness)
		var represented := {}
		for cell: Vector2i in expected_perimeter.keys():
			if wall_cells.has(cell):
				represented[cell] = true
		var contained_floor := {}
		for cell: Vector2i in floor_cells.keys():
			var world_point := floor_layer.to_global(floor_layer.map_to_local(cell))
			if rect.has_point(world_point):
				contained_floor[cell] = true
		rows.append({
			"island_id": String(island.get("island_id", "")),
			"perimeter_cell_count": expected_perimeter.size(),
			"represented_perimeter_cell_count": represented.size(),
			"perimeter_represented": represented.size() == expected_perimeter.size(),
			"contained_floor_cell_count": contained_floor.size(),
			"containment_represented": represented.size() == expected_perimeter.size() and not contained_floor.is_empty(),
			"perimeter_cells": _sorted_cell_arrays(expected_perimeter),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.island_id) < String(b.island_id))
	return rows


static func _representative_data(layers: Dictionary, cells_by_kind: Dictionary) -> Array:
	var rows: Array = []
	for kind: String in BlueprintSpec.REGION_KINDS:
		var sorted_cells := _sorted_cells(cells_by_kind[kind])
		if sorted_cells.is_empty():
			continue
		var cell: Vector2i = sorted_cells[0]
		var layer := layers[kind] as TileMapLayer
		var world_point := layer.to_global(layer.map_to_local(cell))
		var round_trip_cell := layer.local_to_map(layer.to_local(world_point))
		rows.append({
			"kind": kind,
			"layer_path": String(BlueprintSpec.PAINT_LAYER_BY_KIND[kind]),
			"cell": [cell.x, cell.y],
			"world_point": [world_point.x, world_point.y],
			"round_trip_cell": [round_trip_cell.x, round_trip_cell.y],
		})
	return rows


static func _used_cell_counts(layers: Dictionary) -> Dictionary:
	var counts := {}
	for kind: String in BlueprintSpec.REGION_KINDS:
		counts[kind] = (layers[kind] as TileMapLayer).get_used_cells().size()
	return counts


static func _rect_from_array(value: Variant) -> Rect2:
	if value is Array and (value as Array).size() == 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Rect2()


static func _points_from_array(value: Variant) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if not (value is Array):
		return points
	for entry: Variant in value:
		if entry is Array and (entry as Array).size() >= 2:
			points.append(Vector2(float(entry[0]), float(entry[1])))
	return points


static func _sorted_cells(cells: Dictionary) -> Array[Vector2i]:
	var sorted: Array[Vector2i] = []
	for cell: Vector2i in cells.keys():
		sorted.append(cell)
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return sorted


static func _sorted_cell_arrays(cells: Dictionary) -> Array:
	var rows: Array = []
	for cell: Vector2i in _sorted_cells(cells):
		rows.append([cell.x, cell.y])
	return rows


static func _sorted_strings(value: Variant) -> Array[String]:
	var strings: Array[String] = []
	if value is Array:
		for entry: Variant in value:
			strings.append(String(entry))
	strings.sort()
	return strings


static func _contract_label(region_label: String, contract_labels: Array[String]) -> String:
	for label: String in contract_labels:
		if region_label == label or region_label.begins_with(label + " -"):
			return label
	return region_label


static func _sha256(path: String) -> String:
	return FileAccess.get_sha256(path) if path != "" and FileAccess.file_exists(path) else ""


static func _finalize_hashes(result: Dictionary) -> void:
	result.source_hashes.scene.after = _sha256(String(result.get("scene_path", "")))
	result.source_hashes.blueprint.after = _sha256(String(result.get("blueprint_path", "")))
	result.source_hashes.target.after = _sha256(String(result.get("target_scene_path", "")))
	result.mutation_flags.scene_mutated = result.source_hashes.scene.before != result.source_hashes.scene.after
	result.mutation_flags.blueprint_mutated = result.source_hashes.blueprint.before != result.source_hashes.blueprint.after
