# MissionSelect.gd
# UI for selecting missions

extends Control

@onready var missions_container: VBoxContainer = $MenuContainer/VBoxContainer/MissionsContainer
@onready var back_button: Button = $MenuContainer/VBoxContainer/ButtonContainer/BackButton

var _mission_buttons: Array[Button] = []

func _ready() -> void:
	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	
	# Set focus
	back_button.grab_focus()
	
	# Initially hidden
	hide()
	
	EventBus.debug("MissionSelect loaded")

func show_menu() -> void:
	"""Show the mission selection menu"""
	# Clear existing missions
	for button in _mission_buttons:
		button.queue_free()
	_mission_buttons.clear()
	
	# Load available missions
	_populate_missions()
	
	# Show menu
	show()
	
	# Set focus to first mission button if available
	if _mission_buttons.size() > 0:
		_mission_buttons[0].grab_focus()
	else:
		back_button.grab_focus()
	
	EventBus.debug("MissionSelect shown")

func hide_menu() -> void:
	"""Hide the mission selection menu"""
	hide()
	EventBus.debug("MissionSelect hidden")

func _populate_missions() -> void:
	"""Populate the container with available missions"""
	var game_state = get_node("/root/GameState")
	if not game_state:
		EventBus.debug("MissionSelect: GameState not found")
		return
	
	# Get available missions
	var available_missions = game_state.available_missions
	
	# Create mission buttons
	for mission_id in available_missions:
		var mission_data = MissionData.get_mission(mission_id)
		if mission_data:
			var button = _create_mission_button(mission_id, mission_data)
			missions_container.add_child(button)
			_mission_buttons.append(button)
	
	# If no missions, show message
	if available_missions.size() == 0:
		var label = Label.new()
		label.text = "No missions available. Complete the tutorial first."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		missions_container.add_child(label)

func _create_mission_button(mission_id: String, mission_data: Dictionary) -> Button:
	"""Create a button for a mission"""
	var button = Button.new()
	
	# Set button text and tooltip
	var mission_name = mission_data.get("name", mission_id)
	var mission_desc = mission_data.get("desc", "")
	var difficulty = mission_data.get("difficulty", 1)
	
	button.text = mission_name
	button.tooltip_text = mission_desc + "\n\nDifficulty: " + str(difficulty) + "/5"
	
	# Set button size
	button.custom_minimum_size = Vector2(300, 60)
	
	# Style based on completion status
	var game_state = get_node("/root/GameState")
	if game_state and mission_id in game_state.completed_missions:
		# Mission completed
		button.text += " ✓"
		button.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4, 1))
		button.disabled = false
		button.tooltip_text += "\n\nStatus: Completed"
	elif game_state and game_state.get_failure_count(mission_id) > 0:
		# Mission failed before
		var failure_count = game_state.get_failure_count(mission_id)
		button.text += " (" + str(failure_count) + " attempts)"
		button.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
		button.disabled = false
		button.tooltip_text += "\n\nStatus: Failed " + str(failure_count) + " time(s)"
	else:
		# Mission available
		button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		button.disabled = false
		button.tooltip_text += "\n\nStatus: Available"
	
	# Connect signal
	button.pressed.connect(_on_mission_button_pressed.bind(mission_id))
	
	return button

func _on_mission_button_pressed(mission_id: String) -> void:
	"""Handle mission button press"""
	EventBus.debug("Mission selected: " + mission_id)
	
	# Hide mission select menu
	hide_menu()
	
	# Show Scheme Card selection for this mission
	EventBus.debug("Showing SchemeCardMenu for mission: " + mission_id)
	
	# Get SchemeCardMenu and show it
	var scheme_card_menu = get_node("/root/SchemeCardMenu")
	if scheme_card_menu:
		scheme_card_menu.show_menu(mission_id)
	else:
		# Create and show SchemeCardMenu
		var scene = load("res://scenes/ui/SchemeCardMenu.tscn")
		if scene:
			var instance = scene.instantiate()
			get_tree().root.add_child(instance)
			instance.show_menu(mission_id)
		else:
			EventBus.debug("Failed to load SchemeCardMenu scene")
			# Fallback: start mission directly
			_start_mission_directly(mission_id)

func _start_mission_directly(mission_id: String) -> void:
	"""Start mission directly (fallback)"""
	var mission_data = MissionData.get_mission(mission_id)
	if mission_data and mission_data.has("scene"):
		var scene_path = mission_data["scene"]
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager:
			scene_manager.change_scene(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		EventBus.debug("No scene path for mission: " + mission_id)

func _on_back_pressed() -> void:
	"""Go back to hideout"""
	EventBus.debug("Back button pressed")
	hide_menu()
	
	# Return to hideout
	EventBus.return_to_hideout.emit()

func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("ui_cancel"):
		# Escape to go back
		_on_back_pressed()

# ===== MISSION BUTTON STYLING =====

func _update_mission_button_styles() -> void:
	"""Update mission button styles"""
	# This would update styles based on mission state
	pass

# ===== ANIMATIONS =====

func _on_mission_button_mouse_entered(button: Button) -> void:
	"""Mission button mouse enter"""
	# Would add hover effect
	pass

func _on_mission_button_mouse_exited(button: Button) -> void:
	"""Mission button mouse exit"""
	# Would remove hover effect
	pass