extends Area2D

signal player_entered

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not triggered and body.is_in_group("player"):
		triggered = true
		player_entered.emit()
