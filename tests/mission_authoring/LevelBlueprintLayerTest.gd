# GdUnit4 tests for the dev-only level blueprint system:
# spec loading/validation, coverage diffing, runtime self-destruct,
# Phase0J redundant stripping, and Mission Dock integration tokens.
extends GdUnitTestSuite

const SpecHelper := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")
const BlueprintLayerScript := preload("res://src/tools/authoring/AuthoringBlueprintLayer.gd")
const HiderScript := preload("res://src/missions/iso/runtime/Phase0JRuntimeAuthoringHider.gd")
const SearchZoneScript := preload("res://src/missions/iso/authoring/mechanics/SearchZone.gd")

const STARTER_SPEC_PATH := "res://docs/blueprints/starter_room.blueprint.json"
const LAUNDROMAT_SPEC_PATH := "res://docs/blueprints/laundromat_heist.blueprint.json"


func test_reference_blueprints_load_and_validate() -> void:
	for path in [STARTER_SPEC_PATH, LAUNDROMAT_SPEC_PATH]:
		var result: Dictionary = SpecHelper.load_spec(path)
		assert_bool(result.get("ok", false)).override_failure_message(
			"Spec %s should validate but got errors: %s" % [path, str(result.get("errors", []))]
		).is_true()
		var spec: Dictionary = result.get("spec", {})
		assert_str(String(spec.get("blueprint_id", ""))).is_not_empty()
		assert_bool(SpecHelper.mechanic_slots(spec).size() > 0).is_true()
		assert_bool(SpecHelper.regions(spec).size() > 0).is_true()


func test_missing_spec_reports_error() -> void:
	var result: Dictionary = SpecHelper.load_spec("res://docs/blueprints/does_not_exist.blueprint.json")
	assert_bool(result.get("ok", true)).is_false()
	assert_bool((result.get("errors", []) as Array).is_empty()).is_false()


func test_every_mission_dock_mechanic_type_has_category() -> void:
	var dock_text := FileAccess.get_file_as_string("res://addons/mission_dock/MissionDock.gd")
	var header := dock_text.find("const MECHANIC_TYPES: Array[String] = [")
	var open_index := dock_text.find("= [", header) + 2
	var end := dock_text.find("]", open_index)
	var block := dock_text.substr(open_index, end - open_index)
	var regex := RegEx.new()
	regex.compile("\"([A-Za-z0-9]+)\"")
	var type_count := 0
	for regex_match in regex.search_all(block):
		var mechanic_type := regex_match.get_string(1)
		type_count += 1
		assert_bool(SpecHelper.CATEGORY_BY_TYPE.has(mechanic_type)).override_failure_message(
			"LevelBlueprintSpec.CATEGORY_BY_TYPE missing Mission Dock type '%s'" % mechanic_type
		).is_true()
	assert_int(type_count).is_equal(SpecHelper.CATEGORY_BY_TYPE.size())


func test_layer_frees_itself_at_runtime() -> void:
	var layer := Node2D.new()
	layer.set_script(BlueprintLayerScript)
	layer.name = "AuthoringBlueprintLayer"
	add_child(layer)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(is_instance_valid(layer) and layer.is_inside_tree()).override_failure_message(
		"AuthoringBlueprintLayer must free itself when running outside the editor"
	).is_false()


func test_phase0j_hider_strips_blueprint_layer_nodes() -> void:
	var root := Node2D.new()
	add_child(root)
	var overlay := Node2D.new()
	overlay.name = "AuthoringBlueprintLayer"
	root.add_child(overlay)
	var hider := HiderScript.new()
	root.add_child(hider)
	hider.call("_hide_authoring_blueprint_layers", root)
	assert_bool(overlay.visible).is_false()
	assert_bool(overlay.has_meta("phase_0ja_hidden_at_runtime")).is_true()
	root.queue_free()


func test_coverage_reports_placed_missing_and_mismatched() -> void:
	var result: Dictionary = SpecHelper.load_spec(STARTER_SPEC_PATH)
	var spec: Dictionary = result.get("spec", {})
	var root := Node2D.new()
	add_child(root)
	var mechanics := Node2D.new()
	mechanics.name = "MissionMechanics"
	root.add_child(mechanics)
	# Correctly placed slot: SearchZone carrying the suggested id.
	var search := Area2D.new()
	search.set_script(SearchZoneScript)
	search.set("mechanic_id", StringName("starter_room.search_zone.01"))
	mechanics.add_child(search)
	# Mismatched slot: reward suggested id on a SearchZone node.
	var wrong_type := Area2D.new()
	wrong_type.set_script(SearchZoneScript)
	wrong_type.set("mechanic_id", StringName("starter_room.reward_node.01"))
	mechanics.add_child(wrong_type)
	var coverage: Dictionary = SpecHelper.coverage(spec, root)
	assert_int(int(coverage.get("total", 0))).is_equal(5)
	assert_array(coverage.get("placed", [])).contains(["entry_search"])
	assert_array(coverage.get("mismatched", [])).contains(["reward_pickup"])
	assert_array(coverage.get("missing", [])).contains(["player_start", "exit_route_unlock", "extraction"])
	root.queue_free()


func test_slot_helpers_and_parent_routing() -> void:
	var result: Dictionary = SpecHelper.load_spec(LAUNDROMAT_SPEC_PATH)
	var spec: Dictionary = result.get("spec", {})
	var camera_slot: Dictionary = SpecHelper.find_slot(spec, "office_camera")
	assert_bool(camera_slot.is_empty()).is_false()
	assert_str(SpecHelper.default_parent_path_for_type(String(camera_slot.get("mechanic_type", "")))).is_equal("GameplayRoot/SecurityAuthoringRoot")
	assert_str(SpecHelper.default_parent_path_for_type("PlayerStartMarker")).is_equal("GameplayRoot/MarkerRoot/Spawns")
	assert_str(SpecHelper.default_parent_path_for_type("SearchZone")).is_equal("MissionMechanics")
	var start_slot: Dictionary = SpecHelper.find_slot(spec, "player_start")
	assert_that(SpecHelper.slot_position(start_slot)).is_equal(Vector2(192, 1408))
	var extraction_slot: Dictionary = SpecHelper.find_slot(spec, "extraction")
	assert_that(SpecHelper.slot_size(extraction_slot)).is_equal(Vector2(128, 128))


func test_mission_dock_carries_blueprint_integration() -> void:
	var dock_text := FileAccess.get_file_as_string("res://addons/mission_dock/MissionDock.gd")
	assert_bool(dock_text.contains("Place From Blueprint")).is_true()
	assert_bool(dock_text.contains("Refresh Blueprint Slots")).is_true()
	assert_bool(dock_text.contains("Prefill From Selected Slot")).is_true()
	assert_bool(dock_text.contains("_audit_blueprint_coverage")).is_true()
	assert_bool(dock_text.contains("blueprint_slot_missing")).is_true()
	assert_bool(FileAccess.file_exists("res://src/tools/editor/level_blueprint/level_blueprint_validator.py")).is_true()
	assert_bool(FileAccess.file_exists("res://src/tools/editor/level_blueprint/generate_blueprint_guide.py")).is_true()
