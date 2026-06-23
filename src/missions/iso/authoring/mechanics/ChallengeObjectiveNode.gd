@tool
class_name ChallengeObjectiveNode
extends MechanicAreaBase

@export_group("Encounter")
@export var encounter_controller_path: NodePath
@export var required_phase_id: StringName = &""
@export var event_id: StringName = &"challenge_objective"
@export var route_tag: StringName = &""
@export var result_tag: StringName = &""
@export var meter_deltas: Dictionary = {}
@export var advances_phase: bool = true
@export var wins_encounter: bool = false
@export var fails_encounter: bool = false


func _init() -> void:
	prompt_text = "Press E: Complete challenge step"
	locked_prompt_text = "Challenge step unavailable"
	preview_color = Color(0.9, 0.55, 0.2, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	var controller := _find_encounter_controller()
	if controller != null:
		context["encounter_controller"] = controller
		if controller.has_method("get_summary"):
			context["encounter"] = controller.call("get_summary")
	context["encounter_phase_id"] = String(required_phase_id)
	context["encounter_event_id"] = String(event_id)
	context["route_tag"] = String(route_tag)
	return context


func is_interaction_available(actor: Node = null) -> bool:
	if not _phase_allows_use():
		return false
	return super.is_interaction_available(actor)


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not _phase_allows_use():
		last_activation_result = _result(false, "encounter_phase_locked", "Challenge objective is not available in this encounter phase.", String(mechanic_id), {"required_phase_id": String(required_phase_id)})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)):
		_apply_encounter_success(build_context(actor), reason)
	return result


func complete_objective(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _apply_encounter_success(context: Dictionary, reason: String) -> void:
	var controller: Variant = context.get("encounter_controller", null)
	if controller == null:
		return
	var details := {"source_id": String(mechanic_id), "reason": reason, "route_tag": String(route_tag)}
	if controller.has_method("record_event"):
		controller.call("record_event", String(event_id), details)
	for meter_id in meter_deltas.keys():
		if controller.has_method("adjust_meter"):
			controller.call("adjust_meter", String(meter_id), int(meter_deltas[meter_id]), details)
	if String(result_tag).strip_edges() != "" and controller.has_method("set_result_tag"):
		controller.call("set_result_tag", String(result_tag), true)
	if fails_encounter and controller.has_method("fail_encounter"):
		controller.call("fail_encounter", "Challenge objective failed: %s." % String(mechanic_id))
	elif wins_encounter and controller.has_method("win_encounter"):
		controller.call("win_encounter", String(result_tag) if String(result_tag).strip_edges() != "" else String(route_tag))
	elif advances_phase and controller.has_method("complete_current_phase"):
		controller.call("complete_current_phase", String(route_tag), details)


func _phase_allows_use() -> bool:
	var required := String(required_phase_id).strip_edges()
	if required == "":
		return true
	var controller := _find_encounter_controller()
	if controller == null:
		return false
	return String(controller.get("current_phase_id")) == required


func _find_encounter_controller() -> Node:
	if encounter_controller_path != NodePath():
		var explicit := get_node_or_null(encounter_controller_path)
		if explicit != null:
			return explicit
	var tree := get_tree()
	if tree != null:
		var grouped := tree.get_first_node_in_group("mission_encounter_controller")
		if grouped != null:
			return grouped
	return null
