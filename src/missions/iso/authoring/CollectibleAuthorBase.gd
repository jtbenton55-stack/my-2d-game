@tool
extends Node2D
## Shared editor placement + runtime config for hand-placed collectible authors (D6-06).

@export_group("Collectible Identity")
@export var collectible_id: StringName = &"collectible"
@export var enabled := true
@export var one_shot := true
@export var display_name: String = ""

@export_group("Hooks")
@export var objective_id: StringName = &""
@export var pickup_event_id: StringName = &""
@export var hideout_collection_key: StringName = &""

@export_group("Pickup Shape")
@export var pickup_radius: float = 40.0
@export var show_pickup_radius_preview := true

@export_group("Editor Preview")
@export var preview_color: Color = Color(0.85, 0.75, 0.2, 0.9)
@export var show_label := true
@export var preview_radius: float = 20.0

var _label: Label = null
var _editor_preview_sig: String = ""


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		_ensure_label()
		_refresh_label()
		queue_redraw()
	else:
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var sig := _preview_signature()
	if sig != _editor_preview_sig:
		_editor_preview_sig = sig
		queue_redraw()
		_refresh_label()


func is_collectible_author() -> bool:
	return true


func get_author_kind() -> String:
	return "collectible"


func build_runtime_config() -> Dictionary:
	return {
		"collectible_id": String(collectible_id).strip_edges(),
		"collectible_type": get_author_kind(),
		"enabled": enabled,
		"one_shot": one_shot,
		"display_name": _resolved_display_name(),
		"objective_id": String(objective_id).strip_edges(),
		"pickup_event_id": String(pickup_event_id).strip_edges(),
		"hideout_collection_key": String(hideout_collection_key).strip_edges(),
		"author_path": str(get_path()),
		"global_position": global_position,
		"preview_color": preview_color,
		"pickup_radius": maxf(pickup_radius, 16.0),
	}


func _resolved_display_name() -> String:
	var dn := display_name.strip_edges()
	if dn != "":
		return dn
	var id_s := String(collectible_id).strip_edges()
	if id_s != "":
		return id_s.capitalize()
	return get_author_kind().capitalize()


func _preview_signature() -> String:
	return "%s|%s|%s|%s" % [
		String(collectible_id),
		str(enabled),
		str(preview_color),
		_resolved_display_name(),
	]


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)


func _refresh_label() -> void:
	if not show_label or _label == null:
		if _label != null:
			_label.visible = false
		return
	_label.visible = true
	_label.text = "%s: %s" % [get_author_kind().to_upper(), _resolved_display_name()]
	_label.position = Vector2(-100.0, -preview_radius - 28.0)
	_label.size = Vector2(200.0, 22.0)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var radius := preview_radius
	if show_pickup_radius_preview:
		radius = pickup_radius
	draw_circle(Vector2.ZERO, radius, preview_color)
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 24, preview_color.lightened(0.2), 2.0)
	if String(collectible_id).strip_edges() == "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-36.0, 4.0),
			"SET ID",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color(1.0, 0.35, 0.35, 1.0)
		)
