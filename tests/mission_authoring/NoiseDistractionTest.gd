# GdUnit4 tests for Phase 8A-8G-lite noise and distraction authoring.
extends GdUnitTestSuite

const NoiseEventScript := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")
const NoiseEmitterNodeScript := preload("res://src/missions/iso/runtime/noise/NoiseEmitterNode.gd")
const NoiseListenerComponentScript := preload("res://src/missions/iso/runtime/noise/NoiseListenerComponent.gd")
const DistractionObjectScript := preload("res://src/missions/iso/authoring/mechanics/DistractionObject.gd")
const MechanicAreaBaseScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")
const MissionAlertControllerScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const MissionPoopBagDecoyPointScript := preload("res://src/missions/iso/runtime/MissionPoopBagDecoyPoint.gd")
const DogCompanionScript := preload("res://src/player/DogCompanion.gd")
const MissionEffectScript := preload("res://src/missions/iso/authoring/core/MissionEffect.gd")
const EffectSetScript := preload("res://src/missions/iso/authoring/core/EffectSet.gd")


func test_noise_event_schema_and_range_helper() -> void:
	var event := NoiseEventScript.make_event("test_noise", "source_01", Vector2(10, 20), 64.0, 0.75, "bark", "player", {"reason": "test"})
	assert_str(String(event.get("noise_id", ""))).is_equal("test_noise")
	assert_str(String(event.get("source_id", ""))).is_equal("source_01")
	assert_vector(event.get("position", Vector2.ZERO)).is_equal(Vector2(10, 20))
	assert_float(float(event.get("radius", 0.0))).is_equal(64.0)
	assert_float(float(event.get("strength", 0.0))).is_equal(0.75)
	assert_str(String(event.get("kind", ""))).is_equal("bark")
	assert_str(String(event.get("team", ""))).is_equal("player")
	assert_bool(NoiseEventScript.is_point_in_range(event, Vector2(20, 20))).is_true()
	assert_bool(NoiseEventScript.is_point_in_range(event, Vector2(200, 20))).is_false()


func test_noise_emitter_extends_mechanic_area_base() -> void:
	var emitter := NoiseEmitterNodeScript.new()
	assert_object(emitter).is_instanceof(MechanicAreaBaseScript)
	emitter.free()


func test_noise_emitter_applies_effect_and_routes_to_alert_controller() -> void:
	var snapshot := _snapshot_game_state()
	GameState.dialogue_flags.clear()
	var alert := MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var emitter := NoiseEmitterNodeScript.new()
	emitter.name = "NoiseEmitterUnderTest"
	emitter.mechanic_id = &"phase8_noise_test"
	emitter.mission_id_override = "test_mission"
	emitter.one_shot = false
	emitter.noise_id = &"test_noise"
	emitter.noise_kind = "bark"
	emitter.noise_team = "player"
	emitter.noise_strength = 0.75
	emitter.success_effects = _set_mission_flag_effect_set("phase8_noise_emitted")
	add_child(emitter)

	var result: Dictionary = emitter.activate(null, "script")
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(emitter.last_noise_result.get("code", ""))).is_equal("noise_emitted")
	assert_str(String(alert.alert_state)).is_equal("suspicious")
	assert_int(alert.total_noise_events).is_equal(1)
	assert_bool(GameState.dialogue_flags.get("mission_flag:test_mission:phase8_noise_emitted", false)).is_true()

	_restore_game_state(snapshot)
	_free_node(emitter)
	_free_node(alert)


func test_bentley_bark_emits_noise_event_to_alert_controller() -> void:
	var alert := MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var dog := DogCompanionScript.new()
	dog.name = "BentleyNoiseUnderTest"
	dog.ability_meter = 100.0
	dog.bark_cost = 1.0
	dog.bark_radius = 120.0
	add_child(dog)

	var result: Dictionary = dog.command_bark()
	assert_bool(result.get("ok", false)).is_true()
	assert_str(String(dog.last_noise_result.get("code", ""))).is_equal("noise_emitted")
	assert_int(alert.total_noise_events).is_equal(1)
	assert_str(String((alert.last_noise_event).get("kind", ""))).is_equal("bark")

	_free_node(dog)
	_free_node(alert)


func test_distraction_object_defaults_to_player_decoy_noise() -> void:
	var distraction := DistractionObjectScript.new()
	assert_object(distraction).is_instanceof(NoiseEmitterNodeScript)
	assert_str(String(distraction.get("noise_kind"))).is_equal("decoy")
	assert_str(String(distraction.get("noise_team"))).is_equal("player")
	assert_str(String(distraction.get("prompt_text"))).contains("distraction")
	distraction.free()


func test_noise_listener_records_in_range_noise() -> void:
	var parent := Node2D.new()
	parent.name = "NoiseListenerParent"
	parent.global_position = Vector2(20, 0)
	add_child(parent)
	var listener := NoiseListenerComponentScript.new()
	listener.listener_id = &"phase8_listener_test"
	parent.add_child(listener)
	var event := NoiseEventScript.make_event("listener_noise", "source", Vector2.ZERO, 64.0, 0.5, "decoy", "player")

	var result: Dictionary = listener.register_noise(event)
	assert_bool(result.get("ok", false)).is_true()
	assert_int(listener.heard_count).is_equal(1)
	assert_str(String(listener.last_heard_noise.get("noise_id", ""))).is_equal("listener_noise")
	assert_bool(parent.has_meta("last_noise_event")).is_true()

	var ignored := NoiseEventScript.make_event("far_noise", "source", Vector2(1000, 0), 64.0, 0.5, "decoy", "player")
	var ignored_result: Dictionary = listener.register_noise(ignored)
	assert_bool(ignored_result.get("ok", true)).is_false()
	assert_int(listener.heard_count).is_equal(1)
	_free_node(parent)


func test_poop_bag_decoy_point_emits_noise_after_consuming_bag() -> void:
	var snapshot := _snapshot_game_state()
	GameState.current_mission_id = "test_mission"
	GameState.poop_bag_count = 1
	GameState.poop_bag_inventory = {"count": 1, "collected_this_mission": 1, "used_this_mission": 0}
	var alert := MissionAlertControllerScript.new()
	alert.name = "MissionAlertController"
	add_child(alert)
	var decoy := MissionPoopBagDecoyPointScript.new()
	decoy.name = "PoopBagDecoyNoiseUnderTest"
	decoy.decoy_id = "poop_decoy_test"
	decoy.placeholder_id = "poop_decoy_test"
	decoy.mission_id = "test_mission"
	decoy.global_position = Vector2(12, 16)
	add_child(decoy)

	decoy._complete(null)
	assert_int(GameState.get_poop_bag_count()).is_equal(0)
	assert_str(String(decoy.last_noise_result.get("code", ""))).is_equal("noise_emitted")
	assert_int(alert.total_noise_events).is_equal(1)
	assert_str(String(alert.last_noise_event.get("kind", ""))).is_equal("poop_decoy")
	assert_vector(alert.last_noise_event.get("position", Vector2.ZERO)).is_equal(Vector2(12, 16))

	_restore_game_state(snapshot)
	_free_node(decoy)
	_free_node(alert)


func test_templates_and_dev_scene_contain_phase8_nodes() -> void:
	assert_object(load("res://scenes/missions/iso/authoring/NoiseEmitterNodeTemplate.tscn")).is_not_null()
	assert_object(load("res://scenes/missions/iso/authoring/DistractionObjectTemplate.tscn")).is_not_null()
	var scene := load("res://scenes/dev/mission_authoring/MechanicAuthoringTestRoom.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var root := scene.instantiate()
	add_child(root)
	assert_object(root.get_node_or_null("MissionAlertController")).is_not_null()
	var noise := root.get_node_or_null("MissionMechanics/NoiseEmitterNode_phase8a_bark_lure")
	var distraction := root.get_node_or_null("MissionMechanics/DistractionObject_phase8d_decoy")
	var listener := root.get_node_or_null("MissionMechanics/Phase8E_NoiseListenerGuard/NoiseListenerComponent_phase8e")
	assert_object(noise).is_not_null()
	assert_object(distraction).is_not_null()
	assert_object(listener).is_not_null()
	assert_str(String(noise.get("noise_kind"))).is_equal("bark")
	assert_str(String(distraction.get("noise_kind"))).is_equal("decoy")
	assert_str(String(listener.get("listener_id"))).is_equal("phase8e_guard_listener")
	root.queue_free()


func _set_mission_flag_effect_set(flag_id: String) -> Resource:
	var effect := MissionEffectScript.new()
	effect.effect_type = MissionEffectScript.EffectType.SET_MISSION_FLAG
	effect.key = flag_id
	effect.value_type = "bool"
	effect.value_bool = true
	var set := EffectSetScript.new()
	set.effects = [effect]
	return set


func _snapshot_game_state() -> Dictionary:
	return {
		"current_mission_id": GameState.current_mission_id,
		"pending_mission_id": GameState.pending_mission_id,
		"dialogue_flags": GameState.dialogue_flags.duplicate(true),
		"poop_bag_count": GameState.poop_bag_count,
		"poop_bag_inventory": GameState.poop_bag_inventory.duplicate(true),
		"mission_performance": GameState.mission_performance.duplicate(true),
	}


func _restore_game_state(snapshot: Dictionary) -> void:
	GameState.current_mission_id = String(snapshot.get("current_mission_id", ""))
	GameState.pending_mission_id = String(snapshot.get("pending_mission_id", ""))
	GameState.dialogue_flags = (snapshot.get("dialogue_flags", {}) as Dictionary).duplicate(true)
	GameState.poop_bag_count = int(snapshot.get("poop_bag_count", 0))
	GameState.poop_bag_inventory = (snapshot.get("poop_bag_inventory", {}) as Dictionary).duplicate(true)
	GameState.mission_performance = (snapshot.get("mission_performance", {}) as Dictionary).duplicate(true)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
