@tool
extends EditorScript
class_name PVGamesPaintLayerCleanupTool

const DEFAULT_SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const BACKUP_PREFIX := "res://scenes/hideout/HideoutHub.phase0mb7_cleanup_backup"
const SUPPORTED_GROUPS := [
	"core",
	"central_security",
	"ground",
	"wall",
	"occludable",
	"foreground",
	"review_only",
	"all_pvgames",
]
const PVGAMES_TILESET_PREFIXES := [
	"res://assets/tilesets/pvgames_catalog_paintable/",
	"res://assets/tilesets/pvgames_central_security_paintable/",
]

var _active_scene_path := DEFAULT_SCENE_PATH
var _active_root: Node = null


func _run() -> void:
	print_inventory(DEFAULT_SCENE_PATH)


func print_inventory(scene_path := DEFAULT_SCENE_PATH) -> void:
	var root := _load_scene_root(scene_path)
	if root == null:
		return
	var layers := get_pvgames_paint_layers(scene_path)
	print("[PVGamesPaintLayerCleanupTool] Inventory for %s" % scene_path)
	for layer in layers:
		print("- %s | %s | used cells: %d | group tags: %s" % [
			layer.get("node_path", ""),
			layer.get("tileset_path", ""),
			int(layer.get("used_cell_count", 0)),
			", ".join(layer.get("groups", [])),
		])
	root.free()


func dry_run_clear_layer(layer_path: String) -> Dictionary:
	var root := _load_scene_root(DEFAULT_SCENE_PATH)
	if root == null:
		return _result("dry_run_layer", layer_path, [], 0, false, "Scene could not be loaded.")
	var layer := _find_layer(root, layer_path)
	var result := _dry_run_for_layers([layer] if layer != null else [], "dry_run_layer", layer_path)
	root.free()
	return result


func clear_layer(layer_path: String, make_backup := true) -> Dictionary:
	var root := _load_scene_root(DEFAULT_SCENE_PATH)
	if root == null:
		return _result("clear_layer", layer_path, [], 0, false, "Scene could not be loaded.")
	var layer := _find_layer(root, layer_path)
	if layer == null:
		root.free()
		return _result("clear_layer", layer_path, [], 0, false, "Layer not found.")
	if not is_safe_paint_layer(layer):
		root.free()
		return _result("clear_layer", layer_path, [], 0, false, "Layer is not a safe PVGames paint layer.")
	var backup_path := ""
	if make_backup:
		backup_path = backup_hideout("clear_layer_%s" % layer.name)
	var before := int(layer.get_used_cells().size())
	clear_cells_on_layer(layer)
	var after := int(layer.get_used_cells().size())
	var saved := _save_scene(root, DEFAULT_SCENE_PATH)
	root.free()
	return {
		"mode": "clear_layer",
		"target": layer_path,
		"backup_path": backup_path,
		"changed": saved,
		"before_cells": before,
		"after_cells": after,
		"cleared_cells": before - after,
	}


func dry_run_clear_group(group_name: String) -> Dictionary:
	if not group_name in SUPPORTED_GROUPS:
		return _result("dry_run_group", group_name, [], 0, false, "Unsupported group.")
	var root := _load_scene_root(DEFAULT_SCENE_PATH)
	if root == null:
		return _result("dry_run_group", group_name, [], 0, false, "Scene could not be loaded.")
	var layers := _matching_group_layers(root, group_name)
	var result := _dry_run_for_layers(layers, "dry_run_group", group_name)
	root.free()
	return result


func clear_group(group_name: String, make_backup := true) -> Dictionary:
	if not group_name in SUPPORTED_GROUPS:
		return _result("clear_group", group_name, [], 0, false, "Unsupported group.")
	var root := _load_scene_root(DEFAULT_SCENE_PATH)
	if root == null:
		return _result("clear_group", group_name, [], 0, false, "Scene could not be loaded.")
	var layers := _matching_group_layers(root, group_name)
	var safe_layers: Array[TileMapLayer] = []
	for layer in layers:
		if is_safe_paint_layer(layer):
			safe_layers.append(layer)
	if safe_layers.is_empty():
		root.free()
		return _result("clear_group", group_name, [], 0, false, "No safe matching layers found.")
	var backup_path := ""
	if make_backup:
		backup_path = backup_hideout("clear_group_%s" % group_name)
	var layer_results: Array[Dictionary] = []
	var total_before := 0
	var total_after := 0
	for layer in safe_layers:
		var before := int(layer.get_used_cells().size())
		clear_cells_on_layer(layer)
		var after := int(layer.get_used_cells().size())
		total_before += before
		total_after += after
		layer_results.append({
			"node_path": _relative_node_path(layer),
			"before_cells": before,
			"after_cells": after,
			"cleared_cells": before - after,
		})
	var saved := _save_scene(root, DEFAULT_SCENE_PATH)
	root.free()
	return {
		"mode": "clear_group",
		"target": group_name,
		"backup_path": backup_path,
		"changed": saved,
		"layers": layer_results,
		"before_cells": total_before,
		"after_cells": total_after,
		"cleared_cells": total_before - total_after,
	}


func backup_hideout(reason: String) -> String:
	var stamp := Time.get_datetime_string_from_system(false, true).replace("-", "").replace(":", "").replace("T", "_")
	var clean_reason := reason.replace(" ", "_").replace("/", "_").replace("\\", "_")
	var backup_path := "%s.%s.%s.tscn" % [BACKUP_PREFIX, clean_reason, stamp]
	var source_bytes := FileAccess.get_file_as_bytes(DEFAULT_SCENE_PATH)
	if source_bytes.is_empty():
		push_error("[PVGamesPaintLayerCleanupTool] Could not read HideoutHub for backup.")
		return ""
	var file := FileAccess.open(backup_path, FileAccess.WRITE)
	if file == null:
		push_error("[PVGamesPaintLayerCleanupTool] Could not write backup: %s" % backup_path)
		return ""
	file.store_buffer(source_bytes)
	file.close()
	print("[PVGamesPaintLayerCleanupTool] Backup written: %s" % backup_path)
	return backup_path


func get_pvgames_paint_layers(scene_path := DEFAULT_SCENE_PATH) -> Array[Dictionary]:
	var root := _load_scene_root(scene_path)
	if root == null:
		return []
	var found: Array[Dictionary] = []
	for node in _all_children(root):
		if node is TileMapLayer and is_safe_paint_layer(node):
			found.append(_metadata_for_layer(node as TileMapLayer))
	root.free()
	return found


func is_safe_paint_layer(node: Node) -> bool:
	if not node is TileMapLayer:
		return false
	var path := _relative_node_path(node)
	if not path.begins_with("ArtRoot/World/"):
		return false
	if path.begins_with("GameplayRoot") or path.contains("/Collision") or path.contains("/Stations") or path.begins_with("UI"):
		return false
	var layer := node as TileMapLayer
	if layer.tile_set == null:
		return false
	var tileset_path := String(layer.tile_set.resource_path)
	for prefix in PVGAMES_TILESET_PREFIXES:
		if tileset_path.begins_with(prefix):
			return true
	return false


func clear_cells_on_layer(layer: TileMapLayer) -> Dictionary:
	var before_cells := layer.get_used_cells()
	var before := int(before_cells.size())
	layer.clear()
	var after := int(layer.get_used_cells().size())
	return {
		"before_cells": before,
		"after_cells": after,
		"cleared_cells": before - after,
	}


func _load_scene_root(scene_path: String) -> Node:
	_active_scene_path = scene_path
	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		push_error("[PVGamesPaintLayerCleanupTool] Could not load scene: %s" % scene_path)
		return null
	_active_root = packed.instantiate()
	return _active_root


func _save_scene(root: Node, scene_path: String) -> bool:
	var packed := PackedScene.new()
	var pack_result := packed.pack(root)
	if pack_result != OK:
		push_error("[PVGamesPaintLayerCleanupTool] Could not pack scene: %s" % scene_path)
		return false
	var save_result := ResourceSaver.save(packed, scene_path)
	if save_result != OK:
		push_error("[PVGamesPaintLayerCleanupTool] Could not save scene: %s" % scene_path)
		return false
	return true


func _find_layer(root: Node, layer_path: String) -> TileMapLayer:
	var normalized := layer_path
	if normalized.begins_with(String(root.name) + "/"):
		normalized = normalized.substr(String(root.name).length() + 1)
	var node := root.get_node_or_null(NodePath(normalized))
	return node as TileMapLayer


func _matching_group_layers(root: Node, group_name: String) -> Array[TileMapLayer]:
	var matches: Array[TileMapLayer] = []
	for node in _all_children(root):
		if not node is TileMapLayer or not is_safe_paint_layer(node):
			continue
		var meta := _metadata_for_layer(node as TileMapLayer)
		if group_name == "all_pvgames" or group_name in meta.get("groups", []):
			matches.append(node as TileMapLayer)
	return matches


func _dry_run_for_layers(layers: Array, mode: String, target: String) -> Dictionary:
	var layer_results: Array[Dictionary] = []
	var total := 0
	for layer in layers:
		if layer == null or not is_safe_paint_layer(layer):
			continue
		var meta := _metadata_for_layer(layer as TileMapLayer)
		var count := int(meta.get("used_cell_count", 0))
		total += count
		layer_results.append(meta)
	return _result(mode, target, layer_results, total, false, "Dry run only; no cells cleared.")


func _result(mode: String, target: String, layers: Array, total_cells: int, changed: bool, message: String) -> Dictionary:
	return {
		"mode": mode,
		"target": target,
		"layers": layers,
		"total_cells_that_would_be_cleared": total_cells,
		"changed": changed,
		"message": message,
	}


func _metadata_for_layer(layer: TileMapLayer) -> Dictionary:
	var used_cells := layer.get_used_cells()
	var groups := _groups_for_layer(layer)
	var first_cells: Array[String] = []
	for i in range(min(25, used_cells.size())):
		first_cells.append(str(used_cells[i]))
	return {
		"node_path": _relative_node_path(layer),
		"parent_path": _relative_node_path(layer.get_parent()),
		"node_name": String(layer.name),
		"tileset_path": String(layer.tile_set.resource_path) if layer.tile_set != null else "",
		"used_cell_count": int(used_cells.size()),
		"first_25_used_cells": first_cells,
		"z_index": layer.z_index,
		"z_as_relative": layer.z_as_relative,
		"y_sort_enabled": layer.y_sort_enabled,
		"visible": layer.visible,
		"owner_scene": _active_scene_path,
		"groups": groups,
		"asset_family": "central_security" if "central_security" in groups else "core",
		"depth_role": _depth_role_for_layer(layer),
		"safe_to_clear": is_safe_paint_layer(layer),
		"safe_reason": "Visual-only PVGames TileMapLayer under ArtRoot/World using a known paint TileSet.",
	}


func _groups_for_layer(layer: TileMapLayer) -> Array[String]:
	var path := _relative_node_path(layer).to_lower()
	var name := String(layer.name).to_lower()
	var tileset_path := String(layer.tile_set.resource_path).to_lower() if layer.tile_set != null else ""
	var groups: Array[String] = ["all_pvgames"]
	if tileset_path.contains("pvgames_catalog_paintable"):
		groups.append("core")
	if tileset_path.contains("pvgames_central_security_paintable") or name.contains("centralsecurity"):
		groups.append("central_security")
	if name.contains("ground") or name.contains("floor") or path.contains("floor"):
		groups.append("ground")
	if name.contains("wall") or name.contains("barrier") or name.contains("backdrop"):
		groups.append("wall")
	if name.contains("occludable"):
		groups.append("occludable")
	if name.contains("foreground") or name.contains("overlay"):
		groups.append("foreground")
	if name.contains("review"):
		groups.append("review_only")
	return groups


func _depth_role_for_layer(layer: TileMapLayer) -> String:
	var name := String(layer.name).to_lower()
	var path := _relative_node_path(layer).to_lower()
	if name.contains("foreground") or name.contains("overlay"):
		return "FOREGROUND_ALWAYS_FRONT"
	if name.contains("occludable"):
		return "OCCLUDABLE_ABOVE_PLAYER"
	if name.contains("review"):
		return "REVIEW_ONLY"
	if name.contains("ground") or name.contains("floor") or name.contains("backdrop") or name.contains("behind"):
		return "BEHIND_PLAYER"
	return "UNKNOWN"


func _all_children(root: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for child in root.get_children():
		nodes.append(child)
		nodes.append_array(_all_children(child))
	return nodes


func _relative_node_path(node: Node) -> String:
	if _active_root == null or node == _active_root:
		return String(node.name)
	var path := String(_active_root.get_path_to(node))
	return path
