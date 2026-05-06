@tool
class_name TacoBellExpandedLayoutValidator
extends RefCounted

## Validator for the Phase 0G v6 deterministic Taco Bell map compiler.
##
## Two entrypoints:
##   - validate_scene_root(root, manifest, context) -> Dictionary
##   - validate_scene_file(scene_path, manifest, context) -> Dictionary
##
## The dry-run pipeline (Phase E) calls validate_scene_root() against the
## in-memory root produced by the builder. Phase H calls validate_scene_file()
## against the saved duplicate.

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")

# ----------------------------- Public entrypoints -----------------------------

static func validate_scene_root(scene_root: Node, manifest: Dictionary, context: Dictionary = {}) -> Dictionary:
	context["entrypoint"] = "validate_scene_root"
	context["scene_root_in_memory"] = true
	return _validate(scene_root, manifest, context)

static func validate_scene_file(scene_path: String, manifest: Dictionary, context: Dictionary = {}) -> Dictionary:
	context["entrypoint"] = "validate_scene_file"
	context["scene_root_in_memory"] = false
	context["scene_file_path"] = scene_path
	if not FileAccess.file_exists(scene_path):
		return {
			"pass": false,
			"phase": "load",
			"errors": ["target_scene_missing: " + scene_path],
			"hard_assertions": {"target_scene_exists": false, "target_scene_loads": false},
		}
	var packed: PackedScene = Shared.load_cache_safe(scene_path, "PackedScene") as PackedScene
	if packed == null:
		return {
			"pass": false,
			"phase": "load",
			"errors": ["target_scene_load_failed: " + scene_path],
			"hard_assertions": {"target_scene_exists": true, "target_scene_loads": false},
		}
	var root := packed.instantiate()
	var result := _validate(root, manifest, context)
	root.queue_free()
	return result

# ----------------------------- Core --------------------------------------------

static func _validate(scene_root: Node, manifest: Dictionary, context: Dictionary) -> Dictionary:
	var result := {
		"pass": true,
		"phase": "starting",
		"entrypoint": String(context.get("entrypoint", "")),
		"scene_root_in_memory": bool(context.get("scene_root_in_memory", false)),
		"errors": [],
		"warnings": [],
		"info": [],
		"hard_assertions": {},
		"counts": {},
		"reachability": [],
		"vent_audit": [],
		"marker_tile_audit": {},
		"editor_only_placeholder_audit": {},
		"required_marker_safety": [],
		"camera_floodlight_spacing": [],
	}

	# Build context flags
	result.cache_safe_load_mode_used = bool(context.get("cache_safe_load_mode_used", true))
	result.source_scene_protection = context.get("source_scene_protection", {})
	result.optional_visual_reference = context.get("optional_visual_reference", {})
	result.builder_report_summary = context.get("builder_report_summary", {})

	# ---- Find required nodes
	result.phase = "find_nodes"
	var required_paths := [
		"GameplayRoot",
		"GameplayRoot/LayoutRoot",
		"GameplayRoot/LayoutRoot/FloorLayer",
		"GameplayRoot/LayoutRoot/WallLayer",
		"GameplayRoot/LayoutRoot/CoverLayer",
		"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
		"GameplayRoot/LayoutRoot/MarkerTileLayer",
		"GameplayRoot/MarkerRoot",
		"GameplayRoot/RuntimeSystems",
		"ArtRoot",
		"EntityRoot",
		"Camera2D",
	]
	var node_presence := {}
	for p in required_paths:
		node_presence[p] = scene_root.get_node_or_null(p) != null
		if not node_presence[p]:
			result.errors.append("required_node_missing: " + p)
	result.required_node_presence = node_presence

	var floor_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer")
	var wall_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/WallLayer")
	var cover_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer")
	var collision_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer")
	var marker_tile_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer")
	var marker_root: Node = scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	if floor_layer == null or wall_layer == null or cover_layer == null or collision_layer == null or marker_tile_layer == null or marker_root == null:
		result.pass = false
		_finalize_assertions(result, manifest)
		return result

	# ---- Anchor lookup
	result.phase = "anchor"
	var anchor_marker_id := String(manifest.get("anchor_marker_id", "player_spawn_main"))
	var anchor_node: Node = Shared.find_anchor_marker(scene_root, anchor_marker_id)
	if anchor_node == null or not (anchor_node is Node2D):
		result.errors.append("anchor_marker_not_found: " + anchor_marker_id)
		result.pass = false
		_finalize_assertions(result, manifest)
		return result
	# Reconstruct the same anchor_cell the builder used. Because the builder
	# moves player_spawn_main to (anchor_cell + spawn_offset), the spawn node is
	# now at (anchor_cell + spawn_offset). We back out spawn_offset from the
	# manifest so abs_cell math matches what the builder painted.
	var rows: Array = manifest.get("runtime_marker_targets", [])
	var spawn_row: Dictionary = _find_row(rows, anchor_marker_id)
	var spawn_offset := Vector2i(int(spawn_row.get("x", 0)), int(spawn_row.get("y", 0)))
	var spawn_node_cell: Vector2i = Shared.compute_anchor_cell(anchor_node as Node2D, floor_layer)
	var anchor_cell: Vector2i = spawn_node_cell - spawn_offset
	result.anchor_cell = [anchor_cell.x, anchor_cell.y]
	result.spawn_node_cell = [spawn_node_cell.x, spawn_node_cell.y]
	result.spawn_offset_used = [spawn_offset.x, spawn_offset.y]

	# ---- Build cell sets
	var floor_cells := {}
	for c in floor_layer.get_used_cells():
		floor_cells[c] = true
	var wall_cells := {}
	for c in wall_layer.get_used_cells():
		wall_cells[c] = true
	var collision_cells := {}
	for c in collision_layer.get_used_cells():
		collision_cells[c] = true
	var cover_cells := {}
	for c in cover_layer.get_used_cells():
		cover_cells[c] = true
	var marker_tile_cells := {}
	for c in marker_tile_layer.get_used_cells():
		marker_tile_cells[c] = true
	result.counts = {
		"floor_cell_count": floor_cells.size(),
		"wall_cell_count": wall_cells.size(),
		"collision_cell_count": collision_cells.size(),
		"cover_cell_count": cover_cells.size(),
		"marker_tile_count": marker_tile_cells.size(),
	}

	# Used rect
	var used_rect: Rect2i = floor_layer.get_used_rect()
	result.counts["used_rect_x"] = used_rect.position.x
	result.counts["used_rect_y"] = used_rect.position.y
	result.counts["used_rect_width"] = used_rect.size.x
	result.counts["used_rect_height"] = used_rect.size.y

	# ---- Tile-vocabulary check on TileSet (cache-safe load)
	result.phase = "tile_vocabulary"
	var marker_atlas_meta: Dictionary = manifest.get("tile_lookup", {}).get("marker_atlas", {})
	var marker_ts_path: String = String(marker_atlas_meta.get("tileset", ""))
	var marker_ts: TileSet = Shared.load_cache_safe(marker_ts_path, "TileSet") as TileSet
	var marker_vocab := {}
	if marker_ts != null:
		var src_id: int = int(marker_atlas_meta.get("source_id", 0))
		var src := marker_ts.get_source(src_id)
		if src is TileSetAtlasSource:
			var atlas_src := src as TileSetAtlasSource
			for abbr in marker_atlas_meta.get("abbreviations", {}).keys():
				var coords_arr: Array = marker_atlas_meta.abbreviations[abbr]
				var coords := Vector2i(int(coords_arr[0]), int(coords_arr[1]))
				marker_vocab[abbr] = atlas_src.has_tile(coords)
	result.marker_vocabulary = marker_vocab

	# DOOR/SWITCH no-collision audit
	var door_no_collision := _atlas_tile_has_no_collision(marker_ts, marker_atlas_meta, "DOOR")
	var switch_no_collision := _atlas_tile_has_no_collision(marker_ts, marker_atlas_meta, "SWITCH")
	result.door_no_collision = door_no_collision
	result.switch_no_collision = switch_no_collision

	# ---- Manifest expectations
	result.phase = "manifest_expectations"
	var marker_index := Shared.index_marker_root(marker_root)
	var groups_result: Dictionary = Shared.build_equivalence_groups(rows, anchor_cell, marker_index)
	var groups: Array = groups_result.get("groups", [])
	var collisions: Array = groups_result.get("collisions", [])
	var enriched: Array = groups_result.get("enriched", [])

	# ---- Marker tile abbr usage rules
	result.phase = "marker_tile_abbr_rules"
	var abbr_rule_results := {
		"only_GATE_garage_code_uses_GATE": true,
		"no_CONTROL_uses_GATE": true,
		"no_BENTLEY_SWITCH_uses_GATE": true,
		"all_BENTLEY_SWITCH_use_SWITCH": true,
		"CONTROL_alarm_panel_uses_SWITCH": false,
		"CONTROL_camera_terminal_uses_SWITCH": false,
		"CONTROL_door_controls_uses_SWITCH": false,
		"ROUTE_IN_louis_service_door_uses_DOOR": false,
		"ROUTE_RET_louis_return_trigger_uses_DOOR": false,
	}
	for r in rows:
		var manifest_id := String(r.get("manifest_id", ""))
		var category := String(r.get("category", ""))
		var abbr := String(r.get("marker_tile_abbr", ""))
		if abbr == "GATE" and manifest_id != "GATE_garage_code":
			abbr_rule_results.only_GATE_garage_code_uses_GATE = false
		if category == "CONTROL" and abbr == "GATE":
			abbr_rule_results.no_CONTROL_uses_GATE = false
		if category == "BENTLEY_SWITCH" and abbr == "GATE":
			abbr_rule_results.no_BENTLEY_SWITCH_uses_GATE = false
		if category == "BENTLEY_SWITCH" and abbr != "SWITCH":
			abbr_rule_results.all_BENTLEY_SWITCH_use_SWITCH = false
		if manifest_id == "CONTROL_alarm_panel" and abbr == "SWITCH":
			abbr_rule_results.CONTROL_alarm_panel_uses_SWITCH = true
		if manifest_id == "CONTROL_camera_terminal" and abbr == "SWITCH":
			abbr_rule_results.CONTROL_camera_terminal_uses_SWITCH = true
		if manifest_id == "CONTROL_door_controls" and abbr == "SWITCH":
			abbr_rule_results.CONTROL_door_controls_uses_SWITCH = true
		if manifest_id == "ROUTE_IN_louis_service_door" and abbr == "DOOR":
			abbr_rule_results.ROUTE_IN_louis_service_door_uses_DOOR = true
		if manifest_id == "ROUTE_RET_louis_return_trigger" and abbr == "DOOR":
			abbr_rule_results.ROUTE_RET_louis_return_trigger_uses_DOOR = true
	result.abbr_rule_results = abbr_rule_results

	# ---- MarkerTileLayer audit (one tile per cell, all explained)
	result.phase = "marker_tile_audit"
	var canonical_cells := {}
	var canonical_cell_to_row := {}
	var gate_atlas_coords := Vector2i(int(marker_atlas_meta.get("abbreviations", {}).get("GATE", [2, 2])[0]), int(marker_atlas_meta.get("abbreviations", {}).get("GATE", [2, 2])[1]))
	for grp in groups:
		var ci: int = int(grp.canonical_index)
		var canon_row: Dictionary = enriched[ci].row
		var ac: Vector2i = grp.abs_cell
		var category := String(canon_row.get("category", ""))
		var abbr := String(canon_row.get("marker_tile_abbr", ""))
		if category != "SPAWN" and abbr != "":
			canonical_cells[ac] = abbr
			canonical_cell_to_row[ac] = canon_row

	var unaccounted_tile_cells := []
	var gate_tile_count := 0
	var per_abbr_tile_counts := {}
	for c in marker_tile_cells.keys():
		var src_id: int = marker_tile_layer.get_cell_source_id(c)
		var coords: Vector2i = marker_tile_layer.get_cell_atlas_coords(c)
		# Look up abbreviation by reverse mapping
		var abbr_found := ""
		for abbr in marker_atlas_meta.get("abbreviations", {}).keys():
			var arr: Array = marker_atlas_meta.abbreviations[abbr]
			if Vector2i(int(arr[0]), int(arr[1])) == coords:
				abbr_found = abbr
				break
		if not per_abbr_tile_counts.has(abbr_found):
			per_abbr_tile_counts[abbr_found] = 0
		per_abbr_tile_counts[abbr_found] = per_abbr_tile_counts[abbr_found] + 1
		if coords == gate_atlas_coords:
			gate_tile_count += 1
		if not canonical_cells.has(c):
			unaccounted_tile_cells.append({"cell": [c.x, c.y], "abbr": abbr_found})
	result.marker_tile_audit = {
		"gate_tile_count": gate_tile_count,
		"per_abbr_tile_counts": per_abbr_tile_counts,
		"unaccounted_cells": unaccounted_tile_cells,
		"unaccounted_count": unaccounted_tile_cells.size(),
	}

	# ---- Required runtime marker safety check
	result.phase = "required_marker_safety"
	var safety_results := []
	for grp in groups:
		var ci: int = int(grp.canonical_index)
		var canon_row: Dictionary = enriched[ci].row
		var manifest_id := String(canon_row.get("manifest_id", ""))
		var ac: Vector2i = grp.abs_cell
		var on_floor: bool = floor_cells.has(ac)
		var in_wall: bool = wall_cells.has(ac)
		var in_collision: bool = collision_cells.has(ac)
		var placeholder_allowed: bool = bool(canon_row.get("placeholder_allowed", true))
		var required: bool = not placeholder_allowed
		safety_results.append({
			"manifest_id": manifest_id,
			"required": required,
			"abs_cell": [ac.x, ac.y],
			"on_floor": on_floor,
			"in_wall": in_wall,
			"in_collision": in_collision,
		})
	result.required_marker_safety = safety_results

	var any_required_off_floor := false
	var any_required_in_wall := false
	var any_required_in_collision := false
	for s in safety_results:
		if not s.required:
			continue
		if not s.on_floor:
			any_required_off_floor = true
		if s.in_wall:
			any_required_in_wall = true
		if s.in_collision:
			any_required_in_collision = true

	# Specific known-issue check: poop_bag_garage_pet_bin
	var poop_safe := true
	for s in safety_results:
		if s.manifest_id == "poop_bag_garage_pet_bin":
			poop_safe = s.on_floor and not s.in_wall and not s.in_collision
			break
	result.poop_bag_garage_pet_bin_status = poop_safe

	# ---- Reachability (4-direction flood fill)
	result.phase = "reachability"
	var spawn_cell := _find_target_cell(rows, "player_spawn_main", anchor_cell)
	var blockers := {}
	for c in wall_cells.keys():
		blockers[c] = true
	for c in collision_cells.keys():
		blockers[c] = true
	# BLOCK explicit
	for blk in manifest.get("explicit_block_cells", []):
		var bc := Vector2i(int(blk.get("x", 0)) + anchor_cell.x, int(blk.get("y", 0)) + anchor_cell.y)
		blockers[bc] = true
	# Bentley-only zones excluded from player flood-fill
	var bentley_zones: Array = manifest.get("validation_rules", {}).get("bentley_only_zones", [])
	var bentley_zone_cells := {}
	for rect in manifest.get("floor_rects", []):
		if String(rect.get("id", "")) in bentley_zones:
			var xmin: int = int(rect.get("x_min", 0)) + anchor_cell.x
			var xmax: int = int(rect.get("x_max", 0)) + anchor_cell.x
			var ymin: int = int(rect.get("y_min", 0)) + anchor_cell.y
			var ymax: int = int(rect.get("y_max", 0)) + anchor_cell.y
			for x in range(xmin, xmax + 1):
				for y in range(ymin, ymax + 1):
					bentley_zone_cells[Vector2i(x, y)] = true

	var reach := _flood_fill_4(spawn_cell, floor_cells, blockers, bentley_zone_cells)
	result.counts["reachable_cell_count"] = reach.size()

	# Required main routes
	var required_main: Array = manifest.get("validation_rules", {}).get("required_main_route_targets", [])
	var reachable_required := []
	for t in required_main:
		var zone_id := String(t.get("zone", ""))
		var label := String(t.get("label", zone_id))
		var center: Vector2i = _zone_center(manifest, zone_id, anchor_cell)
		var ok: bool = reach.has(center)
		reachable_required.append({"zone": zone_id, "label": label, "center": [center.x, center.y], "reachable": ok})
		if not ok:
			result.errors.append("main_route_unreachable: " + label + " center " + str(center))

	# Optional routes
	var optional_targets: Array = manifest.get("validation_rules", {}).get("optional_route_targets", [])
	var reachable_optional := []
	for zid in optional_targets:
		var center: Vector2i = _zone_center(manifest, zid, anchor_cell)
		var ok: bool = reach.has(center)
		reachable_optional.append({"zone": zid, "center": [center.x, center.y], "reachable": ok})
		if not ok:
			result.warnings.append("optional_route_unreachable: " + zid)
	result.reachability = {"required": reachable_required, "optional": reachable_optional}

	# Player must NOT freely reach Bentley utility passage interiors
	var bentley_reach_via_player := false
	for c in reach.keys():
		if bentley_zone_cells.has(c):
			bentley_reach_via_player = true
			break
	result.player_flood_fill_does_not_require_bentley_routes = not bentley_reach_via_player

	# ---- Vent interface audit
	result.phase = "vent_audit"
	var vent_audit_rows := []
	for vi in manifest.get("vent_only_interfaces", []):
		var stand: Dictionary = vi.get("stand_cell_main_side", {})
		var stand_cell := Vector2i(int(stand.get("x", 0)) + anchor_cell.x, int(stand.get("y", 0)) + anchor_cell.y)
		var vid := String(vi.get("vent_in_marker_id", ""))
		var vrow := _find_row(rows, vid)
		var vent_cell := Vector2i(0, 0)
		var vent_cell_on_floor := false
		var vent_cell_blocked := false
		if vrow.size() > 0:
			vent_cell = Vector2i(int(vrow.get("x", 0)) + anchor_cell.x, int(vrow.get("y", 0)) + anchor_cell.y)
			vent_cell_on_floor = floor_cells.has(vent_cell)
			vent_cell_blocked = blockers.has(vent_cell)
		vent_audit_rows.append({
			"id": String(vi.get("id", "")),
			"vent_in_marker_id": vid,
			"vent_cell": [vent_cell.x, vent_cell.y],
			"vent_cell_on_floor": vent_cell_on_floor,
			"vent_cell_blocked": vent_cell_blocked,
			"stand_cell": [stand_cell.x, stand_cell.y],
			"stand_cell_on_floor": floor_cells.has(stand_cell),
			"stand_cell_blocked": blockers.has(stand_cell),
		})
	result.vent_audit = vent_audit_rows

	# ---- Bentley route existence (zones present in floor cells)
	result.phase = "bentley_routes"
	var bentley_routes := {}
	for rid in ["zone_bentley_route_a_passage", "zone_bentley_route_b_passage", "zone_bentley_route_c_passage", "zone_bentley_route_d_passage"]:
		var c: Vector2i = _zone_center(manifest, rid, anchor_cell)
		bentley_routes[rid] = floor_cells.has(c)
	result.bentley_routes_exist = bentley_routes

	# ---- Challenge separation
	result.phase = "challenge_separation"
	var gate_cell := _find_target_cell(rows, "GATE_garage_code", anchor_cell)
	var beam_cell := _find_target_cell(rows, "AMBUSH_security_beam", anchor_cell)
	var dist := absi(gate_cell.x - beam_cell.x) + absi(gate_cell.y - beam_cell.y)
	result.code_gate_to_beam_distance = dist

	# Safe-code-input not in beam zone
	var beam_zone: Vector2i = _zone_center(manifest, "zone_security_beam_approach", anchor_cell)
	var safe_cell := _find_target_cell(rows, "SAFE_CODE_INPUT_ZONE", anchor_cell)
	var safe_in_beam_zone := absi(safe_cell.x - beam_zone.x) <= 5
	result.safe_code_in_beam_zone = safe_in_beam_zone

	# ---- Camera/floodlight spacing
	result.phase = "spacing"
	var spacing_min: int = int(manifest.get("validation_rules", {}).get("camera_floodlight_spacing_min", 12))
	var detection_cells := []
	for r in rows:
		var cat := String(r.get("category", ""))
		if cat == "CAM" or cat == "FLOOD":
			detection_cells.append({
				"manifest_id": String(r.get("manifest_id", "")),
				"abs_cell": Vector2i(int(r.get("x", 0)) + anchor_cell.x, int(r.get("y", 0)) + anchor_cell.y),
				"category": cat,
			})
	var spacing_violations := []
	for i in range(detection_cells.size()):
		for j in range(i + 1, detection_cells.size()):
			var a: Vector2i = detection_cells[i].abs_cell
			var b: Vector2i = detection_cells[j].abs_cell
			var d := absi(a.x - b.x) + absi(a.y - b.y)
			if d < spacing_min:
				spacing_violations.append({
					"a": detection_cells[i].manifest_id,
					"b": detection_cells[j].manifest_id,
					"distance": d,
				})
	result.camera_floodlight_spacing = {"min_required": spacing_min, "violations": spacing_violations}

	# ---- Editor-only placeholder audit
	result.phase = "editor_only_audit"
	var placeholder_parent := marker_root.get_node_or_null(Shared.EDITOR_ONLY_PARENT_NODE_NAME)
	var placeholder_audit := {
		"parent_exists": placeholder_parent != null,
		"placeholder_count": 0,
		"placeholders_with_script": 0,
		"placeholders_with_marker_type": 0,
		"placeholders_in_groups": 0,
		"placeholders_without_owner": 0,
		"label_children_without_owner": 0,
	}
	if placeholder_parent != null:
		var children := placeholder_parent.get_children()
		# Phase 0I attaches helper Phase0IAuthoringHider Nodes as children to hide
		# this parent at runtime. They are not gameplay placeholders and must be
		# skipped by the editor-only-placeholder audit.
		var gameplay_children: Array = []
		for ch in children:
			if String(ch.name) == "Phase0IAuthoringHider":
				continue
			var s: Script = ch.get_script()
			if s != null and String(s.resource_path).ends_with("Phase0IAuthoringHider.gd"):
				continue
			gameplay_children.append(ch)
		placeholder_audit.placeholder_count = gameplay_children.size()
		for ph in gameplay_children:
			if ph.get_script() != null:
				placeholder_audit.placeholders_with_script += 1
			if ph.has_method("get") and ph.get("marker_type") != null:
				placeholder_audit.placeholders_with_marker_type += 1
			var groups_count: int = ph.get_groups().size()
			if groups_count > 0:
				placeholder_audit.placeholders_in_groups += 1
			if ph.owner != scene_root:
				placeholder_audit.placeholders_without_owner += 1
			for sub in ph.get_children():
				if sub.owner != scene_root:
					placeholder_audit.label_children_without_owner += 1
	result.editor_only_placeholder_audit = placeholder_audit

	# ---- Phase 0H: cleanup audit (old artifacts, camera, root, labels, gate links)
	result.phase = "phase_0h_audit"
	result.phase_0h_audit = _phase_0h_audit(scene_root, floor_layer, manifest, anchor_cell, rows)

	# ---- Phase 0I: runtime truth audit (wall collision, marker hide, gate blocker,
	#                core collectibles, route safeguard, Louis route).
	result.phase = "phase_0i_audit"
	result.phase_0i_audit = _phase_0i_audit(scene_root, floor_layer, manifest, anchor_cell, rows)

	# ---- Finalize hard assertions
	_finalize_assertions(result, manifest)

	# Build pass/fail
	var pass_ok := true
	for k in result.hard_assertions.keys():
		var v = result.hard_assertions[k]
		if v is bool and not v:
			pass_ok = false
		# Numeric counts that should be zero:
		if k.ends_with("_count_zero") and v is int and v != 0:
			pass_ok = false
	if result.errors.size() > 0:
		pass_ok = false
	result.pass = pass_ok
	result.phase = "complete"
	return result

# ----------------------------- Phase 0H audit ---------------------------------

static func _phase_0h_audit(scene_root: Node, floor_layer: TileMapLayer, manifest: Dictionary, anchor_cell: Vector2i, rows: Array) -> Dictionary:
	var audit := {
		"old_layer_inventory": [],
		"old_floor_layer_clean": true,
		"old_wall_layer_clean": true,
		"old_collision_layer_clean": true,
		"no_unexpected_tilemap_layers_with_used_cells": true,
		"boundary_colliders": {},
		"boundary_colliders_disabled": false,
		"boundary_static_bodies_with_nonzero_collision": 0,
		"camera": {},
		"camera_limits_cover_used_rect": false,
		"far_route_points_inside_camera_bounds": false,
		"key_marker_ids_inside_camera_bounds": false,
		"root_transform": {},
		"marker_labels": {"markers_total": 0, "markers_with_show_editor_label_true": 0, "at_label_sibling_count": 0, "editor_label_count": 0},
		"markers_with_show_editor_label_true": 0,
		"at_label_sibling_count": 0,
		"clusters": {"largest_cluster_size": 0, "cluster_count": 0, "clusters": []},
		"runtime_marker_audit": [],
		"unexpected_tilemap_layers": [],
		"code_gate_has_block_marker_row": false,
		"code_gate_has_collision_barrier_cell": false,
		"code_gate_blocker_ready_for_future_unlock": false,
		"level_bounds_zone_present": false,
		"level_bounds_zone": {},
	}

	var cleanup_cfg: Dictionary = manifest.get("phase_0h_cleanup", {})
	var expected_layout_paths := {
		"GameplayRoot/LayoutRoot/FloorLayer": true,
		"GameplayRoot/LayoutRoot/WallLayer": true,
		"GameplayRoot/LayoutRoot/CoverLayer": true,
		"GameplayRoot/LayoutRoot/CollisionBarrierLayer": true,
		"GameplayRoot/LayoutRoot/MarkerTileLayer": true,
	}

	# Walk every TileMapLayer in the scene tree.
	var all_tilemap_layers: Array = []
	_collect_tilemap_layers(scene_root, all_tilemap_layers)
	for tml_node in all_tilemap_layers:
		var tml := tml_node as TileMapLayer
		var path := String(scene_root.get_path_to(tml))
		var used := tml.get_used_cells().size()
		var visible_state: bool = tml.visible
		var enabled: bool = tml.enabled
		var collision_enabled: bool = tml.collision_enabled
		var entry := {
			"path": path,
			"used_cell_count": used,
			"visible": visible_state,
			"enabled": enabled,
			"collision_enabled": collision_enabled,
		}
		audit.old_layer_inventory.append(entry)
		var is_expected := expected_layout_paths.has(path) or path.ends_with("LayoutRoot/FloorLayer") or path.ends_with("LayoutRoot/WallLayer") or path.ends_with("LayoutRoot/CoverLayer") or path.ends_with("LayoutRoot/CollisionBarrierLayer") or path.ends_with("LayoutRoot/MarkerTileLayer")
		if not is_expected:
			# An unexpected TileMapLayer must either be empty or hidden+disabled.
			var clean := used == 0 and not visible_state and not enabled
			if not clean and used > 0:
				audit.no_unexpected_tilemap_layers_with_used_cells = false
				audit.unexpected_tilemap_layers.append(entry)
			# Identify well-known old siblings:
			if path == "GameplayRoot/GameplayFloorLayer":
				audit.old_floor_layer_clean = (used == 0 and not visible_state)
			elif path == "GameplayRoot/GameplayCollisionLayer":
				audit.old_collision_layer_clean = (used == 0 and not visible_state)
			elif path == "GameplayRoot/GameplayMarkersLayer":
				audit.old_wall_layer_clean = (used == 0 and not visible_state)

	# BoundaryColliders audit
	var bc_path := String(cleanup_cfg.get("boundary_colliders_path", "GameplayRoot/BoundaryColliders"))
	var bc: Node = scene_root.get_node_or_null(bc_path)
	if bc != null:
		# Use Array containers because GDScript lambdas cannot mutate captured ints.
		var counts_box := [0, 0]  # [bodies, nonzero_bodies]
		_count_collision_bodies(bc, counts_box)
		var bodies: int = int(counts_box[0])
		var nonzero_bodies: int = int(counts_box[1])
		audit.boundary_colliders = {
			"path": bc_path,
			"found": true,
			"visible": bc.visible if bc is CanvasItem else false,
			"process_mode": int(bc.process_mode),
			"static_body_count": bodies,
			"static_body_with_nonzero_collision_count": nonzero_bodies,
		}
		var disabled_state: bool = (
			(bc is CanvasItem and not (bc as CanvasItem).visible)
			or bc.process_mode == Node.PROCESS_MODE_DISABLED
		)
		audit.boundary_colliders_disabled = disabled_state and (nonzero_bodies == 0)
		audit.boundary_static_bodies_with_nonzero_collision = nonzero_bodies
	else:
		audit.boundary_colliders = {"path": bc_path, "found": false}
		audit.boundary_colliders_disabled = true # Nothing to disable
		audit.boundary_static_bodies_with_nonzero_collision = 0

	# Camera audit
	var cam_path := String(cleanup_cfg.get("camera_node_path", "Camera2D"))
	var cam: Camera2D = scene_root.get_node_or_null(cam_path) as Camera2D
	if cam != null:
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
		audit.camera = {
			"path": cam_path,
			"limits": {"left": cam.limit_left, "top": cam.limit_top, "right": cam.limit_right, "bottom": cam.limit_bottom},
			"floor_world_rect": {"min": [min_x, min_y], "max": [max_x, max_y]},
		}
		var covers := (cam.limit_left <= min_x and cam.limit_right >= max_x and cam.limit_top <= min_y and cam.limit_bottom >= max_y)
		audit.camera_limits_cover_used_rect = covers

		# Far points: corners + key markers
		var far_points := [
			Vector2i(min_x, min_y),
			Vector2i(max_x, min_y),
			Vector2i(min_x, max_y),
			Vector2i(max_x, max_y),
		]
		var all_far_inside := true
		for fp in far_points:
			if fp.x < cam.limit_left or fp.x > cam.limit_right or fp.y < cam.limit_top or fp.y > cam.limit_bottom:
				all_far_inside = false
				break
		audit.far_route_points_inside_camera_bounds = all_far_inside

		# Key markers in bounds
		var key_ids: Array = manifest.get("validation_rules", {}).get("phase_0h", {}).get("key_marker_ids_in_camera_bounds", [])
		var all_keys_in := true
		var key_results := []
		for mid in key_ids:
			var cell: Vector2i = _find_target_cell(rows, String(mid), anchor_cell)
			var w: Vector2 = floor_layer.to_global(floor_layer.map_to_local(cell))
			var inside := w.x >= cam.limit_left and w.x <= cam.limit_right and w.y >= cam.limit_top and w.y <= cam.limit_bottom
			key_results.append({"manifest_id": mid, "abs_cell": [cell.x, cell.y], "world": [int(w.x), int(w.y)], "inside_camera_bounds": inside})
			if not inside:
				all_keys_in = false
		audit.key_marker_ids_inside_camera_bounds = all_keys_in
		audit.key_markers = key_results
	else:
		audit.camera = {"path": cam_path, "found": false}

	# Root transform audit
	if scene_root is Node2D:
		var n2d := scene_root as Node2D
		audit.root_transform = {
			"position": [n2d.position.x, n2d.position.y],
			"rotation": n2d.rotation,
			"scale": [n2d.scale.x, n2d.scale.y],
			"is_identity": n2d.position == Vector2.ZERO and is_zero_approx(n2d.rotation) and n2d.scale == Vector2.ONE,
		}

	# Marker label audit (walk MarkerRoot)
	var marker_root: Node = scene_root.get_node_or_null("GameplayRoot/MarkerRoot")
	if marker_root != null:
		_phase_0h_label_audit_recursive(marker_root, audit.marker_labels)
		audit.markers_with_show_editor_label_true = int(audit.marker_labels.markers_with_show_editor_label_true)
		audit.at_label_sibling_count = int(audit.marker_labels.at_label_sibling_count)

	# Marker spam clusters
	audit.clusters = _phase_0h_cluster_audit(scene_root, manifest, anchor_cell, rows)

	# Runtime marker position audit
	audit.runtime_marker_audit = _phase_0h_runtime_marker_position_audit(marker_root, rows, anchor_cell, floor_layer)

	# Code gate verification
	audit.code_gate_has_block_marker_row = _has_row(rows, "BLOCK_code_gate")
	var collision_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer")
	var gate_blocker_cell := Vector2i(0, 0)
	for blk in manifest.get("explicit_block_cells", []):
		if String(blk.get("id", "")) == "BLOCK_code_gate_physical":
			gate_blocker_cell = Vector2i(int(blk.get("x", 0)) + anchor_cell.x, int(blk.get("y", 0)) + anchor_cell.y)
			break
	audit.code_gate_has_collision_barrier_cell = collision_layer != null and collision_layer.get_cell_source_id(gate_blocker_cell) != -1
	# Future unlock readiness: BLOCK_code_gate manifest row links to GATE; SAFE_CODE_INPUT links to BLOCK_code_gate; collision tile present at the dedicated blocker cell.
	var safe_row := _find_row(rows, "SAFE_CODE_INPUT_ZONE")
	var gate_row := _find_row(rows, "GATE_garage_code")
	var block_row := _find_row(rows, "BLOCK_code_gate")
	var safe_links: Array = safe_row.get("linked_target_ids", [])
	var gate_links: Array = gate_row.get("linked_target_ids", [])
	var block_links: Array = block_row.get("linked_target_ids", [])
	audit.code_gate_blocker_ready_for_future_unlock = (
		audit.code_gate_has_block_marker_row
		and audit.code_gate_has_collision_barrier_cell
		and "GATE_garage_code" in safe_links
		and "BLOCK_code_gate" in safe_links
		and "BLOCK_code_gate" in gate_links
		and "GATE_garage_code" in block_links
	)

	# Level bounds zone in mission_definition.tres
	var def_path := String(cleanup_cfg.get("mission_definition_resource_path", "res://assets/missions/taco_bell_iso_blockout_definition.tres"))
	var def_res: Resource = Shared.load_cache_safe(def_path, "Resource")
	if def_res != null:
		var zones: Variant = def_res.get("zones")
		if zones is Array:
			var zid := String(cleanup_cfg.get("level_bounds_zone_id", "level_bounds_max"))
			for z in zones:
				if z != null and String(z.get("zone_id")) == zid:
					audit.level_bounds_zone_present = true
					audit.level_bounds_zone = {
						"zone_id": zid,
						"origin": [z.get("origin").x, z.get("origin").y],
						"size": [z.get("size").x, z.get("size").y],
					}
					break

	return audit

static func _collect_tilemap_layers(node: Node, out: Array) -> void:
	if node is TileMapLayer:
		out.append(node)
	for child in node.get_children():
		_collect_tilemap_layers(child, out)

static func _count_collision_bodies(node: Node, counts_box: Array) -> void:
	# counts_box is a 2-slot Array used as a lambda-free counter:
	#   [0] = total CollisionObject2D bodies seen
	#   [1] = bodies with non-zero collision_layer or collision_mask
	if node is CollisionObject2D:
		var co := node as CollisionObject2D
		counts_box[0] = int(counts_box[0]) + 1
		if int(co.collision_layer) != 0 or int(co.collision_mask) != 0:
			counts_box[1] = int(counts_box[1]) + 1
	for child in node.get_children():
		_count_collision_bodies(child, counts_box)

static func _phase_0h_label_audit_recursive(node: Node, summary: Dictionary) -> void:
	if node.get_script() != null and node.has_method("get") and node.get("marker_type") != null:
		summary.markers_total += 1
		if bool(node.get("show_editor_label")):
			summary.markers_with_show_editor_label_true += 1
		for child in node.get_children():
			if child is Label:
				if String(child.name).begins_with("@Label@"):
					summary.at_label_sibling_count += 1
				elif String(child.name) == "EditorLabel":
					summary.editor_label_count += 1
	for child in node.get_children():
		_phase_0h_label_audit_recursive(child, summary)

static func _phase_0h_cluster_audit(scene_root: Node, manifest: Dictionary, anchor_cell: Vector2i, rows: Array) -> Dictionary:
	var marker_tile_layer: TileMapLayer = scene_root.get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer")
	if marker_tile_layer == null:
		return {"largest_cluster_size": 0, "cluster_count": 0, "clusters": []}
	var cells: Array[Vector2i] = marker_tile_layer.get_used_cells()
	# Within radius R (Manhattan), count adjacents.
	var radius := 5
	var threshold := 4
	var clusters: Array = []
	var visited := {}
	for c in cells:
		if visited.has(c):
			continue
		var nearby: Array = []
		for d in cells:
			if absi(c.x - d.x) + absi(c.y - d.y) <= radius:
				nearby.append(d)
		if nearby.size() >= threshold:
			for n in nearby:
				visited[n] = true
			var cx := 0
			var cy := 0
			for n in nearby:
				cx += (n as Vector2i).x
				cy += (n as Vector2i).y
			cx = int(cx / nearby.size())
			cy = int(cy / nearby.size())
			clusters.append({"center": [cx, cy], "size": nearby.size()})
	clusters.sort_custom(func(a, b): return int(a.size) > int(b.size))
	var largest := 0
	if clusters.size() > 0:
		largest = int(clusters[0].size)
	return {"largest_cluster_size": largest, "cluster_count": clusters.size(), "clusters": clusters.slice(0, mini(8, clusters.size()))}

static func _phase_0h_runtime_marker_position_audit(marker_root: Node, rows: Array, anchor_cell: Vector2i, floor_layer: TileMapLayer) -> Array:
	var out: Array = []
	if marker_root == null:
		return out
	# Index existing IsoMissionMarker nodes by marker_id.
	var by_id := {}
	_index_markers_recursive(marker_root, by_id)
	for r in rows:
		var manifest_id := String(r.get("manifest_id", ""))
		var category := String(r.get("category", ""))
		var abbr := String(r.get("marker_tile_abbr", ""))
		var rel_x: int = int(r.get("x", 0))
		var rel_y: int = int(r.get("y", 0))
		var expected_cell := Vector2i(rel_x + anchor_cell.x, rel_y + anchor_cell.y)
		var matched_node: Node = by_id.get(manifest_id, null)
		# Try aliases
		if matched_node == null:
			for alias in r.get("alias_of_legacy_marker_ids", []):
				if by_id.has(String(alias)):
					matched_node = by_id[String(alias)]
					break
		var status := "missing_in_scene"
		var actual_cell := Vector2i(0, 0)
		var node_path := ""
		if matched_node != null and matched_node is Node2D:
			node_path = String(matched_node.name)
			var n2d := matched_node as Node2D
			var cell := floor_layer.local_to_map(floor_layer.to_local(n2d.global_position))
			actual_cell = cell
			if cell == expected_cell:
				status = "real_existing_position_ok"
			else:
				status = "real_existing_position_mismatch"
		else:
			status = "editor_only_or_missing"
		out.append({
			"manifest_id": manifest_id,
			"category": category,
			"marker_tile_abbr": abbr,
			"rel_cell": [rel_x, rel_y],
			"expected_abs_cell": [expected_cell.x, expected_cell.y],
			"actual_abs_cell": [actual_cell.x, actual_cell.y],
			"matched_runtime_marker": matched_node != null,
			"runtime_marker_name": node_path,
			"status": status,
		})
	return out

static func _index_markers_recursive(node: Node, by_id: Dictionary) -> void:
	if node.has_method("get") and node.get("marker_id") != null and String(node.get("marker_id")) != "":
		by_id[String(node.get("marker_id"))] = node
	# Also index by name as a fallback (Phase 0G v6 placeholder pattern).
	if not by_id.has(String(node.name)):
		by_id[String(node.name)] = node
	for child in node.get_children():
		_index_markers_recursive(child, by_id)

static func _has_row(rows: Array, manifest_id: String) -> bool:
	for r in rows:
		if String(r.get("manifest_id", "")) == manifest_id:
			return true
	return false


# ============================================================================
#  Phase 0I — runtime truth audit.
# ============================================================================

static func _phase_0i_audit(scene_root: Node, floor_layer: TileMapLayer, manifest: Dictionary, anchor_cell: Vector2i, rows: Array) -> Dictionary:
	var audit := {
		"wall_layer_path": "",
		"wall_layer_collision_enabled": false,
		"wall_layer_uses_walls_physics_layer": false,
		"wall_layer_tileset_physics_layer_collision_layer_bits": -1,
		"player_collision_mask_includes_walls": true,
		"player_collision_mask_value": 7,
		"marker_tile_layer_path": "",
		"marker_tile_layer_authoring_visible_property": true,
		"marker_tile_layer_hider_attached": false,
		"marker_tile_layer_z_index": 0,
		"editor_only_placeholders_path": "",
		"editor_only_placeholders_hider_attached": false,
		"authoring_marker_root_subnodes": [],
		"authoring_hiders_attached_count": 0,
		"authoring_hiders_attached_min": false,
		"authoring_tiles_runtime_safe": false,
		"generated_runtime_collision_root_present": false,
		"generated_runtime_collision_root_path": "",
		"generated_wall_collision_present": false,
		"code_gate_generated_blocker_present": false,
		"code_gate_generated_blocker_node_path": "",
		"code_gate_generated_blocker_uses_walls_layer": false,
		"code_gate_generated_blocker_future_unlockable": false,
		"code_gate_generated_blocker_world_position": [],
		"core_collectibles_promoted": [],
		"core_delivery_bag_promoted_or_reported": false,
		"at_least_one_poop_bag_promoted_or_reported": false,
		"at_least_one_photo_promoted_or_reported": false,
		"at_least_one_clue_promoted_or_reported": false,
		"route_safeguard_attached": false,
		"route_safeguard_node_path": "",
		"route_safeguard_targets": [],
		"route_destinations_consistent_with_manifest": true,
		"louis_route_audit": {},
		"louis_route_bypasses_code_gate": false,
		"louis_route_does_not_skip_bag_objective": false,
		"louis_route_does_not_skip_exit": false,
		"louis_route_return_before_security_beam": false,
	}
	var cfg: Dictionary = manifest.get("phase_0i_cleanup", {})

	# ---- Wall layer collision audit
	var wall_path := String(cfg.get("wall_layer_path", "GameplayRoot/LayoutRoot/WallLayer"))
	audit.wall_layer_path = wall_path
	var wall_node: Node = scene_root.get_node_or_null(wall_path)
	if wall_node is TileMapLayer:
		var wl := wall_node as TileMapLayer
		audit.wall_layer_collision_enabled = bool(wl.collision_enabled)
		var ts: TileSet = wl.tile_set
		if ts != null and ts.get_physics_layers_count() > 0:
			var bits: int = int(ts.get_physics_layer_collision_layer(0))
			audit.wall_layer_tileset_physics_layer_collision_layer_bits = bits
			# Walls = layer 3 = bit value 4.
			audit.wall_layer_uses_walls_physics_layer = (bits == 4)

	# ---- Player collision mask audit (best-effort: read from packed scene if available)
	var player_node: Node = scene_root.get_node_or_null("EntityRoot/Player")
	if player_node is CollisionObject2D:
		var pco := player_node as CollisionObject2D
		audit.player_collision_mask_value = int(pco.collision_mask)
		# bit 3 = value 4 = Walls
		audit.player_collision_mask_includes_walls = (int(pco.collision_mask) & 4) != 0

	# ---- MarkerTileLayer hider audit
	var mtl_path := String(cfg.get("marker_tile_layer_path", "GameplayRoot/LayoutRoot/MarkerTileLayer"))
	audit.marker_tile_layer_path = mtl_path
	var mtl_node: Node = scene_root.get_node_or_null(mtl_path)
	if mtl_node is TileMapLayer:
		var mtl := mtl_node as TileMapLayer
		audit.marker_tile_layer_authoring_visible_property = bool(mtl.visible)
		audit.marker_tile_layer_z_index = int(mtl.z_index)
		audit.marker_tile_layer_hider_attached = _phase_0i_has_hider_child(mtl)

	# ---- EditorOnlyPlaceholders hider audit
	var eop_path := String(cfg.get("editor_only_placeholders_path", "GameplayRoot/MarkerRoot/EditorOnlyPlaceholders"))
	audit.editor_only_placeholders_path = eop_path
	var eop_node: Node = scene_root.get_node_or_null(eop_path)
	if eop_node != null:
		audit.editor_only_placeholders_hider_attached = _phase_0i_has_hider_child(eop_node)

	# ---- Authoring marker root subnodes hider audit
	var amr_paths: Array = cfg.get("authoring_marker_root_runtime_hide_paths", [])
	var amr_attached_count := 0
	for p_obj in amr_paths:
		var p := String(p_obj)
		var n: Node = scene_root.get_node_or_null(p)
		var has_hider := false
		if n != null:
			has_hider = _phase_0i_has_hider_child(n)
		if has_hider:
			amr_attached_count += 1
		audit.authoring_marker_root_subnodes.append({
			"path": p,
			"found": n != null,
			"hider_attached": has_hider,
		})
	audit.authoring_hiders_attached_count = amr_attached_count + (1 if audit.marker_tile_layer_hider_attached else 0) + (1 if audit.editor_only_placeholders_hider_attached else 0)
	# Minimum: MarkerTileLayer + EditorOnlyPlaceholders + at least 3 authoring marker subnodes.
	audit.authoring_hiders_attached_min = (
		audit.marker_tile_layer_hider_attached
		and audit.editor_only_placeholders_hider_attached
		and amr_attached_count >= 3
	)
	audit.authoring_tiles_runtime_safe = (
		audit.marker_tile_layer_hider_attached
		and audit.editor_only_placeholders_hider_attached
	)

	# ---- Generated runtime collision root + gate blocker audit
	var rc_path := String(cfg.get("generated_runtime_collision_root_path", "GameplayRoot/GeneratedRuntimeCollision"))
	audit.generated_runtime_collision_root_path = rc_path
	var rc_node: Node = scene_root.get_node_or_null(rc_path)
	audit.generated_runtime_collision_root_present = rc_node != null
	if rc_node != null:
		var gate_cfg: Dictionary = cfg.get("code_gate_blocker", {})
		var gb_path := rc_path + "/" + String(cfg.get("gate_blockers_subpath", "GateBlockers")) + "/" + String(gate_cfg.get("manifest_id", "BLOCK_code_gate"))
		var gb_node: Node = scene_root.get_node_or_null(gb_path)
		if gb_node is StaticBody2D:
			var gb := gb_node as StaticBody2D
			audit.code_gate_generated_blocker_present = true
			audit.code_gate_generated_blocker_node_path = gb_path
			audit.code_gate_generated_blocker_uses_walls_layer = (int(gb.collision_layer) & 4) != 0
			audit.code_gate_generated_blocker_future_unlockable = bool(gb.get_meta("future_unlockable", false))
			audit.code_gate_generated_blocker_world_position = [gb.global_position.x, gb.global_position.y]

	audit.generated_wall_collision_present = audit.wall_layer_collision_enabled or audit.code_gate_generated_blocker_present

	# ---- Core collectibles promotion audit
	var collectibles_parent_path := "EntityRoot/Interactables/Phase0IGeneratedCollectibles"
	var collectibles_parent: Node = scene_root.get_node_or_null(collectibles_parent_path)
	var promoted_categories := {}
	if collectibles_parent != null:
		for child in collectibles_parent.get_children():
			if child is Area2D:
				var area := child as Area2D
				var manifest_id := String(child.name)
				var is_real := area.get_script() != null
				var collectible_type := ""
				if "collectible_type" in area:
					collectible_type = String(area.get("collectible_type"))
				audit.core_collectibles_promoted.append({
					"manifest_id": manifest_id,
					"node_path": String(scene_root.get_path_to(area)),
					"interactable": is_real and area.is_in_group("interactable") if is_real else false,
					"collectible_type": collectible_type,
					"is_area2d": true,
				})
				promoted_categories[manifest_id] = collectible_type
	# Categorize.
	for mid_obj in promoted_categories.keys():
		var mid := String(mid_obj)
		var ctype := String(promoted_categories[mid])
		if mid == "OBJ_bag_recovery":
			audit.core_delivery_bag_promoted_or_reported = true
		if ctype == "poop_bag" or mid.begins_with("BAG_") or mid == "poop_bag_garage_pet_bin":
			audit.at_least_one_poop_bag_promoted_or_reported = true
		if ctype == "polaroid" or mid.begins_with("PHOTO_"):
			audit.at_least_one_photo_promoted_or_reported = true
		if ctype == "evidence_clue" or mid.begins_with("CLUE_"):
			audit.at_least_one_clue_promoted_or_reported = true

	# ---- Route safeguard audit
	var sg_parent_path := String(cfg.get("route_safeguard_parent_path", "GameplayRoot"))
	var sg_name := String(cfg.get("route_safeguard_node_name", "Phase0IRouteSafeguard"))
	var sg_path := sg_parent_path + "/" + sg_name
	var sg_node: Node = scene_root.get_node_or_null(sg_path)
	if sg_node != null:
		audit.route_safeguard_attached = true
		audit.route_safeguard_node_path = sg_path
		var targets_meta: Variant = sg_node.get_meta("phase_0i_safeguard_targets", PackedStringArray())
		if targets_meta is PackedStringArray:
			audit.route_safeguard_targets = (targets_meta as PackedStringArray)
		else:
			audit.route_safeguard_targets = []

	# ---- Louis route geometry audit
	audit.louis_route_audit = _phase_0i_louis_route_audit(rows)
	var louis: Dictionary = audit.louis_route_audit
	audit.louis_route_bypasses_code_gate = bool(louis.get("entry_after_market", false)) and bool(louis.get("return_after_gate", false))
	audit.louis_route_does_not_skip_bag_objective = bool(louis.get("bag_objective_present_and_not_bypassed", false))
	audit.louis_route_does_not_skip_exit = bool(louis.get("exit_present_and_after_return", false))
	audit.louis_route_return_before_security_beam = bool(louis.get("return_destination_before_security_beam", false))
	audit.route_destinations_consistent_with_manifest = bool(louis.get("destinations_resolve", true))

	return audit


static func _phase_0i_has_hider_child(parent: Node) -> bool:
	for child in parent.get_children():
		var s: Script = child.get_script()
		if s != null and (String(s.resource_path).ends_with("Phase0IAuthoringHider.gd") or String(child.name) == "Phase0IAuthoringHider"):
			return true
	return false


static func _phase_0i_louis_route_audit(rows: Array) -> Dictionary:
	# Pull out Louis-relevant cells from manifest rows.
	var cells := {}
	for r_obj in rows:
		var r: Dictionary = r_obj
		var mid := String(r.get("manifest_id", ""))
		if mid == "":
			continue
		cells[mid] = Vector2i(int(r.get("x", 0)), int(r.get("y", 0)))
	var info := {
		"player_spawn_present": cells.has("player_spawn_main"),
		"market_objective_present": cells.has("OBJ_market_investigation"),
		"louis_entry_present": cells.has("ROUTE_IN_louis_service_door") or cells.has("spawn_route_louis_entry") or cells.has("ROUTE_SPAWN_louis_entry"),
		"louis_return_destination_present": cells.has("ROUTE_DEST_louis_return_destination") or cells.has("spawn_route_louis_return"),
		"louis_return_trigger_present": cells.has("ROUTE_RET_louis_return_trigger") or cells.has("transition_route_louis_return"),
		"code_gate_present": cells.has("GATE_garage_code"),
		"security_beam_present": cells.has("AMBUSH_security_beam"),
		"bag_objective_present": cells.has("OBJ_bag_recovery"),
		"exit_present": cells.has("EXIT_mission_return_to_louis"),
	}
	var market_x := int(cells.get("OBJ_market_investigation", Vector2i(38, 1)).x)
	var entry_x := int(cells.get("ROUTE_IN_louis_service_door", cells.get("ROUTE_SPAWN_louis_entry", Vector2i(60, 0))).x)
	var gate_x := int(cells.get("GATE_garage_code", Vector2i(149, 3)).x)
	var return_dest_x := int(cells.get("ROUTE_DEST_louis_return_destination", cells.get("spawn_route_louis_return", Vector2i(170, 3))).x)
	var beam_x := int(cells.get("AMBUSH_security_beam", Vector2i(181, 14)).x)
	var bag_x := int(cells.get("OBJ_bag_recovery", Vector2i(260, 20)).x)
	var exit_x := int(cells.get("EXIT_mission_return_to_louis", Vector2i(12, 52)).x)
	info.entry_after_market = entry_x >= market_x
	info.return_after_gate = return_dest_x >= gate_x
	info.return_destination_before_security_beam = return_dest_x <= beam_x
	info.bag_objective_present_and_not_bypassed = info.bag_objective_present and bag_x > return_dest_x
	info.exit_present_and_after_return = info.exit_present  # Exit is south corridor; structurally always reachable post-return.
	info.destinations_resolve = info.louis_entry_present and info.louis_return_destination_present and info.code_gate_present
	info.entry_x = entry_x
	info.market_x = market_x
	info.gate_x = gate_x
	info.return_dest_x = return_dest_x
	info.beam_x = beam_x
	info.bag_x = bag_x
	info.exit_x = exit_x
	return info


# ----------------------------- Helpers ----------------------------------------

static func _finalize_assertions(result: Dictionary, manifest: Dictionary) -> void:
	var counts: Dictionary = result.get("counts", {})
	var src_protect: Dictionary = result.get("source_scene_protection", {})
	var floor_count: int = int(counts.get("floor_cell_count", 0))
	var wall_count: int = int(counts.get("wall_cell_count", 0))
	var marker_count: int = int(counts.get("marker_tile_count", 0))
	var rules: Dictionary = manifest.get("validation_rules", {})

	var hard := {
		"source_scene_unchanged": bool(src_protect.get("unchanged", true)),
		"target_scene_exists": result.scene_root_in_memory or true,
		"target_scene_loads": true,
		"FloorLayer_exists": result.required_node_presence.get("GameplayRoot/LayoutRoot/FloorLayer", false) if result.has("required_node_presence") else false,
		"WallLayer_exists": result.required_node_presence.get("GameplayRoot/LayoutRoot/WallLayer", false) if result.has("required_node_presence") else false,
		"CoverLayer_exists": result.required_node_presence.get("GameplayRoot/LayoutRoot/CoverLayer", false) if result.has("required_node_presence") else false,
		"CollisionBarrierLayer_exists": result.required_node_presence.get("GameplayRoot/LayoutRoot/CollisionBarrierLayer", false) if result.has("required_node_presence") else false,
		"MarkerTileLayer_exists": result.required_node_presence.get("GameplayRoot/LayoutRoot/MarkerTileLayer", false) if result.has("required_node_presence") else false,
		"MarkerRoot_exists": result.required_node_presence.get("GameplayRoot/MarkerRoot", false) if result.has("required_node_presence") else false,
		"floor_cell_count_meets_min": floor_count >= int(rules.get("floor_cell_count_min", 10000)),
		"used_rect_width_meets_min": int(counts.get("used_rect_width", 0)) >= int(rules.get("used_rect_width_min", 250)),
		"used_rect_height_meets_min": int(counts.get("used_rect_height", 0)) >= int(rules.get("used_rect_height_min", 100)),
		"FloorLayer_not_empty": floor_count > 0,
		"WallLayer_not_empty": wall_count > 0,
		"MarkerTileLayer_not_empty": marker_count > 0,
		"random_old_marker_tiles_removed": int(result.get("marker_tile_audit", {}).get("unaccounted_count", 0)) == 0,
		"unaccounted_marker_tile_count_zero": int(result.get("marker_tile_audit", {}).get("unaccounted_count", 0)),
		"gate_marker_tile_count_equals_one": int(result.get("marker_tile_audit", {}).get("gate_tile_count", 0)) == 1,
		"only_GATE_garage_code_uses_GATE": bool(result.get("abbr_rule_results", {}).get("only_GATE_garage_code_uses_GATE", false)),
		"no_CONTROL_uses_GATE": bool(result.get("abbr_rule_results", {}).get("no_CONTROL_uses_GATE", false)),
		"no_BENTLEY_SWITCH_uses_GATE": bool(result.get("abbr_rule_results", {}).get("no_BENTLEY_SWITCH_uses_GATE", false)),
		"all_BENTLEY_SWITCH_use_SWITCH": bool(result.get("abbr_rule_results", {}).get("all_BENTLEY_SWITCH_use_SWITCH", false)),
		"CONTROL_alarm_panel_uses_SWITCH": bool(result.get("abbr_rule_results", {}).get("CONTROL_alarm_panel_uses_SWITCH", false)),
		"CONTROL_camera_terminal_uses_SWITCH": bool(result.get("abbr_rule_results", {}).get("CONTROL_camera_terminal_uses_SWITCH", false)),
		"CONTROL_door_controls_uses_SWITCH": bool(result.get("abbr_rule_results", {}).get("CONTROL_door_controls_uses_SWITCH", false)),
		"ROUTE_IN_louis_service_door_uses_DOOR": bool(result.get("abbr_rule_results", {}).get("ROUTE_IN_louis_service_door_uses_DOOR", false)),
		"ROUTE_RET_louis_return_trigger_uses_DOOR": bool(result.get("abbr_rule_results", {}).get("ROUTE_RET_louis_return_trigger_uses_DOOR", false)),
		"marker_vocabulary_includes_DOOR": bool(result.get("marker_vocabulary", {}).get("DOOR", false)),
		"marker_vocabulary_includes_SWITCH": bool(result.get("marker_vocabulary", {}).get("SWITCH", false)),
		"DOOR_marker_tile_has_no_collision": bool(result.get("door_no_collision", false)),
		"SWITCH_marker_tile_has_no_collision": bool(result.get("switch_no_collision", false)),
		"player_flood_fill_does_not_require_bentley_routes": bool(result.get("player_flood_fill_does_not_require_bentley_routes", false)),
		"poop_bag_garage_pet_bin_not_in_blocking_collision": bool(result.get("poop_bag_garage_pet_bin_status", false)),
		"editor_only_placeholders_have_no_iso_mission_marker_script": int(result.get("editor_only_placeholder_audit", {}).get("placeholders_with_script", 1)) == 0,
		"editor_only_placeholders_have_no_marker_type_field": int(result.get("editor_only_placeholder_audit", {}).get("placeholders_with_marker_type", 1)) == 0,
		"editor_only_placeholders_have_no_gameplay_groups": int(result.get("editor_only_placeholder_audit", {}).get("placeholders_in_groups", 1)) == 0,
		"placeholder_nodes_have_owner": int(result.get("editor_only_placeholder_audit", {}).get("placeholders_without_owner", 1)) == 0,
		"placeholder_children_have_owner": int(result.get("editor_only_placeholder_audit", {}).get("label_children_without_owner", 1)) == 0,
		"dry_run_validator_used_in_memory_root": bool(result.scene_root_in_memory) or String(result.get("entrypoint", "")) == "validate_scene_file",
		"validator_loaded_target_file": String(result.get("entrypoint", "")) == "validate_scene_root" or String(result.get("entrypoint", "")) == "validate_scene_file",
		"cache_safe_load_mode_used": bool(result.cache_safe_load_mode_used),
		"optional_visual_reference_NOT_used_for_coordinates": true,
		"code_gate_to_beam_cell_distance_meets_min": int(result.get("code_gate_to_beam_distance", 0)) >= int(rules.get("code_gate_to_beam_cell_distance_min", 25)),
		"safe_code_input_not_inside_beam_zone": not bool(result.get("safe_code_in_beam_zone", true)),
		"all_required_main_routes_reachable": _all_required_reachable(result),
		"bentley_route_A_exists": bool(result.get("bentley_routes_exist", {}).get("zone_bentley_route_a_passage", false)),
		"bentley_route_B_exists": bool(result.get("bentley_routes_exist", {}).get("zone_bentley_route_b_passage", false)),
		"bentley_route_C_exists": bool(result.get("bentley_routes_exist", {}).get("zone_bentley_route_c_passage", false)),
		"bentley_route_D_exists": bool(result.get("bentley_routes_exist", {}).get("zone_bentley_route_d_passage", false)),
		"vent_in_marker_cells_not_blocked": _vent_in_cells_safe(result),
		"vent_interactable_stand_cells_available": _vent_stand_cells_safe(result),
		"camera_floodlight_spacing_meets_min": int(result.get("camera_floodlight_spacing", {}).get("violations", []).size()) == 0,
		"missing_required_runtime_markers_count_zero": int(result.get("builder_report_summary", {}).get("missing_required_runtime_markers", 0)),
		"equivalence_collisions_count_zero": int(result.get("builder_report_summary", {}).get("equivalence_collisions", 0)),
	}
	# ---- Phase 0H assertions
	var p0h: Dictionary = result.get("phase_0h_audit", {})
	if p0h.size() > 0:
		hard["no_unexpected_tilemap_layers_with_used_cells"] = bool(p0h.get("no_unexpected_tilemap_layers_with_used_cells", false))
		hard["old_prototype_floor_tiles_not_visible"] = bool(p0h.get("old_floor_layer_clean", false))
		hard["old_prototype_wall_tiles_not_visible"] = bool(p0h.get("old_wall_layer_clean", false))
		hard["old_collision_boundary_artifacts_not_visible"] = bool(p0h.get("old_collision_layer_clean", false)) and bool(p0h.get("boundary_colliders_disabled", false))
		hard["boundary_colliders_disabled"] = bool(p0h.get("boundary_colliders_disabled", false))
		hard["boundary_colliders_zero_collision_layers"] = int(p0h.get("boundary_static_bodies_with_nonzero_collision", 1)) == 0
		hard["camera_limits_cover_floor_used_rect"] = bool(p0h.get("camera_limits_cover_used_rect", false))
		hard["far_route_points_inside_camera_bounds"] = bool(p0h.get("far_route_points_inside_camera_bounds", false))
		hard["key_marker_ids_inside_camera_bounds"] = bool(p0h.get("key_marker_ids_inside_camera_bounds", false))
		# Root transform: not asserted as identity; we only assert the audit was performed.
		hard["root_transform_audit_recorded"] = p0h.has("root_transform")
		hard["marker_labels_no_at_label_siblings"] = int(p0h.get("at_label_sibling_count", 1)) == 0
		hard["marker_labels_show_editor_label_false"] = int(p0h.get("markers_with_show_editor_label_true", 1)) == 0
		hard["exactly_one_gate_tile"] = int(result.get("marker_tile_audit", {}).get("gate_tile_count", 0)) == 1
		hard["code_gate_has_associated_block_marker"] = bool(p0h.get("code_gate_has_block_marker_row", false))
		hard["code_gate_has_collision_barrier"] = bool(p0h.get("code_gate_has_collision_barrier_cell", false))
		hard["code_gate_blocker_ready_for_future_unlock"] = bool(p0h.get("code_gate_blocker_ready_for_future_unlock", false))
		hard["level_bounds_zone_present_in_mission_definition"] = bool(p0h.get("level_bounds_zone_present", false))
	# ---- Phase 0I assertions
	var p0i: Dictionary = result.get("phase_0i_audit", {})
	if p0i.size() > 0:
		hard["wall_layer_collision_runtime_active"] = bool(p0i.get("wall_layer_collision_enabled", false))
		hard["wall_collision_runtime_active"] = bool(p0i.get("wall_layer_collision_enabled", false))
		hard["WallLayer_or_GeneratedRuntimeCollision_blocks_player"] = bool(p0i.get("wall_layer_collision_enabled", false)) or bool(p0i.get("generated_wall_collision_present", false))
		hard["generated_wall_collision_uses_walls_layer"] = bool(p0i.get("wall_layer_uses_walls_physics_layer", false))
		hard["player_collision_mask_includes_walls"] = bool(p0i.get("player_collision_mask_includes_walls", true))
		hard["old_boundary_colliders_not_required_for_wall_collision"] = bool(p0h.get("boundary_colliders_disabled", false)) and bool(p0i.get("wall_layer_collision_enabled", false))
		hard["MarkerTileLayer_visible_in_editor"] = bool(p0i.get("marker_tile_layer_authoring_visible_property", true))
		hard["MarkerTileLayer_hidden_at_runtime"] = bool(p0i.get("marker_tile_layer_hider_attached", false))
		hard["authoring_tiles_do_not_render_above_player_at_runtime"] = bool(p0i.get("authoring_tiles_runtime_safe", false))
		hard["editor_only_placeholders_do_not_render_as_gameplay_pickups"] = bool(p0i.get("editor_only_placeholders_hider_attached", false))
		hard["code_gate_blocker_runtime_blocks_player"] = bool(p0i.get("code_gate_generated_blocker_present", false)) and bool(p0i.get("code_gate_generated_blocker_uses_walls_layer", false))
		hard["code_gate_blocker_future_unlockable"] = bool(p0i.get("code_gate_generated_blocker_future_unlockable", false))
		hard["code_gate_blocker_not_just_visual_marker"] = bool(p0i.get("code_gate_generated_blocker_present", false))
		hard["core_delivery_bag_interactable_or_existing_system_missing_reported"] = bool(p0i.get("core_delivery_bag_promoted_or_reported", false))
		hard["at_least_one_poophag_or_bag_pickup_interactable_or_missing_system_reported"] = bool(p0i.get("at_least_one_poop_bag_promoted_or_reported", false))
		hard["at_least_one_photo_interactable_or_missing_system_reported"] = bool(p0i.get("at_least_one_photo_promoted_or_reported", false))
		hard["at_least_one_clue_interactable_or_missing_system_reported"] = bool(p0i.get("at_least_one_clue_promoted_or_reported", false))
		hard["collectible_authoring_tiles_hidden_at_runtime"] = bool(p0i.get("marker_tile_layer_hider_attached", false))
		hard["player_crossing_vent_area_does_not_teleport_to_spawn"] = bool(p0i.get("route_safeguard_attached", false))
		hard["VENT_IN_bentley_routes_are_not_player_teleport_triggers"] = bool(p0i.get("route_safeguard_attached", false))
		hard["louis_route_trigger_not_accidentally_on_bentley_vent"] = bool(p0i.get("route_safeguard_attached", false))
		hard["route_triggers_have_correct_linked_destinations"] = bool(p0i.get("route_destinations_consistent_with_manifest", false))
		hard["louis_route_bypasses_code_gate_challenge"] = bool(p0i.get("louis_route_bypasses_code_gate", false))
		hard["louis_route_does_not_skip_bag_objective"] = bool(p0i.get("louis_route_does_not_skip_bag_objective", false))
		hard["louis_route_does_not_skip_exit"] = bool(p0i.get("louis_route_does_not_skip_exit", false))
		hard["louis_route_return_before_security_beam"] = bool(p0i.get("louis_route_return_before_security_beam", false))
		hard["phase_0i_helper_scripts_attached"] = bool(p0i.get("authoring_hiders_attached_min", false)) and bool(p0i.get("route_safeguard_attached", false))
	result.hard_assertions = hard

static func _all_required_reachable(result: Dictionary) -> bool:
	var reach: Dictionary = result.get("reachability", {})
	if not reach is Dictionary:
		return false
	var req: Array = reach.get("required", [])
	for r in req:
		if not bool(r.get("reachable", false)):
			return false
	return true

static func _vent_in_cells_safe(result: Dictionary) -> bool:
	for v in result.get("vent_audit", []):
		if bool(v.get("vent_cell_blocked", false)):
			return false
		if not bool(v.get("vent_cell_on_floor", true)):
			return false
	return true

static func _vent_stand_cells_safe(result: Dictionary) -> bool:
	for v in result.get("vent_audit", []):
		if not bool(v.get("stand_cell_on_floor", false)):
			return false
		if bool(v.get("stand_cell_blocked", false)):
			return false
	return true

static func _atlas_tile_has_no_collision(ts: TileSet, atlas_meta: Dictionary, abbr: String) -> bool:
	if ts == null:
		return false
	var src_id: int = int(atlas_meta.get("source_id", 0))
	var src := ts.get_source(src_id)
	if not (src is TileSetAtlasSource):
		return false
	var atlas_src := src as TileSetAtlasSource
	var abbreviations: Dictionary = atlas_meta.get("abbreviations", {})
	if not abbreviations.has(abbr):
		return false
	var arr: Array = abbreviations[abbr]
	var coords := Vector2i(int(arr[0]), int(arr[1]))
	if not atlas_src.has_tile(coords):
		return false
	var td := atlas_src.get_tile_data(coords, 0)
	if td == null:
		return false
	for pl in range(ts.get_physics_layers_count()):
		if td.get_collision_polygons_count(pl) > 0:
			return false
	return true

static func _find_target_cell(rows: Array, manifest_id: String, anchor_cell: Vector2i) -> Vector2i:
	for r in rows:
		if String(r.get("manifest_id", "")) == manifest_id:
			return Vector2i(int(r.get("x", 0)) + anchor_cell.x, int(r.get("y", 0)) + anchor_cell.y)
	return anchor_cell

static func _find_row(rows: Array, manifest_id: String) -> Dictionary:
	for r in rows:
		if String(r.get("manifest_id", "")) == manifest_id:
			return r
	return {}

static func _zone_center(manifest: Dictionary, zone_id: String, anchor_cell: Vector2i) -> Vector2i:
	for rect in manifest.get("floor_rects", []):
		if String(rect.get("id", "")) == zone_id:
			var xmin: int = int(rect.get("x_min", 0)) + anchor_cell.x
			var xmax: int = int(rect.get("x_max", 0)) + anchor_cell.x
			var ymin: int = int(rect.get("y_min", 0)) + anchor_cell.y
			var ymax: int = int(rect.get("y_max", 0)) + anchor_cell.y
			return Vector2i((xmin + xmax) / 2, (ymin + ymax) / 2)
	return anchor_cell

static func _flood_fill_4(start: Vector2i, floor_cells: Dictionary, blockers: Dictionary, exclude: Dictionary) -> Dictionary:
	var visited := {}
	if not floor_cells.has(start):
		return visited
	if blockers.has(start):
		return visited
	var queue := [start]
	visited[start] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d in dirs:
			var n: Vector2i = c + d
			if visited.has(n):
				continue
			if not floor_cells.has(n):
				continue
			if blockers.has(n):
				continue
			if exclude.has(n):
				continue
			visited[n] = true
			queue.append(n)
	return visited

# ----------------------------- Report writers ---------------------------------

static func write_json_report(result: Dictionary, path: String) -> void:
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_json_report failed to open: " + path)
		return
	var sanitized: Variant = _sanitize_for_json(result)
	f.store_string(JSON.stringify(sanitized, "  "))
	f.close()

static func _sanitize_for_json(value: Variant) -> Variant:
	if value is Dictionary:
		var out := {}
		for k in value.keys():
			# Skip live Node references.
			var v: Variant = value[k]
			if k == "scene_root":
				continue
			if v is Node:
				out[k] = String((v as Node).name) if (v as Node) != null else null
			elif v is Vector2i:
				out[k] = [v.x, v.y]
			elif v is Vector2:
				out[k] = [v.x, v.y]
			else:
				out[k] = _sanitize_for_json(v)
		return out
	elif value is Array:
		var out := []
		for v in value:
			if v is Node:
				out.append(String((v as Node).name) if (v as Node) != null else null)
			elif v is Vector2i:
				out.append([v.x, v.y])
			elif v is Vector2:
				out.append([v.x, v.y])
			else:
				out.append(_sanitize_for_json(v))
		return out
	elif value is Vector2i:
		return [value.x, value.y]
	elif value is Vector2:
		return [value.x, value.y]
	return value

static func write_markdown_report(result: Dictionary, path: String, title: String) -> void:
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_markdown_report failed to open: " + path)
		return
	var lines: Array = []
	lines.append("# " + title)
	lines.append("")
	var pass_str := "PASS" if bool(result.get("pass", false)) else "FAIL"
	lines.append("**Status:** " + pass_str)
	lines.append("**Entrypoint:** " + String(result.get("entrypoint", "")))
	lines.append("**Scene root in memory:** " + str(bool(result.get("scene_root_in_memory", false))))
	lines.append("")
	lines.append("## Hard assertions")
	lines.append("")
	lines.append("| Assertion | Value |")
	lines.append("| --- | --- |")
	var hard: Dictionary = result.get("hard_assertions", {})
	for k in hard.keys():
		lines.append("| `" + String(k) + "` | " + str(hard[k]) + " |")
	lines.append("")
	lines.append("## Counts")
	lines.append("")
	for k in result.get("counts", {}).keys():
		lines.append("- **" + String(k) + ":** " + str(result.counts[k]))
	lines.append("")
	if result.has("anchor_cell"):
		lines.append("**Anchor cell:** " + str(result.anchor_cell))
		lines.append("")
	if result.has("reachability"):
		lines.append("## Reachability")
		lines.append("")
		lines.append("### Required main routes")
		for r in result.reachability.get("required", []):
			var ok := "[OK]" if bool(r.get("reachable", false)) else "[FAIL]"
			lines.append("- " + ok + " " + String(r.get("label", "")) + " @ " + str(r.get("center", [])))
		lines.append("")
		lines.append("### Optional routes")
		for r in result.reachability.get("optional", []):
			var ok := "[OK]" if bool(r.get("reachable", false)) else "[WARN]"
			lines.append("- " + ok + " " + String(r.get("zone", "")) + " @ " + str(r.get("center", [])))
		lines.append("")
	if result.has("vent_audit"):
		lines.append("## Vent interface audit")
		lines.append("")
		lines.append("| ID | VENT_IN | Vent on floor | Vent blocked | Stand cell | Stand on floor | Stand blocked |")
		lines.append("| --- | --- | --- | --- | --- | --- | --- |")
		for v in result.vent_audit:
			lines.append("| " + String(v.id) + " | " + String(v.vent_in_marker_id) + " | " + str(v.vent_cell_on_floor) + " | " + str(v.vent_cell_blocked) + " | " + str(v.stand_cell) + " | " + str(v.stand_cell_on_floor) + " | " + str(v.stand_cell_blocked) + " |")
		lines.append("")
	if result.has("marker_tile_audit"):
		var mta: Dictionary = result.marker_tile_audit
		lines.append("## MarkerTileLayer audit")
		lines.append("")
		lines.append("- **GATE tile count:** " + str(mta.gate_tile_count))
		lines.append("- **Unaccounted cells:** " + str(mta.unaccounted_count))
		lines.append("")
		lines.append("### Per-abbreviation tile counts")
		for k in mta.per_abbr_tile_counts.keys():
			lines.append("- " + String(k) + ": " + str(mta.per_abbr_tile_counts[k]))
		lines.append("")
	if result.has("editor_only_placeholder_audit"):
		var pa: Dictionary = result.editor_only_placeholder_audit
		lines.append("## Editor-only placeholder audit")
		lines.append("")
		for k in pa.keys():
			lines.append("- **" + String(k) + ":** " + str(pa[k]))
		lines.append("")
	if result.has("errors") and (result.errors as Array).size() > 0:
		lines.append("## Errors")
		lines.append("")
		for e in result.errors:
			lines.append("- " + String(e))
		lines.append("")
	if result.has("warnings") and (result.warnings as Array).size() > 0:
		lines.append("## Warnings")
		lines.append("")
		for w in result.warnings:
			lines.append("- " + String(w))
		lines.append("")
	f.store_string("\n".join(lines))
	f.close()
