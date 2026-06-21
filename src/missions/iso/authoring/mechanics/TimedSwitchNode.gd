@tool
class_name TimedSwitchNode
extends MechanicAreaBase

signal timed_switch_started(switch_id: String, result: Dictionary)
signal timed_switch_expired(switch_id: String, result: Dictionary)

@export_group("Timed Switch")
@export var switch_id: StringName = &"timed_switch"
@export var switch_flag: StringName = &""
@export var active_seconds: float = 5.0
@export var clear_flag_on_expire: bool = true

var switch_active: bool = false
var switch_until_msec: int = 0
var last_switch_result: Dictionary = {}


func _ready() -> void:
	super._ready()
	set_process(true)


func _process(_delta: float) -> void:
	refresh_timer_state()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["switch_id"] = String(switch_id)
	context["switch_flag"] = String(switch_flag)
	context["switch_active"] = switch_active
	context["switch_until_msec"] = switch_until_msec
	return context


func trigger_switch(actor: Node = null, reason: String = "trigger_switch") -> Dictionary:
	var activation_result := activate(actor, reason)
	if not bool(activation_result.get("ok", false)) or String(activation_result.get("code", "")) != "activation_succeeded":
		last_switch_result = activation_result
		return last_switch_result
	var context := build_context(actor)
	switch_active = true
	switch_until_msec = Time.get_ticks_msec() + int(maxf(active_seconds, 0.0) * 1000.0)
	var flag_result := _set_switch_flag(true, context)
	last_switch_result = _result(true, "timed_switch_started", "Timed switch started.", String(mechanic_id), {"reason": reason, "flag_result": flag_result, "active_until_msec": switch_until_msec})
	timed_switch_started.emit(String(switch_id), last_switch_result)
	refresh_debug_label()
	return last_switch_result


func refresh_timer_state() -> Dictionary:
	if not switch_active:
		return _result(true, "timed_switch_inactive", "Timed switch is inactive.")
	if Time.get_ticks_msec() < switch_until_msec:
		return _result(true, "timed_switch_active", "Timed switch is active.", String(mechanic_id), {"active_until_msec": switch_until_msec})
	switch_active = false
	var context := build_context(current_actor)
	var flag_result := _result(true, "switch_flag_retained", "Switch flag retained.")
	if clear_flag_on_expire:
		flag_result = _set_switch_flag(false, context)
	last_switch_result = _result(true, "timed_switch_expired", "Timed switch expired.", String(mechanic_id), {"flag_result": flag_result})
	timed_switch_expired.emit(String(switch_id), last_switch_result)
	refresh_debug_label()
	return last_switch_result


func interact(actor: Node = null) -> bool:
	return bool(trigger_switch(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(trigger_switch(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(trigger_switch(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(trigger_switch(actor, "interact").get("ok", false))


func get_switch_summary() -> Dictionary:
	return {
		"switch_id": String(switch_id),
		"switch_flag": String(switch_flag),
		"switch_active": switch_active,
		"switch_until_msec": switch_until_msec,
		"active_seconds": active_seconds,
		"last_switch_result": last_switch_result.duplicate(true),
	}


func _set_switch_flag(value: bool, context: Dictionary) -> Dictionary:
	if switch_flag == &"":
		return _result(true, "no_switch_flag", "No switch_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(switch_flag), value, context)


func _debug_label_text() -> String:
	return "SWITCH ON" if switch_active else "SWITCH"
