# GdUnit4 tests for Phase 13A-13G social stealth identity authoring.
extends GdUnitTestSuite

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const CoverStoryDataScript := preload("res://src/missions/iso/social/CoverStoryData.gd")
const CredentialDataScript := preload("res://src/missions/iso/social/CredentialData.gd")
const InspectionRuleSetScript := preload("res://src/missions/iso/social/InspectionRuleSet.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const InspectionZoneScript := preload("res://src/missions/iso/authoring/mechanics/InspectionZone.gd")
const BelievableTaskZoneScript := preload("res://src/missions/iso/authoring/mechanics/BelievableTaskZone.gd")
const ProtocolZoneScript := preload("res://src/missions/iso/authoring/mechanics/ProtocolZone.gd")
const ProfessionalismMeterNodeScript := preload("res://src/missions/iso/authoring/mechanics/ProfessionalismMeterNode.gd")
const CleanlinessGateScript := preload("res://src/missions/iso/authoring/mechanics/CleanlinessGate.gd")


func test_cover_story_credentials_and_social_fact_bridge() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "unit_test"}
	var cover := CoverStoryDataScript.new()
	cover.cover_story_id = &"staff_cleaner"
	cover.display_name = "Staff Cleaner"
	cover.professionalism_bonus = 1
	var cover_result: Dictionary = cover.activate(context)
	assert_bool(cover_result.get("ok", false)).is_true()
	assert_str(String(MissionFactBridge.get_fact_value(&"social_cover_story_active", "", context))).is_equal("staff_cleaner")

	var credential := CredentialDataScript.new()
	credential.credential_id = &"staff_badge"
	credential.display_name = "Staff Badge"
	var credential_result: Dictionary = credential.grant(context)
	assert_bool(credential_result.get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_credential_active", "staff_badge", context)).is_true()
	assert_int(int(MissionFactBridge.get_fact_value(&"professionalism_score", "", context))).is_equal(1)
	_restore_game_state(snapshot)


func test_social_effects_route_through_effect_applier() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "effect_test"}
	var cover := MissionEffectScript.new()
	cover.effect_type = MissionEffectScript.EffectType.ACTIVATE_COVER_STORY
	cover.key = "delivery_vendor"
	cover.payload = {"display_name": "Delivery Vendor"}
	assert_bool(cover.apply(context).get("ok", false)).is_true()

	var credential := MissionEffectScript.new()
	credential.effect_type = MissionEffectScript.EffectType.GRANT_CREDENTIAL
	credential.key = "delivery_badge"
	assert_bool(credential.apply(context).get("ok", false)).is_true()

	var professionalism := MissionEffectScript.new()
	professionalism.effect_type = MissionEffectScript.EffectType.ADJUST_PROFESSIONALISM
	professionalism.value_type = "int"
	professionalism.value_int = 2
	assert_bool(professionalism.apply(context).get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_credential_active", "delivery_badge", context)).is_true()
	assert_int(int(MissionFactBridge.get_fact_value(&"professionalism_score", "", context))).is_equal(2)
	_restore_game_state(snapshot)


func test_inspection_rule_set_accepts_and_rejects_social_state() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "rule_test"}
	var rules := InspectionRuleSetScript.new()
	rules.accepted_cover_story_ids = [&"staff_cleaner"]
	rules.required_credential_ids = [&"staff_badge"]
	rules.min_professionalism = 1
	var rejected: Dictionary = rules.evaluate(context)
	assert_bool(rejected.get("ok", true)).is_false()

	SocialStealthAdapterScript.set_cover_story("staff_cleaner", {}, context)
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)
	SocialStealthAdapterScript.set_professionalism(1, context)
	var accepted: Dictionary = rules.evaluate(context)
	assert_bool(accepted.get("ok", false)).is_true()
	_restore_game_state(snapshot)


func test_social_mechanic_nodes_drive_believable_action_flow() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var context := {"mission_id": "test_mission", "source_id": "mechanic_test"}
	SocialStealthAdapterScript.set_cover_story("staff_cleaner", {}, context)
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, context)
	SocialStealthAdapterScript.set_cleanliness(1, context)

	var meter := ProfessionalismMeterNodeScript.new()
	meter.mission_id_override = "test_mission"
	meter.apply_initial_on_ready = false
	add_child(meter)
	assert_object(meter).is_instanceof(ProfessionalismMeterNodeScript)
	assert_bool(meter.adjust_professionalism(1).get("ok", false)).is_true()

	var task := BelievableTaskZoneScript.new()
	task.mission_id_override = "test_mission"
	task.mechanic_id = &"restock_task"
	task.task_id = &"restock_wipes"
	task.completed_flag = &"restock_wipes_done"
	add_child(task)
	assert_object(task).is_instanceof(MechanicAreaBaseScript)
	assert_bool(task.complete_task(null, "test").get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_task_complete", "restock_wipes", context)).is_true()

	var protocol := ProtocolZoneScript.new()
	protocol.mission_id_override = "test_mission"
	protocol.mechanic_id = &"wipe_protocol_node"
	protocol.protocol_id = &"wipe_protocol"
	protocol.required_cover_story_id = &"staff_cleaner"
	protocol.required_credential_id = &"staff_badge"
	add_child(protocol)
	assert_bool(protocol.complete_protocol(null, "test").get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_protocol_complete", "wipe_protocol", context)).is_true()

	var rules := InspectionRuleSetScript.new()
	rules.accepted_cover_story_ids = [&"staff_cleaner"]
	rules.required_credential_ids = [&"staff_badge"]
	rules.required_protocol_ids = [&"wipe_protocol"]
	rules.required_task_ids = [&"restock_wipes"]
	rules.min_professionalism = 2
	rules.min_cleanliness = 1
	var inspection := InspectionZoneScript.new()
	inspection.mission_id_override = "test_mission"
	inspection.mechanic_id = &"staff_hall_check_node"
	inspection.inspection_id = &"staff_hall_check"
	inspection.set("rule_set", rules)
	inspection.accepted_flag = &"staff_hall_accepted"
	add_child(inspection)
	var inspection_result: Dictionary = inspection.inspect_actor(null, "test")
	assert_bool(inspection_result.get("ok", false)).is_true()
	assert_bool(MissionFactBridge.get_fact_value(&"social_inspection_passed", "staff_hall_check", context)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:staff_hall_accepted", false)).is_true()

	var gate := CleanlinessGateScript.new()
	gate.mission_id_override = "test_mission"
	gate.mechanic_id = &"clean_gate"
	gate.min_cleanliness = 1
	gate.required_protocol_id = &"wipe_protocol"
	gate.unlocked_flag = &"clean_gate_unlocked"
	add_child(gate)
	assert_bool(gate.unlock(null, "test").get("ok", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:clean_gate_unlocked", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(meter)
	_free_node(task)
	_free_node(protocol)
	_free_node(inspection)
	_free_node(gate)


func test_mission_result_receives_social_summary() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	GameState.start_mission("test_mission")
	SocialStealthAdapterScript.set_cover_story("staff_cleaner", {}, {"mission_id": "test_mission"})
	SocialStealthAdapterScript.grant_credential("staff_badge", {}, {"mission_id": "test_mission"})
	SocialStealthAdapterScript.record_inspection("staff_hall_check", true, {"ok": true}, {"mission_id": "test_mission"})
	var result: Dictionary = GameState.complete_mission("test_mission")
	assert_bool(result.has("social_stealth")).is_true()
	assert_str(String(result.get("social_stealth_state", ""))).is_equal("credible")
	var summary: Dictionary = result.get("social_stealth", {})
	assert_int(int(summary.get("credential_count", 0))).is_equal(1)
	_restore_game_state(snapshot)


func test_templates_and_dev_scene_contain_phase13_nodes() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/InspectionZoneTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/BelievableTaskZoneTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/ProtocolZoneTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/ProfessionalismMeterNodeTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/CleanlinessGateTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase13SocialStealthProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/InspectionZone_phase13d_inspection")).is_instanceof(InspectionZoneScript)
	assert_object(root.get_node_or_null("MissionMechanics/BelievableTaskZone_phase13e_believable_task")).is_instanceof(BelievableTaskZoneScript)
	assert_object(root.get_node_or_null("MissionMechanics/ProtocolZone_phase13f_protocol")).is_instanceof(ProtocolZoneScript)
	assert_object(root.get_node_or_null("MissionMechanics/ProfessionalismMeterNode_phase13f_professionalism")).is_instanceof(ProfessionalismMeterNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/CleanlinessGate_phase13f_cleanliness_gate")).is_instanceof(CleanlinessGateScript)
	_free_node(root)


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"is_in_mission": GameState.is_in_mission,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"completed_missions": GameState.completed_missions.duplicate(true),
		"last_mission_result": GameState.last_mission_result.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.is_in_mission = bool(snapshot.get("is_in_mission", false))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.completed_missions = (snapshot.get("completed_missions", []) as Array).duplicate(true)
	GameState.last_mission_result = (snapshot.get("last_mission_result", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)
	SocialStealthAdapterScript.clear_all()


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
