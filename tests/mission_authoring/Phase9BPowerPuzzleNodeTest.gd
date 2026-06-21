# GdUnit4 tests for Phase 9B power circuits, timed switches, and pressure plates.
extends GdUnitTestSuite

const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const PowerCircuitNodeScript := preload("res://src/missions/iso/authoring/mechanics/PowerCircuitNode.gd")
const TimedSwitchNodeScript := preload("res://src/missions/iso/authoring/mechanics/TimedSwitchNode.gd")
const PressurePlateNodeScript := preload("res://src/missions/iso/authoring/mechanics/PressurePlateNode.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_phase9b_nodes_extend_mechanic_area_base() -> void:
	var circuit := PowerCircuitNodeScript.new()
	var timed_switch := TimedSwitchNodeScript.new()
	var plate := PressurePlateNodeScript.new()
	assert_object(circuit).is_instanceof(MechanicAreaBaseScript)
	assert_object(timed_switch).is_instanceof(MechanicAreaBaseScript)
	assert_object(plate).is_instanceof(MechanicAreaBaseScript)
	circuit.free()
	timed_switch.free()
	plate.free()


func test_timed_switch_sets_and_expires_mission_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_timed_switch()
	node.mission_id_override = "test_mission"
	node.switch_id = &"test_switch"
	node.switch_flag = &"test_switch_active"
	node.one_shot = false
	node.success_effects = _set_mission_flag_effect_set("test_switch_used")

	var start_result: Dictionary = node.trigger_switch(null, "test")
	assert_bool(start_result.get("ok", false)).is_true()
	assert_str(String(start_result.get("code", ""))).is_equal("timed_switch_started")
	assert_bool(node.switch_active).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_switch_active", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_switch_used", false)).is_true()

	node.switch_until_msec = Time.get_ticks_msec() - 1
	var expire_result: Dictionary = node.refresh_timer_state()
	assert_str(String(expire_result.get("code", ""))).is_equal("timed_switch_expired")
	assert_bool(node.switch_active).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_switch_active", true)).is_false()

	_restore_game_state(snapshot)
	_free_node(node)


func test_pressure_plate_sets_and_clears_pressed_flag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_pressure_plate()
	node.mission_id_override = "test_mission"
	node.plate_id = &"test_plate"
	node.pressed_flag = &"test_plate_pressed"
	node.one_shot = false
	node.success_effects = _set_mission_flag_effect_set("test_plate_effect")

	var press_result: Dictionary = node.press(null, "test")
	assert_bool(press_result.get("ok", false)).is_true()
	assert_str(String(press_result.get("code", ""))).is_equal("pressure_plate_pressed")
	assert_bool(node.pressed).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_plate_pressed", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_plate_effect", false)).is_true()

	var release_result: Dictionary = node.release(null, "test")
	assert_bool(release_result.get("ok", false)).is_true()
	assert_str(String(release_result.get("code", ""))).is_equal("pressure_plate_released")
	assert_bool(node.pressed).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_plate_pressed", true)).is_false()

	_restore_game_state(snapshot)
	_free_node(node)


func test_pressure_plate_accepts_bentley_actor_group() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_pressure_plate()
	node.mission_id_override = "test_mission"
	node.plate_id = &"test_bentley_plate"
	node.pressed_flag = &"test_bentley_plate_pressed"
	node.one_shot = false
	var bentley := Node2D.new()
	bentley.name = "BentleyUnderTest"
	bentley.add_to_group("bentley")
	add_child(bentley)

	var press_result: Dictionary = node.press(bentley, "test_bentley")
	assert_bool(press_result.get("ok", false)).is_true()
	assert_bool(node.pressed).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_bentley_plate_pressed", false)).is_true()

	var release_result: Dictionary = node.release(bentley, "test_bentley")
	assert_bool(release_result.get("ok", false)).is_true()
	assert_bool(node.pressed).is_false()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_bentley_plate_pressed", true)).is_false()

	_restore_game_state(snapshot)
	_free_node(bentley)
	_free_node(node)


func test_power_circuit_requires_linked_flags_before_powering() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var node := _spawn_power_circuit()
	node.mission_id_override = "test_mission"
	node.circuit_id = &"test_circuit"
	node.circuit_flag = &"test_circuit_powered"
	var required_flags: Array[StringName] = [&"test_switch_active", &"test_plate_pressed"]
	node.required_power_flags = required_flags
	node.one_shot = false
	node.success_effects = _set_mission_flag_effect_set("test_circuit_effect")

	var incomplete_result: Dictionary = node.check_circuit(null, "test")
	assert_bool(incomplete_result.get("ok", true)).is_false()
	assert_str(String(incomplete_result.get("code", ""))).is_equal("circuit_incomplete")
	assert_bool(node.powered).is_false()

	MissionFactBridge.set_fact_value(&"mission_flag", "test_switch_active", true, node.build_context(null))
	MissionFactBridge.set_fact_value(&"mission_flag", "test_plate_pressed", true, node.build_context(null))
	var powered_result: Dictionary = node.check_circuit(null, "test")
	assert_bool(powered_result.get("ok", false)).is_true()
	assert_str(String(powered_result.get("code", ""))).is_equal("circuit_powered")
	assert_bool(node.powered).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_circuit_powered", false)).is_true()
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:test_circuit_effect", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(node)


func test_templates_and_dev_scene_contain_phase9b_nodes() -> void:
	var circuit_template := load("res://scenes/missions/iso/authoring/PowerCircuitNodeTemplate.tscn") as PackedScene
	var switch_template := load("res://scenes/missions/iso/authoring/TimedSwitchNodeTemplate.tscn") as PackedScene
	var plate_template := load("res://scenes/missions/iso/authoring/PressurePlateNodeTemplate.tscn") as PackedScene
	assert_object(circuit_template).is_not_null()
	assert_object(switch_template).is_not_null()
	assert_object(plate_template).is_not_null()
	var circuit_root := circuit_template.instantiate()
	var switch_root := switch_template.instantiate()
	var plate_root := plate_template.instantiate()
	assert_object(circuit_root).is_instanceof(PowerCircuitNodeScript)
	assert_object(switch_root).is_instanceof(TimedSwitchNodeScript)
	assert_object(plate_root).is_instanceof(PressurePlateNodeScript)
	circuit_root.queue_free()
	switch_root.queue_free()
	plate_root.queue_free()

	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionMechanics/PowerCircuitNode_phase9b_circuit")).is_instanceof(PowerCircuitNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/TimedSwitchNode_phase9b_switch")).is_instanceof(TimedSwitchNodeScript)
	assert_object(root.get_node_or_null("MissionMechanics/PressurePlateNode_phase9b_plate")).is_instanceof(PressurePlateNodeScript)
	var player := root.get_node_or_null("Player")
	assert_object(player).is_instanceof(CharacterBody2D)
	assert_object(player.get_node_or_null("CollisionShape2D")).is_instanceof(CollisionShape2D)
	assert_int(player.get("collision_layer")).is_equal(1)
	assert_int(player.get("collision_mask")).is_equal(0)
	var bentley := root.get_node_or_null("Bentley")
	assert_object(bentley).is_instanceof(CharacterBody2D)
	assert_object(bentley.get_node_or_null("CollisionShape2D")).is_instanceof(CollisionShape2D)
	assert_int(bentley.get("collision_layer")).is_equal(1)
	assert_int(bentley.get("collision_mask")).is_equal(0)
	var bridge := root.get_node_or_null("MissionInteractionBridge")
	assert_float(float(bridge.get("interaction_radius"))).is_less(176.0)
	var timed_switch := root.get_node_or_null("MissionMechanics/TimedSwitchNode_phase9b_switch") as Node2D
	assert_vector(timed_switch.position).is_equal(Vector2(520, -112))
	var plate := root.get_node_or_null("MissionMechanics/PressurePlateNode_phase9b_plate")
	var accepted_groups: Array = plate.get("accepted_actor_groups")
	assert_bool(accepted_groups.has(&"bentley")).is_true()
	root.queue_free()


func _spawn_power_circuit() -> Node:
	var node: Node = PowerCircuitNodeScript.new()
	node.name = "PowerCircuitUnderTest"
	add_child(node)
	return node


func _spawn_timed_switch() -> Node:
	var node: Node = TimedSwitchNodeScript.new()
	node.name = "TimedSwitchUnderTest"
	add_child(node)
	return node


func _spawn_pressure_plate() -> Node:
	var node: Node = PressurePlateNodeScript.new()
	node.name = "PressurePlateUnderTest"
	add_child(node)
	return node


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _set_mission_flag_effect_set(flag_key: String) -> EffectSet:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_key
	effect.value_type = "bool"
	effect.value_bool = true
	var effect_set := EffectSetScript.new()
	effect_set.effects = [effect]
	return effect_set


func _snapshot_game_state() -> Dictionary:
	return {
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
