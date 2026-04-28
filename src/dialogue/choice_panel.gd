extends Control

signal choice_made(index: int)

var choices: Array[String] = []

@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer

func _ready() -> void:
	grab_focus()

func setup(prompt: String, choices_array: Array[String]) -> void:
	choices = choices_array.duplicate()
	if not is_node_ready():
		await ready
	prompt_label.text = prompt
	for child in choices_container.get_children():
		child.queue_free()
	for i in range(choices.size()):
		var button := Button.new()
		button.text = choices[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_button_pressed.bind(i))
		choices_container.add_child(button)
	if choices_container.get_child_count() > 0:
		var first_button := choices_container.get_child(0) as Button
		if first_button:
			first_button.grab_focus()

func _on_button_pressed(index: int) -> void:
	choice_made.emit(index)
	queue_free()
