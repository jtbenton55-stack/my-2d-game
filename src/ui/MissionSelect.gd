extends Control

const MISSION_BUTTON_SCENE = preload("res://scenes/ui/MissionButton.tscn")

@onready var missions_container: VBoxContainer = $Panel/VBoxContainer
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_missions()
	AudioManager.play_music("mission_select")

func _populate_missions() -> void:
	for child in missions_container.get_children():
		child.queue_free()
	
	for mission_id in GameState.available_missions:
		var mission_data = GameState.mission_catalog.get(mission_id)
		if mission_data:
			var button = MISSION_BUTTON_SCENE.instantiate()
			button.set_mission(mission_id, mission_data)
			button.pressed.connect(_on_mission_selected.bind(mission_id))
			missions_container.add_child(button)

func _on_mission_selected(mission_id: String) -> void:
	SceneManager.open_scheme_card_menu(mission_id)

func _on_back_pressed() -> void:
	SceneManager.return_to_hideout()
