extends Node
class_name BranchingDialogueTrigger

@export var dialogue_lines: Array[Dictionary] = [
	{"speaker": "Parmida", "text": "Hello."},
	{"speaker": "Bentley", "text": "Woof."}
]
@export var choices: Array[String] = []
@export var choice_event_name: String = ""

var waiting_for_dialogue_end := false

func start_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	var lines_to_play := dialogue_lines.duplicate()
	if not choices.is_empty():
		lines_to_play.remove_at(lines_to_play.size() - 1)
	if not lines_to_play.is_empty():
		waiting_for_dialogue_end = true
		if not EventBus.dialogue_ended.is_connected(_on_dialogue_finished):
			EventBus.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.start_simple_dialogue(lines_to_play)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	if waiting_for_dialogue_end and EventBus.dialogue_ended.is_connected(_on_dialogue_finished):
		EventBus.dialogue_ended.disconnect(_on_dialogue_finished)
	waiting_for_dialogue_end = false
	if not choices.is_empty():
		var last_line := ""
		if not dialogue_lines.is_empty():
			last_line = String(dialogue_lines[dialogue_lines.size() - 1].get("text", ""))
		_show_choices(last_line)
	else:
		_dialogue_ended()

func _show_choices(prompt: String) -> void:
	var packed := load("res://src/dialogue/choice_panel.tscn") as PackedScene
	if packed == null:
		EventBus.warn("Choice panel scene missing.")
		_dialogue_ended()
		return
	var panel := packed.instantiate()
	if panel.has_method("setup"):
		panel.setup(prompt, choices)
	if panel.has_signal("choice_made"):
		panel.choice_made.connect(_on_choice_made)
	get_tree().current_scene.add_child(panel)

func _on_choice_made(index: int) -> void:
	if choice_event_name != "" and EventBus.has_signal(choice_event_name):
		EventBus.emit_signal(choice_event_name, index)
	_dialogue_ended()

func _dialogue_ended() -> void:
	pass
