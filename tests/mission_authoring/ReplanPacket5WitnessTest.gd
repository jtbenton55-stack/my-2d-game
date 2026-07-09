# GdUnit4 tests for Replan Packet 5: witness notice/report pipeline with
# travel time, intercept counterplay (clean, distract, sabotage), gossip-lite.
extends GdUnitTestSuite

const WitnessNpcScript := preload("res://src/missions/iso/ai/WitnessNpc.gd")
const MessSpotNodeScript := preload("res://src/missions/iso/runtime/mess/MessSpotNode.gd")
const PhoneSabotageNodeScript := preload("res://src/missions/iso/authoring/mechanics/PhoneSabotageNode.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const NoiseEventScript := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

var _saved_mission_id := ""


func before_test() -> void:
	_saved_mission_id = GameState.current_mission_id
	GameState.current_mission_id = "test_mission"
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.reset_mission("test_mission")


func after_test() -> void:
	GameState.current_mission_id = _saved_mission_id
	ReactiveNpcBrainAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.reset_mission("test_mission")
	SocialStealthAdapterScript.reset_mission("test_mission")


func test_witness_scan_notices_nearby_mess() -> void:
	var witness := _make_witness(Vector2.ZERO)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(80, 0), {"mission_id_override": "test_mission"})
	witness._scan_for_mess()
	assert_str(witness.state).is_equal("noticing")

	var far_witness := _make_witness(Vector2(2000, 2000))
	far_witness._scan_for_mess()
	assert_str(far_witness.state).is_equal("idle")
	_free_node(mess)
	_free_node(witness)
	_free_node(far_witness)


func test_report_files_signal_trace_and_exposure() -> void:
	var alert: Node = MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var witness := _make_witness(Vector2.ZERO)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "broken_glass", Vector2(60, 0), {"mission_id_override": "test_mission"})
	witness.force_notice(mess)
	witness._begin_report()
	witness._file_report()

	assert_int(witness.reports_filed).is_equal(1)
	var summary := ReactiveNpcBrainAdapterScript.get_summary("test_mission")
	assert_int(int(summary.get("signal_count", 0))).is_equal(1)
	assert_int(PaperTrailAdapterScript.count_active_traces_by_type("test_mission", "witness")).is_equal(1)
	assert_float(alert.alert_score).is_greater(0.3)
	assert_str(witness.state).is_equal("returning")
	_free_node(mess)
	_free_node(witness)
	_free_node(alert)


func test_cleaning_mess_makes_witness_stand_down() -> void:
	var witness := _make_witness(Vector2.ZERO)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(70, 0), {"mission_id_override": "test_mission"})
	witness.force_notice(mess)
	assert_bool(witness._witnessed_still_there()).is_true()
	mess.clean_up(null)
	assert_bool(witness._witnessed_still_there()).is_false()
	_free_node(mess)
	_free_node(witness)


func test_player_decoy_noise_distracts_witness() -> void:
	var witness := _make_witness(Vector2.ZERO)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(70, 0), {"mission_id_override": "test_mission"})
	witness.force_notice(mess)

	var noise := NoiseEventScript.make_event("packet5_decoy", "kit_decoy", Vector2(30, 0), 120.0, 0.8, "decoy", "player")
	witness._on_noise_emitted(noise)
	assert_str(witness.state).is_equal("distracted")
	assert_int(witness.reports_filed).is_equal(0)

	var guard_noise := NoiseEventScript.make_event("packet5_guard", "guard", Vector2(30, 0), 120.0, 0.8, "generic", "security")
	witness._on_noise_emitted(guard_noise)
	assert_str(witness.state).is_equal("distracted")
	_free_node(mess)
	_free_node(witness)


func test_sabotaged_phone_blocks_report() -> void:
	var phone: Area2D = PhoneSabotageNodeScript.new()
	phone.mechanic_id = &"packet5_phone"
	phone.mission_id_override = "test_mission"
	phone.interact_duration = 0.0
	add_child(phone)
	phone.global_position = Vector2(200, 0)

	var sabotage_result: Dictionary = phone.activate(null, "script")
	assert_bool(sabotage_result.get("ok", false)).is_true()
	assert_bool(bool(phone.get_meta("sabotaged", false))).is_true()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "packet5_phone_sabotage")).is_true()

	var witness := _make_witness(Vector2.ZERO)
	witness.report_target_path = witness.get_path_to(phone)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(70, 0), {"mission_id_override": "test_mission"})
	witness.force_notice(mess)
	witness._begin_report()
	witness.global_position = phone.global_position
	witness._file_report()
	assert_int(witness.reports_filed).is_equal(0)
	assert_str(witness.state).is_equal("returning")
	_free_node(mess)
	_free_node(witness)
	_free_node(phone)


func test_gossip_reaches_exactly_one_nearby_witness() -> void:
	var reporter := _make_witness(Vector2.ZERO)
	var friend_a := _make_witness(Vector2(100, 0))
	var friend_b := _make_witness(Vector2(120, 0))
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(60, 0), {"mission_id_override": "test_mission"})
	reporter.force_notice(mess)
	reporter._begin_report()
	reporter._file_report()

	var gossiped := 0
	if friend_a.gossip_received:
		gossiped += 1
	if friend_b.gossip_received:
		gossiped += 1
	assert_int(gossiped).is_equal(1)
	assert_bool(reporter.gossip_received).is_false()
	_free_node(mess)
	_free_node(reporter)
	_free_node(friend_a)
	_free_node(friend_b)


func test_gossip_shortens_notice_delay() -> void:
	var witness := _make_witness(Vector2.ZERO)
	witness.notice_delay = 2.0
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(60, 0), {"mission_id_override": "test_mission"})
	witness.force_notice(mess)
	var normal_timer: float = witness._notice_timer
	witness._set_state("idle")
	witness.receive_gossip()
	witness.force_notice(mess)
	assert_float(witness._notice_timer).is_less(normal_timer)
	_free_node(mess)
	_free_node(witness)


func _make_witness(pos: Vector2) -> Node2D:
	var witness: Node2D = WitnessNpcScript.new()
	witness.witness_id = StringName("packet5_witness_%d" % randi())
	add_child(witness)
	witness.global_position = pos
	return witness


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
