@tool
class_name TacoBellExpandedLayoutBuilder
extends RefCounted

## Deterministic Taco Bell expanded map compiler (Phase 0G v6).
##
## Loads the v6 manifest, instantiates the source scene in memory (source scene
## is byte-protected), clears the approved layout layers in the duplicate,
## paints floors/walls/cover/blockers, moves runtime markers, creates plain
## editor-only Node2D placeholders, and (in apply mode) saves the duplicate.
##
## In dry_run mode no scene file is touched.
##
## Use:
##   var result := TacoBellExpandedLayoutBuilder.run({"dry_run": true})
##   var root := result.get("scene_root")  # null if save_failed
##
## Apply mode (Phases F-G; do not invoke without explicit user approval):
##   TacoBellExpandedLayoutBuilder.run({"dry_run": false})

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")

const APPROVED_LAYER_PATHS := [
	"GameplayRoot/LayoutRoot/FloorLayer",
	"GameplayRoot/LayoutRoot/WallLayer",
	"GameplayRoot/LayoutRoot/CoverLayer",
	"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	"GameplayRoot/LayoutRoot/MarkerTileLayer",
]

# ----------------------------- Public entrypoint ------------------------------

static func run(opts: Dictionary = {}) -> Dictionary:
	var dry_run := bool(opts.get("dry_run", true))
	var write_dry_run_report := bool(opts.get("write_dry_run_report", true))

	var report := {
		"dry_run": dry_run,
		"phase": "starting",
		"errors": [],
		"warnings": [],
		"info": [],
		"hard_assertions": {},
		"counts": {},
		"runtime_marker_movement": [],
		"editor_only_placeholders_created": [],
		"missing_required_runtime_markers": [],
		"marker_tile_placements": [],
		"marker_tile_suppressed": [],
		"equivalence_collisions": [],
		"cover_adjustments": [],
		"vent_interfaces": [],
		"source_protection": {},
		"cache_safe_load_mode_used": true,
		"optional_visual_reference": {},
	}

	# ---- Phase 1: preflight + manifest load
	report.phase = "preflight"
	var manifest := Shared.load_manifest()
	if manifest.has("_error"):
		report.errors.append("manifest_load_failed: " + String(manifest.get("_error", "")))
		return report
	report.manifest_path = Shared.MANIFEST_PATH

	var source_path: String = manifest.get("source_scene", Shared.SOURCE_SCENE_PATH)
	var target_path: String = manifest.get("target_scene", Shared.TARGET_SCENE_PATH)
	report.source_scene_path = source_path
	report.target_scene_path = target_path

	if not FileAccess.file_exists(source_path):
		report.errors.append("source_scene_missing: " + source_path)
		return report
	var hash_before := Shared.file_md5(source_path)
	var mtime_before := Shared.file_mtime(source_path)
	report.source_protection["hash_before"] = hash_before
	report.source_protection["mtime_before"] = mtime_before

	# Optional reference image
	var ref_path := Shared.OPTIONAL_REFERENCE_IMAGE_PATH
	var ref_found := FileAccess.file_exists(ref_path) or FileAccess.file_exists(_uppercase_extension(ref_path))
	report.optional_visual_reference = {
		"path": ref_path,
		"found": ref_found,
		"used_for_coordinates": false,
	}

	# ---- Phase 2: load + instantiate source (CACHE_MODE_IGNORE)
	report.phase = "instantiate"
	var packed: PackedScene = Shared.load_cache_safe(source_path, "PackedScene") as PackedScene
	if packed == null:
		report.errors.append("source_scene_load_failed: " + source_path)
		return report
	var scene_root: Node = packed.instantiate()
	if scene_root == null:
		report.errors.append("source_scene_instantiate_failed")
		return report

	# ---- Phase 3: find required nodes
	report.phase = "find_nodes"
	var layers := {}
	for path in APPROVED_LAYER_PATHS:
		var node := scene_root.get_node_or_null(path)
		if node == null:
			report.errors.append("required_layer_missing: " + path)
			scene_root.queue_free()
			return report
		layers[path] = node
	var floor_layer: TileMapLayer = layers["GameplayRoot/LayoutRoot/FloorLayer"]
	var wall_layer: TileMapLayer = layers["GameplayRoot/LayoutRoot/WallLayer"]
	var cover_layer: TileMapLayer = layers["GameplayRoot/LayoutRoot/CoverLayer"]
	var collision_layer: TileMapLayer = layers["GameplayRoot/LayoutRoot/CollisionBarrierLayer"]
	var marker_tile_layer: TileMapLayer = layers["GameplayRoot/LayoutRoot/MarkerTileLayer"]
	var marker_root: Node = scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	if marker_root == null:
		report.errors.append("required_node_missing: GameplayRoot/MarkerRoot")
		scene_root.queue_free()
		return report

	# ---- Phase 4: anchor lookup
	report.phase = "anchor"
	var anchor_marker_id := String(manifest.get("anchor_marker_id", "player_spawn_main"))
	var anchor_node: Node = Shared.find_anchor_marker(scene_root, anchor_marker_id)
	if anchor_node == null:
		report.errors.append("anchor_marker_not_found: " + anchor_marker_id)
		scene_root.queue_free()
		return report
	if not (anchor_node is Node2D):
		report.errors.append("anchor_marker_not_node2d: " + anchor_marker_id)
		scene_root.queue_free()
		return report
	var anchor_cell: Vector2i = Shared.compute_anchor_cell(anchor_node as Node2D, floor_layer)
	report.anchor = {
		"marker_id": anchor_marker_id,
		"node_path": String(scene_root.get_path_to(anchor_node)),
		"cell": [anchor_cell.x, anchor_cell.y],
		"global_position": [(anchor_node as Node2D).global_position.x, (anchor_node as Node2D).global_position.y],
	}

	# ---- Phase 5: build equivalence groups
	report.phase = "equivalence_groups"
	var marker_index := Shared.index_marker_root(marker_root)
	var rows: Array = manifest.get("runtime_marker_targets", [])
	var groups_result: Dictionary = Shared.build_equivalence_groups(rows, anchor_cell, marker_index)
	var groups: Array = groups_result.get("groups", [])
	var collisions: Array = groups_result.get("collisions", [])
	var enriched: Array = groups_result.get("enriched", [])
	report.equivalence_collisions = collisions

	# ---- Phase 6: clear approved layers
	report.phase = "clear_layers"
	floor_layer.clear()
	wall_layer.clear()
	cover_layer.clear()
	collision_layer.clear()
	marker_tile_layer.clear()

	# ---- Phase 7: paint floor
	report.phase = "paint_floor"
	var floor_lookup: Dictionary = Shared.tile_lookup_floor(manifest)
	var floor_cells: Dictionary = Shared.collect_floor_cells(manifest, anchor_cell)
	for cell in floor_cells.keys():
		floor_layer.set_cell(cell, floor_lookup.source_id, floor_lookup.atlas_coords)
	report.counts["floor_cell_count"] = floor_cells.size()

	# ---- Phase 8: collect open gaps + canonical marker target cells (used by walls)
	var open_gap_cells: Dictionary = Shared.collect_open_gap_cells(manifest, anchor_cell)
	var canonical_marker_cells := {}
	for grp in groups:
		var c: Vector2i = grp.abs_cell
		canonical_marker_cells[c] = true

	# ---- Phase 9: paint walls
	report.phase = "paint_walls"
	var wall_lookup: Dictionary = Shared.tile_lookup_wall(manifest)
	var explicit_blocks: Array = Shared.collect_explicit_block_cells(manifest, anchor_cell)
	var explicit_block_cells := {}
	for blk in explicit_blocks:
		explicit_block_cells[blk.abs_cell] = true

	var wall_count := 0
	for floor_cell in floor_cells.keys():
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var n_cell := Vector2i(floor_cell.x + dx, floor_cell.y + dy)
				if floor_cells.has(n_cell):
					continue
				if open_gap_cells.has(n_cell):
					continue
				if canonical_marker_cells.has(n_cell):
					continue
				if explicit_block_cells.has(n_cell):
					continue
				if wall_layer.get_cell_source_id(n_cell) != -1:
					continue
				wall_layer.set_cell(n_cell, wall_lookup.source_id, wall_lookup.atlas_coords)
				wall_count += 1
	report.counts["wall_cell_count"] = wall_count

	# ---- Phase 10: paint deliberate blockers on CollisionBarrierLayer
	report.phase = "paint_blockers"
	var collision_lookup: Dictionary = Shared.tile_lookup_collision(manifest)
	var blocker_count := 0
	for blk in explicit_blocks:
		collision_layer.set_cell(blk.abs_cell, collision_lookup.source_id, collision_lookup.atlas_coords)
		blocker_count += 1

	var vent_blockers: Array = Shared.collect_vent_blocker_cells(manifest, anchor_cell)
	for vb in vent_blockers:
		collision_layer.set_cell(vb.abs_cell, collision_lookup.source_id, collision_lookup.atlas_coords)
		blocker_count += 1
	report.counts["collision_cell_count"] = blocker_count

	# Record vent interfaces
	for vi in manifest.get("vent_only_interfaces", []):
		var stand_dict: Dictionary = vi.get("stand_cell_main_side", {})
		var stand_cell := Vector2i(int(stand_dict.get("x", 0)) + anchor_cell.x, int(stand_dict.get("y", 0)) + anchor_cell.y)
		var stand_on_floor := floor_cells.has(stand_cell)
		report.vent_interfaces.append({
			"id": String(vi.get("id", "")),
			"vent_in_marker_id": String(vi.get("vent_in_marker_id", "")),
			"stand_cell_main_side": [stand_cell.x, stand_cell.y],
			"stand_cell_on_floor": stand_on_floor,
			"player_block": bool(vi.get("player_block", true)),
		})

	# ---- Phase 11: paint cover
	report.phase = "paint_cover"
	var cover_lookup: Dictionary = Shared.tile_lookup_cover(manifest)
	var cover_count := 0
	for c in manifest.get("cover_cells", []):
		var cell := Vector2i(int(c.get("x", 0)) + anchor_cell.x, int(c.get("y", 0)) + anchor_cell.y)
		var adjusted := cell
		if not floor_cells.has(cell):
			adjusted = _nearest_floor_cell(cell, floor_cells)
			if adjusted != cell:
				report.cover_adjustments.append({
					"id": String(c.get("id", "")),
					"original": [cell.x, cell.y],
					"adjusted_to": [adjusted.x, adjusted.y]
				})
		if not floor_cells.has(adjusted):
			report.warnings.append("cover_cell_off_floor_no_adjustment: " + String(c.get("id", "")))
			continue
		# Don't overwrite required marker cells.
		if canonical_marker_cells.has(adjusted):
			report.warnings.append("cover_cell_on_marker_cell_skipped: " + String(c.get("id", "")))
			continue
		cover_layer.set_cell(adjusted, cover_lookup.source_id, cover_lookup.atlas_coords)
		cover_count += 1
	report.counts["cover_cell_count"] = cover_count

	# ---- Phase 12: clear EditorOnlyPlaceholders + recreate empty
	report.phase = "editor_only_placeholders_setup"
	var placeholder_parent: Node2D = _ensure_editor_only_placeholders_parent(marker_root, scene_root)

	# ---- Phase 13: process each canonical group
	report.phase = "process_groups"
	var rt_movements: Array = report.runtime_marker_movement
	var placeholder_creations: Array = report.editor_only_placeholders_created
	var missing_required: Array = report.missing_required_runtime_markers
	var tile_placements: Array = report.marker_tile_placements
	var tile_suppressed: Array = report.marker_tile_suppressed

	# Build cell-to-row map for marker tile painting (one tile per cell rule).
	var marker_atlas: Dictionary = manifest.get("tile_lookup", {}).get("marker_atlas", {})
	var marker_atlas_source_id: int = int(marker_atlas.get("source_id", 0))
	var marker_tile_painted := {}

	# Sort groups so canonical processing is deterministic.
	var group_order := groups.duplicate()
	group_order.sort_custom(func(a, b):
		var ai: int = int(a.canonical_index)
		var bi: int = int(b.canonical_index)
		var aid := String((enriched[ai].row as Dictionary).get("manifest_id", ""))
		var bid := String((enriched[bi].row as Dictionary).get("manifest_id", ""))
		return aid < bid
	)

	for grp in group_order:
		var canon_idx: int = int(grp.canonical_index)
		var canon_row: Dictionary = enriched[canon_idx].row
		var manifest_id := String(canon_row.get("manifest_id", ""))
		var category := String(canon_row.get("category", ""))
		var abbr := String(canon_row.get("marker_tile_abbr", ""))
		var ac: Vector2i = grp.abs_cell
		var matched_node: Node = grp.matched_node
		var placeholder_allowed: bool = bool(canon_row.get("placeholder_allowed", true))
		var desired_tier := String(canon_row.get("desired_runtime_tier", ""))
		var aliases: Array = canon_row.get("alias_of_legacy_marker_ids", [])
		var merged_aliases: Array = grp.merged_aliases

		var actual_tier := ""
		var moved_marker_id := ""

		if matched_node != null:
			# Real existing
			actual_tier = Shared.REAL_EXISTING
			var floor_local: Vector2 = floor_layer.map_to_local(ac)
			var world_pos: Vector2 = floor_layer.to_global(floor_local)
			(matched_node as Node2D).global_position = world_pos
			if matched_node.has_method("get") and matched_node.get("marker_id") != null:
				moved_marker_id = String(matched_node.get("marker_id"))
			rt_movements.append({
				"manifest_id": manifest_id,
				"category": category,
				"marker_tile_abbr": abbr,
				"runtime_marker_found": true,
				"matched_marker_id": moved_marker_id,
				"matched_node_path": String(scene_root.get_path_to(matched_node)),
				"new_cell": [ac.x, ac.y],
				"placeholder_created": false,
				"merged_aliases": merged_aliases,
				"alias_of_legacy_marker_ids": aliases,
				"desired_tier": desired_tier,
				"actual_tier": actual_tier,
			})
		elif not placeholder_allowed:
			actual_tier = "missing"
			missing_required.append({
				"manifest_id": manifest_id,
				"category": category,
				"target_cell": [ac.x, ac.y],
				"alias_of_legacy_marker_ids": aliases,
				"reason": "placeholder_allowed_false_and_no_existing_runtime_marker_matched",
			})
			rt_movements.append({
				"manifest_id": manifest_id,
				"category": category,
				"marker_tile_abbr": abbr,
				"runtime_marker_found": false,
				"matched_marker_id": "",
				"new_cell": [ac.x, ac.y],
				"placeholder_created": false,
				"merged_aliases": merged_aliases,
				"alias_of_legacy_marker_ids": aliases,
				"desired_tier": desired_tier,
				"actual_tier": actual_tier,
			})
		else:
			actual_tier = Shared.EDITOR_ONLY
			# Create plain Node2D placeholder, no script, owner=scene_root.
			var ph: Node2D = Node2D.new()
			ph.name = manifest_id
			placeholder_parent.add_child(ph)
			ph.owner = scene_root
			var floor_local2: Vector2 = floor_layer.map_to_local(ac)
			ph.global_position = floor_layer.to_global(floor_local2)
			ph.set_meta("editor_only", true)
			ph.set_meta("manifest_id", manifest_id)
			ph.set_meta("category", category)
			ph.set_meta("marker_tile_abbr", abbr)
			ph.set_meta("desired_runtime_tier", desired_tier)
			ph.set_meta("alias_of_legacy_marker_ids", aliases)
			ph.set_meta("merged_aliases", merged_aliases)
			ph.set_meta("linked_target_ids", canon_row.get("linked_target_ids", []))

			placeholder_creations.append({
				"manifest_id": manifest_id,
				"category": category,
				"marker_tile_abbr": abbr,
				"abs_cell": [ac.x, ac.y],
				"merged_aliases": merged_aliases,
				"desired_tier": desired_tier,
				"actual_tier": actual_tier,
				"node_path": String(scene_root.get_path_to(ph)),
				"owner_set": ph.owner == scene_root,
				"has_iso_mission_marker_script": ph.get_script() != null,
				"has_marker_type_field": ph.get("marker_type") != null,
			})

		# Marker tile placement (skip SPAWN; skip empty abbr; only one tile per cell).
		var rules: Dictionary = manifest.get("marker_tile_rules", {})
		var place_categories: Array = rules.get("place_for_categories", [])
		var skip_categories: Array = rules.get("skip_for_categories", [])
		if abbr == "" or skip_categories.has(category):
			tile_suppressed.append({
				"manifest_id": manifest_id,
				"reason": "spawn_or_empty_abbr",
				"category": category,
				"marker_tile_abbr": abbr,
				"abs_cell": [ac.x, ac.y],
			})
		elif not place_categories.has(category):
			tile_suppressed.append({
				"manifest_id": manifest_id,
				"reason": "category_not_in_place_for_categories",
				"category": category,
				"marker_tile_abbr": abbr,
				"abs_cell": [ac.x, ac.y],
			})
		elif marker_tile_painted.has(ac):
			tile_suppressed.append({
				"manifest_id": manifest_id,
				"reason": "cell_already_has_marker_tile",
				"category": category,
				"marker_tile_abbr": abbr,
				"abs_cell": [ac.x, ac.y],
				"existing_at_cell": marker_tile_painted[ac],
			})
		else:
			var atlas_lookup: Dictionary = Shared.abbr_to_atlas(manifest, abbr)
			if not atlas_lookup.ok:
				report.errors.append("unknown_marker_abbreviation_for_row: " + manifest_id + " abbr=" + abbr)
			else:
				marker_tile_layer.set_cell(ac, marker_atlas_source_id, atlas_lookup.atlas_coords)
				marker_tile_painted[ac] = manifest_id
				tile_placements.append({
					"manifest_id": manifest_id,
					"category": category,
					"marker_tile_abbr": abbr,
					"abs_cell": [ac.x, ac.y],
					"atlas_coords": [atlas_lookup.atlas_coords.x, atlas_lookup.atlas_coords.y],
					"associated_runtime_marker": (matched_node != null),
					"placeholder": (matched_node == null and placeholder_allowed),
				})

	report.counts["marker_tile_count"] = marker_tile_layer.get_used_cells().size()
	report.counts["editor_only_placeholders_created"] = placeholder_creations.size()
	report.counts["runtime_markers_moved"] = rt_movements.filter(func(m): return m.runtime_marker_found).size()
	report.counts["missing_required_runtime_markers"] = missing_required.size()
	report.counts["equivalence_collisions"] = collisions.size()

	# ---- Phase 13b: Phase 0H cleanup of old map artifacts (idempotent)
	report.phase = "phase_0h_cleanup"
	report.phase_0h_cleanup = _phase_0h_cleanup(scene_root, manifest, floor_layer)

	# ---- Phase 13c: Phase 0I runtime truth fixes (idempotent)
	# Wall collision, MarkerTileLayer/Authoring hide-at-runtime, generated runtime
	# collision blockers (code gate), promoted core collectibles, and runtime
	# safeguard for vent/Louis route player teleport.
	report.phase = "phase_0i_cleanup"
	report.phase_0i_cleanup = _phase_0i_cleanup(scene_root, manifest, floor_layer, wall_layer, collision_layer, marker_tile_layer, anchor_cell)

	# Used rect width/height
	var used_rect: Rect2i = floor_layer.get_used_rect()
	report.counts["used_rect_x"] = used_rect.position.x
	report.counts["used_rect_y"] = used_rect.position.y
	report.counts["used_rect_width"] = used_rect.size.x
	report.counts["used_rect_height"] = used_rect.size.y

	# ---- Phase 14: save (apply only) or skip
	report.phase = "save"
	var saved := false
	if not dry_run:
		var packed_out := PackedScene.new()
		var pack_err := packed_out.pack(scene_root)
		if pack_err != OK:
			report.errors.append("packed_scene_pack_failed: " + str(pack_err))
		else:
			var save_err := ResourceSaver.save(packed_out, target_path)
			if save_err != OK:
				report.errors.append("resource_saver_save_failed: " + str(save_err))
			else:
				saved = true
	report.saved = saved

	# ---- Phase 15: source protection check
	report.phase = "source_protection_check"
	var hash_after := Shared.file_md5(source_path)
	var mtime_after := Shared.file_mtime(source_path)
	report.source_protection["hash_after"] = hash_after
	report.source_protection["mtime_after"] = mtime_after
	report.source_protection["unchanged"] = (hash_before == hash_after)

	# ---- Phase 16: idempotency self-check (in-memory)
	report.phase = "idempotency"
	var second_packed: PackedScene = Shared.load_cache_safe(source_path, "PackedScene") as PackedScene
	if second_packed != null:
		var second_root: Node = second_packed.instantiate()
		var second_floor: TileMapLayer = second_root.get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer")
		if second_floor != null:
			var second_anchor: Node = Shared.find_anchor_marker(second_root, anchor_marker_id)
			if second_anchor is Node2D:
				var second_anchor_cell: Vector2i = Shared.compute_anchor_cell(second_anchor as Node2D, second_floor)
				var second_floor_cells: Dictionary = Shared.collect_floor_cells(manifest, second_anchor_cell)
				report.idempotency = {
					"first_floor_count": floor_cells.size(),
					"second_floor_count": second_floor_cells.size(),
					"equal": floor_cells.size() == second_floor_cells.size(),
				}
		second_root.queue_free()

	# ---- Phase 17: hard assertions ledger (computed details for the validator)
	report.phase = "assertions_ledger"
	report.hard_assertions = {
		"source_scene_unchanged": report.source_protection.get("unchanged", false),
		"floor_cell_count_meets_min": floor_cells.size() >= int(manifest.get("validation_rules", {}).get("floor_cell_count_min", 10000)),
		"used_rect_width_meets_min": used_rect.size.x >= int(manifest.get("validation_rules", {}).get("used_rect_width_min", 250)),
		"used_rect_height_meets_min": used_rect.size.y >= int(manifest.get("validation_rules", {}).get("used_rect_height_min", 100)),
		"floor_layer_not_empty": floor_cells.size() > 0,
		"wall_layer_not_empty": wall_count > 0,
		"marker_tile_layer_not_empty": marker_tile_layer.get_used_cells().size() > 0,
		"manifest_loaded": true,
		"anchor_found": true,
		"equivalence_collision_free": collisions.size() == 0,
		"missing_required_count": missing_required.size(),
		"editor_only_placeholders_have_no_iso_mission_marker": _all_placeholders_clean(placeholder_parent),
		"cache_safe_load_mode_used": true,
		"optional_visual_reference_used_for_coordinates": false,
		"door_switch_no_collision": _door_switch_no_collision(manifest),
	}

	report.phase = "complete"
	report.scene_root = scene_root  # caller decides whether to free
	return report

# ----------------------------- Helpers ---------------------------------------

static func _ensure_editor_only_placeholders_parent(marker_root: Node, scene_root: Node) -> Node2D:
	var existing := marker_root.get_node_or_null(Shared.EDITOR_ONLY_PARENT_NODE_NAME)
	if existing != null:
		# Wipe children.
		for child in existing.get_children():
			existing.remove_child(child)
			child.queue_free()
		return existing as Node2D
	var n := Node2D.new()
	n.name = Shared.EDITOR_ONLY_PARENT_NODE_NAME
	marker_root.add_child(n)
	n.owner = scene_root
	n.set_meta("editor_only", true)
	n.set_meta("description", "Phase 0G v6 editor-only placeholders. Plain Node2Ds, no IsoMissionMarker.gd.")
	return n

static func _nearest_floor_cell(cell: Vector2i, floor_cells: Dictionary) -> Vector2i:
	if floor_cells.has(cell):
		return cell
	var best := cell
	var best_dist := 1 << 30
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var c := Vector2i(cell.x + dx, cell.y + dy)
				if floor_cells.has(c):
					var d := absi(dx) + absi(dy)
					if d < best_dist:
						best_dist = d
						best = c
		if best_dist <= r:
			break
	return best

static func _all_placeholders_clean(placeholder_parent: Node) -> bool:
	if placeholder_parent == null:
		return true
	for child in placeholder_parent.get_children():
		if child.get_script() != null:
			return false
		if child.has_method("get") and child.get("marker_type") != null:
			return false
	return true

static func _door_switch_no_collision(manifest: Dictionary) -> bool:
	# We only need to verify that the DOOR/SWITCH atlas tiles in the marker
	# authoring tileset have no physics polygon. The TileSet is loaded via a
	# cache-safe ResourceLoader call. If the file is missing we conservatively
	# return false.
	var marker_atlas: Dictionary = manifest.get("tile_lookup", {}).get("marker_atlas", {})
	var ts_path: String = String(marker_atlas.get("tileset", ""))
	if ts_path == "":
		return false
	var ts: TileSet = Shared.load_cache_safe(ts_path, "TileSet") as TileSet
	if ts == null:
		return false
	var src_id: int = int(marker_atlas.get("source_id", 0))
	var src := ts.get_source(src_id)
	if not (src is TileSetAtlasSource):
		return false
	var atlas_src := src as TileSetAtlasSource
	var abbreviations: Dictionary = marker_atlas.get("abbreviations", {})
	for abbr in ["DOOR", "SWITCH"]:
		if not abbreviations.has(abbr):
			return false
		var coords_arr: Array = abbreviations[abbr]
		var coords := Vector2i(int(coords_arr[0]), int(coords_arr[1]))
		if not atlas_src.has_tile(coords):
			return false
		var td := atlas_src.get_tile_data(coords, 0)
		if td == null:
			return false
		# Inspect physics layers.
		for pl in range(ts.get_physics_layers_count()):
			if td.get_collision_polygons_count(pl) > 0:
				return false
	return true

static func _uppercase_extension(path: String) -> String:
	var dot := path.rfind(".")
	if dot < 0:
		return path
	return path.substr(0, dot) + path.substr(dot).to_upper()

# ===================== Phase 0H cleanup helpers =====================
#
# Phase 0H extends the Phase 0G v6 builder with an idempotent cleanup pass:
#   - clears + hides the old prototype TileMapLayers under GameplayRoot
#     (GameplayFloorLayer, GameplayCollisionLayer, GameplayMarkersLayer,
#      LayoutRoot/DebugLabelLayer);
#   - disables the old BoundaryColliders/StaticBody2D ring (collision_layer=0,
#     collision_mask=0, visible=false, process_mode=DISABLED) so the player is
#     no longer clamped to the old map size;
#   - bakes Camera2D.limit_* from FloorLayer.get_used_rect() with a configured
#     margin so the camera covers the full generated map;
#   - dedupes editor-only Label spam created by IsoMissionMarker._ensure_label
#     (multiple @Label@xxxxx siblings) and sets show_editor_label=false on
#     each marker so the white labels are no longer drawn;
#   - audits the duplicate scene root transform (does NOT modify it; the
#     source scene has the same non-identity transform and resetting could
#     shift content).
#
# The old layer node paths and BoundaryColliders parent path are kept exactly
# where the source scene defines them. We do NOT move, rename, or delete those
# nodes - IsoMissionBase.gd at runtime references them at those exact paths.
# We only set their cells/visibility/process_mode/collision_layer.
static func _phase_0h_cleanup(scene_root: Node, manifest: Dictionary, floor_layer: TileMapLayer) -> Dictionary:
	var summary := {
		"old_tilemap_layers": [],
		"boundary_colliders": {"path": "", "found": false, "disabled": false, "child_count": 0, "static_bodies_disabled": 0, "collision_shapes_disabled": 0},
		"camera": {"path": "", "found": false, "limits_before": {}, "limits_after": {}, "applied": false},
		"marker_labels": {"markers_processed": 0, "labels_removed": 0, "labels_kept_invisible": 0, "show_editor_label_set_false": 0, "extra_at_label_siblings_removed": 0},
		"root_transform": {"position_before": [], "rotation_before": 0.0, "scale_before": [], "left_unchanged_reason": ""},
	}

	var cleanup_cfg: Dictionary = manifest.get("phase_0h_cleanup", {})
	var old_paths: Array = cleanup_cfg.get("old_artifact_layer_paths", [])
	for path in old_paths:
		var n := scene_root.get_node_or_null(String(path))
		if n == null:
			summary.old_tilemap_layers.append({"path": path, "found": false, "cleared": false})
			continue
		if n is TileMapLayer:
			var tml := n as TileMapLayer
			var before_count: int = tml.get_used_cells().size()
			tml.clear()
			tml.visible = false
			tml.enabled = false
			tml.collision_enabled = false
			summary.old_tilemap_layers.append({
				"path": path,
				"found": true,
				"class": "TileMapLayer",
				"cells_before": before_count,
				"cells_after": tml.get_used_cells().size(),
				"visible": tml.visible,
				"enabled": tml.enabled,
				"collision_enabled": tml.collision_enabled,
				"cleared": true,
			})
		else:
			# Unexpected node class at this path. Hide if possible.
			if n is CanvasItem:
				(n as CanvasItem).visible = false
			summary.old_tilemap_layers.append({
				"path": path,
				"found": true,
				"class": n.get_class(),
				"cleared": false,
				"hidden": (n is CanvasItem),
			})

	var bc_path := String(cleanup_cfg.get("boundary_colliders_path", "GameplayRoot/BoundaryColliders"))
	summary.boundary_colliders.path = bc_path
	var bc: Node = scene_root.get_node_or_null(bc_path)
	if bc != null:
		summary.boundary_colliders.found = true
		if bc is CanvasItem:
			(bc as CanvasItem).visible = false
		bc.process_mode = Node.PROCESS_MODE_DISABLED
		summary.boundary_colliders.child_count = bc.get_child_count()
		# Use Array container so deeper recursion can mutate counters reliably.
		var counts_box := [0, 0]  # [bodies_disabled, shapes_disabled]
		_phase_0h_disable_collision_recursive(bc, counts_box)
		summary.boundary_colliders.static_bodies_disabled = int(counts_box[0])
		summary.boundary_colliders.collision_shapes_disabled = int(counts_box[1])
		summary.boundary_colliders.disabled = true

	var cam_path := String(cleanup_cfg.get("camera_node_path", "Camera2D"))
	summary.camera.path = cam_path
	var cam_node: Node = scene_root.get_node_or_null(cam_path)
	if cam_node is Camera2D:
		var cam := cam_node as Camera2D
		summary.camera.found = true
		summary.camera.limits_before = {"left": cam.limit_left, "top": cam.limit_top, "right": cam.limit_right, "bottom": cam.limit_bottom}
		var rect: Rect2i = floor_layer.get_used_rect()
		var corners := [
			rect.position,
			Vector2i(rect.position.x + rect.size.x, rect.position.y),
			Vector2i(rect.position.x, rect.position.y + rect.size.y),
			Vector2i(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		]
		var min_x: int = 1 << 30
		var min_y: int = 1 << 30
		var max_x: int = -(1 << 30)
		var max_y: int = -(1 << 30)
		for c in corners:
			var w: Vector2 = floor_layer.to_global(floor_layer.map_to_local(c as Vector2i))
			min_x = mini(min_x, int(w.x))
			min_y = mini(min_y, int(w.y))
			max_x = maxi(max_x, int(w.x))
			max_y = maxi(max_y, int(w.y))
		var margin: int = int(cleanup_cfg.get("camera_margin_px", 384))
		cam.limit_left = min_x - margin
		cam.limit_top = min_y - margin
		cam.limit_right = max_x + margin
		cam.limit_bottom = max_y + margin
		summary.camera.limits_after = {"left": cam.limit_left, "top": cam.limit_top, "right": cam.limit_right, "bottom": cam.limit_bottom}
		summary.camera.applied = true
		summary.camera.margin_px = margin

	# Marker labels: dedup + suppress + set show_editor_label=false.
	var marker_root: Node = scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	if marker_root != null:
		_phase_0h_sanitize_markers(marker_root, summary.marker_labels)

	# Root transform audit (no modification).
	if scene_root is Node2D:
		var n2d := scene_root as Node2D
		summary.root_transform.position_before = [n2d.position.x, n2d.position.y]
		summary.root_transform.rotation_before = n2d.rotation
		summary.root_transform.scale_before = [n2d.scale.x, n2d.scale.y]
		summary.root_transform.is_identity = (n2d.position == Vector2.ZERO and is_zero_approx(n2d.rotation) and n2d.scale == Vector2.ONE)
		if not bool(summary.root_transform.is_identity):
			summary.root_transform.left_unchanged_reason = "source_scene_has_same_non_identity_transform_resetting_would_shift_world_positions"
	return summary

static func _phase_0h_disable_collision_recursive(node: Node, counts_box: Array) -> void:
	if node is StaticBody2D or node is CollisionObject2D:
		var co := node as CollisionObject2D
		co.collision_layer = 0
		co.collision_mask = 0
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
		counts_box[0] = int(counts_box[0]) + 1
	if node is CollisionShape2D:
		var cs := node as CollisionShape2D
		cs.disabled = true
		if cs is CanvasItem:
			(cs as CanvasItem).visible = false
		counts_box[1] = int(counts_box[1]) + 1
	for child in node.get_children():
		_phase_0h_disable_collision_recursive(child, counts_box)

static func _phase_0h_sanitize_markers(node: Node, summary: Dictionary) -> void:
	# Detects nodes that act like an IsoMissionMarker (script + marker_type).
	# Walks every such node, sets show_editor_label = false, and removes any
	# Label children whose name matches "@Label@*" (autogenerated label spam
	# from IsoMissionMarker._ensure_label across repeated editor saves). Keeps
	# at most one Label named "EditorLabel" (made invisible by show_editor_label).
	if node.get_script() != null and node.has_method("get") and node.get("marker_type") != null:
		summary.markers_processed += 1
		# Suppress the white label text via the public flag.
		node.set("show_editor_label", false)
		summary.show_editor_label_set_false += 1
		# Walk children, remove duplicate labels, keep at most one EditorLabel.
		var labels: Array = []
		for child in node.get_children():
			if child is Label:
				labels.append(child)
		var kept_one_editor_label := false
		for lbl in labels:
			var l := lbl as Label
			var nm := String(l.name)
			if nm == "EditorLabel" and not kept_one_editor_label:
				kept_one_editor_label = true
				l.visible = false
				summary.labels_kept_invisible += 1
			elif nm.begins_with("@Label@") or nm == "EditorLabel":
				node.remove_child(l)
				l.queue_free()
				if nm.begins_with("@Label@"):
					summary.extra_at_label_siblings_removed += 1
				summary.labels_removed += 1
	for child in node.get_children():
		_phase_0h_sanitize_markers(child, summary)


# =============================================================================
#  Phase 0I — runtime truth fixes (wall collision, authoring hide, gate blocker,
#  promoted core collectibles, route teleport safeguard).
# =============================================================================

const PHASE_0I_AUTHORING_HIDER_PATH := "res://src/missions/iso/runtime/Phase0IAuthoringHider.gd"
const PHASE_0I_ROUTE_SAFEGUARD_PATH := "res://src/missions/iso/runtime/Phase0IRouteSafeguard.gd"
const PHASE_0I_COLLECTIBLE_PICKUP_PATH := "res://src/missions/iso/placeholders/MissionCollectiblePickupPlaceholder.gd"
const PHASE_0I_CLUE_PICKUP_PATH := "res://src/missions/iso/placeholders/MissionCluePickupPlaceholder.gd"
const PHASE_0I_GENERATED_COLLECTIBLES_PARENT_PATH := "EntityRoot/Interactables/Phase0IGeneratedCollectibles"
const PHASE_0I_WALLS_LAYER_BITS := 4  # project layer 3 = Walls (1 << 2 = 4)


static func _phase_0i_cleanup(scene_root: Node, manifest: Dictionary, floor_layer: TileMapLayer, wall_layer: TileMapLayer, collision_layer: TileMapLayer, marker_tile_layer: TileMapLayer, anchor_cell: Vector2i) -> Dictionary:
	var summary := {
		"wall_layer": {"collision_enabled_before": null, "collision_enabled_after": null, "tileset_physics_layer_collision_layer_bits": null},
		"marker_tile_layer": {"hidden_at_runtime": false, "z_index_after_runtime": null, "hider_attached": false},
		"editor_only_placeholders": {"found": false, "hider_attached": false},
		"authoring_marker_root_subnodes": [],
		"tilemap_authoring_layers_collision_disabled": [],
		"generated_runtime_collision": {"root_path": "", "gate_blocker": {}},
		"core_collectibles_promoted": [],
		"core_collectibles_skipped": [],
		"route_safeguard": {"node_path": "", "attached": false, "targets": [], "legacy_blockers": []},
		"errors": [],
	}
	var cfg: Dictionary = manifest.get("phase_0i_cleanup", {})
	if cfg.is_empty():
		summary.errors.append("phase_0i_cleanup_config_missing")
		return summary

	# ---- B: Wall collision -----------------------------------------------------
	if wall_layer != null:
		summary.wall_layer.collision_enabled_before = bool(wall_layer.collision_enabled)
		if bool(cfg.get("wall_layer_enable_collision", true)):
			wall_layer.collision_enabled = true
		summary.wall_layer.collision_enabled_after = bool(wall_layer.collision_enabled)
		var ts: TileSet = wall_layer.tile_set
		if ts != null and ts.get_physics_layers_count() > 0:
			summary.wall_layer.tileset_physics_layer_collision_layer_bits = int(ts.get_physics_layer_collision_layer(0))

	# ---- A: Hide MarkerTileLayer + EditorOnlyPlaceholders + authoring marker
	#         root containers at runtime via Phase0IAuthoringHider helper child.
	var hider_script: Script = ResourceLoader.load(PHASE_0I_AUTHORING_HIDER_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if hider_script == null:
		summary.errors.append("authoring_hider_script_load_failed")
	else:
		# MarkerTileLayer.
		if marker_tile_layer != null:
			_phase_0i_attach_hider(marker_tile_layer, hider_script, scene_root, true, true)
			summary.marker_tile_layer.hider_attached = true
			summary.marker_tile_layer.hidden_at_runtime = true
			summary.marker_tile_layer.z_index_after_runtime = -4096
		# EditorOnlyPlaceholders.
		var placeholders_path := String(cfg.get("editor_only_placeholders_path", "GameplayRoot/MarkerRoot/EditorOnlyPlaceholders"))
		var placeholders_node: Node = scene_root.get_node_or_null(placeholders_path)
		if placeholders_node != null:
			summary.editor_only_placeholders.found = true
			_phase_0i_attach_hider(placeholders_node, hider_script, scene_root, true, false)
			summary.editor_only_placeholders.hider_attached = true
		# Each authoring marker root subnode (Spawns, Routes, Transitions, etc.).
		var auth_paths: Array = cfg.get("authoring_marker_root_runtime_hide_paths", [])
		for p in auth_paths:
			var path_str := String(p)
			var node: Node = scene_root.get_node_or_null(path_str)
			if node == null:
				summary.authoring_marker_root_subnodes.append({"path": path_str, "found": false, "attached": false})
				continue
			_phase_0i_attach_hider(node, hider_script, scene_root, true, false)
			summary.authoring_marker_root_subnodes.append({"path": path_str, "found": true, "attached": true})

	# ---- A2: Disable collision on TileMap-authoring layers explicitly.
	var auth_layer_paths: Array = cfg.get("tilemap_authoring_layer_paths_collision_disable", [])
	for path_obj in auth_layer_paths:
		var p2 := String(path_obj)
		var n2: Node = scene_root.get_node_or_null(p2)
		if n2 is TileMapLayer:
			(n2 as TileMapLayer).collision_enabled = false
		summary.tilemap_authoring_layers_collision_disabled.append({"path": p2, "found": n2 != null, "is_tilemap_layer": n2 is TileMapLayer})

	# ---- C: Generated runtime collision: code gate blocker ---------------------
	var rc_root_path := String(cfg.get("generated_runtime_collision_root_path", "GameplayRoot/GeneratedRuntimeCollision"))
	var rc_root: Node2D = _phase_0i_ensure_node2d(scene_root, rc_root_path)
	summary.generated_runtime_collision.root_path = rc_root_path
	var gate_subpath := String(cfg.get("gate_blockers_subpath", "GateBlockers"))
	var gate_root: Node2D = _phase_0i_ensure_child_node2d(rc_root, gate_subpath, scene_root)
	var gate_cfg: Dictionary = cfg.get("code_gate_blocker", {})
	if not gate_cfg.is_empty():
		summary.generated_runtime_collision.gate_blocker = _phase_0i_create_gate_blocker(scene_root, floor_layer, gate_root, gate_cfg, anchor_cell)

	# ---- D: Promote 5 core collectibles to real Area2D + script ----------------
	var promote_list: Array = cfg.get("core_collectibles_to_promote", [])
	if not promote_list.is_empty():
		var collectibles_parent: Node2D = _phase_0i_ensure_node2d(scene_root, PHASE_0I_GENERATED_COLLECTIBLES_PARENT_PATH)
		# Always clear and rebuild this parent for idempotency.
		for child in collectibles_parent.get_children():
			collectibles_parent.remove_child(child)
			child.queue_free()
		var pickup_script: Script = ResourceLoader.load(PHASE_0I_COLLECTIBLE_PICKUP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		var clue_script: Script = ResourceLoader.load(PHASE_0I_CLUE_PICKUP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		for entry_obj in promote_list:
			var entry: Dictionary = entry_obj
			var promo := _phase_0i_promote_collectible(scene_root, floor_layer, collectibles_parent, entry, pickup_script, clue_script, anchor_cell, manifest)
			if bool(promo.get("ok", false)):
				summary.core_collectibles_promoted.append(promo)
			else:
				summary.core_collectibles_skipped.append(promo)

	# ---- E: Route safeguard runtime helper -------------------------------------
	var safeguard_script: Script = ResourceLoader.load(PHASE_0I_ROUTE_SAFEGUARD_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	var safeguard_parent_path := String(cfg.get("route_safeguard_parent_path", "GameplayRoot"))
	var safeguard_parent: Node = scene_root.get_node_or_null(safeguard_parent_path)
	var safeguard_name := String(cfg.get("route_safeguard_node_name", "Phase0IRouteSafeguard"))
	if safeguard_script != null and safeguard_parent != null:
		# Remove any existing instance for idempotency.
		var existing := safeguard_parent.get_node_or_null(safeguard_name)
		if existing != null:
			safeguard_parent.remove_child(existing)
			existing.queue_free()
		var sg := Node.new()
		sg.set_script(safeguard_script)
		sg.name = safeguard_name
		safeguard_parent.add_child(sg)
		sg.owner = scene_root
		# Document targets for validator audit. The script has its own defaults;
		# we mirror them into metadata for transparent verification.
		sg.set_meta("phase_0i_safeguard_targets", PackedStringArray([
			"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_vent_return",
			"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_louis_return",
		]))
		sg.set_meta("phase_0i_legacy_blockers_to_disable", PackedStringArray([
			"GameplayRoot/RuntimeSystems/TransitionTriggers/CodeGateBarrier_garage_office_code",
		]))
		summary.route_safeguard.attached = true
		summary.route_safeguard.node_path = safeguard_parent_path + "/" + safeguard_name
		summary.route_safeguard.targets = [
			"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_vent_return",
			"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_louis_return",
		]
		summary.route_safeguard.legacy_blockers = [
			"GameplayRoot/RuntimeSystems/TransitionTriggers/CodeGateBarrier_garage_office_code",
		]
	else:
		summary.errors.append("route_safeguard_attach_failed")

	return summary


static func _phase_0i_attach_hider(parent: Node, hider_script: Script, scene_root: Node, hide: bool, force_low_z: bool) -> void:
	if parent == null:
		return
	# Remove any existing Phase0IAuthoringHider child for idempotency.
	for child in parent.get_children():
		if child is Node and child.get_script() == hider_script:
			parent.remove_child(child)
			child.queue_free()
	var hider := Node.new()
	hider.set_script(hider_script)
	hider.name = "Phase0IAuthoringHider"
	if "hide_at_runtime" in hider:
		hider.set("hide_at_runtime", hide)
	if "force_low_z_index" in hider:
		hider.set("force_low_z_index", force_low_z)
	if "disable_collision_on_tilemap" in hider:
		hider.set("disable_collision_on_tilemap", true)
	parent.add_child(hider)
	hider.owner = scene_root


static func _phase_0i_ensure_node2d(scene_root: Node, dot_path: String) -> Node2D:
	var existing: Node = scene_root.get_node_or_null(dot_path)
	if existing is Node2D:
		return existing as Node2D
	if existing != null:
		return null
	# Create the chain segment by segment.
	var parts := dot_path.split("/")
	var current: Node = scene_root
	var partial := ""
	for part in parts:
		if String(part).is_empty():
			continue
		partial = (partial + "/" + part) if partial.length() > 0 else String(part)
		var nxt: Node = scene_root.get_node_or_null(partial)
		if nxt == null:
			var n2d := Node2D.new()
			n2d.name = String(part)
			current.add_child(n2d)
			n2d.owner = scene_root
			current = n2d
		else:
			current = nxt
	return current as Node2D


static func _phase_0i_ensure_child_node2d(parent: Node, child_name: String, scene_root: Node) -> Node2D:
	var existing: Node = parent.get_node_or_null(child_name)
	if existing is Node2D:
		return existing as Node2D
	if existing != null:
		parent.remove_child(existing)
		existing.queue_free()
	var n := Node2D.new()
	n.name = child_name
	parent.add_child(n)
	n.owner = scene_root
	return n


static func _phase_0i_create_gate_blocker(scene_root: Node, floor_layer: TileMapLayer, gate_root: Node2D, gate_cfg: Dictionary, anchor_cell: Vector2i) -> Dictionary:
	var manifest_id := String(gate_cfg.get("manifest_id", "BLOCK_code_gate"))
	# Idempotent: if already there, free and recreate.
	var existing: Node = gate_root.get_node_or_null(manifest_id)
	if existing != null:
		gate_root.remove_child(existing)
		existing.queue_free()
	var cell_x_rel: int = int(gate_cfg.get("cell_x", 150))
	var cell_y_rel: int = int(gate_cfg.get("cell_y", 3))
	var abs_cell := Vector2i(anchor_cell.x + cell_x_rel, anchor_cell.y + cell_y_rel)
	var local_pos: Vector2 = floor_layer.map_to_local(abs_cell)
	var world_pos: Vector2 = floor_layer.to_global(local_pos)

	var body := StaticBody2D.new()
	body.name = manifest_id
	body.collision_layer = int(gate_cfg.get("collision_layer_bits", PHASE_0I_WALLS_LAYER_BITS))
	body.collision_mask = int(gate_cfg.get("collision_mask_bits", 0))
	body.global_position = world_pos
	gate_root.add_child(body)
	body.owner = scene_root

	var shape_node := CollisionShape2D.new()
	shape_node.name = "Shape"
	var rect := RectangleShape2D.new()
	var size_arr: Array = gate_cfg.get("shape_size_px", [64, 64])
	rect.size = Vector2(float(size_arr[0]), float(size_arr[1]))
	shape_node.shape = rect
	body.add_child(shape_node)
	shape_node.owner = scene_root

	# Metadata for future-unlock and validator.
	body.set_meta("phase_0i_generated_gate_blocker", true)
	body.set_meta("manifest_id", manifest_id)
	body.set_meta("linked_gate_id", String(gate_cfg.get("linked_gate_id", "GATE_garage_code")))
	body.set_meta("linked_input_id", String(gate_cfg.get("linked_input_id", "SAFE_CODE_INPUT_ZONE")))
	body.set_meta("future_unlockable", bool(gate_cfg.get("future_unlockable", true)))
	body.set_meta("abs_cell", PackedInt32Array([abs_cell.x, abs_cell.y]))

	var gb_node_path := "GameplayRoot/GeneratedRuntimeCollision/GateBlockers/" + manifest_id
	return {
		"manifest_id": manifest_id,
		"node_path": gb_node_path,
		"abs_cell": [abs_cell.x, abs_cell.y],
		"world_position": [world_pos.x, world_pos.y],
		"shape_size_px": [rect.size.x, rect.size.y],
		"collision_layer": body.collision_layer,
		"collision_mask": body.collision_mask,
		"future_unlockable": bool(body.get_meta("future_unlockable", true)),
		"linked_gate_id": String(body.get_meta("linked_gate_id", "")),
		"linked_input_id": String(body.get_meta("linked_input_id", "")),
		"created": true,
	}


static func _phase_0i_promote_collectible(scene_root: Node, floor_layer: TileMapLayer, parent: Node2D, entry: Dictionary, pickup_script: Script, clue_script: Script, anchor_cell: Vector2i, manifest: Dictionary) -> Dictionary:
	var manifest_id := String(entry.get("manifest_id", ""))
	if manifest_id == "":
		return {"ok": false, "manifest_id": "", "reason": "missing_manifest_id"}
	var implementation := String(entry.get("implementation", "MissionCollectiblePickupPlaceholder"))
	# Find the manifest row to get the cell.
	var rows: Array = manifest.get("runtime_marker_targets", [])
	var row_found: Dictionary = {}
	for r_obj in rows:
		var r: Dictionary = r_obj
		if String(r.get("manifest_id", "")) == manifest_id:
			row_found = r
			break
	if row_found.is_empty():
		return {"ok": false, "manifest_id": manifest_id, "reason": "manifest_row_not_found"}
	var cell := Vector2i(anchor_cell.x + int(row_found.get("x", 0)), anchor_cell.y + int(row_found.get("y", 0)))
	var local_pos: Vector2 = floor_layer.map_to_local(cell)
	var world_pos: Vector2 = floor_layer.to_global(local_pos)

	var script_to_use: Script = pickup_script if implementation == "MissionCollectiblePickupPlaceholder" else clue_script
	if script_to_use == null:
		return {"ok": false, "manifest_id": manifest_id, "reason": "script_load_failed_for_" + implementation}

	var area := Area2D.new()
	area.set_script(script_to_use)
	area.name = manifest_id
	# CollisionShape2D child.
	var shape_node := CollisionShape2D.new()
	shape_node.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = float(entry.get("shape_radius", 18.0))
	shape_node.shape = circle
	area.add_child(shape_node)

	# Configure script properties.
	if implementation == "MissionCollectiblePickupPlaceholder":
		area.set("collectible_type", String(entry.get("collectible_type", "polaroid")))
		area.set("collectible_id", String(entry.get("collectible_id", manifest_id)))
		area.set("required", bool(entry.get("required", false)))
		area.set("placeholder_id", String(entry.get("collectible_id", manifest_id)))
	else:
		area.set("clue_id", String(entry.get("clue_id", manifest_id)))
		area.set("category", String(entry.get("category", "Mission Bible")))
		area.set("clue_description", String(entry.get("clue_description", "")))
		area.set("connects_to", String(entry.get("connects_to", "Sterling Tower")))
		area.set("placeholder_id", String(entry.get("clue_id", manifest_id)))
	# Common script fields.
	area.set("display_name", String(entry.get("display_name", manifest_id)))
	area.set("interaction_text", String(entry.get("interaction_text", "")))
	area.set("objective_update", String(entry.get("objective_update", "")))
	area.set("mission_id", String(manifest.get("mission_id_hint", "taco_bell_iso_blockout")))

	parent.add_child(area)
	area.owner = scene_root
	area.global_position = world_pos
	# Metadata.
	area.set_meta("phase_0i_promoted_collectible", true)
	area.set_meta("phase_0i_implementation", implementation)
	area.set_meta("phase_0i_manifest_id", manifest_id)
	area.set_meta("phase_0i_abs_cell", PackedInt32Array([cell.x, cell.y]))

	var col_node_path := "EntityRoot/Interactables/Phase0IGeneratedCollectibles/" + manifest_id
	return {
		"ok": true,
		"manifest_id": manifest_id,
		"implementation": implementation,
		"node_path": col_node_path,
		"abs_cell": [cell.x, cell.y],
		"world_position": [world_pos.x, world_pos.y],
	}
