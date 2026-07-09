# GdUnit4 tests for Replan Packet 1: hold-interact channels and the
# mission readability stack (noise pulses, NPC pips, casing overlay).
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const NoisePulseVisualizerScript := preload("res://src/missions/iso/runtime/readability/NoisePulseVisualizer.gd")
const NpcAlertPipVisualizerScript := preload("res://src/missions/iso/runtime/readability/NpcAlertPipVisualizer.gd")
const MissionCasingOverlayScript := preload("res://src/missions/iso/runtime/readability/MissionCasingOverlay.gd")
const MissionReadabilityLayerScript := preload("res://src/missions/iso/runtime/readability/MissionReadabilityLayer.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const NoiseEventScript := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")


func test_instant_interact_still_activates_immediately() -> void:
	var mechanic: Area2D = MechanicAreaBaseScript.new()
	mechanic.mechanic_id = &"packet1_instant"
	mechanic.mission_id_override = "test_mission"
	mechanic.interact_duration = 0.0
	add_child(mechanic)

	var ok: bool = mechanic.interact(null)
	assert_bool(ok).is_true()
	assert_bool(mechanic.used).is_true()
	assert_bool(mechanic.is_hold_in_progress()).is_false()
	_free_node(mechanic)


func test_hold_interact_channels_then_activates() -> void:
	var actor := _make_player_actor(Vector2.ZERO)
	var mechanic: Area2D = MechanicAreaBaseScript.new()
	mechanic.mechanic_id = &"packet1_hold"
	mechanic.mission_id_override = "test_mission"
	mechanic.interact_duration = 0.5
	add_child(mechanic)

	var started: bool = mechanic.interact(actor)
	assert_bool(started).is_true()
	assert_bool(mechanic.is_hold_in_progress()).is_true()
	assert_bool(mechanic.used).is_false()

	mechanic._advance_hold(0.3)
	assert_bool(mechanic.is_hold_in_progress()).is_true()
	assert_float(mechanic.get_hold_ratio()).is_greater(0.5)

	mechanic._advance_hold(0.3)
	assert_bool(mechanic.is_hold_in_progress()).is_false()
	assert_bool(mechanic.used).is_true()
	assert_str(String(mechanic.last_activation_result.get("code", ""))).is_equal("activation_succeeded")
	_free_node(mechanic)
	_free_node(actor)


func test_hold_interrupts_when_actor_moves() -> void:
	var actor := _make_player_actor(Vector2.ZERO)
	var mechanic: Area2D = MechanicAreaBaseScript.new()
	mechanic.mechanic_id = &"packet1_hold_break"
	mechanic.mission_id_override = "test_mission"
	mechanic.interact_duration = 1.0
	mechanic.hold_move_tolerance = 24.0
	add_child(mechanic)

	var interrupted_reasons: Array = []
	mechanic.hold_interrupted.connect(func(_id: String, reason: String) -> void:
		interrupted_reasons.append(reason)
	)
	mechanic.interact(actor)
	assert_bool(mechanic.is_hold_in_progress()).is_true()

	actor.global_position = Vector2(200.0, 0.0)
	mechanic._advance_hold(0.1)
	assert_bool(mechanic.is_hold_in_progress()).is_false()
	assert_bool(mechanic.used).is_false()
	assert_array(interrupted_reasons).contains(["actor_moved"])
	_free_node(mechanic)
	_free_node(actor)


func test_hold_interrupt_adds_alert_exposure_when_configured() -> void:
	var alert: Node = MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var actor := _make_player_actor(Vector2.ZERO)
	var mechanic: Area2D = MechanicAreaBaseScript.new()
	mechanic.mechanic_id = &"packet1_hold_exposure"
	mechanic.mission_id_override = "test_mission"
	mechanic.interact_duration = 1.0
	mechanic.interrupt_alert_exposure = 0.4
	add_child(mechanic)

	mechanic.interact(actor)
	mechanic.cancel_hold("test_interrupt")
	assert_float(alert.alert_score).is_greater(0.3)
	assert_str(String(alert.alert_state)).is_equal("suspicious")
	_free_node(mechanic)
	_free_node(actor)
	_free_node(alert)


func test_noise_pulse_visualizer_records_emitted_noise() -> void:
	var visualizer: Node2D = NoisePulseVisualizerScript.new()
	add_child(visualizer)
	assert_int(visualizer.get_active_pulse_count()).is_equal(0)

	var event: Dictionary = NoiseEventScript.make_event("packet1_noise", "test_source", Vector2(50, 60), 96.0, 0.7, "decoy", "player")
	EventBus.mission_noise_emitted.emit(event)
	assert_int(visualizer.get_active_pulse_count()).is_equal(1)
	_free_node(visualizer)


func test_npc_pip_visualizer_marks_enemies_when_suspicious() -> void:
	var alert: Node = MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var enemy := Node2D.new()
	enemy.name = "Packet1PipEnemy"
	enemy.add_to_group("enemy")
	add_child(enemy)
	var visualizer: Node2D = NpcAlertPipVisualizerScript.new()
	add_child(visualizer)

	alert.set_alert_state("suspicious")
	visualizer._refresh_pips()
	assert_int(visualizer.get_pip_count()).is_equal(1)

	alert.set_alert_state("resolved")
	alert.set_alert_state("normal")
	visualizer._refresh_pips()
	assert_int(visualizer.get_pip_count()).is_equal(0)
	_free_node(visualizer)
	_free_node(enemy)
	_free_node(alert)


func test_readability_layer_composes_all_visualizers() -> void:
	var layer: Node2D = MissionReadabilityLayerScript.new()
	add_child(layer)
	var summary: Dictionary = layer.get_readability_summary()
	assert_bool(bool(summary.get("noise_pulses", false))).is_true()
	assert_bool(bool(summary.get("npc_pips", false))).is_true()
	assert_bool(bool(summary.get("casing_overlay", false))).is_true()
	assert_bool(bool(summary.get("casing_active", true))).is_false()
	assert_bool(layer.is_in_group("mission_readability_layer")).is_true()
	_free_node(layer)


func test_casing_overlay_reads_mission_state_without_crash() -> void:
	var overlay: Node2D = MissionCasingOverlayScript.new()
	add_child(overlay)
	PaperTrailAdapter.reset_mission("test_mission")
	PaperTrailAdapter.record_trace(
		"packet1_trace", "packet1_source", "door_memory", 2, true, "",
		{"mission_id": "test_mission", "position": Vector2(10, 20)}
	)
	overlay.casing_active = true
	overlay.queue_redraw()
	var events := PaperTrailAdapter.get_trace_events("test_mission")
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0].has("position")).is_true()
	PaperTrailAdapter.reset_mission("test_mission")
	_free_node(overlay)


func _make_player_actor(pos: Vector2) -> Node2D:
	var actor := Node2D.new()
	actor.name = "Packet1PlayerActor"
	actor.add_to_group("player")
	add_child(actor)
	actor.global_position = pos
	return actor


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
