extends Control

@onready var result_label: Label = $Panel/ResultLabel
@onready var title_label: Label = $TitleLabel
@onready var continue_button: Button = $ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_result_display()
	continue_button.grab_focus()

func _update_result_display() -> void:
	var result: Dictionary = GameState.last_mission_result
	if result.size() == 0:
		result_label.text = "Mission completed!"
		return
	
	var title: String = String(result.get("title", "Mission Complete"))
	var subtitle: String = String(result.get("subtitle", ""))
	var rewards: Array = Array(result.get("rewards", []))
	var success: bool = result.get("success", false) == true
	var rank: String = String(result.get("rank", ""))
	
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1) if success else Color(1, 0.72, 0.35, 1))
	AudioManager.play_music("victory" if success else "cozy_hideout")
	
	var text := subtitle + "\n\n"
	if success and rank != "":
		text += "Mission Rank: " + rank + "\n\n"
	
	if rewards.size() > 0:
		text += "Progress:\n"
		for reward in rewards:
			text += "- " + str(reward) + "\n"
	
	if not success:
		text += "\nJake: As your doctor, I recommend fewer rooftop fistfights.\n"
		text += "Bentley refuses to discuss it, but stays close.\n"
	
	text += "\nTotal Intel: %d" % GameState.intel_points
	
	if success and GameState.crew_members.size() > 2:
		text += "\n\nCrew members: %d" % GameState.crew_members.size()
	
	result_label.text = text

func _on_continue_pressed() -> void:
	GameState.last_mission_result = {}
	SceneManager.return_to_hideout()
