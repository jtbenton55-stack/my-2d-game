extends CanvasLayer

const DialoguePortraitRegistry = preload("res://src/dialogue/DialoguePortraitRegistry.gd")

@onready var speaker_label := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/SpeakerLabel") as Label
@onready var text_label := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/TextLabel") as Label
@onready var next_indicator := get_node_or_null("DialoguePanel/MarginContainer/HBox/ContentContainer/NextIndicator") as Label
@onready var skip_button := get_node_or_null("DialoguePanel/SkipButton") as Button
@onready var portrait_container := get_node_or_null("DialoguePanel/MarginContainer/HBox/PortraitContainer") as Control
@onready var portrait_rect := get_node_or_null("DialoguePanel/MarginContainer/HBox/PortraitContainer/PortraitMargin/PortraitRect") as TextureRect

var _last_portrait_id := ""

func _ready() -> void:
	visible = false
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_line_changed.connect(_on_dialogue_line_changed)
	if EventBus.has_signal("dialogue_line_changed_full"):
		EventBus.dialogue_line_changed_full.connect(_on_dialogue_line_changed_full)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	if skip_button:
		skip_button.pressed.connect(DialogueManager.end_dialogue)

func _unhandled_input(event: InputEvent) -> void:
	if visible and InputMap.has_action("interact") and event.is_action_pressed("interact"):
		DialogueManager.next_line()
		get_viewport().set_input_as_handled()

func _on_dialogue_started(_lines: Array) -> void:
	visible = true
	_last_portrait_id = ""
	_apply_portrait("")

func _on_dialogue_line_changed(speaker: String, text: String) -> void:
	visible = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if next_indicator:
		next_indicator.text = "Press E"
	# Legacy listeners may fire before the _full signal in the same frame.
	# If the _full signal arrives, it will overwrite the portrait correctly.
	# Default to inferring portrait_id from the speaker name when the
	# legacy signal is the only thing we receive.
	if _last_portrait_id == "":
		_apply_portrait(_speaker_to_portrait_id(speaker))

func _on_dialogue_line_changed_full(speaker: String, text: String, portrait_id: String, _line_data: Dictionary) -> void:
	visible = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if next_indicator:
		next_indicator.text = "Press E"
	var resolved_id := portrait_id
	if resolved_id == "":
		resolved_id = _speaker_to_portrait_id(speaker)
	_apply_portrait(resolved_id)

func _on_dialogue_ended() -> void:
	visible = false
	_apply_portrait("")

func _apply_portrait(portrait_id: String) -> void:
	_last_portrait_id = portrait_id
	if portrait_rect == null:
		return
	if portrait_id == "":
		portrait_rect.texture = null
		if portrait_container:
			portrait_container.visible = false
		return
	var texture := DialoguePortraitRegistry.get_portrait_texture(portrait_id)
	portrait_rect.texture = texture
	if portrait_container:
		portrait_container.visible = texture != null

func _speaker_to_portrait_id(speaker: String) -> String:
	# Map a clean speaker name back to the registry key. Anything we cannot
	# resolve falls through to the registry's fallback portrait.
	var key := speaker.strip_edges().to_lower()
	if DialoguePortraitRegistry.has_portrait(key):
		return key
	return ""
