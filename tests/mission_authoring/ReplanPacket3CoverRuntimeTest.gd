# GdUnit4 tests for Replan Packet 3: cover meter drain/refill runtime,
# alibi windows on believable tasks, the roaming inspector, and challenge barks.
extends GdUnitTestSuite

const CoverMeterRuntimeScript := preload("res://src/missions/iso/runtime/cover/CoverMeterRuntime.gd")
const CoverChallengePromptScript := preload("res://src/missions/iso/runtime/cover/CoverChallengePrompt.gd")
const MissionCoverLayerScript := preload("res://src/missions/iso/runtime/cover/MissionCoverLayer.gd")
const RoamingInspectorNpcScript := preload("res://src/missions/iso/ai/RoamingInspectorNpc.gd")
const BelievableTaskZoneScript := preload("res://src/missions/iso/authoring/mechanics/BelievableTaskZone.gd")
const InspectionRuleSetScript := preload("res://src/missions/iso/social/InspectionRuleSet.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const MissionInventoryScript := preload("res://src/inventory/MissionInventory.gd")

var _mission_snapshot: Dictionary = {}


func before_test() -> void:
	_mission_snapshot = {
		"current_mission_id": GameState.current_mission_id,
	}
	GameState.current_mission_id = "test_mission"
	SocialStealthAdapterScript.reset_mission("test_mission")
	MissionInventoryScript.clear_all()


func after_test() -> void:
	GameState.current_mission_id = String(_mission_snapshot.get("current_mission_id", ""))
	SocialStealthAdapterScript.reset_mission("test_mission")
	MissionInventoryScript.clear_all()


func test_cover_meter_drains_on_sustained_running() -> void:
	var runtime: Node = CoverMeterRuntimeScript.new()
	runtime.run_drain_interval = 1.0
	add_child(runtime)
	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.set("velocity", Vector2(500.0, 0.0))
	player.set("speed", 300.0)
	add_child(player)

	var drained: Array = []
	runtime.cover_drained.connect(func(reason: String, value: int) -> void:
		drained.append([reason, value])
	)
	runtime._process_run_drain(player, 0.6)
	assert_int(drained.size()).is_equal(0)
	runtime._process_run_drain(player, 0.6)
	assert_int(drained.size()).is_equal(1)
	assert_str(String(drained[0][0])).is_equal("running_indoors")
	var prof := int(SocialStealthAdapterScript.get_summary("test_mission").get("professionalism", 99))
	assert_int(prof).is_equal(-1)
	_free_node(player)
	_free_node(runtime)


func test_cover_meter_drain_floor_stops_passive_drain() -> void:
	var runtime: Node = CoverMeterRuntimeScript.new()
	runtime.drain_floor = -1
	add_child(runtime)
	SocialStealthAdapterScript.set_professionalism(-1, {"mission_id": "test_mission"})
	runtime._drain(1, "running_indoors")
	var prof := int(SocialStealthAdapterScript.get_summary("test_mission").get("professionalism", 99))
	assert_int(prof).is_equal(-1)
	_free_node(runtime)


func test_alibi_window_registration_and_expiry_query() -> void:
	var runtime: Node = CoverMeterRuntimeScript.new()
	add_child(runtime)
	assert_bool(runtime.is_alibi_active()).is_false()
	runtime.register_alibi_window(30.0)
	assert_bool(runtime.is_alibi_active()).is_true()
	assert_float(runtime.get_alibi_seconds_remaining()).is_greater(25.0)
	_free_node(runtime)


func test_believable_task_grants_alibi_window() -> void:
	var runtime: Node = CoverMeterRuntimeScript.new()
	add_child(runtime)
	var task: Area2D = BelievableTaskZoneScript.new()
	task.mechanic_id = &"packet3_task"
	task.mission_id_override = "test_mission"
	task.alibi_window_seconds = 20.0
	task.one_shot = false
	add_child(task)

	var result: Dictionary = task.activate(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_bool(runtime.is_alibi_active()).is_true()
	_free_node(task)
	_free_node(runtime)


func test_believable_task_repeat_cooldown_blocks_spam() -> void:
	var task: Area2D = BelievableTaskZoneScript.new()
	task.mechanic_id = &"packet3_task_cd"
	task.mission_id_override = "test_mission"
	task.one_shot = false
	task.repeat_cooldown_seconds = 60.0
	add_child(task)

	var first: Dictionary = task.activate(null, "script")
	assert_bool(first.get("ok", false)).is_true()
	var second: Dictionary = task.activate(null, "script")
	assert_bool(second.get("ok", true)).is_false()
	assert_str(String(second.get("code", ""))).is_equal("task_cooling_down")
	assert_bool(task.is_interaction_available(null)).is_false()
	_free_node(task)


func test_roaming_inspector_auto_passes_during_alibi() -> void:
	var runtime: Node = CoverMeterRuntimeScript.new()
	add_child(runtime)
	runtime.register_alibi_window(30.0)
	var rules: Resource = InspectionRuleSetScript.new()
	rules.min_professionalism = 99
	var inspector: Node2D = RoamingInspectorNpcScript.new()
	inspector.inspector_id = &"packet3_inspector"
	inspector.inspection_rules = rules
	inspector.start_active = false
	add_child(inspector)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	inspector._arrive_and_inspect(player)
	assert_bool(bool(inspector.last_inspection_result.get("ok", false))).is_true()
	var details: Dictionary = inspector.last_inspection_result.get("details", {})
	assert_str(String(details.get("reason", ""))).is_equal("alibi_window")
	_free_node(player)
	_free_node(inspector)
	_free_node(runtime)


func test_roaming_inspector_fail_confiscates_and_bumps_exposure() -> void:
	var alert: Node = MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	MissionInventoryScript.add_item("packet3_crowbar", 1, {"incriminating": 3})
	MissionInventoryScript.add_item("packet3_snack", 1, {"incriminating": 0})
	var rules: Resource = InspectionRuleSetScript.new()
	rules.min_professionalism = 99
	var inspector: Node2D = RoamingInspectorNpcScript.new()
	inspector.inspector_id = &"packet3_inspector_fail"
	inspector.inspection_rules = rules
	inspector.start_active = false
	inspector.open_challenge_on_fail = false
	add_child(inspector)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)

	inspector._arrive_and_inspect(player)
	assert_bool(bool(inspector.last_inspection_result.get("ok", true))).is_false()
	assert_bool(MissionInventoryScript.has_item("packet3_crowbar")).is_false()
	assert_bool(MissionInventoryScript.has_item("packet3_snack")).is_true()
	assert_float(alert.alert_score).is_greater(0.3)
	_free_node(player)
	_free_node(inspector)
	_free_node(alert)


func test_challenge_prompt_choices_respect_facts() -> void:
	var prompt: CanvasLayer = CoverChallengePromptScript.new()
	add_child(prompt)

	prompt.open_challenge("Test challenge")
	assert_bool(prompt.challenge_open).is_true()
	var bluff_fail: Dictionary = prompt.resolve_choice("bluff")
	assert_bool(bluff_fail.get("ok", true)).is_false()

	SocialStealthAdapterScript.set_cover_story("packet3_cover", {}, {"mission_id": "test_mission"})
	prompt.open_challenge("Test challenge 2")
	var bluff_ok: Dictionary = prompt.resolve_choice("bluff")
	assert_bool(bluff_ok.get("ok", false)).is_true()

	prompt.open_challenge("Test challenge 3")
	var deflect: Dictionary = prompt.resolve_choice("deflect")
	assert_bool(deflect.get("ok", false)).is_true()
	var prof := int(SocialStealthAdapterScript.get_summary("test_mission").get("professionalism", 99))
	assert_int(prof).is_equal(-1)
	_free_node(prompt)


func test_cover_layer_composes_meter_and_prompt() -> void:
	var layer: Node = MissionCoverLayerScript.new()
	add_child(layer)
	var summary: Dictionary = layer.get_cover_layer_summary()
	assert_bool(bool(summary.get("cover_meter", false))).is_true()
	assert_bool(bool(summary.get("challenge_prompt", false))).is_true()
	assert_bool(bool(summary.get("alibi_active", true))).is_false()
	assert_bool(layer.is_in_group("mission_cover_layer")).is_true()
	_free_node(layer)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
