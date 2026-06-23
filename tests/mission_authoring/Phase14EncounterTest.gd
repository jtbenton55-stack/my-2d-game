# GdUnit4 tests for Phase 14A-14G non-HP encounter challenges.
extends GdUnitTestSuite

const EncounterControllerScript := preload("res://src/missions/iso/encounters/EncounterController.gd")
const EncounterPhaseDataScript := preload("res://src/missions/iso/encounters/EncounterPhaseData.gd")
const ChallengeMeterDataScript := preload("res://src/missions/iso/encounters/ChallengeMeterData.gd")
const EncounterResultAdapterScript := preload("res://src/missions/iso/encounters/EncounterResultAdapter.gd")
const ChallengeObjectiveNodeScript := preload("res://src/missions/iso/authoring/mechanics/ChallengeObjectiveNode.gd")
const DisruptionActionNodeScript := preload("res://src/missions/iso/authoring/mechanics/DisruptionActionNode.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")


func test_encounter_controller_exposes_phase_meter_and_result_facts() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	controller.reset_encounter()
	assert_bool(controller.start_encounter().get("ok", false)).is_true()
	var context := {"mission_id": "test_mission", "encounter_controller": controller}
	assert_bool(MissionFactBridge.get_fact_value(&"encounter_phase", "opening", context)).is_true()
	assert_bool(controller.adjust_meter("evidence_strength", 3).get("ok", false)).is_true()
	assert_int(int(MissionFactBridge.get_fact_value(&"encounter_meter", "evidence_strength", context))).is_equal(3)
	controller.set_result_tag("evidence_route", true)
	assert_bool(MissionFactBridge.get_fact_value(&"encounter_result_tag", "evidence_route", context)).is_true()
	_restore_game_state(snapshot)
	_free_node(controller)


func test_encounter_effects_route_through_effect_applier() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	controller.reset_encounter()
	controller.start_encounter()
	var context := {"mission_id": "test_mission", "encounter_controller": controller}

	var meter_effect := MissionEffectScript.new()
	meter_effect.effect_type = MissionEffectScript.EffectType.ADJUST_ENCOUNTER_METER
	meter_effect.key = "bentley_confidence"
	meter_effect.value_type = "int"
	meter_effect.value_int = 4
	assert_bool(meter_effect.apply(context).get("ok", false)).is_true()
	assert_int(int(controller.meter_values.get("bentley_confidence", 0))).is_equal(4)

	var phase_effect := MissionEffectScript.new()
	phase_effect.effect_type = MissionEffectScript.EffectType.SET_ENCOUNTER_PHASE
	phase_effect.key = "pressure"
	assert_bool(phase_effect.apply(context).get("ok", false)).is_true()
	assert_str(controller.current_phase_id).is_equal("pressure")

	var tag_effect := MissionEffectScript.new()
	tag_effect.effect_type = MissionEffectScript.EffectType.SET_ENCOUNTER_RESULT_TAG
	tag_effect.key = "bentley_route"
	tag_effect.value_bool = true
	assert_bool(tag_effect.apply(context).get("ok", false)).is_true()
	assert_bool(controller.result_tags.get("bentley_route", false)).is_true()
	_restore_game_state(snapshot)
	_free_node(controller)


func test_challenge_and_disruption_nodes_drive_non_hp_flow() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	controller.reset_encounter()
	controller.start_encounter()

	var challenge := ChallengeObjectiveNodeScript.new()
	challenge.mission_id_override = "test_mission"
	challenge.mechanic_id = &"challenge_step"
	challenge.required_phase_id = &"opening"
	challenge.route_tag = &"social_route"
	challenge.meter_deltas = {"plausible_deniability": 2}
	add_child(challenge)
	var challenge_result: Dictionary = challenge.complete_objective(null, "test")
	assert_bool(challenge_result.get("ok", false)).is_true()
	assert_str(controller.current_phase_id).is_equal("pressure")
	assert_int(int(controller.meter_values.get("plausible_deniability", 0))).is_equal(2)

	var disruption := DisruptionActionNodeScript.new()
	disruption.mission_id_override = "test_mission"
	disruption.mechanic_id = &"messy_disruption"
	disruption.required_phase_id = &"pressure"
	disruption.action_type = "paper_trace"
	disruption.paper_trace_id = &"messy_trace"
	disruption.paper_trace_type = &"witness"
	disruption.paper_trace_severity = 3
	disruption.social_professionalism_delta = -1
	disruption.meter_deltas = {"suspicion": 2, "security_integrity": -2}
	add_child(disruption)
	var disruption_result: Dictionary = disruption.run_disruption(null, "test")
	assert_bool(disruption_result.get("ok", false)).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "messy_trace")).is_true()
	assert_int(int(MissionFactBridge.get_fact_value(&"professionalism_score", "", {"mission_id": "test_mission"}))).is_equal(-1)
	assert_int(int(controller.meter_values.get("suspicion", 0))).is_equal(2)
	assert_int(int(controller.meter_values.get("security_integrity", 0))).is_equal(4)
	_restore_game_state(snapshot)
	_free_node(controller)
	_free_node(challenge)
	_free_node(disruption)


func test_mission_result_receives_encounter_summary() -> void:
	var snapshot := _snapshot_game_state()
	_reset_runtime_state()
	var controller := _make_controller()
	add_child(controller)
	controller.reset_encounter()
	controller.start_encounter()
	controller.adjust_meter("evidence_strength", 5)
	controller.win_encounter("evidence_route")
	GameState.start_mission("test_mission")
	var result: Dictionary = GameState.complete_mission("test_mission")
	assert_bool(result.has("encounter")).is_true()
	assert_str(String(result.get("encounter_state", ""))).is_equal("won")
	var summary: Dictionary = result.get("encounter", {})
	assert_bool((summary.get("result_tags", {}) as Dictionary).get("evidence_route", false)).is_true()
	_restore_game_state(snapshot)
	_free_node(controller)


func test_templates_and_proof_scene_contain_phase14_nodes_and_buttons() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/EncounterControllerTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/ChallengeObjectiveNodeTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/DisruptionActionNodeTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/Phase14EncounterProofRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/EncounterController_phase14_encounter")).is_instanceof(EncounterControllerScript)
	assert_object(root.get_node_or_null("MissionMechanics/ChallengeObjectiveNode_phase14_clean_social")).is_instanceof(ChallengeObjectiveNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/DisruptionActionNode_phase14_messy")).is_instanceof(DisruptionActionNodeScript)
	assert_object(root.find_child("Run Clean Social Route", true, false)).is_not_null()
	assert_object(root.find_child("Run Bentley Route", true, false)).is_not_null()
	assert_object(root.find_child("Run Evidence Route", true, false)).is_not_null()
	assert_object(root.find_child("Run Messy Route", true, false)).is_not_null()
	_free_node(root)


func _make_controller() -> Node:
	var opening := EncounterPhaseDataScript.new()
	opening.phase_id = &"opening"
	opening.next_phase_id = &"pressure"
	var pressure := EncounterPhaseDataScript.new()
	pressure.phase_id = &"pressure"
	pressure.next_phase_id = &"resolution"
	var resolution := EncounterPhaseDataScript.new()
	resolution.phase_id = &"resolution"
	resolution.win_on_success = true
	resolution.result_tag_on_success = &"resolved"
	var evidence := ChallengeMeterDataScript.new()
	evidence.meter_id = &"evidence_strength"
	evidence.max_value = 10
	var bentley := ChallengeMeterDataScript.new()
	bentley.meter_id = &"bentley_confidence"
	bentley.max_value = 10
	var deniability := ChallengeMeterDataScript.new()
	deniability.meter_id = &"plausible_deniability"
	deniability.max_value = 10
	var suspicion := ChallengeMeterDataScript.new()
	suspicion.meter_id = &"suspicion"
	suspicion.max_value = 10
	suspicion.favorable_when_high = false
	var security := ChallengeMeterDataScript.new()
	security.meter_id = &"security_integrity"
	security.initial_value = 6
	security.max_value = 10
	var controller := EncounterControllerScript.new()
	controller.start_on_ready = false
	controller.encounter_id = &"unit_encounter"
	controller.mission_id_override = "test_mission"
	var phases: Array[Resource] = []
	phases.append(opening)
	phases.append(pressure)
	phases.append(resolution)
	var meters: Array[Resource] = []
	meters.append(evidence)
	meters.append(bentley)
	meters.append(deniability)
	meters.append(suspicion)
	meters.append(security)
	controller.set("phases", phases)
	controller.set("meters", meters)
	return controller


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
	PaperTrailAdapterScript.clear_all()
	SocialStealthAdapterScript.clear_all()


func _reset_runtime_state() -> void:
	GameState.current_mission_id = "test_mission"
	GameState.pending_mission_id = ""
	GameState.is_in_mission = true
	GameState.dialogue_flags.clear()
	GameState.mission_performance.clear()
	GameState.begin_mission_performance("test_mission")
	PaperTrailAdapterScript.clear_all()
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.clear_all()
	SocialStealthAdapterScript.reset_mission("test_mission")


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
