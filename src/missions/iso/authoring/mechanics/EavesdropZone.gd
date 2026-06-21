@tool
class_name EavesdropZone
extends MechanicAreaBase

signal eavesdrop_started(eavesdrop_id: String, result: Dictionary)
signal eavesdrop_completed(eavesdrop_id: String, result: Dictionary)
signal eavesdrop_cancelled(eavesdrop_id: String, result: Dictionary)

@export_group("Eavesdrop")
@export var eavesdrop_id: StringName = &"eavesdrop"
@export var completed_flag: StringName = &""
@export var listen_seconds: float = 3.0
@export var complete_on_enter_when_zero: bool = true
@export var cancel_on_exit: bool = true

var listening: bool = false
var completed: bool = false
var listen_until_msec: int = 0
var last_eavesdrop_result: Dictionary = {}


func _ready() -> void:
	interaction_mode = InteractionMode.SCRIPT_ONLY
	super._ready()
	set_process(true)
	if not body_entered.is_connected(_on_eavesdrop_body_entered):
		body_entered.connect(_on_eavesdrop_body_entered)
	if not body_exited.is_connected(_on_eavesdrop_body_exited):
		body_exited.connect(_on_eavesdrop_body_exited)


func _process(_delta: float) -> void:
	refresh_eavesdrop_state()


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["eavesdrop_id"] = String(eavesdrop_id)
	context["completed_flag"] = String(completed_flag)
	context["listen_seconds"] = listen_seconds
	context["listening"] = listening
	context["completed"] = completed
	context["listen_until_msec"] = listen_until_msec
	return context


func start_eavesdrop(actor: Node = null, reason: String = "enter") -> Dictionary:
	if not enabled:
		last_eavesdrop_result = _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
		return last_eavesdrop_result
	if one_shot and completed:
		last_eavesdrop_result = _result(true, "already_completed", "Eavesdrop already completed.", String(mechanic_id), {"reason": reason})
		return last_eavesdrop_result
	if actor != null and not can_actor_use(actor):
		last_eavesdrop_result = _result(false, "actor_not_allowed", "Actor cannot use this eavesdrop zone.", String(mechanic_id), {"reason": reason, "actor": actor})
		return last_eavesdrop_result
	current_actor = actor
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(build_context(actor))
		last_eavesdrop_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_eavesdrop_result)
		refresh_debug_label()
		return last_eavesdrop_result
	if listen_seconds <= 0.0 and complete_on_enter_when_zero:
		return complete_eavesdrop(actor, "instant_complete")
	listening = true
	listen_until_msec = Time.get_ticks_msec() + int(maxf(listen_seconds, 0.0) * 1000.0)
	last_eavesdrop_result = _result(true, "eavesdrop_started", "Eavesdrop started.", String(mechanic_id), {"reason": reason, "listen_until_msec": listen_until_msec})
	eavesdrop_started.emit(String(eavesdrop_id), last_eavesdrop_result)
	refresh_debug_label()
	return last_eavesdrop_result


func refresh_eavesdrop_state() -> Dictionary:
	if not listening:
		return _result(true, "eavesdrop_inactive", "Eavesdrop is inactive.")
	if Time.get_ticks_msec() < listen_until_msec:
		return _result(true, "eavesdrop_listening", "Eavesdrop in progress.", String(mechanic_id), {"listen_until_msec": listen_until_msec})
	return complete_eavesdrop(current_actor, "duration_complete")


func complete_eavesdrop(actor: Node = null, reason: String = "complete") -> Dictionary:
	listening = false
	completed = true
	var context := build_context(actor)
	var flag_result := _set_completed_flag(context)
	last_effect_result = apply_success_effects(context)
	if one_shot:
		mark_used()
	last_eavesdrop_result = _result(true, "eavesdrop_completed", "Eavesdrop completed.", String(mechanic_id), {"reason": reason, "completed_flag_result": flag_result, "effect_result": last_effect_result})
	activation_succeeded.emit(String(mechanic_id), last_eavesdrop_result)
	eavesdrop_completed.emit(String(eavesdrop_id), last_eavesdrop_result)
	refresh_debug_label()
	_notify_availability()
	return last_eavesdrop_result


func cancel_eavesdrop(actor: Node = null, reason: String = "exit") -> Dictionary:
	if not listening:
		return _result(true, "eavesdrop_not_listening", "Eavesdrop was not active.")
	listening = false
	last_effect_result = apply_failure_effects(build_context(actor))
	last_eavesdrop_result = _result(false, "eavesdrop_cancelled", "Eavesdrop cancelled.", String(mechanic_id), {"reason": reason, "effect_result": last_effect_result})
	activation_failed.emit(String(mechanic_id), last_eavesdrop_result)
	eavesdrop_cancelled.emit(String(eavesdrop_id), last_eavesdrop_result)
	refresh_debug_label()
	_notify_availability()
	return last_eavesdrop_result


func interact(actor: Node = null) -> bool:
	return bool(start_eavesdrop(actor, "interact").get("ok", false))


func on_interact(actor: Node = null) -> bool:
	return bool(start_eavesdrop(actor, "interact").get("ok", false))


func use(actor: Node = null) -> bool:
	return bool(start_eavesdrop(actor, "interact").get("ok", false))


func inspect_marker(actor: Node = null) -> bool:
	return bool(start_eavesdrop(actor, "interact").get("ok", false))


func get_eavesdrop_summary() -> Dictionary:
	return {
		"eavesdrop_id": String(eavesdrop_id),
		"completed_flag": String(completed_flag),
		"listen_seconds": listen_seconds,
		"listening": listening,
		"completed": completed,
		"listen_until_msec": listen_until_msec,
		"last_eavesdrop_result": last_eavesdrop_result.duplicate(true),
	}


func _set_completed_flag(context: Dictionary) -> Dictionary:
	if completed_flag == &"":
		return _result(true, "no_completed_flag", "No completed_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", String(completed_flag), true, context)


func _on_eavesdrop_body_entered(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	start_eavesdrop(body, "body_entered")


func _on_eavesdrop_body_exited(body: Node) -> void:
	if Engine.is_editor_hint() or not cancel_on_exit:
		return
	cancel_eavesdrop(body, "body_exited")


func _debug_label_text() -> String:
	if completed:
		return "EAVESDONE"
	return "LISTENING" if listening else "EAVESDROP"
