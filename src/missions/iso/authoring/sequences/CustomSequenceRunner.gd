@tool
class_name CustomSequenceRunner
extends Node

signal sequence_step_completed(sequence_id: String, step_id: String, result: Dictionary)
signal sequence_completed(sequence_id: String, result: Dictionary)

@export var sequence: Resource
@export var run_on_ready: bool = false

var completed_steps: Array[String] = []
var last_sequence_result: Dictionary = {}


func _ready() -> void:
	if run_on_ready and not Engine.is_editor_hint():
		run_ready_steps()


func build_context(step: Resource = null) -> Dictionary:
	var mission_id := ""
	if sequence != null:
		mission_id = String(sequence.get("mission_id_override")).strip_edges()
	return {
		"mission_id": mission_id,
		"sequence_id": _sequence_id(),
		"step_id": String(step.get("step_id")) if step != null else "",
		"source_id": _sequence_id(),
		"source_path": str(get_path()),
		"sequence_runner": self,
	}


func run_ready_steps() -> Dictionary:
	if sequence == null:
		last_sequence_result = _result(false, "missing_sequence", "Custom sequence resource is missing.")
		return last_sequence_result
	var results: Array[Dictionary] = []
	for step in sequence.call("ordered_steps"):
		if step == null or not bool(step.get("auto_complete_when_requirements_pass")):
			continue
		if _dependencies_met(step) and _requirements_met(step):
			results.append(complete_step(String(step.get("step_id")), "run_ready_steps"))
	last_sequence_result = _result(true, "ready_steps_processed", "Ready sequence steps processed.", _sequence_id(), {"results": results})
	return last_sequence_result


func complete_step(step_id: String, reason: String = "complete_step") -> Dictionary:
	if sequence == null:
		last_sequence_result = _result(false, "missing_sequence", "Custom sequence resource is missing.")
		return last_sequence_result
	var step: Resource = sequence.call("find_step", step_id)
	if step == null:
		last_sequence_result = _result(false, "step_missing", "Sequence step is missing: %s." % step_id, _sequence_id(), {"step_id": step_id, "reason": reason})
		return last_sequence_result
	var id := String(step.get("step_id"))
	if completed_steps.has(id):
		last_sequence_result = _result(true, "step_already_completed", "Sequence step already completed.", _sequence_id(), {"step_id": id, "reason": reason})
		return last_sequence_result
	if not _dependencies_met(step):
		last_sequence_result = _result(false, "step_dependencies_missing", "Sequence step dependencies are incomplete.", _sequence_id(), {"step_id": id, "missing_dependencies": _missing_dependencies(step), "reason": reason})
		return last_sequence_result
	if not _requirements_met(step):
		last_sequence_result = _result(false, "step_requirements_failed", "Sequence step requirements failed.", _sequence_id(), {"step_id": id, "reason": reason})
		return last_sequence_result
	var context := build_context(step)
	var flag_result := _set_step_flag(step, context)
	var effect_result := _apply_step_effects(step, context)
	completed_steps.append(id)
	last_sequence_result = _result(true, "sequence_step_completed", "Sequence step completed: %s." % id, _sequence_id(), {"step_id": id, "reason": reason, "flag_result": flag_result, "effect_result": effect_result})
	sequence_step_completed.emit(_sequence_id(), id, last_sequence_result)
	if _all_steps_complete():
		sequence_completed.emit(_sequence_id(), get_sequence_summary())
	return last_sequence_result


func reset_sequence() -> void:
	completed_steps.clear()
	last_sequence_result.clear()


func get_sequence_summary() -> Dictionary:
	return {
		"sequence_id": _sequence_id(),
		"completed_steps": completed_steps.duplicate(),
		"all_steps_complete": _all_steps_complete(),
		"last_sequence_result": last_sequence_result.duplicate(true),
	}


func _requirements_met(step: Resource) -> bool:
	var req: Variant = step.get("requirements")
	if req == null:
		return true
	if Engine.is_editor_hint():
		return true
	return bool((req as RequirementSet).evaluate(build_context(step)).get("ok", false))


func _dependencies_met(step: Resource) -> bool:
	return _missing_dependencies(step).is_empty()


func _missing_dependencies(step: Resource) -> Array[String]:
	var missing: Array[String] = []
	for dep: StringName in step.get("depends_on_step_ids"):
		var id := String(dep).strip_edges()
		if id != "" and not completed_steps.has(id):
			missing.append(id)
	return missing


func _set_step_flag(step: Resource, context: Dictionary) -> Dictionary:
	var flag := String(step.get("completion_flag")).strip_edges()
	if flag == "":
		return _result(true, "no_completion_flag", "No completion_flag configured.")
	return MissionFactBridge.set_fact_value(&"mission_flag", flag, true, context)


func _apply_step_effects(step: Resource, context: Dictionary) -> Dictionary:
	var effects: Variant = step.get("success_effects")
	if effects == null:
		return _result(true, "no_success_effects", "No success effects assigned.")
	return (effects as EffectSet).apply_all(context)


func _all_steps_complete() -> bool:
	if sequence == null:
		return false
	for step in sequence.get("steps"):
		if step is Resource and not completed_steps.has(String((step as Resource).get("step_id"))):
			return false
	return not (sequence.get("steps") as Array).is_empty()


func _sequence_id() -> String:
	if sequence == null:
		return ""
	return String(sequence.get("sequence_id"))


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
