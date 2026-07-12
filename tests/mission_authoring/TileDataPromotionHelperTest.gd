extends GdUnitTestSuite

const Helper := preload("res://src/tools/editor/level_blueprint/TileDataPromotionHelper.gd")
const BASELINE_SHA := "d806b32cd341c30661142bb783086d04c89990c912692270c447c0cf3788f56c"
const CHECKPOINT := "res://reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_checkpoints/phase_03b_retry4_pre_promotion/scenes_missions_iso_VelvetPawJazzClub_Editable.tscn.snapshot"
const WORK := "res://reports/godot_ignored_backups/velvet_paw_collision_2026-07-10/phase_03b_retry4_work"
const SCRATCH_BASELINE := WORK + "/integration_unpainted_baseline.tscn"
const CANDIDATE := WORK + "/VelvetPawJazzClub_Editable_phase3b_retry4_candidate.tscn"
const SCRATCH_STAGED := WORK + "/integration_staged.tscn"


func test_synthetic_lf_and_crlf_preserve_every_baseline_byte() -> void:
	for newline: String in ["\n", "\r\n"]:
		var baseline: PackedByteArray = _scene_text(newline, false).to_utf8_buffer()
		var report: Dictionary = Helper.stage_bytes(baseline, _scene_text(newline, true).to_utf8_buffer())
		assert_bool(report.ok).override_failure_message(str(report.errors)).is_true()
		assert_int((report.inserted_spans as Array).size()).is_equal(4)
		assert_int(int(report.staged_size)).is_equal(int(report.baseline_size) + int(report.inserted_size))
		assert_array(Helper.remove_spans(report.staged_bytes, report.inserted_spans)).is_equal(baseline)
		assert_str((report.staged_bytes as PackedByteArray).get_string_from_utf8().replace("tile_map_data = PackedByteArray(\"AAAA\")" + newline, "")).is_equal(baseline.get_string_from_utf8())


func test_rejects_invalid_exact_block_contracts() -> void:
	var baseline: String = _scene_text("\n", false)
	var candidate: String = _scene_text("\n", true)
	var cases: Array[Array] = [
		[baseline.replace("FloorLayer", "MissingFloor"), candidate],
		[baseline + _block("FloorLayer", 2053303541, "\n", false), candidate],
		[baseline.replace('parent="GameplayRoot/LayoutRoot"', 'parent="Wrong"'), candidate],
		[baseline.replace('type="TileMapLayer"', 'type="Node2D"'), candidate],
		[baseline.replace("unique_id=2053303541", "unique_id=1"), candidate],
		[baseline.replace(Helper.TILE_SET_LINE, 'tile_set = ExtResource("4")'), candidate],
		[baseline, candidate.replace(Helper.TILE_SET_LINE, 'tile_set = ExtResource("wrong")')],
		[baseline.replace(Helper.TILE_SET_LINE, 'tile_map_data = PackedByteArray("OLD")\n' + Helper.TILE_SET_LINE), candidate],
		[baseline, candidate.replace('tile_map_data = PackedByteArray("AAAA")', "tile_map_data = PackedByteArray(\n\"AAAA\")")],
		[baseline, candidate.replace('tile_map_data = PackedByteArray("AAAA")', 'tile_map_data = PackedByteArray("")')],
	]
	for pair: Array in cases:
		assert_bool(bool(Helper.stage_bytes(String(pair[0]).to_utf8_buffer(), String(pair[1]).to_utf8_buffer()).ok)).is_false()


func test_deterministic_payloads_and_known_defaults_excluded() -> void:
	var baseline: PackedByteArray = _scene_text("\n", false).to_utf8_buffer()
	var candidate: PackedByteArray = _scene_text("\n", true).to_utf8_buffer()
	var first: Dictionary = Helper.stage_bytes(baseline, candidate)
	var second: Dictionary = Helper.stage_bytes(baseline, candidate)
	assert_array(first.staged_bytes).is_equal(second.staged_bytes)
	assert_array(first.inserted_spans).is_equal(second.inserted_spans)
	var staged: String = (first.staged_bytes as PackedByteArray).get_string_from_utf8()
	for forbidden: String in Helper.KNOWN_UNRELATED_DEFAULTS:
		assert_bool(staged.contains(forbidden)).is_false()


func test_real_candidate_uses_immutable_checkpoint_scratch_baseline() -> void:
	assert_str(FileAccess.get_sha256(CHECKPOINT)).is_equal(BASELINE_SHA)
	var checkpoint_bytes: PackedByteArray = FileAccess.get_file_as_bytes(CHECKPOINT)
	var scratch: FileAccess = FileAccess.open(SCRATCH_BASELINE, FileAccess.WRITE)
	assert_object(scratch).is_not_null()
	scratch.store_buffer(checkpoint_bytes)
	scratch.close()
	assert_str(FileAccess.get_sha256(SCRATCH_BASELINE)).is_equal(BASELINE_SHA)
	assert_bool(FileAccess.file_exists(CANDIDATE)).is_true()
	var report: Dictionary = Helper.stage_files(SCRATCH_BASELINE, CANDIDATE, SCRATCH_STAGED)
	assert_bool(report.ok).override_failure_message(str(report.errors)).is_true()
	assert_str(FileAccess.get_sha256(SCRATCH_BASELINE)).is_equal(BASELINE_SHA)
	assert_array(Helper.remove_spans(FileAccess.get_file_as_bytes(SCRATCH_STAGED), report.inserted_spans)).is_equal(checkpoint_bytes)
	var packed: PackedScene = ResourceLoader.load(SCRATCH_STAGED, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	assert_object(packed).is_not_null()
	var root: Node = packed.instantiate()
	assert_object(root).is_not_null()
	root.free()


func _scene_text(newline: String, painted: bool) -> String:
	var text: String = "[gd_scene format=3]" + newline + '[ext_resource type="TileSet" path="%s" id="3"]' % Helper.CANONICAL_TILE_SET_PATH + newline + newline + "unrelated = \"preserve me\"" + newline
	for spec: Dictionary in Helper.LAYERS:
		text += _block(String(spec.name), int(spec.id), newline, painted)
	text += '[node name="MarkerTileLayer" type="TileMapLayer" parent="GameplayRoot/LayoutRoot" unique_id=773819837]' + newline
	text += 'tile_set = ExtResource("4")' + newline
	return text


func _block(name: String, unique_id: int, newline: String, painted: bool) -> String:
	var text: String = '[node name="%s" type="TileMapLayer" parent="GameplayRoot/LayoutRoot" unique_id=%d]' % [name, unique_id] + newline
	if painted:
		text += 'tile_map_data = PackedByteArray("AAAA")' + newline
	text += Helper.TILE_SET_LINE + newline + newline
	return text
