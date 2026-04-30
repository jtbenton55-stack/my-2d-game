extends Area2D

signal activated

@export var prompt_text: String = "Service Door"

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	activated.emit()
