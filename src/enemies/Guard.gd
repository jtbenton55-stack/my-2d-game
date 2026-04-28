extends "res://src/enemies/EnemyBase.gd"

@export var patrol_speed := 100.0
@export var wait_time_at_points := 2.0
@export var detection_speed := 1.0
@export var detection_decay := 0.5
@export var alert_duration := 5.0

func _ready() -> void:
	super._ready()
