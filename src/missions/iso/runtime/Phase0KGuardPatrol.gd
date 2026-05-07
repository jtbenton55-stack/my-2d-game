@tool
class_name Phase0KGuardPatrol
extends CharacterBody2D

@export var guard_id := ""
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed := 80.0
@export var hostile := false
@export var chase_player := false

var _target_index := 0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("phase0k_guard")
	set_meta("generated_by", "Phase0K")
	_build_visual()


func _physics_process(_delta: float) -> void:
	if chase_player:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null:
			var to_player := player.global_position - global_position
			velocity = to_player.normalized() * patrol_speed
			move_and_slide()
			return
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var target := patrol_points[_target_index]
	var delta_pos := target - global_position
	if delta_pos.length() < 10.0:
		_target_index = (_target_index + 1) % patrol_points.size()
		target = patrol_points[_target_index]
		delta_pos = target - global_position
	velocity = delta_pos.normalized() * patrol_speed
	move_and_slide()


func _build_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = 18
		shape.shape = circle
		add_child(shape)
	var outline := ColorRect.new()
	outline.name = "BlackBodyOutline"
	outline.position = Vector2(-18, -18)
	outline.size = Vector2(36, 42)
	outline.color = Color(0, 0, 0, 1)
	add_child(outline)
	var body := ColorRect.new()
	body.name = "RedBody"
	body.position = Vector2(-13, -12)
	body.size = Vector2(26, 32)
	body.color = Color(0.9, 0.02, 0.02, 1)
	add_child(body)
	var cone := Polygon2D.new()
	cone.name = "RedScanningCone"
	cone.color = Color(1.0, 0.0, 0.0, 0.28)
	cone.polygon = PackedVector2Array([Vector2(0, 0), Vector2(96, -34), Vector2(96, 34)])
	add_child(cone)
	var head := Polygon2D.new()
	head.name = "WhiteCircleHead"
	head.color = Color(1, 1, 1, 1)
	var points := PackedVector2Array()
	for i in range(16):
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / 16.0) * 10.0 + Vector2(0, -22))
	head.polygon = points
	add_child(head)
	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(-54, -62)
	label.text = "ATTACK\nGUARD" if hostile else "GUARD"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
