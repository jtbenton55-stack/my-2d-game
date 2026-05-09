@tool
extends EditorScript
class_name PVGamesEditableObjectPaletteBrowserHelper

const INDEX_PATH := "res://docs/reports/pvgames_editable_object_palette/pvgames_editable_object_palette_index_by_container.json"


func _run() -> void:
	print("PVGamesEditableObjectPaletteBrowserHelper ready. Call print_object_info, print_stamp_command, list_by_container, list_by_category, or validate_palette_scene.")


func print_object_info(object_id: String) -> void:
	var entry := find_object(object_id)
	print(JSON.stringify(entry, "\t"))


func print_stamp_command(object_id: String) -> void:
	var entry := find_object(object_id)
	if entry.is_empty():
		print("Object not found: %s" % object_id)
		return
	var container := String(entry.get("recommended_container", "OccludableObjects"))
	print("Set PVGamesEditableObjectPaletteRunner.gd:")
	print("const MODE := \"dry_run_stamp_object\"")
	print("const OBJECT_ID := \"%s\"" % object_id)
	print("const TARGET_CONTAINER := \"%s\"" % container)


func list_by_container(container_name: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _objects():
		if String(entry.get("recommended_container", "")) == container_name:
			out.append(entry)
	print(JSON.stringify(out, "\t"))
	return out


func list_by_category(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _objects():
		if String(entry.get("object_category", "")) == category:
			out.append(entry)
	print(JSON.stringify(out, "\t"))
	return out


func validate_palette_scene(scene_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(scene_path)
	var result := {
		"scene_path": scene_path,
		"has_object_id_metadata": text.contains("metadata/object_id"),
		"has_object_id_labels": text.contains("ObjectId"),
		"uses_contact_sheet_as_texture": text.contains("contact_sheets") or text.contains("contact_sheet"),
		"has_collision": text.contains("CollisionShape2D") or text.contains("StaticBody2D") or text.contains("Area2D"),
	}
	print(JSON.stringify(result, "\t"))
	return result


func find_object(object_id: String) -> Dictionary:
	for entry in _objects():
		if String(entry.get("object_id", "")) == object_id:
			return entry
	return {}


func _objects() -> Array[Dictionary]:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
	var out: Array[Dictionary] = []
	if parsed is Dictionary and parsed.has("objects"):
		for item in parsed["objects"]:
			if item is Dictionary:
				out.append(item)
	return out
