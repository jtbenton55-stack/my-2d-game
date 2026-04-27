# TacoBellMission.gd
# Mission 1: The Taco Bell Drop
# Help Louis recover his delivery bag from goons in the alley

extends LevelBase

# Mission state
enum MissionPhase {
	START,
	LOUIS_DIALOGUE,
	FIND_BAG,
	HAS_BAG,
	ESCAPE,
	COMPLETE
}
var current_phase: MissionPhase = MissionPhase.START

# Mission data
const MISSION_ID: String = "taco_bell_drop"
const REWARD_CARD: String = "louis_delivery_route"
const REWARD_POLAROID: String = "taco_bell"
const REWARD_TRINKET: String = "louis_keychain"

# Spawn points
@onready var louis_spawn: Marker2D = $LouisSpawn
@onready var bag_spawn: Marker2D = $BagSpawn
@onready var goon_spawns: Node = $GoonSpawns
@onready var collectible_spawns: Node = $CollectibleSpawns
@onready var sniff_trail: Line2D = $SniffTrail
@onready var bag_pickup_zone: Area2D = $BagPickupZone

# NPC and interactables
var louis_npc: Area2D = null
var bag_collected: bool = false
var polaroid_collected: bool = false
var trinket_collected: bool = false

# Dialogue lines
const LOUIS_INTRO_LINES: Array[String] = [
	"Hey! You gotta help me!",
	"Those goons jumped me and stole my delivery bag!",
	"It's got tonight's orders and my keys in it.",
	"Bentley can sniff it out - he's got a nose for tacos!"
]

const LOUIS_OUTRO_LINES: Array[String] = [
	"You found it! You're a lifesaver!",
	"Here, take this - my delivery route card.",
	"It'll help you get around Nocturn City fast.",
	"Come by Taco Bell anytime, friend!"
]

func _ready() -> void:
	# Don't call super._ready() yet - we need to set up mission-specific things first
	EventBus.debug("Taco Bell Drop mission loaded")
	
	# Start the mission in GameState
	GameState.start_mission(MISSION_ID)
	
	# Setup sniff trail (hidden initially)
	if sniff_trail:
		sniff_trail.visible = false
	
	# Setup bag pickup zone
	if bag_pickup_zone:
		bag_pickup_zone.body_entered.connect(_on_bag_zone_body_entered)
	
	# Now spawn player, dog, enemies via base class
	_spawn_player()
	_spawn_dog()
	_spawn_enemies()
	_setup_camera()
	
	# Spawn Louis NPC
	_spawn_louis()
	
	# Spawn collectibles
	_spawn_collectibles()
	
	# Connect exit zone
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_zone_body_entered)
	
	# Show initial objective
	EventBus.show_objective_marker.emit(true, louis_spawn.global_position)
	
	# Start with Louis dialogue after brief delay
	await get_tree().create_timer(0.5).timeout
	_start_louis_intro_dialogue()

# Spawn Louis NPC
func _spawn_louis() -> void:
	louis_npc = Area2D.new()
	louis_npc.name = "LouisNPC"
	louis_npc.global_position = louis_spawn.global_position
	louis_npc.add_to_group("npc")
	louis_npc.add_to_group("louis")
	
	# Collision shape for interaction
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	collision.shape = shape
	louis_npc.add_child(collision)
	
	# Visual - placeholder colored rectangle
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-16, -32), Vector2(16, -32),
		Vector2(16, 0), Vector2(-16, 0)
	])
	sprite.color = Color(0.2, 0.6, 1.0, 1.0)  # Blue for Louis
	louis_npc.add_child(sprite)
	
	# Name label
	var label := Label.new()
	label.text = "Louis"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -48)
	label.add_theme_font_size_override("font_size", 12)
	louis_npc.add_child(label)
	
	add_child(louis_npc)
	EventBus.debug("Louis spawned at " + str(louis_spawn.global_position))

# Spawn goons
func _spawn_enemies() -> void:
	if not goon_spawns:
		return
	
	var goon_scene := preload("res://scenes/characters/goon.tscn")
	var spawn_index := 0
	
	for spawn in goon_spawns.get_children():
		if spawn is Marker2D:
			var goon = goon_scene.instantiate()
			goon.global_position = spawn.global_position
			goon.name = "Goon_" + str(spawn_index)
			add_child(goon)
			spawn_index += 1
			EventBus.debug("Goon spawned at " + str(spawn.global_position))

# Spawn collectibles
func _spawn_collectibles() -> void:
	if not collectible_spawns:
		return
	
	var spawn_index := 0
	for spawn in collectible_spawns.get_children():
		if spawn is Marker2D:
			if spawn_index == 0:
				_spawn_polaroid(spawn.global_position)
			elif spawn_index == 1:
				_spawn_trinket(spawn.global_position)
			spawn_index += 1

func _spawn_polaroid(pos: Vector2) -> void:
	var polaroid := Area2D.new()
	polaroid.name = "Polaroid_TacoBell"
	polaroid.global_position = pos
	polaroid.add_to_group("collectible")
	polaroid.add_to_group("polaroid")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	polaroid.add_child(collision)
	
	# Visual - white rectangle (polaroid)
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16),
		Vector2(12, 16), Vector2(-12, 16)
	])
	sprite.color = Color(0.95, 0.95, 0.95, 1.0)
	polaroid.add_child(sprite)
	
	# Border
	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16),
		Vector2(12, 16), Vector2(-12, 16),
		Vector2(-12, -16)
	])
	border.width = 2
	border.default_color = Color(0.3, 0.3, 0.3, 1.0)
	polaroid.add_child(border)
	
	polaroid.body_entered.connect(_on_polaroid_body_entered)
	add_child(polaroid)

func _spawn_trinket(pos: Vector2) -> void:
	var trinket := Area2D.new()
	trinket.name = "Trinket_Keychain"
	trinket.global_position = pos
	trinket.add_to_group("collectible")
	trinket.add_to_group("trinket")
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	trinket.add_child(collision)
	
	# Visual - small gold circle (keychain)
	var sprite := Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 8), Vector2(-8, 8)
	])
	sprite.color = Color(1.0, 0.84, 0.0, 1.0)  # Gold
	trinket.add_child(sprite)
	
	trinket.body_entered.connect(_on_trinket_body_entered)
	add_child(trinket)

# Dialogue
func _start_louis_intro_dialogue() -> void:
	current_phase = MissionPhase.LOUIS_DIALOGUE
	
	for line in LOUIS_INTRO_LINES:
		EventBus.dialogue_started.emit("Louis", line)
		await get_tree().create_timer(2.0).timeout
	
	EventBus.dialogue_ended.emit()
	_start_find_bag_phase()

func _start_louis_outro_dialogue() -> void:
	current_phase = MissionPhase.COMPLETE
	
	for line in LOUIS_OUTRO_LINES:
		EventBus.dialogue_started.emit("Louis", line)
		await get_tree().create_timer(2.0).timeout
	
	EventBus.dialogue_ended.emit()
	complete_level()

# Phase transitions
func _start_find_bag_phase() -> void:
	current_phase = MissionPhase.FIND_BAG
	EventBus.debug("Phase: FIND_BAG")
	EventBus.quest_started.emit(MISSION_ID, "Follow Bentley's sniff trail to find Louis's bag")
	
	# Show sniff trail
	if sniff_trail:
		sniff_trail.visible = true
	
	# Update objective marker to bag location
	EventBus.show_objective_marker.emit(true, bag_spawn.global_position)

func _on_bag_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and current_phase == MissionPhase.FIND_BAG:
		_bag_found()

func _bag_found() -> void:
	bag_collected = true
	current_phase = MissionPhase.HAS_BAG
	EventBus.debug("Bag collected!")
	EventBus.objective_completed.emit("find_bag")
	EventBus.quest_updated.emit("Escape with the bag!")
	
	# Hide bag pickup zone
	if bag_pickup_zone:
		bag_pickup_zone.monitoring = false
	
	# Update objective marker to exit
	if exit_zone:
		EventBus.show_objective_marker.emit(true, exit_zone.global_position)
	
	# Show bag collected feedback
	EventBus.debug("You got Louis's delivery bag!")

# Collectible handlers
func _on_polaroid_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not polaroid_collected:
		polaroid_collected = true
		GameState.add_polaroid(REWARD_POLAROID)
		EventBus.debug("Polaroid collected: Taco Bell")
		# Remove from scene
		var polaroid = get_node_or_null("Polaroid_TacoBell")
		if polaroid:
			polaroid.queue_free()

func _on_trinket_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not trinket_collected:
		trinket_collected = true
		GameState.add_trinket(REWARD_TRINKET)
		EventBus.debug("Trinket collected: Louis's Keychain")
		# Remove from scene
		var trinket = get_node_or_null("Trinket_Keychain")
		if trinket:
			trinket.queue_free()

# Exit zone override
func _on_exit_zone_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	if current_phase == MissionPhase.HAS_BAG:
		# Success - has bag, escaping
		_start_louis_outro_dialogue()
	elif current_phase == MissionPhase.FIND_BAG:
		# Trying to leave without bag
		EventBus.dialogue_started.emit("Louis", "Wait! You can't leave without my bag!")
		await get_tree().create_timer(2.0).timeout
		EventBus.dialogue_ended.emit()

# Override completion for mission rewards
func complete_level() -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("Taco Bell Drop completed!")
	
	# Complete mission in GameState
	GameState.complete_mission(MISSION_ID)
	
	# Unlock reward card
	if REWARD_CARD != "":
		GameState.unlock_card(REWARD_CARD)
		EventBus.debug("Unlocked card: " + REWARD_CARD)
	
	# Set friend helped
	GameState.set_friend_helped("louis", REWARD_CARD)
	EventBus.friend_helped.emit("louis")
	
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

# Mission failure (player died)
func fail_mission() -> void:
	EventBus.debug("Taco Bell Drop failed")
	GameState.fail_mission(MISSION_ID)
	
	var partial_progress := 0.0
	if bag_collected:
		partial_progress = 0.5
	elif polaroid_collected or trinket_collected:
		partial_progress = 0.25
	
	EventBus.show_failure_screen.emit("Mission Failed - You were caught!", partial_progress)
	
	await get_tree().create_timer(3.0).timeout
	SceneManager.change_to_scene("hideout")

# Cleanup override
func cleanup() -> void:
	super.cleanup()
	EventBus.debug("Taco Bell Drop cleanup complete")
