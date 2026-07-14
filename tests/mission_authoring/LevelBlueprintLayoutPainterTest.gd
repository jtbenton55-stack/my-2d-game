extends GdUnitTestSuite

const Painter := preload("res://src/tools/editor/level_blueprint/LevelBlueprintLayoutPainter.gd")

const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const BLUEPRINT_PATH := "res://docs/blueprints/velvet_paw_jazz_club.blueprint.json"
var _cached_report: Dictionary = {}


func test_dry_run_ok_and_production_scene_hash_unchanged() -> void:
	var scene_hash_before := FileAccess.get_sha256(SCENE_PATH)
	var report := _report()
	assert_bool(report.get("ok", false)).override_failure_message(str(report.get("errors", []))).is_true()
	assert_bool(report.get("dry_run", false)).is_true()
	assert_str(String(report.source_hashes.scene.before)).is_equal(scene_hash_before)
	assert_str(String(report.source_hashes.scene.after)).is_equal(scene_hash_before)
	assert_str(FileAccess.get_sha256(SCENE_PATH)).is_equal(scene_hash_before)
	assert_dict(report.mutation_flags).is_equal({
		"scene_mutated": false,
		"blueprint_mutated": false,
		"in_memory_tiles_changed": false,
		"tiles_written": false,
		"nodes_added": false,
		"nodes_removed": false,
	})
	assert_bool(bool(report.save_flags.any_save_called)).is_false()


func test_semantic_region_and_cell_sets() -> void:
	var report := _report()
	assert_int(_region_count(report, "floor")).is_equal(7)
	assert_int(int(report.per_kind_cell_counts.wall)).is_greater(0)
	assert_int(int(report.per_kind_cell_counts.collision_barrier)).is_greater(0)
	assert_int(int(report.cover_analysis.painted_solid_cell_count)).is_greater(0)
	var barriers := _regions(report, "collision_barrier")
	assert_int(barriers.size()).is_equal(10)
	assert_bool(_has_label_prefix(barriers, "Front Entrance Crowd Rope")).is_true()


func test_cover_contract_has_four_solid_and_two_non_solid_labels() -> void:
	var report := _report()
	var cover: Dictionary = report.cover_analysis
	assert_int(int(cover.solid_count)).is_equal(4)
	assert_int(int(cover.safe_non_solid_count)).is_equal(2)
	assert_array(cover.solid_labels).contains(["Subwoofer Stack", "Costume Rack", "Alley Dumpster", "Basement Crates"])
	assert_array(cover.safe_non_solid_labels).contains(["Bar Corner", "Dance Floor Silhouette"])
	for row: Dictionary in cover.regions:
		if String(row.classification) == "solid":
			assert_bool(bool(row.blocks_movement)).is_true()
		else:
			assert_bool(bool(row.blocks_movement)).is_false()
	for row: Dictionary in _regions(report, "cover"):
		if bool(row.blocks_movement):
			assert_int(int(row.cell_count)).is_greater(0)
		else:
			assert_int(int(row.cell_count)).is_equal(0)


func test_nine_openings_have_expected_classifications_and_blocking() -> void:
	var openings: Array = _report().opening_analysis
	assert_int(openings.size()).is_equal(9)
	var expected := {
		"front_entrance_crowd_rope": ["dynamic", "vip_social_gate"],
		"staff_side_club_entrance": ["fixed_open", "usable_route"],
		"stage_row_bathroom_access": ["fixed_open", "usable_route"],
		"stage_row_backstage_hatch": ["dynamic", "portal_gated"],
		"stage_row_staff_gate": ["dynamic", "gate"],
		"bathroom_divider_south_end": ["dynamic", "barback_service_gate"],
		"stage_wing_divider_south_gate": ["dynamic", "gate"],
		"vip_rope_north_end": ["dynamic", "protocol_gate"],
		"server_cage_south_center_door": ["dynamic", "gate"],
	}
	for row: Dictionary in openings:
		var wanted: Array = expected.get(String(row.opening_id), [])
		assert_int(wanted.size()).override_failure_message("Unexpected opening: %s" % row.opening_id).is_equal(2)
		assert_str(String(row.state)).is_equal(String(wanted[0]))
		assert_str(String(row.classification)).is_equal(String(wanted[1]))
		assert_bool(bool(row.future_blocker_painted)).is_false()
	var staff := _row_by_id(openings, "opening_id", "staff_side_club_entrance")
	assert_bool(bool(staff.continuous_clear_candidate_lane)).is_true()
	assert_int(int(staff.clear_candidate_cell_count)).is_greater(0)
	var front := _row_by_id(openings, "opening_id", "front_entrance_crowd_rope")
	assert_bool(bool(front.blocked_by_current_barrier)).is_true()
	assert_int((front.blocked_by_barrier_cells as Array).size()).is_greater(0)


func test_owner_suite_and_basement_closed_islands_are_contained() -> void:
	var islands: Array = _report().closed_island_analysis
	assert_int(islands.size()).is_equal(2)
	for island_id in ["owner_suite", "basement"]:
		var row := _row_by_id(islands, "island_id", island_id)
		assert_bool(bool(row.perimeter_represented)).override_failure_message(str(row)).is_true()
		assert_bool(bool(row.containment_represented)).override_failure_message(str(row)).is_true()
		assert_int(int(row.contained_floor_cell_count)).is_greater(0)


func test_blocking_overlap_and_union_evidence() -> void:
	var overlap: Dictionary = _report().blocking_overlap_analysis
	assert_array(overlap.wall_barrier_cells).is_equal([[23, 156], [23, 158]])
	assert_array(overlap.wall_cover_cells).is_empty()
	assert_array(overlap.barrier_cover_cells).is_empty()
	assert_array(overlap.triple_intersection_cells).is_empty()
	var union := {}
	for kind: String in ["wall", "collision_barrier", "cover"]:
		for row: Dictionary in _regions(_report(), kind):
			for cell: Array in row.cells:
				union[Vector2i(int(cell[0]), int(cell[1]))] = true
	assert_int(union.size()).is_equal(int(overlap.unique_blocking_union_count))
	assert_int(union.size()).is_equal(1996)


func test_all_five_approved_layer_paths_resolve() -> void:
	assert_dict(_report().layer_paths).is_equal({
		"floor": "GameplayRoot/LayoutRoot/FloorLayer",
		"wall": "GameplayRoot/LayoutRoot/WallLayer",
		"cover": "GameplayRoot/LayoutRoot/CoverLayer",
		"collision_barrier": "GameplayRoot/LayoutRoot/CollisionBarrierLayer",
		"marker": "GameplayRoot/LayoutRoot/MarkerTileLayer",
	})


func test_non_dry_run_is_rejected_without_mutation() -> void:
	var scene_hash_before := FileAccess.get_sha256(SCENE_PATH)
	var report: Dictionary = Painter.run({"scene_path": SCENE_PATH, "blueprint_path": BLUEPRINT_PATH, "dry_run": false})
	assert_bool(report.get("ok", true)).is_false()
	assert_bool(report.get("dry_run", true)).is_false()
	assert_str(" ".join(report.errors)).contains("allow_apply=true")
	assert_str(String(report.source_hashes.scene.before)).is_equal(String(report.source_hashes.scene.after))
	assert_bool(bool(report.mutation_flags.scene_mutated)).is_false()
	assert_bool(bool(report.mutation_flags.blueprint_mutated)).is_false()
	assert_bool(bool(report.save_flags.any_save_called)).is_false()
	assert_str(FileAccess.get_sha256(SCENE_PATH)).is_equal(scene_hash_before)


func test_repeated_runs_are_deterministic() -> void:
	var first := _report()
	var second: Dictionary = Painter.run({"scene_path": SCENE_PATH, "blueprint_path": BLUEPRINT_PATH})
	assert_bool(second.get("ok", false)).override_failure_message(str(second.get("errors", []))).is_true()
	assert_dict(second.per_kind_cell_counts).is_equal(first.per_kind_cell_counts)
	assert_array(second.representative_data).is_equal(first.representative_data)
	assert_array(second.opening_analysis).is_equal(first.opening_analysis)


func _report() -> Dictionary:
	if _cached_report.is_empty():
		_cached_report = Painter.run({"scene_path": SCENE_PATH, "blueprint_path": BLUEPRINT_PATH})
	return _cached_report


func _regions(report: Dictionary, kind: String) -> Array:
	var rows: Array = []
	for row: Dictionary in report.get("per_region", []):
		if String(row.get("kind", "")) == kind:
			rows.append(row)
	return rows


func _region_count(report: Dictionary, kind: String) -> int:
	return _regions(report, kind).size()


func _has_label_prefix(rows: Array, prefix: String) -> bool:
	for row: Dictionary in rows:
		if String(row.get("label", "")).begins_with(prefix):
			return true
	return false


func _row_by_id(rows: Array, key: String, wanted: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get(key, "")) == wanted:
			return row
	return {}
