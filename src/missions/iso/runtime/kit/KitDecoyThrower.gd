class_name KitDecoyThrower
extends Node

## Replan Packet 2: deliberate noise verb. Press the throw action (G by
## default, registered at runtime so project.godot stays untouched) to lob a
## kit decoy item toward the mouse cursor. It consumes one item and creates a
## player-team decoy NoiseEvent at the landing point, which guards in range
## will investigate.

const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export var action_throw: StringName = &"kit_throw_decoy"
@export var default_key: Key = KEY_G
@export var decoy_item_id: String = "decoy_coin"
@export var throw_range: float = 240.0
@export var decoy_noise_radius: float = 160.0
@export var decoy_noise_strength: float = 0.8

var last_throw_result: Dictionary = {}
var total_throws: int = 0


func _ready() -> void:
	_ensure_action()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not event.is_action_pressed(String(action_throw)):
		return
	try_throw_decoy(_target_position())
	get_viewport().set_input_as_handled()


func try_throw_decoy(target_position: Vector2) -> Dictionary:
	var player := _find_player()
	if player == null:
		last_throw_result = _result(false, "player_missing", "No player found.")
		return last_throw_result
	if not MissionInventory.has_item(decoy_item_id):
		last_throw_result = _result(false, "no_decoy_item", "No %s in the kit." % decoy_item_id)
		EventBus.objective_updated.emit("No decoy to throw.")
		return last_throw_result
	var origin := player.global_position
	var landing := target_position
	if origin.distance_to(landing) > throw_range:
		landing = origin + (landing - origin).normalized() * throw_range
	MissionInventory.remove_item(decoy_item_id, 1)
	total_throws += 1
	var event := NoiseEventHelper.make_event(
		"kit_decoy_%d" % total_throws,
		"kit_decoy_throw",
		landing,
		decoy_noise_radius,
		decoy_noise_strength,
		"decoy",
		"player",
		{"item_id": decoy_item_id, "thrown_from": origin}
	)
	if EventBus.has_signal("mission_noise_emitted"):
		EventBus.mission_noise_emitted.emit(event)
	EventBus.objective_updated.emit("Decoy thrown.")
	last_throw_result = _result(true, "decoy_thrown", "Decoy thrown to %s." % str(landing), {"noise_event": event})
	return last_throw_result


func _target_position() -> Vector2:
	var player := _find_player()
	var viewport := get_viewport()
	if viewport != null and player != null:
		return player.get_global_mouse_position()
	return player.global_position if player != null else Vector2.ZERO


func _ensure_action() -> void:
	var action := String(action_throw)
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = default_key
	InputMap.action_add_event(action, key_event)


func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node2D


func _result(ok: bool, code: String, message: String, details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "details": details}
