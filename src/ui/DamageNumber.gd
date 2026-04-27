# DamageNumber.gd
# Floating damage number display

extends Label

@export var float_speed: float = 100.0
@export var float_distance: float = 50.0
@export var fade_time: float = 1.0

var start_position: Vector2 = Vector2.ZERO
var timer: float = 0.0

func _ready() -> void:
	visible = false

# Show a damage number
func show_damage(damage: int) -> void:
	text = str(damage)
	visible = true
	start_position = global_position
	timer = 0.0
	
	# Start animation
	$Tween.kill()
	$Tween.tween_property(self, "global_position:y", start_position.y - float_distance, fade_time)
	$Tween.tween_property(self, "modulate:a", 0.0, fade_time)
	$Tween.tween_callback(_on_animation_complete)

func _process(delta: float) -> void:
	if not visible:
		return
	
	timer += delta
	if timer >= fade_time:
		visible = false

func _on_animation_complete() -> void:
	visible = false
	modulate.a = 1.0
	global_position = start_position