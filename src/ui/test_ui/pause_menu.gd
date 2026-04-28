extends Control

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	resume_button.pressed.connect(_resume_game)
	exit_button.pressed.connect(_exit_to_hideout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func _pause_game() -> void:
	get_tree().paused = true
	show()
	resume_button.grab_focus()

func _resume_game() -> void:
	get_tree().paused = false
	hide()

func _exit_to_hideout() -> void:
	get_tree().paused = false
	SceneManager.return_to_hideout()
