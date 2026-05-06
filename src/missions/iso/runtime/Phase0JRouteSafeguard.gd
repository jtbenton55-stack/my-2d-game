class_name Phase0JRouteSafeguard
extends Node
## Phase 0J — Comprehensive runtime route/vent safeguard.
##
## Like Phase0IRouteSafeguard, but instead of a hardcoded short list it scans
## every Area2D under `GameplayRoot/RuntimeSystems/TransitionTriggers/` and
## disables player-teleport behavior for any transition whose name or
## `transition_id` matches a Bentley/Louis route pattern. This catches all four
## A/B/C/D Bentley vent return triggers + the Louis return trigger without
## maintenance.
##
## It also force-enables `WallLayer.collision_enabled = true` after
## `IsoMissionBase._apply_blockout_tileset()` resets it to false, and disables
## any legacy single-cell code-gate static blocker the global runtime spawned at
## an obsolete cell, so only the Phase 0J generated corridor blocker remains.
##
## Phase 0J rules (per user):
##   - duplicate-scene-only helper under res://src/missions/iso/runtime/.
##   - does NOT modify IsoMissionBase, IsoMissionMarker, Player, save/load.
##   - idempotent.

@export var transition_root_path: String = "GameplayRoot/RuntimeSystems/TransitionTriggers"

## Substrings that mark a transition as a Bentley/Louis route (case-insensitive).
@export var route_name_patterns: Array[String] = [
	"route_vent",
	"route_louis",
	"vent_in",
	"vent_out",
	"vent_return",
	"louis_return",
]

@export var legacy_blockers_to_disable: Array[String] = [
	"GameplayRoot/RuntimeSystems/TransitionTriggers/CodeGateBarrier_garage_office_code",
]

@export var force_collision_enabled_paths: Array[String] = [
	"GameplayRoot/LayoutRoot/WallLayer",
]

@export var safeguard_reason: String = "phase_0j_player_walktest_routes_disabled"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_apply_safeguards")


func _apply_safeguards() -> void:
	var root := _find_scene_root()
	if root == null:
		return
	var transitions := root.get_node_or_null(transition_root_path)
	if transitions != null:
		_walk_and_disable_routes(transitions)
	for path in legacy_blockers_to_disable:
		var node := root.get_node_or_null(path)
		if node == null:
			continue
		_disable_legacy_static_blocker(node)
	for path in force_collision_enabled_paths:
		var node := root.get_node_or_null(path)
		if node is TileMapLayer:
			(node as TileMapLayer).collision_enabled = true
			node.set_meta("phase_0j_wall_collision_forced_enabled", true)


func _find_scene_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	if tree.current_scene != null:
		return tree.current_scene
	# Walk up until we find a node whose parent is the SceneTree root.
	var n: Node = self
	while n != null and n.get_parent() != null and n.get_parent() != tree.get_root():
		n = n.get_parent()
	return n if n != null else tree.get_root()


func _walk_and_disable_routes(parent: Node) -> void:
	for child in parent.get_children():
		if child is Area2D and _matches_route(child):
			_disable_player_teleport_trigger(child)
		_walk_and_disable_routes(child)


func _matches_route(node: Node) -> bool:
	var lname := String(node.name).to_lower()
	var tid := ""
	if node.get("transition_id") != null:
		tid = String(node.get("transition_id")).to_lower()
	for pat in route_name_patterns:
		var p := pat.to_lower()
		if lname.contains(p) or tid.contains(p):
			return true
	return false


func _disable_player_teleport_trigger(node: Node) -> void:
	if node is Area2D:
		var area := node as Area2D
		area.monitoring = false
		area.collision_mask = 0
		if area.get("auto_trigger_on_enter") != null:
			area.set("auto_trigger_on_enter", false)
		if area.is_in_group("interactable"):
			area.remove_from_group("interactable")
		area.set_meta("phase_0j_player_teleport_disabled", true)
		area.set_meta("phase_0j_safeguard_reason", safeguard_reason)


func _disable_legacy_static_blocker(node: Node) -> void:
	if node is StaticBody2D:
		var body := node as StaticBody2D
		body.collision_layer = 0
		body.collision_mask = 0
		for c in body.get_children():
			if c is CollisionShape2D:
				(c as CollisionShape2D).disabled = true
			elif c is CollisionPolygon2D:
				(c as CollisionPolygon2D).disabled = true
		if body is CanvasItem:
			(body as CanvasItem).visible = false
		body.set_meta("phase_0j_legacy_blocker_disabled", true)
