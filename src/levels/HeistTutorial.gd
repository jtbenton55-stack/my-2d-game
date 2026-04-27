# HeistTutorial.gd
# Tutorial heist level

extends LevelBase

@onready var guard_spawn: Marker2D = $GuardSpawn

func _ready() -> void:
	super._ready()
	
	# Setup tutorial-specific things
	EventBus.debug("Tutorial heist started")
	
	# Show tutorial message
	EventBus.debug("Objective: Reach the exit zone without being detected!")

# Override enemy spawning
func _spawn_enemies() -> void:
	super._spawn_enemies()
	
	# Spawn a guard
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	var guard = guard_scene.instantiate()
	guard.global_position = guard_spawn.global_position
	guard.name = "TutorialGuard"
	
	# Set patrol points
	if guard.has_method("set_patrol_points"):
		guard.set_patrol_points([
			guard_spawn.global_position,
			guard_spawn.global_position + Vector2(200, 0),
			guard_spawn.global_position + Vector2(200, 200),
			guard_spawn.global_position + Vector2(0, 200)
		])
	
	add_child(guard)
	EventBus.debug("Guard spawned at " + str(guard_spawn.global_position))

# Override completion
func complete_level() -> void:
	EventBus.debug("Tutorial completed!")
	super.complete_level()

# Tutorial-specific cleanup
func cleanup() -> void:
	super.cleanup()
	EventBus.debug("Tutorial cleanup complete")