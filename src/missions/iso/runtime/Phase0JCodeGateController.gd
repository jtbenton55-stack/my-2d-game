@tool
class_name Phase0JCodeGateController
extends Node

@export var blocker_path: NodePath = NodePath("../../GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate")
@export var code_input_ui_path: NodePath = NodePath("../Phase0JCodeInputUI")
@export var debug_hud_path: NodePath = NodePath("../Phase0JDebugHUD")
@export var mission_state_adapter_path: NodePath = NodePath("../Phase0JMissionStateAdapter")
@export var completion_controller_path: NodePath = NodePath("../Phase0KMissionCompletionController")
@export var wrong_code_spawner_path: NodePath = NodePath("../Phase0KBWrongCodeAttackGuardSpawner")
@export var correct_code := "0420"
@export var safe_code_input_id: String = "SAFE_CODE_INPUT_ZONE"
@export var debug_enabled: bool = true

var unlocked := false
var wrong_code_attempts := 0


func _ready() -> void:
	set_meta("generated_by", "Phase0J-C2")
	set_meta("scene_local_only", true)
	lock_gate()


func open_code_ui() -> void:
	var ui := get_node_or_null(code_input_ui_path)
	if ui != null and ui.has_method("open_for_controller"):
		ui.set("correct_code", correct_code)
		ui.call("open_for_controller", self)
		_hud_message("Code gate: enter code")
		return
	_hud_message("Code input UI missing")


func submit_code(value: String) -> bool:
	if value.strip_edges() == correct_code:
		unlock_gate()
		return true
	register_wrong_code_attempt()
	return false


func register_wrong_code_attempt() -> Dictionary:
	wrong_code_attempts += 1
	var spawner := get_node_or_null(wrong_code_spawner_path)
	if spawner != null and spawner.has_method("register_wrong_code_attempt"):
		var result: Dictionary = spawner.call("register_wrong_code_attempt")
		_hud_message("Wrong code attempt %d/%d" % [wrong_code_attempts, int(result.get("threshold", 2))])
		return result
	_hud_message("Wrong code")
	return {
		"wrong_code_attempts": wrong_code_attempts,
		"guard_spawned": false,
		"status": "spawner_missing",
	}


func unlock_gate() -> void:
	var blocker := get_node_or_null(blocker_path)
	if blocker == null:
		push_warning("[Phase0J-C] Code gate blocker missing at %s" % [str(blocker_path)])
		_hud_message("Code gate blocker missing")
		return
	unlocked = true
	blocker.set_meta("unlocked", true)
	blocker.set_meta("unlocked_by", safe_code_input_id)
	if blocker is CollisionObject2D:
		(blocker as CollisionObject2D).collision_layer = 0
		(blocker as CollisionObject2D).collision_mask = 0
	_set_shapes_disabled(blocker, true)
	_set_state_gate(true)
	_set_completion_gate(true)
	_set_gate_hud(true)
	if debug_enabled:
		print("[Phase0J-C2] Code accepted - gate unlocked")
	_hud_message("Code accepted - gate unlocked")


func lock_gate() -> void:
	var blocker := get_node_or_null(blocker_path)
	unlocked = false
	if blocker == null:
		return
	blocker.set_meta("unlocked", false)
	if blocker is CollisionObject2D:
		(blocker as CollisionObject2D).collision_layer = 4
		(blocker as CollisionObject2D).collision_mask = 0
	_set_shapes_disabled(blocker, false)
	_set_state_gate(false)
	_set_completion_gate(false)
	_set_gate_hud(false)


func is_unlocked() -> bool:
	return unlocked


func _set_shapes_disabled(node: Node, disabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = disabled
		elif child is CollisionPolygon2D:
			(child as CollisionPolygon2D).disabled = disabled
		_set_shapes_disabled(child, disabled)


func _hud_message(text: String) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("show_message"):
		hud.call("show_message", text, 3.0)


func _set_gate_hud(gate_unlocked: bool) -> void:
	var hud := get_node_or_null(debug_hud_path)
	if hud != null and hud.has_method("set_gate_state"):
		hud.call("set_gate_state", gate_unlocked)


func _set_state_gate(gate_unlocked: bool) -> void:
	var adapter := get_node_or_null(mission_state_adapter_path)
	if adapter != null and adapter.has_method("set_gate_unlocked"):
		adapter.call("set_gate_unlocked", gate_unlocked)


func _set_completion_gate(gate_unlocked: bool) -> void:
	var controller := get_node_or_null(completion_controller_path)
	if controller != null and controller.has_method("set_code_gate_unlocked"):
		controller.call("set_code_gate_unlocked", gate_unlocked)
