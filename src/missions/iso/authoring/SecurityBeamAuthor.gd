@tool
extends Node2D

const MIN_VISUAL_HEIGHT := 16.0
const MAX_VISUAL_HEIGHT := 640.0
const MIN_VISUAL_WIDTH := 4.0
const MAX_VISUAL_WIDTH := 96.0
const MIN_TRIGGER_WIDTH := 8.0
const MAX_TRIGGER_WIDTH := 256.0
const MAX_TRIGGER_EXTRA_HEIGHT := 128.0

@export_group("Beam Identity")
@export var beam_id: StringName = &"AMBUSH_security_beam"
@export var enabled := true
@export var alarm_id: StringName = &"AMBUSH_security_beam"
@export var one_shot := true

@export_group("Security Events")
@export var on_trip_event: StringName = &"ambush_beam_tripped"
@export var emit_event_on_trip := true

@export_group("Visual")
@export_range(16.0, 640.0, 1.0, "suffix:px") var visual_height: float = 340.0
@export_range(4.0, 96.0, 1.0, "suffix:px") var visual_width: float = 32.0
@export var preview_color: Color = Color(1.0, 0.1, 0.1, 0.95)

@export_group("Trigger")
@export_range(8.0, 256.0, 1.0, "suffix:px") var trigger_width: float = 72.0
@export_range(0.0, 128.0, 1.0, "suffix:px") var trigger_extra_height: float = 16.0

@export_group("Editor Preview")
@export var show_label := true
@export var show_trigger_preview := true
@export_range(0.0, 64.0, 1.0, "suffix:px") var snap_height_step: float = 0.0
@export_multiline var authoring_notes: String = ""

var _label: Label = null
var _editor_preview_sig: String = ""


func _ready() -> void:
	_sanitize_exports(false)
	if Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)
	_ensure_label()
	_refresh_label()
	queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var sig := _preview_signature()
	if sig != _editor_preview_sig:
		_editor_preview_sig = sig
		queue_redraw()
		_refresh_label()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if String(beam_id).strip_edges() == "":
		warnings.append("beam_id is empty.")
	if not enabled:
		warnings.append("Beam is disabled; runtime will use FIX7F fallback if no other enabled author matches.")
	if get_clamped_visual_height() < 48.0:
		warnings.append("visual_height is very short; increase for hallway coverage.")
	if get_clamped_trigger_width() < get_clamped_visual_width():
		warnings.append("trigger_width is narrower than visual_width; trips may be hard to register.")
	return warnings


func get_clamped_visual_height() -> float:
	return _snap_height(visual_height)


func get_clamped_visual_width() -> float:
	return clampf(visual_width, MIN_VISUAL_WIDTH, MAX_VISUAL_WIDTH)


func get_clamped_trigger_width() -> float:
	return clampf(trigger_width, MIN_TRIGGER_WIDTH, MAX_TRIGGER_WIDTH)


func get_clamped_trigger_extra_height() -> float:
	return clampf(trigger_extra_height, 0.0, MAX_TRIGGER_EXTRA_HEIGHT)


func get_trigger_height() -> float:
	return get_clamped_visual_height() + get_clamped_trigger_extra_height() * 2.0


func get_beam_center_global() -> Vector2:
	return global_position


func get_visual_half_height() -> float:
	return get_clamped_visual_height() * 0.5


func get_trigger_size() -> Vector2:
	return Vector2(get_clamped_trigger_width(), get_trigger_height())


func get_runtime_alarm_id() -> String:
	var id := String(alarm_id).strip_edges()
	if id == "":
		return String(beam_id).strip_edges()
	return id


func get_validation_status() -> String:
	if String(beam_id).strip_edges() == "":
		return "invalid_empty_beam_id"
	if not enabled:
		return "disabled"
	return "ok"


func build_runtime_config() -> Dictionary:
	_sanitize_exports(false)
	var vh := get_clamped_visual_height()
	var vw := get_clamped_visual_width()
	var tw := get_clamped_trigger_width()
	var te := get_clamped_trigger_extra_height()
	var trig := Vector2(tw, get_trigger_height())
	return {
		"beam_id": String(beam_id),
		"enabled": enabled,
		"on_trip_event": String(on_trip_event),
		"emit_event_on_trip": emit_event_on_trip,
		"center": get_beam_center_global(),
		"visual_height": vh,
		"visual_width": vw,
		"visual_half_height": vh * 0.5,
		"trigger_size": trig,
		"trigger_width": tw,
		"trigger_height": trig.y,
		"trigger_extra_height": te,
		"alarm_id": get_runtime_alarm_id(),
		"one_shot": one_shot,
		"author_path": str(get_path()),
		"validation_status": get_validation_status(),
	}


func _draw() -> void:
	if not _should_draw_preview():
		return
	var half_h := get_visual_half_height()
	var line_w := get_clamped_visual_width()
	var line_col := preview_color
	line_col.a = 0.95
	draw_line(Vector2(0.0, -half_h), Vector2(0.0, half_h), line_col, line_w)
	draw_circle(Vector2(0.0, -half_h), 5.0, Color(1.0, 0.85, 0.2, 0.9))
	draw_circle(Vector2(0.0, half_h), 5.0, Color(1.0, 0.85, 0.2, 0.9))
	draw_circle(Vector2.ZERO, 4.0, Color(0.2, 1.0, 0.4, 0.95))
	if show_trigger_preview:
		var trig_h := get_trigger_height() * 0.5
		var tw := get_clamped_trigger_width()
		var trig_col := Color(preview_color.r, preview_color.g, preview_color.b, 0.35)
		var trig_rect := Rect2(Vector2(-tw * 0.5, -trig_h), Vector2(tw, trig_h * 2.0))
		draw_rect(trig_rect, trig_col, false, 2.0)


func _should_draw_preview() -> bool:
	if Engine.is_editor_hint():
		return true
	var parent_root := get_parent()
	if parent_root != null and parent_root.has_method("collect_beam_authors"):
		return bool(parent_root.get("show_previews"))
	return false


func _ensure_label() -> void:
	if _label == null or not is_instance_valid(_label):
		_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "AuthorLabel"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.size = Vector2(180.0, 22.0)
		_label.add_theme_font_size_override("font_size", 11)
		add_child(_label)
		if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
			_label.owner = get_tree().edited_scene_root


func _refresh_label() -> void:
	_ensure_label()
	if _label == null:
		return
	_label.visible = show_label and _should_draw_preview()
	_label.text = "BEAM %s  h=%.0f" % [String(beam_id), get_clamped_visual_height()]
	_label.position = Vector2(-90.0, -get_visual_half_height() - 52.0)


func _sanitize_exports(mark_dirty: bool) -> void:
	var snapped_h := _snap_height(visual_height)
	var clamped_w := clampf(visual_width, MIN_VISUAL_WIDTH, MAX_VISUAL_WIDTH)
	var clamped_tw := clampf(trigger_width, MIN_TRIGGER_WIDTH, MAX_TRIGGER_WIDTH)
	var clamped_te := clampf(trigger_extra_height, 0.0, MAX_TRIGGER_EXTRA_HEIGHT)
	var changed := false
	if not is_equal_approx(visual_height, snapped_h):
		visual_height = snapped_h
		changed = true
	if not is_equal_approx(visual_width, clamped_w):
		visual_width = clamped_w
		changed = true
	if not is_equal_approx(trigger_width, clamped_tw):
		trigger_width = clamped_tw
		changed = true
	if not is_equal_approx(trigger_extra_height, clamped_te):
		trigger_extra_height = clamped_te
		changed = true
	if changed and mark_dirty and Engine.is_editor_hint():
		queue_redraw()
		_refresh_label()


func _snap_height(raw: float) -> float:
	var clamped := clampf(raw, MIN_VISUAL_HEIGHT, MAX_VISUAL_HEIGHT)
	if snap_height_step > 0.0:
		clamped = roundf(clamped / snap_height_step) * snap_height_step
		clamped = clampf(clamped, MIN_VISUAL_HEIGHT, MAX_VISUAL_HEIGHT)
	return clamped


func _preview_signature() -> String:
	return "%s|%s|%.3f|%.3f|%.3f|%.3f|%s|%s|%s" % [
		String(beam_id),
		str(enabled),
		visual_height,
		visual_width,
		trigger_width,
		trigger_extra_height,
		str(show_label),
		str(show_trigger_preview),
		preview_color.to_html(false),
	]
