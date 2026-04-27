# MissionResult.gd
# Success/failure screen shown after mission completion
# Connects to EventBus.show_mission_result and show_failure_screen signals

extends Control

@onready var title_label: Label = $MenuContainer/VBoxContainer/Title
@onready var subtitle_label: Label = $MenuContainer/VBoxContainer/Subtitle
@onready var rewards_container: VBoxContainer = $MenuContainer/VBoxContainer/RewardsContainer
@onready var continue_button: Button = $MenuContainer/VBoxContainer/ContinueButton

var _is_success: bool = false
var _mission_id: String = ""

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	hide()
	
	# Connect to EventBus signals
	EventBus.show_mission_result.connect(_on_show_mission_result)
	EventBus.show_failure_screen.connect(_on_show_failure_screen)
	EventBus.mission_completed.connect(_on_mission_completed)
	
	EventBus.debug("MissionResult loaded")

func _on_show_mission_result(success: bool, rewards: Dictionary = {}) -> void:
	_show_result(success, rewards)

func _on_show_failure_screen(message: String, partial_progress: Dictionary = {}) -> void:
	var rewards = {
		"message": message,
		"partial_progress": partial_progress
	}
	_show_result(false, rewards)

func _on_mission_completed(mission_id: String, success: bool) -> void:
	_mission_id = mission_id
	
	var mission_data = MissionData.get_mission(mission_id)
	var rewards = {}
	
	if success:
		rewards = {
			"mission_name": mission_data.get("name", mission_id),
			"reward_card": mission_data.get("reward_card", ""),
			"reward_polaroid": mission_data.get("reward_polaroid", ""),
			"intel_reward": mission_data.get("intel_reward", 0)
		}
	else:
		var failure_count = GameState.get_failure_count(mission_id)
		rewards = {
			"mission_name": mission_data.get("name", mission_id),
			"message": "Mission Failed",
			"intel_gained": 10,
			"failure_count": failure_count,
			"partial_clue": GameState.partial_clues.get(mission_id, 0.0)
		}
	
	_show_result(success, rewards)

func _show_result(success: bool, rewards: Dictionary) -> void:
	_is_success = success
	
	# Clear previous rewards
	for child in rewards_container.get_children():
		child.queue_free()
	
	if success:
		title_label.text = "MISSION ACCOMPLISHED"
		title_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1))
		subtitle_label.text = rewards.get("mission_name", "Mission Complete")
		
		# Show rewards
		var intel = rewards.get("intel_reward", 0)
		if intel > 0:
			_add_reward_line("Intel Gained: +" + str(intel), Color(0.6, 0.8, 1, 1))
		
		var card = rewards.get("reward_card", "")
		if card != "":
			var card_manager = get_node("/root/CardManager")
			var card_name = card
			if card_manager:
				var card_obj = card_manager.get_card(card)
				if card_obj:
					card_name = card_obj.display_name
			_add_reward_line("Card Unlocked: " + card_name, Color(0.8, 0.4, 1, 1))
		
		var polaroid = rewards.get("reward_polaroid", "")
		if polaroid != "":
			_add_reward_line("Polaroid Collected!", Color(1, 0.8, 0.4, 1))
		
		# Show friend helped
		var friend = MissionData.get_friend_for_mission(_mission_id)
		if friend != "":
			_add_reward_line("Friend Helped: " + friend.capitalize(), Color(0.4, 0.8, 0.6, 1))
	else:
		title_label.text = "MISSION FAILED"
		title_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))
		subtitle_label.text = rewards.get("mission_name", "")
		
		var message = rewards.get("message", "You were caught or defeated.")
		_add_reward_line(message, Color(0.8, 0.8, 0.8, 1))
		
		var intel = rewards.get("intel_gained", 10)
		_add_reward_line("Intel Gained: +" + str(intel), Color(0.6, 0.8, 1, 1))
		
		var failure_count = rewards.get("failure_count", 0)
		if failure_count > 0:
			_add_reward_line("Attempt #" + str(failure_count), Color(0.8, 0.6, 0.2, 1))
		
		var clue = rewards.get("partial_clue", 0.0)
		if clue > 0:
			var pct = int(clue * 100)
			_add_reward_line("Clue Progress: " + str(pct) + "%", Color(0.4, 0.6, 0.8, 1))
		
		if failure_count >= 3:
			var hint_card = MissionData.get_hint_card(_mission_id)
			if hint_card != "" and hint_card not in GameState.unlocked_cards:
				_add_reward_line("Hint Card Unlocked!", Color(0.8, 0.4, 1, 1))
	
	continue_button.text = "Continue"
	continue_button.grab_focus()
	show()
	EventBus.debug("MissionResult shown: success=" + str(success))

func _add_reward_line(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	rewards_container.add_child(label)

func _on_continue_pressed() -> void:
	hide()
	
	if _is_success:
		# Return to hideout on success
		EventBus.return_to_hideout.emit()
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager:
			scene_manager.change_to_scene("hideout")
		else:
			get_tree().change_scene_to_file("res://scenes/hideout/hideout.tscn")
	else:
		# On failure, return to hideout to retry
		EventBus.return_to_hideout.emit()
		var scene_manager = get_node("/root/SceneManager")
		if scene_manager:
			scene_manager.change_to_scene("hideout")
		else:
			get_tree().change_scene_to_file("res://scenes/hideout/hideout.tscn")

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_continue_pressed()
