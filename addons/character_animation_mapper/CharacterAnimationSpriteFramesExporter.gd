extends RefCounted

const MAPPER_HELPERS := preload("res://addons/character_animation_mapper/CharacterAnimationMapperHelpers.gd")
const PREVIEW_DIR := "res://resources/character_animation_maps/generated_preview/"


static func load_map_from_path(map_path: String) -> Dictionary:
	if map_path.is_empty() or not map_path.begins_with("res://"):
		return {}
	if not FileAccess.file_exists(ProjectSettings.globalize_path(map_path)):
		return {}
	var file := FileAccess.open(ProjectSettings.globalize_path(map_path), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func atlas_for_frame(
	sheet_texture: Texture2D,
	global_index: int,
	columns: int,
	frame_width: int,
	frame_height: int
) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet_texture
	var row: int = global_index / columns
	var col: int = global_index % columns
	atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
	return atlas


static func build_spriteframes_from_map_data(map_data: Dictionary) -> Dictionary:
	if map_data.is_empty():
		return {"ok": false, "message": "Empty map data."}
	var sheet_path := String(map_data.get("source_sheet", ""))
	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		return {"ok": false, "message": "Map source_sheet missing or not loadable: %s" % sheet_path}
	var sheet_texture: Texture2D = load(sheet_path) as Texture2D
	if sheet_texture == null:
		return {"ok": false, "message": "Failed to load sheet texture: %s" % sheet_path}
	var columns := int(map_data.get("columns", 50))
	var frame_width := int(map_data.get("frame_width", 200))
	var frame_height := int(map_data.get("frame_height", 200))
	var sf := SpriteFrames.new()
	var added := 0
	for raw in map_data.get("animations", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw
		if String(entry.get("review_status", "")) != "reviewed":
			continue
		var anim_name := String(entry.get("animation_name", ""))
		if anim_name.is_empty():
			continue
		var frames := MAPPER_HELPERS.frames_from_entry(entry)
		if frames.is_empty():
			continue
		if sf.has_animation(anim_name):
			sf.remove_animation(anim_name)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(entry.get("fps", 10.0)))
		sf.set_animation_loop(anim_name, bool(entry.get("loop", true)))
		for g: int in frames:
			sf.add_frame(anim_name, atlas_for_frame(sheet_texture, g, columns, frame_width, frame_height), 1.0)
		added += 1
	if added == 0:
		return {"ok": false, "message": "No reviewed animations exported."}
	return {"ok": true, "spriteframes": sf, "animation_count": added, "sheet_path": sheet_path}


static func save_spriteframes_from_map(map_path: String, output_path: String) -> Dictionary:
	var map_data := load_map_from_path(map_path)
	if map_data.is_empty():
		return {"ok": false, "message": "Failed to load map: %s" % map_path}
	var built := build_spriteframes_from_map_data(map_data)
	if not bool(built.get("ok", false)):
		return built
	var out_path := output_path
	if not out_path.begins_with("res://"):
		return {"ok": false, "message": "Output path must be res://"}
	if not out_path.begins_with(PREVIEW_DIR):
		return {"ok": false, "message": "Refusing output outside generated_preview: %s" % out_path}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var sf: SpriteFrames = built.get("spriteframes")
	var err := ResourceSaver.save(sf, out_path)
	if err != OK:
		return {"ok": false, "message": "ResourceSaver.save failed: %s" % error_string(err)}
	return {
		"ok": true,
		"message": "Saved SpriteFrames (%d anims): %s" % [int(built.get("animation_count", 0)), out_path],
		"animation_count": int(built.get("animation_count", 0)),
		"output_path": out_path,
		"map_path": map_path,
		"sheet_path": String(built.get("sheet_path", "")),
	}
