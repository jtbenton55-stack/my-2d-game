extends Node2D

var player: Node2D = null
var dog: Node2D = null
var active_camera: Camera2D = null

func _ready() -> void:
	AudioManager.play_music("nocturne_city")
	_spawn_party()
	_setup_camera()
	_ensure_common_ui()
	_setup_contact_prompts()
	_setup_mission_marker_states()
	QuestManager.set_objective("Nocturne City: talk to contacts, choose a job, or return to the hideout.")

func _spawn_party() -> void:
	var spawn := _get_spawn_point()
	player = preload("res://scenes/characters/player.tscn").instantiate()
	add_child(player)
	player.global_position = spawn.global_position if spawn else Vector2(400, 300)
	dog = preload("res://scenes/characters/dog.tscn").instantiate()
	add_child(dog)
	dog.global_position = player.global_position + Vector2(44, 18)

func _get_spawn_point() -> Node2D:
	if GameState.next_spawn != "":
		var spawn_points := get_node_or_null("SpawnPoints")
		if spawn_points:
			var named_spawn := spawn_points.get_node_or_null(GameState.next_spawn) as Node2D
			if named_spawn:
				GameState.next_spawn = "default"
				return named_spawn
	return get_node_or_null("PlayerSpawn") as Node2D

func _setup_camera() -> void:
	active_camera = get_node_or_null("Camera2D") as Camera2D
	if active_camera:
		active_camera.make_current()

func _process(_delta: float) -> void:
	if active_camera and player:
		active_camera.global_position = player.global_position

func _setup_contact_prompts() -> void:
	for child in get_children():
		if child is Area2D:
			child.add_to_group("interactable")

func _setup_mission_marker_states() -> void:
	for child in get_children():
		if not (child is Area2D):
			continue
		var node_name := String(child.name)
		if not node_name.begins_with("MissionTrigger_"):
			continue
		var mission_id := node_name.trim_prefix("MissionTrigger_")
		var label := child.get_node_or_null("Label") as Label
		if label == null:
			continue
		var base_text := _clean_marker_text(label.text)
		if GameState.has_completed(mission_id):
			label.text = "[DONE]\n" + base_text
			label.add_theme_color_override("font_color", Color(0.6, 0.95, 0.65, 1.0))
		elif GameState.available_missions.has(mission_id):
			label.text = base_text
			label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35, 1.0))
		else:
			label.text = "[LOCKED]\n" + base_text
			label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))

func _clean_marker_text(text: String) -> String:
	return text.replace("[DONE]\n", "").replace("[LOCKED]\n", "")

func _unhandled_input(event: InputEvent) -> void:
	if not (InputMap.has_action("interact") and event.is_action_pressed("interact")):
		return
	if player == null:
		return
	var best_area: Area2D = null
	var best_dist := 70.0
	for child in get_children():
		if child is Area2D:
			var dist := player.global_position.distance_to(child.global_position)
			if dist < best_dist:
				best_area = child
				best_dist = dist
	if best_area == null:
		return
	var node_name := String(best_area.name)
	if node_name.begins_with("MissionTrigger_"):
		var mission_id := node_name.trim_prefix("MissionTrigger_")
		if GameState.available_missions.has(mission_id):
			SceneManager.open_scheme_card_menu(mission_id)
		else:
			DialogueManager.start_simple_dialogue([{ "speaker": "City Map", "text": "That job is still buried under favors. Help the right friend first." }])
		return
	if node_name.ends_with("NPC"):
		_start_contact_dialogue(node_name.trim_suffix("NPC").to_lower())
		return
	if node_name == "HideoutEntrance":
		SceneManager.return_to_hideout()
		return

func _start_contact_dialogue(contact_id: String) -> void:
	match contact_id:
		"louis":
			DialogueManager.start_simple_dialogue([{ "speaker": "Louis", "text": "I deliver tacos, secrets, and occasionally fugitives. Depends on the tip." }])
		"yordano":
			DialogueManager.start_simple_dialogue([{ "speaker": "Yordano", "text": "The Velvet Paw upstairs plays jazz. Downstairs, the bass tells the truth." }])
		"mere":
			DialogueManager.start_simple_dialogue([{ "speaker": "Mere", "text": "A bad contract is just a locked door wearing nicer shoes." }])
		"dom":
			DialogueManager.start_simple_dialogue([{ "speaker": "Dom", "text": "In this city, you don't need a crew. You need family." }])
		"jake":
			var line := "As your doctor, I recommend fewer rooftop fistfights. As your boyfriend, I am unfortunately impressed."
			if GameState.failed_attempts.size() > 0:
				line = "I patched up three bruises and one Shiba ego. The ego was harder."
			DialogueManager.start_simple_dialogue([{ "speaker": "Jake", "text": line }])
		_:
			DialogueManager.start_character_dialogue(contact_id)


func _ensure_common_ui() -> void:
	if get_node_or_null("HUD") == null:
		var hud := preload("res://scenes/ui/hud.tscn").instantiate()
		hud.name = "HUD"
		add_child(hud)
	if get_node_or_null("DialogueBox") == null:
		var dialogue := preload("res://scenes/ui/DialogueBox.tscn").instantiate()
		dialogue.name = "DialogueBox"
		add_child(dialogue)
	if get_node_or_null("PauseMenu") == null:
		var pause := preload("res://scenes/ui/pause_menu.tscn").instantiate()
		pause.name = "PauseMenu"
		add_child(pause)
