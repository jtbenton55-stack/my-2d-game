extends GdUnitTestSuite

const MISSION_ID := "velvet_paw_jazz_club"
const SCENE_PATH := "res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn"
const MECHANICS := "GameplayRoot/MissionMechanics/"
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")


func before() -> void:
	_reset_state()


func after() -> void:
	_reset_state()


func test_route_component_runtime_helpers_and_front_contract_are_authored() -> void:
	var root := _instantiate()
	assert_array(root.get("layout_collision_excluded_cells")).has_size(12)
	assert_object(root.get_node_or_null("IsoMissionDebugPanel")).is_not_null()
	var bridge := root.get_node("GameplayRoot/RuntimeHelpers/MissionInteractionBridge")
	assert_str(str(bridge.get("prompt_target_path"))).is_equal("../../../HUD/MissionHudStrip/ControlHint")
	assert_bool(bridge.get("action_scan_or_debug") == null).is_true()
	var provider := root.get_node("GameplayRoot/RuntimeHelpers/MissionCaseHintProvider")
	assert_int((provider.get("hints") as Array).size()).is_equal(3)
	var rope := root.get_node("GameplayRoot/RouteBlockers/FrontEntranceCrowdRopeBlocker/RopeShape") as CollisionShape2D
	assert_vector(rope.position).is_equal(Vector2(1440, 2528))
	assert_vector((rope.shape as RectangleShape2D).size).is_equal(Vector2(192, 64))
	assert_bool(rope.disabled).is_false()
	root.free()


func test_front_inspection_requires_both_vip_facts_and_opens_rope() -> void:
	var root := _instantiate()
	var inspection := root.get_node(MECHANICS + "InspectionZone_velvet_paw_jazz_club_inspection_zone_01")
	assert_bool((inspection.call("evaluate_requirements") as Dictionary).get("ok", true)).is_false()
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapter.set_cover_story("velvet_paw_vip_guest", {}, context)
	assert_bool((inspection.call("evaluate_requirements") as Dictionary).get("ok", true)).is_false()
	SocialStealthAdapter.grant_credential("velvet_paw_vip_wristband", {}, context)
	assert_bool((inspection.call("evaluate_requirements") as Dictionary).get("ok", false)).is_true()
	var result := inspection.call("activate", null, "route_component_1_test") as Dictionary
	assert_bool(result.get("ok", false)).is_true()
	assert_bool((root.get_node("GameplayRoot/RouteBlockers/FrontEntranceCrowdRopeBlocker/RopeShape") as CollisionShape2D).disabled).is_true()
	assert_bool((root.get_node("ArtRoot/FrontEntranceCrowdRope") as CanvasItem).visible).is_false()
	assert_bool(MissionFactBridge.get_fact_value(&"mission_flag", "vpj_front_vip_accepted", context)).is_true()
	root.free()


func test_front_rejection_is_timed_non_manual_and_skipped_for_vip() -> void:
	var root := _instantiate()
	var context := {"mission_id": MISSION_ID}
	SocialStealthAdapter.clear_cover_story("velvet_paw_vip_guest", context)
	SocialStealthAdapter.revoke_credential("velvet_paw_vip_wristband", context)
	var trigger := root.get_node(MECHANICS + "DialogueTriggerZone_velvet_paw_front_bouncer_sequence")
	var lines := (trigger.get("dialogue_payload") as Dictionary).get("lines", []) as Array
	assert_int(lines.size()).is_equal(2)
	assert_str(String((lines[0] as Dictionary).get("text", ""))).is_equal("You're not on the list.")
	assert_str(String((lines[1] as Dictionary).get("text", ""))).is_equal("Do they know who I am?!")
	for line: Dictionary in lines:
		assert_float(float(line.get("auto_advance_seconds", 0.0))).is_equal(2.5)
		assert_bool(bool(line.get("allow_manual_advance", true))).is_false()
		assert_bool(bool(line.get("allow_skip", true))).is_false()
	assert_bool((trigger.call("evaluate_requirements") as Dictionary).get("ok", false)).is_true()
	SocialStealthAdapter.set_cover_story("velvet_paw_vip_guest", {}, context)
	SocialStealthAdapter.grant_credential("velvet_paw_vip_wristband", {}, context)
	assert_bool((trigger.call("evaluate_requirements") as Dictionary).get("ok", true)).is_false()
	root.free()


func test_eavesdrop_phone_and_dead_drop_present_and_transfer_information() -> void:
	var root := _instantiate()
	var eavesdrop := root.get_node(MECHANICS + "EavesdropZone_velvet_paw_jazz_club_eavesdrop_zone_01")
	var eavesdrop_result := eavesdrop.call("complete_eavesdrop", null, "route_component_1_test") as Dictionary
	assert_bool(eavesdrop_result.get("ok", false)).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).contains("staff side door")
	DialogueManager.end_dialogue()
	var phone := root.get_node(MECHANICS + "SearchZone_velvet_paw_jazz_club_search_zone_01")
	var blocked_phone_result := phone.call("search", null, "route_component_1_blocked_test") as Dictionary
	assert_bool(blocked_phone_result.get("ok", true)).is_false()
	MissionFactBridge.set_fact_value(&"mission_flag", "vpj_vip_protocol_complete", true, {"mission_id": MISSION_ID})
	var phone_result := phone.call("search", null, "route_component_1_test") as Dictionary
	assert_bool(phone_result.get("ok", false)).is_true()
	assert_bool(MissionInventoryScript.has_item("velvet_paw_vip_voicemail_copy")).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).contains("dead drop")
	DialogueManager.end_dialogue()
	var dead_drop := root.get_node(MECHANICS + "DeadDropNode_velvet_paw_jazz_club_dead_drop_node_01")
	var drop_result := dead_drop.call("use_dead_drop", null, "route_component_1_test") as Dictionary
	assert_bool(drop_result.get("ok", false)).is_true()
	assert_bool(MissionInventoryScript.has_item("velvet_paw_vip_voicemail_copy")).is_false()
	assert_bool(MissionFactBridge.get_fact_value(&"mission_flag", "vpj_vip_voicemail_copy_dropped", {"mission_id": MISSION_ID})).is_true()
	assert_str(String(DialogueManager.current_lines[0].get("text", ""))).contains("clue board")
	MissionFactBridge.clear_fact_value(&"mission_flag", "vpj_vip_protocol_complete", {"mission_id": MISSION_ID})
	root.free()


func _instantiate() -> Node:
	return (load(SCENE_PATH) as PackedScene).instantiate()


func _reset_state() -> void:
	DialogueManager.end_dialogue()
	GameState.start_mission(MISSION_ID)
	MissionInventoryScript.clear_mission_items()
	SocialStealthAdapter.reset_mission(MISSION_ID)
