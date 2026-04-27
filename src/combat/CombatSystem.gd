# CombatSystem.gd
# Handles combat mechanics: hitboxes, damage numbers, knockback, i-frames

extends Node

# Damage number pool
const DAMAGE_NUMBER_SCENE := preload("res://scenes/ui/damage_number.tscn")
var damage_number_pool: Array = []

# Knockback
@export var default_knockback_force: float = 200.0
@export var knockback_decay: float = 0.9

# i-frame tracking
var iframe_entities: Dictionary = {}  # entity -> iframe_timer

func _ready() -> void:
	EventBus.debug("CombatSystem loaded")
	
	# Pre-create damage numbers
	_create_damage_number_pool(20)
	
	# Connect signals
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_dodged.connect(_on_player_dodged)

# Apply damage with combat effects
func apply_damage(source: Node, target: Node, damage: int, knockback_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	# Check if target has i-frames
	if _has_iframes(target):
		EventBus.debug("Target has i-frames, damage blocked")
		return
	
	# Apply damage
	if target.has_method("take_damage"):
		target.take_damage(damage, source)
	
	# Show damage number
	_show_damage_number(target.global_position, damage)
	
	# Apply knockback
	if knockback_direction != Vector2.ZERO:
		var force := knockback_force if knockback_force > 0 else default_knockback_force
		_apply_knockback(target, knockback_direction, force)
	
	# Emit combat events
	if not GameState.is_in_combat:
		GameState.is_in_combat = true
		EventBus.combat_started.emit()
	
	EventBus.debug("Combat: " + source.name + " dealt " + str(damage) + " damage to " + target.name)

# Apply knockback to a target
func _apply_knockback(target: Node, direction: Vector2, force: float) -> void:
	if target is CharacterBody2D:
		target.velocity += direction.normalized() * force
		EventBus.debug("Applied knockback to " + target.name)
	elif target.has_method("apply_knockback"):
		target.apply_knockback(direction, force)

# Show a floating damage number
func _show_damage_number(position: Vector2, damage: int) -> void:
	var damage_number = _get_damage_number_from_pool()
	if not damage_number:
		return
	
	damage_number.global_position = position
	damage_number.show_damage(damage)
	
	# Add to scene if not already
	if not damage_number.is_inside_tree():
		get_tree().root.add_child(damage_number)

# Create a pool of damage numbers
func _create_damage_number_pool(count: int) -> void:
	for i in range(count):
		var damage_number = DAMAGE_NUMBER_SCENE.instantiate()
		damage_number.visible = false
		damage_number_pool.append(damage_number)

# Get a damage number from the pool
func _get_damage_number_from_pool() -> Node:
	for damage_number in damage_number_pool:
		if not damage_number.visible:
			return damage_number
	
	# If pool is empty, create a new one
	var new_damage_number = DAMAGE_NUMBER_SCENE.instantiate()
	damage_number_pool.append(new_damage_number)
	return new_damage_number

# Grant i-frames to an entity
func grant_iframes(entity: Node, duration: float) -> void:
	iframe_entities[entity] = duration
	EventBus.debug("Granted i-frames to " + entity.name + " for " + str(duration) + "s")

# Check if entity has i-frames
func _has_iframes(entity: Node) -> bool:
	return iframe_entities.has(entity) and iframe_entities[entity] > 0

# Update i-frames
func _process(delta: float) -> void:
	# Update i-frame timers
	for entity in iframe_entities.keys():
		iframe_entities[entity] -= delta
		if iframe_entities[entity] <= 0:
			iframe_entities.erase(entity)
	
	# Check if combat has ended
	_check_combat_end()

# Check if combat should end
func _check_combat_end() -> void:
	if not GameState.is_in_combat:
		return
	
	# Check if any enemies are alive and in combat range
	var enemies := get_tree().get_nodes_in_group("enemy")
	var player := get_tree().get_first_node_in_group("player")
	
	if not player:
		return
	
	var combat_active := false
	
	for enemy in enemies:
		if enemy.global_position.distance_to(player.global_position) < 500.0:
			# Check if enemy is in a combat state
			if enemy.has_method("get_current_state"):
				var state = enemy.get_current_state()
				if state in [enemy.State.CHASE, enemy.State.ATTACK, enemy.State.ALERT]:
					combat_active = true
					break
			else:
				# Simple distance check
				combat_active = true
				break
	
	if not combat_active:
		GameState.is_in_combat = false
		EventBus.combat_ended.emit()
		EventBus.debug("Combat ended")

# Calculate damage based on various factors
func calculate_damage(base_damage: int, source: Node, target: Node) -> int:
	var damage := base_damage
	
	# Apply stealth bonus
	if source == get_tree().get_first_node_in_group("player") and source.get("is_stealth") == true:
		damage *= 2  # Double damage from stealth
		EventBus.debug("Stealth attack bonus applied")
	
	# Apply critical chance (placeholder)
	var crit_chance := 0.1  # 10% base crit chance
	if randf() < crit_chance:
		damage *= 2
		EventBus.debug("Critical hit!")
	
	return damage

# Signal handlers
func _on_damage_dealt(source: Node, target: Node, amount: int) -> void:
	# This is already handled by apply_damage, but we can add additional effects here
	pass

func _on_player_dodged() -> void:
	# Grant i-frames to player on dodge
	var player := get_tree().get_first_node_in_group("player")
	if player:
		grant_iframes(player, 0.5)  # 0.5 seconds of i-frames

# Clean up combat state
func cleanup() -> void:
	# Return all damage numbers to pool
	for damage_number in damage_number_pool:
		if damage_number.visible:
			damage_number.visible = false
	
	# Clear i-frames
	iframe_entities.clear()
	
	# End combat
	if GameState.is_in_combat:
		GameState.is_in_combat = false
		EventBus.combat_ended.emit()