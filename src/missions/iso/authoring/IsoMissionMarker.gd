@tool
class_name IsoMissionMarker
extends Node2D

@export_enum(
	"player_spawn",
	"bentley_spawn",
	"guard_spawn",
	"ambush_guard_spawn",
	"extra_heat_guard_spawn",
	"patrol_point",
	"security_camera",
	"camera_terminal",
	"camera_cone",
	"alarm_zone",
	"detection_zone",
	"shadow_zone",
	"bright_zone",
	"flicker_zone",
	"louis",
	"objective",
	"clue",
	"keycard",
	"code_gate",
	"route_access",
	"transition",
	"exit",
	"polaroid_hidden",
	"polaroid_completion",
	"polaroid_perfect",
	"glow_guy",
	"tiny_icon",
	"poop_bag",
	"scent_trail_real",
	"scent_trail_fake",
	"bentley_sniff_zone",
	"bentley_vent_route",
	"bentley_exit",
	"ambush_trigger",
	"camera_shake_trigger",
	"alarm_trigger",
	"dialogue_trigger",
	"transition_entry",
	"transition_exit",
	"return_spawn"
) var marker_type: String = "objective":
	set(value):
		marker_type = value
		queue_redraw()
		_refresh_label()
@export var marker_id: String = "":
	set(value):
		marker_id = value
		_refresh_label()
@export var display_name: String = "":
	set(value):
		display_name = value
		_refresh_label()
@export var required := false
@export var linked_objective_id: String = ""
@export var linked_clue_id: String = ""
@export var linked_collectible_id: String = ""
@export var linked_route_id: String = ""
@export var linked_guard_id: String = ""
@export var linked_camera_id: String = ""
@export var group_id: String = ""
@export var interactable := true
@export var marker_purpose: String = "gameplay"
@export var editor_display_name: String = ""
@export var debug_label: String = ""
@export var authoring_note: String = ""
@export var order: int = 0
@export var interaction_text: String = ""
@export var locked_message: String = ""
@export var unlocked_message: String = ""
@export var runtime_scene: String = ""
@export var runtime_class: String = ""
@export var route_id: String = ""
@export var route_role: String = ""
@export var linked_entry_spawn_id: String = ""
@export var linked_return_trigger_id: String = ""
@export var linked_return_destination_id: String = ""
@export var bypasses_challenge_id: String = ""
@export var scent_group_id: String = ""
@export var scent_role: String = ""
@export var heat_level_applicability: String = ""
@export var player_facing_label: String = ""
@export var radius: float = 18.0:
	set(value):
		radius = maxf(4.0, value)
		queue_redraw()
@export var zone_size: Vector2 = Vector2(36, 36):
	set(value):
		zone_size = Vector2(maxf(8.0, value.x), maxf(8.0, value.y))
		queue_redraw()
@export var debug_color: Color = Color(0.2, 0.95, 1.0, 0.95):
	set(value):
		debug_color = value
		queue_redraw()
@export var notes: String = ""
@export var show_editor_label := true:
	set(value):
		show_editor_label = value
		_refresh_label()

var _label: Label = null


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	_ensure_label()
	_refresh_label()


func _draw() -> void:
	var fill := debug_color
	fill.a = 0.22
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, debug_color, 2.0)
	if zone_size.x > radius * 1.6 or zone_size.y > radius * 1.6:
		var rect := Rect2(-zone_size * 0.5, zone_size)
		var frame := debug_color
		frame.a = 0.8
		draw_rect(rect, Color(fill.r, fill.g, fill.b, 0.12), true)
		draw_rect(rect, frame, false, 1.0)


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = Label.new()
	_label.name = "EditorLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector2(-80, -42)
	_label.size = Vector2(160, 18)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)
	_label.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self


func _refresh_label() -> void:
	if _label == null:
		return
	if not show_editor_label:
		_label.visible = false
		return
	var short := debug_label.strip_edges().to_upper()
	if short == "":
		short = marker_type.to_upper()
	if short.length() > 16:
		short = short.substr(0, 16)
	var parts: Array[String] = [short]
	if editor_display_name.strip_edges() != "":
		parts.append(editor_display_name.strip_edges())
	elif marker_id != "":
		parts.append(marker_id)
	elif display_name != "":
		parts.append(display_name)
	_label.text = " ".join(parts)
	_label.visible = true
