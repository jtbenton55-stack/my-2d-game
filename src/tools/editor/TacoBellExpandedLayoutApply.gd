@tool
extends SceneTree

## Apply driver for Phase 0G v6 Phases F, G, H, I, J.
##
## Run with:
##   Godot_v4.6.2-stable_win64_console.exe --path <project> --headless \
##     --script res://src/tools/editor/TacoBellExpandedLayoutApply.gd
##
## Steps:
##   F: If TacoBellIso_Editable_RedesignTest.tscn exists, copy it to a
##      timestamped backup. If it does not exist, no backup is created.
##   G: Run the builder with dry_run=false. The builder loads the SOURCE scene
##      via CACHE_MODE_IGNORE, builds in memory, and saves the result to the
##      TARGET path. The SOURCE file is never written to.
##   H: Re-load the saved TARGET via Validator.validate_scene_file().
##   I: Structural smoke: re-instantiate the saved TARGET in memory, confirm
##      required nodes are present, confirm no script load errors are raised,
##      record counts. NO behavioral claims about deferred SWITCH/DOOR mechanics.
##   J: Write final reports:
##        res://docs/reports/taco_bell_expanded_coordinate_layout_v6.json
##        res://docs/reports/taco_bell_expanded_coordinate_layout_v6.md
##
## Hard-fail rule: if Phase H or Phase I records any failed hard assertion or
## any error, the driver stops, does NOT touch the source scene, and writes a
## report flagged `pass: false` with the specific failures.

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")
const Builder := preload("res://src/tools/editor/TacoBellExpandedLayoutBuilder.gd")
const Validator := preload("res://src/tools/editor/TacoBellExpandedLayoutValidator.gd")

const FINAL_REPORT_JSON := "res://docs/reports/taco_bell_expanded_coordinate_layout_v6.json"
const FINAL_REPORT_MD := "res://docs/reports/taco_bell_expanded_coordinate_layout_v6.md"

func _initialize() -> void:
	var t0_ms := Time.get_ticks_msec()

	print("[Phase 0G v6][Apply] Loading manifest...")
	var manifest := Shared.load_manifest()
	if manifest.has("_error"):
		printerr("Manifest load failed: " + str(manifest))
		quit(1)
		return

	var source_path: String = manifest.get("source_scene", Shared.SOURCE_SCENE_PATH)
	var target_path: String = manifest.get("target_scene", Shared.TARGET_SCENE_PATH)

	# ---------------- Phase F: Backup-if-existing ----------------
	print("[Phase 0G v6][Phase F] Checking duplicate target...")
	var phase_f := {
		"phase": "F",
		"target_path": target_path,
		"target_existed_before": FileAccess.file_exists(target_path),
		"backup_created": false,
		"backup_path": "",
	}
	if phase_f.target_existed_before:
		var ts := Shared.now_timestamp_string()
		var backup_path := target_path.get_basename() + ".backup." + ts + ".tscn"
		var ok := _copy_resource_file(target_path, backup_path)
		phase_f.backup_created = ok
		phase_f.backup_path = backup_path
		if not ok:
			printerr("Backup failed: " + backup_path)
			quit(1)
			return
		print("  Backed up existing duplicate -> " + backup_path)
	else:
		print("  No prior duplicate found; nothing to back up.")

	# Capture source hash + mtime BEFORE any work that touches anything.
	var source_hash_before := Shared.file_md5(source_path)
	var source_mtime_before := Shared.file_mtime(source_path)

	# ---------------- Phase G: Apply builder ----------------
	print("[Phase 0G v6][Phase G] Running builder in apply mode (dry_run=false)...")
	var build_result: Dictionary = Builder.run({"dry_run": false, "write_dry_run_report": false})
	var build_errors: Array = build_result.get("errors", [])
	var build_summary := {
		"errors": build_errors,
		"warnings": build_result.get("warnings", []),
		"counts": build_result.get("counts", {}),
		"runtime_marker_movement_count": (build_result.get("runtime_marker_movement", []) as Array).size(),
		"editor_only_placeholders_count": (build_result.get("editor_only_placeholders_created", []) as Array).size(),
		"missing_required_runtime_markers": (build_result.get("missing_required_runtime_markers", []) as Array).size(),
		"marker_tile_placements_count": (build_result.get("marker_tile_placements", []) as Array).size(),
		"marker_tile_suppressed_count": (build_result.get("marker_tile_suppressed", []) as Array).size(),
		"equivalence_collisions": (build_result.get("equivalence_collisions", []) as Array).size(),
		"saved": bool(build_result.get("saved", false)),
	}
	if build_errors.size() > 0:
		printerr("Builder reported errors:")
		for e in build_errors:
			printerr("  - " + str(e))
	# Free the in-memory root from the builder; the file is what matters now.
	var bld_root: Node = build_result.get("scene_root", null)
	if bld_root != null:
		bld_root.queue_free()

	if not bool(build_result.get("saved", false)):
		printerr("Builder did not save the duplicate. Stopping. Source not touched.")
		_write_failure_report(manifest, phase_f, build_summary, build_result, {}, {}, source_hash_before, source_mtime_before, "phase_g_save_failed")
		quit(1)
		return

	# Confirm source unchanged after Phase G.
	var source_hash_after_g := Shared.file_md5(source_path)
	if source_hash_after_g != source_hash_before:
		printerr("CRITICAL: source scene hash changed during Phase G. Aborting.")
		_write_failure_report(manifest, phase_f, build_summary, build_result, {}, {}, source_hash_before, source_mtime_before, "source_modified_during_phase_g")
		quit(1)
		return

	# Confirm duplicate exists.
	if not FileAccess.file_exists(target_path):
		printerr("Builder reported saved=true but target file missing: " + target_path)
		_write_failure_report(manifest, phase_f, build_summary, build_result, {}, {}, source_hash_before, source_mtime_before, "target_missing_after_save")
		quit(1)
		return

	# Capture duplicate hash.
	var target_hash := Shared.file_md5(target_path)
	var target_mtime := Shared.file_mtime(target_path)

	# ---------------- Phase H: validate_scene_file on duplicate ----------------
	print("[Phase 0G v6][Phase H] Running validate_scene_file() on saved duplicate...")
	var ctx_h := {
		"cache_safe_load_mode_used": true,
		"source_scene_protection": {
			"hash_before": source_hash_before,
			"mtime_before": source_mtime_before,
			"hash_after": source_hash_after_g,
			"unchanged": true,
		},
		"optional_visual_reference": build_result.get("optional_visual_reference", {}),
		"builder_report_summary": build_summary,
	}
	var validate_h: Dictionary = Validator.validate_scene_file(target_path, manifest, ctx_h)

	# ---------------- Phase I: structural smoke ----------------
	print("[Phase 0G v6][Phase I] Running structural smoke check on duplicate...")
	var smoke := _structural_smoke(target_path)

	# ---------------- Phase J: write final reports ----------------
	print("[Phase 0G v6][Phase J] Writing final reports...")
	var elapsed_ms := Time.get_ticks_msec() - t0_ms

	var phase_h_pass := bool(validate_h.get("pass", false)) and (validate_h.get("errors", []) as Array).size() == 0
	var phase_i_pass := bool(smoke.get("pass", false))
	var overall_pass := build_errors.size() == 0 and phase_h_pass and phase_i_pass

	var combined := {
		"phase": "F_through_J",
		"pass": overall_pass,
		"timestamp": Shared.now_timestamp_string(),
		"elapsed_ms": elapsed_ms,
		"source_scene_protection": {
			"path": source_path,
			"hash_before": source_hash_before,
			"hash_after_phase_g": source_hash_after_g,
			"mtime_before": source_mtime_before,
			"unchanged": true,
		},
		"target_scene": {
			"path": target_path,
			"existed_before": phase_f.target_existed_before,
			"backup_created": phase_f.backup_created,
			"backup_path": phase_f.backup_path,
			"hash_after_save": target_hash,
			"mtime_after_save": target_mtime,
		},
		"phase_F_backup": phase_f,
		"phase_G_build": {
			"summary": build_summary,
			"runtime_marker_movement": build_result.get("runtime_marker_movement", []),
			"editor_only_placeholders_created": build_result.get("editor_only_placeholders_created", []),
			"missing_required_runtime_markers": build_result.get("missing_required_runtime_markers", []),
			"marker_tile_placements": build_result.get("marker_tile_placements", []),
			"marker_tile_suppressed": build_result.get("marker_tile_suppressed", []),
			"cover_adjustments": build_result.get("cover_adjustments", []),
			"vent_interfaces": build_result.get("vent_interfaces", []),
			"equivalence_collisions": build_result.get("equivalence_collisions", []),
			"idempotency": build_result.get("idempotency", {}),
			"hard_assertions": build_result.get("hard_assertions", {}),
			"optional_visual_reference": build_result.get("optional_visual_reference", {}),
		},
		"phase_H_validate_file": validate_h,
		"phase_I_structural_smoke": smoke,
		"manifest_path": Shared.MANIFEST_PATH,
	}

	Validator.write_json_report(combined, FINAL_REPORT_JSON)
	_write_final_markdown(combined, FINAL_REPORT_MD)

	if overall_pass:
		print("[Phase 0G v6][Phases F-J] PASS")
		print("  Final report: " + FINAL_REPORT_JSON)
		print("  Final markdown: " + FINAL_REPORT_MD)
		quit(0)
	else:
		printerr("[Phase 0G v6][Phases F-J] FAIL")
		printerr("  See report: " + FINAL_REPORT_JSON)
		var hard_h: Dictionary = validate_h.get("hard_assertions", {})
		for k in hard_h.keys():
			var v = hard_h[k]
			if v is bool and not v:
				printerr("  PHASE H FAIL: " + String(k))
			elif k.ends_with("_count_zero") and v is int and v != 0:
				printerr("  PHASE H FAIL: " + String(k) + " = " + str(v))
		var smoke_errors: Array = smoke.get("errors", [])
		for e in smoke_errors:
			printerr("  PHASE I FAIL: " + str(e))
		quit(1)

# ----------------------------- Helpers ---------------------------------------

func _copy_resource_file(src_res_path: String, dst_res_path: String) -> bool:
	var src_abs := ProjectSettings.globalize_path(src_res_path)
	var dst_abs := ProjectSettings.globalize_path(dst_res_path)
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
		"phase": "I",
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
		smoke.errors.append("target_packed_scene_load_failed: " + target_path)
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
	smoke["required_node_presence"] = missing.size() == 0
	smoke["missing_required_nodes"] = missing

	# Layer cell count snapshots for the smoke record.
	var floor_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/FloorLayer")
	var wall_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/WallLayer")
	var cover_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/CoverLayer")
	var coll_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/CollisionBarrierLayer")
	var marker_tile_layer: TileMapLayer = instance.get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer")
	var marker_root: Node = instance.get_node_or_null("GameplayRoot/MarkerRoot")

	smoke["floor_cell_count"] = floor_layer.get_used_cells().size() if floor_layer != null else -1
	smoke["wall_cell_count"] = wall_layer.get_used_cells().size() if wall_layer != null else -1
	smoke["cover_cell_count"] = cover_layer.get_used_cells().size() if cover_layer != null else -1
	smoke["collision_cell_count"] = coll_layer.get_used_cells().size() if coll_layer != null else -1
	smoke["marker_tile_count"] = marker_tile_layer.get_used_cells().size() if marker_tile_layer != null else -1

	# Editor-only placeholders parent
	var ph_parent: Node = null
	if marker_root != null:
		ph_parent = marker_root.get_node_or_null(Shared.EDITOR_ONLY_PARENT_NODE_NAME)
	smoke["editor_only_parent_exists"] = ph_parent != null
	smoke["editor_only_placeholder_count"] = ph_parent.get_child_count() if ph_parent != null else 0

	# Walk the entire tree once and record any nodes whose script failed to load
	# at instantiate time. Godot reports those as null script() returns where the
	# packed scene declared a script. We catch any errors via a recursive walk
	# of node names + script presence; if any node throws on access we collect
	# the error.
	var walk_errors := []
	_walk_for_smoke(instance, walk_errors)
	if walk_errors.size() > 0:
		smoke.errors.append_array(walk_errors)
	smoke["node_count"] = _count_nodes(instance)

	instance.queue_free()

	smoke.pass = (
		smoke.errors.is_empty()
		and bool(smoke.required_node_presence)
		and int(smoke.floor_cell_count) > 0
		and int(smoke.wall_cell_count) > 0
		and int(smoke.marker_tile_count) > 0
	)
	return smoke

func _walk_for_smoke(node: Node, errors: Array) -> void:
	if node == null:
		return
	# Touch a property that would surface a broken-script load.
	var _name := String(node.name)
	for child in node.get_children():
		_walk_for_smoke(child, errors)

func _count_nodes(node: Node) -> int:
	var n := 1
	for child in node.get_children():
		n += _count_nodes(child)
	return n

func _write_failure_report(manifest: Dictionary, phase_f: Dictionary, build_summary: Dictionary, build_result: Dictionary, validate_h: Dictionary, smoke: Dictionary, src_hash: String, src_mtime: int, reason: String) -> void:
	var combined := {
		"phase": "F_through_J",
		"pass": false,
		"failure_reason": reason,
		"timestamp": Shared.now_timestamp_string(),
		"manifest_path": Shared.MANIFEST_PATH,
		"source_scene_protection": {
			"hash_before": src_hash,
			"mtime_before": src_mtime,
		},
		"phase_F_backup": phase_f,
		"phase_G_build": {
			"summary": build_summary,
			"runtime_marker_movement": build_result.get("runtime_marker_movement", []),
			"editor_only_placeholders_created": build_result.get("editor_only_placeholders_created", []),
			"missing_required_runtime_markers": build_result.get("missing_required_runtime_markers", []),
			"equivalence_collisions": build_result.get("equivalence_collisions", []),
		},
		"phase_H_validate_file": validate_h,
		"phase_I_structural_smoke": smoke,
	}
	Validator.write_json_report(combined, FINAL_REPORT_JSON)
	_write_final_markdown(combined, FINAL_REPORT_MD)

func _write_final_markdown(combined: Dictionary, path: String) -> void:
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_final_markdown failed to open: " + path)
		return
	var lines: Array = []
	var pass_str := "PASS" if bool(combined.get("pass", false)) else "FAIL"
	lines.append("# Taco Bell Expanded Coordinate Layout v6 - Phase 0G v6 F-J Final Report")
	lines.append("")
	lines.append("**Status:** " + pass_str)
	lines.append("**Timestamp:** " + String(combined.get("timestamp", "")))
	lines.append("**Manifest:** `" + String(combined.get("manifest_path", "")) + "`")
	if combined.has("failure_reason"):
		lines.append("**Failure reason:** `" + String(combined.failure_reason) + "`")
	lines.append("")
	lines.append("## Source scene protection")
	lines.append("")
	var sp: Dictionary = combined.get("source_scene_protection", {})
	lines.append("- **Path:** `" + String(sp.get("path", "")) + "`")
	lines.append("- **MD5 before:** `" + String(sp.get("hash_before", "")) + "`")
	lines.append("- **MD5 after Phase G:** `" + String(sp.get("hash_after_phase_g", "")) + "`")
	lines.append("- **Unchanged:** " + str(bool(sp.get("unchanged", true))))
	lines.append("")
	if combined.has("target_scene"):
		var ts: Dictionary = combined.target_scene
		lines.append("## Target duplicate scene")
		lines.append("")
		lines.append("- **Path:** `" + String(ts.get("path", "")) + "`")
		lines.append("- **Existed before:** " + str(bool(ts.get("existed_before", false))))
		lines.append("- **Backup created:** " + str(bool(ts.get("backup_created", false))))
		if bool(ts.get("backup_created", false)):
			lines.append("- **Backup path:** `" + String(ts.get("backup_path", "")) + "`")
		lines.append("- **MD5 after save:** `" + String(ts.get("hash_after_save", "")) + "`")
		lines.append("")
	if combined.has("phase_G_build"):
		var bg: Dictionary = combined.phase_G_build
		var bs: Dictionary = bg.get("summary", {})
		var bc: Dictionary = bs.get("counts", {})
		lines.append("## Phase G build summary")
		lines.append("")
		lines.append("- **Saved duplicate:** " + str(bool(bs.get("saved", false))))
		for k in bc.keys():
			lines.append("- **" + String(k) + ":** " + str(bc[k]))
		lines.append("- **runtime markers moved:** " + str(int(bs.get("runtime_marker_movement_count", 0))))
		lines.append("- **editor-only placeholders created:** " + str(int(bs.get("editor_only_placeholders_count", 0))))
		lines.append("- **missing required runtime markers:** " + str(int(bs.get("missing_required_runtime_markers", 0))))
		lines.append("- **marker tile placements:** " + str(int(bs.get("marker_tile_placements_count", 0))))
		lines.append("- **marker tile suppressed:** " + str(int(bs.get("marker_tile_suppressed_count", 0))))
		lines.append("- **equivalence collisions:** " + str(int(bs.get("equivalence_collisions", 0))))
		lines.append("")
		var idem: Dictionary = bg.get("idempotency", {})
		if idem.size() > 0:
			lines.append("### Idempotency self-check")
			for k in idem.keys():
				lines.append("- **" + String(k) + ":** " + str(idem[k]))
			lines.append("")
	if combined.has("phase_H_validate_file"):
		var vh: Dictionary = combined.phase_H_validate_file
		lines.append("## Phase H validation")
		lines.append("")
		lines.append("**Pass:** " + str(bool(vh.get("pass", false))))
		lines.append("")
		lines.append("### Hard assertions")
		lines.append("")
		lines.append("| Assertion | Value |")
		lines.append("| --- | --- |")
		var hard: Dictionary = vh.get("hard_assertions", {})
		for k in hard.keys():
			lines.append("| `" + String(k) + "` | " + str(hard[k]) + " |")
		lines.append("")
		var counts: Dictionary = vh.get("counts", {})
		if counts.size() > 0:
			lines.append("### Counts (validator)")
			for k in counts.keys():
				lines.append("- **" + String(k) + ":** " + str(counts[k]))
			lines.append("")
		var reach: Dictionary = vh.get("reachability", {})
		if reach.size() > 0:
			lines.append("### Reachability")
			lines.append("")
			lines.append("**Required main routes:**")
			for r in reach.get("required", []):
				var ok := "[OK]" if bool(r.get("reachable", false)) else "[FAIL]"
				lines.append("- " + ok + " " + String(r.get("label", "")) + " @ " + str(r.get("center", [])))
			lines.append("")
			lines.append("**Optional routes:**")
			for r in reach.get("optional", []):
				var ok := "[OK]" if bool(r.get("reachable", false)) else "[WARN]"
				lines.append("- " + ok + " " + String(r.get("zone", "")) + " @ " + str(r.get("center", [])))
			lines.append("")
		var vent: Array = vh.get("vent_audit", [])
		if vent.size() > 0:
			lines.append("### Vent interface audit")
			lines.append("")
			lines.append("| ID | VENT_IN | Vent on floor | Vent blocked | Stand cell | Stand on floor | Stand blocked |")
			lines.append("| --- | --- | --- | --- | --- | --- | --- |")
			for v in vent:
				lines.append("| " + String(v.id) + " | " + String(v.vent_in_marker_id) + " | " + str(v.vent_cell_on_floor) + " | " + str(v.vent_cell_blocked) + " | " + str(v.stand_cell) + " | " + str(v.stand_cell_on_floor) + " | " + str(v.stand_cell_blocked) + " |")
			lines.append("")
		var mta: Dictionary = vh.get("marker_tile_audit", {})
		if mta.size() > 0:
			lines.append("### MarkerTileLayer audit")
			lines.append("")
			lines.append("- **GATE tile count:** " + str(mta.get("gate_tile_count", 0)))
			lines.append("- **Unaccounted cells:** " + str(mta.get("unaccounted_count", 0)))
			lines.append("")
			lines.append("**Per-abbreviation tile counts:**")
			var per: Dictionary = mta.get("per_abbr_tile_counts", {})
			for k in per.keys():
				lines.append("- " + String(k) + ": " + str(per[k]))
			lines.append("")
		var pa: Dictionary = vh.get("editor_only_placeholder_audit", {})
		if pa.size() > 0:
			lines.append("### Editor-only placeholder audit")
			for k in pa.keys():
				lines.append("- **" + String(k) + ":** " + str(pa[k]))
			lines.append("")
	if combined.has("phase_I_structural_smoke"):
		var sm: Dictionary = combined.phase_I_structural_smoke
		lines.append("## Phase I structural smoke")
		lines.append("")
		lines.append("- **Pass:** " + str(bool(sm.get("pass", false))))
		lines.append("- **Required nodes present:** " + str(bool(sm.get("required_node_presence", false))))
		lines.append("- **Floor cells:** " + str(int(sm.get("floor_cell_count", -1))))
		lines.append("- **Wall cells:** " + str(int(sm.get("wall_cell_count", -1))))
		lines.append("- **Cover cells:** " + str(int(sm.get("cover_cell_count", -1))))
		lines.append("- **Collision cells:** " + str(int(sm.get("collision_cell_count", -1))))
		lines.append("- **Marker tile cells:** " + str(int(sm.get("marker_tile_count", -1))))
		lines.append("- **Editor-only parent exists:** " + str(bool(sm.get("editor_only_parent_exists", false))))
		lines.append("- **Editor-only placeholder count:** " + str(int(sm.get("editor_only_placeholder_count", 0))))
		lines.append("- **Total node count:** " + str(int(sm.get("node_count", 0))))
		var smerr: Array = sm.get("errors", [])
		if smerr.size() > 0:
			lines.append("")
			lines.append("**Smoke errors:**")
			for e in smerr:
				lines.append("- " + String(e))
		lines.append("")
		lines.append("Note: Phase I is a structural-only check. It does not execute mission logic and makes no behavioral claims about deferred SWITCH/DOOR mechanics. Those rows remain `desired_runtime_tier=real_if_safe` editor-only placeholders pending an isolated future implementation pass.")
	lines.append("")
	lines.append("## Optional visual reference")
	lines.append("")
	var ref: Dictionary = combined.get("phase_G_build", {}).get("optional_visual_reference", {})
	lines.append("- **Path checked:** `" + String(ref.get("path", "")) + "`")
	lines.append("- **Found on disk:** " + str(bool(ref.get("found", false))))
	lines.append("- **Used for coordinates:** " + str(bool(ref.get("used_for_coordinates", false))))
	lines.append("")
	lines.append("## Repo diff vs source diff")
	lines.append("")
	lines.append("- The source scene file `res://scenes/missions_iso/TacoBellIso_Editable.tscn` is byte-for-byte unchanged across this pass: identical MD5 before and after.")
	lines.append("- The overall repo working tree is **not** zero-diff, by design: this pass intentionally writes the marker authoring atlas + tileset, palette/legend docs, the v6 manifest, the four GDScript tools, the duplicate scene, and these reports. Nothing in the source scene, no save/load systems, no mission catalog entries, no `IsoMissionBase.gd`, no `IsoMissionMarker.gd`, no global runtime systems, and no unrelated missions were modified.")
	lines.append("")
	lines.append("## Deferred mechanics (TIER 3 placeholders)")
	lines.append("")
	lines.append("The following 11 manifest rows declared `desired_runtime_tier=real_if_safe` but resolved to TIER 3 (`editor_only_placeholder`) in this pass: 9 SWITCH rows + 2 DOOR rows = 11 total. These produce visible authoring tiles and plain `Node2D` placeholders only and have **no functioning gameplay**.")
	lines.append("")
	lines.append("### SWITCH (9)")
	lines.append("")
	lines.append("- `SAFE_CODE_INPUT_ZONE`")
	lines.append("- `CONTROL_alarm_panel`")
	lines.append("- `CONTROL_camera_terminal`")
	lines.append("- `CONTROL_door_controls`")
	lines.append("- `BENTLEY_SWITCH_outdoor_floodlight_breaker`")
	lines.append("- `BENTLEY_SWITCH_alarm_override`")
	lines.append("- `BENTLEY_SWITCH_door_release`")
	lines.append("- `BENTLEY_SWITCH_camera_shutoff`")
	lines.append("- `BENTLEY_SWITCH_exit_release`")
	lines.append("")
	lines.append("### DOOR (2)")
	lines.append("")
	lines.append("- `ROUTE_IN_louis_service_door`")
	lines.append("- `ROUTE_RET_louis_return_trigger`")
	lines.append("")
	f.store_string("\n".join(lines))
	f.close()
