@tool
extends EditorScript
class_name PVGamesArtStamper

## Manifest-based visual-only PVGames art stamper.
## This tool is intentionally opt-in. It does not run automatically and should
## stamp duplicate/test scenes unless a human explicitly chooses production.

func stamp_manifest(manifest_path: String, output_scene_path: String = "") -> Dictionary:
	var result := {"ok": false, "created": 0, "errors": []}
	if not FileAccess.file_exists(manifest_path):
		result["errors"].append("Manifest not found: %s" % manifest_path)
		return result
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if data == null:
		result["errors"].append("Manifest JSON parse failed.")
		return result
	var target_scene := String(data.get("target_scene", ""))
	var packed := load(target_scene) as PackedScene
	if packed == null:
		result["errors"].append("Target scene failed to load: %s" % target_scene)
		return result
	var root := packed.instantiate()
	var container_name := String(data.get("container_name", "PVGamesStampedArt"))
	for entry in data.get("placements", []):
		if not bool(entry.get("visual_only", true)) or not bool(entry.get("collision_disabled", true)):
			result["errors"].append("Rejected non-visual placement: %s" % String(entry.get("asset_id", "")))
			continue
		var target_layer := root.get_node_or_null(String(entry.get("target_layer", "")))
		if target_layer == null:
			result["errors"].append("Missing target layer: %s" % String(entry.get("target_layer", "")))
			continue
		var container := target_layer.get_node_or_null(container_name)
		if container == null:
			container = Node2D.new()
			container.name = container_name
			target_layer.add_child(container)
			container.owner = root
		var texture := load(String(entry.get("asset_path", ""))) as Texture2D
		if texture == null:
			result["errors"].append("Texture load failed: %s" % String(entry.get("asset_path", "")))
			continue
		var sprite := Sprite2D.new()
		sprite.name = "PVG_%s_%s" % [String(entry.get("category", "asset")).to_lower(), String(entry.get("asset_id", "asset"))]
		sprite.texture = texture
		var pos: Array = entry.get("position", [0, 0])
		var scl: Array = entry.get("scale", [1, 1])
		sprite.position = Vector2(float(pos[0]), float(pos[1]))
		sprite.scale = Vector2(float(scl[0]), float(scl[1]))
		sprite.rotation_degrees = float(entry.get("rotation_degrees", 0.0))
		sprite.z_index = int(entry.get("z_index", 0))
		sprite.set_meta("pvgames_asset_id", String(entry.get("asset_id", "")))
		sprite.set_meta("category", String(entry.get("category", "")))
		sprite.set_meta("subcategory", String(entry.get("subcategory", "")))
		sprite.set_meta("placement_method", String(entry.get("placement_method", "Sprite2D")))
		sprite.set_meta("visual_only", true)
		sprite.set_meta("collision_disabled", true)
		container.add_child(sprite)
		sprite.owner = root
		result["created"] += 1
	var save_path := output_scene_path if output_scene_path != "" else String(data.get("output_scene", ""))
	if save_path == "":
		result["errors"].append("No output scene path provided. Refusing to overwrite target scene by default.")
		root.free()
		return result
	var out := PackedScene.new()
	out.pack(root)
	var err := ResourceSaver.save(out, save_path)
	root.free()
	result["ok"] = err == OK and result["errors"].is_empty()
	return result
