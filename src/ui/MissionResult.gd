extends Control

@onready var title_label := get_node_or_null("MenuContainer/VBoxContainer/Title") as Label
@onready var subtitle_label := get_node_or_null("MenuContainer/VBoxContainer/Subtitle") as Label
@onready var rewards_container := get_node_or_null("MenuContainer/VBoxContainer/RewardsContainer") as VBoxContainer
@onready var continue_button := get_node_or_null("MenuContainer/VBoxContainer/ContinueButton") as Button

func _ready() -> void:
	if continue_button:
		continue_button.pressed.connect(SceneManager.return_to_hideout)
	_show_result()

func _show_result() -> void:
	var result := GameState.last_mission_result
	if title_label:
		title_label.text = String(result.get("title", "Back to the Hideout"))
	if subtitle_label:
		subtitle_label.text = String(result.get("subtitle", "Bentley refuses to discuss it."))
	if rewards_container:
		for child in rewards_container.get_children():
			child.queue_free()
		for reward in result.get("rewards", []):
			var label := Label.new()
			label.text = "• " + String(reward)
			rewards_container.add_child(label)
