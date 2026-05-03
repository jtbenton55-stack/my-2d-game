class_name MissionCameraShake
extends Node

@export var enabled := true
@export var max_offset: float = 10.0

var _camera: Camera2D = null
var _base_offset := Vector2.ZERO
var _time_left := 0.0
var _intensity := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_camera = get_parent() as Camera2D
	if _camera != null:
		_base_offset = _camera.offset
	if not EventBus.screen_shake.is_connected(shake):
		EventBus.screen_shake.connect(shake)
	set_process(true)


func _exit_tree() -> void:
	if EventBus.screen_shake.is_connected(shake):
		EventBus.screen_shake.disconnect(shake)
	_restore()


func _process(delta: float) -> void:
	if not enabled or _camera == null:
		return
	if _time_left <= 0.0:
		_restore()
		return
	_time_left -= delta
	var amount := minf(max_offset, _intensity * max_offset)
	_camera.offset = _base_offset + Vector2(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount))
	if _time_left <= 0.0:
		_restore()


func shake(intensity: float, duration: float) -> void:
	if not enabled:
		return
	if _camera == null:
		push_warning("MissionCameraShake: camera missing, cannot shake.")
		return
	EventBus.debug("Camera shake: intensity %.2f duration %.2f" % [intensity, duration])
	_intensity = maxf(_intensity, clampf(intensity / 8.0, 0.05, 1.0))
	_time_left = maxf(_time_left, duration)


func _restore() -> void:
	if _camera != null:
		_camera.offset = _base_offset
	_intensity = 0.0
