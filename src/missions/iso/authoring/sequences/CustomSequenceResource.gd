@tool
class_name CustomSequenceResource
extends Resource

@export var sequence_id: StringName = &"custom_sequence"
@export var display_name: String = ""
@export var mission_id_override: String = ""
@export var steps: Array[Resource] = []
@export var debug_note: String = ""


func ordered_steps() -> Array[Resource]:
	var result := steps.duplicate()
	result.sort_custom(func(a: Resource, b: Resource) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		return int(a.get("order_index")) < int(b.get("order_index"))
	)
	return result


func find_step(step_id: String) -> Resource:
	var wanted := step_id.strip_edges()
	if wanted == "":
		return null
	for step in steps:
		if step is Resource and String((step as Resource).get("step_id")) == wanted:
			return step as Resource
	return null
