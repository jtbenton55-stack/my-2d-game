class_name MissionLightZone
extends Area2D

@export_enum("shadow", "bright", "flicker") var zone_type: String = "shadow"
@export var detection_modifier_shadow: float = 0.55
@export var detection_modifier_bright: float = 1.25
@export var flicker_speed: float = 3.0
@export var flicker_low: float = 0.7
@export var flicker_high: float = 1.35
@export var radius: float = 70.0

var _controller: MissionAlertController = null
var _player_inside := false
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("iso_light_zone")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_controller = _find_controller()
	set_process(zone_type == "flicker")


func _process(delta: float) -> void:
	if not _player_inside or _controller == null:
		return
	if zone_type != "flicker":
		return
	_time += delta
	var t := 0.5 + 0.5 * sin(_time * flicker_speed)
	var mod := lerpf(flicker_low, flicker_high, t)
	_controller.set_detection_modifier(mod)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_apply_modifier()


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if _controller != null:
		_controller.set_detection_modifier(1.0)


func _apply_modifier() -> void:
	if _controller == null:
		return
	match zone_type:
		"shadow":
			_controller.set_detection_modifier(detection_modifier_shadow)
		"bright":
			_controller.set_detection_modifier(detection_modifier_bright)
		"flicker":
			_controller.set_detection_modifier(flicker_low)
		_:
			_controller.set_detection_modifier(1.0)


func _find_controller() -> MissionAlertController:
	var node := get_tree().get_first_node_in_group("iso_alert_controller")
	if node is MissionAlertController:
		return node
	return null
