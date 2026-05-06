@tool
class_name TacoBellExpandedLayoutShared
extends RefCounted

## Shared helpers for the deterministic Taco Bell expanded map compiler (Phase 0G v6).
##
## Pure utility module. Used by [TacoBellExpandedLayoutBuilder] and
## [TacoBellExpandedLayoutValidator]. Does not modify scenes.

const MANIFEST_PATH := "res://assets/missions/layouts/taco_bell_expanded_layout_v6.json"
const SOURCE_SCENE_PATH := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const TARGET_SCENE_PATH := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const OPTIONAL_REFERENCE_IMAGE_PATH := "res://docs/reference/taco_bell_mission_layout_map.png"
const EDITOR_ONLY_PARENT_NODE_NAME := "EditorOnlyPlaceholders"

const REAL_EXISTING := "real_existing"
const REAL_IF_SAFE := "real_if_safe"
const EDITOR_ONLY := "editor_only_placeholder"

# ------------------------------ Manifest IO -----------------------------------

static func load_manifest(path: String = MANIFEST_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"_error": "manifest_missing", "_path": path}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"_error": "manifest_parse_failed", "_path": path}
	return parsed as Dictionary

static func file_md5(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_md5(path)

static func file_mtime(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	return FileAccess.get_modified_time(path)

# ------------------------------ Resource loading ------------------------------

## Cache-safe load. Always uses CACHE_MODE_IGNORE to avoid stale resources during
## repeated load/save cycles in builds.
static func load_cache_safe(path: String, type_hint: String = "") -> Resource:
	return ResourceLoader.load(path, type_hint, ResourceLoader.CACHE_MODE_IGNORE)

# ------------------------------ Anchor lookup ---------------------------------

static func find_anchor_marker(scene_root: Node, anchor_marker_id: String) -> Node:
	var marker_root := scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	if marker_root == null:
		return null
	return _find_node_by_marker_id(marker_root, anchor_marker_id)

static func _find_node_by_marker_id(node: Node, marker_id: String) -> Node:
	if node.has_method("get") and node.get("marker_id") != null:
		if String(node.get("marker_id")) == marker_id:
			return node
	if node.name == marker_id:
		return node
	for child in node.get_children():
		var hit := _find_node_by_marker_id(child, marker_id)
		if hit != null:
			return hit
	return null

static func compute_anchor_cell(anchor_node: Node2D, floor_layer: TileMapLayer) -> Vector2i:
	var world_pos: Vector2 = anchor_node.global_position
	var floor_local: Vector2 = floor_layer.to_local(world_pos)
	return floor_layer.local_to_map(floor_local)

static func abs_cell(anchor_cell: Vector2i, rel_x: int, rel_y: int) -> Vector2i:
	return Vector2i(anchor_cell.x + rel_x, anchor_cell.y + rel_y)

static func cell_to_world(floor_layer: TileMapLayer, cell: Vector2i) -> Vector2:
	return floor_layer.to_global(floor_layer.map_to_local(cell))

# ------------------------------ MarkerRoot index ------------------------------

## Recursively walks `marker_root` and returns:
##   {
##     "by_marker_id": { String -> Node },
##     "by_node_name": { String -> Node },
##     "all_nodes": Array[Node]
##   }
##
## Includes only nodes that expose a `marker_id` exported field (i.e. nodes
## that the runtime marker scanner would index). Plain Node2D editor-only
## placeholders are intentionally excluded by this filter.
static func index_marker_root(marker_root: Node) -> Dictionary:
	var by_marker_id := {}
	var by_node_name := {}
	var all_nodes := []
	_walk_index(marker_root, by_marker_id, by_node_name, all_nodes)
	return {
		"by_marker_id": by_marker_id,
		"by_node_name": by_node_name,
		"all_nodes": all_nodes,
	}

static func _walk_index(node: Node, by_marker_id: Dictionary, by_node_name: Dictionary, all_nodes: Array) -> void:
	if node.has_method("get") and node.get("marker_id") != null:
		var mid := String(node.get("marker_id"))
		if mid != "" and not by_marker_id.has(mid):
			by_marker_id[mid] = node
		if not by_node_name.has(node.name):
			by_node_name[String(node.name)] = node
		all_nodes.append(node)
	for child in node.get_children():
		_walk_index(child, by_marker_id, by_node_name, all_nodes)

# ------------------------------ Marker matching --------------------------------

## Try to resolve a manifest row to an existing runtime marker. Returns the Node
## or null. Does not move it.
##
## Match order:
##   1. exact marker_id == manifest_id
##   2. node name == manifest_id
##   3. marker_id in alias_of_legacy_marker_ids
##   4. node name in alias_of_legacy_marker_ids
static func match_runtime_marker(row: Dictionary, marker_index: Dictionary) -> Node:
	var manifest_id := String(row.get("manifest_id", ""))
	if manifest_id == "":
		return null
	var by_id: Dictionary = marker_index.get("by_marker_id", {})
	var by_name: Dictionary = marker_index.get("by_node_name", {})

	if by_id.has(manifest_id):
		return by_id[manifest_id]
	if by_name.has(manifest_id):
		return by_name[manifest_id]

	var aliases: Array = row.get("alias_of_legacy_marker_ids", [])
	for a in aliases:
		var alias := String(a)
		if alias == "":
			continue
		if by_id.has(alias):
			return by_id[alias]
		if by_name.has(alias):
			return by_name[alias]
	return null

# ------------------------------ Equivalence groups -----------------------------

## Build equivalence groups across runtime_marker_targets rows. Groups rows that
## share:
##   - manifest_id (always)
##   - any alias_of_legacy_marker_ids entry
##   - matched_existing_runtime_marker_id
##   - (abs_cell, category) when both equal
##
## Returns array of groups; each group is a Dictionary:
##   {
##     "rows": Array[Dictionary],
##     "canonical_index": int,
##     "merged_aliases": Array[String],
##     "collision_warnings": Array[String]
##   }
##
## Also detects "same cell + same marker_tile_abbr but different category and no
## shared alias/runtime equivalence" as a hard manifest collision (recorded in
## the group's collision_warnings; validator escalates to FAIL).
static func build_equivalence_groups(rows: Array, anchor_cell: Vector2i, marker_index: Dictionary) -> Dictionary:
	var n := rows.size()
	var parent := []
	parent.resize(n)
	for i in range(n):
		parent[i] = i

	var find = func(idx: int) -> int:
		var i := idx
		while parent[i] != i:
			parent[i] = parent[parent[i]]
			i = parent[i]
		return i

	var union = func(a: int, b: int) -> void:
		var ra: int = find.call(a)
		var rb: int = find.call(b)
		if ra != rb:
			parent[ra] = rb

	# Pre-compute keys per row.
	var enriched := []
	enriched.resize(n)
	for i in range(n):
		var row: Dictionary = rows[i]
		var rx: int = int(row.get("x", 0))
		var ry: int = int(row.get("y", 0))
		var ac := abs_cell(anchor_cell, rx, ry)
		var matched_node: Node = match_runtime_marker(row, marker_index)
		var matched_id := ""
		if matched_node != null and matched_node.has_method("get") and matched_node.get("marker_id") != null:
			matched_id = String(matched_node.get("marker_id"))
		enriched[i] = {
			"row": row,
			"abs_cell": ac,
			"matched_node": matched_node,
			"matched_id": matched_id,
		}

	# Group by manifest_id.
	var manifest_id_to_idx := {}
	for i in range(n):
		var mid := String((enriched[i].row as Dictionary).get("manifest_id", ""))
		if manifest_id_to_idx.has(mid):
			union.call(manifest_id_to_idx[mid], i)
		else:
			manifest_id_to_idx[mid] = i

	# Group by matched runtime marker_id.
	var matched_to_idx := {}
	for i in range(n):
		var matched: String = enriched[i].matched_id
		if matched == "":
			continue
		if matched_to_idx.has(matched):
			union.call(matched_to_idx[matched], i)
		else:
			matched_to_idx[matched] = i

	# Group by alias entries.
	var alias_to_idx := {}
	for i in range(n):
		var aliases: Array = (enriched[i].row as Dictionary).get("alias_of_legacy_marker_ids", [])
		for a in aliases:
			var alias := String(a)
			if alias_to_idx.has(alias):
				union.call(alias_to_idx[alias], i)
			else:
				alias_to_idx[alias] = i

	# Group by (abs_cell, category) when both shared.
	var cell_cat_to_idx := {}
	for i in range(n):
		var row_dict: Dictionary = enriched[i].row
		var category := String(row_dict.get("category", ""))
		if category == "" or category == "SPAWN":
			continue
		var ac: Vector2i = enriched[i].abs_cell
		var key := "%d_%d_%s" % [ac.x, ac.y, category]
		if cell_cat_to_idx.has(key):
			union.call(cell_cat_to_idx[key], i)
		else:
			cell_cat_to_idx[key] = i

	# Bucket rows by root.
	var groups_by_root := {}
	for i in range(n):
		var r: int = find.call(i)
		if not groups_by_root.has(r):
			groups_by_root[r] = []
		(groups_by_root[r] as Array).append(i)

	# Detect (abs_cell, marker_tile_abbr) collisions WITHOUT shared root group.
	var cell_abbr_to_root := {}
	var collisions := []
	for i in range(n):
		var row_dict: Dictionary = enriched[i].row
		var abbr := String(row_dict.get("marker_tile_abbr", ""))
		if abbr == "":
			continue
		var ac: Vector2i = enriched[i].abs_cell
		var key := "%d_%d_%s" % [ac.x, ac.y, abbr]
		var root_i: int = find.call(i)
		if cell_abbr_to_root.has(key):
			var other_root: int = cell_abbr_to_root[key]
			if other_root != root_i:
				collisions.append({
					"key": key,
					"row_a": String((enriched[i].row as Dictionary).get("manifest_id", "")),
					"abs_cell": ac,
					"marker_tile_abbr": abbr,
					"detail": "Two unrelated rows share (abs_cell, marker_tile_abbr) without alias/runtime/category equivalence."
				})
		else:
			cell_abbr_to_root[key] = root_i

	# Build canonical per group.
	var groups := []
	for root_idx in groups_by_root.keys():
		var member_idxs: Array = groups_by_root[root_idx]
		var canonical_idx: int = _pick_canonical(member_idxs, enriched)
		var merged_aliases := []
		for mi in member_idxs:
			if mi == canonical_idx:
				continue
			merged_aliases.append(String((enriched[mi].row as Dictionary).get("manifest_id", "")))
		groups.append({
			"member_indices": member_idxs,
			"canonical_index": canonical_idx,
			"merged_aliases": merged_aliases,
			"abs_cell": enriched[canonical_idx].abs_cell,
			"matched_node": enriched[canonical_idx].matched_node,
			"matched_id": enriched[canonical_idx].matched_id,
		})

	return {
		"enriched": enriched,
		"groups": groups,
		"collisions": collisions,
	}

static func _pick_canonical(member_idxs: Array, enriched: Array) -> int:
	# Precedence:
	#   1. tier real_existing wins
	#   2. placeholder_allowed=false wins
	#   3. lowercase legacy id (no uppercase letter in manifest_id) wins
	#   4. shortest manifest_id wins (stable, deterministic tiebreak)
	var best: int = member_idxs[0]
	for idx in member_idxs:
		if _better(idx, best, enriched):
			best = idx
	return best

static func _better(a: int, b: int, enriched: Array) -> bool:
	var ra: Dictionary = enriched[a].row
	var rb: Dictionary = enriched[b].row
	var ta := _tier_score(String(ra.get("desired_runtime_tier", "")))
	var tb := _tier_score(String(rb.get("desired_runtime_tier", "")))
	if ta != tb:
		return ta > tb
	var pa := bool(ra.get("placeholder_allowed", true))
	var pb := bool(rb.get("placeholder_allowed", true))
	if pa != pb:
		return not pa  # placeholder_allowed=false beats true
	var aid := String(ra.get("manifest_id", ""))
	var bid := String(rb.get("manifest_id", ""))
	var a_lower := _is_lowercase_legacy(aid)
	var b_lower := _is_lowercase_legacy(bid)
	if a_lower != b_lower:
		return a_lower
	if aid.length() != bid.length():
		return aid.length() < bid.length()
	return aid < bid

static func _tier_score(tier: String) -> int:
	match tier:
		REAL_EXISTING:
			return 3
		REAL_IF_SAFE:
			return 2
		EDITOR_ONLY:
			return 1
		_:
			return 0

static func _is_lowercase_legacy(manifest_id: String) -> bool:
	if manifest_id == "":
		return false
	for c in manifest_id:
		if c >= "A" and c <= "Z":
			return false
	return true

# ------------------------------ Atlas helpers ---------------------------------

static func abbr_to_atlas(manifest: Dictionary, abbreviation: String) -> Dictionary:
	if abbreviation == "":
		return {"ok": false, "reason": "empty_abbreviation"}
	var marker_atlas: Dictionary = manifest.get("tile_lookup", {}).get("marker_atlas", {})
	var abbreviations: Dictionary = marker_atlas.get("abbreviations", {})
	if not abbreviations.has(abbreviation):
		return {"ok": false, "reason": "unknown_abbreviation", "abbreviation": abbreviation}
	var coords: Array = abbreviations[abbreviation]
	return {
		"ok": true,
		"source_id": int(marker_atlas.get("source_id", 0)),
		"atlas_coords": Vector2i(int(coords[0]), int(coords[1]))
	}

static func tile_lookup_floor(manifest: Dictionary) -> Dictionary:
	var f: Dictionary = manifest.get("tile_lookup", {}).get("floor", {})
	var coords: Array = f.get("atlas_coords", [0, 0])
	return {"source_id": int(f.get("source_id", 0)), "atlas_coords": Vector2i(int(coords[0]), int(coords[1]))}

static func tile_lookup_wall(manifest: Dictionary) -> Dictionary:
	var f: Dictionary = manifest.get("tile_lookup", {}).get("wall", {})
	var coords: Array = f.get("atlas_coords", [1, 0])
	return {"source_id": int(f.get("source_id", 0)), "atlas_coords": Vector2i(int(coords[0]), int(coords[1]))}

static func tile_lookup_cover(manifest: Dictionary) -> Dictionary:
	var f: Dictionary = manifest.get("tile_lookup", {}).get("cover", {})
	var coords: Array = f.get("atlas_coords", [1, 0])
	return {"source_id": int(f.get("source_id", 0)), "atlas_coords": Vector2i(int(coords[0]), int(coords[1]))}

static func tile_lookup_collision(manifest: Dictionary) -> Dictionary:
	var f: Dictionary = manifest.get("tile_lookup", {}).get("collision", {})
	var coords: Array = f.get("atlas_coords", [1, 0])
	return {"source_id": int(f.get("source_id", 0)), "atlas_coords": Vector2i(int(coords[0]), int(coords[1]))}

# ------------------------------ Cell sets -------------------------------------

static func collect_floor_cells(manifest: Dictionary, anchor_cell: Vector2i) -> Dictionary:
	var cells := {}
	for rect in manifest.get("floor_rects", []):
		var xmin: int = int(rect.get("x_min", 0)) + anchor_cell.x
		var xmax: int = int(rect.get("x_max", 0)) + anchor_cell.x
		var ymin: int = int(rect.get("y_min", 0)) + anchor_cell.y
		var ymax: int = int(rect.get("y_max", 0)) + anchor_cell.y
		for x in range(xmin, xmax + 1):
			for y in range(ymin, ymax + 1):
				cells[Vector2i(x, y)] = String(rect.get("id", ""))
	return cells

static func collect_open_gap_cells(manifest: Dictionary, anchor_cell: Vector2i) -> Dictionary:
	var cells := {}
	for gap in manifest.get("connection_gaps", []):
		var t := String(gap.get("type", "open"))
		# Only "open" main-route gaps and "vent_only_internal" (between Bentley
		# zones) are added here. "vent_only_interface" is intentionally NOT in
		# the open set: the builder will paint a player blocker on the cell
		# immediately into the passage at those interfaces.
		if t == "open" or t == "vent_only_internal":
			var xmin: int = int(gap.get("x_min", 0)) + anchor_cell.x
			var xmax: int = int(gap.get("x_max", 0)) + anchor_cell.x
			var ymin: int = int(gap.get("y_min", 0)) + anchor_cell.y
			var ymax: int = int(gap.get("y_max", 0)) + anchor_cell.y
			for x in range(xmin, xmax + 1):
				for y in range(ymin, ymax + 1):
					cells[Vector2i(x, y)] = String(gap.get("id", ""))
	return cells

static func collect_explicit_block_cells(manifest: Dictionary, anchor_cell: Vector2i) -> Array:
	var out := []
	for blk in manifest.get("explicit_block_cells", []):
		out.append({
			"id": String(blk.get("id", "")),
			"abs_cell": Vector2i(int(blk.get("x", 0)) + anchor_cell.x, int(blk.get("y", 0)) + anchor_cell.y)
		})
	return out

static func collect_vent_blocker_cells(manifest: Dictionary, anchor_cell: Vector2i) -> Array:
	var out := []
	for vi in manifest.get("vent_only_interfaces", []):
		var blockers: Array = vi.get("blocker_cells_into_passage", [])
		for blk in blockers:
			var xmin: int = int(blk.get("x_min", 0)) + anchor_cell.x
			var xmax: int = int(blk.get("x_max", 0)) + anchor_cell.x
			var ymin: int = int(blk.get("y_min", 0)) + anchor_cell.y
			var ymax: int = int(blk.get("y_max", 0)) + anchor_cell.y
			for x in range(xmin, xmax + 1):
				for y in range(ymin, ymax + 1):
					out.append({
						"vent_interface_id": String(vi.get("id", "")),
						"abs_cell": Vector2i(x, y)
					})
	return out

# ------------------------------ Misc ------------------------------------------

static func now_timestamp_string() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]

static func project_root_globalized() -> String:
	return ProjectSettings.globalize_path("res://")
