class_name MissionEncounterTrigger
extends Area2D

const TacoBellDialogue := preload("res://src/missions/iso/runtime/TacoBellDialogue.gd")

signal encounter_triggered(encounter_id: String)

@export var encounter_id: String = ""
@export var one_shot := true
@export var trigger_alert := true
@export var spawn_guard := false
@export var spawn_scene_path: String = "res://scenes/characters/guard.tscn"
@export var spawn_position: Vector2 = Vector2.ZERO
@export var shake_intensity: float = 4.0
@export var shake_duration: float = 0.16
@export var dialogue_line: String = "Ambush!"

var _triggered := false
var _controller: MissionAlertController = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("iso_encounter_trigger")
	body_entered.connect(_on_body_entered)
	_controller = _find_controller()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	var scene := get_tree().current_scene
	if one_shot and scene != null and scene.has_method("is_runtime_encounter_triggered"):
		if scene.call("is_runtime_encounter_triggered", encounter_id) == true:
			_triggered = true
			monitoring = false
			return
	_triggered = true
	if scene != null and scene.has_method("mark_runtime_encounter_triggered"):
		scene.call("mark_runtime_encounter_triggered", encounter_id)
	encounter_triggered.emit(encounter_id)
	if dialogue_line != "":
		var ambush := TacoBellDialogue.line("ambush_trigger_001", dialogue_line, "Garage")
		DialogueManager.start_simple_dialogue([ambush])
	if trigger_alert and _controller != null:
		_controller.set_alert_state("alerted")
		_controller.record_alarm_event("ambush", encounter_id)
	if spawn_guard:
		_spawn_encounter_guard()
	EventBus.screen_shake.emit(shake_intensity, shake_duration)
	if one_shot:
		monitoring = false


func _spawn_encounter_guard() -> void:
	var packed := load(spawn_scene_path) as PackedScene
	if packed == null:
		return
	var guard := packed.instantiate() as Node2D
	if guard == null:
		return
	var parent := get_tree().current_scene.get_node_or_null("EntityRoot/Enemies")
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(guard)
	guard.global_position = spawn_position if spawn_position != Vector2.ZERO else global_position + Vector2(40, 0)
	var sprite := guard.get_node_or_null("AnimatedSprite2D") as Node2D
	if sprite != null:
		sprite.scale = Vector2.ONE * 0.86
	var collider := guard.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null and collider.shape is RectangleShape2D:
		(collider.shape as RectangleShape2D).size = Vector2(24, 24)


func _find_controller() -> MissionAlertController:
	var node := get_tree().get_first_node_in_group("iso_alert_controller")
	if node is MissionAlertController:
		return node
	return null
