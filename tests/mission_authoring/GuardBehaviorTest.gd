# Focused tests for reusable guard perception, social cover, noise, and author binding.
extends GdUnitTestSuite

const GuardScript := preload("res://src/enemies/Guard.gd")
const GuardSpawnAuthorScript := preload("res://src/missions/iso/authoring/GuardSpawnAuthor.gd")
const InspectionRuleSetScript := preload("res://src/missions/iso/social/InspectionRuleSet.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const NoiseEventScript := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")
const AlertScript := preload("res://src/missions/iso/runtime/MissionAlertController.gd")


func before_test() -> void:
	SocialStealthAdapterScript.clear_all()


func test_unaware_guard_requires_facing_cone_and_detection_buildup() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	var player: Node2D = pair.player
	guard.detection_speed = 1.0
	guard.detection_threshold = 1.0
	guard.alert_duration = 0.0
	guard.set_facing_direction(Vector2.RIGHT)
	player.global_position = Vector2(-20, 0)
	guard._update_ai(2.0)
	assert_bool(guard.is_aware()).is_false()
	assert_float(guard.get_detection_progress()).is_equal(0.0)
	player.global_position = Vector2(20, 0)
	guard._update_ai(0.5)
	assert_bool(guard.is_aware()).is_false()
	assert_float(guard.get_detection_progress()).is_equal_approx(0.5, 0.001)
	guard._update_ai(0.5)
	assert_bool(guard.is_aware()).is_true()
	_free_pair(pair)


func test_detection_decays_and_does_not_attack_before_threshold() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	var player: Node2D = pair.player
	guard.attack_range = 50.0
	guard.detection_speed = 1.0
	guard.detection_decay = 0.5
	guard.detection_threshold = 1.0
	guard.set_facing_direction(Vector2.RIGHT)
	player.global_position = Vector2(20, 0)
	guard._update_ai(0.4)
	assert_int(player.damage_taken).is_equal(0)
	player.global_position = Vector2(-20, 0)
	guard._update_ai(0.4)
	assert_float(guard.get_detection_progress()).is_equal_approx(0.2, 0.001)
	_free_pair(pair)


func test_line_of_sight_blocker_prevents_detection_buildup() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	guard.set_facing_direction(Vector2.RIGHT)
	pair.player.global_position = Vector2(40, 0)
	var blocker := _make_wall(Vector2(20, 0), Vector2(8, 80))
	add_child(blocker)
	await get_tree().physics_frame
	guard._update_ai(2.0)
	assert_bool(guard.is_aware()).is_false()
	assert_float(guard.get_detection_progress()).is_equal(0.0)
	blocker.queue_free()
	_free_pair(pair)


func test_production_guard_contract_covers_startup_and_reinforcement_instances() -> void:
	var packed := load("res://scenes/characters/guard.tscn") as PackedScene
	for role in ["startup", "reinforcement"]:
		var guard := packed.instantiate() as CharacterBody2D
		guard.name = role.capitalize() + "Guard"
		add_child(guard)
		guard.set_physics_process(false)
		assert_int(guard.collision_layer).is_equal(2)
		assert_int(guard.collision_mask).is_equal(7)
		guard.queue_free()


func test_production_guard_body_is_blocked_by_layer_four_wall() -> void:
	var guard := (load("res://scenes/characters/guard.tscn") as PackedScene).instantiate() as CharacterBody2D
	add_child(guard)
	guard.set_physics_process(false)
	guard.global_position = Vector2.ZERO
	var wall := _make_wall(Vector2(40, 0), Vector2(16, 96))
	add_child(wall)
	await get_tree().physics_frame
	var collision := guard.move_and_collide(Vector2(100, 0))
	assert_object(collision).is_not_null()
	assert_object(collision.get_collider()).is_same(wall)
	assert_float(guard.global_position.x).is_less(20.0)
	wall.queue_free()
	guard.queue_free()


func test_damage_knockback_stops_at_layer_four_wall() -> void:
	var player := DamagePlayer.new()
	player.add_to_group("player")
	player.global_position = Vector2.ZERO
	add_child(player)
	var guard := (load("res://scenes/characters/guard.tscn") as PackedScene).instantiate() as CharacterBody2D
	add_child(guard)
	guard.set_physics_process(false)
	guard.global_position = Vector2(16, 0)
	var wall := _make_wall(Vector2(40, 0), Vector2(16, 96))
	add_child(wall)
	await get_tree().physics_frame
	guard.take_damage(1, player)
	await get_tree().process_frame
	assert_float(guard.global_position.x).is_greater_equal(15.9)
	assert_float(guard.global_position.x).is_less_equal(16.0)
	assert_int(guard.health).is_equal(guard.max_health - 1)
	wall.queue_free()
	guard.queue_free()
	player.queue_free()


func test_direct_player_provocation_and_attack_player_spawn_are_hostile() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	guard.take_damage(1, pair.player)
	assert_bool(guard.is_hostile()).is_true()
	assert_bool(guard.is_aware()).is_true()
	guard.set_hostile(false, false)
	guard.apply_authoring_spawn_behavior(&"attack_player")
	assert_bool(guard.is_hostile()).is_true()
	_free_pair(pair)


func test_valid_social_cover_suppresses_only_ambient_detection() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	var rules := InspectionRuleSetScript.new()
	rules.accepted_cover_story_ids = [&"staff"]
	rules.required_task_ids = [&"clear_glasses"]
	rules.min_professionalism = 1
	guard.inspection_rule_set = rules
	guard.social_cover_mission_id = "guard_test"
	guard.set_facing_direction(Vector2.RIGHT)
	pair.player.global_position = Vector2(20, 0)
	SocialStealthAdapterScript.set_cover_story("staff", {}, {"mission_id": "guard_test"})
	SocialStealthAdapterScript.complete_task("clear_glasses", {}, {"mission_id": "guard_test"})
	SocialStealthAdapterScript.set_professionalism(1, {"mission_id": "guard_test"})
	guard._update_ai(2.0)
	assert_bool(guard.is_aware()).is_false()
	guard.set_hostile(true, false)
	assert_bool(guard.is_aware()).is_true()
	_free_pair(pair)


func test_restricted_room_entry_forces_immediate_hostility() -> void:
	var pair := _guard_and_player()
	var guard: Node = pair.guard
	guard.apply_guard_authoring_config({"hostile_on_player_enter_rect": Rect2(100, 100, 200, 200)})
	pair.player.global_position = Vector2(50, 50)
	guard._update_ai(0.01)
	assert_bool(guard.is_hostile()).is_false()
	pair.player.global_position = Vector2(150, 150)
	guard._update_ai(0.01)
	assert_bool(guard.is_hostile()).is_true()
	_free_pair(pair)


func test_decoy_interrupts_patrol_then_resumes_saved_index() -> void:
	var guard := GuardScript.new()
	add_child(guard)
	guard.assign_patrol_points_world([Vector2.ZERO, Vector2(100, 0), Vector2(200, 0)])
	guard._patrol_target_index = 2
	var event := NoiseEventScript.make_event("decoy", "coin", Vector2(10, 0), 100.0, 0.1, "decoy", "player")
	var result: Dictionary = guard.on_noise_heard(event)
	assert_str(String(result.get("code", ""))).is_equal("guard_investigating_noise")
	assert_str(String(guard.get_noise_investigation_state().get("state", ""))).is_equal("traveling")
	guard.global_position = Vector2(10, 0)
	guard._update_ai(0.01)
	assert_str(String(guard.get_noise_investigation_state().get("state", ""))).is_equal("inspecting")
	guard._update_ai(3.01)
	var state := guard.get_noise_investigation_state()
	assert_str(String(state.get("state", ""))).is_equal("idle")
	assert_int(int(state.get("patrol_target_index", -1))).is_equal(2)
	guard.queue_free()


func test_bark_accumulates_to_threshold_and_combat_ignores_noise() -> void:
	var guard := GuardScript.new()
	add_child(guard)
	guard.noise_attention_threshold = 1.0
	var bark := NoiseEventScript.make_event("bark", "bentley", Vector2(20, 0), 100.0, 0.6, "bark", "player")
	assert_str(String(guard.on_noise_heard(bark).get("code", ""))).is_equal("guard_noise_attention_accumulated")
	assert_str(String(guard.on_noise_heard(bark).get("code", ""))).is_equal("guard_investigating_noise")
	guard.set_hostile(true, false)
	assert_str(String(guard.on_noise_heard(bark).get("code", ""))).is_equal("guard_ignored_noise_in_combat")
	guard.queue_free()


func test_guard_scene_has_production_noise_listener() -> void:
	var guard := (load("res://scenes/characters/guard.tscn") as PackedScene).instantiate()
	add_child(guard)
	var listener := guard.get_node_or_null("NoiseListenerComponent")
	assert_object(listener).is_not_null()
	assert_bool(listener.is_in_group("noise_listener")).is_true()
	assert_bool((listener.get("accepted_teams") as PackedStringArray).has("player")).is_true()
	guard.queue_free()


func test_spawn_author_binds_config_and_routes_spotted_to_alert() -> void:
	var mission := Node.new()
	add_child(mission)
	var alert := AlertScript.new()
	alert.name = "MissionAlertController"
	mission.add_child(alert)
	var author := GuardSpawnAuthorScript.new()
	author.spawn_id = &"front_bouncer"
	author.detection_speed_override = 0.25
	mission.add_child(author)
	author.bind_mission(mission)
	var guard := GuardScript.new()
	mission.add_child(guard)
	author._bind_spawned_guard(guard)
	assert_float(guard.detection_speed).is_equal(0.25)
	guard.spotted_player.emit()
	assert_str(alert.last_detection_source).is_equal("guard:front_bouncer")
	assert_str(alert.alert_state).is_equal("alerted")
	mission.queue_free()


func test_velvet_startup_and_reinforcement_guards_use_production_collision_contract() -> void:
	var packed := load("res://scenes/missions_iso/VelvetPawJazzClub_Editable.tscn") as PackedScene
	var mission := packed.instantiate()
	add_child(mission)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var enemies := mission.get_node("EntityRoot/Enemies")
	var startup_guards_checked := 0
	for guard: Node in enemies.get_children():
		if bool(guard.get_meta("ambient_security_guard", false)):
			assert_int(guard.collision_layer).is_equal(2)
			assert_int(guard.collision_mask).is_equal(7)
			startup_guards_checked += 1
	assert_int(startup_guards_checked).is_greater_equal(6)
	for camera: Node in mission.get_node("EntityRoot/Cameras").get_children():
		if String(camera.get("camera_id")) == "velvet_paw_jazz_club.security_camera_author.01":
			camera.set("_minimum_exposure_elapsed", 6.0)
			camera.set("_minimum_exposure_triggered", true)
			break
	var controller := mission.get_node("GameplayRoot/RuntimeHelpers/VelvetPawJazzClubMissionController")
	controller.call("_commit_vip_trespass_alarm")
	await get_tree().process_frame
	var reinforcement_guards_checked := 0
	for guard: Node in enemies.get_children():
		if bool(guard.get_meta("security_response_spawn", false)):
			assert_int(guard.collision_layer).is_equal(2)
			assert_int(guard.collision_mask).is_equal(7)
			reinforcement_guards_checked += 1
	assert_int(reinforcement_guards_checked).is_greater_equal(3)
	mission.queue_free()
	await get_tree().process_frame
	GameState.current_mission_id = ""
	GameState.is_in_mission = false
	GameState.velvet_paw_club_hostile = false
	for key: Variant in GameState.dialogue_flags.keys():
		if String(key).begins_with("mission_flag:velvet_paw_jazz_club:"):
			GameState.dialogue_flags.erase(key)


func _guard_and_player() -> Dictionary:
	var player := DamagePlayer.new()
	player.add_to_group("player")
	add_child(player)
	var guard := GuardScript.new()
	add_child(guard)
	guard.target = player
	return {"guard": guard, "player": player}


func _free_pair(pair: Dictionary) -> void:
	(pair.guard as Node).queue_free()
	(pair.player as Node).queue_free()


func _make_wall(position: Vector2, size: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = 4
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	wall.add_child(shape)
	wall.global_position = position
	return wall


class DamagePlayer:
	extends Node2D
	var damage_taken := 0
	func take_damage(amount: int, _source: Node = null) -> void:
		damage_taken += amount
