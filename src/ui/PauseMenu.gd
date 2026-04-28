extends CanvasLayer

@onready var resume_button := get_node_or_null("Panel/VBoxContainer/ResumeButton") as Button
@onready var save_button := get_node_or_null("Panel/VBoxContainer/SaveButton") as Button
@onready var quit_button := get_node_or_null("Panel/VBoxContainer/QuitButton") as Button

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if resume_button:
		resume_button.pressed.connect(_toggle_pause)
	if save_button:
		save_button.pressed.connect(func(): SaveManager.save_game())
	if quit_button:
		quit_button.pressed.connect(_quit_to_hideout)

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("pause") and event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible

func _quit_to_hideout() -> void:
	get_tree().paused = false
	visible = false
	SceneManager.return_to_hideout()
