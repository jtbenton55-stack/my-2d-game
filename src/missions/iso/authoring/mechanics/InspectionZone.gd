@tool
class_name InspectionZone
extends MechanicAreaBase

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export_group("Inspection")
@export var inspection_id: StringName = &""
@export var rule_set: Resource
@export var accepted_flag: StringName = &""
@export var rejected_flag: StringName = &""
@export var reject_marks_used: bool = false

var last_inspection_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Present story"
	locked_prompt_text = "Cannot pass inspection"
	preview_color = Color(0.55, 0.45, 0.9, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["inspection_id"] = String(_resolved_inspection_id())
	context["inspection_result"] = last_inspection_result
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	current_actor = actor
	activation_started.emit(String(mechanic_id), actor)
	if not enabled:
		last_activation_result = _result(false, "mechanic_disabled", "Inspection zone is disabled.", String(mechanic_id), {"reason": reason})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	if one_shot and used:
		last_activation_result = _result(true, "already_used", "Inspection zone already used.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result
	if actor != null and not can_actor_use(actor):
		last_activation_result = _result(false, "actor_not_allowed", "Actor cannot use this inspection zone.", String(mechanic_id), {"reason": reason, "actor": actor})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	if Engine.is_editor_hint():
		last_activation_result = _result(true, "editor_preview", "Inspection skipped in editor.", String(mechanic_id), {"reason": reason})
		refresh_debug_label()
		return last_activation_result
	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		last_activation_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	last_inspection_result = _evaluate_inspection(context)
	var passed := bool(last_inspection_result.get("ok", false))
	SocialStealthAdapterScript.record_inspection(String(_resolved_inspection_id()), passed, last_inspection_result, context)
	_set_result_flag(passed, context)
	context["inspection_result"] = last_inspection_result
	last_effect_result = apply_success_effects(context) if passed else apply_failure_effects(context)
	var details := {"reason": reason, "requirement_result": last_requirement_result, "inspection_result": last_inspection_result, "effect_result": last_effect_result}
	if passed and one_shot:
		mark_used()
	if not passed and reject_marks_used and one_shot:
		mark_used()
	last_activation_result = _result(passed, "inspection_passed" if passed else "inspection_rejected", String(last_inspection_result.get("message", "Inspection complete.")), String(mechanic_id), details)
	if passed:
		activation_succeeded.emit(String(mechanic_id), last_activation_result)
	else:
		activation_failed.emit(String(mechanic_id), last_activation_result)
	refresh_debug_label()
	return last_activation_result


func inspect_actor(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _evaluate_inspection(context: Dictionary) -> Dictionary:
	if rule_set == null or not rule_set.has_method("evaluate"):
		return _result(false, "inspection_rule_set_missing", "Inspection rule set is missing.", String(_resolved_inspection_id()))
	return rule_set.call("evaluate", context)


func _set_result_flag(passed: bool, context: Dictionary) -> void:
	var flag := String(accepted_flag if passed else rejected_flag)
	if flag.strip_edges() == "":
		return
	MissionFactBridge.set_fact_value(&"mission_flag", flag, true, context)


func _resolved_inspection_id() -> StringName:
	if inspection_id != &"":
		return inspection_id
	return mechanic_id
