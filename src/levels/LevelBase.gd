# LevelBase.gd
# Base class for all levels with common functionality

extends Node2D

# References
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var camera: Camera2D = $Camera2D
@onready var exit_zone: Area2D = $ExitZone

# Level state
var player: Node2D = null
var dog: Node2D = null
var is_complete: bool = false

func _ready() -> void:
	EventBus.debug("Level loaded: " + name)
	
	# Spawn player
	_spawn_player()
	
	# Spawn dog
	_spawn_dog()
	
	# Spawn enemies
	_spawn_enemies()
	
	# Setup camera
	_setup_camera()
	
	# Connect signals
	exit_zone.body_entered.connect(_on_exit_zone_body_entered)
	
	# Start mission
	var mission_id = _get_mission_id()
	GameState.start_mission(mission_id)
	EventBus.show_objective_marker.emit(true, exit_zone.global_position)

# Spawn player at spawn point
func _spawn_player() -> void:
	var player_scene := preload("res://scenes/characters/player.tscn")
	player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	player.add_to_group("player")
	add_child(player)
	
	# Make camera follow player
	if camera:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.make_current()

# Spawn dog companion
func _spawn_dog() -> void:
	var dog_scene := preload("res://scenes/characters/dog.tscn")
	dog = dog_scene.instantiate()
	dog.global_position = player_spawn.global_position + Vector2(50, 0)
	add_child(dog)

# Spawn enemies (override in specific levels)
func _spawn_enemies() -> void:
	# This is a base implementation - specific levels should override
	pass

# Setup camera
func _setup_camera() -> void:
	if camera and player:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.make_current()

# Complete the level
func complete_level() -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("Level completed: " + name)
	
	# Complete mission
	var mission_id = GameState.current_mission
	if mission_id != "":
		GameState.complete_mission(mission_id)
	GameState.end_mission()
	
	# Save game
	SaveManager.auto_save()
	
	# Show completion message
	EventBus.debug("Heist completed successfully!")
	
	# Return to hideout after delay
	await get_tree().create_timer(2.0).timeout
	SceneManager.change_to_scene("hideout")

# Exit zone handler
func _on_exit_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_complete:
		complete_level()

# Get mission ID for this level (override in subclasses)
func _get_mission_id() -> String:
	# Default: derive from scene name or use "tutorial"
	return "tutorial"

# Clean up level
func cleanup() -> void:
	EventBus.debug("Cleaning up level: " + name)
	
	# Disconnect signals
	if exit_zone and exit_zone.body_entered.is_connected(_on_exit_zone_body_entered):
		exit_zone.body_entered.disconnect(_on_exit_zone_body_entered)
	
	# Hide objective marker
	EventBus.show_objective_marker.emit(false, Vector2.ZERO)

# Get player position
func get_player_position() -> Vector2:
	if player:
		return player.global_position
	return Vector2.ZERO

# Get all enemies in level
func get_enemies() -> Array:
	return get_tree().get_nodes_in_group("enemy")