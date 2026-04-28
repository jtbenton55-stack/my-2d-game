extends Node2D

var player: Node2D = null
var dog: Node2D = null

func _ready() -> void:
	AudioManager.play_music("nocturne_city")
	_spawn_party()
	_setup_camera()
	_ensure_common_ui()
	QuestManager.set_objective("Talk to contacts or step into a mission marker.")

func _spawn_party() -> void:
	var spawn := get_node_or_null("PlayerSpawn") as Node2D
	player = preload("res://scenes/characters/player.tscn").instantiate()
	add_child(player)
	player.global_position = spawn.global_position if spawn else Vector2(400, 300)
	dog = preload("res://scenes/characters/dog.tscn").instantiate()
	add_child(dog)
	dog.global_position = player.global_position + Vector2(44, 18)

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()

func _unhandled_input(event: InputEvent) -> void:
	if not (InputMap.has_action("interact") and event.is_action_pressed("interact")):
		return
	if player == null:
		return
	for child in get_children():
		if child is Area2D and player.global_position.distance_to(child.global_position) < 70.0:
			var node_name := String(child.name)
			if node_name.begins_with("MissionTrigger_"):
				SceneManager.open_scheme_card_menu(node_name.trim_prefix("MissionTrigger_"))
				return
			if node_name.ends_with("NPC"):
				DialogueManager.start_character_dialogue(node_name.trim_suffix("NPC").to_lower())
				return
			if node_name == "HideoutEntrance":
				SceneManager.return_to_hideout()
				return


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
