extends CharacterBody2D

@export var character_id := "city_contact"
@export var display_name := "Contact"
@export_multiline var dialogue_text := "The city is listening."

var player_in_range := false

func _ready() -> void:
	add_to_group("interactable")
	var zone := get_node_or_null("InteractionZone")
	if zone:
		zone.body_entered.connect(_on_body_entered)
		zone.body_exited.connect(_on_body_exited)
	var label := get_node_or_null("InteractionIndicator")
	if label:
		label.visible = false

func interact(player: Node = null) -> void:
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": dialogue_text }])

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		var label := get_node_or_null("InteractionIndicator")
		if label:
			label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		var label := get_node_or_null("InteractionIndicator")
		if label:
			label.visible = false
