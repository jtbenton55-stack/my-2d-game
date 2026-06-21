@tool
class_name PressurePlateNode
extends MechanicAreaBase

signal pressure_plate_pressed(plate_id: String, result: Dictionary)
signal pressure_plate_released(plate_id: String, result: Dictionary)

@export_group("Pressure Plate")
@export var plate_id: StringName = &"pressure_plate"
@export var pressed_flag: StringName = &""
@export var clear_flag_on_exit: bool = true
@export var apply_success_on_press: bool = true
@export var accepted_actor_groups: Array[StringName] = [&"player", &"bentley"]

var pressed: bool = false
var pressing_actor: Node = null
var last_plate_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	if not body_entered.is_connected(_on_plate_body_entered):
		body_entered.connect(_on_plate_body_entered)
	if not body_exited.is_connected(_on_plate_body_exited):
		body_exited.connect(_on_plate_body_exited)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["plate_id"] = String(plate_id)
	context["pressed_flag"] = String(pressed_flag)
	context["pressed"] = pressed
	return context


func press(actor: Node = null, reason: String = "pressure_entered") -> Dictionary:
	if not enabled:
		last_plate_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		return last_plate_result
	if one_shot and used:
		last_plate_result = _result(true, "already_used", "Mechanic already used.", String(mechanic_id), {"reason": reason})
		return last_plate_result
	if actor != null and not _can_actor_press(actor):
		last_plate_result = _result(false, "actor_not_allowed", "Actor cannot use this pressure plate.", String(mechanic_id), {"reason": reason, "actor": actor})
		return last_plate_result
	pressing_actor = actor
	pressed = true
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_plate_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
	else:
		var flag_result := _set_pressed_flag(true, context)
		last_effect_result = apply_success_effects(context) if apply_success_on_press else _result(true, "success_effects_skipped", "Success effects skipped.")
		if one_shot:
			mark_used()
		last_plate_result = _result(true, "pressure_plate_pressed", "Pressure plate pressed.", String(mechanic_id), {"reason": reason, "flag_result": flag_result, "effect_result": last_effect_result})
		pressure_plate_pressed.emit(String(plate_id), last_plate_result)
	refresh_debug_label()
	_notify_availability()
	return last_plate_result


func release(actor: Node = null, reason: String = "pressure_exited") -> Dictionary:
	if actor != null and pressing_actor != null and actor != pressing_actor:
		return _result(true, "ignored_other_actor", "Ignoring release from a different actor.")
	pressed = false
	pressing_actor = null
	var context := build_context(actor)
	var flag_result := _result(true, "pressed_flag_retained", "Pressed flag retained.")
	if clear_flag_on_exit:
		flag_result = _set_pressed_flag(false, context)
	last_plate_result = _result(true, "pressure_plate_released", "Pressure plate released.", String(mechanic_id), {"reason": reason, "flag_result": flag_result})
	pressure_plate_released.emit(String(plate_id), last_plate_result)
	refresh_debug_label()
	_notify_availability()
	return last_plate_result


func handle_body_entered(body: Node) -> void:
	_on_plate_body_entered(body)


func handle_body_exited(body: Node) -> void:
	_on_plate_body_exited(body)


func get_plate_summary() -> Dictionary:
	return {
		"plate_id": String(plate_id),
		"pressed_flag": String(pressed_flag),
		"pressed": pressed,
		"last_plate_result": last_plate_result.duplicate(true),
	}


func _set_pressed_flag(value: bool, context: Dictionary) -> Dictionary:
	if pressed_flag == &"":
		return _result(true, "no_pressed_flag", "No pressed_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(pressed_flag), value, context)


func _can_actor_press(actor: Node) -> bool:
	if actor == null:
		return true
	for group_name: StringName in accepted_actor_groups:
		var text := String(group_name).strip_edges()
		if text != "" and actor.is_in_group(text):
			return true
	return can_actor_use(actor)


func _on_plate_body_entered(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	press(body, "body_entered")


func _on_plate_body_exited(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	release(body, "body_exited")


func _debug_label_text() -> String:
	return "PRESSED" if pressed else "PLATE"
