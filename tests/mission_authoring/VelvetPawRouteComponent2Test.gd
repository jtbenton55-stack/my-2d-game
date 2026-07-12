extends GdUnitTestSuite

const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const QA_PANEL_SCRIPT := preload("res://src/missions/iso/runtime/MissionQAChecklistPanel.gd")


func test_component_2_authoring_contract_is_wired() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	assert_object(packed).is_not_null()
	var mission: Node = auto_free(packed.instantiate()) as Node
	var mechanics: Node = mission.get_node("GameplayRoot/MissionMechanics")
	var floor_music_a: Node = mechanics.get_node("MusicTriggerZone_velvet_paw_jazz_club_music_trigger_zone_01")
	var floor_music_b: Node = mechanics.get_node("MusicTriggerZone_velvet_paw_jazz_club_music_trigger_zone_03")
	assert_str(String(floor_music_a.music_key)).is_equal("velvet_paw_floor")
	assert_str(String(floor_music_b.music_key)).is_equal("velvet_paw_floor")
	assert_str(String(floor_music_a.mechanic_id)).is_not_equal(String(floor_music_b.mechanic_id))
	assert_bool(floor_music_a.loop_music).is_true()

	var bar_task: Node = mechanics.get_node("BelievableTaskZone_velvet_paw_jazz_club_believable_task_zone_01")
	assert_str(String(bar_task.task_id)).is_equal("velvet_paw_clear_glasses")
	assert_str(String(bar_task.cover_story_id)).is_equal("velvet_paw_new_staff")
	assert_str(bar_task.completion_message).contains("Cover established")

	var inspection: Node = mechanics.get_node("InspectionZone_velvet_paw_jazz_club_inspection_zone_02")
	assert_object(inspection.rule_set).is_not_null()
	assert_int(inspection.interaction_mode).is_equal(0)
	assert_str(String(inspection.accepted_flag)).is_equal("vpj_floor_inspection_passed")
	assert_str(String(inspection.rejected_flag)).is_equal("vpj_floor_inspection_rejected")

	var wait_marker: Node = mechanics.get_node("BentleyWaitMarker_velvet_paw_jazz_club_bentley_wait_marker_01")
	assert_int(wait_marker.success_dialogue_lines.size()).is_equal(2)
	assert_str(String(wait_marker.success_dialogue_lines[0].get("text"))).contains("No dogs in the VIP area is racist")
	assert_str(String(wait_marker.success_dialogue_lines[1].get("text"))).contains("mom is a lawyer")
	assert_str(String(wait_marker.companion_group)).is_equal("bentley")
	assert_bool(wait_marker.one_shot).is_false()

	var protocol: Node = mechanics.get_node("ProtocolZone_velvet_paw_jazz_club_protocol_zone_01")
	assert_str(String(protocol.required_cover_story_id)).is_equal("velvet_paw_new_staff")
	assert_bool(protocol.require_companion_waiting).is_true()
	assert_str(String(protocol.required_companion_wait_marker_id)).is_equal(String(wait_marker.mechanic_id))
	var phone: Node = mechanics.get_node("SearchZone_velvet_paw_jazz_club_search_zone_01")
	assert_object(phone.requirements).is_not_null()
	var mere_hint_found := false
	for effect: Resource in phone.success_effects.effects:
		if String(effect.payload.get("speaker", "")) == "Mere" and String(effect.payload.get("text", "")).contains("dead drop"):
			mere_hint_found = true
	assert_bool(mere_hint_found).is_true()
	var dead_drop: Node = mechanics.get_node("DeadDropNode_velvet_paw_jazz_club_dead_drop_node_01")
	var clue_effect_found := false
	for effect: Resource in dead_drop.success_effects.effects:
		if int(effect.effect_type) == 9 and String(effect.key) == "velvet_paw_vip_voicemail":
			clue_effect_found = true
	assert_bool(clue_effect_found).is_true()
	var vip_polaroid: Area2D = mechanics.get_node("VipChampagnePolaroid") as Area2D
	assert_str(vip_polaroid.polaroid_id).is_equal("velvet_vip_champagne_polaroid")
	assert_vector(vip_polaroid.position).is_equal(Vector2(2944.0, 2304.0))
	assert_str(String(CollectibleManager.get_polaroid_info(vip_polaroid.polaroid_id).get("title", ""))).is_equal("Champagne for One")
	var gate_shape := mission.get_node("GameplayRoot/RouteBlockers/VipProtocolGateBlocker/GateShape") as CollisionShape2D
	assert_bool(gate_shape.disabled).is_false()
	assert_vector((gate_shape.shape as RectangleShape2D).size).is_equal(Vector2(64.0, 192.0))
	assert_float(float(bar_task.interact_duration)).is_equal(1.5)
	assert_str(String(bar_task.suspicious_action_kind)).is_equal("tampering")
	var distraction: Node = mechanics.get_node("DistractionObject_velvet_paw_jazz_club_distraction_object_01")
	assert_float(float(distraction.noise_radius)).is_equal(460.0)
	assert_bool(bool(distraction.route_to_alert_controller)).is_true()
	for pickup_name: String in [
		"InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_01",
		"InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_02",
		"InventoryPickupNode_velvet_paw_jazz_club_inventory_pickup_node_03",
		"RewardNode_velvet_paw_jazz_club_reward_node_01",
	]:
		var pickup: Node = mechanics.get_node(pickup_name)
		assert_str(String(pickup.suspicious_action_kind)).is_equal("theft")
		assert_float(float(pickup.interact_duration)).is_greater(0.0)


func test_component_2_security_authors_are_runtime_ready() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	var mission: Node = auto_free(packed.instantiate()) as Node
	var security: Node = mission.get_node("GameplayRoot/SecurityAuthoringRoot")
	var spawn_a: Node = security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_01")
	var spawn_b: Node = security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_02")
	var reinforcement: Node = security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_03")
	var vip_reinforcement: Node = security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_08")
	assert_bool(spawn_a.spawn_on_ready).is_true()
	assert_bool(spawn_b.spawn_on_ready).is_true()
	for suffix: String in ["04", "05", "06", "07"]:
		var added_spawn: Node = security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_%s" % suffix)
		assert_bool(added_spawn.spawn_on_ready).is_true()
	assert_object(spawn_a.inspection_rule_set).is_not_null()
	assert_object(spawn_b.inspection_rule_set).is_not_null()
	assert_object(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_04").inspection_rule_set).is_null()
	assert_object(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_05").inspection_rule_set).is_null()
	assert_bool(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_04").ignore_social_cover).is_true()
	assert_bool(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_05").ignore_social_cover).is_true()
	assert_bool(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_04").hostile_on_player_enter_rect.has_area()).is_true()
	assert_bool(security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_05").hostile_on_player_enter_rect.has_area()).is_true()
	var camera_authors := security.find_children("SecurityCameraAuthor_*", "Node2D", false, false)
	assert_int(camera_authors.size()).is_equal(12)
	for camera_author: Node in camera_authors:
		assert_bool(camera_author.require_line_of_sight).is_true()
	assert_array(reinforcement.trigger_events).contains([&"wrong_note_alarm"])
	assert_array(vip_reinforcement.trigger_events).contains([&"vip_trespass_alarm"])
	assert_int(vip_reinforcement.spawn_count).is_equal(3)
	var vip_camera: Node = security.get_node("SecurityCameraAuthor_velvet_paw_jazz_club_security_camera_author_01")
	assert_float(float(vip_camera.range_px)).is_equal(520.0)
	assert_float(float(vip_camera.sweep_arc_degrees)).is_equal(110.0)
	assert_bool(bool(vip_camera.exposure_requires_player_movement)).is_true()
	assert_float(float(vip_camera.player_movement_threshold)).is_equal(8.0)


func test_component_2_dev_overlay_is_created_by_controller() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	var mission: Node = auto_free(packed.instantiate()) as Node
	add_child(mission)
	await get_tree().process_frame
	await get_tree().process_frame
	var controller: Node = mission.get_node("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")
	var overlay: Node2D = controller.get_node_or_null("CollisionDebugOverlay") as Node2D
	assert_object(overlay).is_not_null()
	assert_int(overlay.z_index).is_equal(3900)
	assert_bool(overlay.visible).is_false()
	var panel: Panel = auto_free(QA_PANEL_SCRIPT.new()) as Panel
	add_child(panel)
	panel.call("set_mission", mission)
	var map_toggle := panel.get_node("VelvetRedMapOverlayToggle") as CheckButton
	assert_bool(map_toggle.visible).is_true()
	var player := get_tree().get_first_node_in_group("player")
	var bentley := get_tree().get_first_node_in_group("bentley")
	assert_object(player).is_not_null()
	assert_object(bentley).is_not_null()
	assert_bool(bool(overlay.call("_is_overlay_subject", player))).is_false()
	assert_bool(bool(overlay.call("_is_overlay_subject", bentley))).is_false()
	assert_bool(bool(overlay.call("_is_overlay_subject", bentley.get_node("DistractionArea")))).is_false()
	var production_wait_marker: Node = mission.get_node("GameplayRoot/MissionMechanics/BentleyWaitMarker_velvet_paw_jazz_club_bentley_wait_marker_01")
	var wait_result: Dictionary = production_wait_marker.call("run_command", player, "test")
	assert_bool(bool(wait_result.get("ok", false))).is_true()
	assert_str(String((bentley.call("get_command_state") as Dictionary).get("wait_marker_id", ""))).is_equal(String(production_wait_marker.mechanic_id))
	var production_protocol: Node = mission.get_node("GameplayRoot/MissionMechanics/ProtocolZone_velvet_paw_jazz_club_protocol_zone_01")
	assert_bool(bool(production_protocol.call("_companion_is_waiting"))).is_true()
	var gameplay_camera := mission.find_child("Camera2D", true, false)
	assert_object(gameplay_camera).is_not_null()
	assert_bool(bool(overlay.call("_is_overlay_subject", gameplay_camera))).is_false()
	map_toggle.button_pressed = true
	await get_tree().process_frame
	assert_bool(overlay.visible).is_true()
	map_toggle.button_pressed = false
	assert_bool(overlay.visible).is_false()
	await get_tree().physics_frame
	var runtime_security: Node = mission.get_node("GameplayRoot/SecurityAuthoringRoot")
	var runtime_spawn_a: Node = runtime_security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_01")
	var runtime_spawn_b: Node = runtime_security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_02")
	assert_bool(String(runtime_spawn_a.last_spawn_result).begins_with("spawned")).is_true()
	assert_bool(String(runtime_spawn_b.last_spawn_result).begins_with("spawned")).is_true()
	var enemies: Node = mission.get_node("EntityRoot/Enemies")
	assert_int(enemies.get_child_count()).is_greater_equal(6)
	var cameras: Node = mission.get_node("EntityRoot/Cameras")
	var authored_camera_count := 0
	for camera: Node in cameras.get_children():
		assert_object(camera.get_node_or_null("CameraVisual")).is_not_null()
		if bool(camera.get_meta("authored_camera", false)):
			authored_camera_count += 1
	assert_int(authored_camera_count).is_equal(12)
	controller.call("_commit_vip_trespass_alarm")
	await get_tree().process_frame
	var vip_spawn: Node = runtime_security.get_node("GuardSpawnAuthor_velvet_paw_jazz_club_guard_spawn_author_08")
	assert_int(int(vip_spawn.last_spawned_count)).is_equal(3)
	assert_int(enemies.get_child_count()).is_greater_equal(9)
	for guard: Node in get_tree().get_nodes_in_group("enemy"):
		assert_bool(bool(guard.call("is_hostile"))).is_true()
	var floor_music: Node = mission.get_node("GameplayRoot/MissionMechanics/MusicTriggerZone_velvet_paw_jazz_club_music_trigger_zone_01")
	var music_result: Dictionary = floor_music.call("_request_music_change")
	await get_tree().process_frame
	assert_bool(bool(music_result.get("ok", false))).is_true()
	assert_bool(AudioManager.is_music_playing("velvet_paw_floor")).is_true()
	AudioManager.stop_music()
