extends Control

@onready var new_game_button := get_node_or_null("TitleContainer/ButtonContainer/NewGameButton") as Button
@onready var continue_button := get_node_or_null("TitleContainer/ButtonContainer/ContinueButton") as Button
@onready var quit_button := get_node_or_null("TitleContainer/ButtonContainer/QuitButton") as Button

func _ready() -> void:
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
		new_game_button.grab_focus()
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.disabled = not SaveManager.has_any_save()
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	AudioManager.play_music("title_theme")

func _on_new_game_pressed() -> void:
	SceneManager.start_new_game()

func _on_continue_pressed() -> void:
	SceneManager.continue_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
