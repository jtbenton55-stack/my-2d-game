extends Control

var _starting_game := false
var _mouse_was_down := false

@onready var menu_container: VBoxContainer = $VBoxContainer
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var settings_panel: Panel = $SettingsPanel
@onready var volume_slider: HSlider = $SettingsPanel/MasterSlider
@onready var back_button: Button = $SettingsPanel/BackButton

func _ready() -> void:
	set_process(true)
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)

	continue_button.visible = SaveManager.has_any_save()
	settings_panel.visible = false
	_setup_volume_slider()
	new_game_button.grab_focus()
	AudioManager.play_music("title_theme")

func _process(_delta: float) -> void:
	var mouse_is_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_is_down and not _mouse_was_down:
		_handle_mouse_press(get_global_mouse_position())
	_mouse_was_down = mouse_is_down
	
	if not settings_panel.visible and not _starting_game:
		if Input.is_action_just_pressed("ui_accept"):
			var focused := get_viewport().gui_get_focus_owner()
			if focused == new_game_button:
				_on_new_game_pressed()
			elif focused == continue_button and continue_button.visible:
				_on_continue_pressed()
			elif focused == settings_button:
				_on_settings_pressed()
			elif focused == quit_button:
				_on_quit_pressed()
		
		if Input.is_key_pressed(KEY_N):
			_on_new_game_pressed()
		elif Input.is_key_pressed(KEY_C) and continue_button.visible:
			_on_continue_pressed()
		elif Input.is_key_pressed(KEY_S):
			_on_settings_pressed()
		elif Input.is_key_pressed(KEY_Q):
			_on_quit_pressed()

func _handle_mouse_press(mouse_position: Vector2) -> void:
	if settings_panel.visible:
		if back_button.get_global_rect().has_point(mouse_position):
			_on_back_pressed()
		return
	if new_game_button.get_global_rect().has_point(mouse_position):
		_on_new_game_pressed()
	elif continue_button.visible and continue_button.get_global_rect().has_point(mouse_position):
		_on_continue_pressed()
	elif settings_button.get_global_rect().has_point(mouse_position):
		_on_settings_pressed()
	elif quit_button.get_global_rect().has_point(mouse_position):
		_on_quit_pressed()

func _setup_volume_slider() -> void:
	var master_bus_idx := AudioServer.get_bus_index("Master")
	if master_bus_idx == -1:
		return
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.001
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_idx))

func _on_new_game_pressed() -> void:
	if _starting_game:
		return
	_starting_game = true
	SceneManager.start_new_game()

func _on_continue_pressed() -> void:
	if _starting_game:
		return
	_starting_game = true
	SceneManager.continue_game()

func _on_settings_pressed() -> void:
	menu_container.visible = false
	settings_panel.visible = true
	back_button.grab_focus()

func _on_back_pressed() -> void:
	settings_panel.visible = false
	menu_container.visible = true
	settings_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	var master_bus_idx := AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))
