# SceneManager.gd
# Scene transition wrapper with fade effects

extends Node

# Transition types
enum Transition {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	NONE
}

# Scene paths
const SCENES := {
	"hideout": "res://scenes/hideout/hideout.tscn",
	"heist_tutorial": "res://scenes/heists/heist_tutorial.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn"
}

var current_scene: Node = null
var transition_in_progress: bool = false

@onready var transition_layer: CanvasLayer = _create_transition_layer()

func _ready() -> void:
	EventBus.debug("SceneManager loaded")
	
	# Connect to scene change request
	get_tree().connect("node_added", _on_node_added)

# Change scene with transition
func change_scene(scene_path: String, transition_type: Transition = Transition.FADE, transition_time: float = 0.5) -> void:
	if transition_in_progress:
		EventBus.debug("Scene change already in progress")
		return
	
	transition_in_progress = true
	EventBus.debug("Changing scene to: " + scene_path)
	
	# Store player position if in a mission
	if GameState.is_in_mission and current_scene:
		var player := current_scene.find_child("Player", true, false)
		if player:
			GameState.player_position = player.global_position
	
	match transition_type:
		Transition.FADE:
			_fade_transition(scene_path, transition_time)
		Transition.NONE:
			_immediate_transition(scene_path)
		_:
			# Default to fade for other unimplemented transitions
			_fade_transition(scene_path, transition_time)

# Change to a named scene (from SCENES dictionary)
func change_to_scene(scene_name: String, transition_type: Transition = Transition.FADE, transition_time: float = 0.5) -> void:
	if scene_name in SCENES:
		change_scene(SCENES[scene_name], transition_type, transition_time)
	else:
		EventBus.debug("Unknown scene: " + scene_name)

# Reload current scene
func reload_current_scene(transition_type: Transition = Transition.FADE, transition_time: float = 0.5) -> void:
	if current_scene:
		var current_path := current_scene.scene_file_path
		if current_path:
			change_scene(current_path, transition_type, transition_time)

# Fade transition
func _fade_transition(scene_path: String, transition_time: float) -> void:
	# Create fade rect
	var fade_rect := ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().size
	transition_layer.add_child(fade_rect)
	
	# Fade in
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, transition_time / 2)
	tween.tween_callback(_load_scene.bind(scene_path, fade_rect, transition_time))

# Immediate transition (no effect)
func _immediate_transition(scene_path: String) -> void:
	_load_scene(scene_path)

# Load the new scene
func _load_scene(scene_path: String, fade_rect: ColorRect = null, transition_time: float = 0.5) -> void:
	# Load and instantiate new scene
	var new_scene := load(scene_path)
	if new_scene:
		var instance := new_scene.instantiate()
		
		# Remove old scene
		if current_scene:
			current_scene.queue_free()
		
		# Add new scene
		get_tree().root.add_child(instance)
		current_scene = instance
		
		# Update GameState
		GameState.player_current_scene = scene_path
		
		# Position player if returning to hideout
		if scene_path == SCENES.hideout and GameState.player_position != Vector2.ZERO:
			var player := instance.find_child("Player", true, false)
			if player:
				player.global_position = GameState.player_position
		
		EventBus.debug("Scene loaded: " + scene_path)
		
		# Complete fade transition if applicable
		if fade_rect:
			var tween := create_tween()
			tween.tween_property(fade_rect, "modulate:a", 0.0, transition_time / 2)
			tween.tween_callback(fade_rect.queue_free)
			tween.tween_callback(_on_transition_complete)
	else:
		EventBus.debug("Failed to load scene: " + scene_path)
		transition_in_progress = false

# Create transition layer
func _create_transition_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100  # Very high layer to be on top of everything
	layer.follow_viewport_enabled = true
	add_child(layer)
	return layer

# Called when transition completes
func _on_transition_complete() -> void:
	transition_in_progress = false
	EventBus.debug("Scene transition complete")

# Track when nodes are added to detect scene changes
func _on_node_added(node: Node) -> void:
	# Check if this is a new scene root (not a child of current scene)
	if node != self and node != transition_layer and node.get_parent() == get_tree().root:
		if node != current_scene:
			# This might be a scene loaded directly (not through SceneManager)
			if current_scene:
				current_scene.queue_free()
			current_scene = node
			EventBus.debug("Detected direct scene load: " + node.name)