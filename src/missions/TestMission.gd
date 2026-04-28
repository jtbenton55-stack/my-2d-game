extends Node2D

var player: Node2D = null
var dog: Node2D = null
var has_loot := false

@onready var exit_zone: Area2D = $ExitZone
@onready var complete_button: Button = $UI/CompleteButton

func _ready() -> void:
	AudioManager.play_music("mission")
	_spawn_player_and_dog()
	_setup_exit_zone()
	_spawn_loot()
	complete_button.pressed.connect(_on_complete_pressed)

func _spawn_player_and_dog() -> void:
	var player_scene := preload("res://scenes/characters/player.tscn")
	var dog_scene := preload("res://scenes/characters/dog.tscn")
	var spawn := $PlayerSpawn as Node2D
	
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawn.global_position if spawn else Vector2(100, 300)
	
	dog = dog_scene.instantiate()
	add_child(dog)
	dog.global_position = player.global_position + Vector2(-60, 40)
	
	var camera := $Camera2D as Camera2D
	if camera:
		camera.make_current()

func _setup_exit_zone() -> void:
	exit_zone.body_entered.connect(_on_exit_zone_entered)

func _spawn_loot() -> void:
	var loot := Area2D.new()
	loot.name = "Loot"
	loot.position = Vector2(500, 300)
	
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	shape.shape = rect
	loot.add_child(shape)
	
	var outer := ColorRect.new()
	outer.custom_minimum_size = Vector2(48, 48)
	outer.color = Color(0.8, 0.6, 0, 1)
	outer.position = Vector2(-24, -24)
	loot.add_child(outer)
	
	var inner := ColorRect.new()
	inner.custom_minimum_size = Vector2(32, 32)
	inner.color = Color(1, 0.9, 0.3, 1)
	inner.position = Vector2(-16, -16)
	loot.add_child(inner)
	
	var label := Label.new()
	label.text = "[ LOOT ]"
	label.position = Vector2(-40, -55)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	loot.add_child(label)
	
	$LootContainer.add_child(loot)
	loot.body_entered.connect(_on_loot_collected)

func _on_loot_collected(body: Node2D) -> void:
	if body.is_in_group("player") and not has_loot:
		has_loot = true
		$UI/MissionLabel.text = "Mission: Get to the exit!"
		$LootContainer/Loot.queue_free()

func _on_exit_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player") and has_loot:
		complete_button.visible = true

func _on_complete_pressed() -> void:
	var result := {
		"mission_id": GameState.current_mission_id,
		"success": true,
		"loot_collected": 1,
		"time": 0.0
	}
	
	if not GameState.completed_missions.has(GameState.current_mission_id):
		GameState.completed_missions.append(GameState.current_mission_id)
	
	var mission_data = GameState.mission_catalog.get(GameState.current_mission_id, {})
	for card_id in mission_data.get("reward_cards", []):
		GameState.unlock_card(card_id)
	
	SceneManager.show_mission_result(result)
