@tool
extends SceneTree

## Headless dry-run driver for Phase 0G v6 Phase E.
##
## Run with:
##   Godot_v4.6.2-stable_win64_console.exe --path <project> --headless \
##     --script res://src/tools/editor/TacoBellExpandedLayoutDryRun.gd
##
## Loads the manifest, runs the builder in dry_run mode (no scene save), runs
## the validator via validate_scene_root() against the in-memory mutated source
## tree, and writes:
##   res://docs/reports/taco_bell_expanded_coordinate_layout_v6_dry_run.json
##
## Exits with code 0 on PASS, 1 on FAIL.

const Shared := preload("res://src/tools/editor/TacoBellExpandedLayoutShared.gd")
const Builder := preload("res://src/tools/editor/TacoBellExpandedLayoutBuilder.gd")
const Validator := preload("res://src/tools/editor/TacoBellExpandedLayoutValidator.gd")

const DRY_RUN_REPORT_JSON := "res://docs/reports/taco_bell_expanded_coordinate_layout_v6_dry_run.json"
const DRY_RUN_REPORT_MD := "res://docs/reports/taco_bell_expanded_coordinate_layout_v6_dry_run.md"

func _initialize() -> void:
	print("[Phase 0G v6][Phase E] Loading manifest...")
	var manifest := Shared.load_manifest()
	if manifest.has("_error"):
		printerr("Manifest load failed: " + str(manifest))
		quit(1)
		return

	print("[Phase 0G v6][Phase E] Running builder dry-run...")
	var build_result: Dictionary = Builder.run({"dry_run": true, "write_dry_run_report": true})

	var build_summary := {
		"errors": build_result.get("errors", []),
		"warnings": build_result.get("warnings", []),
		"counts": build_result.get("counts", {}),
		"runtime_marker_movement_count": (build_result.get("runtime_marker_movement", []) as Array).size(),
		"editor_only_placeholders_count": (build_result.get("editor_only_placeholders_created", []) as Array).size(),
		"missing_required_runtime_markers": (build_result.get("missing_required_runtime_markers", []) as Array).size(),
		"marker_tile_placements_count": (build_result.get("marker_tile_placements", []) as Array).size(),
		"marker_tile_suppressed_count": (build_result.get("marker_tile_suppressed", []) as Array).size(),
		"equivalence_collisions": (build_result.get("equivalence_collisions", []) as Array).size(),
	}

	if (build_result.get("errors", []) as Array).size() > 0:
		printerr("Builder errors:")
		for e in build_result.errors:
			printerr("  - " + str(e))

	var scene_root: Node = build_result.get("scene_root", null)
	if scene_root == null:
		printerr("Builder did not return scene_root; aborting.")
		quit(1)
		return

	print("[Phase 0G v6][Phase E] Running validator on in-memory root...")
	var ctx := {
		"cache_safe_load_mode_used": bool(build_result.get("cache_safe_load_mode_used", true)),
		"source_scene_protection": build_result.get("source_protection", {}),
		"optional_visual_reference": build_result.get("optional_visual_reference", {}),
		"builder_report_summary": build_summary,
	}
	var validate_result: Dictionary = Validator.validate_scene_root(scene_root, manifest, ctx)

	# Combine builder + validator into a single dry-run report blob.
	var combined := {
		"phase": "E_dry_run",
		"pass": bool(validate_result.get("pass", false)) and (build_result.get("errors", []) as Array).size() == 0,
		"build_summary": build_summary,
		"build_runtime_marker_movement": build_result.get("runtime_marker_movement", []),
		"build_editor_only_placeholders_created": build_result.get("editor_only_placeholders_created", []),
		"build_missing_required_runtime_markers": build_result.get("missing_required_runtime_markers", []),
		"build_marker_tile_placements": build_result.get("marker_tile_placements", []),
		"build_marker_tile_suppressed": build_result.get("marker_tile_suppressed", []),
		"build_cover_adjustments": build_result.get("cover_adjustments", []),
		"build_vent_interfaces": build_result.get("vent_interfaces", []),
		"build_equivalence_collisions": build_result.get("equivalence_collisions", []),
		"build_idempotency": build_result.get("idempotency", {}),
		"build_source_protection": build_result.get("source_protection", {}),
		"build_optional_visual_reference": build_result.get("optional_visual_reference", {}),
		"validate": validate_result,
	}

	# Write JSON report.
	Validator.write_json_report(combined, DRY_RUN_REPORT_JSON)
	Validator.write_markdown_report(validate_result, DRY_RUN_REPORT_MD, "Taco Bell Expanded Coordinate Layout v6 - Phase E Dry-Run Validation")

	# Free the scene root we got from the builder.
	scene_root.queue_free()

	var pass_ok: bool = bool(combined.pass)
	print("[Phase 0G v6][Phase E] Dry-run " + ("PASS" if pass_ok else "FAIL"))
	if not pass_ok:
		printerr("Dry-run FAIL. See report: " + DRY_RUN_REPORT_JSON)
		# Print first 20 failed assertions for visibility
		var hard: Dictionary = validate_result.get("hard_assertions", {})
		var failed_count := 0
		for k in hard.keys():
			var v = hard[k]
			var failed := false
			if v is bool and not v:
				failed = true
			elif k.ends_with("_count_zero") and v is int and v != 0:
				failed = true
			if failed:
				printerr("  FAIL: " + String(k) + " = " + str(v))
				failed_count += 1
				if failed_count >= 25:
					printerr("  ... (truncated)")
					break
		quit(1)
	else:
		print("Dry-run report: " + DRY_RUN_REPORT_JSON)
		quit(0)
