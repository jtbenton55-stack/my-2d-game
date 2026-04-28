extends "res://src/enemies/EnemyBase.gd"

@export var phase_two_threshold := 0.5
var phase_two := false

func _ready() -> void:
	max_health = max(max_health, 180)
	attack_damage = max(attack_damage, 16)
	chase_speed = max(chase_speed, 170.0)
	super._ready()

func take_damage(amount: int, source: Node = null) -> void:
	super.take_damage(amount, source)
	if not phase_two and health > 0 and float(health) / float(max_health) <= phase_two_threshold:
		phase_two = true
		chase_speed *= 1.25
		attack_cooldown *= 0.75
		DialogueManager.start_simple_dialogue([{ "speaker": "Victor Sterling", "text": "You brought friends to a power play. How quaint." }])
