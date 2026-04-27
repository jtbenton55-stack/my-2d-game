# SchemeCardMenu.gd
# UI for selecting Scheme Cards before missions

extends Control

@onready var cards_container: GridContainer = $MenuContainer/VBoxContainer/CardsContainer
@onready var selected_count_label: Label = $MenuContainer/VBoxContainer/SelectedCount
@onready var confirm_button: Button = $MenuContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var back_button: Button = $MenuContainer/VBoxContainer/ButtonContainer/BackButton

var _card_buttons: Array[Button] = []
var _selected_card_ids: Array[String] = []
var _max_selection: int = 3
var _mission_id: String = ""

func _ready() -> void:
	# Connect signals
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Set focus
	back_button.grab_focus()
	
	# Initially hidden
	hide()
	
	EventBus.debug("SchemeCardMenu loaded")

func show_menu(mission_id: String = "") -> void:
	"""Show the card selection menu"""
	_mission_id = mission_id
	_selected_card_ids.clear()
	
	# Load unlocked cards
	_populate_cards()
	
	# Update UI
	_update_selected_count()
	
	# Show menu
	show()
	
	# Set focus to first card button if available
	if _card_buttons.size() > 0:
		_card_buttons[0].grab_focus()
	
	EventBus.debug("SchemeCardMenu shown for mission: " + mission_id)

func hide_menu() -> void:
	"""Hide the card selection menu"""
	hide()
	EventBus.debug("SchemeCardMenu hidden")

func _populate_cards() -> void:
	"""Populate the grid with unlocked cards"""
	# Clear existing cards
	for button in _card_buttons:
		button.queue_free()
	_card_buttons.clear()
	
	# Get unlocked cards
	var card_manager = get_node("/root/CardManager")
	if not card_manager:
		# Create a temporary CardManager if it doesn't exist
		card_manager = _create_temp_card_manager()
	
	var unlocked_cards = card_manager.get_unlocked_cards()
	
	# Create card buttons
	for card in unlocked_cards:
		var button = _create_card_button(card)
		cards_container.add_child(button)
		_card_buttons.append(button)
	
	# If no cards, show message
	if unlocked_cards.size() == 0:
		var label = Label.new()
		label.text = "No Scheme Cards unlocked yet."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		cards_container.add_child(label)

func _create_card_button(card) -> Button:
	"""Create a button for a Scheme Card"""
	var button = Button.new()
	
	# Set button text and tooltip
	button.text = card.display_name
	button.tooltip_text = card.description + "\n\nEffect: " + _get_effect_description(card)
	
	# Set button size
	button.custom_minimum_size = Vector2(200, 100)
	
	# Style based on selection state
	button.theme_type_variation = "CardButton"
	
	# Connect signal
	button.pressed.connect(_on_card_button_pressed.bind(card.id, button))
	
	return button

func _get_effect_description(card) -> String:
	"""Get human-readable effect description"""
	match card.effect_type:
		"boolean":
			return "Activates " + card.effect_key.replace("has_", "").replace("_", " ")
		"stat_mod":
			var value_str = str(card.effect_value)
			if card.effect_value > 1.0:
				value_str = "+" + str(int((card.effect_value - 1.0) * 100)) + "%"
			elif card.effect_value < 1.0:
				value_str = "-" + str(int((1.0 - card.effect_value) * 100)) + "%"
			return card.effect_key.replace("_", " ") + " " + value_str
		_:
			return card.effect_key

func _on_card_button_pressed(card_id: String, button: Button) -> void:
	"""Handle card button press"""
	if card_id in _selected_card_ids:
		# Deselect card
		_selected_card_ids.erase(card_id)
		button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8, 1))
		EventBus.debug("Card deselected: " + card_id)
	else:
		# Select card if under limit
		if _selected_card_ids.size() < _max_selection:
			_selected_card_ids.append(card_id)
			button.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8, 1))
			button.add_theme_color_override("font_pressed_color", Color(0.6, 0.2, 0.8, 1))
			EventBus.debug("Card selected: " + card_id)
		else:
			# Show feedback that limit reached
			EventBus.debug("Maximum cards selected (" + str(_max_selection) + ")")
			# Would add visual/audio feedback
	
	_update_selected_count()

func _update_selected_count() -> void:
	"""Update selected count label and confirm button"""
	var count = _selected_card_ids.size()
	selected_count_label.text = "Selected: " + str(count) + "/" + str(_max_selection)
	
	# Enable confirm button if at least one card selected
	confirm_button.disabled = count == 0
	
	# Update card button styles
	for i in range(_card_buttons.size()):
		var button = _card_buttons[i]
		# Reset style
		button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8, 1))
	
	# Reapply selection styles
	for card_id in _selected_card_ids:
		for button in _card_buttons:
			if button.text == _get_card_display_name(card_id):
				button.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8, 1))
				button.add_theme_color_override("font_pressed_color", Color(0.6, 0.2, 0.8, 1))
				break

func _get_card_display_name(card_id: String) -> String:
	"""Get display name for card ID"""
	var card_manager = get_node("/root/CardManager")
	if card_manager:
		var card = card_manager.get_card(card_id)
		if card:
			return card.display_name
	return card_id

func _on_confirm_pressed() -> void:
	"""Confirm card selection and proceed to mission"""
	if _selected_card_ids.size() == 0:
		EventBus.debug("Cannot confirm: no cards selected")
		return
	
	EventBus.debug("Cards confirmed: " + str(_selected_card_ids))
	
	# Save selected cards to GameState
	var game_state = get_node("/root/GameState")
	if game_state:
		game_state.select_cards(_selected_card_ids)
	
	# Hide menu
	hide_menu()
	
	# Start mission
	if _mission_id != "":
		EventBus.debug("Starting mission: " + _mission_id)
		# This would be handled by MissionManager
		# For now, just emit a signal
		EventBus.cards_selected.emit(_selected_card_ids)
		
		# Load mission scene
		var mission_data = MissionData.get_mission(_mission_id)
		if mission_data and mission_data.has("scene"):
			var scene_path = mission_data["scene"]
			var scene_manager = get_node("/root/SceneManager")
			if scene_manager:
				scene_manager.change_scene(scene_path)
			else:
				get_tree().change_scene_to_file(scene_path)
	else:
		EventBus.debug("No mission ID specified")

func _on_back_pressed() -> void:
	"""Go back without confirming selection"""
	EventBus.debug("Back button pressed")
	hide_menu()
	
	# Return to mission select
	EventBus.show_mission_select.emit()

func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("ui_cancel"):
		# Escape to go back
		_on_back_pressed()
	
	if event.is_action_pressed("ui_accept"):
		# Enter to confirm if confirm button is focused
		if confirm_button.has_focus() and not confirm_button.disabled:
			_on_confirm_pressed()

func _create_temp_card_manager() -> Node:
	"""Create a temporary CardManager if one doesn't exist"""
	var card_manager = Node.new()
	card_manager.set_script(load("res://src/inventory/CardManager.gd"))
	get_tree().root.add_child(card_manager)
	return card_manager

# ===== CARD BUTTON STYLING =====

func _update_card_button_styles() -> void:
	"""Update card button styles based on selection state"""
	# This would be more sophisticated in a full implementation
	pass

# ===== ANIMATIONS =====

func _on_card_button_mouse_entered(button: Button) -> void:
	"""Card button mouse enter"""
	# Would add hover effect
	pass

func _on_card_button_mouse_exited(button: Button) -> void:
	"""Card button mouse exit"""
	# Would remove hover effect
	pass