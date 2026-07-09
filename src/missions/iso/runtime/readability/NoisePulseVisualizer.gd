class_name NoisePulseVisualizer
extends Node2D

## Draws expanding rings at every mission noise event so players can read
## exactly how far their noise reached (Replan Packet 1).

const PULSE_LIFETIME := 0.9

var _pulses: Array[Dictionary] = []


func _ready() -> void:
	z_as_relative = false
	z_index = 200
	if EventBus.mission_noise_emitted.is_connected(_on_noise_emitted):
		return
	EventBus.mission_noise_emitted.connect(_on_noise_emitted)


func _process(delta: float) -> void:
	if _pulses.is_empty():
		return
	for pulse in _pulses:
		pulse["age"] = float(pulse.get("age", 0.0)) + delta
	_pulses = _pulses.filter(func(p: Dictionary) -> bool:
		return float(p.get("age", 0.0)) < PULSE_LIFETIME
	)
	queue_redraw()


func _draw() -> void:
	for pulse in _pulses:
		var age := float(pulse.get("age", 0.0))
		var progress := clampf(age / PULSE_LIFETIME, 0.0, 1.0)
		var target_radius := float(pulse.get("radius", 64.0))
		var radius := maxf(6.0, target_radius * progress)
		var alpha := (1.0 - progress) * 0.65
		var color: Color = pulse.get("color", Color(1.0, 0.75, 0.2))
		var center := to_local(pulse.get("position", Vector2.ZERO))
		draw_arc(center, radius, 0.0, TAU, 48, Color(color.r, color.g, color.b, alpha), 3.0)
		if progress < 0.35:
			draw_circle(center, 5.0, Color(color.r, color.g, color.b, alpha))


func _on_noise_emitted(noise_event: Dictionary) -> void:
	var team := String(noise_event.get("team", "neutral"))
	var kind := String(noise_event.get("kind", "generic"))
	var color := Color(1.0, 0.75, 0.2)
	if team != "player":
		color = Color(0.7, 0.7, 0.9)
	elif kind in ["decoy", "poop_decoy", "bark"]:
		color = Color(0.35, 0.85, 0.5)
	_pulses.append({
		"position": noise_event.get("position", Vector2.ZERO),
		"radius": float(noise_event.get("radius", 64.0)),
		"age": 0.0,
		"color": color,
	})
	queue_redraw()


func get_active_pulse_count() -> int:
	return _pulses.size()
