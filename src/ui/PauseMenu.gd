# PauseMenu.gd
# Pause menu with resume, save, quit options

extends CanvasLayer

# References
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	EventBus.debug("PauseMenu loaded")
	
	# Connect signals
	resume_button.pressed.connect(_on_resume_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Hide initially
	visible = false

# Show pause menu
func show_menu() -> void:
	visible = true
	get_tree().paused = true
	EventBus.debug("Pause menu shown")
	
	# Update button states
	_update_button_states()

# Hide pause menu
func hide_menu() -> void:
	visible = false
	get_tree().paused = false
	EventBus.debug("Pause menu hidden")

# Toggle pause menu
func toggle_menu() -> void:
	if visible:
		hide_menu()
	else:
		show_menu()

# Update button states based on game state
func _update_button_states() -> void:
	# Enable save button only in hideout or after mission
	save_button.disabled = GameState.is_in_mission
	
	if GameState.is_in_mission:
		save_button.tooltip_text = "Cannot save during mission"
	else:
		save_button.tooltip_text = "Save game"

# Button handlers
func _on_resume_button_pressed() -> void:
	hide_menu()

func _on_save_button_pressed() -> void:
	if SaveManager.save_game(1):  # Save to slot 1
		EventBus.debug("Game saved from pause menu")
		# Show save confirmation
		_show_save_confirmation()
	else:
		EventBus.debug("Failed to save game")

func _on_quit_button_pressed() -> void:
	EventBus.debug("Quit button pressed")
	
	# Return to hideout if in mission
	if GameState.is_in_mission:
		hide_menu()
		SceneManager.change_to_scene("hideout")
	else:
		# In a real game, this would quit to main menu
		EventBus.debug("Would quit to main menu (not implemented)")

# Show save confirmation
func _show_save_confirmation() -> void:
	EventBus.debug("Save successful!")
	# In a real game, this would show a confirmation message on screen

# Handle input
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_menu()

# Clean up
func cleanup() -> void:
	EventBus.debug("Cleaning up pause menu")
	
	# Disconnect signals
	if resume_button:
		resume_button.pressed.disconnect(_on_resume_button_pressed)
	
	if save_button:
		save_button.pressed.disconnect(_on_save_button_pressed)
	
	if quit_button:
		quit_button.pressed.disconnect(_on_quit_button_pressed)