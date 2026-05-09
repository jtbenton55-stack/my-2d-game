@tool
extends Node2D
class_name PVGEditableObject

const PIVOT_TEXTURE_CENTER := "TEXTURE_CENTER"
const PIVOT_VISIBLE_ALPHA_CENTER := "VISIBLE_ALPHA_CENTER"

@export var object_id := ""
@export var source_set := ""
@export var source_png_path := ""
@export var original_asset_id := ""
@export var object_category := ""
@export var recommended_container := ""
@export_enum("TEXTURE_CENTER", "VISIBLE_ALPHA_CENTER") var pivot_mode := PIVOT_VISIBLE_ALPHA_CENTER
@export var alpha_bbox := Rect2()
@export_multiline var notes := ""


func _ready() -> void:
	_ensure_sprite()
	if source_png_path != "":
		assign_texture_from_path(source_png_path)
	apply_center_pivot()


func assign_texture_from_path(path: String) -> void:
	source_png_path = path
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("[PVGEditableObject] Could not load texture: %s" % path)
		return
	var sprite := _ensure_sprite()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2.ZERO
	apply_center_pivot()


func apply_center_pivot() -> void:
	var sprite := _ensure_sprite()
	sprite.centered = true
	if pivot_mode == PIVOT_VISIBLE_ALPHA_CENTER and alpha_bbox.size.x > 0.0 and alpha_bbox.size.y > 0.0:
		apply_visible_alpha_center_pivot()
	else:
		sprite.offset = Vector2.ZERO


func apply_visible_alpha_center_pivot() -> void:
	var sprite := _ensure_sprite()
	if sprite.texture == null or alpha_bbox.size.x <= 0.0 or alpha_bbox.size.y <= 0.0:
		sprite.offset = Vector2.ZERO
		return
	var texture_center := sprite.texture.get_size() * 0.5
	var visible_center := alpha_bbox.position + alpha_bbox.size * 0.5
	sprite.centered = true
	sprite.offset = texture_center - visible_center


func set_depth_role(role: String) -> void:
	match role:
		"behind", "BehindPlayerObjects", "BEHIND_PLAYER":
			z_index = -120
			recommended_container = "BehindPlayerObjects"
		"occludable", "OccludableObjects", "OCCLUDABLE_ABOVE_PLAYER":
			z_index = 90
			recommended_container = "OccludableObjects"
		"foreground", "ForegroundObjects", "FOREGROUND_ALWAYS_FRONT":
			z_index = 160
			recommended_container = "ForegroundObjects"
		"review", "ReviewObjects", "REVIEW_ONLY":
			z_index = -40
			recommended_container = "ReviewObjects"


func set_metadata_from_index_entry(entry: Dictionary) -> void:
	object_id = String(entry.get("object_id", ""))
	source_set = String(entry.get("source_set", ""))
	source_png_path = String(entry.get("source_png_path", ""))
	original_asset_id = String(entry.get("original_asset_id", ""))
	object_category = String(entry.get("recommended_object_category", ""))
	recommended_container = String(entry.get("recommended_container", ""))
	pivot_mode = String(entry.get("recommended_pivot_mode", PIVOT_VISIBLE_ALPHA_CENTER))
	notes = String(entry.get("notes", ""))
	var bbox = entry.get("alpha_bbox", null)
	if bbox is Array and bbox.size() == 4:
		alpha_bbox = Rect2(Vector2(float(bbox[0]), float(bbox[1])), Vector2(float(bbox[2]) - float(bbox[0]), float(bbox[3]) - float(bbox[1])))
	assign_texture_from_path(source_png_path)
	z_index = int(entry.get("recommended_z_index", z_index))


func validate_visual_only() -> bool:
	for child in get_children():
		if child is CollisionObject2D or child is CollisionShape2D or child is CollisionPolygon2D or child is NavigationRegion2D:
			return false
	return true


func _ensure_sprite() -> Sprite2D:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		if owner != null:
			sprite.owner = owner
	sprite.centered = true
	return sprite
