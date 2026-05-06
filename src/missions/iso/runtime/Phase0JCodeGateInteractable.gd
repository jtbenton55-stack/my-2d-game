class_name Phase0JCodeGateInteractable
extends Area2D
## Phase 0J — Real interactable for SAFE_CODE_INPUT_ZONE.
##
## Conforms to the Player.gd interaction contract:
##   - in group "interactable"
##   - has interact(player) method
##   - global_position is queried for distance test (<72 px)
##
## On interact():
##   - finds the linked code-gate StaticBody2D (default
##     `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`)
##   - clears its `collision_layer` so it no longer blocks the player
##   - hides it visually
##   - records `gate_unlocked = true` metadata
##   - emits a dialogue line via DialogueManager so the user can confirm in-game
##
## Idempotent: calling interact() again after unlock simply re-confirms.
##
## Phase 0J rules (per user):
##   - duplicate-scene-only helper under res://src/missions/iso/runtime/
##   - does NOT modify Player.gd, IsoMissionBase, save/load, mission catalog.

signal gate_unlocked()

@export var blocker_path: NodePath = NodePath("../../GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate")
@export var display_name: String = "Code Gate Keypad"
@export var unlock_message: String = "Code accepted -- gate unlocked."
@export var already_message: String = "Gate already unlocked."
@export var interaction_priority: int = 200

var _unlocked: bool = false


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 1
	set_meta("phase_0j_code_gate_interactable", true)


func interact(_player: Node) -> void:
	if _unlocked:
		_dialogue(already_message)
		return
	var blocker := _resolve_blocker()
	if blocker == null:
		_dialogue("Code gate blocker not found. (Phase 0J: blocker_path misconfigured)")
		return
	if blocker is StaticBody2D:
		var sb := blocker as StaticBody2D
		sb.collision_layer = 0
		sb.collision_mask = 0
		# Disable each shape so it definitely stops blocking immediately.
		for c in sb.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = true
			elif c is CollisionPolygon2D:
				(c as CollisionPolygon2D).disabled = true
		if sb is CanvasItem:
			(sb as CanvasItem).visible = false
		sb.set_meta("phase_0j_gate_unlocked", true)
	_unlocked = true
	set_meta("phase_0j_unlocked", true)
	_dialogue(unlock_message)
	gate_unlocked.emit()


func is_interaction_available(_player: Node = null) -> bool:
	return not _unlocked


func get_interaction_priority(_player: Node = null) -> int:
	return interaction_priority


func is_completed() -> bool:
	return _unlocked


func should_show_interaction_prompt() -> bool:
	return not _unlocked


func _resolve_blocker() -> Node:
	if blocker_path.is_empty():
		return null
	return get_node_or_null(blocker_path)


func _dialogue(text: String) -> void:
	# DialogueManager is an autoload; guard for headless smoke.
	var dm := Engine.get_singleton("DialogueManager") if Engine.has_singleton("DialogueManager") else null
	if dm == null:
		# Fallback to printing so we can see it in headless.
		print("[Phase0JCodeGate] %s: %s" % [display_name, text])
		return
	if dm.has_method("start_simple_dialogue"):
		dm.call("start_simple_dialogue", [{ "speaker": display_name, "text": text }])
	else:
		print("[Phase0JCodeGate] %s: %s" % [display_name, text])
