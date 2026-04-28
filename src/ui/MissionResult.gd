extends Control

@onready var result_label: Label = $Panel/ResultLabel
@onready var continue_button: Button = $ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	_update_result_display()
	AudioManager.play_music("victory")

func _update_result_display() -> void:
	var result = GameState.last_mission_result
	if result.size() == 0:
		result_label.text = "Mission completed!"
		return
	
	var title = result.get("title", "Mission Complete")
	var subtitle = result.get("subtitle", "")
	var rewards = result.get("rewards", [])
	var success = result.get("success", false)
	
wa	var text := "[b]" + title + "[/b]\n\n"
	text += subtitle + "\n\n"
	
	if rewards.size() > 0:
		text += "Rewards:\n"
		for reward in rewards:
			text += "- " + str(reward) + "\n"
	
	# Show intel points
	text += "\nTotal Intel: %d" % GameState.intel_points
	
	# Show crew status
	if success and GameState.crew_members.size() > 2:
		text += "\n\nCrew members: %d" % GameState.crew_members.size()
	
	result_label.text = text

func _on_continue_pressed() -> void:
	GameState.last_mission_result = {}
	SceneManager.return_to_hideout()
