extends Node
class_name PVGamesIconLibrary

const CATALOG_PATH := "res://docs/reports/pvgames_icon_library/pvgames_verified_icon_catalog.json"

var _catalog: Array[Dictionary] = []
var _by_id: Dictionary = {}


func load_catalog() -> bool:
	_catalog.clear()
	_by_id.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_warning("[PVGamesIconLibrary] Catalog missing: %s" % CATALOG_PATH)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Array:
		return false
	for item in parsed:
		if item is Dictionary:
			_catalog.append(item)
			_by_id[String(item.get("icon_id", ""))] = item
	return true


func get_icon_entry(icon_id: String) -> Dictionary:
	if _by_id.is_empty():
		load_catalog()
	return _by_id.get(icon_id, {})


func get_icon_texture(icon_id: String) -> Texture2D:
	var entry := get_icon_entry(icon_id)
	var path := String(entry.get("source_png_path", ""))
	if path == "" or not ResourceLoader.exists(path):
		push_warning("[PVGamesIconLibrary] Missing texture for icon_id: %s" % icon_id)
		return null
	return load(path) as Texture2D


func find_icons_by_tag(tag: String) -> Array:
	return list_icons("", "", tag)


func list_icons(source_set := "", quality := "", tag := "") -> Array:
	if _catalog.is_empty():
		load_catalog()
	var out: Array = []
	var query := tag.to_lower()
	for entry in _catalog:
		if source_set != "" and String(entry.get("source_set", "")) != source_set:
			continue
		if quality != "" and String(entry.get("quality_classification", "")) != quality:
			continue
		if query != "":
			var blob := JSON.stringify(entry).to_lower()
			if not blob.contains(query):
				continue
		out.append(entry)
	return out


func validate_icon_id(icon_id: String) -> bool:
	return not get_icon_entry(icon_id).is_empty()


func get_icon_ids_for_use(use_tag: String) -> Array:
	var ids: Array = []
	for entry in list_icons("", "", use_tag):
		ids.append(entry.get("icon_id", ""))
	return ids


func get_random_icon_for_use(use_tag: String) -> Dictionary:
	var matches := list_icons("", "", use_tag)
	if matches.is_empty():
		return {}
	return matches[randi() % matches.size()]
