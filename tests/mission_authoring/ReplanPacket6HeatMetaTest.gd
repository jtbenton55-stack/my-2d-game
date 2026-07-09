# GdUnit4 tests for Replan Packet 6: venue heat meta loop -- scanner radio
# readout, cool-down shifts, briefing display, and heat spawn seeding inputs.
extends GdUnitTestSuite

const HeatScannerRadioScript := preload("res://src/hideout/HeatScannerRadio.gd")
const MissionBoardControllerScript := preload("res://src/hideout/HideoutMissionBoardController.gd")

var _saved_venue_heat: Dictionary = {}
var _saved_failed_attempts: Dictionary = {}
var _saved_completed: Array = []


func before_test() -> void:
	_saved_venue_heat = GameState.venue_heat.duplicate(true)
	_saved_failed_attempts = GameState.failed_attempts.duplicate(true)
	_saved_completed = GameState.completed_missions.duplicate(true)
	GameState.venue_heat.clear()
	GameState.failed_attempts.clear()
	GameState.completed_missions.clear()


func after_test() -> void:
	GameState.venue_heat = _saved_venue_heat
	GameState.failed_attempts = _saved_failed_attempts
	GameState.completed_missions = _saved_completed


func test_scanner_readout_lists_venues_by_heat() -> void:
	GameState.completed_missions.append("taco_bell_drop")
	GameState.venue_heat["taco_bell_drop"] = 3
	GameState.venue_heat["corner_store_cashout"] = 1

	var readout := HeatScannerRadioScript.build_scanner_readout()
	var venues: Array = readout.get("venues", [])
	assert_int(venues.size()).is_equal(2)
	var hottest: Dictionary = venues[0]
	assert_str(String(hottest.get("mission_id", ""))).is_equal("taco_bell_drop")
	assert_int(int(hottest.get("heat", 0))).is_equal(3)
	assert_str(String(hottest.get("dial", ""))).is_equal("[###--]")
	assert_bool(bool(hottest.get("can_cool_down", false))).is_true()
	assert_str(String(readout.get("hottest_mission_id", ""))).is_equal("taco_bell_drop")
	assert_str(String(readout.get("text", ""))).contains("POLICE BAND")


func test_scanner_chatter_scales_with_heat() -> void:
	GameState.venue_heat["quiet_venue"] = 0
	GameState.venue_heat["hot_venue"] = 5
	var readout := HeatScannerRadioScript.build_scanner_readout()
	var text := String(readout.get("text", ""))
	assert_str(text).contains("Full task force")


func test_cooldown_shift_requires_completed_venue() -> void:
	GameState.venue_heat["never_worked"] = 4
	var rejected := HeatScannerRadioScript.run_cooldown_shift("never_worked")
	assert_bool(rejected.get("ok", true)).is_false()
	assert_str(String(rejected.get("code", ""))).is_equal("venue_not_worked")


func test_cooldown_shift_cools_worked_venue() -> void:
	GameState.completed_missions.append("taco_bell_drop")
	GameState.venue_heat["taco_bell_drop"] = 4
	var shift := HeatScannerRadioScript.run_cooldown_shift("taco_bell_drop")
	assert_bool(shift.get("ok", false)).is_true()
	assert_int(int(shift.get("heat_before", 0))).is_equal(4)
	assert_int(int(shift.get("heat_after", -1))).is_equal(2)
	assert_int(GameState.get_mission_heat("taco_bell_drop")).is_equal(2)

	GameState.venue_heat["taco_bell_drop"] = 0
	var already_cool := HeatScannerRadioScript.run_cooldown_shift("taco_bell_drop")
	assert_bool(already_cool.get("ok", true)).is_false()
	assert_str(String(already_cool.get("code", ""))).is_equal("venue_already_cool")


func test_cooldown_shift_cannot_cool_below_attempt_floor() -> void:
	GameState.completed_missions.append("taco_bell_drop")
	GameState.failed_attempts["taco_bell_drop"] = 2
	GameState.venue_heat["taco_bell_drop"] = 3
	HeatScannerRadioScript.run_cooldown_shift("taco_bell_drop")
	assert_int(GameState.get_mission_heat("taco_bell_drop")).is_equal(2)


func test_briefing_line_reflects_heat_level() -> void:
	var board: Node = MissionBoardControllerScript.new()
	add_child(board)
	assert_str(board._heat_briefing_line("taco_bell_drop")).contains("0/5")
	GameState.venue_heat["taco_bell_drop"] = 2
	var warm := String(board._heat_briefing_line("taco_bell_drop"))
	assert_str(warm).contains("2/5")
	assert_str(warm).contains("extra patrol pressure")
	GameState.venue_heat["taco_bell_drop"] = 5
	assert_str(String(board._heat_briefing_line("taco_bell_drop"))).contains("detective on site")
	_free_node(board)


func test_mission_heat_uses_max_of_report_and_attempts() -> void:
	GameState.venue_heat["test_mission"] = 1
	GameState.failed_attempts["test_mission"] = 3
	assert_int(GameState.get_mission_heat("test_mission")).is_equal(3)
	GameState.venue_heat["test_mission"] = 4
	assert_int(GameState.get_mission_heat("test_mission")).is_equal(4)
	var summary := GameState.get_mission_heat_summary("test_mission")
	assert_int(int(summary.get("report_heat", 0))).is_equal(4)
	assert_int(int(summary.get("failed_attempts", 0))).is_equal(3)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
