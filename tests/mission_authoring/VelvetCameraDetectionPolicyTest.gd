# GdUnit4 tests for reusable camera policy, occlusion, and forced stealth.
extends GdUnitTestSuite

const AlertScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")
const CameraScript := preload("res://src/missions/iso/runtime/MissionSecurityCamera.gd")
const CameraAuthorScript := preload("res://src/missions/iso/authoring/SecurityCameraAuthor.gd")
const HideSpotScript := preload("res://src/missions/iso/authoring/mechanics/HideSpotNode.gd")
const PlayerScript := preload("res://src/player/Player.gd")
const MechanicScript := preload("res://src/missions/iso/authoring/mechanics/MechanicAreaBase.gd")

class StealthActor extends Node2D:
	var stealth_active := false

	func is_stealth_active() -> bool:
		return stealth_active


func test_default_camera_policy_preserves_always_detect_behavior() -> void:
	var alert := AlertScript.new()
	add_child(alert)
	assert_bool(alert.should_camera_accumulate_exposure(null, "default_camera")).is_true()
	assert_str(String(alert.get_camera_policy_debug_state().get("last_evaluation", {}).get("reason", ""))).is_equal("default_always_detect")
	await _free_node(alert)


func test_velvet_normal_heat_requires_action_and_theft_respects_concealment() -> void:
	var alert := AlertScript.new()
	add_child(alert)
	alert.configure_camera_detection_policy(true, 0)
	var actor := StealthActor.new()
	actor.add_to_group("player")
	add_child(actor)

	assert_bool(alert.should_camera_accumulate_exposure(actor, "velvet_camera")).is_false()
	assert_bool(alert.register_suspicious_action("take_staff_key", "theft").get("ok", false)).is_true()
	assert_bool(alert.should_camera_accumulate_exposure(actor, "velvet_camera")).is_true()
	actor.stealth_active = true
	assert_bool(alert.should_camera_accumulate_exposure(actor, "velvet_camera")).is_false()
	actor.stealth_active = false
	actor.add_to_group("mission_hidden")
	assert_bool(alert.should_camera_accumulate_exposure(actor, "velvet_camera")).is_false()
	actor.remove_from_group("mission_hidden")
	assert_bool(alert.end_suspicious_action("take_staff_key").get("ok", false)).is_true()
	assert_bool(alert.should_camera_accumulate_exposure(actor, "velvet_camera")).is_false()

	await _free_node(actor)
	await _free_node(alert)


func test_raised_initial_posture_and_reset_clear_actions() -> void:
	var alert := AlertScript.new()
	add_child(alert)
	alert.configure_camera_detection_policy(true, 2)
	assert_bool(alert.should_camera_accumulate_exposure(null, "hot_camera")).is_true()
	assert_str(String(alert.get_camera_policy_debug_state().get("last_evaluation", {}).get("reason", ""))).is_equal("raised_initial_posture")
	alert.configure_camera_detection_policy(true, 0)
	alert.register_suspicious_action("theft", "theft")
	alert.reset_attempt_state()
	assert_bool(alert.is_suspicious_action_active()).is_false()
	assert_int((alert.get_camera_policy_debug_state().get("active_actions", {}) as Dictionary).size()).is_equal(0)
	await _free_node(alert)


func test_hold_interaction_registers_and_clears_camera_suspicion() -> void:
	var alert := AlertScript.new()
	add_child(alert)
	var mechanic := MechanicScript.new()
	mechanic.mechanic_id = &"watched_pickup"
	mechanic.interact_duration = 1.0
	mechanic.suspicious_action_kind = "theft"
	add_child(mechanic)
	var actor := Node2D.new()
	add_child(actor)

	mechanic.call("_begin_hold", actor)
	assert_bool(alert.is_suspicious_action_active("watched_pickup")).is_true()
	mechanic.cancel_hold("test_cancel")
	assert_bool(alert.is_suspicious_action_active("watched_pickup")).is_false()

	await _free_node(actor)
	await _free_node(mechanic)
	await _free_node(alert)


func test_forced_stealth_sources_preserve_manual_stealth_and_hide_spot_source() -> void:
	var alert := AlertScript.new()
	alert.add_to_group("iso_alert_controller")
	add_child(alert)
	var player := PlayerScript.new()
	player.is_stealth = true
	add_child(player)
	assert_bool(player.add_forced_stealth_source("scripted_cover")).is_true()
	assert_bool(player.remove_forced_stealth_source("scripted_cover")).is_true()
	assert_bool(player.is_stealth_active()).is_true()

	player.is_stealth = false
	player.set("_manual_stealth", false)
	var hide := HideSpotScript.new()
	hide.mechanic_id = &"camera_hide"
	add_child(hide)
	assert_bool(hide.enter_hide(player).get("ok", false)).is_true()
	assert_bool(player.has_forced_stealth_source()).is_true()
	assert_bool(player.is_stealth_active()).is_true()
	hide.exit_hide(player)
	assert_bool(player.has_forced_stealth_source()).is_false()
	assert_bool(player.is_stealth_active()).is_false()

	await _free_node(hide)
	await _free_node(player)
	await _free_node(alert)


func test_camera_author_passes_los_occlusion_configuration() -> void:
	var author := CameraAuthorScript.new()
	author.require_line_of_sight = true
	author.occlusion_collision_mask = 12
	author.visible_cone_ray_count = 9
	author.exposure_requires_player_movement = true
	author.player_movement_threshold = 12.0
	var config: Dictionary = author.build_runtime_config()
	assert_bool(config.get("require_line_of_sight", false)).is_true()
	assert_int(int(config.get("occlusion_collision_mask", 0))).is_equal(12)
	assert_bool(bool(config.get("occlude_cover_tiles", false))).is_true()
	assert_int(int(config.get("visible_cone_ray_count", 0))).is_equal(9)
	assert_bool(bool(config.get("exposure_requires_player_movement", false))).is_true()
	assert_float(float(config.get("player_movement_threshold", 0.0))).is_equal(12.0)
	author.free()


func test_camera_queries_controller_before_accumulating() -> void:
	var alert := AlertScript.new()
	add_child(alert)
	alert.configure_camera_detection_policy(true, 0)
	var actor := StealthActor.new()
	actor.add_to_group("player")
	actor.position = Vector2(40, 0)
	add_child(actor)
	var camera := CameraScript.new()
	camera.sweep_min_degrees = 0.0
	camera.sweep_max_degrees = 0.0
	camera.sweep_speed = 0.0
	add_child(camera)
	camera.set("_player", actor)
	camera.set("_controller", alert)
	camera.call("_process", 1.0)
	assert_float(alert.alert_score).is_equal(0.0)
	assert_float(camera.get_detection_value()).is_equal(0.0)
	alert.register_suspicious_action("camera_theft", "theft")
	camera.call("_process", 1.0)
	assert_bool(alert.alert_score > 0.0).is_true()

	await _free_node(camera)
	await _free_node(actor)
	await _free_node(alert)


func test_movement_sensitive_camera_freezes_exposure_while_stationary() -> void:
	var actor := StealthActor.new()
	actor.add_to_group("player")
	actor.position = Vector2(40, 0)
	add_child(actor)
	var camera := CameraScript.new()
	camera.sweep_min_degrees = 0.0
	camera.sweep_max_degrees = 0.0
	camera.sweep_speed = 0.0
	camera.exposure_requires_player_movement = true
	camera.player_movement_threshold = 8.0
	add_child(camera)
	camera.call("_on_body_entered", actor)
	camera.set("_detection_value", 0.35)

	camera.call("_process", 0.5)
	assert_float(camera.get_detection_value()).is_equal(0.35)
	actor.position += Vector2(16, 0)
	camera.call("_process", 0.5)
	assert_float(camera.get_detection_value()).is_greater(0.35)
	var moving_detection := camera.get_detection_value()
	camera.call("_process", 0.5)
	assert_float(camera.get_detection_value()).is_equal(moving_detection)

	await _free_node(camera)
	await _free_node(actor)


func test_wall_blocks_los_and_clips_visible_cone() -> void:
	var camera := CameraScript.new()
	camera.sight_range = 200.0
	camera.fov_angle_degrees = 60.0
	camera.require_line_of_sight = true
	camera.occlusion_collision_mask = 4
	camera.visible_cone_ray_count = 9
	camera.sweep_min_degrees = 0.0
	camera.sweep_max_degrees = 0.0
	camera.sweep_speed = 0.0
	add_child(camera)
	var wall := StaticBody2D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	wall.position = Vector2(80, 0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(12, 120)
	shape.shape = rectangle
	wall.add_child(shape)
	add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_bool(camera.has_line_of_sight_to(Vector2(160, 0))).is_false()
	camera.call("_update_visible_cone")
	var points := camera.get_visible_cone_points()
	var center_point: Vector2 = points[5]
	assert_bool(center_point.length() < 100.0).is_true()

	await _free_node(wall)
	await _free_node(camera)


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
