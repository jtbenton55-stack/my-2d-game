extends Node2D

@export var mission_id := "test_mission"
@export var guard_count := 0
@export var auto_start_mission := true
@export var objective_text := "Reach the exit."

var player: Node2D = null
var dog: Node2D = null
var is_complete := false
var is_failed := false
var active_camera: Camera2D = null

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
	var detection_reduction: float = _card_float("get_guard_detection_reduction", 0.0)
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
	var spawn := _get_spawn_point()
	if spawn:
		player.global_position = spawn.global_position

func _get_spawn_point() -> Node2D:
	var spawn_name: String = GameState.next_spawn
	if spawn_name != "":
		var spawn_points := get_node_or_null("SpawnPoints")
		if spawn_points:
			var named_spawn := spawn_points.get_node_or_null(spawn_name) as Node2D
			if named_spawn:
				GameState.next_spawn = "default"
				return named_spawn
	return get_node_or_null("PlayerSpawn") as Node2D

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
	active_camera = get_node_or_null("Camera2D") as Camera2D
	if active_camera:
		active_camera.make_current()
		if player:
			active_camera.global_position = player.global_position

func _process(_delta: float) -> void:
	if active_camera and player:
		active_camera.global_position = player.global_position

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


func award_hidden_polaroid(polaroid_id: String) -> void:
	CollectibleManager.collect_polaroid(polaroid_id)


func award_perfect_polaroid(polaroid_id: String, _reason: String = "") -> void:
	CollectibleManager.collect_polaroid(polaroid_id)


func discover_mission_clue(clue_id: String, data: Dictionary) -> void:
	GameState.ensure_and_discover_sterling_clue(clue_id, data)


func spawn_poop_bags_at_global_positions(positions: Array[Vector2]) -> void:
	var ps := load("res://scenes/collectibles/PoopBagPickup.tscn") as PackedScene
	if ps == null:
		return
	for pos in positions:
		var bag := ps.instantiate() as Node2D
		if bag == null:
			continue
		add_child(bag)
		bag.global_position = pos


func _ensure_common_ui() -> void:
	if get_node_or_null("HUD") == null:
		var hud := preload("res://scenes/ui/hud.tscn").instantiate()
		hud.name = "HUD"
		add_child(hud)
	if get_node_or_null("DialogueBox") == null:
		var dialogue := preload("res://scenes/ui/DialogueBox.tscn").instantiate()
		dialogue.name = "DialogueBox"
		add_child(dialogue)
	if get_node_or_null("ControlsOverlay") == null:
		var overlay_scene := load("res://src/ui/test_ui/controls_overlay.tscn") as PackedScene
		if overlay_scene:
			var overlay := overlay_scene.instantiate()
			overlay.name = "ControlsOverlay"
			add_child(overlay)
	if get_node_or_null("PauseMenu") == null:
		var pause_scene := load("res://src/ui/test_ui/pause_menu.tscn") as PackedScene
		if pause_scene:
			var pause := pause_scene.instantiate()
			pause.name = "PauseMenu"
			add_child(pause)

func _card_float(method_name: String, fallback: float) -> float:
	var card_effects = get_node_or_null("/root/CardEffects")
	if card_effects != null and card_effects.has_method(method_name):
		return float(card_effects.call(method_name))
	return fallback
