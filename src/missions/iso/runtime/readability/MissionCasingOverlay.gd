class_name MissionCasingOverlay
extends Node2D

## Casing Mode (hold the case_the_joint action): renders the player's own
## crime scene in world space -- paper traces, physical mess, recent noise
## memory, and a cover summary line (Replan Packet 1).

const TRACE_COLOR_ACTIVE := Color(1.0, 0.45, 0.3, 0.9)
const TRACE_COLOR_REDIRECTED := Color(0.7, 0.5, 1.0, 0.9)
const TRACE_COLOR_CLEANED := Color(0.4, 0.9, 0.5, 0.55)
const MESS_COLOR := Color(0.75, 0.55, 0.3, 0.9)
const NOISE_MEMORY_COLOR := Color(1.0, 0.85, 0.4, 0.35)

@export var action_casing: StringName = &"case_the_joint"
@export var summary_offset: Vector2 = Vector2(0.0, -96.0)

var casing_active: bool = false


func _ready() -> void:
	z_as_relative = false
	z_index = 220


func _process(_delta: float) -> void:
	var next_active := _is_casing_pressed()
	if next_active != casing_active:
		casing_active = next_active
		queue_redraw()
	elif casing_active:
		queue_redraw()


func _draw() -> void:
	if not casing_active:
		return
	var font := ThemeDB.fallback_font
	_draw_paper_traces(font)
	_draw_mess_spots(font)
	_draw_noise_memory()
	_draw_cover_summary(font)


func _is_casing_pressed() -> bool:
	var action := String(action_casing)
	return InputMap.has_action(action) and Input.is_action_pressed(action)


func _resolved_mission_id() -> String:
	return MissionFactBridge.resolve_mission_id({})


func _draw_paper_traces(font: Font) -> void:
	for event in PaperTrailAdapter.get_trace_events(_resolved_mission_id()):
		if not event.has("position"):
			continue
		var pos := to_local(event.get("position", Vector2.ZERO))
		var status := String(event.get("status", "active"))
		var severity := int(event.get("severity", 0))
		var color := TRACE_COLOR_ACTIVE
		if status == "cleaned" or severity <= 0:
			color = TRACE_COLOR_CLEANED
		elif status == "redirected":
			color = TRACE_COLOR_REDIRECTED
		draw_circle(pos, 9.0, Color(0.05, 0.05, 0.08, 0.75))
		draw_arc(pos, 9.0, 0.0, TAU, 24, color, 2.5)
		var label := String(event.get("trace_type", "trace"))
		if severity > 0 and status != "cleaned":
			label += " x%d" % severity
		draw_string(font, pos + Vector2(12.0, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, color)


func _draw_mess_spots(font: Font) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("mission_mess"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var pos := to_local((node as Node2D).global_position)
		draw_circle(pos, 8.0, Color(MESS_COLOR.r, MESS_COLOR.g, MESS_COLOR.b, 0.35))
		draw_arc(pos, 8.0, 0.0, TAU, 20, MESS_COLOR, 2.0)
		var label := "mess"
		if node.has_method("get_mess_label"):
			label = String(node.call("get_mess_label"))
		draw_string(font, pos + Vector2(11.0, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, MESS_COLOR)


func _draw_noise_memory() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var controller := tree.get_first_node_in_group("iso_alert_controller")
	if controller == null or not controller.has_method("get_noise_debug_summary"):
		return
	var summary: Dictionary = controller.call("get_noise_debug_summary")
	var recent: Array = summary.get("recent_noise_events", [])
	for event: Variant in recent:
		if not (event is Dictionary) or not (event as Dictionary).has("position"):
			continue
		var evt := event as Dictionary
		var pos := to_local(evt.get("position", Vector2.ZERO))
		draw_arc(pos, float(evt.get("radius", 64.0)), 0.0, TAU, 40, NOISE_MEMORY_COLOR, 1.5)


func _draw_cover_summary(font: Font) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player")
	if not (player is Node2D):
		return
	var mid := _resolved_mission_id()
	var social := SocialStealthAdapter.get_summary(mid)
	var paper := PaperTrailAdapter.get_summary(mid)
	var line := "Cover %d | Mess debt %d | Traces %d active" % [
		int(social.get("professionalism", 0)),
		_open_mess_count(),
		int(paper.get("active_events", 0)),
	]
	var pos := to_local((player as Node2D).global_position) + summary_offset
	var text_size := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13)
	draw_rect(Rect2(pos - Vector2(text_size.x * 0.5 + 6.0, 14.0), text_size + Vector2(12.0, 8.0)), Color(0.05, 0.05, 0.08, 0.8))
	draw_string(font, pos - Vector2(text_size.x * 0.5, 0.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.95, 0.92, 0.8))


func _open_mess_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for node in tree.get_nodes_in_group("mission_mess"):
		if node is Node2D and is_instance_valid(node):
			count += 1
	return count
