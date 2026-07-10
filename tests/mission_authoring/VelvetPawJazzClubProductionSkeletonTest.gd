extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const BLUEPRINT_PATH := "res://docs/blueprints/velvet_paw_jazz_club.blueprint.json"
const BlueprintSpec := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")
const MissionControllerScript := preload("res://src/missions/iso/runtime/VelvetPawJazzClubMissionController.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")


func before() -> void:
	_reset_runtime_state()


func after() -> void:
	_reset_runtime_state()


func test_scene_loads_and_instantiates() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var root := packed.instantiate()
	assert_object(root).is_not_null()
	assert_str(root.name).is_equal("VelvetPawJazzClub_Editable")
	var bridge := root.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionInteractionBridge")
	assert_object(bridge).is_not_null()
	assert_bool(bool(bridge.get("include_legacy_candidates"))).is_false()
	assert_object(root.get_node_or_null("GameplayRoot/RuntimeHelpers/MissionAlertController")).is_not_null()
	assert_object(root.get_node_or_null("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")).is_not_null()
	var blueprint_layer := root.get_node_or_null("GameplayRoot/LayoutRoot/AuthoringBlueprintLayer")
	assert_object(blueprint_layer).is_not_null()
	assert_str(String(blueprint_layer.get("blueprint_path"))).is_equal(BLUEPRINT_PATH)
	root.free()


func test_mission_catalog_resolves_playable_scene() -> void:
	assert_str(MissionSceneResolver.resolve_playable_scene_path(MISSION_ID)).is_equal(SCENE_PATH)
	var report: Dictionary = MissionSceneResolver.get_resolution_report(MISSION_ID)
	assert_bool(report.get("ok", false)).is_true()
	assert_str(String(report.get("chosen_playable_path", ""))).is_equal(SCENE_PATH)


func test_blueprint_coverage_is_complete() -> void:
	var loaded := BlueprintSpec.load_spec(BLUEPRINT_PATH)
	assert_bool(loaded.get("ok", false)).is_true()
	var slots: Array = BlueprintSpec.mechanic_slots(loaded.get("spec", {}))
	assert_int(slots.size()).is_equal(68)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var coverage := BlueprintSpec.coverage(loaded.get("spec", {}), root)
	assert_int(coverage.get("total", 0)).is_equal(68)
	assert_int((coverage.get("placed", []) as Array).size()).is_equal(68)
	assert_array(coverage.get("missing", [])).is_empty()
	assert_array(coverage.get("mismatched", [])).is_empty()
	root.free()


func test_representative_stubs_match_blueprint_contract() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var player_start := root.get_node("GameplayRoot/MarkerRoot/Spawns/PlayerStartMarker_start_main") as Marker2D
	assert_vector(player_start.position).is_equal(Vector2(256, 2880))
	assert_str(String(player_start.get("marker_id"))).is_equal("start_main")
	var terminal := root.get_node("GameplayRoot/MissionMechanics/TerminalHackNode_velvet_paw_jazz_club_terminal_hack_node_01") as Area2D
	assert_vector(terminal.position).is_equal(Vector2(1152, 640))
	assert_str(String(terminal.get("mechanic_id"))).is_equal("velvet_paw_jazz_club.terminal_hack_node.01")
	var queue := root.get_node("GameplayRoot/MissionMechanics/InspectionZone_velvet_paw_jazz_club_inspection_zone_01") as Area2D
	var shape := queue.get_node("CollisionShape2D") as CollisionShape2D
	assert_vector((shape.shape as RectangleShape2D).size).is_equal(Vector2(256, 192))
	var beam := root.get_node("GameplayRoot/SecurityAuthoringRoot/SecurityBeamAuthor_velvet_paw_jazz_club_security_beam_author_01")
	assert_str(String(beam.get("beam_id"))).is_equal("velvet_paw_jazz_club.security_beam_author.01")
	root.free()


func test_staff_gate_requirement_blocks_then_passes() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var gate := root.get_node("GameplayRoot/MissionMechanics/LockedInteractionNode_velvet_paw_jazz_club_locked_interaction_node_01")
	assert_bool(gate.call("evaluate_requirements").get("ok", true)).is_false()
	_set_flag("vpj_staff_badge_collected")
	assert_bool(gate.call("evaluate_requirements").get("ok", false)).is_true()
	root.free()


func test_staff_badge_soft_voicemail_dependency_is_authored() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var badge := root.get_node("GameplayRoot/MissionMechanics/InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_01")
	var requirements: Resource = badge.get("requirements")
	assert_object(requirements).is_not_null()
	assert_int(requirements.requirements.size()).is_equal(1)
	assert_str(String(requirements.requirements[0].key)).is_equal("vpj_vip_voicemail_found")
	assert_bool(requirements.requirements[0].enabled).is_false()
	assert_bool(badge.call("evaluate_requirements").get("ok", false)).is_true()
	root.free()


func test_extraction_requires_flags_and_objectives() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var extraction := root.get_node("GameplayRoot/MissionMechanics/ExtractionZone_velvet_paw_jazz_club_extraction_zone_01")
	assert_bool(extraction.call("can_extract").get("ok", true)).is_false()
	_set_flag("vpj_escape_hatch_open")
	_set_flag("vpj_briefcase_collected")
	for objective_id in ["solve_setlist", "recover_shard", "defeat_owner", "recover_briefcase", "open_escape"]:
		ObjectiveStepController.complete_objective(objective_id, "", MISSION_ID)
	assert_bool(extraction.call("can_extract").get("ok", false)).is_true()
	root.free()


func test_teleport_and_patrol_links_resolve() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	for zone_name in [
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_01",
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_02",
		"TeleportZone_velvet_paw_jazz_club_teleport_zone_03",
	]:
		var zone := root.get_node("GameplayRoot/MissionMechanics/%s" % zone_name)
		assert_object(zone.get_node_or_null(zone.get("target_marker_path"))).is_not_null()
	var security_root := root.get_node("GameplayRoot/SecurityAuthoringRoot")
	for spawn_name in [
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_01",
		"GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_02",
	]:
		var spawn := security_root.get_node(spawn_name)
		assert_object(security_root.call("find_patrol_route", spawn.get("patrol_route_id"))).is_not_null()
	var routes := security_root.call("get_enabled_patrol_route_authors") as Array
	assert_int(routes.size()).is_equal(2)
	for route in routes:
		assert_int((route as Node).get_child_count()).is_greater_equal(2)
	root.free()


func test_setlist_requirement_and_effect_resources_are_live() -> void:
	GameState.start_mission(MISSION_ID)
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var terminal := root.get_node("GameplayRoot/MissionMechanics/TerminalHackNode_velvet_paw_jazz_club_terminal_hack_node_01")
	assert_bool(terminal.call("evaluate_requirements").get("ok", true)).is_false()
	_set_flag("vpj_clue_setlist_read")
	_set_flag("vpj_clue_manager_read")
	assert_bool(terminal.call("evaluate_requirements").get("ok", false)).is_true()
	var applied: Dictionary = terminal.get("success_effects").call("apply_all", {"mission_id": MISSION_ID, "mechanic": terminal})
	assert_bool(applied.get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"mission_flag", "vpj_setlist_solved", {"mission_id": MISSION_ID})).is_true()
	var alarm_effect_found := false
	for effect: Resource in terminal.get("failure_effects").effects:
		if String(effect.effect_id) == "emit_wrong_note_alarm":
			alarm_effect_found = true
			assert_str(String(effect.method_name)).is_equal("trigger_wrong_note_alarm")
	assert_bool(alarm_effect_found).is_true()
	root.free()


func test_dialogue_zones_have_fallback_text_or_key() -> void:
	var root := (load(SCENE_PATH) as PackedScene).instantiate()
	var missing: Array[String] = []
	for node in root.find_children("*", "", true, false):
		if node is DialogueTriggerZone:
			var fallback_text := String(node.get("fallback_text")).strip_edges()
			var dialogue_key := String(node.get("dialogue_key")).strip_edges()
			if fallback_text == "" and dialogue_key == "":
				missing.append(str(node.get_path()))
	assert_array(missing).is_empty()
	root.free()


func test_required_dialogue_content_is_authored() -> void:
	var scene_text := FileAccess.get_file_as_string(SCENE_PATH)
	for required_line in [
		"Too many colognes. The bass line is honest, though.",
		"the staff side door stays propped open between sets.",
		"Shred before midnight. The badge is in the green room.",
		"Album arc tonight - start where we started hungry",
		"Setlist policy: five songs only",
		"House lights love you. Don't waste the downbeat.",
		"Tuck behind the bar - the rails swallow the bass spikes.",
		"That hum is the vault handshake.",
		"Bentley respects the grout lines.",
		"Grab it and don't admire the view.",
		"The club has turned hostile",
		"Bass drop. Release the escape hatch and move.",
		"Sterling's crew planted a prop ledger.",
	]:
		assert_bool(scene_text.contains(required_line)).is_true()


func test_controller_syncs_canonical_flags_and_game_state_side_effects() -> void:
	GameState.start_mission(MISSION_ID)
	var controller := MissionControllerScript.new()
	add_child(controller)
	controller.reset_attempt_state()
	_set_flag("vpj_entered_club")
	_set_flag("vpj_staff_badge_collected")
	_set_flag("vpj_setlist_solved")
	_set_flag("vpj_shard_collected")
	MissionInventoryScript.add_item("velvet_paw_basement_keycard", 1, {"category": "credential"})
	controller.sync_from_mission_facts()
	assert_bool(controller.entered_club).is_true()
	assert_bool(controller.staff_badge_collected).is_true()
	assert_bool(controller.setlist_solved).is_true()
	assert_bool(controller.shard_collected).is_true()
	assert_bool(controller.basement_keycard_collected).is_true()
	assert_bool(GameState.velvet_paw_basement_shard_collected).is_true()
	assert_bool(GameState.velvet_paw_basement_keycard_collected).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_false()
	controller.mark_returned_upstairs()
	assert_bool(controller.returned_upstairs_with_shard).is_true()
	assert_bool(GameState.velvet_paw_club_hostile).is_true()
	controller.queue_free()


func _set_flag(flag_id: String) -> void:
	MissionFactBridge.set_fact_value(&"mission_flag", flag_id, true, {"mission_id": MISSION_ID})


func _reset_runtime_state() -> void:
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	GameState.velvet_paw_club_hostile = false
	GameState.velvet_paw_basement_shard_collected = false
	GameState.velvet_paw_basement_keycard_collected = false
	for key: Variant in GameState.dialogue_flags.keys():
		if String(key).begins_with("mission_flag:%s:" % MISSION_ID):
			GameState.dialogue_flags.erase(key)
	MissionInventoryScript.clear_mission_items()
	QuestManager.objectives.clear()
	QuestManager.objective_records.clear()
	QuestManager.active_objectives.clear()
	QuestManager.completed_objectives.clear()
