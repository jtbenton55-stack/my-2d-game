@tool
extends Node2D

@export_group("Trigger Identity")
@export var trigger_id: StringName = &"area_trigger"
@export var enabled := true
@export var on_enter_event: StringName = &"test_area_entered"
@export var one_shot := true
@export var zone_display_name: String = ""

@export_group("Shape")
@export var trigger_size: Vector2 = Vector2(96.0, 96.0)
@export var preview_color: Color = Color(0.35, 0.55, 1.0, 0.85)

@export_group("Editor Preview")
@export var show_label := true
@export var show_trigger_preview := true

const PLAYER_COLLISION_MASK := 1

var _label: Label = null
var _editor_preview_sig: String = ""
var _runtime_area: Area2D = null
var _runtime_router: Node = null
var _runtime_mission: Node = null
var _tripped := false


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


func setup_runtime_trigger(mission: Node, router: Node) -> void:
	if Engine.is_editor_hint() or not enabled:
		return
	_runtime_mission = mission
	_runtime_router = router
	var parent := mission.get_node_or_null("GameplayRoot/RuntimeSystems/AuthoringAreaTriggers")
	if parent == null:
		parent = Node2D.new()
		parent.name = "AuthoringAreaTriggers"
		var systems := mission.get_node_or_null("GameplayRoot/RuntimeSystems")
		if systems != null:
			systems.add_child(parent)
		else:
			mission.add_child(parent)
	var area_name := "AreaTrigger_%s" % String(trigger_id)
	_runtime_area = parent.get_node_or_null(area_name) as Area2D
	if _runtime_area == null:
		_runtime_area = Area2D.new()
		_runtime_area.name = area_name
		parent.add_child(_runtime_area)
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = _clamped_trigger_size()
		shape.shape = rect
		_runtime_area.add_child(shape)
	_runtime_area.collision_layer = 0
	_runtime_area.collision_mask = PLAYER_COLLISION_MASK
	_runtime_area.monitorable = false
	_runtime_area.monitoring = true
	var cs := _runtime_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		cs = CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		_runtime_area.add_child(cs)
	if cs.shape == null or not (cs.shape is RectangleShape2D):
		cs.shape = RectangleShape2D.new()
	(cs.shape as RectangleShape2D).size = _clamped_trigger_size()
	cs.disabled = false
	if not _runtime_area.body_entered.is_connected(_on_runtime_body_entered):
		_runtime_area.body_entered.connect(_on_runtime_body_entered)
	_sync_runtime_area_transform()


func _sync_runtime_area_transform() -> void:
	if _runtime_area == null:
		return
	_runtime_area.global_position = global_position
	_runtime_area.global_rotation = global_rotation
	_runtime_area.global_scale = global_scale


func _on_runtime_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _tripped:
		return
	_tripped = true
	if one_shot and _runtime_area != null:
		_runtime_area.set_deferred("monitoring", false)
	var event_id := String(on_enter_event).strip_edges()
	if event_id == "" or _runtime_router == null:
		return
	var player_pos := Vector2.ZERO
	if body is Node2D:
		player_pos = (body as Node2D).global_position
	var heat := 0
	if GameState.has_method("get_mission_heat"):
		heat = int(GameState.get_mission_heat(String(GameState.current_mission_id)))
	var payload := {
		"source_type": "area_trigger_author",
		"source_id": String(trigger_id),
		"source_path": str(get_path()),
		"player_position": player_pos,
		"heat": heat,
		"timestamp": Time.get_ticks_msec(),
		"reason": "player_entered",
	}
	if _runtime_mission != null and _runtime_mission.has_method("record_d6_05c_zone_trigger"):
		_runtime_mission.call("record_d6_05c_zone_trigger", String(trigger_id), event_id, payload)
	_runtime_router.call("emit_event", StringName(event_id), payload)


func _clamped_trigger_size() -> Vector2:
	return Vector2(maxf(8.0, trigger_size.x), maxf(8.0, trigger_size.y))


func _draw() -> void:
	if not _should_draw_preview():
		return
	var sz := _clamped_trigger_size()
	var col := Color(preview_color.r, preview_color.g, preview_color.b, 0.22)
	var rect := Rect2(Vector2(-sz.x * 0.5, -sz.y * 0.5), sz)
	draw_rect(rect, col, true)
	draw_rect(rect, preview_color, false, 2.0)


func _should_draw_preview() -> bool:
	if Engine.is_editor_hint():
		return show_trigger_preview
	var root := get_parent()
	if root != null and root.has_method("collect_area_trigger_authors"):
		return bool(root.get("show_previews"))
	return false


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = Label.new()
	_label.name = "AuthorLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200.0, 22.0)
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)
	if Engine.is_editor_hint() and get_tree() != null and get_tree().edited_scene_root != null:
		_label.owner = get_tree().edited_scene_root


func _refresh_label() -> void:
	_ensure_label()
	if _label == null:
		return
	_label.visible = show_label and _should_draw_preview()
	var title := zone_display_name.strip_edges()
	if title == "":
		title = String(trigger_id)
	_label.text = "%s -> %s" % [title, String(on_enter_event)]
	_label.position = Vector2(-100.0, -_clamped_trigger_size().y * 0.5 - 28.0)


func _preview_signature() -> String:
	return "%s|%s|%.1f|%.1f|%s" % [
		String(trigger_id),
		String(on_enter_event),
		trigger_size.x,
		trigger_size.y,
		zone_display_name,
	]
