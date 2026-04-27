# TestMissionRoom.gd
# Generic test mission room for spine validation
# Simple room with player spawn, exit zone, and optional guards

extends LevelBase

@export var mission_id: String = "taco_bell_drop"
@export var guard_count: int = 1

func _get_mission_id() -> String:
	return mission_id

func _ready() -> void:
	super._ready()
	EventBus.debug("TestMissionRoom started: " + mission_id)

# Override enemy spawning
func _spawn_enemies() -> void:
	if guard_count <= 0:
		return
	
	var guard_scene := preload("res://scenes/characters/guard.tscn")
	if not guard_scene:
		EventBus.debug("TestMissionRoom: guard scene not found")
		return
	
	# Spawn guards in a simple patrol pattern
	for i in range(guard_count):
		var guard = guard_scene.instantiate()
		var spawn_pos = player_spawn.global_position + Vector2(200 + i * 150, 100 + (i % 2) * 150)
		guard.global_position = spawn_pos
		guard.name = "TestGuard_" + str(i)
		
		# Set patrol points
		if guard.has_method("set_patrol_points"):
			guard.set_patrol_points([
				spawn_pos,
				spawn_pos + Vector2(100, 0),
				spawn_pos + Vector2(100, 100),
				spawn_pos + Vector2(0, 100)
			])
		
		add_child(guard)
		EventBus.debug("Guard spawned at " + str(spawn_pos))

# Override completion to show MissionResult
func complete_level() -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("TestMissionRoom completed: " + mission_id)
	
	# Complete mission in GameState
	if mission_id != "":
		GameState.complete_mission(mission_id)
	GameState.end_mission()
	
	# Save game
	SaveManager.auto_save()
	
	# Show mission result via EventBus
	EventBus.show_mission_result.emit(true, {})

# Called when player dies or is caught
func fail_level(reason: String = "caught") -> void:
	if is_complete:
		return
	
	is_complete = true
	EventBus.debug("TestMissionRoom failed: " + reason)
	
	# Fail mission in GameState
	if mission_id != "":
		GameState.fail_mission(mission_id, 10)
	GameState.end_mission()
	
	# Save game (failure progress still saves)
	SaveManager.auto_save()
	
	# Show failure screen
	EventBus.show_failure_screen.emit("Mission Failed: " + reason, {})

# Input for testing: press K to instantly complete, L to instantly fail
func _input(event: InputEvent) -> void:
	if OS.is_debug_build():
		if event.is_action_pressed("ui_page_down"):
			complete_level()
		if event.is_action_pressed("ui_page_up"):
			fail_level("debug_fail")
