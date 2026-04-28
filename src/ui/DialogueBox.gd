extends CanvasLayer

@onready var speaker_label := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/SpeakerLabel") as Label
@onready var text_label := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/TextLabel") as Label
@onready var next_indicator := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/NextIndicator") as Label
@onready var skip_button := get_node_or_null("DialoguePanel/SkipButton") as Button

func _ready() -> void:
	visible = false
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_line_changed.connect(_on_dialogue_line_changed)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	if skip_button:
		skip_button.pressed.connect(DialogueManager.end_dialogue)

func _unhandled_input(event: InputEvent) -> void:
	if visible and InputMap.has_action("interact") and event.is_action_pressed("interact"):
		DialogueManager.next_line()

func _on_dialogue_started(_lines: Array) -> void:
	visible = true

func _on_dialogue_line_changed(speaker: String, text: String) -> void:
	visible = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if next_indicator:
		next_indicator.text = "Press E"

func _on_dialogue_ended() -> void:
	visible = false
