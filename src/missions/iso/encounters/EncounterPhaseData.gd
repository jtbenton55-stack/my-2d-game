@tool
class_name EncounterPhaseData
extends Resource

@export var phase_id: StringName = &"phase"
@export var display_name: String = "Encounter Phase"
@export_multiline var objective_text: String = ""
@export var requirements: RequirementSet
@export var enter_effects: EffectSet
@export var success_effects: EffectSet
@export var failure_effects: EffectSet
@export var next_phase_id: StringName = &""
@export var win_on_success: bool = false
@export var fail_on_failure: bool = false
@export var result_tag_on_success: StringName = &""
@export var route_tag_on_success: StringName = &""


func evaluate(context: Dictionary = {}) -> Dictionary:
	if requirements == null:
		return _result(true, "no_requirements", "No phase requirements assigned.", String(phase_id))
	return requirements.evaluate(context)


func apply_enter_effects(context: Dictionary = {}) -> Dictionary:
	if enter_effects == null or enter_effects.is_empty():
		return _result(true, "no_enter_effects", "No phase enter effects assigned.", String(phase_id))
	return enter_effects.apply_all(context)


func apply_success_effects(context: Dictionary = {}) -> Dictionary:
	if success_effects == null or success_effects.is_empty():
		return _result(true, "no_success_effects", "No phase success effects assigned.", String(phase_id))
	return success_effects.apply_all(context)


func apply_failure_effects(context: Dictionary = {}) -> Dictionary:
	if failure_effects == null or failure_effects.is_empty():
		return _result(true, "no_failure_effects", "No phase failure effects assigned.", String(phase_id))
	return failure_effects.apply_all(context)


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
