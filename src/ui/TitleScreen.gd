# TitleScreen.gd
# Title screen for Untitled Heist RPG

extends Control

@onready var new_game_button: Button = $TitleContainer/ButtonContainer/NewGameButton
@onready var continue_button: Button = $TitleContainer/ButtonContainer/ContinueButton
@onready var quit_button: Button = $TitleContainer/ButtonContainer/QuitButton

func _ready() -> void:
	# Connect signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Check if there's a save to continue from
	_update_continue_button()
	
	# Set focus
	new_game_button.grab_focus()
	
	EventBus.debug("TitleScreen loaded")

func _update_continue_button() -> void:
	"""Update continue button state based on save availability"""
	var save_manager = get_node("/root/SaveManager")
	if save_manager:
		var has_save = save_manager.has_any_save()
		continue_button.disabled = not has_save
		if has_save:
			continue_button.tooltip_text = "Continue your adventure"
		else:
			continue_button.tooltip_text = "No save file found"
	else:
		continue_button.disabled = true
		continue_button.tooltip_text = "Save system not available"

func _on_new_game_pressed() -> void:
	"""Start a new game"""
	EventBus.debug("New game button pressed")
	
	# Reset game state
	var game_state = get_node("/root/GameState")
	if game_state:
		# Create fresh game state
		game_state.completed_missions = []
		game_state.failed_attempts = {}
		game_state.available_missions = ["taco_bell_drop"]
		game_state.unlocked_cards = ["bentley_dental_boy", "fish_treat_focus", "jakes_resident_orders"]
		game_state.selected_cards = []
		game_state.collected_polaroids = []
		game_state.intel_points = 0
		game_state.player_health = 100
		game_state.player_max_health = 100
		
		# Reset friend favors
		var known_friends = ["louis", "mere", "jake", "dom", "yordano", "bryce", "jc", "violet", "jinx", "eren", "kiro", "jin"]
		for friend in known_friends:
			game_state.friend_favors[friend] = {
				"helped": false,
				"favors_owed": 0,
				"card_unlocked": ""
			}
	
	# Load hideout scene
	var scene_manager = get_node("/root/SceneManager")
	if scene_manager:
		scene_manager.change_scene("res://scenes/hideout/hideout.tscn")
	else:
		# Fallback: direct scene change
		get_tree().change_scene_to_file("res://scenes/hideout/hideout.tscn")

func _on_continue_pressed() -> void:
	"""Continue from last save"""
	EventBus.debug("Continue button pressed")
	
	var save_manager = get_node("/root/SaveManager")
	if save_manager:
		# Try to load the most recent save
		if save_manager.has_any_save():
			var success = save_manager.load_most_recent()
			if success:
				EventBus.debug("Save loaded successfully")
				# Load hideout scene
				var scene_manager = get_node("/root/SceneManager")
				if scene_manager:
					scene_manager.change_scene("res://scenes/hideout/hideout.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/hideout/hideout.tscn")
			else:
				EventBus.debug("Failed to load save")
				# Show error message (would be implemented in UI)
				pass
		else:
			EventBus.debug("No save file to continue from")
	else:
		EventBus.debug("SaveManager not available")

func _on_quit_pressed() -> void:
	"""Quit the game"""
	EventBus.debug("Quit button pressed")
	get_tree().quit()

func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("ui_cancel"):
		# Escape to quit
		_on_quit_pressed()
	
	if event.is_action_pressed("ui_accept"):
		# Enter to start new game if focused on new game button
		if new_game_button.has_focus():
			_on_new_game_pressed()
		elif continue_button.has_focus() and not continue_button.disabled:
			_on_continue_pressed()

# ===== UI ANIMATIONS =====

func _on_new_game_mouse_entered() -> void:
	"""New game button mouse enter"""
	# Would add visual feedback
	pass

func _on_continue_mouse_entered() -> void:
	"""Continue button mouse enter"""
	# Would add visual feedback
	pass

func _on_quit_mouse_entered() -> void:
	"""Quit button mouse enter"""
	# Would add visual feedback
	pass