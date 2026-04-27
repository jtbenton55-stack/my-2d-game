# StealthSystem.gd
# Handles stealth mechanics: vision cones, detection meter, noise, cover

extends Node

# Noise levels
enum NoiseLevel {
	SILENT = 0,
	WALK = 1,
	RUN = 2,
	ATTACK = 3,
	LOUD = 4
}

# References
var player: Node2D = null
var enemies: Array = []

# Noise propagation
var noise_sources: Array = []
@export var noise_decay_rate: float = 1.0  # Noise units per second

# Cover system
var cover_objects: Array = []

func _ready() -> void:
	EventBus.debug("StealthSystem loaded")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Find all enemies
	enemies = get_tree().get_nodes_in_group("enemy")
	
	# Connect signals
	EventBus.player_stealth_changed.connect(_on_player_stealth_changed)
	EventBus.damage_dealt.connect(_on_damage_dealt)

func _process(delta: float) -> void:
	# Update noise propagation
	_update_noise(delta)
	
	# Check cover
	_check_cover()

# Check if player is behind cover
func _check_cover() -> void:
	if not player:
		return
	
	var is_behind_cover := false
	
	# Simple raycast check (placeholder)
	# In a real implementation, this would use actual raycasting
	for enemy in enemies:
		if enemy.has_method("can_see_player"):
			var can_see: bool = enemy.can_see_player()
			if not can_see:
				is_behind_cover = true
				break
	
	# Update player visibility
	if is_behind_cover:
		EventBus.debug("Player is behind cover")
		# In a real game, this would make player semi-transparent or hidden

# Update noise propagation
func _update_noise(delta: float) -> void:
	# Decay existing noise
	for i in range(noise_sources.size() - 1, -1, -1):
		var noise: Dictionary = noise_sources[i]
		noise.strength -= noise_decay_rate * delta
		
		if noise.strength <= 0:
			noise_sources.remove_at(i)
			EventBus.debug("Noise source decayed at " + str(noise.position))
		else:
			# Propagate noise to enemies
			_propagate_noise_to_enemies(noise)

# Propagate noise to nearby enemies
func _propagate_noise_to_enemies(noise: Dictionary) -> void:
	for enemy in enemies:
		if enemy.global_position.distance_to(noise.position) <= noise.range:
			EventBus.debug("Enemy heard noise at " + str(noise.position))
			# In a real game, this would trigger enemy investigation

# Create a noise source
func create_noise(position: Vector2, level: NoiseLevel, source: Node = null) -> void:
	var noise_strength: float
	var noise_range: float
	
	match level:
		NoiseLevel.SILENT:
			noise_strength = 0.5
			noise_range = 50.0
		NoiseLevel.WALK:
			noise_strength = 1.0
			noise_range = 100.0
		NoiseLevel.RUN:
			noise_strength = 2.0
			noise_range = 200.0
		NoiseLevel.ATTACK:
			noise_strength = 3.0
			noise_range = 300.0
		NoiseLevel.LOUD:
			noise_strength = 5.0
			noise_range = 500.0
		_:
			noise_strength = 1.0
			noise_range = 100.0
	
	var noise := {
		"position": position,
		"strength": noise_strength,
		"range": noise_range,
		"source": source,
		"level": level
	}
	
	noise_sources.append(noise)
	EventBus.debug("Noise created at " + str(position) + " (level: " + str(level) + ")")

# Get noise level at a position
func get_noise_level_at(position: Vector2) -> float:
	var total_noise := 0.0
	
	for noise in noise_sources:
		var distance := position.distance_to(noise.position)
		if distance <= noise.range:
			# Inverse square law for noise propagation
			var distance_factor := 1.0 - (distance / noise.range)
			total_noise += noise.strength * distance_factor * distance_factor
	
	return total_noise

# Check if an enemy can see the player
func can_enemy_see_player(enemy: Node2D) -> bool:
	if not player or not enemy:
		return false
	
	# Check distance
	var distance := enemy.global_position.distance_to(player.global_position)
	if distance > 500.0:  # Max vision distance
		return false
	
	# Check line of sight (placeholder - would use raycasting)
	# For now, just check if player is in enemy's vision area
	if enemy.has_node("VisionArea"):
		var vision_area: Area2D = enemy.get_node("VisionArea")
		return vision_area.overlaps_body(player)
	
	return false

# Get all enemies that can see the player
func get_enemies_that_can_see_player() -> Array:
	var visible_enemies := []
	
	for enemy in enemies:
		if can_enemy_see_player(enemy):
			visible_enemies.append(enemy)
	
	return visible_enemies

# Signal handlers
func _on_player_stealth_changed(is_stealth: bool) -> void:
	if is_stealth:
		EventBus.debug("Player entered stealth mode")
	else:
		EventBus.debug("Player exited stealth mode")

func _on_damage_dealt(source: Node, target: Node, amount: int) -> void:
	# Create noise when damage is dealt
	if source == player:
		create_noise(player.global_position, NoiseLevel.ATTACK, player)
	elif target == player:
		create_noise(player.global_position, NoiseLevel.ATTACK, source)

# Register a cover object
func register_cover_object(cover: Node2D) -> void:
	if not cover in cover_objects:
		cover_objects.append(cover)
		EventBus.debug("Cover object registered: " + cover.name)

# Unregister a cover object
func unregister_cover_object(cover: Node2D) -> void:
	if cover in cover_objects:
		cover_objects.erase(cover)
		EventBus.debug("Cover object unregistered: " + cover.name)