# CarChaseMission.gd
# Mission 4: The Fast Family Getaway
# Top-down scrolling car chase - help Dom escape with evidence
# Different gameplay style: scrolling dodge sequence instead of exploration

extends Node2D

# ===== MISSION PHASES =====
enum MissionPhase {
	GARAGE_INTRO,      # Dom dialogue in garage
	CHASE_START,       # Transition animation
	CHASE_ACTIVE,      # Main scrolling chase
	CHASE_SUCCESS,     # Reached safehouse
	COMPLETE           # Mission done
}
var current_phase: MissionPhase = MissionPhase.GARAGE_INTRO

# Mission data
const MISSION_ID: String = "fast_family_getaway"
const REWARD_CARD: String = "doms_getaway_keys"
const REWARD_POLAROID: String = "car_chase"
const REWARD_TRINKET: String = "doms_wrench"

# ===== CHASE CONFIG =====
const ROAD_WIDTH: float = 400.0
const ROAD_CENTER_X: float = 400.0
const ROAD_LEFT: float = ROAD_CENTER_X - ROAD_WIDTH / 2.0
const ROAD_RIGHT: float = ROAD_CENTER_X + ROAD_WIDTH / 2.0
const SCROLL_SPEED_BASE: float = 200.0
const SCROLL_SPEED_MAX: float = 400.0
const CHASE_DISTANCE_TOTAL: float = 8000.0  # Total distance to safehouse
const PLAYER_SPEED: float = 300.0
const PLAYER_SPEED_BOOST: float = 390.0     # With Dom's Getaway Keys card
const PLAYER_CAR_WIDTH: float = 40.0
const PLAYER_CAR_HEIGHT: float = 60.0
const ENEMY_CAR_WIDTH: float = 40.0
const ENEMY_CAR_HEIGHT: float = 60.0
const OBSTACLE_WIDTH: float = 50.0
const OBSTACLE_HEIGHT: float = 30.0
const CRASH_DAMAGE: int = 25
const INVULN_TIME: float = 1.0

# ===== NODES =====
@onready var player_car: Area2D = $PlayerCar
@onready var road_container: Node2D = $RoadContainer
@onready var obstacle_container: Node2D = $ObstacleContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var collectible_container: Node2D = $CollectibleContainer
@onready var camera: Camera2D = $Camera2D
@onready var hud_container: CanvasLayer = $HUD

# ===== STATE =====
var scroll_speed: float = SCROLL_SPEED_BASE
var chase_distance: float = 0.0
var player_health: int = 100
var player_max_health: int = 100
var player_invuln_timer: float = 0.0
var player_x: float = ROAD_CENTER_X
var player_target_x: float = ROAD_CENTER_X
var is_alive: bool = true
var polaroid_collected: bool = false
var trinket_collected: bool = false
var has_getaway_keys: bool = false
var obstacle_timer: float = 0.0
var enemy_timer: float = 0.0
var collectible_timer: float = 0.0
var road_stripe_offset: float = 0.0
var difficulty_ramp: float = 0.0  # 0.0 to 1.0 over the chase

# Road visual nodes
var road_bg: Polygon2D
var road_stripes: Node2D
var road_walls: Array[Polygon2D] = []

# HUD elements
var health_bar: ProgressBar
var distance_bar: ProgressBar
var speed_label: Label
var objective_label: Label
var damage_flash: ColorRect

# ===== DIALOGUE =====
const DOM_GARAGE_LINES: Array[String] = [
	"Alright, listen up.",
	"Sterling's goons are right behind us.",
	"I've got the evidence in the trunk - we CANNOT let them get it.",
	"You drive, I'll keep the engine running hot.",
	"Let's ride."
]

const DOM_CHASE_BANTER: Array[String] = [
	"Watch out!",
	"They're gaining!",
	"Left! No, RIGHT!",
	"Nice move!",
	"Keep it steady!",
	"They're everywhere!",
	"Don't let them box you in!",
	"Almost there!",
	"Step on it!"
]

const DOM_SUCCESS_LINES: Array[String] = [
	"We made it! Haha!",
	"Nobody outruns Dom in a chase.",
	"Here - take my getaway keys. You earned 'em.",
	"Next time Sterling tries something, we'll be ready."
]

# ===== LIFECYCLE =====

func _ready() -> void:
	# Check if player has Dom's Getaway Keys card (hint card from previous mission)
	has_getaway_keys = GameState.has_card("doms_getaway_keys")
	
	# Start mission in GameState
	GameState.start_mission(MISSION_ID)
	
	# Build the scene
	_build_road()
	_build_player_car()
	_build_hud()
	
	# Start with garage intro
	_start_garage_intro()

func _process(delta: float) -> void:
	match current_phase:
		MissionPhase.GARAGE_INTRO:
			pass  # Waiting for dialogue
		MissionPhase.CHASE_ACTIVE:
			_update_chase(delta)
		MissionPhase.CHASE_SUCCESS:
			pass  # Waiting for dialogue
		MissionPhase.COMPLETE:
			pass

# ===== GARAGE INTRO =====

func _start_garage_intro() -> void:
	current_phase = MissionPhase.GARAGE_INTRO
	
	# Show garage visual
	_show_garage_visual()
	
	# Hide chase elements
	road_container.visible = false
	obstacle_container.visible = false
	enemy_container.visible = false
	
	# Show Dom dialogue
	for line in DOM_GARAGE_LINES:
		EventBus.dialogue_started.emit("Dom", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()
	
	# Transition to chase
	await get_tree().create_timer(0.5).timeout
	_start_chase()

func _show_garage_visual() -> void:
	# Dark garage background
	var garage_bg := Polygon2D.new()
	garage_bg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(800, 0),
		Vector2(800, 600), Vector2(0, 600)
	])
	garage_bg.color = Color(0.12, 0.12, 0.14, 1.0)
	garage_bg.z_index = -10
	add_child(garage_bg)
	
	# Garage door (top)
	var garage_door := Polygon2D.new()
	garage_door.polygon = PackedVector2Array([
		Vector2(200, 0), Vector2(600, 0),
		Vector2(600, 120), Vector2(200, 120)
	])
	garage_door.color = Color(0.35, 0.3, 0.25, 1.0)
	garage_door.z_index = -5
	add_child(garage_door)
	
	# Dom's car (center)
	var car_body := Polygon2D.new()
	car_body.polygon = PackedVector2Array([
		Vector2(-20, -30), Vector2(20, -30),
		Vector2(20, 30), Vector2(-20, 30)
	])
	car_body.color = Color(0.8, 0.15, 0.15, 1.0)  # Red car
	car_body.position = Vector2(400, 350)
	car_body.z_index = 0
	add_child(car_body)
	
	# Dom (standing next to car)
	var dom_sprite := Polygon2D.new()
	dom_sprite.polygon = PackedVector2Array([
		Vector2(-12, -24), Vector2(12, -24),
		Vector2(12, 0), Vector2(-12, 0)
	])
	dom_sprite.color = Color(0.2, 0.2, 0.7, 1.0)  # Blue for Dom
	dom_sprite.position = Vector2(340, 340)
	dom_sprite.z_index = 1
	add_child(dom_sprite)
	
	# Dom label
	var dom_label := Label.new()
	dom_label.text = "Dom"
	dom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dom_label.position = Vector2(320, 300)
	dom_label.add_theme_font_size_override("font_size", 14)
	add_child(dom_label)
	
	# Workbench
	var bench := Polygon2D.new()
	bench.polygon = PackedVector2Array([
		Vector2(600, 300), Vector2(750, 300),
		Vector2(750, 380), Vector2(600, 380)
	])
	bench.color = Color(0.4, 0.35, 0.3, 1.0)
	bench.z_index = -1
	add_child(bench)
	
	# Wrench on bench (trinket hint)
	var wrench := Polygon2D.new()
	wrench.polygon = PackedVector2Array([
		Vector2(-4, -12), Vector2(4, -12),
		Vector2(4, 12), Vector2(-4, 12)
	])
	wrench.color = Color(0.7, 0.7, 0.75, 1.0)
	wrench.position = Vector2(670, 310)
	wrench.z_index = 0
	add_child(wrench)

# ===== CHASE START =====

func _start_chase() -> void:
	current_phase = MissionPhase.CHASE_START
	
	# Remove garage visuals
	for child in get_children():
		if child is Polygon2D and child != road_bg and child != player_car:
			if child.get_parent() == self and child.name != "RoadBG" and child.name != "PlayerCar":
				child.queue_free()
	
	# Show chase elements
	road_container.visible = true
	obstacle_container.visible = true
	enemy_container.visible = true
	
	# Reset player position
	player_x = ROAD_CENTER_X
	player_target_x = ROAD_CENTER_X
	player_car.position = Vector2(player_x, 450)
	
	# Update HUD
	objective_label.text = "ESCAPE TO SAFEHOUSE"
	
	# Brief countdown
	EventBus.dialogue_started.emit("Dom", "GO GO GO!")
	await get_tree().create_timer(1.0).timeout
	EventBus.dialogue_ended.emit()
	
	current_phase = MissionPhase.CHASE_ACTIVE
	EventBus.quest_started.emit(MISSION_ID, "Escape to the safehouse!")

# ===== CHASE UPDATE =====

func _update_chase(delta: float) -> void:
	if not is_alive:
		return
	
	# Ramp difficulty over the chase
	difficulty_ramp = clamp(chase_distance / CHASE_DISTANCE_TOTAL, 0.0, 1.0)
	
	# Update scroll speed (gets faster as chase progresses)
	scroll_speed = lerp(SCROLL_SPEED_BASE, SCROLL_SPEED_MAX, difficulty_ramp)
	if has_getaway_keys:
		scroll_speed *= 1.15  # 15% speed boost with card
	
	# Update distance
	chase_distance += scroll_speed * delta
	
	# Update player position (smooth movement to target)
	var move_speed = PLAYER_SPEED_BOOST if has_getaway_keys else PLAYER_SPEED
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		player_target_x -= move_speed * delta
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		player_target_x += move_speed * delta
	
	# Clamp to road
	player_target_x = clamp(player_target_x, ROAD_LEFT + PLAYER_CAR_WIDTH / 2.0, ROAD_RIGHT - PLAYER_CAR_WIDTH / 2.0)
	
	# Smooth interpolation
	player_x = lerp(player_x, player_target_x, 10.0 * delta)
	player_car.position.x = player_x
	
	# Update invulnerability timer
	if player_invuln_timer > 0:
		player_invuln_timer -= delta
		# Flash effect
		player_car.modulate.a = 0.5 if fmod(player_invuln_timer, 0.15) < 0.075 else 1.0
	else:
		player_car.modulate.a = 1.0
	
	# Scroll road visuals
	_update_road_scroll(delta)
	
	# Spawn obstacles
	obstacle_timer -= delta
	if obstacle_timer <= 0:
		_spawn_obstacle()
		obstacle_timer = lerp(1.5, 0.5, difficulty_ramp) + randf() * 0.5
	
	# Spawn enemies
	enemy_timer -= delta
	if enemy_timer <= 0:
		_spawn_enemy()
		enemy_timer = lerp(4.0, 1.5, difficulty_ramp) + randf() * 1.0
	
	# Spawn collectibles
	collectible_timer -= delta
	if collectible_timer <= 0:
		_spawn_collectible()
		collectible_timer = 5.0 + randf() * 5.0
	
	# Update obstacles (scroll down)
	_update_obstacles(delta)
	
	# Update enemies (scroll + AI)
	_update_enemies(delta)
	
	# Update collectibles (scroll)
	_update_collectibles(delta)
	
	# Update HUD
	_update_hud()
	
	# Check win condition
	if chase_distance >= CHASE_DISTANCE_TOTAL:
		_chase_success()

# ===== ROAD BUILDING & SCROLLING =====

func _build_road() -> void:
	road_container = Node2D.new()
	road_container.name = "RoadContainer"
	add_child(road_container)
	
	# Road background (dark asphalt)
	road_bg = Polygon2D.new()
	road_bg.name = "RoadBG"
	road_bg.polygon = PackedVector2Array([
		Vector2(ROAD_LEFT, -100), Vector2(ROAD_RIGHT, -100),
		Vector2(ROAD_RIGHT, 700), Vector2(ROAD_LEFT, 700)
	])
	road_bg.color = Color(0.18, 0.18, 0.22, 1.0)
	road_bg.z_index = -5
	road_container.add_child(road_bg)
	
	# Sidewalks
	var sidewalk_left := Polygon2D.new()
	sidewalk_left.polygon = PackedVector2Array([
		Vector2(ROAD_LEFT - 40, -100), Vector2(ROAD_LEFT, -100),
		Vector2(ROAD_LEFT, 700), Vector2(ROAD_LEFT - 40, 700)
	])
	sidewalk_left.color = Color(0.35, 0.35, 0.35, 1.0)
	sidewalk_left.z_index = -4
	road_container.add_child(sidewalk_left)
	
	var sidewalk_right := Polygon2D.new()
	sidewalk_right.polygon = PackedVector2Array([
		Vector2(ROAD_RIGHT, -100), Vector2(ROAD_RIGHT + 40, -100),
		Vector2(ROAD_RIGHT + 40, 700), Vector2(ROAD_RIGHT, 700)
	])
	sidewalk_right.color = Color(0.35, 0.35, 0.35, 1.0)
	sidewalk_right.z_index = -4
	road_container.add_child(sidewalk_right)
	
	# Buildings (left side)
	for i in range(8):
		var building := Polygon2D.new()
		var bw := 30.0 + randf() * 20.0
		var bh := 80.0 + randf() * 60.0
		building.polygon = PackedVector2Array([
			Vector2(-bw, 0), Vector2(0, 0),
			Vector2(0, bh), Vector2(-bw, bh)
		])
		building.position = Vector2(ROAD_LEFT - 45, i * 100.0 - 50.0)
		building.color = Color(0.15 + randf() * 0.1, 0.15 + randf() * 0.08, 0.2 + randf() * 0.1, 1.0)
		building.z_index = -3
		road_container.add_child(building)
	
	# Buildings (right side)
	for i in range(8):
		var building := Polygon2D.new()
		var bw := 30.0 + randf() * 20.0
		var bh := 80.0 + randf() * 60.0
		building.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(bw, 0),
			Vector2(bw, bh), Vector2(0, bh)
		])
		building.position = Vector2(ROAD_RIGHT + 45, i * 100.0 - 50.0)
		building.color = Color(0.15 + randf() * 0.1, 0.15 + randf() * 0.08, 0.2 + randf() * 0.1, 1.0)
		building.z_index = -3
		road_container.add_child(building)
	
	# Road stripes (dashed center line)
	road_stripes = Node2D.new()
	road_stripes.name = "RoadStripes"
	road_stripes.z_index = -2
	road_container.add_child(road_stripes)
	
	# Create stripe segments
	for i in range(15):
		var stripe := Polygon2D.new()
		stripe.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0),
			Vector2(3, 25), Vector2(-3, 25)
		])
		stripe.position = Vector2(ROAD_CENTER_X, i * 50.0 - 25.0)
		stripe.color = Color(0.9, 0.85, 0.3, 0.6)  # Yellow dashed line
		road_stripes.add_child(stripe)

func _update_road_scroll(delta: float) -> void:
	road_stripe_offset += scroll_speed * delta
	
	# Wrap stripe offset
	if road_stripe_offset >= 50.0:
		road_stripe_offset -= 50.0
	
	# Update stripe positions
	if road_stripes:
		var stripe_index := 0
		for child in road_stripes.get_children():
			if child is Polygon2D:
				child.position.y = (stripe_index * 50.0 - 25.0 + road_stripe_offset)
				# Wrap around
				if child.position.y > 700:
					child.position.y -= 750
				stripe_index += 1

# ===== PLAYER CAR =====

func _build_player_car() -> void:
	player_car = Area2D.new()
	player_car.name = "PlayerCar"
	player_car.position = Vector2(ROAD_CENTER_X, 450)
	add_child(player_car)
	
	# Collision shape
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(PLAYER_CAR_WIDTH, PLAYER_CAR_HEIGHT)
	collision.shape = shape
	player_car.add_child(collision)
	
	# Car body (red)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-18, -28), Vector2(18, -28),
		Vector2(20, -10), Vector2(20, 25),
		Vector2(18, 28), Vector2(-18, 28),
		Vector2(-20, 25), Vector2(-20, -10)
	])
	body.color = Color(0.85, 0.12, 0.12, 1.0)  # Red car
	player_car.add_child(body)
	
	# Windshield
	var windshield := Polygon2D.new()
	windshield.polygon = PackedVector2Array([
		Vector2(-14, -18), Vector2(14, -18),
		Vector2(12, -8), Vector2(-12, -8)
	])
	windshield.color = Color(0.4, 0.6, 0.8, 0.7)  # Blue glass
	player_car.add_child(windshield)
	
	# Rear window
	var rear := Polygon2D.new()
	rear.polygon = PackedVector2Array([
		Vector2(-12, 10), Vector2(12, 10),
		Vector2(14, 20), Vector2(-14, 20)
	])
	rear.color = Color(0.4, 0.6, 0.8, 0.5)
	player_car.add_child(rear)
	
	# Headlights
	var hl_left := Polygon2D.new()
	hl_left.polygon = PackedVector2Array([
		Vector2(-16, -28), Vector2(-10, -28),
		Vector2(-10, -24), Vector2(-16, -24)
	])
	hl_left.color = Color(1.0, 1.0, 0.7, 1.0)
	player_car.add_child(hl_left)
	
	var hl_right := Polygon2D.new()
	hl_right.polygon = PackedVector2Array([
		Vector2(10, -28), Vector2(16, -28),
		Vector2(16, -24), Vector2(10, -24)
	])
	hl_right.color = Color(1.0, 1.0, 0.7, 1.0)
	player_car.add_child(hl_right)
	
	# Tail lights
	var tl_left := Polygon2D.new()
	tl_left.polygon = PackedVector2Array([
		Vector2(-18, 25), Vector2(-12, 25),
		Vector2(-12, 28), Vector2(-18, 28)
	])
	tl_left.color = Color(1.0, 0.2, 0.1, 1.0)
	player_car.add_child(tl_left)
	
	var tl_right := Polygon2D.new()
	tl_right.polygon = PackedVector2Array([
		Vector2(12, 25), Vector2(18, 25),
		Vector2(18, 28), Vector2(12, 28)
	])
	tl_right.color = Color(1.0, 0.2, 0.1, 1.0)
	player_car.add_child(tl_right)
	
	# Connect collision
	player_car.area_entered.connect(_on_player_area_entered)

# ===== OBSTACLES =====

func _spawn_obstacle() -> void:
	var obstacle := Area2D.new()
	obstacle.name = "Obstacle"
	obstacle.add_to_group("obstacle")
	
	# Random type
	var obs_type := randi() % 3  # 0=barrier, 1=car, 2=construction
	var color: Color
	var width: float
	var height: float
	
	match obs_type:
		0:  # Traffic barrier
			color = Color(0.9, 0.6, 0.1, 1.0)  # Orange
			width = OBSTACLE_WIDTH
			height = OBSTACLE_HEIGHT
		1:  # Parked car
			color = Color(0.3 + randf() * 0.4, 0.3 + randf() * 0.3, 0.3 + randf() * 0.4, 1.0)
			width = ENEMY_CAR_WIDTH
			height = ENEMY_CAR_HEIGHT
		2:  # Construction cone cluster
			color = Color(0.9, 0.4, 0.1, 1.0)
			width = 35.0
			height = 25.0
		_:
			color = Color.GRAY
			width = OBSTACLE_WIDTH
			height = OBSTACLE_HEIGHT
	
	# Random lane position
	var lane_count := 3
	var lane_width := ROAD_WIDTH / lane_count
	var lane := randi() % lane_count
	var x_pos := ROAD_LEFT + lane_width * lane + lane_width / 2.0
	
	obstacle.position = Vector2(x_pos, -80.0)
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	obstacle.add_child(collision)
	
	# Visual
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-width/2, -height/2), Vector2(width/2, -height/2),
		Vector2(width/2, height/2), Vector2(-width/2, height/2)
	])
	visual.color = color
	obstacle.add_child(visual)
	
	# If it's a parked car, add detail
	if obs_type == 1:
		var windshield := Polygon2D.new()
		windshield.polygon = PackedVector2Array([
			Vector2(-12, -height/2 + 5), Vector2(12, -height/2 + 5),
			Vector2(10, -height/2 + 15), Vector2(-10, -height/2 + 15)
		])
		windshield.color = Color(0.4, 0.6, 0.8, 0.5)
		obstacle.add_child(windshield)
	
	obstacle_container.add_child(obstacle)

func _update_obstacles(delta: float) -> void:
	var to_remove: Array[Area2D] = []
	
	for child in obstacle_container.get_children():
		if child is Area2D:
			child.position.y += scroll_speed * delta
			if child.position.y > 700:
				to_remove.append(child)
	
	for obs in to_remove:
		obs.queue_free()

# ===== ENEMY VEHICLES =====

func _spawn_enemy() -> void:
	var enemy := Area2D.new()
	enemy.name = "EnemyVehicle"
	enemy.add_to_group("enemy_vehicle")
	
	# Random type: 0=police, 1=goon car
	var enemy_type := randi() % 2
	var color: Color
	var label_text: String
	
	match enemy_type:
		0:  # Police car
			color = Color(0.15, 0.15, 0.7, 1.0)  # Dark blue
			label_text = "POLICE"
		1:  # Goon car
			color = Color(0.25, 0.25, 0.25, 1.0)  # Dark gray
			label_text = "STERLING"
	
	# Spawn from sides or top
	var spawn_side := randi() % 3  # 0=left, 1=right, 2=top
	var x_pos: float
	var y_pos: float
	
	match spawn_side:
		0:  # Left side
			x_pos = ROAD_LEFT + 30.0
			y_pos = 300.0 + randf() * 100.0
		1:  # Right side
			x_pos = ROAD_RIGHT - 30.0
			y_pos = 300.0 + randf() * 100.0
		2:  # Top
			x_pos = ROAD_LEFT + randf() * ROAD_WIDTH
			y_pos = -80.0
	
	enemy.position = Vector2(x_pos, y_pos)
	
	# Store enemy data
	enemy.set_meta("enemy_type", enemy_type)
	enemy.set_meta("lateral_speed", 60.0 + randf() * 40.0)
	enemy.set_meta("chase_speed", scroll_speed * (0.7 + randf() * 0.3))
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(ENEMY_CAR_WIDTH, ENEMY_CAR_HEIGHT)
	collision.shape = shape
	enemy.add_child(collision)
	
	# Car body
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-18, -28), Vector2(18, -28),
		Vector2(20, -10), Vector2(20, 25),
		Vector2(18, 28), Vector2(-18, 28),
		Vector2(-20, 25), Vector2(-20, -10)
	])
	body.color = color
	enemy.add_child(body)
	
	# Windshield
	var windshield := Polygon2D.new()
	windshield.polygon = PackedVector2Array([
		Vector2(-14, -18), Vector2(14, -18),
		Vector2(12, -8), Vector2(-12, -8)
	])
	windshield.color = Color(0.4, 0.6, 0.8, 0.5)
	enemy.add_child(windshield)
	
	# Police lights
	if enemy_type == 0:
		var light_left := Polygon2D.new()
		light_left.polygon = PackedVector2Array([
			Vector2(-16, -26), Vector2(-8, -26),
			Vector2(-8, -22), Vector2(-16, -22)
		])
		light_left.color = Color(0.2, 0.2, 1.0, 1.0) if randf() > 0.5 else Color(1.0, 0.1, 0.1, 1.0)
		enemy.add_child(light_left)
		
		var light_right := Polygon2D.new()
		light_right.polygon = PackedVector2Array([
			Vector2(8, -26), Vector2(16, -26),
			Vector2(16, -22), Vector2(8, -22)
		])
		light_right.color = Color(1.0, 0.1, 0.1, 1.0) if light_left.color.b > 0.5 else Color(0.2, 0.2, 1.0, 1.0)
		enemy.add_child(light_right)
	
	# Label
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-25, -40)
	label.add_theme_font_size_override("font_size", 10)
	enemy.add_child(label)
	
	enemy_container.add_child(enemy)

func _update_enemies(delta: float) -> void:
	var to_remove: Array[Area2D] = []
	
	for child in enemy_container.get_children():
		if child is Area2D and child.is_in_group("enemy_vehicle"):
			# Chase AI: move toward player X, scroll with road
			var lateral_speed: float = child.get_meta("lateral_speed", 60.0)
			var chase_speed: float = child.get_meta("chase_speed", scroll_speed * 0.8)
			
			# Move toward player's X position
			var x_diff := player_x - child.position.x
			if abs(x_diff) > 5.0:
				child.position.x += sign(x_diff) * lateral_speed * delta
			
			# Clamp to road
			child.position.x = clamp(child.position.x, ROAD_LEFT + 25.0, ROAD_RIGHT - 25.0)
			
			# Scroll (enemies chase from behind, so they move slower than scroll)
			child.position.y += chase_speed * delta
			
			# Remove if off screen
			if child.position.y > 700 or child.position.y < -200:
				to_remove.append(child)
	
	for enemy in to_remove:
		enemy.queue_free()

# ===== COLLECTIBLES =====

func _spawn_collectible() -> void:
	var collectible := Area2D.new()
	collectible.add_to_group("chase_collectible")
	
	# Random type
	var c_type := randi() % 3  # 0=health, 1=polaroid (rare), 2=trinket (rare)
	var color: Color
	var size: float
	var c_name: String
	
	match c_type:
		0:  # Health pickup
			color = Color(0.2, 0.9, 0.3, 1.0)  # Green
			size = 14.0
			c_name = "HealthPickup"
		1:  # Polaroid (only if not collected, 20% chance)
			if polaroid_collected or randf() > 0.2:
				# Fallback to health
				color = Color(0.2, 0.9, 0.3, 1.0)
				size = 14.0
				c_name = "HealthPickup"
			else:
				color = Color(0.95, 0.95, 0.9, 1.0)  # White
				size = 16.0
				c_name = "Polaroid"
		2:  # Trinket (only if not collected, 15% chance)
			if trinket_collected or randf() > 0.15:
				# Fallback to health
				color = Color(0.2, 0.9, 0.3, 1.0)
				size = 14.0
				c_name = "HealthPickup"
			else:
				color = Color(1.0, 0.84, 0.0, 1.0)  # Gold
				size = 12.0
				c_name = "Trinket"
	
	collectible.name = c_name
	collectible.set_meta("collectible_type", c_name)
	
	# Random lane position
	var x_pos := ROAD_LEFT + 30.0 + randf() * (ROAD_WIDTH - 60.0)
	collectible.position = Vector2(x_pos, -50.0)
	
	# Collision
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = size
	collision.shape = shape
	collectible.add_child(collision)
	
	# Visual
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size, -size), Vector2(size, -size),
		Vector2(size, size), Vector2(-size, size)
	])
	visual.color = color
	collectible.add_child(visual)
	
	# Glow effect
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-size - 4, -size - 4), Vector2(size + 4, -size - 4),
		Vector2(size + 4, size + 4), Vector2(-size - 4, size + 4)
	])
	glow.color = Color(color.r, color.g, color.b, 0.3)
	collectible.add_child(glow)
	
	collectible_container.add_child(collectible)

func _update_collectibles(delta: float) -> void:
	var to_remove: Array[Area2D] = []
	
	for child in collectible_container.get_children():
		if child is Area2D:
			child.position.y += scroll_speed * delta
			# Rotate for visual flair
			child.rotation += 2.0 * delta
			if child.position.y > 700:
				to_remove.append(child)
	
	for col in to_remove:
		col.queue_free()

# ===== COLLISION HANDLING =====

func _on_player_area_entered(area: Area2D) -> void:
	if not is_alive or player_invuln_timer > 0:
		return
	
	if area.is_in_group("obstacle"):
		_take_damage(CRASH_DAMAGE)
		area.queue_free()
		# Knockback visual
		player_car.position.y += 10.0
		# Banter
		_random_banter()
	
	elif area.is_in_group("enemy_vehicle"):
		_take_damage(CRASH_DAMAGE + 5)
		# Push enemy away
		area.position.x += sign(area.position.x - player_x) * 50.0
		_random_banter()
	
	elif area.is_in_group("chase_collectible"):
		_collect_item(area)

func _take_damage(amount: int) -> void:
	player_health = max(0, player_health - amount)
	player_invuln_timer = INVULN_TIME
	
	# Flash damage
	if damage_flash:
		damage_flash.visible = true
		damage_flash.color = Color(1.0, 0.0, 0.0, 0.3)
		await get_tree().create_timer(0.15).timeout
		if damage_flash:
			damage_flash.visible = false
	
	# Update HUD
	if health_bar:
		health_bar.value = player_health
	
	EventBus.debug("Player hit! Health: " + str(player_health))
	
	# Check death
	if player_health <= 0:
		_chase_failed()

func _collect_item(area: Area2D) -> void:
	var c_type: String = area.get_meta("collectible_type", "HealthPickup")
	
	match c_type:
		"HealthPickup":
			player_health = min(player_max_health, player_health + 15)
			if health_bar:
				health_bar.value = player_health
			EventBus.debug("Health pickup! +15 HP")
		"Polaroid":
			polaroid_collected = true
			GameState.add_polaroid(REWARD_POLAROID)
			EventBus.debug("Polaroid collected: Car Chase!")
		"Trinket":
			trinket_collected = true
			GameState.add_trinket(REWARD_TRINKET)
			EventBus.debug("Trinket collected: Dom's Wrench!")
	
	area.queue_free()

func _random_banter() -> void:
	if randf() < 0.4:  # 40% chance of banter on hit
		var line = DOM_CHASE_BANTER[randi() % DOM_CHASE_BANTER.size()]
		EventBus.dialogue_started.emit("Dom", line)
		await get_tree().create_timer(1.5).timeout
		EventBus.dialogue_ended.emit()

# ===== CHASE END =====

func _chase_success() -> void:
	current_phase = MissionPhase.CHASE_SUCCESS
	is_alive = false
	
	# Stop scrolling
	scroll_speed = 0.0
	
	# Show safehouse visual
	_show_safehouse_visual()
	
	# Dom success dialogue
	for line in DOM_SUCCESS_LINES:
		EventBus.dialogue_started.emit("Dom", line)
		await get_tree().create_timer(2.0).timeout
	EventBus.dialogue_ended.emit()
	
	# Complete the mission
	_complete_mission()

func _chase_failed() -> void:
	is_alive = false
	current_phase = MissionPhase.COMPLETE
	
	EventBus.debug("Car chase failed - car destroyed!")
	GameState.fail_mission(MISSION_ID)
	
	var partial_progress := chase_distance / CHASE_DISTANCE_TOTAL
	EventBus.show_failure_screen.emit("Your car was wrecked! Dom barely escaped.", partial_progress)
	
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

func _show_safehouse_visual() -> void:
	# Safehouse door at top
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(ROAD_CENTER_X - 60, -20), Vector2(ROAD_CENTER_X + 60, -20),
		Vector2(ROAD_CENTER_X + 60, 60), Vector2(ROAD_CENTER_X - 60, 60)
	])
	door.color = Color(0.4, 0.35, 0.3, 1.0)
	door.z_index = 10
	add_child(door)
	
	# Safehouse label
	var label := Label.new()
	label.text = "SAFEHOUSE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(ROAD_CENTER_X - 40, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.z_index = 11
	add_child(label)
	
	# Green glow
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(ROAD_CENTER_X - 80, -30), Vector2(ROAD_CENTER_X + 80, -30),
		Vector2(ROAD_CENTER_X + 80, 70), Vector2(ROAD_CENTER_X - 80, 70)
	])
	glow.color = Color(0.2, 0.8, 0.3, 0.3)
	glow.z_index = 9
	add_child(glow)

# ===== MISSION COMPLETION =====

func _complete_mission() -> void:
	current_phase = MissionPhase.COMPLETE
	
	EventBus.debug("Fast Family Getaway completed!")
	
	# Complete mission in GameState
	GameState.complete_mission(MISSION_ID)
	
	# Unlock reward card
	if REWARD_CARD != "":
		GameState.unlock_card(REWARD_CARD)
		EventBus.debug("Unlocked card: " + REWARD_CARD)
	
	# Set friend helped
	GameState.set_friend_helped("dom", REWARD_CARD)
	EventBus.friend_helped.emit("dom")
	
	# Give intel reward
	var intel_reward := MissionData.get_intel_reward(MISSION_ID)
	if intel_reward > 0:
		GameState.add_intel_points(intel_reward)
	
	# Show mission result
	var rewards := {
		"card": REWARD_CARD,
		"polaroid": REWARD_POLAROID if polaroid_collected else "",
		"trinket": REWARD_TRINKET if trinket_collected else "",
		"intel": intel_reward
	}
	EventBus.show_mission_result.emit(true, rewards)
	
	# Save game
	SaveManager.auto_save()
	
	# Return to hideout after delay
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

# ===== HUD =====

func _build_hud() -> void:
	hud_container = CanvasLayer.new()
	hud_container.name = "HUD"
	hud_container.layer = 10
	add_child(hud_container)
	
	# Health bar
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(20, 20)
	health_bar.min_value = 0
	health_bar.max_value = player_max_health
	health_bar.value = player_health
	health_bar.custom_minimum_size = Vector2(150, 20)
	health_bar.show_percentage = false
	hud_container.add_child(health_bar)
	
	# Health label
	var health_label := Label.new()
	health_label.text = "CAR HEALTH"
	health_label.position = Vector2(20, 4)
	health_label.add_theme_font_size_override("font_size", 12)
	hud_container.add_child(health_label)
	
	# Distance bar
	distance_bar = ProgressBar.new()
	distance_bar.position = Vector2(20, 55)
	distance_bar.min_value = 0
	distance_bar.max_value = 100
	distance_bar.value = 0
	distance_bar.custom_minimum_size = Vector2(150, 15)
	distance_bar.show_percentage = false
	hud_container.add_child(distance_bar)
	
	# Distance label
	var dist_label := Label.new()
	dist_label.text = "DISTANCE TO SAFEHOUSE"
	dist_label.position = Vector2(20, 39)
	dist_label.add_theme_font_size_override("font_size", 10)
	hud_container.add_child(dist_label)
	
	# Speed label
	speed_label = Label.new()
	speed_label.text = "SPEED: 0"
	speed_label.position = Vector2(620, 20)
	speed_label.add_theme_font_size_override("font_size", 14)
	hud_container.add_child(speed_label)
	
	# Objective label
	objective_label = Label.new()
	objective_label.text = "LISTEN TO DOM"
	objective_label.position = Vector2(280, 5)
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_container.add_child(objective_label)
	
	# Card indicator
	if has_getaway_keys:
		var card_label := Label.new()
		card_label.text = "[Dom's Getaway Keys - Speed Boost!]"
		card_label.position = Vector2(560, 55)
		card_label.add_theme_font_size_override("font_size", 11)
		card_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		hud_container.add_child(card_label)
	
	# Damage flash overlay
	damage_flash = ColorRect.new()
	damage_flash.color = Color(1.0, 0.0, 0.0, 0.0)
	damage_flash.size = Vector2(800, 600)
	damage_flash.visible = false
	damage_flash.z_index = 100
	hud_container.add_child(damage_flash)
	
	# Controls hint
	var controls := Label.new()
	controls.text = "A/D or Arrow Keys: Dodge Left/Right"
	controls.position = Vector2(250, 575)
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	hud_container.add_child(controls)

func _update_hud() -> void:
	if health_bar:
		health_bar.value = player_health
	
	if distance_bar:
		distance_bar.value = (chase_distance / CHASE_DISTANCE_TOTAL) * 100.0
	
	if speed_label:
		speed_label.text = "SPEED: " + str(int(scroll_speed))
	
	if objective_label:
		var pct := int((chase_distance / CHASE_DISTANCE_TOTAL) * 100.0)
		objective_label.text = "ESCAPE - " + str(pct) + "%"

# ===== CAMERA =====

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(ROAD_CENTER_X, 300)
	camera.zoom = Vector2(1.0, 1.0)
	camera.make_current()
	add_child(camera)

# ===== CLEANUP =====

func cleanup() -> void:
	EventBus.debug("Car Chase Mission cleanup")
	EventBus.show_objective_marker.emit(false, Vector2.ZERO)
