extends Control

var _starting_new_game := false
var _mouse_was_down := false

@onready var new_game_button: Button = $TitleContainer/ButtonContainer/NewGameButton
@onready var continue_button: Button = $TitleContainer/ButtonContainer/ContinueButton
@onready var quit_button: Button = $TitleContainer/ButtonContainer/QuitButton

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	continue_button.disabled = not SaveManager.has_any_save()
	new_game_button.grab_focus()
	
	AudioManager.play_music("title_theme")

func _process(_delta: float) -> void:
	var mouse_is_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_is_down and not _mouse_was_down and new_game_button.get_global_rect().has_point(get_global_mouse_position()):
		_start_new_game()
	if Input.is_action_just_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == new_game_button:
		_start_new_game()
	_mouse_was_down = mouse_is_down

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if new_game_button.get_global_rect().has_point(event.position):
			_start_new_game()
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == new_game_button:
		_start_new_game()

func _on_new_game_pressed() -> void:
	_start_new_game()

func _start_new_game() -> void:
	if _starting_new_game:
		return
	_starting_new_game = true
	SceneManager.start_new_game()

func _on_continue_pressed() -> void:
	SceneManager.continue_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
