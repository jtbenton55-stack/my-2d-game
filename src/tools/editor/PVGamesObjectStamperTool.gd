@tool
extends EditorScript
class_name PVGamesObjectStamperTool

const INDEX_PATH := "res://docs/reports/pvgames_editable_object_asset_index.json"
const DEFAULT_SCENE_PATH := "res://scenes/hideout/HideoutHub.tscn"
const BACKUP_PREFIX := "res://scenes/hideout/HideoutHub.phase0mb8_stamper_backup"
const EDITABLE_SCRIPT := preload("res://src/hideout/PVGEditableObject.gd")
const CONTAINER_ROOT := "ArtRoot/World/PVG_EditableObjects"
const VALID_CONTAINERS := ["BehindPlayerObjects", "OccludableObjects", "ForegroundObjects", "ReviewObjects"]


func _run() -> void:
	print(JSON.stringify(list_object_assets(""), "\t"))


func list_object_assets(filter := "") -> Array[Dictionary]:
	var entries := _load_index()
	if filter == "":
		return entries.slice(0, min(entries.size(), 50))
	var out: Array[Dictionary] = []
	var query := filter.to_lower()
	for entry in entries:
		var blob := " ".join([
			String(entry.get("object_id", "")),
			String(entry.get("filename", "")),
			String(entry.get("source_set", "")),
			String(entry.get("recommended_object_category", "")),
			String(entry.get("recommended_container", "")),
			String(entry.get("notes", "")),
		]).to_lower()
		if blob.contains(query):
			out.append(entry)
	return out


func stamp_object_dry_run(scene_path: String, object_id: String, object_position: Vector2, target_container := "", object_scale := Vector2.ONE, object_rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry_by_id(object_id)
	if entry.is_empty():
		return {"changed": false, "error": "object_id not found", "object_id": object_id}
	var container := _target_container(entry, target_container)
	return {
		"changed": false,
		"mode": "dry_run_stamp",
		"object_id": object_id,
		"source_png_path": entry.get("source_png_path", ""),
		"target_scene": scene_path,
		"target_container": CONTAINER_ROOT + "/" + container,
		"final_object_node_name": _unique_object_name(entry),
		"final_position": object_position,
		"final_scale": object_scale,
		"final_rotation_degrees": object_rotation_degrees,
		"final_z_index": z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index", 0)),
		"pivot_mode": entry.get("recommended_pivot_mode", "VISIBLE_ALPHA_CENTER"),
		"source_png_exists": ResourceLoader.exists(String(entry.get("source_png_path", ""))),
		"under_artroot_world": true,
		"backup_would_be_created": true,
	}


func stamp_object(scene_path: String, object_id: String, object_position: Vector2, target_container := "", object_scale := Vector2.ONE, object_rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry_by_id(object_id)
	if entry.is_empty():
		return {"changed": false, "error": "object_id not found", "object_id": object_id}
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var container_name := _target_container(entry, target_container)
	var container := _ensure_container(root, container_name)
	if container == null:
		root.free()
		return {"changed": false, "error": "target container missing or unsafe"}
	var backup := backup_scene(scene_path, "stamp_object")
	var obj := _create_object_node(entry)
	obj.name = _unique_child_name(container, _unique_object_name(entry))
	obj.position = object_position
	obj.scale = object_scale
	obj.rotation_degrees = object_rotation_degrees
	obj.z_index = z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index", 0))
	container.add_child(obj)
	_set_owner_recursive(obj, root)
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": CONTAINER_ROOT + "/" + container_name + "/" + obj.name}


func set_object_transform(scene_path: String, object_node_path: String, object_position := Vector2.INF, object_scale := Vector2.INF, object_rotation_degrees := INF, z_index_override := 999999) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path)) as Node2D
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "set_object_transform")
	if object_position != Vector2.INF:
		obj.position = object_position
	if object_scale != Vector2.INF:
		obj.scale = object_scale
	if object_rotation_degrees != INF:
		obj.rotation_degrees = object_rotation_degrees
	if z_index_override != 999999:
		obj.z_index = z_index_override
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": object_node_path}


func duplicate_stamped_object(scene_path: String, object_node_path: String, new_position := Vector2.INF) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path)) as Node2D
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "duplicate_object")
	var copy := obj.duplicate()
	copy.name = _unique_child_name(obj.get_parent(), String(obj.name) + "_Copy")
	if new_position != Vector2.INF:
		copy.position = new_position
	obj.get_parent().add_child(copy)
	_set_owner_recursive(copy, root)
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "object_path": object_node_path, "duplicate_name": copy.name}


func delete_stamped_object(scene_path: String, object_node_path: String) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var obj := root.get_node_or_null(NodePath(object_node_path))
	if obj == null or not object_node_path.begins_with(CONTAINER_ROOT + "/"):
		root.free()
		return {"changed": false, "error": "object not found or unsafe"}
	var backup := backup_scene(scene_path, "delete_object")
	obj.get_parent().remove_child(obj)
	obj.free()
	var saved := _save_scene(root, scene_path)
	root.free()
	return {"changed": saved, "backup_path": backup, "deleted_path": object_node_path}


func convert_tile_cell_to_object_dry_run(scene_path: String, layer_path: String, cell_coords: Vector2i) -> Dictionary:
	var root := _load_scene_root(scene_path)
	if root == null:
		return {"changed": false, "error": "scene load failed"}
	var layer := root.get_node_or_null(NodePath(layer_path)) as TileMapLayer
	if layer == null:
		root.free()
		return {"changed": false, "error": "layer not found"}
	var source_id := layer.get_cell_source_id(cell_coords)
	var atlas_coords := layer.get_cell_atlas_coords(cell_coords)
	var alt_id := layer.get_cell_alternative_tile(cell_coords)
	var source_path := ""
	if layer.tile_set != null and source_id >= 0:
		var source := layer.tile_set.get_source(source_id)
		if source is TileSetAtlasSource and (source as TileSetAtlasSource).texture != null:
			source_path = (source as TileSetAtlasSource).texture.resource_path
	var map_position := layer.map_to_local(cell_coords)
	var world_position := layer.to_global(map_position)
	var matched := _entry_by_source_path(source_path)
	root.free()
	return {
		"changed": false,
		"layer_path": layer_path,
		"cell_coords": cell_coords,
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile_id": alt_id,
		"inferred_source_png_path": source_path,
		"world_position_estimate": world_position,
		"target_object_id": matched.get("object_id", ""),
		"conversion_safe": source_path != "" and not matched.is_empty(),
	}


func convert_tile_cell_to_object(scene_path: String, layer_path: String, cell_coords: Vector2i, erase_original := false) -> Dictionary:
	var dry := convert_tile_cell_to_object_dry_run(scene_path, layer_path, cell_coords)
	if not bool(dry.get("conversion_safe", false)):
		return dry
	var result := stamp_object(scene_path, String(dry.get("target_object_id", "")), dry.get("world_position_estimate", Vector2.ZERO), "ReviewObjects")
	if erase_original and bool(result.get("changed", false)):
		var root := _load_scene_root(scene_path)
		var layer := root.get_node_or_null(NodePath(layer_path)) as TileMapLayer
		if layer != null:
			layer.erase_cell(cell_coords)
			_save_scene(root, scene_path)
		root.free()
	return result


func backup_scene(scene_path: String, reason: String) -> String:
	var stamp := Time.get_datetime_string_from_system(false, true).replace("-", "").replace(":", "").replace("T", "_")
	var backup_path := "%s.%s.%s.tscn" % [BACKUP_PREFIX, reason, stamp]
	var bytes := FileAccess.get_file_as_bytes(scene_path)
	var file := FileAccess.open(backup_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(bytes)
		file.close()
	return backup_path


func _load_index() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	var out: Array[Dictionary] = []
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				out.append(item)
	return out


func _entry_by_id(object_id: String) -> Dictionary:
	for entry in _load_index():
		if String(entry.get("object_id", "")) == object_id:
			return entry
	return {}


func _entry_by_source_path(source_path: String) -> Dictionary:
	for entry in _load_index():
		if String(entry.get("source_png_path", "")) == source_path:
			return entry
	return {}


func _target_container(entry: Dictionary, override: String) -> String:
	if override in VALID_CONTAINERS:
		return override
	var recommended := String(entry.get("recommended_container", "ReviewObjects"))
	return recommended if recommended in VALID_CONTAINERS else "ReviewObjects"


func _load_scene_root(scene_path: String) -> Node:
	if scene_path.contains("missions_iso"):
		push_error("[PVGamesObjectStamperTool] Refusing to modify mission scenes.")
		return null
	var packed := load(scene_path) as PackedScene
	return packed.instantiate() if packed != null else null


func _save_scene(root: Node, scene_path: String) -> bool:
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		return false
	return ResourceSaver.save(packed, scene_path) == OK


func _ensure_container(root: Node, container_name: String) -> Node2D:
	var world := root.get_node_or_null("ArtRoot/World")
	if world == null:
		return null
	var base := world.get_node_or_null("PVG_EditableObjects") as Node2D
	if base == null:
		base = Node2D.new()
		base.name = "PVG_EditableObjects"
		world.add_child(base)
		_set_owner_recursive(base, root)
	var container := base.get_node_or_null(container_name) as Node2D
	if container == null:
		container = Node2D.new()
		container.name = container_name
		base.add_child(container)
		_set_owner_recursive(container, root)
	return container


func _create_object_node(entry: Dictionary) -> PVGEditableObject:
	var obj := PVGEditableObject.new()
	obj.set_metadata_from_index_entry(entry)
	return obj


func _unique_object_name(entry: Dictionary) -> String:
	var set_prefix := "Core" if String(entry.get("source_set", "")) == "core" else "CentralSecurity"
	var category := String(entry.get("recommended_object_category", "Object")).capitalize().replace(" ", "")
	return "PVG_%s_%s_%s" % [set_prefix, category, String(entry.get("object_id", "")).right(4)]


func _unique_child_name(parent: Node, base: String) -> String:
	var name := base
	var i := 1
	while parent.get_node_or_null(name) != null:
		name = "%s_%04d" % [base, i]
		i += 1
	return name


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)
