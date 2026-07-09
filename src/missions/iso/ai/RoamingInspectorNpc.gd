class_name RoamingInspectorNpc
extends Node2D

## Replan Packet 3: inspections come to you. This NPC does telegraphed rounds
## on a timer, walks to the player, and evaluates its InspectionRuleSet on
## arrival. Being mid-task (alibi window) auto-passes. Failing bumps alert
## exposure, confiscates the most incriminating item, and opens the cover
## challenge prompt when one is present.

signal rounds_started
signal inspection_finished(passed: bool, result: Dictionary)

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var inspector_id: StringName = &"roaming_inspector"
@export var rounds_interval: float = 45.0
@export var announce_text: String = "Manager: Doing my rounds!"
@export var move_speed: float = 130.0
@export var arrive_distance: float = 56.0
@export var inspection_rules: Resource
@export var fail_exposure: float = 0.5
@export var confiscate_on_fail: bool = true
@export var open_challenge_on_fail: bool = true
@export var start_active: bool = true

var state: String = "posted"
var last_inspection_result: Dictionary = {}
var inspections_run: int = 0

var _post_position := Vector2.ZERO
var _rounds_timer := 0.0


func _ready() -> void:
	add_to_group("roaming_inspector")
	_post_position = global_position
	_rounds_timer = rounds_interval
	set_process(start_active and not Engine.is_editor_hint())


func _process(delta: float) -> void:
	match state:
		"posted":
			_rounds_timer -= delta
			if _rounds_timer <= 0.0:
				force_start_rounds()
		"walking":
			var player := _find_player()
			if player == null:
				_return_to_post()
				return
			var target := (player as Node2D).global_position
			global_position = global_position.move_toward(target, move_speed * delta)
			if global_position.distance_to(target) <= arrive_distance:
				_arrive_and_inspect(player)
		"returning":
			global_position = global_position.move_toward(_post_position, move_speed * delta)
			if global_position.distance_to(_post_position) <= 4.0:
				state = "posted"
				_rounds_timer = rounds_interval


func force_start_rounds() -> void:
	state = "walking"
	rounds_started.emit()
	EventBus.objective_updated.emit(announce_text)
	EventBus.debug("Roaming inspector %s started rounds." % String(inspector_id))


func _arrive_and_inspect(player: Node) -> void:
	inspections_run += 1
	var passed := false
	var result: Dictionary = {}
	if _is_alibi_active():
		passed = true
		result = {
			"ok": true,
			"code": "inspection_passed",
			"message": "You looked busy. They moved on.",
			"details": {"reason": "alibi_window"},
		}
	elif inspection_rules != null and inspection_rules.has_method("evaluate"):
		result = inspection_rules.call("evaluate", {"actor": player})
		passed = bool(result.get("ok", false))
	else:
		passed = true
		result = {"ok": true, "code": "inspection_passed", "message": "Nothing worth checking.", "details": {}}
	last_inspection_result = result
	SocialStealthAdapterScript.record_inspection(String(inspector_id), passed, result, {})
	if passed:
		EventBus.objective_updated.emit(String(result.get("message", "Story checks out.")))
	else:
		_apply_fail_consequences(result)
	inspection_finished.emit(passed, result)
	_return_to_post()


func _apply_fail_consequences(result: Dictionary) -> void:
	EventBus.objective_updated.emit(String(result.get("message", "Something does not add up.")))
	var controller := _alert_controller()
	if controller != null and controller.has_method("accumulate_exposure") and fail_exposure > 0.0:
		controller.call("accumulate_exposure", String(inspector_id), fail_exposure, "failed_inspection")
	if confiscate_on_fail:
		_confiscate_most_incriminating()
	if open_challenge_on_fail:
		var prompt := _challenge_prompt()
		if prompt != null and prompt.has_method("open_challenge"):
			prompt.call("open_challenge", "Inspector: Care to explain yourself?")


func _confiscate_most_incriminating() -> Dictionary:
	var snapshot := MissionInventory.get_snapshot()
	var items: Dictionary = snapshot.get("items", {})
	var worst_id := ""
	var worst_weight := 0
	for key in items.keys():
		var summary: Dictionary = items[key]
		var weight := int(summary.get("incriminating", 0))
		if weight > worst_weight:
			worst_weight = weight
			worst_id = String(key)
	if worst_id == "":
		return {"ok": false, "code": "nothing_to_confiscate"}
	var removed := MissionInventory.remove_item(worst_id, 1)
	EventBus.objective_updated.emit("Confiscated: %s." % worst_id)
	return removed


func _is_alibi_active() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var runtime := tree.get_first_node_in_group("cover_meter_runtime")
	return runtime != null and runtime.has_method("is_alibi_active") and bool(runtime.call("is_alibi_active"))


func _return_to_post() -> void:
	state = "returning"


func _challenge_prompt() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("cover_challenge_prompt")


func _alert_controller() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("iso_alert_controller")


func _find_player() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player")
