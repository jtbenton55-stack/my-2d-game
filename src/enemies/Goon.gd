extends "res://src/enemies/EnemyBase.gd"

@export var wander_radius := 50.0
@export var wander_speed := 80.0
@export var wait_time := 1.5

func _ready() -> void:
	super._ready()
