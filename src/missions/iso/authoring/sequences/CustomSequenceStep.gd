@tool
class_name CustomSequenceStep
extends Resource

@export var step_id: StringName = &"step"
@export var display_name: String = ""
@export var order_index: int = 0
@export var depends_on_step_ids: Array[StringName] = []
@export var completion_flag: StringName = &""
@export var requirements: RequirementSet
@export var success_effects: EffectSet
@export var auto_complete_when_requirements_pass: bool = false
@export var debug_note: String = ""


func get_step_id() -> String:
	return String(step_id).strip_edges()


func get_dependency_ids() -> Array[String]:
	var result: Array[String] = []
	for id: StringName in depends_on_step_ids:
		var text := String(id).strip_edges()
		if text != "":
			result.append(text)
	return result
