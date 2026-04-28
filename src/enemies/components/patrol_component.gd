extends Node

@export var path: Path2D
@export var speed: float = 60.0
@export var wait_time: float = 2.0
@export var snap_parent_to_first_point := true

var points: Array[Vector2] = []
var target_index := 0
var state := 0
var idle_timer := 0.0
var body: CharacterBody2D

func _ready() -> void:
	body = get_parent() as CharacterBody2D
	if body == null:
		EventBus.warn("PatrolComponent parent must be a CharacterBody2D.")
		queue_free()
		return
	_collect_points()
	if points.is_empty():
		queue_free()
		return
	if snap_parent_to_first_point:
		body.global_position = points[0]

func _physics_process(delta: float) -> void:
	if body == null or points.is_empty():
		return
	if state == 0:
		var target := points[target_index]
		var direction := (target - body.global_position).normalized()
		body.velocity = direction * speed
		body.move_and_slide()
		if body.global_position.distance_to(target) < 10.0:
			body.velocity = Vector2.ZERO
			state = 1
			idle_timer = wait_time
	else:
		body.velocity = Vector2.ZERO
		idle_timer -= delta
		if idle_timer <= 0.0:
			_move_to_next()
			state = 0

func _collect_points() -> void:
	points.clear()
	if path == null or path.curve == null:
		return
	for i in range(path.curve.point_count):
		points.append(path.to_global(path.curve.get_point_position(i)))

func _move_to_next() -> void:
	target_index = (target_index + 1) % points.size()
