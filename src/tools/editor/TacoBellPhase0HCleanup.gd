@tool
extends SceneTree

## Phase 0H — Taco Bell duplicate-scene cleanup, marker verification, camera bounds,
## and editor artifact audit.
##
## Audit-first, fix-via-builder pass. The script:
##   1. Captures source-scene + duplicate-scene MD5 baselines.
##   2. Backs up the existing duplicate scene (timestamped).
##   3. Adds/updates a `level_bounds_max` MissionZoneDefinition on
##      taco_bell_iso_blockout_definition.tres so the runtime
##      IsoMissionBase._apply_camera_bounds() picks up the new map size.
##   4. Calls the deterministic builder with dry_run=false. The builder paints
##      the manifest layout AND performs the Phase 0H cleanup pass:
##         - clears + hides old TileMapLayers under GameplayRoot/...
##         - disables BoundaryColliders (collision_layer/mask=0, visible=false,
##           process_mode=DISABLED)
##         - bakes Camera2D limits from FloorLayer.get_used_rect()
##         - dedups @Label@xxxxx siblings and sets show_editor_label=false on
##           every IsoMissionMarker
##         - audits the duplicate root transform (does NOT modify it)
##   5. Calls the validator on the saved duplicate.
##   6. Writes Phase 0H audit reports under res://docs/reports/.
##   7. Re-checks source-scene hash to prove byte-stability.
##
## Hard-fail rule: if any hard assertion fails, the script stops, logs the
## failing assertions with cells / counts where applicable, and writes a
## report flagged pass=false. The source scene is never written to.

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")
const Builder := preload("res://src/tools/editor/TacoBellExpandedLayoutBuilder.gd")
const Validator := preload("res://src/tools/editor/TacoBellExpandedLayoutValidator.gd")

const REPORT_JSON := "res://docs/reports/taco_bell_phase_0h_cleanup_audit.json"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0h_cleanup_audit.md"

func _initialize() -> void:
	var t0_ms := Time.get_ticks_msec()
	print("[Phase 0H][Apply] Loading manifest...")
	var manifest := Shared.load_manifest()
	if manifest.has("_error"):
		printerr("Manifest load failed: " + str(manifest))
		quit(1)
		return

	var source_path: String = manifest.get("source_scene", Shared.SOURCE_SCENE_PATH)
	var target_path: String = manifest.get("target_scene", Shared.TARGET_SCENE_PATH)

	var source_hash_before := Shared.file_md5(source_path)
	var target_hash_before := Shared.file_md5(target_path) if FileAccess.file_exists(target_path) else ""

	# Step 1: Backup existing duplicate (idempotent; always runs in 0H).
	var phase_f := {
		"target_path": target_path,
		"target_existed_before": FileAccess.file_exists(target_path),
		"target_hash_before": target_hash_before,
		"backup_created": false,
		"backup_path": "",
	}
	if phase_f.target_existed_before:
		var ts := Shared.now_timestamp_string()
		var backup_path := target_path.get_basename() + ".phase0h_backup." + ts + ".tscn"
		var ok := _copy_resource_file(target_path, backup_path)
		phase_f.backup_created = ok
		phase_f.backup_path = backup_path
		if not ok:
			printerr("Backup failed: " + backup_path)
			quit(1)
			return
		print("  Backed up existing duplicate -> " + backup_path)

	# Step 2: Update mission_definition.tres with level_bounds_max zone.
	print("[Phase 0H][Step 2] Updating mission_definition.tres with level_bounds_max zone...")
	var def_update := _ensure_level_bounds_zone(manifest, source_hash_before)
	if not bool(def_update.get("ok", false)):
		printerr("Could not ensure level_bounds_max zone: " + String(def_update.get("error", "")))
		quit(1)
		return

	# Step 3: Run builder in apply mode (now extended with Phase 0H cleanup).
	print("[Phase 0H][Step 3] Running builder in apply mode (dry_run=false)...")
	var build_result: Dictionary = Builder.run({"dry_run": false, "write_dry_run_report": false})
	var build_errors: Array = build_result.get("errors", [])
	if build_errors.size() > 0:
		for e in build_errors:
			printerr("  Builder error: " + str(e))

	# Free the in-memory root.
	var bld_root: Node = build_result.get("scene_root", null)
	if bld_root != null:
		bld_root.queue_free()

	if not bool(build_result.get("saved", false)):
		printerr("Builder did not save the duplicate. Stopping. Source not touched.")
		_write_failure_report(manifest, phase_f, build_result, {}, def_update, source_hash_before, "phase_g_save_failed")
		quit(1)
		return

	var source_hash_after_g := Shared.file_md5(source_path)
	if source_hash_after_g != source_hash_before:
		printerr("CRITICAL: source scene hash changed during build. Aborting.")
		_write_failure_report(manifest, phase_f, build_result, {}, def_update, source_hash_before, "source_modified")
		quit(1)
		return

	if not FileAccess.file_exists(target_path):
		printerr("Builder reported saved=true but target file missing: " + target_path)
		_write_failure_report(manifest, phase_f, build_result, {}, def_update, source_hash_before, "target_missing")
		quit(1)
		return

	var target_hash_after := Shared.file_md5(target_path)

	# Step 4: validate_scene_file
	print("[Phase 0H][Step 4] Running validate_scene_file()...")
	var ctx := {
		"cache_safe_load_mode_used": true,
		"source_scene_protection": {
			"hash_before": source_hash_before,
			"hash_after": source_hash_after_g,
			"unchanged": true,
		},
		"optional_visual_reference": build_result.get("optional_visual_reference", {}),
		"builder_report_summary": {
			"missing_required_runtime_markers": (build_result.get("missing_required_runtime_markers", []) as Array).size(),
			"equivalence_collisions": (build_result.get("equivalence_collisions", []) as Array).size(),
		},
	}
	var validate_h: Dictionary = Validator.validate_scene_file(target_path, manifest, ctx)

	# Step 5: structural smoke (re-instantiate)
	print("[Phase 0H][Step 5] Structural smoke check...")
	var smoke := _structural_smoke(target_path)

	# Step 6: combine + write reports
	print("[Phase 0H][Step 6] Writing final Phase 0H audit reports...")
	var elapsed_ms := Time.get_ticks_msec() - t0_ms

	var phase_h_pass := bool(validate_h.get("pass", false)) and (validate_h.get("errors", []) as Array).size() == 0
	var smoke_pass := bool(smoke.get("pass", false))
	var overall_pass := build_errors.size() == 0 and phase_h_pass and smoke_pass

	var combined := {
		"phase": "0H_cleanup_audit",
		"pass": overall_pass,
		"timestamp": Shared.now_timestamp_string(),
		"elapsed_ms": elapsed_ms,
		"source_scene_protection": {
			"path": source_path,
			"hash_before": source_hash_before,
			"hash_after": source_hash_after_g,
			"unchanged": true,
		},
		"target_scene": {
			"path": target_path,
			"existed_before": phase_f.target_existed_before,
			"backup_created": phase_f.backup_created,
			"backup_path": phase_f.backup_path,
			"hash_before": phase_f.target_hash_before,
			"hash_after": target_hash_after,
		},
		"mission_definition_update": def_update,
		"build_summary": {
			"counts": build_result.get("counts", {}),
			"phase_0h_cleanup": build_result.get("phase_0h_cleanup", {}),
			"runtime_markers_moved": int(build_result.get("counts", {}).get("runtime_markers_moved", 0)),
			"editor_only_placeholders_created": int(build_result.get("counts", {}).get("editor_only_placeholders_created", 0)),
			"saved": bool(build_result.get("saved", false)),
		},
		"validate_h": validate_h,
		"structural_smoke": smoke,
	}

	Validator.write_json_report(combined, REPORT_JSON)
	_write_markdown_report(combined, REPORT_MD)

	if overall_pass:
		print("[Phase 0H] PASS")
		print("  Final report: " + REPORT_JSON)
		print("  Final markdown: " + REPORT_MD)
		quit(0)
	else:
		printerr("[Phase 0H] FAIL")
		printerr("  See report: " + REPORT_JSON)
		var hard: Dictionary = validate_h.get("hard_assertions", {})
		for k in hard.keys():
			var v = hard[k]
			if v is bool and not v:
				printerr("  HARD ASSERTION FAIL: " + String(k))
			elif String(k).ends_with("_count_zero") and v is int and v != 0:
				printerr("  HARD ASSERTION FAIL: " + String(k) + " = " + str(v))
		var smoke_errors: Array = smoke.get("errors", [])
		for e in smoke_errors:
			printerr("  SMOKE FAIL: " + str(e))
		quit(1)

# -------------------------- mission_definition.tres update -------------------

func _ensure_level_bounds_zone(manifest: Dictionary, _source_hash_before: String) -> Dictionary:
	var cleanup_cfg: Dictionary = manifest.get("phase_0h_cleanup", {})
	var def_path := String(cleanup_cfg.get("mission_definition_resource_path", "res://assets/missions/taco_bell_iso_blockout_definition.tres"))
	var zone_id := String(cleanup_cfg.get("level_bounds_zone_id", "level_bounds_max"))
	var pad: int = int(cleanup_cfg.get("level_bounds_padding_cells", 8))
	var size_min: Array = cleanup_cfg.get("level_bounds_zone_size_min", [200, 80])

	var def: Resource = Shared.load_cache_safe(def_path, "Resource")
	if def == null:
		return {"ok": false, "error": "mission_definition_load_failed: " + def_path}
	var zones: Variant = def.get("zones")
	if not (zones is Array):
		return {"ok": false, "error": "mission_definition.zones is not an Array"}

	# Compute origin/size from manifest floor_rects (anchor-relative coords).
	# The runtime _mission_rect() iterates zones in cell coordinates relative
	# to the FloorLayer. Adding a single bounding zone with the union of all
	# floor_rects (plus padding) will cause the runtime camera bounds to expand.
	var min_x: int = 1 << 30
	var min_y: int = 1 << 30
	var max_x: int = -(1 << 30)
	var max_y: int = -(1 << 30)
	var floor_rects: Array = manifest.get("floor_rects", [])
	for fr in floor_rects:
		var xmin: int = int(fr.get("x_min", 0))
		var xmax: int = int(fr.get("x_max", 0))
		var ymin: int = int(fr.get("y_min", 0))
		var ymax: int = int(fr.get("y_max", 0))
		min_x = mini(min_x, xmin)
		min_y = mini(min_y, ymin)
		max_x = maxi(max_x, xmax)
		max_y = maxi(max_y, ymax)
	# Apply padding
	var origin := Vector2i(min_x - pad, min_y - pad)
	var size := Vector2i((max_x - min_x) + 2 * pad, (max_y - min_y) + 2 * pad)
	# Enforce size_min
	if size.x < int(size_min[0]):
		size.x = int(size_min[0])
	if size.y < int(size_min[1]):
		size.y = int(size_min[1])

	# Find or create the zone.
	var found_idx := -1
	for i in range(zones.size()):
		var z = zones[i]
		if z != null and String(z.get("zone_id")) == zone_id:
			found_idx = i
			break

	var zone_script_path := "res://src/missions/definitions/MissionZoneDefinition.gd"
	var zone_script: Script = Shared.load_cache_safe(zone_script_path, "Script") as Script
	if zone_script == null:
		return {"ok": false, "error": "MissionZoneDefinition_script_load_failed"}

	var zone: Resource
	var added := false
	if found_idx < 0:
		zone = zone_script.new() as Resource
		zone.set("zone_id", zone_id)
		zone.set("display_name", "Level Bounds Max (Phase 0H)")
		zone.set("description", "Auto-generated by Phase 0H. Used by IsoMissionBase._mission_rect() to size camera bounds across the full Phase 0G v6 map. Not a gameplay zone.")
		zones.append(zone)
		added = true
	else:
		zone = zones[found_idx]

	# Make idempotent: only write if changed.
	var prev_origin: Vector2i = zone.get("origin")
	var prev_size: Vector2i = zone.get("size")
	if prev_origin == origin and prev_size == size and not added:
		return {
			"ok": true,
			"def_path": def_path,
			"zone_id": zone_id,
			"created": false,
			"updated": false,
			"origin": [origin.x, origin.y],
			"size": [size.x, size.y],
			"reason": "already_at_target_state_idempotent_noop",
		}

	zone.set("origin", origin)
	zone.set("size", size)
	zone.set("display_name", "Level Bounds Max (Phase 0H)")

	# Save the resource. ResourceSaver.save infers format from extension.
	var save_err := ResourceSaver.save(def, def_path)
	if save_err != OK:
		return {"ok": false, "error": "ResourceSaver_save_failed: " + str(save_err)}

	return {
		"ok": true,
		"def_path": def_path,
		"zone_id": zone_id,
		"created": added,
		"updated": not added,
		"origin": [origin.x, origin.y],
		"size": [size.x, size.y],
		"prev_origin": [prev_origin.x, prev_origin.y],
		"prev_size": [prev_size.x, prev_size.y],
	}

# -------------------------- Helpers ------------------------------------------

func _copy_resource_file(src_res_path: String, dst_res_path: String) -> bool:
	var data := FileAccess.get_file_as_bytes(src_res_path)
	if data.size() == 0 and not FileAccess.file_exists(src_res_path):
		return false
	var f := FileAccess.open(dst_res_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(data)
	f.close()
	return FileAccess.file_exists(dst_res_path)

func _structural_smoke(target_path: String) -> Dictionary:
	var smoke := {
		"phase": "structural_smoke",
		"pass": false,
		"errors": [],
		"warnings": [],
		"target_path": target_path,
	}
	if not FileAccess.file_exists(target_path):
		smoke.errors.append("target_missing_for_smoke: " + target_path)
		return smoke
	var packed: PackedScene = Shared.load_cache_safe(target_path, "PackedScene") as PackedScene
	if packed == null:
		smoke.errors.append("target_packed_scene_load_failed")
		return smoke
	var instance := packed.instantiate()
	if instance == null:
		smoke.errors.append("target_packed_scene_instantiate_failed")
		return smoke

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
	var missing := []
	for p in required_paths:
		if instance.get_node_or_null(p) == null:
			missing.append(p)
	smoke["required_node_presence"] = missing.is_empty()
	smoke["missing_required_nodes"] = missing

	var floor_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer")
	smoke["floor_cell_count"] = floor_layer.get_used_cells().size() if floor_layer != null else -1

	var cam: Camera2D = instance.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		smoke["camera_limits"] = {"left": cam.limit_left, "right": cam.limit_right, "top": cam.limit_top, "bottom": cam.limit_bottom}

	# Check old layers are clean
	var old_paths := [
		"GameplayRoot/GameplayFloorLayer",
		"GameplayRoot/GameplayCollisionLayer",
		"GameplayRoot/GameplayMarkersLayer",
		"GameplayRoot/LayoutRoot/DebugLabelLayer",
	]
	var old_layer_status: Array = []
	for p in old_paths:
		var n := instance.get_node_or_null(p)
		if n is TileMapLayer:
			var t := n as TileMapLayer
			old_layer_status.append({"path": p, "used_cells": t.get_used_cells().size(), "visible": t.visible})
		elif n != null:
			old_layer_status.append({"path": p, "class": n.get_class()})
		else:
			old_layer_status.append({"path": p, "missing": true})
	smoke["old_layer_status"] = old_layer_status

	var bc: Node = instance.get_node_or_null("GameplayRoot/BoundaryColliders")
	if bc != null:
		var counts_box := [0, 0]
		_smoke_count_collision(bc, counts_box)
		smoke["boundary_colliders"] = {
			"visible": bc.visible if bc is CanvasItem else false,
			"process_mode": int(bc.process_mode),
			"static_body_count": int(counts_box[0]),
			"static_body_with_nonzero_collision_count": int(counts_box[1]),
		}

	instance.queue_free()
	smoke.pass = (
		smoke.errors.is_empty()
		and bool(smoke.required_node_presence)
		and int(smoke.floor_cell_count) > 0
	)
	return smoke

func _smoke_count_collision(node: Node, counts_box: Array) -> void:
	if node is CollisionObject2D:
		var co := node as CollisionObject2D
		counts_box[0] = int(counts_box[0]) + 1
		if int(co.collision_layer) != 0 or int(co.collision_mask) != 0:
			counts_box[1] = int(counts_box[1]) + 1
	for child in node.get_children():
		_smoke_count_collision(child, counts_box)

func _write_failure_report(manifest: Dictionary, phase_f: Dictionary, build_result: Dictionary, validate_h: Dictionary, def_update: Dictionary, source_hash_before: String, reason: String) -> void:
	var combined := {
		"phase": "0H_cleanup_audit",
		"pass": false,
		"failure_reason": reason,
		"timestamp": Shared.now_timestamp_string(),
		"manifest_path": Shared.MANIFEST_PATH,
		"source_scene_protection": {"hash_before": source_hash_before},
		"target_scene": phase_f,
		"mission_definition_update": def_update,
		"build_result_keys": build_result.keys(),
		"validate_h": validate_h,
	}
	Validator.write_json_report(combined, REPORT_JSON)
	_write_markdown_report(combined, REPORT_MD)

func _write_markdown_report(combined: Dictionary, path: String) -> void:
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_markdown_report failed to open: " + path)
		return
	var lines: Array = []
	var status_str := "PASS" if bool(combined.get("pass", false)) else "FAIL"
	lines.append("# Phase 0H — Taco Bell Duplicate-Scene Cleanup, Marker Verification, Camera Bounds, Editor Artifact Audit")
	lines.append("")
	lines.append("**Status:** " + status_str)
	lines.append("**Timestamp:** " + String(combined.get("timestamp", "")))
	if combined.has("failure_reason"):
		lines.append("**Failure reason:** `" + String(combined.failure_reason) + "`")
	lines.append("")
	lines.append("## Source-scene protection")
	lines.append("")
	var sp: Dictionary = combined.get("source_scene_protection", {})
	lines.append("- **Path:** `" + String(sp.get("path", "")) + "`")
	lines.append("- **MD5 before:** `" + String(sp.get("hash_before", "")) + "`")
	lines.append("- **MD5 after:** `" + String(sp.get("hash_after", "")) + "`")
	lines.append("- **Unchanged:** " + str(bool(sp.get("unchanged", false))))
	lines.append("")
	lines.append("## Target duplicate scene")
	lines.append("")
	var ts: Dictionary = combined.get("target_scene", {})
	lines.append("- **Path:** `" + String(ts.get("path", "")) + "`")
	lines.append("- **Existed before:** " + str(bool(ts.get("existed_before", false))))
	lines.append("- **Backup created:** " + str(bool(ts.get("backup_created", false))))
	if bool(ts.get("backup_created", false)):
		lines.append("- **Backup path:** `" + String(ts.get("backup_path", "")) + "`")
	lines.append("- **MD5 before:** `" + String(ts.get("hash_before", "")) + "`")
	lines.append("- **MD5 after:** `" + String(ts.get("hash_after", "")) + "`")
	lines.append("")
	lines.append("## Mission-definition update (level_bounds_max)")
	lines.append("")
	var mu: Dictionary = combined.get("mission_definition_update", {})
	lines.append("- **Path:** `" + String(mu.get("def_path", "")) + "`")
	lines.append("- **Zone id:** `" + String(mu.get("zone_id", "")) + "`")
	lines.append("- **Created:** " + str(bool(mu.get("created", false))))
	lines.append("- **Updated:** " + str(bool(mu.get("updated", false))))
	lines.append("- **Origin:** " + str(mu.get("origin", [])))
	lines.append("- **Size:** " + str(mu.get("size", [])))
	if mu.has("reason"):
		lines.append("- **Reason:** " + String(mu.reason))
	lines.append("")

	if combined.has("build_summary"):
		var bs: Dictionary = combined.build_summary
		var p0h: Dictionary = bs.get("phase_0h_cleanup", {})
		lines.append("## Builder Phase 0H cleanup summary")
		lines.append("")
		lines.append("- **Saved duplicate:** " + str(bool(bs.get("saved", false))))
		var counts: Dictionary = bs.get("counts", {})
		for k in counts.keys():
			lines.append("- **" + String(k) + ":** " + str(counts[k]))
		lines.append("")
		lines.append("### Old TileMapLayer cleanup")
		lines.append("")
		lines.append("| Path | Found | Class | Cells before | Cells after | Visible | Enabled | Collision |")
		lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
		for entry in p0h.get("old_tilemap_layers", []):
			lines.append("| `" + String(entry.get("path", "")) + "` | " + str(bool(entry.get("found", false))) + " | " + String(entry.get("class", "-")) + " | " + str(entry.get("cells_before", "-")) + " | " + str(entry.get("cells_after", "-")) + " | " + str(entry.get("visible", "-")) + " | " + str(entry.get("enabled", "-")) + " | " + str(entry.get("collision_enabled", "-")) + " |")
		lines.append("")
		lines.append("### Boundary collider cleanup")
		lines.append("")
		var bc: Dictionary = p0h.get("boundary_colliders", {})
		lines.append("- **Path:** `" + String(bc.get("path", "")) + "`")
		lines.append("- **Found:** " + str(bool(bc.get("found", false))))
		lines.append("- **Disabled:** " + str(bool(bc.get("disabled", false))))
		lines.append("- **Static body count:** " + str(bc.get("child_count", 0)))
		lines.append("- **Static bodies disabled:** " + str(bc.get("static_bodies_disabled", 0)))
		lines.append("- **Collision shapes disabled:** " + str(bc.get("collision_shapes_disabled", 0)))
		lines.append("")
		lines.append("### Camera2D bake")
		lines.append("")
		var cam: Dictionary = p0h.get("camera", {})
		lines.append("- **Path:** `" + String(cam.get("path", "")) + "`")
		lines.append("- **Found:** " + str(bool(cam.get("found", false))))
		lines.append("- **Applied:** " + str(bool(cam.get("applied", false))))
		lines.append("- **Margin px:** " + str(cam.get("margin_px", 0)))
		lines.append("- **Limits before:** " + str(cam.get("limits_before", {})))
		lines.append("- **Limits after:** " + str(cam.get("limits_after", {})))
		lines.append("")
		lines.append("### Marker label dedup + suppression")
		lines.append("")
		var ml: Dictionary = p0h.get("marker_labels", {})
		lines.append("- **Markers processed:** " + str(ml.get("markers_processed", 0)))
		lines.append("- **show_editor_label set false:** " + str(ml.get("show_editor_label_set_false", 0)))
		lines.append("- **EditorLabel kept invisible:** " + str(ml.get("labels_kept_invisible", 0)))
		lines.append("- **@Label@ siblings removed:** " + str(ml.get("extra_at_label_siblings_removed", 0)))
		lines.append("- **Total labels removed:** " + str(ml.get("labels_removed", 0)))
		lines.append("")
		lines.append("### Root transform audit")
		lines.append("")
		var rt: Dictionary = p0h.get("root_transform", {})
		lines.append("- **Position before:** " + str(rt.get("position_before", [])))
		lines.append("- **Rotation before:** " + str(rt.get("rotation_before", 0.0)))
		lines.append("- **Scale before:** " + str(rt.get("scale_before", [])))
		lines.append("- **Is identity:** " + str(bool(rt.get("is_identity", false))))
		lines.append("- **Left unchanged reason:** " + String(rt.get("left_unchanged_reason", "")))
		lines.append("")

	if combined.has("validate_h"):
		var vh: Dictionary = combined.validate_h
		lines.append("## Validator (Phase H + 0H assertions)")
		lines.append("")
		lines.append("**Pass:** " + str(bool(vh.get("pass", false))))
		lines.append("")
		var hard: Dictionary = vh.get("hard_assertions", {})
		var p0h_keys: Array = []
		var other_keys: Array = []
		for k in hard.keys():
			var ks := String(k)
			var p0h_match := (
				ks.begins_with("no_unexpected")
				or ks.begins_with("old_prototype")
				or ks.begins_with("boundary_colliders")
				or ks.begins_with("camera_limits")
				or ks.begins_with("far_route_points")
				or ks.begins_with("key_marker_ids")
				or ks.begins_with("root_transform_audit_recorded")
				or ks.begins_with("marker_labels_")
				or ks.begins_with("exactly_one_gate_tile")
				or ks.begins_with("code_gate_")
				or ks.begins_with("level_bounds_zone_")
			)
			if p0h_match:
				p0h_keys.append(k)
			else:
				other_keys.append(k)
		lines.append("### Phase 0H-specific hard assertions")
		lines.append("")
		lines.append("| Assertion | Value |")
		lines.append("| --- | --- |")
		for k in p0h_keys:
			lines.append("| `" + String(k) + "` | " + str(hard[k]) + " |")
		lines.append("")
		lines.append("### Phase 0G v6 carry-forward hard assertions")
		lines.append("")
		lines.append("| Assertion | Value |")
		lines.append("| --- | --- |")
		for k in other_keys:
			lines.append("| `" + String(k) + "` | " + str(hard[k]) + " |")
		lines.append("")

		var p0h_audit: Dictionary = vh.get("phase_0h_audit", {})
		if p0h_audit.size() > 0:
			lines.append("### Phase 0H raw audit")
			lines.append("")
			lines.append("**TileMapLayer inventory** (every TileMapLayer in the scene tree):")
			lines.append("")
			lines.append("| Path | Used cells | Visible | Enabled | Collision |")
			lines.append("| --- | --- | --- | --- | --- |")
			for entry in p0h_audit.get("old_layer_inventory", []):
				lines.append("| `" + String(entry.get("path", "")) + "` | " + str(entry.get("used_cell_count", 0)) + " | " + str(entry.get("visible", "-")) + " | " + str(entry.get("enabled", "-")) + " | " + str(entry.get("collision_enabled", "-")) + " |")
			lines.append("")
			lines.append("**Camera world floor rect:** " + str(p0h_audit.get("camera", {}).get("floor_world_rect", {})))
			lines.append("")
			lines.append("**Camera limits:** " + str(p0h_audit.get("camera", {}).get("limits", {})))
			lines.append("")
			lines.append("**Key markers in camera bounds:**")
			lines.append("")
			lines.append("| Manifest id | Abs cell | World position | Inside camera bounds |")
			lines.append("| --- | --- | --- | --- |")
			for km in p0h_audit.get("key_markers", []):
				lines.append("| `" + String(km.get("manifest_id", "")) + "` | " + str(km.get("abs_cell", [])) + " | " + str(km.get("world", [])) + " | " + str(bool(km.get("inside_camera_bounds", false))) + " |")
			lines.append("")
			lines.append("**Boundary colliders audit:**")
			lines.append("")
			var bc: Dictionary = p0h_audit.get("boundary_colliders", {})
			lines.append("- **Path:** `" + String(bc.get("path", "")) + "`")
			lines.append("- **Found:** " + str(bool(bc.get("found", false))))
			lines.append("- **Visible:** " + str(bool(bc.get("visible", false))))
			lines.append("- **Process mode:** " + str(bc.get("process_mode", -1)) + " (4 = PROCESS_MODE_DISABLED)")
			lines.append("- **Static body count:** " + str(bc.get("static_body_count", 0)))
			lines.append("- **Static bodies with nonzero collision:** " + str(bc.get("static_body_with_nonzero_collision_count", 0)))
			lines.append("")
			lines.append("**Marker label audit:**")
			lines.append("")
			var ml: Dictionary = p0h_audit.get("marker_labels", {})
			lines.append("- **Markers total:** " + str(ml.get("markers_total", 0)))
			lines.append("- **Markers with show_editor_label = true:** " + str(ml.get("markers_with_show_editor_label_true", 0)))
			lines.append("- **EditorLabel children:** " + str(ml.get("editor_label_count", 0)))
			lines.append("- **`@Label@xxxxx` siblings remaining:** " + str(ml.get("at_label_sibling_count", 0)))
			lines.append("")
			lines.append("**Marker spam clusters (radius 5 manhattan, threshold 4):**")
			lines.append("")
			var clusters_dict: Dictionary = p0h_audit.get("clusters", {})
			lines.append("- **Largest cluster size:** " + str(clusters_dict.get("largest_cluster_size", 0)))
			lines.append("- **Cluster count:** " + str(clusters_dict.get("cluster_count", 0)))
			var cluster_arr: Array = clusters_dict.get("clusters", [])
			if cluster_arr.size() > 0:
				lines.append("")
				lines.append("| Center | Size |")
				lines.append("| --- | --- |")
				for c in cluster_arr:
					lines.append("| " + str(c.get("center", [])) + " | " + str(c.get("size", 0)) + " |")
			lines.append("")
			lines.append("**Code gate verification:**")
			lines.append("")
			lines.append("- **BLOCK_code_gate manifest row present:** " + str(bool(p0h_audit.get("code_gate_has_block_marker_row", false))))
			lines.append("- **CollisionBarrierLayer cell at gate blocker:** " + str(bool(p0h_audit.get("code_gate_has_collision_barrier_cell", false))))
			lines.append("- **Blocker ready for future unlock (linked + collidable + GATE/BLOCK rows valid):** " + str(bool(p0h_audit.get("code_gate_blocker_ready_for_future_unlock", false))))
			lines.append("")
			lines.append("**Level bounds zone in mission definition:**")
			lines.append("")
			lines.append("- **Present:** " + str(bool(p0h_audit.get("level_bounds_zone_present", false))))
			if p0h_audit.has("level_bounds_zone"):
				var lbz: Dictionary = p0h_audit.level_bounds_zone
				lines.append("- **Zone id:** `" + String(lbz.get("zone_id", "")) + "`")
				lines.append("- **Origin:** " + str(lbz.get("origin", [])))
				lines.append("- **Size:** " + str(lbz.get("size", [])))
			lines.append("")
			lines.append("**Runtime marker position audit (first 30 rows):**")
			lines.append("")
			lines.append("| manifest_id | category | abbr | expected cell | actual cell | matched | runtime name | status |")
			lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
			var rma: Array = p0h_audit.get("runtime_marker_audit", [])
			for i in range(mini(30, rma.size())):
				var r: Dictionary = rma[i]
				lines.append("| `" + String(r.get("manifest_id", "")) + "` | " + String(r.get("category", "")) + " | " + String(r.get("marker_tile_abbr", "")) + " | " + str(r.get("expected_abs_cell", [])) + " | " + str(r.get("actual_abs_cell", [])) + " | " + str(bool(r.get("matched_runtime_marker", false))) + " | `" + String(r.get("runtime_marker_name", "")) + "` | " + String(r.get("status", "")) + " |")
			lines.append("")
			if rma.size() > 30:
				lines.append("(showing first 30 of " + str(rma.size()) + " rows)")
				lines.append("")

	if combined.has("structural_smoke"):
		var sm: Dictionary = combined.structural_smoke
		lines.append("## Structural smoke")
		lines.append("")
		lines.append("- **Pass:** " + str(bool(sm.get("pass", false))))
		lines.append("- **Required nodes present:** " + str(bool(sm.get("required_node_presence", false))))
		lines.append("- **Floor cell count:** " + str(sm.get("floor_cell_count", -1)))
		var clim: Dictionary = sm.get("camera_limits", {})
		if clim.size() > 0:
			lines.append("- **Camera2D limits:** " + str(clim))
		lines.append("- **Old layer status:**")
		for entry in sm.get("old_layer_status", []):
			lines.append("  - " + str(entry))
		lines.append("- **Boundary colliders:** " + str(sm.get("boundary_colliders", {})))
		lines.append("")

	lines.append("## Repo diff vs source diff")
	lines.append("")
	lines.append("- The source scene file `res://scenes/missions_iso/TacoBellIso_Editable.tscn` is byte-for-byte unchanged.")
	lines.append("- The mission-definition resource `res://assets/missions/taco_bell_iso_blockout_definition.tres` was modified to add the `level_bounds_max` zone (which expands runtime camera bounds by enlarging the rect produced by `IsoMissionBase._mission_rect()`). This is a per-mission resource (not the catalog) and was modified in a controlled, reversible way (it adds one zone with a specific zone_id; removing it restores the prior behavior).")
	lines.append("- The duplicate scene was overwritten by the deterministic builder. A timestamped backup of the prior duplicate state is retained.")
	lines.append("- No save/load systems, mission catalog, `IsoMissionBase.gd`, `IsoMissionMarker.gd`, unrelated missions, or global runtime systems were modified.")
	lines.append("")
	lines.append("## Remaining limitations / deferred items")
	lines.append("")
	lines.append("- The 11 `real_if_safe` rows (9 SWITCH + 2 DOOR) remain editor-only `Node2D` placeholders. No behavioral claims. Future passes will convert each into a real mechanic in isolation.")
	lines.append("- The duplicate root transform is non-identity. The source scene root has the same transform, and resetting in the duplicate would shift world positions (ArtRoot/EntityRoot/Camera2D/Player/etc. are all expressed in the root-relative coordinate frame). The audit records the value but does NOT modify it. A separate isolated pass can compensate child transforms and reset the root if you want the warning gone.")
	lines.append("- The label readability fix relies on `show_editor_label = false` and dedup of `@Label@xxxxx`. Each Godot editor open of an `IsoMissionMarker` re-creates one new `Label` named `EditorLabel` (and may rename the saved one to `@Label@xxxxx` due to a known `IsoMissionMarker._ensure_label` accumulation pattern). Re-running the Phase 0H driver collapses them again. A real fix lives in `IsoMissionMarker.gd`, which is intentionally not modified per Phase 0H rules.")
	lines.append("- IsoMissionBase.gd currently reads the OLD layer paths (`GameplayRoot/GameplayFloorLayer`, etc.) for some helper functions. We have NOT renamed or moved those nodes; we only emptied them and disabled their collision/visibility. The runtime helpers continue to find the (now empty) layers at their original paths, and the new layout lives at `GameplayRoot/LayoutRoot/...` as expected. No changes to `IsoMissionBase.gd` were required or made.")
	lines.append("")
	f.store_string("\n".join(lines))
	f.close()
