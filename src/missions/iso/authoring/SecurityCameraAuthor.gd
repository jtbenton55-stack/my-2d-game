@tool
extends Node2D

@export_group("Identity")
@export var camera_id: StringName = &"security_camera"
@export var enabled := true

@export_group("Vision")
@export var range_px: float = 320.0
@export var fov_degrees: float = 55.0
@export var direction_degrees: float = 0.0
@export var require_line_of_sight: bool = false
@export_flags_2d_physics var occlusion_collision_mask: int = 4
@export var occlude_cover_tiles: bool = true
@export_range(3, 65, 2) var visible_cone_ray_count: int = 17
@export var show_visible_cone: bool = true

@export_group("Sweep")
@export var sweep_enabled := false
@export var sweep_arc_degrees: float = 90.0
@export var sweep_speed_degrees: float = 45.0
@export var sweep_readability_label: String = ""

@export_group("Detection")
@export var detection_rate: float = 0.7
@export var detection_decay: float = 0.4
@export var alarm_threshold: float = 1.0
@export var exposure_requires_player_movement := false
@export var player_movement_threshold: float = 8.0
@export var minimum_exposure_seconds: float = 0.0
@export var show_exposure_countdown_ring := true

@export_group("Events")
@export var on_detect_event: StringName = &""
@export var on_alarm_event: StringName = &"camera_alarm"
@export var emit_detect_event := false
@export var emit_alarm_event := true

@export_group("Editor Preview")
@export var preview_color: Color = Color(0.2, 0.75, 1.0, 0.85)
@export var show_label := true
@export var show_cone_preview := true

var _label: Label = null
var _editor_preview_sig: String = ""
var _runtime_camera: Node = null


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


func build_runtime_config() -> Dictionary:
	return {
		"camera_id": String(camera_id),
		"enabled": enabled,
		"range_px": range_px,
		"fov_degrees": fov_degrees,
		"direction_degrees": direction_degrees,
		"require_line_of_sight": require_line_of_sight,
		"occlusion_collision_mask": occlusion_collision_mask,
		"occlude_cover_tiles": occlude_cover_tiles,
		"visible_cone_ray_count": visible_cone_ray_count,
		"show_visible_cone": show_visible_cone,
		"sweep_enabled": sweep_enabled,
		"sweep_arc_degrees": sweep_arc_degrees,
		"sweep_speed_degrees": sweep_speed_degrees,
		"sweep_readability_label": sweep_readability_label,
		"detection_rate": detection_rate,
		"detection_decay": detection_decay,
		"alarm_threshold": alarm_threshold,
		"exposure_requires_player_movement": exposure_requires_player_movement,
		"player_movement_threshold": player_movement_threshold,
		"minimum_exposure_seconds": minimum_exposure_seconds,
		"show_exposure_countdown_ring": show_exposure_countdown_ring,
		"on_detect_event": String(on_detect_event),
		"on_alarm_event": String(on_alarm_event),
		"emit_detect_event": emit_detect_event,
		"emit_alarm_event": emit_alarm_event,
		"author_path": str(get_path()) if is_inside_tree() else "",
	}


func setup_runtime_camera(mission: Node, router: Node) -> Node:
	if Engine.is_editor_hint() or not enabled:
		return null
	var cfg := build_runtime_config()
	cfg["parity_target"] = "CAM_market_01"
	cfg["parity_script"] = "res://src/missions/iso/runtime/MissionSecurityCamera.gd"
	var parent := _resolve_camera_parent(mission)
	if parent == null:
		return null
	var cam_name := "AuthoredCamera_%s" % String(camera_id)
	var existing := parent.get_node_or_null(cam_name)
	if existing != null:
		existing.queue_free()
	var script := load("res://src/missions/iso/runtime/MissionSecurityCamera.gd") as Script
	if script == null:
		return null
	## Match Phase0KCameraSpawner: Area2D + MissionSecurityCamera script, parent first, then world pose.
	var camera := Area2D.new()
	camera.name = cam_name
	camera.set_script(script)
	camera.set_meta("generated_by", "SecurityCameraAuthor")
	camera.set_meta("authored_camera", true)
	camera.set_meta("author_path", str(get_path()))
	camera.set_meta("parity_target", "CAM_market_01")
	parent.add_child(camera)
	camera.global_position = global_position
	camera.global_rotation = deg_to_rad(direction_degrees)
	if camera.has_method("apply_authoring_config"):
		camera.call("apply_authoring_config", cfg)
	else:
		_apply_config_to_camera(camera, cfg)
	if camera.has_method("refresh_sweep_basis_from_world"):
		camera.call_deferred("refresh_sweep_basis_from_world")
	if mission.has_method("_bind_authored_security_camera"):
		mission.call("_bind_authored_security_camera", camera, self, router, cfg)
	_runtime_camera = camera
	return camera


func _resolve_camera_parent(mission: Node) -> Node2D:
	var cameras := mission.get_node_or_null("EntityRoot/Cameras") as Node2D
	if cameras != null:
		return cameras
	var entity_root := mission.get_node_or_null("EntityRoot") as Node2D
	if entity_root == null:
		return null
	cameras = entity_root.get_node_or_null("Cameras") as Node2D
	if cameras == null:
		cameras = Node2D.new()
		cameras.name = "Cameras"
		entity_root.add_child(cameras)
	return cameras


func _apply_config_to_camera(camera: Area2D, cfg: Dictionary) -> void:
	if camera.has_method("apply_authoring_config"):
		camera.call("apply_authoring_config", cfg)
		return
	camera.set("camera_id", String(cfg.get("camera_id", "security_camera")))
	camera.set("sight_range", float(cfg.get("range_px", 320.0)))
	camera.set("fov_angle_degrees", float(cfg.get("fov_degrees", 55.0)))
	camera.set("detection_rate", float(cfg.get("detection_rate", 0.7)))
	camera.set("detection_decay", float(cfg.get("detection_decay", 0.4)))
	camera.set("detection_threshold", float(cfg.get("alarm_threshold", 1.0)))
	camera.set("enabled", bool(cfg.get("enabled", true)))
	var sweep_on := bool(cfg.get("sweep_enabled", false))
	if sweep_on:
		var arc := float(cfg.get("sweep_arc_degrees", 90.0))
		camera.set("sweep_min_degrees", -arc * 0.5)
		camera.set("sweep_max_degrees", arc * 0.5)
		camera.set("sweep_speed", float(cfg.get("sweep_speed_degrees", 45.0)) * 0.02)
	else:
		camera.set("sweep_min_degrees", 0.0)
		camera.set("sweep_max_degrees", 0.0)
		camera.set("sweep_speed", 0.0)


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_cone_preview:
		return
	var half_fov := deg_to_rad(clampf(fov_degrees, 8.0, 170.0) * 0.5)
	var dir := deg_to_rad(direction_degrees)
	var left := dir - half_fov
	var right := dir + half_fov
	var reach := maxf(32.0, range_px)
	var pts: PackedVector2Array = [Vector2.ZERO]
	pts.append(Vector2(cos(left), sin(left)) * reach)
	pts.append(Vector2(cos(right), sin(right)) * reach)
	var fill := preview_color
	fill.a = 0.18
	draw_colored_polygon(pts, fill)
	draw_polyline(pts, preview_color, 2.0, true)
	draw_line(Vector2.ZERO, Vector2(cos(dir), sin(dir)) * reach, preview_color.lightened(0.2), 2.0)
	if sweep_enabled:
		var arc_half := deg_to_rad(sweep_arc_degrees * 0.5)
		var s_left := dir - arc_half
		var s_right := dir + arc_half
		draw_arc(Vector2.ZERO, reach * 0.65, s_left, s_right, 16, preview_color.darkened(0.2), 1.5)
	draw_circle(Vector2.ZERO, 5.0, preview_color)


func _preview_signature() -> String:
	return "%s|%s|%.1f|%.1f|%.1f|%s" % [
		String(camera_id), str(enabled), range_px, fov_degrees, direction_degrees, str(sweep_enabled),
	]


func get_camera_readability_summary() -> String:
	var label := sweep_readability_label.strip_edges()
	if label == "":
		label = String(camera_id)
	if sweep_enabled:
		return "%s sweeps %.0f deg at %.0f deg/s" % [label, sweep_arc_degrees, sweep_speed_degrees]
	return "%s fixed %.0f deg cone" % [label, fov_degrees]


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	_label = get_node_or_null("AuthorLabel") as Label
	if _label == null:
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
	if _label == null or not show_label:
		return
	_label.text = "CAM %s -> %s\n%s" % [String(camera_id), String(on_alarm_event), get_camera_readability_summary()]
	_label.position = Vector2(-100.0, -maxf(32.0, range_px) - 24.0)
