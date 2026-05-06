class_name Phase0IRouteSafeguard
extends Node
## Phase 0I — Runtime Route/Vent/Stairs Player-Teleport Safeguard.
##
## At Phase 0G/0H the player gets teleported when they walk through the
## Bentley vent area. Root cause is `IsoMissionBase._spawn_transition_placeholder()`
## which creates Area2D `MissionTransitionPlaceholder` instances whose
## `_ready()` sets `auto_trigger_on_enter = transition_id.begins_with("route_")`.
## For `route_vent_return` and `route_louis_return` this means walking through
## the area teleports the player to the route entry/return spawn — which is wrong
## for a player-only walktest because Bentley/Louis route mechanics are not
## yet implemented.
##
## This safeguard runs at runtime (NOT in the editor) and AFTER `IsoMissionBase`
## has spawned its runtime triggers. It finds:
##   GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_vent_return
##   GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_louis_return
## and disables them for the PLAYER body specifically:
##   - monitoring = false
##   - collision_mask = 0
##   - auto_trigger_on_enter = false (in case the runtime script re-checks it)
##
## It also handles the `IsoMissionBase._spawn_code_gate_blockers()` legacy
## blocker `CodeGateBarrier_garage_office_code` which is positioned at an
## obsolete cell (21, -3) on the *new* expanded map and would create an
## invisible wall in walkable space. We disable its collision_layer.
##
## A Phase 0I generated `GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate`
## StaticBody2D replaces it deterministically at the correct cell.
##
## Phase 0I rules (per user):
##   - New isolated runtime/helper under res://src/missions/iso/runtime/, allowed.
##   - Does NOT modify IsoMissionBase, IsoMissionMarker, save/load, mission catalog.
##   - Idempotent.

@export var safeguard_targets: Array[String] = [
	"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_vent_return",
	"GameplayRoot/RuntimeSystems/TransitionTriggers/Transition_route_louis_return",
]

@export var legacy_blockers_to_disable: Array[String] = [
	"GameplayRoot/RuntimeSystems/TransitionTriggers/CodeGateBarrier_garage_office_code",
]

## TileMapLayer paths whose `collision_enabled` should be forced TRUE at runtime
## even after `IsoMissionBase._apply_blockout_tileset()` resets them to `false`.
##
## `IsoMissionBase._apply_blockout_tileset()` (in unmodifiable global runtime)
## hard-codes `layer.collision_enabled = path.contains("GameplayCollisionLayer")`
## for every TileMapLayer it knows about, which disables WallLayer collision at
## runtime. This safeguard re-enables collision on the new LayoutRoot/WallLayer
## after that init runs.
@export var force_collision_enabled_paths: Array[String] = [
	"GameplayRoot/LayoutRoot/WallLayer",
]

@export var safeguard_reason: String = "phase_0i_player_walktest_no_bentley_or_louis_route_yet"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Defer so that IsoMissionBase has time to spawn its runtime children.
	call_deferred("_apply_safeguards")


func _apply_safeguards() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		# When the duplicate is loaded as the "current_scene", fall through.
		# When loaded headlessly via add_child(), use the parent of self.
		root = get_parent()
		while root != null and root.get_parent() != null and root.get_parent() != tree.get_root():
			root = root.get_parent()
	if root == null:
		root = tree.get_root()
	if root == null:
		return
	for path in safeguard_targets:
		var node := root.get_node_or_null(path)
		if node == null:
			continue
		_disable_player_teleport_trigger(node)
	for path in legacy_blockers_to_disable:
		var node := root.get_node_or_null(path)
		if node == null:
			continue
		_disable_legacy_static_blocker(node)
	for path in force_collision_enabled_paths:
		var node := root.get_node_or_null(path)
		if node is TileMapLayer:
			(node as TileMapLayer).collision_enabled = true
			node.set_meta("phase_0i_wall_collision_forced_enabled", true)


func _disable_player_teleport_trigger(node: Node) -> void:
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = false
		area.collision_mask = 0
		# MissionTransitionPlaceholder/MissionRouteAccessPoint expose this:
		if area.get("auto_trigger_on_enter") != null:
			area.set("auto_trigger_on_enter", false)
		# Also disable any pending interact() side effect for click:
		if area.is_in_group("interactable"):
			area.remove_from_group("interactable")
		area.set_meta("phase_0i_player_teleport_disabled", true)
		area.set_meta("phase_0i_safeguard_reason", safeguard_reason)


func _disable_legacy_static_blocker(node: Node) -> void:
	if node is StaticBody2D:
		var body := node as StaticBody2D
		body.collision_layer = 0
		body.collision_mask = 0
		if body is CanvasItem:
			(body as CanvasItem).visible = false
		body.set_meta("phase_0i_legacy_blocker_disabled", true)
		body.set_meta("phase_0i_safeguard_reason", "legacy_blocker_at_obsolete_cell_replaced_by_generated_runtime_collision")
