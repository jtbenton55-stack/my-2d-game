@tool
class_name Phase0IAuthoringHider
extends Node
## Phase 0I — Editor-Only Authoring Hider.
##
## Attached by the deterministic builder to specific authoring layers/parents
## inside res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn.
##
## Purpose: keep authoring visuals (MarkerTileLayer tiles, IsoMissionMarker
## debug rings, EditorOnlyPlaceholders, marker-root containers, etc.) visible
## inside the Godot editor for authoring/inspection, but hide them at runtime
## so they do not float over the player and so the player cannot mistake an
## authoring tile for a real pickup/collision.
##
## This script:
##   - Does nothing in the editor (Engine.is_editor_hint() == true).
##   - At runtime, sets `visible = false` on its parent (a CanvasItem subtree).
##   - Optionally also sets a few defensive properties:
##       * z_index = -10000 so even if some other code re-shows it, it cannot
##         render above the player.
##       * collision_enabled = false on TileMapLayer parents.
##
## It does NOT:
##   - Free or queue_free the parent.
##   - Remove children.
##   - Modify gameplay groups.
##   - Modify any property on nodes outside its parent subtree.
##
## Phase 0I rules (per user):
##   - This script is a NEW isolated runtime/helper under
##     res://src/missions/iso/runtime/ which is explicitly allowed.
##   - It does not modify save/load, mission catalog, IsoMissionBase,
##     IsoMissionMarker, or any other global runtime system.

@export var hide_at_runtime: bool = true
@export var force_low_z_index: bool = true
@export var disable_collision_on_tilemap: bool = true
@export var hide_reason: String = "phase_0i_authoring_only_visual"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var parent := get_parent()
	if parent == null:
		return
	if hide_at_runtime and parent is CanvasItem:
		(parent as CanvasItem).visible = false
	if force_low_z_index and parent is CanvasItem:
		# z_index is clamped by Godot to [-4096, 4096]; -4096 is safest.
		(parent as CanvasItem).z_index = -4096
	if disable_collision_on_tilemap and parent is TileMapLayer:
		(parent as TileMapLayer).collision_enabled = false
	parent.set_meta("phase_0i_hidden_at_runtime", true)
	parent.set_meta("phase_0i_hide_reason", hide_reason)
