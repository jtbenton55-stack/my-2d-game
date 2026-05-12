class_name PlayerStaminaController
extends RefCounted
## Sprint stamina (no animation dependency). Canonical action: `sprint` (Ctrl + documented **C** fallback in Input Map). `is_sprint_requested` also polls `KEY_CTRL` via physical + layout key and action strength.

signal stamina_changed(current: float, max_stamina: float)
signal sprint_started
signal sprint_stopped
signal exhausted_changed(is_exhausted: bool)

var max_stamina: float = 100.0
## Full bar to 0 while sprinting: time ~= max_stamina / this value (default ~2s at max 100).
var drain_rate_per_sec: float = 50.0
## 0 to full while not sprinting: time ~= max_stamina / this value (default ~15s at max 100).
var regen_rate_per_sec: float = 100.0 / 15.0
var sprint_speed_multiplier: float = 1.35
var exhausted_threshold: float = 0.5
var sprint_action_name: String = "sprint"
## Optional extra actions treated as sprint-hold (e.g. legacy compat). Prefer binding keys on `sprint` in Input Map.
var alternate_sprint_action_names: Array[String] = []

var current_stamina: float = 100.0
var _sprinting: bool = false
var _exhausted: bool = false


func reset_stamina() -> void:
	current_stamina = max_stamina
	_sprinting = false
	_exhausted = false
	stamina_changed.emit(current_stamina, max_stamina)
	exhausted_changed.emit(_exhausted)


func can_sprint() -> bool:
	return current_stamina > exhausted_threshold


func is_sprint_requested() -> bool:
	if InputMap.has_action(sprint_action_name):
		if Input.is_action_pressed(sprint_action_name):
			return true
		## Strength catches edge cases where `pressed` lags for modifier-only bindings.
		if Input.get_action_strength(sprint_action_name) > 0.01:
			return true
	## InputMap-only Ctrl can fail; poll layout + physical Ctrl.
	if Input.is_physical_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_CTRL):
		return true
	for alt in alternate_sprint_action_names:
		if alt != "" and InputMap.has_action(alt) and Input.is_action_pressed(alt):
			return true
		if alt != "" and InputMap.has_action(alt) and Input.get_action_strength(alt) > 0.01:
			return true
	return false


func is_sprint_active() -> bool:
	return _sprinting


func get_debug_snapshot() -> Dictionary:
	var snap := get_stamina_snapshot()
	var sprint_str := Input.get_action_strength(sprint_action_name) if InputMap.has_action(sprint_action_name) else 0.0
	snap["sprint_action_strength"] = sprint_str
	snap["sprint_action_pressed"] = (
		InputMap.has_action(sprint_action_name)
		and (Input.is_action_pressed(sprint_action_name) or sprint_str > 0.01)
	)
	snap["ctrl_physical_pressed"] = Input.is_physical_key_pressed(KEY_CTRL)
	snap["ctrl_key_pressed"] = Input.is_key_pressed(KEY_CTRL)
	snap["space_physical_pressed"] = Input.is_physical_key_pressed(KEY_SPACE)
	snap["space_key_pressed"] = Input.is_key_pressed(KEY_SPACE)
	snap["dodge_action_pressed"] = InputMap.has_action("dodge") and Input.is_action_pressed("dodge")
	snap["run_animation_required"] = false
	return snap


func get_sprint_signal_chain_debug() -> Dictionary:
	var d := get_debug_snapshot()
	d["is_sprint_requested"] = is_sprint_requested()
	d["is_sprint_active"] = is_sprint_active()
	d["can_sprint"] = can_sprint()
	d["speed_multiplier"] = get_speed_multiplier()
	d["stamina_draining"] = is_sprint_active()
	return d


func request_sprint(active: bool) -> void:
	if active == _sprinting:
		return
	_sprinting = active
	if _sprinting:
		sprint_started.emit()
	else:
		sprint_stopped.emit()


func get_speed_multiplier() -> float:
	if _sprinting and can_sprint():
		return sprint_speed_multiplier
	return 1.0


func process_frame(delta: float, wants_sprint: bool, is_moving: bool) -> void:
	var had_sprint := _sprinting
	_sprinting = wants_sprint and can_sprint() and is_moving
	if _sprinting:
		current_stamina = maxf(0.0, current_stamina - drain_rate_per_sec * delta)
	else:
		current_stamina = minf(max_stamina, current_stamina + regen_rate_per_sec * delta)
	var ex := current_stamina <= exhausted_threshold
	if ex != _exhausted:
		_exhausted = ex
		exhausted_changed.emit(_exhausted)
	if had_sprint != _sprinting:
		if _sprinting:
			sprint_started.emit()
		else:
			sprint_stopped.emit()
	stamina_changed.emit(current_stamina, max_stamina)


func get_stamina_snapshot() -> Dictionary:
	return {
		"max_stamina": max_stamina,
		"current_stamina": current_stamina,
		"drain_rate_per_sec": drain_rate_per_sec,
		"regen_rate_per_sec": regen_rate_per_sec,
		"sprint_multiplier": sprint_speed_multiplier,
		"exhausted_threshold": exhausted_threshold,
		"sprint_action_name": sprint_action_name,
		"alternate_sprint_action_names": alternate_sprint_action_names.duplicate(),
		"is_sprinting": _sprinting,
		"is_exhausted": _exhausted,
	}
