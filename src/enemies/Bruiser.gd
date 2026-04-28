extends "res://src/enemies/EnemyBase.gd"

@export var wind_up_time := 1.2
@export var slam_radius := 60.0
@export var recovery_time := 0.8

func _ready() -> void:
	super._ready()
