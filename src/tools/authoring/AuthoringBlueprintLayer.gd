@tool
class_name AuthoringBlueprintLayer
extends Node2D
## Dev-only blueprint overlay for level authoring.
##
## Renders a deterministic blueprint spec (res://docs/blueprints/*.blueprint.json)
## behind the level so walls/floors/collision/mechanics can be traced with
## Mission Paint Dock and Mission Dock. Draw-only: never mutates the scene.
##
## Player safety: this node frees itself immediately when the game runs
## (editor-only by construction), and Phase0JRuntimeAuthoringHider strips it
## as a redundant second guard.

const Spec := preload("res://src/tools/authoring/LevelBlueprintSpec.gd")

const SLOT_MARKER_RADIUS := 14.0
const LABEL_FONT_SIZE := 13
const LEGEND_FONT_SIZE := 12
const TITLE_FONT_SIZE := 20

@export_file("*.blueprint.json") var blueprint_path := "" : set = _set_blueprint_path
@export var overlay_visible := true : set = _set_overlay_visible
@export_range(0.05, 1.0, 0.05) var opacity := 0.45 : set = _set_opacity
@export var show_grid := true : set = _set_show_grid
@export var show_regions := true : set = _set_show_regions
@export var show_mechanic_slots := true : set = _set_show_mechanic_slots
@export var show_labels := true : set = _set_show_labels
@export var show_dependency_arrows := true : set = _set_show_dependency_arrows
@export var show_legend := true : set = _set_show_legend
## When true the overlay draws above the map at low opacity instead of behind it.
@export var draw_on_top := false : set = _set_draw_on_top
## Toggle to re-read the blueprint file after editing it externally.
@export var reload_blueprint := false : set = _set_reload_blueprint

var _spec: Dictionary = {}
var _spec_errors: Array[String] = []
var _spec_loaded := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	_apply_z_index()
	_reload_spec()


func _set_blueprint_path(value: String) -> void:
	blueprint_path = value
	_reload_spec()


func _set_overlay_visible(value: bool) -> void:
	overlay_visible = value
	queue_redraw()


func _set_opacity(value: float) -> void:
	opacity = value
	queue_redraw()


func _set_show_grid(value: bool) -> void:
	show_grid = value
	queue_redraw()


func _set_show_regions(value: bool) -> void:
	show_regions = value
	queue_redraw()


func _set_show_mechanic_slots(value: bool) -> void:
	show_mechanic_slots = value
	queue_redraw()


func _set_show_labels(value: bool) -> void:
	show_labels = value
	queue_redraw()


func _set_show_dependency_arrows(value: bool) -> void:
	show_dependency_arrows = value
	queue_redraw()


func _set_show_legend(value: bool) -> void:
	show_legend = value
	queue_redraw()


func _set_draw_on_top(value: bool) -> void:
	draw_on_top = value
	_apply_z_index()
	queue_redraw()


func _set_reload_blueprint(value: bool) -> void:
	reload_blueprint = false
	if value:
		_reload_spec()


func _apply_z_index() -> void:
	z_index = 3500 if draw_on_top else -3500


func _reload_spec() -> void:
	_spec = {}
	_spec_errors = []
	_spec_loaded = false
	if blueprint_path.strip_edges() != "":
		var result := Spec.load_spec(blueprint_path)
		_spec = result.get("spec", {})
		var errors: Array = result.get("errors", [])
		for error: Variant in errors:
			_spec_errors.append(String(error))
		_spec_loaded = bool(result.get("ok", false))
	queue_redraw()


func get_spec() -> Dictionary:
	return _spec


func spec_is_loaded() -> bool:
	return _spec_loaded


func spec_errors() -> Array[String]:
	return _spec_errors


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if not overlay_visible:
		return
	var font := ThemeDB.fallback_font
	if blueprint_path.strip_edges() == "":
		draw_string(font, Vector2(0, 0), "AuthoringBlueprintLayer: set blueprint_path to a .blueprint.json file.", HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE, Color(1, 0.7, 0.2, 0.9))
		return
	if not _spec_errors.is_empty():
		var error_pos := Vector2(0, 0)
		draw_string(font, error_pos, "Blueprint errors (%s):" % blueprint_path.get_file(), HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE, Color(1, 0.25, 0.2, 0.95))
		for error: String in _spec_errors:
			error_pos.y += TITLE_FONT_SIZE + 6
			draw_string(font, error_pos, "- %s" % error, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color(1, 0.4, 0.3, 0.95))
		return
	if _spec.is_empty():
		return
	var canvas := Spec.canvas_size(_spec)
	if show_grid:
		_draw_grid(canvas)
	_draw_canvas_frame(font, canvas)
	if show_regions:
		_draw_regions(font)
	if show_dependency_arrows:
		_draw_dependency_arrows()
	if show_mechanic_slots:
		_draw_mechanic_slots(font)
	if show_legend:
		_draw_legend(font, canvas)


func _draw_grid(canvas: Vector2) -> void:
	var step := Spec.grid_size(_spec)
	if step <= 1.0:
		return
	var grid_color := Color(0.6, 0.7, 0.9, 0.12 * opacity * 2.0)
	var x := 0.0
	while x <= canvas.x:
		draw_line(Vector2(x, 0), Vector2(x, canvas.y), grid_color, 1.0)
		x += step
	var y := 0.0
	while y <= canvas.y:
		draw_line(Vector2(0, y), Vector2(canvas.x, y), grid_color, 1.0)
		y += step


func _draw_canvas_frame(font: Font, canvas: Vector2) -> void:
	var frame_color := Color(0.85, 0.9, 1.0, clampf(opacity + 0.2, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, canvas), frame_color, false, 2.0)
	var title := "%s  (%s)" % [String(_spec.get("blueprint_id", "")), blueprint_path.get_file()]
	draw_string(font, Vector2(4, -10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE, frame_color)


func _draw_regions(font: Font) -> void:
	for entry: Variant in Spec.regions(_spec):
		if not (entry is Dictionary):
			continue
		var region := entry as Dictionary
		var kind := String(region.get("kind", ""))
		var base_color: Color = Spec.region_color(kind)
		var fill := Color(base_color.r, base_color.g, base_color.b, 0.5 * opacity)
		var outline := Color(base_color.r, base_color.g, base_color.b, clampf(opacity + 0.25, 0.0, 1.0))
		var label_anchor := Vector2.ZERO
		match String(region.get("shape", "")):
			"rect":
				var values: Array = region.get("rect", [])
				var rect := Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))
				draw_rect(rect, fill, true)
				draw_rect(rect, outline, false, 2.0)
				label_anchor = rect.position + Vector2(6, LABEL_FONT_SIZE + 4)
			"polyline":
				var points: Array = region.get("points", [])
				var packed := PackedVector2Array()
				for point: Variant in points:
					if point is Array and (point as Array).size() >= 2:
						packed.append(Vector2(float((point as Array)[0]), float((point as Array)[1])))
				if packed.size() >= 2:
					draw_polyline(packed, outline, 6.0)
					label_anchor = packed[0] + Vector2(6, -8)
			"circle":
				var center_values: Array = region.get("center", [])
				var center := Vector2(float(center_values[0]), float(center_values[1]))
				var radius := float(region.get("radius", 0.0))
				draw_circle(center, radius, fill)
				draw_arc(center, radius, 0.0, TAU, 48, outline, 2.0)
				label_anchor = center + Vector2(-radius + 6, -radius - 6)
		if show_labels:
			var label := String(region.get("label", ""))
			if label != "":
				draw_string(font, label_anchor, "%s [%s]" % [label, kind], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, outline)


func _draw_dependency_arrows() -> void:
	var arrow_color := Color(1.0, 1.0, 1.0, clampf(opacity + 0.1, 0.0, 1.0))
	for entry: Variant in Spec.mechanic_slots(_spec):
		if not (entry is Dictionary):
			continue
		var slot := entry as Dictionary
		var to_pos: Vector2 = Spec.slot_position(slot)
		var depends: Variant = slot.get("depends_on", [])
		if not (depends is Array):
			continue
		for dependency: Variant in (depends as Array):
			var from_slot := Spec.find_slot(_spec, String(dependency))
			if from_slot.is_empty():
				continue
			_draw_arrow(Spec.slot_position(from_slot), to_pos, arrow_color)


func _draw_arrow(from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	var direction := to_pos - from_pos
	if direction.length() < SLOT_MARKER_RADIUS * 2.0 + 4.0:
		return
	var unit := direction.normalized()
	var start := from_pos + unit * SLOT_MARKER_RADIUS
	var end := to_pos - unit * (SLOT_MARKER_RADIUS + 6.0)
	draw_dashed_line(start, end, color, 2.0, 8.0)
	var head_size := 10.0
	var left := end - unit.rotated(0.5) * head_size
	var right := end - unit.rotated(-0.5) * head_size
	draw_line(end, left, color, 2.0)
	draw_line(end, right, color, 2.0)


func _draw_mechanic_slots(font: Font) -> void:
	for entry: Variant in Spec.mechanic_slots(_spec):
		if not (entry is Dictionary):
			continue
		var slot := entry as Dictionary
		var mechanic_type := String(slot.get("mechanic_type", ""))
		var position_2d: Vector2 = Spec.slot_position(slot)
		var base_color: Color = Spec.color_for_type(mechanic_type)
		var fill := Color(base_color.r, base_color.g, base_color.b, clampf(opacity + 0.15, 0.0, 1.0))
		var outline := Color(0, 0, 0, clampf(opacity + 0.3, 0.0, 1.0))
		var size: Vector2 = Spec.slot_size(slot)
		if size != Vector2.ZERO:
			var zone_rect := Rect2(position_2d - size * 0.5, size)
			draw_rect(zone_rect, Color(base_color.r, base_color.g, base_color.b, 0.25 * opacity), true)
			draw_rect(zone_rect, fill, false, 2.0)
		draw_circle(position_2d, SLOT_MARKER_RADIUS, fill)
		draw_arc(position_2d, SLOT_MARKER_RADIUS, 0.0, TAU, 32, outline, 2.0)
		if show_labels:
			var slot_id := String(slot.get("slot_id", ""))
			var label_pos := position_2d + Vector2(SLOT_MARKER_RADIUS + 4.0, -2.0)
			draw_string(font, label_pos, mechanic_type, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, fill)
			draw_string(font, label_pos + Vector2(0, LABEL_FONT_SIZE + 3), slot_id, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color(1, 1, 1, clampf(opacity + 0.2, 0.0, 1.0)))


func _draw_legend(font: Font, canvas: Vector2) -> void:
	var used_kinds: Dictionary = {}
	for entry: Variant in Spec.regions(_spec):
		if entry is Dictionary:
			used_kinds[String((entry as Dictionary).get("kind", ""))] = true
	var used_categories: Dictionary = {}
	for entry: Variant in Spec.mechanic_slots(_spec):
		if entry is Dictionary:
			used_categories[Spec.category_for_type(String((entry as Dictionary).get("mechanic_type", "")))] = true
	var line_height := LEGEND_FONT_SIZE + 6
	var entry_count := used_kinds.size() + used_categories.size()
	var legend_height := (entry_count + 1) * line_height + 12
	var legend_origin := Vector2(canvas.x + 24.0, 0.0)
	var legend_width := 260.0
	var text_alpha := clampf(opacity + 0.35, 0.0, 1.0)
	draw_rect(Rect2(legend_origin, Vector2(legend_width, legend_height)), Color(0.08, 0.09, 0.12, 0.85), true)
	draw_rect(Rect2(legend_origin, Vector2(legend_width, legend_height)), Color(0.85, 0.9, 1.0, text_alpha), false, 1.0)
	var cursor := legend_origin + Vector2(8, line_height)
	draw_string(font, cursor, "LEGEND", HORIZONTAL_ALIGNMENT_LEFT, -1, LEGEND_FONT_SIZE, Color(1, 1, 1, text_alpha))
	for kind: String in Spec.REGION_KINDS:
		if not used_kinds.has(kind):
			continue
		cursor.y += line_height
		var color: Color = Spec.region_color(kind)
		draw_rect(Rect2(cursor + Vector2(0, -LEGEND_FONT_SIZE + 2), Vector2(LEGEND_FONT_SIZE, LEGEND_FONT_SIZE)), Color(color.r, color.g, color.b, 0.9), true)
		draw_string(font, cursor + Vector2(LEGEND_FONT_SIZE + 6, 0), "region: %s" % kind, HORIZONTAL_ALIGNMENT_LEFT, -1, LEGEND_FONT_SIZE, Color(1, 1, 1, text_alpha))
	for category: String in Spec.CATEGORY_COLORS.keys():
		if not used_categories.has(category):
			continue
		cursor.y += line_height
		var color: Color = Spec.CATEGORY_COLORS.get(category, Color.WHITE)
		draw_circle(cursor + Vector2(LEGEND_FONT_SIZE * 0.5, -LEGEND_FONT_SIZE * 0.35), LEGEND_FONT_SIZE * 0.5, Color(color.r, color.g, color.b, 0.9))
		draw_string(font, cursor + Vector2(LEGEND_FONT_SIZE + 6, 0), "mechanic: %s" % category, HORIZONTAL_ALIGNMENT_LEFT, -1, LEGEND_FONT_SIZE, Color(1, 1, 1, text_alpha))
