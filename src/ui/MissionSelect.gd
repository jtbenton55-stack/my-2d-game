extends Control

@onready var missions_container := get_node_or_null("MenuContainer/VBoxContainer/MissionsContainer") as VBoxContainer
@onready var back_button := get_node_or_null("MenuContainer/VBoxContainer/ButtonContainer/BackButton") as Button

func _ready() -> void:
	if back_button:
		back_button.pressed.connect(SceneManager.return_to_hideout)
	_build_mission_buttons()

func _build_mission_buttons() -> void:
	if missions_container == null:
		return
	for child in missions_container.get_children():
		child.queue_free()
	for mission_id in GameState.get_available_mission_ids():
		var info := GameState.get_mission_info(mission_id)
		var button := Button.new()
		button.text = String(info.get("name", mission_id)) + (" ✓" if GameState.has_completed(mission_id) else "")
		button.tooltip_text = String(info.get("description", ""))
		button.pressed.connect(func(): _on_mission_pressed(mission_id))
		missions_container.add_child(button)
	if missions_container.get_child_count() == 0:
		var label := Label.new()
		label.text = "No jobs available yet."
		missions_container.add_child(label)

func _on_mission_pressed(mission_id: String) -> void:
	SceneManager.open_scheme_card_menu(mission_id)
