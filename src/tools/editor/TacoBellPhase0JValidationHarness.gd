@tool
class_name TacoBellPhase0JValidationHarness
extends RefCounted

const SOURCE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable.tscn"
const DUPLICATE_SCENE := "res://scenes/missions_iso/TacoBellIso_Editable_RedesignTest.tscn"
const MISSION_DEFINITION := "res://assets/missions/taco_bell_iso_blockout_definition.tres"

const REQUIRED_NODE_PATHS := [
	"GameplayRoot",
	"EntityRoot/Player",
	"Camera2D",
	"GameplayRoot/LayoutRoot/FloorLayer",
	"GameplayRoot/LayoutRoot/WallLayer",
	"GameplayRoot/LayoutRoot/CoverLayer",
	"GameplayRoot/LayoutRoot/CollisionBarrierLayer",
	"GameplayRoot/LayoutRoot/MarkerTileLayer",
	"GameplayRoot/GeneratedRuntimeCollision",
	"EntityRoot/Interactables",
	"GameplayRoot/EditorOnlyRoomLabels",
]

const RUNTIME_VISIBILITY_PATHS := [
	"GameplayRoot/LayoutRoot/MarkerTileLayer",
	"GameplayRoot/LayoutRoot/CoverLayer",
	"GameplayRoot/GameplayMarkersLayer",
	"GameplayRoot/MarkerRoot/EditorOnlyPlaceholders",
	"GameplayRoot/EditorOnlyRoomLabels",
]

const FUTURE_MODES := {
	"collision": "supported_structural",
	"gate": "supported_structural",
	"interactables": "not_run",
	"combat": "not_run",
	"cameras": "not_run",
	"routes": "not_run",
}


static func inspect_static(opts: Dictionary = {}) -> Dictionary:
	var target_path := String(opts.get("target_path", DUPLICATE_SCENE))
	var source_before := String(opts.get("source_md5_before", ""))
	var result := _base_result(target_path, source_before)
	var packed := ResourceLoader.load(target_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	result.load.packed_scene_loaded = packed != null
	if packed == null:
		result.errors.append("packed_scene_load_failed")
		result.pass = false
		return result
	var instance := packed.instantiate()
	result.load.instantiated = instance != null
	if instance == null:
		result.errors.append("packed_scene_instantiate_failed")
		result.pass = false
		return result
	_inspect_instance(instance, result)
	instance.queue_free()
	result.pass = result.errors.is_empty()
	return result


static func inspect_runtime(tree: SceneTree, opts: Dictionary = {}) -> Dictionary:
	var target_path := String(opts.get("target_path", DUPLICATE_SCENE))
	var source_before := String(opts.get("source_md5_before", ""))
	var result := _base_result(target_path, source_before)
	var packed := ResourceLoader.load(target_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	result.load.packed_scene_loaded = packed != null
	if packed == null:
		result.errors.append("packed_scene_load_failed")
		result.pass = false
		return result
	var instance := packed.instantiate()
	result.load.instantiated = instance != null
	if instance == null:
		result.errors.append("packed_scene_instantiate_failed")
		result.pass = false
		return result
	tree.root.add_child(instance)
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame
	_inspect_instance(instance, result)
	_inspect_runtime_visibility(instance, result)
	tree.root.remove_child(instance)
	instance.queue_free()
	result.pass = result.errors.is_empty()
	return result


static func _base_result(target_path: String, source_before: String) -> Dictionary:
	var source_after := _file_md5(SOURCE_SCENE)
	return {
		"harness": "TacoBellPhase0JValidationHarness",
		"modifies_scene": false,
		"modes_supported": ["baseline", "runtime_visibility", "labels", "source_hash"],
		"future_modes": FUTURE_MODES.duplicate(true),
		"target_path": target_path,
		"source_scene": {
			"path": SOURCE_SCENE,
			"md5_before": source_before,
			"md5_after": source_after,
			"source_changed": source_before != "" and source_before != source_after,
		},
		"mission_definition": {
			"path": MISSION_DEFINITION,
			"md5": _file_md5(MISSION_DEFINITION),
		},
		"load": {
			"packed_scene_loaded": false,
			"instantiated": false,
		},
		"required_nodes": {},
		"tile_layers": [],
		"runtime_visibility": {},
		"editor_labels": {},
		"phase_0jb": {},
		"errors": [],
		"warnings": [],
		"pass": false,
	}


static func _inspect_instance(instance: Node, result: Dictionary) -> void:
	for p in REQUIRED_NODE_PATHS:
		result.required_nodes[p] = instance.get_node_or_null(p) != null
	_walk_tile_layers(instance, result.tile_layers)
	_inspect_labels(instance, result)
	_inspect_phase_0jb_collision_gate(instance, result)


static func _inspect_runtime_visibility(instance: Node, result: Dictionary) -> void:
	for p in RUNTIME_VISIBILITY_PATHS:
		var node := instance.get_node_or_null(p)
		if node == null:
			result.runtime_visibility[p] = {"exists": false}
			continue
		result.runtime_visibility[p] = {
			"exists": true,
			"type": node.get_class(),
			"visible": bool((node as CanvasItem).visible) if node is CanvasItem else null,
			"z_index": int((node as CanvasItem).z_index) if node is CanvasItem else null,
		}


static func _inspect_labels(instance: Node, result: Dictionary) -> void:
	var parent := instance.get_node_or_null("GameplayRoot/EditorOnlyRoomLabels")
	var out := {
		"parent_exists": parent != null,
		"count": 0,
		"labels": [],
	}
	if parent != null:
		for child in parent.get_children():
			var entry := {
				"name": String(child.name),
				"path": String(parent.get_path_to(child)),
				"type": child.get_class(),
				"owner_set": child.owner != null,
				"in_gameplay_group": _is_in_any_group(child, ["interactable", "interactables", "enemy", "guard", "guards", "collectibles", "markers", "iso_security_camera"]),
			}
			if child is CanvasItem:
				entry.visible = bool((child as CanvasItem).visible)
				entry.z_index = int((child as CanvasItem).z_index)
			if child.get("label_color") != null:
				var c: Color = child.get("label_color")
				entry.label_color = [c.r, c.g, c.b, c.a]
				entry.dark_text = c.r <= 0.25 and c.g <= 0.25 and c.b <= 0.25
			if child.get("label_text") != null:
				entry.label_text = String(child.get("label_text"))
			out.labels.append(entry)
		out.count = out.labels.size()
	result.editor_labels = out


static func _walk_tile_layers(node: Node, out: Array) -> void:
	if node is TileMapLayer:
		var layer := node as TileMapLayer
		out.append({
			"path": String(node.get_path()),
			"name": String(node.name),
			"type": "TileMapLayer",
			"visible": bool(layer.visible),
			"enabled": bool(layer.enabled),
			"collision_enabled": bool(layer.collision_enabled),
			"z_index": int(layer.z_index),
			"y_sort_enabled": bool(layer.y_sort_enabled),
			"used_cell_count": layer.get_used_cells().size(),
			"used_rect": str(layer.get_used_rect()),
		})
	for child in node.get_children():
		_walk_tile_layers(child, out)


static func _is_in_any_group(node: Node, group_names: Array) -> bool:
	for g in group_names:
		if node.is_in_group(String(g)):
			return true
	return false


static func _inspect_phase_0jb_collision_gate(instance: Node, result: Dictionary) -> void:
	var out := {
		"wall_collision": _collision_summary(instance, "GameplayRoot/GeneratedRuntimeCollision/WallCollision"),
		"boundary_collision": _collision_summary(instance, "GameplayRoot/GeneratedRuntimeCollision/BoundaryCollision"),
		"code_gate_blocker": _collision_summary(instance, "GameplayRoot/GeneratedRuntimeCollision/GateBlockers/BLOCK_code_gate"),
		"player_mask_includes_walls": null,
	}
	var player := instance.get_node_or_null("EntityRoot/Player")
	if player is CollisionObject2D:
		out.player_mask_includes_walls = (int((player as CollisionObject2D).collision_mask) & 4) != 0
	result.phase_0jb = out


static func _collision_summary(root: Node, path: String) -> Dictionary:
	var node := root.get_node_or_null(path)
	var out := {
		"path": path,
		"exists": node != null,
		"body_count": 0,
		"shape_count": 0,
		"walls_layer_body_count": 0,
		"future_unlockable": null,
		"generated_by": "",
	}
	if node == null:
		return out
	if node.has_meta("future_unlockable"):
		out.future_unlockable = bool(node.get_meta("future_unlockable"))
	if node.has_meta("generated_by"):
		out.generated_by = String(node.get_meta("generated_by"))
	_count_collision_nodes(node, out)
	return out


static func _count_collision_nodes(node: Node, out: Dictionary) -> void:
	if node is StaticBody2D:
		out.body_count += 1
		if int((node as StaticBody2D).collision_layer) & 4:
			out.walls_layer_body_count += 1
	if node is CollisionShape2D or node is CollisionPolygon2D:
		out.shape_count += 1
	for child in node.get_children():
		_count_collision_nodes(child, out)


static func _file_md5(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_md5(path)
