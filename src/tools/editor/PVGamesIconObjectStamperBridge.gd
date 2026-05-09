@tool
extends EditorScript
class_name PVGamesIconObjectStamperBridge

const CATALOG_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"
const EDITABLE_OBJECT_SCENE := "res://scenes/hideout/tools/PVGEditableObject.tscn"
const ICON_CONTAINERS := ["BehindPlayerIcons", "OccludableIcons", "ForegroundIcons", "ReviewIcons"]

func list_world_stampable_icons(filter := "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _catalog():
		var q := String(entry.get("quality_classification", ""))
		if not ["READY_WORLD_DECAL", "READY_BOTH", "REVIEW_MANUALLY"].has(q):
			continue
		if filter != "" and not JSON.stringify(entry).to_lower().contains(filter.to_lower()):
			continue
		out.append(entry)
	return out

func dry_run_stamp_icon(scene_path: String, icon_id: String, position: Vector2, target_container := "", scale := Vector2.ONE, rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	var entry := _entry(icon_id)
	var container := target_container if ICON_CONTAINERS.has(target_container) else String(entry.get("recommended_world_container", "ReviewIcons"))
	return {"changed": false, "icon_id": icon_id, "source_texture": entry.get("source_png_path", ""), "target_scene": scene_path, "target_container": "ArtRoot/World/PVG_EditableObjects/IconObjects/%s" % container, "position": position, "scale": scale, "rotation_degrees": rotation_degrees, "z_index": z_index_override if z_index_override != 999999 else int(entry.get("recommended_z_index_role", 0)), "would_add_collision": false, "would_touch_gameplayroot": false}

func stamp_icon(scene_path: String, icon_id: String, position: Vector2, target_container := "", scale := Vector2.ONE, rotation_degrees := 0.0, z_index_override := 999999) -> Dictionary:
	return {"changed": false, "error": "Use the B8B dock for in-memory editor stamping; bridge destructive scene-file stamping is intentionally not implemented."}

func set_stamped_icon_transform(_scene_path: String, _object_node_path: String, _position := Vector2.INF, _scale := Vector2.INF, _rotation_degrees := INF, _z_index := 999999) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor transform tools for stamped icon objects."}

func duplicate_stamped_icon(_scene_path: String, _object_node_path: String, _new_position := Vector2.INF) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor duplicate or B8B dock workflow."}

func delete_stamped_icon(_scene_path: String, _object_node_path: String) -> Dictionary:
	return {"changed": false, "error": "Use Godot editor delete for stamped icon objects."}

func _catalog() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	var out: Array[Dictionary] = []
	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				out.append(item)
	return out

func _entry(icon_id: String) -> Dictionary:
	for item in _catalog():
		if String(item.get("icon_id", "")) == icon_id:
			return item
	return {}
