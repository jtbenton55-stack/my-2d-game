@tool
extends StaticBody2D
## D6-05A/B/C/D proof-only test door. Blocks passage when locked (walls layer 4 + enabled shape).

const WALLS_COLLISION_LAYER_BIT := 3
const WALLS_COLLISION_LAYER_VALUE := 4

@export var start_unlocked := true
@export var barrier_size := Vector2(140.0, 32.0):
	set(value):
		barrier_size = value
		_apply_barrier_size()

@export_group("Orientation")
@export var snap_rotation_to_15_degrees := true
@export var rotation_snap_degrees: float = 15.0
@export var orientation_degrees: float = 0.0:
	set(value):
		orientation_degrees = _snap_degrees(value)
		rotation_degrees = orientation_degrees
		_apply_barrier_size()
		queue_redraw()

var _locked := false
var _visual: ColorRect = null
var _label: Label = null


func _ready() -> void:
	add_to_group("d6_05a_test_door_lock")
	collision_mask = 0
	z_index = 8
	_ensure_visual_children()
	if snap_rotation_to_15_degrees:
		rotation_degrees = _snap_degrees(rotation_degrees)
	orientation_degrees = rotation_degrees
	apply_locked_state(not start_unlocked)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if snap_rotation_to_15_degrees:
		var snapped := _snap_degrees(rotation_degrees)
		if not is_equal_approx(snapped, rotation_degrees):
			rotation_degrees = snapped
	if not is_equal_approx(orientation_degrees, rotation_degrees):
		orientation_degrees = rotation_degrees
	queue_redraw()


func _draw() -> void:
	var half := barrier_size * 0.5
	var rect := Rect2(-half, barrier_size)
	var fill := Color(0.9, 0.15, 0.1, 0.35) if _locked else Color(0.15, 0.85, 0.3, 0.35)
	var border := Color(1.0, 0.2, 0.15, 0.95) if _locked else Color(0.2, 1.0, 0.4, 0.95)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 3.0)


## Single source of truth for lock state (visual + physics). Returns runtime debug dict.
func apply_locked_state(locked: bool) -> Dictionary:
	set_locked(locked)
	return get_runtime_debug_state()


func set_locked(locked: bool) -> void:
	_locked = locked
	_apply_physics_locked(locked)
	_ensure_visual_children()
	_update_visual()
	set_meta("d6_05a_lock_state", "locked" if locked else "unlocked")
	queue_redraw()


func is_locked() -> bool:
	return _locked


func get_lock_state() -> String:
	return "locked" if _locked else "unlocked"


func toggle_locked() -> void:
	apply_locked_state(not _locked)


func get_runtime_debug_state() -> Dictionary:
	var shape := _get_collision_shape()
	var shape_enabled := shape != null and not shape.disabled
	var layer_on := (collision_layer & WALLS_COLLISION_LAYER_VALUE) != 0
	var collision_enabled := shape_enabled and layer_on
	return {
		"path": str(get_path()),
		"lock_state": get_lock_state(),
		"collision_layer": collision_layer,
		"collision_shape_enabled": shape_enabled,
		"collision_enabled": collision_enabled,
		"physics_matches_visual": collision_enabled == _locked,
		"orientation_degrees": rotation_degrees,
		"global_position": global_position,
	}


func _apply_physics_locked(locked: bool) -> void:
	var shape := _get_collision_shape()
	if shape == null:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = barrier_size
		shape.shape = rect
		add_child(shape)
		if Engine.is_editor_hint() and get_tree() != null:
			shape.owner = get_tree().edited_scene_root
	if shape.shape is RectangleShape2D:
		(shape.shape as RectangleShape2D).size = barrier_size
	shape.disabled = not locked
	set_collision_layer_value(WALLS_COLLISION_LAYER_BIT, locked)
	collision_layer = WALLS_COLLISION_LAYER_VALUE if locked else 0
	shape.set_deferred("disabled", not locked)
	set_deferred("collision_layer", WALLS_COLLISION_LAYER_VALUE if locked else 0)


func _get_collision_shape() -> CollisionShape2D:
	return get_node_or_null("CollisionShape2D") as CollisionShape2D


func _snap_degrees(deg: float) -> float:
	if not snap_rotation_to_15_degrees:
		return deg
	var step := maxf(1.0, rotation_snap_degrees)
	var n := roundf(deg / step)
	var snapped := fmod(n * step, 360.0)
	if snapped < 0.0:
		snapped += 360.0
	return snapped


func _ensure_visual_children() -> void:
	_visual = get_node_or_null("DoorVisual") as ColorRect
	if _visual == null:
		_visual = ColorRect.new()
		_visual.name = "DoorVisual"
		_visual.z_index = 5
		add_child(_visual)
		if Engine.is_editor_hint() and get_tree() != null:
			_visual.owner = get_tree().edited_scene_root
	_label = get_node_or_null("DoorLabel") as Label
	if _label == null:
		_label = Label.new()
		_label.name = "DoorLabel"
		_label.z_index = 6
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 13)
		add_child(_label)
		if Engine.is_editor_hint() and get_tree() != null:
			_label.owner = get_tree().edited_scene_root
	_apply_barrier_size()


func _apply_barrier_size() -> void:
	var shape := _get_collision_shape()
	if shape != null and shape.shape is RectangleShape2D:
		(shape.shape as RectangleShape2D).size = barrier_size
	if _visual != null:
		_visual.position = Vector2(-barrier_size.x * 0.5, -barrier_size.y * 0.5)
		_visual.size = barrier_size
	if _label != null:
		_label.position = Vector2(-barrier_size.x * 0.5, -barrier_size.y - 24.0)
		_label.size = Vector2(barrier_size.x, 22.0)
		_label.rotation = -rotation


func _update_visual() -> void:
	if _visual != null:
		_visual.color = Color(0.95, 0.18, 0.12, 0.82) if _locked else Color(0.18, 0.92, 0.32, 0.72)
	if _label != null:
		_label.text = "D6-05A TEST LOCK DOOR [%s]" % get_lock_state().to_upper()
	queue_redraw()
