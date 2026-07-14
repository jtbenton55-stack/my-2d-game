extends CanvasLayer

const DialoguePortraitRegistry = preload("res://src/dialogue/DialoguePortraitRegistry.gd")
const InputBindingFormatterScript := preload("res://src/utils/InputBindingFormatter.gd")

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
		skip_button.pressed.connect(DialogueManager.skip_dialogue)


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_in_dialogue or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		DialogueManager.end_dialogue()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		DialogueManager.end_dialogue()
		get_viewport().set_input_as_handled()
		return
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		DialogueManager.next_line()
		get_viewport().set_input_as_handled()

func _on_dialogue_started(_lines: Array) -> void:
	visible = true
	_last_portrait_id = ""
	_apply_portrait("")
	_apply_line_controls(true, true)

func _on_dialogue_line_changed(speaker: String, text: String) -> void:
	visible = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if next_indicator:
		next_indicator.text = "Press %s" % InputBindingFormatterScript.action_summary(&"interact", "E")
	_apply_line_controls(true, true)
	# Legacy listeners may fire before the _full signal in the same frame.
	# If the _full signal arrives, it will overwrite the portrait correctly.
	# Default to inferring portrait_id from the speaker name when the
	# legacy signal is the only thing we receive.
	if _last_portrait_id == "":
		_apply_portrait(_speaker_to_portrait_id(speaker))

func _on_dialogue_line_changed_full(speaker: String, text: String, portrait_id: String, line_data: Dictionary) -> void:
	visible = true
	if speaker_label:
		speaker_label.text = speaker
	if text_label:
		text_label.text = text
	if next_indicator:
		next_indicator.text = "Press %s" % InputBindingFormatterScript.action_summary(&"interact", "E")
	_apply_line_controls(
		bool(line_data.get("allow_manual_advance", true)),
		bool(line_data.get("allow_skip", true))
	)
	var resolved_id := portrait_id
	if resolved_id == "":
		resolved_id = _speaker_to_portrait_id(speaker)
	_apply_portrait(resolved_id)

func _on_dialogue_ended() -> void:
	visible = false
	_apply_portrait("")
	_apply_line_controls(true, true)

func _apply_line_controls(allow_manual_advance: bool, allow_skip: bool) -> void:
	if next_indicator:
		next_indicator.visible = true
		var advance := InputBindingFormatterScript.action_summary(&"interact", "E")
		var close := InputBindingFormatterScript.action_summary(&"ui_cancel", "Esc")
		next_indicator.text = "%s: Advance | %s: Close" % [advance, close] if allow_manual_advance else "%s: Close" % close
	if skip_button:
		skip_button.visible = allow_skip

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
