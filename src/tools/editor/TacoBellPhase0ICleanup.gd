@tool
extends SceneTree
## Phase 0I — Runtime Truth Audit and Minimal Playability Fix driver.
##
## Orchestrates:
##   1. Backup of res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn.
##   2. Run TacoBellExpandedLayoutBuilder (now with Phase 13c Phase 0I cleanup).
##   3. Run TacoBellExpandedLayoutValidator.validate_scene_file() on the saved
##      duplicate.
##   4. Smoke-instantiate the saved scene into the live SceneTree to verify
##      runtime behavior:
##        - WallLayer.collision_enabled = true
##        - MarkerTileLayer.visible = false (after Phase0IAuthoringHider._ready())
##        - EditorOnlyPlaceholders.visible = false
##        - GateBlockers/BLOCK_code_gate StaticBody2D present + collides
##        - Phase0IRouteSafeguard node present
##        - Promoted collectibles present + interactable group
##   5. Write JSON + Markdown reports.
##   6. Write the human-readable map room guide.
##
## Source scene must remain byte-for-byte unchanged (asserted via MD5).

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")
const Builder := preload("res://src/tools/editor/TacoBellExpandedLayoutBuilder.gd")
const Validator := preload("res://src/tools/editor/TacoBellExpandedLayoutValidator.gd")

const REPORT_JSON := "res://docs/reports/taco_bell_phase_0i_runtime_truth_audit.json"
const REPORT_MD := "res://docs/reports/taco_bell_phase_0i_runtime_truth_audit.md"
const ROOM_GUIDE_MD := "res://docs/reports/taco_bell_generated_map_room_guide.md"

const SOURCE_PATH := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const TARGET_PATH := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"


func _initialize() -> void:
	print("[Phase 0I][Apply] Loading manifest...")
	var manifest_path := "res://assets/missions/layouts/taco_bell_expanded_layout_v6.json"
	var manifest: Dictionary = Shared.load_manifest(manifest_path)
	if manifest.is_empty():
		_emit_failure({}, "manifest_load_failed")
		quit(1)
		return

	var source_hash_before := Shared.file_md5(SOURCE_PATH)
	var target_hash_before := Shared.file_md5(TARGET_PATH) if FileAccess.file_exists(TARGET_PATH) else ""

	# Step 1: Backup existing duplicate.
	var backup_info := {"created": false, "path": "", "reason": ""}
	if FileAccess.file_exists(TARGET_PATH):
		var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
		var backup_path := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.phase0i_backup." + stamp + ".tscn"
		if _copy_resource_file(TARGET_PATH, backup_path):
			backup_info.created = true
			backup_info.path = backup_path
			print("  Backed up existing duplicate -> " + backup_path)
		else:
			backup_info.reason = "copy_failed_continuing"

	# Step 2: Run builder in apply mode (Phase 13c is included).
	print("[Phase 0I][Step 2] Running builder in apply mode (dry_run=false)...")
	var build_result: Dictionary = Builder.run({"dry_run": false, "write_dry_run_report": false})
	if build_result.errors.size() > 0:
		_emit_failure({
			"manifest": manifest,
			"build_result": build_result,
			"source_hash_before": source_hash_before,
		}, "builder_errors_present")
		# free instantiated scene_root if any
		if build_result.has("scene_root") and build_result.scene_root is Node:
			(build_result.scene_root as Node).queue_free()
		quit(1)
		return
	if build_result.has("scene_root") and build_result.scene_root is Node:
		(build_result.scene_root as Node).queue_free()
	var source_hash_mid := Shared.file_md5(SOURCE_PATH)
	if source_hash_mid != source_hash_before:
		_emit_failure({
			"manifest": manifest,
			"build_result": build_result,
			"source_hash_before": source_hash_before,
			"source_hash_mid": source_hash_mid,
		}, "source_scene_modified_during_build_should_never_happen")
		quit(1)
		return

	# Step 3: Validator on saved duplicate.
	print("[Phase 0I][Step 3] Running validate_scene_file()...")
	var ctx := {"manifest_path": manifest_path}
	var validate_i: Dictionary = Validator.validate_scene_file(TARGET_PATH, manifest, ctx)

	# Step 4: Structural + runtime smoke (instantiates scene live in this SceneTree).
	print("[Phase 0I][Step 4] Structural + runtime smoke check...")
	var smoke := await _structural_runtime_smoke(TARGET_PATH)

	# Step 5: Write room guide.
	print("[Phase 0I][Step 5] Writing room guide...")
	_write_room_guide(manifest, ROOM_GUIDE_MD, build_result)

	# Step 6: Write final reports.
	print("[Phase 0I][Step 6] Writing final Phase 0I audit reports...")
	var source_hash_after := Shared.file_md5(SOURCE_PATH)
	var target_hash_after := Shared.file_md5(TARGET_PATH)
	var combined := {
		"phase": "0I_runtime_truth_audit",
		"timestamp": Time.get_datetime_string_from_system(),
		"source_scene_protection": {
			"path": SOURCE_PATH,
			"hash_before": source_hash_before,
			"hash_after": source_hash_after,
			"unchanged": source_hash_before == source_hash_after,
		},
		"target_scene": {
			"path": TARGET_PATH,
			"existed_before": target_hash_before != "",
			"hash_before": target_hash_before,
			"hash_after": target_hash_after,
			"backup_created": backup_info.created,
			"backup_path": backup_info.path,
		},
		"build_result": build_result,
		"validate_i": validate_i,
		"smoke": smoke,
		"room_guide_written_to": ROOM_GUIDE_MD,
	}

	var validate_pass := bool(validate_i.get("pass", false))
	var smoke_pass := bool(smoke.get("pass", false))
	var source_unchanged: bool = bool(combined.source_scene_protection.unchanged)
	combined.pass = validate_pass and smoke_pass and source_unchanged
	combined.pass_breakdown = {
		"validate_pass": validate_pass,
		"smoke_pass": smoke_pass,
		"source_unchanged": source_unchanged,
	}

	Validator.write_json_report(combined, REPORT_JSON)
	_write_markdown_report(combined, REPORT_MD)

	if combined.pass:
		print("[Phase 0I] PASS")
	else:
		print("[Phase 0I] FAIL")
		print("  validate_pass=", validate_pass, " smoke_pass=", smoke_pass, " source_unchanged=", source_unchanged)
	print("  Final report: " + REPORT_JSON)
	print("  Final markdown: " + REPORT_MD)
	print("  Room guide: " + ROOM_GUIDE_MD)

	quit(0 if combined.pass else 1)


func _emit_failure(ctx: Dictionary, reason: String) -> void:
	var combined := {
		"phase": "0I_runtime_truth_audit",
		"pass": false,
		"failure_reason": reason,
		"context_keys": ctx.keys(),
	}
	Validator.write_json_report(combined, REPORT_JSON)
	print("[Phase 0I] FAIL: " + reason)


func _copy_resource_file(src_res_path: String, dst_res_path: String) -> bool:
	var src := FileAccess.open(src_res_path, FileAccess.READ)
	if src == null:
		return false
	var bytes := src.get_buffer(int(src.get_length()))
	src.close()
	var dst := FileAccess.open(dst_res_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(bytes)
	dst.close()
	return true


func _structural_runtime_smoke(target_path: String) -> Dictionary:
	var smoke := {
		"target_path": target_path,
		"target_loaded": false,
		"phase": "structural_runtime_smoke",
		"required_node_presence": {},
		"wall_layer_collision_enabled": false,
		"marker_tile_layer_visible_after_ready": null,
		"editor_only_placeholders_visible_after_ready": null,
		"gate_blocker_present": false,
		"gate_blocker_collision_layer": 0,
		"gate_blocker_collision_layer_includes_walls": false,
		"route_safeguard_present": false,
		"promoted_collectibles_count": 0,
		"promoted_collectibles": [],
		"errors": [],
		"warnings": [],
		"pass": false,
	}
	var packed := ResourceLoader.load(target_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		smoke.errors.append("packed_scene_load_failed")
		return smoke
	var instance := packed.instantiate()
	if instance == null:
		smoke.errors.append("packed_scene_instantiate_failed")
		return smoke
	smoke.target_loaded = true
	get_root().add_child(instance)
	# Wait several frames so Phase0IAuthoringHider._ready() and Phase0IRouteSafeguard
	# call_deferred targets actually run AFTER IsoMissionBase._ready completes.
	await process_frame
	await physics_frame
	await process_frame
	await physics_frame
	await process_frame

	# Required nodes.
	var required_paths := [
		"GameplayRoot/LayoutRoot/FloorLayer",
		"GameplayRoot/LayoutRoot/WallLayer",
		"GameplayRoot/LayoutRoot/MarkerTileLayer",
		"GameplayRoot/MarkerRoot/EditorOnlyPlaceholders",
		"GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate",
		"GameplayRoot/Phase0IRouteSafeguard",
		"EntityRoot/Interactables/Phase0IGeneratedCollectibles",
	]
	for p in required_paths:
		smoke.required_node_presence[p] = instance.get_node_or_null(p) != null

	# Wall collision.
	var wall: Node = instance.get_node_or_null("GameplayRoot/LayoutRoot/WallLayer")
	if wall is TileMapLayer:
		smoke.wall_layer_collision_enabled = bool((wall as TileMapLayer).collision_enabled)

	# MarkerTileLayer should be visible=false after _ready hider fired.
	var mtl: Node = instance.get_node_or_null("GameplayRoot/LayoutRoot/MarkerTileLayer")
	if mtl is CanvasItem:
		smoke.marker_tile_layer_visible_after_ready = bool((mtl as CanvasItem).visible)
	# EditorOnlyPlaceholders should be visible=false after _ready hider fired.
	var eop: Node = instance.get_node_or_null("GameplayRoot/MarkerRoot/EditorOnlyPlaceholders")
	if eop is CanvasItem:
		smoke.editor_only_placeholders_visible_after_ready = bool((eop as CanvasItem).visible)

	# Gate blocker.
	var gb: Node = instance.get_node_or_null("GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate")
	if gb is StaticBody2D:
		smoke.gate_blocker_present = true
		smoke.gate_blocker_collision_layer = int((gb as StaticBody2D).collision_layer)
		smoke.gate_blocker_collision_layer_includes_walls = (smoke.gate_blocker_collision_layer & 4) != 0

	# Route safeguard present.
	smoke.route_safeguard_present = instance.get_node_or_null("GameplayRoot/Phase0IRouteSafeguard") != null

	# Promoted collectibles.
	var col_parent: Node = instance.get_node_or_null("EntityRoot/Interactables/Phase0IGeneratedCollectibles")
	if col_parent != null:
		for child in col_parent.get_children():
			if child is Area2D:
				smoke.promoted_collectibles.append({
					"manifest_id": String(child.name),
					"is_in_interactable_group": child.is_in_group("interactable"),
					"global_position": [(child as Node2D).global_position.x, (child as Node2D).global_position.y],
				})
		smoke.promoted_collectibles_count = smoke.promoted_collectibles.size()

	# Pass criteria.
	var fail_reasons: Array = []
	if not smoke.wall_layer_collision_enabled:
		fail_reasons.append("wall_collision_not_enabled_at_runtime")
	if smoke.marker_tile_layer_visible_after_ready != false:
		fail_reasons.append("marker_tile_layer_not_hidden_at_runtime")
	if smoke.editor_only_placeholders_visible_after_ready != false:
		fail_reasons.append("editor_only_placeholders_not_hidden_at_runtime")
	if not smoke.gate_blocker_present:
		fail_reasons.append("gate_blocker_missing_or_wrong_type")
	if not smoke.gate_blocker_collision_layer_includes_walls:
		fail_reasons.append("gate_blocker_not_on_walls_layer")
	if not smoke.route_safeguard_present:
		fail_reasons.append("route_safeguard_missing")
	if smoke.promoted_collectibles_count < 5:
		fail_reasons.append("fewer_than_five_promoted_collectibles")
	smoke.pass = fail_reasons.size() == 0
	smoke.fail_reasons = fail_reasons

	# Cleanup.
	get_root().remove_child(instance)
	instance.queue_free()
	return smoke


func _write_room_guide(manifest: Dictionary, path: String, _build_result: Dictionary) -> void:
	var rows: Array = manifest.get("runtime_marker_targets", [])
	var by_x: Dictionary = {}
	for r_obj in rows:
		var r: Dictionary = r_obj
		var x := int(r.get("x", 0))
		if not by_x.has(x):
			by_x[x] = []
		(by_x[x] as Array).append(r)
	var lines: Array = []
	lines.append("# Taco Bell Iso — Generated Map Room Guide")
	lines.append("")
	lines.append("Source manifest: `res://assets/missions/layouts/taco_bell_expanded_layout_v6.json`.")
	lines.append("All x/y are anchor-relative (anchor = `player_spawn_main`).")
	lines.append("")
	lines.append("Status legend:")
	lines.append("- **REAL** — interactable runtime gameplay (real_existing or Phase 0I-promoted)")
	lines.append("- **EDITOR-ONLY** — authoring placeholder, deferred mechanic")
	lines.append("- **TILE-ONLY** — only the marker tile is painted, no runtime node")
	lines.append("- **BENTLEY** — Bentley utility / vent route only (not for player walktest yet)")
	lines.append("- **LOUIS** — Louis delivery shortcut (deferred mechanic)")
	lines.append("")
	# Hand-curated room order with cell ranges aligned to the manifest layout.
	var rooms := [
		{"name": "Louis Start / Player Spawn", "x_min": -2, "x_max": 9, "what": "Player + Bentley spawn. Talk to Louis (briefing objective). Mission start.", "ids": ["player_spawn_main", "bentley_spawn_main", "OBJ_start_briefing", "HELP_start_controls"]},
		{"name": "Optional Market Nook", "x_min": -8, "x_max": 6, "what": "Quiet rain-soaked alcove south of spawn. Hidden Polaroid pickup.", "ids": ["PHOTO_optional_market_nook"]},
		{"name": "Midnight Market Street", "x_min": 10, "x_max": 45, "what": "Walk east past closed shops. Inspect the receipt/sauce packets.", "ids": ["OBJ_market_investigation", "GUARD_market_01", "PATROL_market_01_A", "GLOW_market_shop"]},
		{"name": "North Shop Row + Dog Station Alley", "x_min": 25, "x_max": 75, "what": "North spur. Dog station and trash alley scent fakes (Bentley sniff training).", "ids": ["SCENT_FAKE_dog_station", "BAG_dog_station", "PHOTO_dog_station", "FLOOD_dog_station"]},
		{"name": "Trash Alley", "x_min": 45, "x_max": 65, "what": "North-side trash alley. Fake scent. Sterling clue token.", "ids": ["SCENT_FAKE_trash_alley", "CLUE_sterling_delivery_token"]},
		{"name": "Loading Dock Lane", "x_min": 40, "x_max": 70, "what": "South-side loading dock fake scent + bag pickup. Poop-bag decoy lane.", "ids": ["SCENT_FAKE_loading_dock", "BAG_loading_dock", "FLOOD_loading_dock"]},
		{"name": "Delivery Alley Hub (Scent Decision)", "x_min": 65, "x_max": 95, "what": "Three scent trails converge. Bentley confirms the real one (parking garage).", "ids": ["SCENT_PATH_hub_center", "OBJ_scent_decision", "HELP_scent_tutorial"]},
		{"name": "Garage Entry Approach", "x_min": 95, "x_max": 130, "what": "Real scent leads east toward the parking garage entry.", "ids": ["SCENT_REAL_garage_approach", "scent_real_parking_garage_02", "scent_real_parking_garage_03"]},
		{"name": "Security Kiosk / Control Room", "x_min": 110, "x_max": 145, "what": "Camera/alarm/door control switches (deferred mechanics).", "ids": ["CONTROL_camera_terminal", "CONTROL_alarm_panel", "CONTROL_door_controls"]},
		{"name": "Safe Code Input Pocket", "x_min": 110, "x_max": 130, "what": "SAFE pocket where player will eventually enter the gate code.", "ids": ["SAFE_CODE_INPUT_ZONE", "HELP_code_gate"]},
		{"name": "Garage Office / Code Clue Room", "x_min": 125, "x_max": 145, "what": "Velvet Paw stamp + delivery receipt clues for the gate code.", "ids": ["CLUE_velvet_paw_stamp", "CLUE_sauce_packet", "CLUE_camera_schedule", "CLUE_delivery_receipt"]},
		{"name": "Code Gate Chokepoint", "x_min": 145, "x_max": 155, "what": "GATE marker tile + BLOCK_code_gate runtime collider. Future code mechanic removes the blocker.", "ids": ["GATE_garage_code", "BLOCK_code_gate", "OBJ_code_gate"]},
		{"name": "Post-Gate Buffer", "x_min": 150, "x_max": 175, "what": "Service corridor after the gate. Louis route returns into this buffer.", "ids": ["BAG_louis_service_corridor", "ROUTE_DEST_louis_return_destination"]},
		{"name": "Louis Service Corridor (Shortcut Return)", "x_min": 60, "x_max": 175, "what": "Louis delivery shortcut bypasses the code gate but returns BEFORE the security beam, so player still does the bag objective.", "ids": ["ROUTE_IN_louis_service_door", "ROUTE_RET_louis_return_trigger", "ROUTE_DEST_louis_return_destination"]},
		{"name": "Security Beam Approach", "x_min": 170, "x_max": 195, "what": "Ambush trigger zone. Player must avoid alarm escalation.", "ids": ["AMBUSH_security_beam", "OBJ_security_beam", "ALARM_beam_escalation"]},
		{"name": "Garage Floor 1", "x_min": 195, "x_max": 230, "what": "Open garage floor. Patrols, cameras, interactables.", "ids": ["GUARD_garage_patrol_01", "PATROL_garage_01_A", "PATROL_garage_01_B", "PATROL_garage_01_C", "CAM_garage_lower", "poop_bag_garage_pet_bin"]},
		{"name": "Upper Platform / Control Alcove", "x_min": 225, "x_max": 250, "what": "Upper alcove with perfect-Polaroid + ambient cameras.", "ids": ["PHOTO_upper_platform", "CAM_garage_upper", "CAM_upper_high_heat"]},
		{"name": "Bag Recovery Room", "x_min": 235, "x_max": 270, "what": "Mission objective destination: recover the delivery bag.", "ids": ["OBJ_bag_recovery", "CAM_bag_room", "GLOW_bag_room", "TINY_loading_dock"]},
		{"name": "South Return Corridor", "x_min": -10, "x_max": 130, "what": "After the bag pickup, head south then west to escape.", "ids": ["BAG_south_return", "OBJ_return_to_louis"]},
		{"name": "Mission Exit", "x_min": -15, "x_max": 5, "what": "Return-to-Louis exit trigger. Mission ends.", "ids": ["EXIT_mission_return_to_louis"]},
		{"name": "Bentley Utility Routes A/B/C/D", "x_min": -30, "x_max": 270, "what": "Bentley-only vent shortcuts (deferred). Disabled for player walktest by Phase0IRouteSafeguard.", "ids": ["VENT_IN", "VENT_OUT", "BENTLEY_SWITCH_alarm_override", "BENTLEY_SWITCH_camera_shutoff", "BENTLEY_SWITCH_door_release", "BENTLEY_SWITCH_exit_release", "BENTLEY_SWITCH_outdoor_floodlight_breaker"]},
	]
	# Quick lookup of marker rows by id.
	var by_id := {}
	for r_obj in rows:
		var r: Dictionary = r_obj
		by_id[String(r.get("manifest_id", ""))] = r
	for room in rooms:
		lines.append("## " + String(room.name))
		lines.append("")
		lines.append("- **Approx cell range (x):** " + str(room.x_min) + " .. " + str(room.x_max))
		lines.append("- **What player should do:** " + String(room.what))
		lines.append("")
		lines.append("| Manifest ID | Cell | Status | Notes |")
		lines.append("|---|---|---|---|")
		var ids_in_room: Array = room.ids
		for id_obj in ids_in_room:
			var id_str := String(id_obj)
			# Either exact id, or prefix match (e.g. "VENT_IN").
			var matched_rows: Array = []
			if by_id.has(id_str):
				matched_rows.append(by_id[id_str])
			else:
				for rr_obj in rows:
					var rr: Dictionary = rr_obj
					if String(rr.get("manifest_id", "")).begins_with(id_str):
						matched_rows.append(rr)
			for mr in matched_rows:
				var mid := String(mr.get("manifest_id", ""))
				var x := int(mr.get("x", 0))
				var y := int(mr.get("y", 0))
				var tier := String(mr.get("desired_runtime_tier", ""))
				var status := "TILE-ONLY"
				if tier == "real_existing":
					status = "REAL"
				elif tier == "editor_only_placeholder":
					status = "EDITOR-ONLY"
				elif tier == "real_if_safe":
					status = "EDITOR-ONLY (deferred)"
				if mid.begins_with("BENTLEY_") or mid.begins_with("VENT_"):
					status += " · BENTLEY"
				if mid.begins_with("ROUTE_") and "louis" in mid.to_lower():
					status += " · LOUIS"
				if mid == "BLOCK_code_gate":
					status = "REAL (Phase 0I generated blocker)"
				if mid in ["OBJ_bag_recovery", "poop_bag_garage_pet_bin", "BAG_louis_service_corridor", "PHOTO_optional_market_nook", "CLUE_security_memo"]:
					status = "REAL (Phase 0I promoted)"
				var notes := String(mr.get("notes", ""))
				lines.append("| `" + mid + "` | (" + str(x) + ", " + str(y) + ") | " + status + " | " + notes + " |")
		lines.append("")

	lines.append("## Walls and collision")
	lines.append("")
	lines.append("- `WallLayer` is the primary wall collision (`collision_enabled = true` after Phase 0I, TileSet `physics_layer_0` -> Walls = layer 3).")
	lines.append("- `CollisionBarrierLayer` carries deliberate blocker tiles only (vents, gate-adjacent cells), `collision_enabled = false` (we use a dedicated StaticBody2D for the gate so it can be cleanly removed by future unlock mechanics).")
	lines.append("- `GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate` is the runtime gate blocker (`collision_layer = 4` = Walls).")
	lines.append("")
	lines.append("## Authoring vs gameplay visuals")
	lines.append("")
	lines.append("- `MarkerTileLayer` and `EditorOnlyPlaceholders` are visible in the editor for authoring, but hidden at runtime by `Phase0IAuthoringHider`.")
	lines.append("- `MarkerRoot/{Spawns,Routes,Transitions,Objectives,...}` are also hidden at runtime (authoring debug only).")
	lines.append("- `FloorLayer`, `WallLayer`, `CoverLayer` remain visible at runtime as gameplay tiles.")
	lines.append("")
	lines.append("## Bentley vs Louis vs player walktest")
	lines.append("")
	lines.append("- Player can walk the full main path: spawn -> market -> hub -> garage approach -> safe pocket -> code gate -> post-gate buffer -> beam -> garage -> bag room -> south corridor -> exit.")
	lines.append("- Louis delivery shortcut bypasses the code gate but rejoins BEFORE the security beam (so the player still does the bag objective and exit).")
	lines.append("- Bentley vents are NOT player-traversable yet. `Phase0IRouteSafeguard` disables player teleport on `Transition_route_vent_return` and `Transition_route_louis_return`.")
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write room guide failed: " + path)
		return
	f.store_string("\n".join(lines))
	f.close()


func _write_markdown_report(combined: Dictionary, path: String) -> void:
	var lines: Array = []
	var status := "PASS" if bool(combined.get("pass", false)) else "FAIL"
	lines.append("# Phase 0I — Taco Bell Runtime Truth Audit and Minimal Playability Fix")
	lines.append("")
	lines.append("**Status:** " + status)
	lines.append("**Timestamp:** " + String(combined.get("timestamp", "")))
	lines.append("")
	lines.append("## Source-scene protection")
	lines.append("")
	var src: Dictionary = combined.get("source_scene_protection", {})
	lines.append("- **Path:** `" + String(src.get("path", "")) + "`")
	lines.append("- **MD5 before:** `" + String(src.get("hash_before", "")) + "`")
	lines.append("- **MD5 after:** `" + String(src.get("hash_after", "")) + "`")
	lines.append("- **Unchanged:** " + str(bool(src.get("unchanged", false))))
	lines.append("")
	lines.append("## Target duplicate scene")
	lines.append("")
	var tgt: Dictionary = combined.get("target_scene", {})
	lines.append("- **Path:** `" + String(tgt.get("path", "")) + "`")
	lines.append("- **Existed before:** " + str(bool(tgt.get("existed_before", false))))
	lines.append("- **Backup created:** " + str(bool(tgt.get("backup_created", false))))
	lines.append("- **Backup path:** `" + String(tgt.get("backup_path", "")) + "`")
	lines.append("- **MD5 before:** `" + String(tgt.get("hash_before", "")) + "`")
	lines.append("- **MD5 after:** `" + String(tgt.get("hash_after", "")) + "`")
	lines.append("")
	# Phase 0I cleanup summary from build_result.
	var bresult: Dictionary = combined.get("build_result", {})
	var p0i: Dictionary = bresult.get("phase_0i_cleanup", {})
	lines.append("## Builder Phase 0I cleanup summary")
	lines.append("")
	if p0i.is_empty():
		lines.append("(No phase_0i_cleanup section present in builder report.)")
	else:
		lines.append("### Wall layer (B)")
		lines.append("")
		var w: Dictionary = p0i.get("wall_layer", {})
		lines.append("- **collision_enabled before:** " + str(w.get("collision_enabled_before")))
		lines.append("- **collision_enabled after:** " + str(w.get("collision_enabled_after")))
		lines.append("- **TileSet physics_layer_0 collision_layer bits:** " + str(w.get("tileset_physics_layer_collision_layer_bits")) + " (4 = Walls)")
		lines.append("")
		lines.append("### Authoring hide-at-runtime (A)")
		lines.append("")
		lines.append("- **MarkerTileLayer hider attached:** " + str(p0i.get("marker_tile_layer", {}).get("hider_attached", false)))
		lines.append("- **EditorOnlyPlaceholders hider attached:** " + str(p0i.get("editor_only_placeholders", {}).get("hider_attached", false)))
		var amrs: Array = p0i.get("authoring_marker_root_subnodes", [])
		var amr_attached: int = 0
		for s in amrs:
			if bool(s.get("attached", false)):
				amr_attached += 1
		lines.append("- **Authoring marker root subnodes hidden:** " + str(amr_attached) + " / " + str(amrs.size()))
		lines.append("")
		lines.append("### Generated runtime collision (C)")
		lines.append("")
		var gb: Dictionary = p0i.get("generated_runtime_collision", {}).get("gate_blocker", {})
		lines.append("- **Path:** `" + String(gb.get("node_path", "")) + "`")
		lines.append("- **abs_cell:** " + str(gb.get("abs_cell", [])))
		lines.append("- **world_position:** " + str(gb.get("world_position", [])))
		lines.append("- **collision_layer:** " + str(gb.get("collision_layer", 0)) + " (4 = Walls)")
		lines.append("- **future_unlockable:** " + str(gb.get("future_unlockable", false)))
		lines.append("")
		lines.append("### Promoted core collectibles (D)")
		lines.append("")
		lines.append("| Manifest ID | Implementation | Cell | Node path |")
		lines.append("|---|---|---|---|")
		for promo in p0i.get("core_collectibles_promoted", []):
			lines.append("| `" + String(promo.get("manifest_id", "")) + "` | " + String(promo.get("implementation", "")) + " | " + str(promo.get("abs_cell", [])) + " | `" + String(promo.get("node_path", "")) + "` |")
		lines.append("")
		lines.append("### Route safeguard (E)")
		lines.append("")
		var rs: Dictionary = p0i.get("route_safeguard", {})
		lines.append("- **Attached:** " + str(rs.get("attached", false)))
		lines.append("- **Node path:** `" + String(rs.get("node_path", "")) + "`")
		var targets: Variant = rs.get("targets", [])
		if targets is Array:
			lines.append("- **Targets:**")
			for t in targets:
				lines.append("  - `" + String(t) + "`")
		var legacy: Variant = rs.get("legacy_blockers", [])
		if legacy is Array and (legacy as Array).size() > 0:
			lines.append("- **Legacy blockers disabled:**")
			for t in legacy:
				lines.append("  - `" + String(t) + "`")
		lines.append("")
	# Validator hard assertions table.
	var validate_i: Dictionary = combined.get("validate_i", {})
	var hard: Dictionary = validate_i.get("hard_assertions", {})
	lines.append("## Hard assertions")
	lines.append("")
	lines.append("**Validator pass:** " + str(bool(validate_i.get("pass", false))))
	lines.append("")
	lines.append("| Assertion | Value |")
	lines.append("|---|---|")
	var keys := hard.keys()
	keys.sort()
	for k in keys:
		lines.append("| `" + String(k) + "` | " + str(hard[k]) + " |")
	lines.append("")
	# Smoke.
	var smoke: Dictionary = combined.get("smoke", {})
	lines.append("## Runtime smoke (live SceneTree instantiate)")
	lines.append("")
	lines.append("- **Pass:** " + str(bool(smoke.get("pass", false))))
	lines.append("- **WallLayer.collision_enabled at runtime:** " + str(smoke.get("wall_layer_collision_enabled")))
	lines.append("- **MarkerTileLayer.visible after Phase0IAuthoringHider._ready:** " + str(smoke.get("marker_tile_layer_visible_after_ready")))
	lines.append("- **EditorOnlyPlaceholders.visible after Phase0IAuthoringHider._ready:** " + str(smoke.get("editor_only_placeholders_visible_after_ready")))
	lines.append("- **GateBlockers/BLOCK_code_gate present:** " + str(smoke.get("gate_blocker_present")))
	lines.append("- **GateBlockers/BLOCK_code_gate uses Walls layer (bit 4):** " + str(smoke.get("gate_blocker_collision_layer_includes_walls")))
	lines.append("- **Phase0IRouteSafeguard present:** " + str(smoke.get("route_safeguard_present")))
	lines.append("- **Promoted collectibles count:** " + str(smoke.get("promoted_collectibles_count")))
	if smoke.has("fail_reasons") and (smoke.fail_reasons as Array).size() > 0:
		lines.append("- **Smoke fail reasons:** " + str(smoke.fail_reasons))
	lines.append("")
	lines.append("## Files changed")
	lines.append("")
	lines.append("- `assets/missions/layouts/taco_bell_expanded_layout_v6.json` — added `phase_0i` validation + `phase_0i_cleanup` config and `mission_id_hint`.")
	lines.append("- `src/tools/editor/TacoBellExpandedLayoutBuilder.gd` — added Phase 13c `_phase_0i_cleanup` (wall collision, hider attach, gate blocker, promoted collectibles, route safeguard).")
	lines.append("- `src/tools/editor/TacoBellExpandedLayoutValidator.gd` — added `_phase_0i_audit` and Phase 0I hard assertions.")
	lines.append("- `src/tools/editor/TacoBellPhase0ICleanup.gd` — new headless driver.")
	lines.append("- `src/missions/iso/runtime/Phase0IAuthoringHider.gd` — new editor-only authoring visual hider.")
	lines.append("- `src/missions/iso/runtime/Phase0IRouteSafeguard.gd` — new runtime player-teleport safeguard.")
	lines.append("- `scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn` — overwritten by deterministic builder.")
	lines.append("- `docs/reports/taco_bell_phase_0i_runtime_truth_audit.{md,json}` — this report.")
	lines.append("- `docs/reports/taco_bell_generated_map_room_guide.md` — human-readable map room guide.")
	lines.append("")
	lines.append("## Remaining limitations / deferred items")
	lines.append("")
	lines.append("- The 11 `real_if_safe` SWITCH/DOOR mechanics remain editor-only. No behavioral claims.")
	lines.append("- Code-gate keypad UI is not implemented. The blocker is real and removable; future work wires the keypad to remove the StaticBody2D's collision_layer.")
	lines.append("- Bentley vent routes are inert for the player. A future pass implementing real Bentley/Louis route mechanics will connect specific Area2D triggers to the right characters via a cleaner runtime check (instead of `auto_trigger_on_enter` for any `transition_id` starting with `route_`).")
	lines.append("- Promoted collectibles other than the 5 core ones remain editor-only `Node2D` placeholders. A separate pass can promote the rest using the same builder pattern.")
	lines.append("- `IsoMissionBase._spawn_code_gate_blockers` still creates a legacy blocker at obsolete cell `(21,-3)`. Phase0IRouteSafeguard disables it at runtime. The proper fix lives in `IsoMissionBase.gd`, which is not modified per the Phase 0I rules.")
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("write_markdown_report failed: " + path)
		return
	f.store_string("\n".join(lines))
	f.close()
