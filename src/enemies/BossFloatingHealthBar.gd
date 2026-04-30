extends Node2D
## Simple world-space HP bar above a boss. Parent must expose max_health, health, and emit health_changed.

@export var bar_width: float = 72.0
@export var bar_height: float = 8.0
@export var offset_y: float = -104.0

var _enemy: Node = null


func _ready() -> void:
	_enemy = get_parent()
	position = Vector2(0.0, offset_y)
	if _enemy and _enemy.has_signal("health_changed") and not _enemy.health_changed.is_connected(_on_health_changed):
		_enemy.health_changed.connect(_on_health_changed)
	queue_redraw()


func _on_health_changed(_current: int, _max_hp: int) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		queue_free()
		return
	position = Vector2(0.0, offset_y)


func _draw() -> void:
	if _enemy == null:
		return
	var max_hp: int = int(_enemy.get("max_health"))
	var hp: int = int(_enemy.get("health"))
	if max_hp <= 0:
		return
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var half_w := bar_width * 0.5
	draw_rect(Rect2(-half_w, 0.0, bar_width, bar_height), Color(0.1, 0.05, 0.05, 0.85))
	draw_rect(Rect2(-half_w, 0.0, bar_width * ratio, bar_height), Color(0.85, 0.2, 0.15, 0.95))
