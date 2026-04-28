extends Node2D

@export var mission_id := "test_mission"
@export var guard_count := 0
@export var auto_start_mission := true
@export var objective_text := "Reach the exit."

var player: Node2D = null
var dog: Node2D = null
var is_complete := false
var is_failed := false

func _ready() -> void:
	_apply_card_effects()
	_spawn_player_if_needed()
	_spawn_dog_if_needed()
	_spawn_default_enemies()
	_setup_camera()
	_setup_exit_zone()
	if auto_start_mission and GameState.current_mission_id == "":
		GameState.start_mission(get_mission_id())
	QuestManager.set_objective(objective_text, get_mission_id())
	if not EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.connect(_on_player_died)
	_ensure_common_ui()
	EventBus.debug("Loaded level: " + name + " mission=" + get_mission_id())

func _apply_card_effects() -> void:
	# Apply detection reduction from cards
	var detection_reduction: float = CardEffects.get_guard_detection_reduction()
	if detection_reduction > 0.0:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy.has_method("set_detection_multiplier"):
				enemy.set_detection_multiplier(1.0 - detection_reduction)

func get_mission_id() -> String:
	if mission_id != "":
		return mission_id
	return String(name).to_lower().replace(" ", "_")

func _spawn_player_if_needed() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		var scene := preload("res://scenes/characters/player.tscn")
		player = scene.instantiate()
		add_child(player)
	var spawn := get_node_or_null("PlayerSpawn") as Node2D
	if spawn:
		player.global_position = spawn.global_position

func _spawn_dog_if_needed() -> void:
	dog = get_tree().get_first_node_in_group("bentley") as Node2D
	if dog == null:
		var scene := preload("res://scenes/characters/dog.tscn")
		dog = scene.instantiate()
		add_child(dog)
	if player:
		dog.global_position = player.global_position + Vector2(42, 18)

func _spawn_default_enemies() -> void:
	if guard_count <= 0:
		return
	var enemy_scene: PackedScene = load("res://scenes/characters/guard.tscn")
	if enemy_scene == null:
		return
	for i in range(guard_count):
		var enemy: Node2D = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = Vector2(280 + i * 80, 280)

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()
		if player:
			camera.global_position = player.global_position

func _setup_exit_zone() -> void:
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone and exit_zone.has_signal("body_entered"):
		exit_zone.body_entered.connect(_on_exit_zone_body_entered)

func complete_level() -> void:
	if is_complete or is_failed:
		return
	is_complete = true
	var result := GameState.complete_mission(get_mission_id())
	SceneManager.show_mission_result(result)

func fail_level(reason = "Not the cleanest getaway.") -> void:
	if is_complete or is_failed:
		return
	is_failed = true
	var result := GameState.fail_mission(get_mission_id(), reason)
	SceneManager.show_mission_result(result)

func _on_exit_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		complete_level()

func _on_player_died() -> void:
	if GameState.is_in_mission:
		fail_level("Jake patched up the damage. Bentley remains judgmental.")


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
