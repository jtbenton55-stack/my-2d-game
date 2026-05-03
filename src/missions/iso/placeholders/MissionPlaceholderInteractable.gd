class_name MissionPlaceholderInteractable
extends Area2D

signal placeholder_completed(placeholder_id: String)

@export var placeholder_id: String = ""
@export var mission_id: String = ""
@export var display_name: String = "Placeholder"
@export_multiline var interaction_text: String = ""
@export var objective_update: String = ""
@export var auto_trigger_on_enter := false
@export var once_only := true
@export var interaction_priority: int = 50
@export var allow_repeat_interaction := false
@export var available_when_completed := false

var completed := false


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 1
	if auto_trigger_on_enter and not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func interact(player: Node) -> void:
	if not is_interaction_available(player):
		return
	_complete(player)


func _complete(_player: Node = null) -> void:
	if once_only and completed:
		return
	completed = true
	var text := interaction_text
	if text == "":
		text = display_name + " placeholder complete."
	if objective_update != "":
		QuestManager.set_objective(objective_update, mission_id)
	else:
		QuestManager.set_objective(text, mission_id)
	DialogueManager.start_simple_dialogue([{ "speaker": display_name, "text": text }])
	placeholder_completed.emit(placeholder_id)
	if once_only:
		remove_from_group("interactable")
		set_deferred("monitoring", false)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_complete(body)


func is_interaction_available(_player: Node = null) -> bool:
	if completed and not available_when_completed and not allow_repeat_interaction:
		return false
	return true


func get_interaction_priority(_player: Node = null) -> int:
	if completed and not allow_repeat_interaction:
		return interaction_priority - 40
	return interaction_priority
