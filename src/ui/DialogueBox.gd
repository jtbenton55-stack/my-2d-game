# DialogueBox.gd
# UI for displaying dialogue with typewriter effect, portraits, and choices
# Listens to DialogueManager V2 signals — single source of truth for dialogue state

extends CanvasLayer

# ===== EXPORTS =====
@export var typewriter_speed: float = 0.03
@export var portrait_size: Vector2 = Vector2(96, 96)

# ===== NODE REFERENCES =====
@onready var panel: Panel = $DialoguePanel
@onready var portrait_rect: ColorRect = $DialoguePanel/MarginContainer/HBox/PortraitContainer/PortraitRect
@onready var initial_label: Label = $DialoguePanel/MarginContainer/HBox/PortraitContainer/InitialLabel
@onready var speaker_label: Label = $DialoguePanel/MarginContainer/HBox/ContentContainer/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/MarginContainer/HBox/ContentContainer/TextLabel
@onready var choices_container: VBoxContainer = $DialoguePanel/MarginContainer/HBox/ContentContainer/ChoicesContainer
@onready var next_indicator: Label = $DialoguePanel/MarginContainer/HBox/ContentContainer/NextIndicator
@onready var skip_button: Button = $DialoguePanel/SkipButton
@onready var auto_button: Button = $DialoguePanel/AutoButton

# ===== STATE =====
var _choice_buttons: Array[Button] = []
var _auto_enabled: bool = false

# ===== LIFECYCLE =====

func _ready() -> void:
	visible = false
	
	# Connect to DialogueManager V2 signals
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_text_updated.connect(_on_text_updated)
	DialogueManager.dialogue_choices_available.connect(_on_choices_available)
	DialogueManager.dialogue_choice_selected.connect(_on_choice_selected)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.typewriter_finished.connect(_on_typewriter_finished)
	
	# Button signals
	skip_button.pressed.connect(_on_skip_pressed)
	auto_button.pressed.connect(_on_auto_pressed)
	
	# Style setup
	_setup_styles()
	
	EventBus.debug("DialogueBox V2 loaded")

func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_in_dialogue():
		return
	
	# Advance / skip typewriter on interact or accept
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if DialogueManager.is_typewriting():
			DialogueManager.skip_typewriter()
		elif _choice_buttons.is_empty():
			DialogueManager.advance_dialogue()
		get_viewport().set_input_as_handled()
	
	# Skip/close on cancel
	if event.is_action_pressed("ui_cancel"):
		if DialogueManager.is_typewriting():
			DialogueManager.skip_typewriter()
		else:
			DialogueManager.end_dialogue()
		get_viewport().set_input_as_handled()
	
	# Number keys for choices
	if not _choice_buttons.is_empty():
		for i in range(min(9, _choice_buttons.size())):
			if event.is_action_pressed("ui_" + str(i + 1)):
				DialogueManager.select_choice(i)
				get_viewport().set_input_as_handled()
				break

# ===== DIALOGUE MANAGER V2 SIGNAL HANDLERS =====

func _on_dialogue_started(_resource: DialogueResource, _node_id: String) -> void:
	_clear_choices()
	visible = true
	_fade_in()

func _on_text_updated(text: String, speaker: String, portrait_path: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	_update_portrait(speaker, portrait_path)
	_update_indicators()

func _on_choices_available(choices: Array) -> void:
	_show_choices(choices)

func _on_choice_selected(_index: int, _data: Dictionary) -> void:
	_clear_choices()

func _on_dialogue_ended() -> void:
	_fade_out()

func _on_typewriter_finished() -> void:
	_update_indicators()

# ===== CHOICES =====

func _show_choices(choices: Array) -> void:
	_clear_choices()
	next_indicator.visible = false
	
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.text = str(i + 1) + ". " + choice.get("text", "...")
		button.custom_minimum_size = Vector2(0, 36)
		button.add_theme_font_size_override("font_size", 14)
		
		# Style
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.15, 0.15, 0.18, 0.9)
		normal.border_width_bottom = 1
		normal.border_color = Color(0.3, 0.3, 0.35, 1.0)
		normal.corner_radius_top_left = 4
		normal.corner_radius_top_right = 4
		normal.corner_radius_bottom_left = 4
		normal.corner_radius_bottom_right = 4
		normal.content_margin_left = 8
		normal.content_margin_top = 4
		normal.content_margin_right = 8
		normal.content_margin_bottom = 4
		button.add_theme_stylebox_override("normal", normal)
		
		var hover := normal.duplicate()
		hover.bg_color = Color(0.25, 0.25, 0.3, 0.9)
		button.add_theme_stylebox_override("hover", hover)
		
		var focus := normal.duplicate()
		focus.border_color = Color(0.6, 0.5, 0.3, 1.0)
		button.add_theme_stylebox_override("focus", focus)
		
		# Highlight important choices (ones that set flags)
		if choice.has("set_flags") and not choice["set_flags"].is_empty():
			button.modulate = Color(1.0, 0.9, 0.6)
		
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		choices_container.add_child(button)
		_choice_buttons.append(button)
	
	if _choice_buttons.size() > 0:
		_choice_buttons[0].grab_focus()

func _clear_choices() -> void:
	for button in _choice_buttons:
		button.queue_free()
	_choice_buttons.clear()

func _on_choice_button_pressed(index: int) -> void:
	DialogueManager.select_choice(index)

# ===== PORTRAIT =====

func _update_portrait(speaker: String, portrait_path: String) -> void:
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var texture := load(portrait_path) as Texture2D
		if texture:
			portrait_rect.color = Color(0.2, 0.2, 0.25, 1.0)
			initial_label.text = ""
			# In a full implementation, swap ColorRect for TextureRect
			return
	
	# Placeholder: colored rect with initial
	portrait_rect.color = _get_speaker_color(speaker)
	initial_label.text = speaker.substr(0, 1).to_upper() if speaker.length() > 0 else "?"

func _get_speaker_color(speaker: String) -> Color:
	match speaker.to_lower():
		"jake": return Color(0.2, 0.4, 0.6, 1.0)
		"louis": return Color(0.6, 0.3, 0.2, 1.0)
		"mere": return Color(0.4, 0.2, 0.5, 1.0)
		"dom": return Color(0.3, 0.5, 0.3, 1.0)
		"yordano": return Color(0.5, 0.4, 0.2, 1.0)
		"bentley": return Color(0.6, 0.5, 0.3, 1.0)
		"narrator": return Color(0.4, 0.4, 0.4, 1.0)
		_:
			var h := speaker.hash()
			return Color(0.3 + (abs(h) % 100) / 200.0, 0.3 + (abs(h >> 8) % 100) / 200.0, 0.3 + (abs(h >> 16) % 100) / 200.0, 1.0)

# ===== INDICATORS =====

func _update_indicators() -> void:
	if DialogueManager.is_typewriting():
		next_indicator.visible = false
		skip_button.disabled = false
	else:
		var choices := DialogueManager.get_available_choices()
		if choices.is_empty():
			next_indicator.visible = true
			next_indicator.text = "▼"
		else:
			next_indicator.visible = false
		skip_button.disabled = false

# ===== BUTTONS =====

func _on_skip_pressed() -> void:
	if DialogueManager.is_typewriting():
		DialogueManager.skip_typewriter()
	else:
		DialogueManager.end_dialogue()

func _on_auto_pressed() -> void:
	_auto_enabled = not _auto_enabled
	DialogueManager.set_auto_advance(_auto_enabled)
	auto_button.text = "Auto: ON" if _auto_enabled else "Auto: OFF"
	auto_button.modulate = Color.GREEN if _auto_enabled else Color.WHITE

# ===== ANIMATION =====

func _fade_in() -> void:
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		_clear_choices()
	)

# ===== STYLES =====

func _setup_styles() -> void:
	# Panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Speaker label
	speaker_label.add_theme_font_size_override("font_size", 18)
	speaker_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 1.0))
	
	# Text label
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Portrait initial
	initial_label.add_theme_font_size_override("font_size", 36)
	initial_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	initial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Next indicator
	next_indicator.add_theme_font_size_override("font_size", 14)
	next_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
