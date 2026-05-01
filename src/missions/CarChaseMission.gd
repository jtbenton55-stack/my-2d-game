extends "res://src/levels/LevelBase.gd"

enum MissionStep {
	INTRO,
	GARAGE_PREP,
	PARTS_COLLECTION,
	CHASE_START,
	OBSTACLE_DODGE,
	SIREN_EVENTS,
	ESCAPE_FINISH,
	COMPLETE
}

# Mission Configuration
const SURVIVAL_TIME_PHASE_1 := 45.0  # First wave - getting out of garage area
const SURVIVAL_TIME_PHASE_2 := 60.0  # Main chase through streets
const SPAWN_INTERVAL_INITIAL := 3.0
const SPAWN_INTERVAL_MIN := 1.2

# Current State
var current_step := MissionStep.INTRO
var survival_timer := 0.0
var total_survival_time := 0.0
var required_total_time := SURVIVAL_TIME_PHASE_1 + SURVIVAL_TIME_PHASE_2
var phase_1_complete := false

# Parts Collection
var parts_collected := {
	"keys": false,
	"engine_module": false,
	"evidence_folder": false
}
var total_parts := 3
var parts_found := 0

# Chase Mechanics
var obstacle_spawn_timer := 0.0
var current_spawn_interval := SPAWN_INTERVAL_INITIAL
var active_obstacles: Array[Node] = []
var max_obstacles := 6
var chase_started := false

# Bentley & Rain
var is_raining := true
var siren_active := false
var siren_timer := 0.0
var raincoat_upgrade := false

# Dialogue State
var dom_dialogue_triggered: Dictionary = {}

func _ready() -> void:
	mission_id = "fast_family_getaway"
	objective_text = "Help Dom prepare the getaway car."
	guard_count = 0
	super._ready()

	spawn_poop_bags_at_global_positions([Vector2(260, 420), Vector2(620, 380), Vector2(440, 540)])

	# Check for raincoat upgrade
	raincoat_upgrade = GameState.has_selected_card("bentley_raincoat") or GameState.bentley_upgrades.get("raincoat", false)
	
	_setup_mission_zones()
	_setup_parts_collection()
	_setup_obstacle_spawners()
	_setup_siren_zones()
	_start_intro_sequence()

func _setup_mission_zones() -> void:
	# Connect to garage door trigger
	var garage_trigger := get_node_or_null("GarageDoorTrigger")
	if garage_trigger and garage_trigger.has_signal("body_entered"):
		garage_trigger.body_entered.connect(_on_garage_door_entered)
	
	# Connect exit zone for escape
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone:
		# Disconnect parent's auto-complete, we'll handle it manually
		if exit_zone.is_connected("body_entered", _on_exit_zone_body_entered):
			exit_zone.disconnect("body_entered", _on_exit_zone_body_entered)
		exit_zone.body_entered.connect(_on_escape_zone_entered)

func _setup_parts_collection() -> void:
	# Connect all collectible parts
	for part_id in parts_collected.keys():
		var part_node := get_node_or_null("Parts/" + part_id.capitalize().replace(" ", "").replace("_", ""))
		if part_node and part_node is Area2D:
			if not part_node.body_entered.is_connected(_on_part_collected):
				part_node.body_entered.connect(_on_part_collected.bind(part_id, part_node))
			part_node.add_to_group("interactable")

func _setup_obstacle_spawners() -> void:
	# Obstacle spawners are Marker2D nodes in the ChaseArea
	var spawners := get_node_or_null("ObstacleSpawners")
	if spawners:
		for spawner in spawners.get_children():
			spawner.add_to_group("obstacle_spawner")

func _setup_siren_zones() -> void:
	var siren_zones := get_node_or_null("SirenZones")
	if siren_zones:
		for zone in siren_zones.get_children():
			if zone is Area2D:
				zone.body_entered.connect(_on_siren_zone_entered.bind(zone))

func _start_intro_sequence() -> void:
	current_step = MissionStep.INTRO
	QuestManager.set_objective("Dom needs help. Talk to him in the garage.", mission_id)
	
	# Start Dom's intro dialogue after brief delay
	await get_tree().create_timer(0.5).timeout
	_play_dom_dialogue("intro")

func _play_dom_dialogue(dialogue_id: String) -> void:
	if dom_dialogue_triggered.get(dialogue_id, false):
		return
	dom_dialogue_triggered[dialogue_id] = true
	
	var dialogue_lines: Array[Dictionary] = []
	
	match dialogue_id:
		"intro":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Jake. Bentley. Good, you're here."},
				{"speaker": "Dom", "text": "Sterling's people are closing in. We need to move fast."},
				{"speaker": "Dom", "text": "The car's not ready. Need you to grab the essentials while I prep the engine."},
				{"speaker": "Dom", "text": "Keys are on the wall. Engine module's in the cabinet. Evidence folder is... somewhere safe."},
				{"speaker": "Dom", "text": "And Bentley? I know you don't like the rain, buddy. Stay close to Jake."}
			]
		"first_part":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Good. Keep looking. Everything we need is in this garage."}
			]
		"half_parts":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Halfway there. You find that evidence folder yet? That's what they're after."}
			]
		"all_parts":
			dialogue_lines = [
				{"speaker": "Dom", "text": "That's everything. Car's warming up."},
				{"speaker": "Dom", "text": "Bentley, you ride shotgun. Jake, you're driving."},
				{"speaker": "Dom", "text": "Rain's coming down hard. Stay sharp."},
				{"speaker": "Dom", "text": "When I give the word, we punch it. No hesitation."}
			]
		"chase_start":
			dialogue_lines = [
				{"speaker": "Dom", "text": "They're here! GO GO GO!"},
				{"speaker": "Dom", "text": "Keep moving! Don't let them box us in!"}
			]
		"bentley_howl":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Bentley's howling! He senses something!"},
				{"speaker": "Dom", "text": "Stay sharp!"}
			]
		"mid_chase":
			dialogue_lines = [
				{"speaker": "Dom", "text": "You're doing good! Just like old times!"},
				{"speaker": "Dom", "text": "Sterling's drones can't handle the rain! Use it!"}
			]
		"escape_open":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Exit's ahead! Punch it!"},
				{"speaker": "Dom", "text": "Don't look back!"}
			]
		"success":
			dialogue_lines = [
				{"speaker": "Dom", "text": "We made it. We actually made it."},
				{"speaker": "Dom", "text": "That's what family does, Jake."},
				{"speaker": "Dom", "text": "Bentley, you were a legend back there."}
			]
		"failure":
			dialogue_lines = [
				{"speaker": "Dom", "text": "Jake! Get up! We need to move!"}
			]
	
	if not dialogue_lines.is_empty():
		DialogueManager.start_simple_dialogue(dialogue_lines)

func _on_part_collected(body: Node, part_id: String, part_node: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	if parts_collected.get(part_id, false):
		return
	
	parts_collected[part_id] = true
	parts_found += 1
	part_node.visible = false
	part_node.set_deferred("monitoring", false)
	
	AudioManager.play_sfx("item_pickup")
	
	# Update objective
	QuestManager.set_objective("Parts found: %d/%d" % [parts_found, total_parts], mission_id)
	
	# Trigger dialogue at milestones
	if parts_found == 1:
		_play_dom_dialogue("first_part")
	elif parts_found == 2:
		_play_dom_dialogue("half_parts")
	elif parts_found >= total_parts:
		_all_parts_collected()

func _all_parts_collected() -> void:
	current_step = MissionStep.CHASE_START
	QuestManager.set_objective("All parts found! Talk to Dom to start the getaway.", mission_id)
	_play_dom_dialogue("all_parts")
	
	# Show the car ready indicator
	var car_indicator := get_node_or_null("DomCar/ReadyIndicator")
	if car_indicator:
		car_indicator.visible = true

func _on_garage_door_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_step == MissionStep.CHASE_START and parts_found >= total_parts:
		_start_chase_sequence()

func _start_chase_sequence() -> void:
	current_step = MissionStep.OBSTACLE_DODGE
	chase_started = true
	survival_timer = 0.0
	total_survival_time = 0.0
	
	_play_dom_dialogue("chase_start")
	QuestManager.set_objective("SURVIVE THE CHASE! Avoid obstacles and enemy cars!", mission_id)
	
	# Show the chase area
	var chase_area := get_node_or_null("ChaseArea")
	if chase_area:
		chase_area.visible = true
	
	# Show the exit zone for later
	var exit_zone := get_node_or_null("ChaseArea/ExitZone")
	if exit_zone:
		exit_zone.visible = true
	
	# Move player to chase start position
	if player:
		player.global_position = Vector2(850, 300)
		# Keep player control but limit to road area
	
	# Move dog to player
	if dog:
		dog.global_position = player.global_position + Vector2(30, 20)
	
	# Start Bentley's reaction to rain
	if is_raining and not raincoat_upgrade:
		_show_bentley_rain_reaction()
	
	# Fade to chase camera view
	_start_chase_camera()

func _show_bentley_rain_reaction() -> void:
	if dog and dog.has_method("set_rain_penalty"):
		dog.set_rain_penalty(true)
	
	# Bentley cute rain reaction dialogue
	var rain_lines: Array[Dictionary] = [
		{"speaker": "Bentley", "text": "*whines softly at the window*"},
		{"speaker": "Dom", "text": "I know, buddy. Rain's tough on the fur."},
		{"speaker": "Dom", "text": "Jake, keep him warm. He'll do the same for you."}
	]
	DialogueManager.start_simple_dialogue(rain_lines)

func _start_chase_camera() -> void:
	# Switch to the chase camera that follows the "road"
	var chase_cam := get_node_or_null("ChaseCamera2D")
	if chase_cam:
		chase_cam.make_current()
		active_camera = chase_cam

func _physics_process(delta: float) -> void:
	if chase_started and not is_complete and not is_failed:
		_process_chase(delta)
	
	if siren_active:
		_process_siren(delta)

func _process_chase(delta: float) -> void:
	survival_timer += delta
	total_survival_time += delta
	
	# Update spawn interval (gets faster over time)
	var progress := total_survival_time / required_total_time
	current_spawn_interval = lerp(SPAWN_INTERVAL_INITIAL, SPAWN_INTERVAL_MIN, progress)
	
	# Spawn obstacles
	obstacle_spawn_timer += delta
	if obstacle_spawn_timer >= current_spawn_interval:
		obstacle_spawn_timer = 0.0
		_spawn_obstacle()
	
	# Phase transitions
	if not phase_1_complete and total_survival_time >= SURVIVAL_TIME_PHASE_1:
		phase_1_complete = true
		current_step = MissionStep.SIREN_EVENTS
		_play_dom_dialogue("mid_chase")
	
	# Check completion
	if total_survival_time >= required_total_time:
		current_step = MissionStep.ESCAPE_FINISH
		QuestManager.set_objective("ESCAPE ROUTE OPEN! Get to the safehouse exit!", mission_id)
		_show_escape_route()
	
	# Update HUD with timer
	var time_remaining: float = maxf(0.0, required_total_time - total_survival_time)
	EventBus.objective_updated.emit("Chase time: %.0f | Survive: %.0f" % [time_remaining, total_survival_time])

func _spawn_obstacle() -> void:
	if active_obstacles.size() >= max_obstacles:
		return
	
	# Get random spawner
	var spawners := get_tree().get_nodes_in_group("obstacle_spawner")
	if spawners.is_empty():
		return
	
	var spawner: Node2D = spawners[randi() % spawners.size()]
	
	# Spawn obstacle (using simple sprites, no Polygon2D)
	var obstacle := _create_obstacle()
	if obstacle:
		add_child(obstacle)
		obstacle.global_position = spawner.global_position
		active_obstacles.append(obstacle)
		
		# Auto-cleanup after obstacle passes
		obstacle.tree_exited.connect(_on_obstacle_removed.bind(obstacle))

func _create_obstacle() -> Node2D:
	var obstacle_type := randi() % 3
	var obstacle := Area2D.new()
	obstacle.add_to_group("enemy")  # So Bentley's bark affects them
	obstacle.add_to_group("obstacle")
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	collision.shape = shape
	obstacle.add_child(collision)
	
	# Visual (ColorRect instead of Polygon2D)
	var visual := ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)  # Center it
	
	match obstacle_type:
		0:  # Enemy car - red
			visual.color = Color(0.8, 0.15, 0.15, 1.0)
			obstacle.name = "EnemyCar"
		1:  # Road block - orange
			visual.color = Color(0.9, 0.5, 0.1, 1.0)
			obstacle.name = "RoadBlock"
		2:  # Drone - yellow
			visual.color = Color(0.95, 0.85, 0.1, 1.0)
			obstacle.name = "Drone"
			visual.size = Vector2(30, 30)
			visual.position = Vector2(-15, -15)
	
	obstacle.add_child(visual)
	
	# Movement script
	var script := GDScript.new()
	script.source_code = """
extends Area2D

@export var speed := 250.0
var stun_timer := 0.0
var is_stunned := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
		return
	
	# Move right to left (toward car)
	position.x -= speed * delta
	
	# Remove if off screen
	if position.x < -100:
		queue_free()

func stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	modulate = Color(0.5, 0.5, 1.0, 0.7)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Damage player
		if body.has_method("take_damage"):
			body.take_damage(15, self)
		queue_free()
"""
	obstacle.set_script(script)
	
	return obstacle

func _on_obstacle_removed(obstacle: Node) -> void:
	active_obstacles.erase(obstacle)

func _process_siren(delta: float) -> void:
	siren_timer += delta
	
	# Bentley howls at sirens
	if siren_timer >= 2.0 and dog:
		_trigger_bentley_howl()
		siren_timer = 0.0

func _trigger_bentley_howl() -> void:
	if dog and dog.has_method("bark_stun"):
		# Extended bark that affects obstacles
		var extended_radius: float = dog.bark_radius * 1.5
		for obstacle in active_obstacles:
			if is_instance_valid(obstacle) and obstacle.global_position.distance_to(dog.global_position) <= extended_radius:
				if obstacle.has_method("stun"):
					obstacle.stun(3.0)  # Longer stun for siren howl
		
		AudioManager.play_sfx("bentley_bark", dog.global_position)
		_play_dom_dialogue("bentley_howl")

func _on_siren_zone_entered(body: Node, _zone: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	
	siren_active = true
	siren_timer = 0.0
	
	# Trigger siren visual effect
	var siren_overlay := get_node_or_null("RainOverlay/SirenFlash")
	if siren_overlay:
		siren_overlay.visible = true

func _show_escape_route() -> void:
	# Show exit zone
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone:
		exit_zone.visible = true
		var exit_visual := exit_zone.get_node_or_null("ExitVisual")
		if exit_visual:
			exit_visual.modulate = Color(0.2, 0.9, 0.3, 0.6)
	
	_play_dom_dialogue("escape_open")

func _on_escape_zone_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_step == MissionStep.ESCAPE_FINISH or total_survival_time >= required_total_time * 0.8:
		_complete_chase_mission()
	else:
		QuestManager.set_objective("Too soon! Keep surviving the chase!", mission_id)

func _complete_chase_mission() -> void:
	if is_complete or is_failed:
		return
	
	chase_started = false
	_play_dom_dialogue("success")
	
	# Wait for dialogue then complete
	await get_tree().create_timer(3.0).timeout
	
	CollectibleManager.collect_polaroid("car_chase_polaroid")
	
	# Restore player control
	if player:
		player.can_control = true
	
	# Reset camera
	_setup_camera()
	
	super.complete_level()

func complete_level() -> void:
	# Override parent - we handle completion through _complete_chase_mission
	if not chase_started and parts_found >= total_parts:
		# If somehow called before chase, just start chase
		_start_chase_sequence()
	return

func fail_level(reason = "The rain won this round. Dom kept the engine warm.") -> void:
	if is_complete or is_failed:
		return
	
	chase_started = false
	
	# Stop all obstacles
	for obstacle in active_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	active_obstacles.clear()
	
	# Restore player control
	if player:
		player.can_control = true
	
	_play_dom_dialogue("failure")
	
	super.fail_level(reason)

func _on_player_died() -> void:
	if GameState.is_in_mission:
		fail_level("Jake went down. Dom had to pull him out. The evidence is still out there.")
