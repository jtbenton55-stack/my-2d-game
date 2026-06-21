@tool
class_name PowerCircuitNode
extends MechanicAreaBase

signal circuit_powered(circuit_id: String, result: Dictionary)
signal circuit_unpowered(circuit_id: String, result: Dictionary)

@export_group("Power Circuit")
@export var circuit_id: StringName = &"power_circuit"
@export var circuit_flag: StringName = &""
@export var required_power_flags: Array[StringName] = []
@export var require_all_flags: bool = true
@export var clear_flag_when_incomplete: bool = false

var powered: bool = false
var last_circuit_result: Dictionary = {}


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["circuit_id"] = String(circuit_id)
	context["circuit_flag"] = String(circuit_flag)
	context["required_power_flags"] = _flag_strings()
	context["powered"] = powered
	return context


func check_circuit(actor: Node = null, reason: String = "check_circuit") -> Dictionary:
	if not enabled:
		last_circuit_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		activation_failed.emit(String(mechanic_id), last_circuit_result)
		refresh_debug_label()
		return last_circuit_result
	if one_shot and used:
		last_circuit_result = _result(true, "already_used", "Mechanic already used.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_circuit_result
	if actor != null and not can_actor_use(actor):
		last_circuit_result = _result(false, "actor_not_allowed", "Actor cannot use this circuit.", String(mechanic_id), {"reason": reason, "actor": actor})
		activation_failed.emit(String(mechanic_id), last_circuit_result)
		refresh_debug_label()
		return last_circuit_result
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_circuit_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_circuit_result)
		refresh_debug_label()
		return last_circuit_result

	var flag_details := _evaluate_required_flags(context)
	var complete := bool(flag_details.get("complete", false))
	if complete:
		powered = true
		_set_circuit_flag(true, context)
		last_effect_result = apply_success_effects(context)
		if one_shot:
			mark_used()
		last_circuit_result = _result(true, "circuit_powered", "Power circuit is powered.", String(mechanic_id), {"reason": reason, "flag_details": flag_details, "effect_result": last_effect_result})
		activation_succeeded.emit(String(mechanic_id), last_circuit_result)
		circuit_powered.emit(String(circuit_id), last_circuit_result)
	else:
		powered = false
		if clear_flag_when_incomplete:
			_set_circuit_flag(false, context)
		last_effect_result = apply_failure_effects(context)
		last_circuit_result = _result(false, "circuit_incomplete", "Power circuit requirements are incomplete.", String(mechanic_id), {"reason": reason, "flag_details": flag_details, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_circuit_result)
		circuit_unpowered.emit(String(circuit_id), last_circuit_result)
	refresh_debug_label()
	_notify_availability()
	return last_circuit_result


func interact(actor: Node = null) -> bool:
	return bool(check_circuit(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(check_circuit(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(check_circuit(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(check_circuit(actor, "interact").get("ok", false))


func get_circuit_summary() -> Dictionary:
	return {
		"circuit_id": String(circuit_id),
		"circuit_flag": String(circuit_flag),
		"required_power_flags": _flag_strings(),
		"require_all_flags": require_all_flags,
		"powered": powered,
		"last_circuit_result": last_circuit_result.duplicate(true),
	}


func _evaluate_required_flags(context: Dictionary) -> Dictionary:
	var states: Dictionary = {}
	var matched_count := 0
	for flag: StringName in required_power_flags:
		var flag_text := String(flag)
		var value := bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_text, context))
		states[flag_text] = value
		if value:
			matched_count += 1
	var complete := false
	if required_power_flags.is_empty():
		complete = true
	elif require_all_flags:
		complete = matched_count == required_power_flags.size()
	else:
		complete = matched_count > 0
	return {"complete": complete, "states": states, "matched_count": matched_count, "required_count": required_power_flags.size()}


func _set_circuit_flag(value: bool, context: Dictionary) -> Dictionary:
	if circuit_flag == &"":
		return _result(true, "no_circuit_flag", "No circuit_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(circuit_flag), value, context)


func _flag_strings() -> Array[String]:
	var result: Array[String] = []
	for flag: StringName in required_power_flags:
		result.append(String(flag))
	return result


func _debug_label_text() -> String:
	return "POWERED" if powered else "CIRCUIT"
