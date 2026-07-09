# GdUnit4 tests for Replan Packet 4: mess props, cleanup crossover verbs,
# paper trace hardening, and the Investigation Report.
extends GdUnitTestSuite

const MessSpotNodeScript := preload("res://src/missions/iso/runtime/mess/MessSpotNode.gd")
const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const ReactiveNpcBrainAdapterScript := preload("res://src/missions/iso/ai/ReactiveNpcBrainAdapter.gd")
const InvestigationReportBuilderScript := preload("res://src/missions/iso/runtime/report/InvestigationReportBuilder.gd")
const CoverMeterRuntimeScript := preload("res://src/missions/iso/runtime/cover/CoverMeterRuntime.gd")

var _saved_mission_id := ""


func before_test() -> void:
	_saved_mission_id = GameState.current_mission_id
	GameState.current_mission_id = "test_mission"
	SocialStealthAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.set_hardening_seconds(0.0)


func after_test() -> void:
	GameState.current_mission_id = _saved_mission_id
	SocialStealthAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.reset_mission("test_mission")
	PaperTrailAdapterScript.set_hardening_seconds(0.0)


func test_mess_spawn_charges_debt_and_cleanup_restores() -> void:
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "broken_glass", Vector2(50, 50), {"mission_id_override": "test_mission"})
	assert_bool(mess.is_in_group("mission_mess")).is_true()
	var after_spawn := int(SocialStealthAdapterScript.get_summary("test_mission").get("cleanliness", 99))
	assert_int(after_spawn).is_equal(-1)

	var runtime: Node = CoverMeterRuntimeScript.new()
	add_child(runtime)
	var result: Dictionary = mess.clean_up(null)
	assert_bool(result.get("ok", false)).is_true()
	var cleanup: Dictionary = (result.get("details", {}) as Dictionary).get("cleanup_result", {})
	assert_str(String(cleanup.get("code", ""))).is_equal("mess_cleaned")
	assert_bool(mess.is_in_group("mission_mess")).is_false()

	var social := SocialStealthAdapterScript.get_summary("test_mission")
	assert_int(int(social.get("cleanliness", 99))).is_equal(0)
	assert_int(int(social.get("professionalism", 0))).is_equal(1)
	assert_int(int(social.get("task_count", 0))).is_equal(1)
	assert_bool(runtime.is_alibi_active()).is_true()
	_free_node(runtime)
	_free_node(mess)


func test_mess_cleanup_with_trace_radius_wipes_nearby_traces() -> void:
	PaperTrailAdapterScript.record_trace(
		"packet4_near_trace", "src", "door_memory", 2, true, "",
		{"mission_id": "test_mission", "position": Vector2(60, 60)}
	)
	PaperTrailAdapterScript.record_trace(
		"packet4_far_trace", "src", "door_memory", 2, true, "",
		{"mission_id": "test_mission", "position": Vector2(900, 900)}
	)
	var mess: Area2D = MessSpotNodeScript.spawn_mess(self, "spill", Vector2(50, 50), {
		"mission_id_override": "test_mission",
		"clean_traces_radius": 100.0,
	})
	var result: Dictionary = mess.clean_up(null)
	var cleanup: Dictionary = (result.get("details", {}) as Dictionary).get("cleanup_result", {})
	var traces_cleaned: Array = cleanup.get("traces_cleaned", [])
	assert_array(traces_cleaned).contains(["packet4_near_trace"])
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "packet4_near_trace")).is_false()
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "packet4_far_trace")).is_true()
	_free_node(mess)


func test_hardened_traces_resist_cleanup_but_allow_redirect() -> void:
	PaperTrailAdapterScript.record_trace(
		"packet4_hard_trace", "src", "audit_log", 3, true, "",
		{"mission_id": "test_mission"}
	)
	PaperTrailAdapterScript.set_hardening_seconds(0.001)
	OS.delay_msec(20)

	var cleanup := PaperTrailAdapterScript.cleanup_traces({"trace_id": "packet4_hard_trace"}, {"mission_id": "test_mission"})
	assert_bool(cleanup.get("ok", true)).is_false()
	assert_str(String(cleanup.get("code", ""))).is_equal("paper_trace_hardened")
	assert_bool(PaperTrailAdapterScript.has_active_trace("test_mission", "packet4_hard_trace")).is_true()

	var redirect := PaperTrailAdapterScript.redirect_traces({"trace_id": "packet4_hard_trace"}, "raccoon_did_it", {"mission_id": "test_mission"})
	assert_bool(redirect.get("ok", false)).is_true()


func test_hardening_disabled_by_default_keeps_cleanup_working() -> void:
	PaperTrailAdapterScript.record_trace(
		"packet4_soft_trace", "src", "audit_log", 3, true, "",
		{"mission_id": "test_mission"}
	)
	var cleanup := PaperTrailAdapterScript.cleanup_traces({"trace_id": "packet4_soft_trace"}, {"mission_id": "test_mission"})
	assert_bool(cleanup.get("ok", false)).is_true()


func test_investigation_report_clean_run_is_cold_case() -> void:
	var report := InvestigationReportBuilderScript.build_report("test_mission")
	assert_str(String(report.get("verdict", ""))).is_equal("cold_case")
	assert_str(String(report.get("headline", ""))).contains("UNSOLVED")
	assert_int(int(report.get("heat_delta", -1))).is_equal(0)


func test_investigation_report_active_traces_open_investigation() -> void:
	PaperTrailAdapterScript.record_trace(
		"packet4_report_trace", "src", "door_memory", 3, true, "",
		{"mission_id": "test_mission"}
	)
	var report := InvestigationReportBuilderScript.build_report("test_mission")
	assert_str(String(report.get("verdict", ""))).is_equal("open_investigation")
	assert_int(int(report.get("heat_delta", 0))).is_greater(0)
	var lines: Array = report.get("lines", [])
	assert_bool(lines.size() > 0).is_true()
	assert_str(String(lines[0])).contains("door")


func test_investigation_report_redirected_names_the_raccoon() -> void:
	PaperTrailAdapterScript.record_trace(
		"packet4_raccoon_trace", "src", "door_memory", 2, true, "",
		{"mission_id": "test_mission"}
	)
	PaperTrailAdapterScript.redirect_traces({"trace_id": "packet4_raccoon_trace"}, "raccoon", {"mission_id": "test_mission"})
	var report := InvestigationReportBuilderScript.build_report("test_mission")
	assert_str(String(report.get("verdict", ""))).is_equal("misdirected")
	assert_str(String(report.get("prime_suspect", ""))).is_equal("local raccoon")


func test_annotate_mission_result_adds_report_payload() -> void:
	var result := InvestigationReportBuilderScript.annotate_mission_result({"mission_id": "test_mission", "success": true})
	assert_bool(result.has("investigation_report")).is_true()
	var report: Dictionary = result.get("investigation_report", {})
	assert_str(String(report.get("mission_id", ""))).is_equal("test_mission")


func test_venue_heat_accumulates_from_report_and_cools() -> void:
	var saved_heat: Dictionary = GameState.venue_heat.duplicate(true)
	var saved_attempts: Dictionary = GameState.failed_attempts.duplicate(true)
	GameState.venue_heat.clear()
	GameState.failed_attempts.erase("test_mission")
	GameState._apply_investigation_heat("test_mission", {"investigation_report": {"heat_delta": 3}})
	assert_int(GameState.get_mission_heat("test_mission")).is_equal(3)
	GameState._apply_investigation_heat("test_mission", {"investigation_report": {"heat_delta": 4}})
	assert_int(GameState.get_mission_heat("test_mission")).is_equal(5)
	GameState.cool_venue_heat("test_mission", 2)
	assert_int(int(GameState.venue_heat.get("test_mission", -1))).is_equal(3)
	GameState.venue_heat = saved_heat
	GameState.failed_attempts = saved_attempts


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
