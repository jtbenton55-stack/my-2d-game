# HUD.gd
# Heads-up display with health bar, detection meter, objective marker

extends CanvasLayer

# References
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_meter: ProgressBar = $DetectionMeter
@onready var detection_label: Label = $DetectionMeter/Label
@onready var objective_marker: Sprite2D = $ObjectiveMarker
@onready var objective_distance: Label = $ObjectiveMarker/Distance

# State
var is_detection_visible: bool = false
var objective_position: Vector2 = Vector2.ZERO
var player: Node2D = null

func _ready() -> void:
	EventBus.debug("HUD loaded")
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Connect signals
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.show_detection_meter.connect(_on_show_detection_meter)
	EventBus.update_detection_meter.connect(_on_update_detection_meter)
	EventBus.show_objective_marker.connect(_on_show_objective_marker)
	
	# Hide detection meter initially
	detection_meter.visible = false
	detection_label.visible = false
	
	# Hide objective marker initially
	objective_marker.visible = false
	objective_distance.visible = false

func _process(delta: float) -> void:
	# Update objective marker position and distance
	if objective_marker.visible and player:
		_update_objective_marker()

# Update health bar
func _on_player_health_changed(new_health: int, max_health: int) -> void:
	var health_percent := float(new_health) / float(max_health) * 100.0
	health_bar.value = health_percent
	
	# Change color based on health
	if health_percent > 70:
		health_bar.add_theme_color_override("fill_color", Color.GREEN)
	elif health_percent > 30:
		health_bar.add_theme_color_override("fill_color", Color.YELLOW)
	else:
		health_bar.add_theme_color_override("fill_color", Color.RED)
	
	EventBus.debug("Health updated: " + str(new_health) + "/" + str(max_health))

# Show/hide detection meter
func _on_show_detection_meter(visible: bool) -> void:
	is_detection_visible = visible
	detection_meter.visible = visible
	detection_label.visible = visible
	
	if visible:
		EventBus.debug("Detection meter shown")
	else:
		EventBus.debug("Detection meter hidden")

# Update detection meter value
func _on_update_detection_meter(value: float) -> void:
	if not is_detection_visible:
		return
	
	var detection_percent := value * 100.0
	detection_meter.value = detection_percent
	
	# Change color based on detection level
	if detection_percent < 30:
		detection_meter.add_theme_color_override("fill_color", Color.GREEN)
	elif detection_percent < 70:
		detection_meter.add_theme_color_override("fill_color", Color.YELLOW)
	else:
		detection_meter.add_theme_color_override("fill_color", Color.RED)
	
	# Update label
	detection_label.text = "DETECTION: " + str(int(detection_percent)) + "%"

# Show/hide objective marker
func _on_show_objective_marker(visible: bool, position: Vector2) -> void:
	objective_marker.visible = visible
	objective_distance.visible = visible
	objective_position = position
	
	if visible:
		EventBus.debug("Objective marker shown at " + str(position))
		_update_objective_marker()
	else:
		EventBus.debug("Objective marker hidden")

# Update objective marker position and distance
func _update_objective_marker() -> void:
	if not player or not objective_marker.visible:
		return
	
	# Calculate direction to objective
	var direction := objective_position - player.global_position
	var distance := direction.length()
	
	# Position marker at edge of screen pointing toward objective
	var screen_center := get_viewport().get_visible_rect().size / 2
	var max_distance_from_center := min(screen_center.x, screen_center.y) - 50
	
	if distance > 100:  # Only show if objective is far
		# Normalize direction and position at edge of screen
		var normalized_dir := direction.normalized()
		var marker_position := screen_center + normalized_dir * max_distance_from_center
		
		objective_marker.position = marker_position
		objective_marker.rotation = direction.angle()
		
		# Update distance text
		objective_distance.text = str(int(distance / 10)) + "m"
		objective_distance.position = marker_position + Vector2(0, 30)
	else:
		# Hide if objective is close
		objective_marker.visible = false
		objective_distance.visible = false

# Show message (for tutorial hints, etc.)
func show_message(text: String, duration: float = 3.0) -> void:
	EventBus.debug("HUD Message: " + text)
	# In a real game, this would show a message on screen
	# For now, just log it

# Clean up
func cleanup() -> void:
	EventBus.debug("Cleaning up HUD")