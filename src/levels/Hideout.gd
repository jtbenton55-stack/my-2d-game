extends Node2D

var player: Node2D = null
var dog: Node2D = null

func _ready() -> void:
	AudioManager.play_music("cozy_hideout")
	_spawn_player_and_dog()
	_setup_camera()
	_setup_interactables()
	_ensure_common_ui()
	QuestManager.set_objective("Use the mission board to choose the next job.")
	if GameState.failed_attempts.size() > 0:
		DialogueManager.start_simple_dialogue([{ "speaker": "Jake", "text": "Welcome back. I patched up the plan, the alibi, and Bentley's ego." }])

func _spawn_player_and_dog() -> void:
	var spawn := get_node_or_null("PlayerSpawn") as Node2D
	var player_scene := preload("res://scenes/characters/player.tscn")
	var dog_scene := preload("res://scenes/characters/dog.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawn.global_position if spawn else Vector2(400, 300)
	dog = dog_scene.instantiate()
	add_child(dog)
	dog.global_position = player.global_position + Vector2(44, 18)

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()

func _setup_interactables() -> void:
	var heist_zone := get_node_or_null("HeistStartZone")
	if heist_zone:
		heist_zone.add_to_group("interactable")
		heist_zone.set_meta("interaction", "mission_board")
		heist_zone.body_entered.connect(func(body):
			if body.is_in_group("player"):
				EventBus.objective_updated.emit("Press E at the mission board to choose a job.")
		)
	var crew := get_node_or_null("CrewMember")
	if crew:
		crew.add_to_group("interactable")
		crew.set_meta("interaction", "crew")

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("interact") and event.is_action_pressed("interact"):
		if player == null:
			return
		var heist_zone := get_node_or_null("HeistStartZone") as Node2D
		if heist_zone and player.global_position.distance_to(heist_zone.global_position) < 90.0:
			SceneManager.open_mission_select()
			return
		var crew := get_node_or_null("CrewMember") as Node2D
		if crew and player.global_position.distance_to(crew.global_position) < 72.0:
			DialogueManager.start_simple_dialogue([{ "speaker": "Mere", "text": "A real plan is just friendship with a calendar invite." }])


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
