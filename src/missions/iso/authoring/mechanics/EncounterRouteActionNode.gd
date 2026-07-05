@tool
class_name EncounterRouteActionNode
extends MechanicAreaBase

const ALLOWED_ROUTE_METHODS: Dictionary = {
	"run_clean_social_route": "clean_social_route",
	"run_bentley_distraction_route": "bentley_distraction_route",
	"run_evidence_route": "evidence_route",
	"run_messy_authority_route": "messy_authority_route",
	"run_cleanup_redirect_trace": "cleanup_redirect_trace",
}

@export_group("Encounter Route")
@export var controller_path: NodePath
@export_enum("run_clean_social_route", "run_bentley_distraction_route", "run_evidence_route", "run_messy_authority_route", "run_cleanup_redirect_trace") var route_method: String = "run_clean_social_route"
@export var route_id: StringName = &"clean_social_route"
@export var route_label: String = "Clean Social"
@export var route_choice_flag: StringName = &"phase18_garage_route_selected"
@export var route_specific_flag: StringName = &""
@export var locks_other_routes: bool = true
@export var allow_repeat_selected_route: bool = false

@export_group("Progress Gate")
@export var required_completed_objective_id: StringName = &""
@export var required_mission_flag: StringName = &""
@export var required_controller_bool_path: NodePath
@export var required_controller_bool_property: StringName = &""
@export var required_controller_bool_expected: bool = true
@export var progress_locked_message: String = "Resolve the garage/code path before choosing a deniability route."


func _init() -> void:
	prompt_text = "Press E: Choose garage route"
	locked_prompt_text = "Garage route unavailable"
	preview_color = Color(0.75, 0.45, 1.0, 0.35)
	one_shot = false
	interaction_priority = 820


func _ready() -> void:
	super._ready()
	add_to_group("phase18_garage_route_action")
	if String(route_id).strip_edges() == "":
		route_id = StringName(String(ALLOWED_ROUTE_METHODS.get(route_method, route_method)))


func is_interaction_available(actor: Node = null) -> bool:
	if not _progress_gate_passes():
		return false
	if _route_is_locked_by_other_choice():
		return false
	return super.is_interaction_available(actor)


func get_interaction_text() -> String:
	if not enabled:
		return ""
	if not _progress_gate_passes():
		return progress_locked_message
	if _route_is_locked_by_other_choice():
		return _selected_route_message()
	return super.get_interaction_text()


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	current_actor = actor
	activation_started.emit(String(mechanic_id), actor)

	var precheck := _precheck(actor, reason)
	if not bool(precheck.get("ok", false)):
		last_activation_result = precheck
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	if String(precheck.get("code", "")) == "editor_preview":
		last_activation_result = precheck
		refresh_debug_label()
		return last_activation_result

	var context := build_context(actor)
	last_requirement_result = evaluate_requirements(actor)
	if not bool(last_requirement_result.get("ok", false)):
		last_effect_result = apply_failure_effects(context)
		effects_applied.emit(String(mechanic_id), last_effect_result)
		last_activation_result = _result(false, "requirements_failed", String(last_requirement_result.get("message", "Requirements failed.")), String(mechanic_id), {"reason": reason, "requirement_result": last_requirement_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	var route_result := _call_route(context, reason)
	if not _route_call_started(route_result):
		last_activation_result = route_result
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result

	last_effect_result = apply_success_effects(context)
	effects_applied.emit(String(mechanic_id), last_effect_result)
	_record_route_choice(context, route_result)
	if one_shot:
		mark_used()
	last_activation_result = _result(
		bool(route_result.get("ok", false)),
		"encounter_route_selected" if bool(route_result.get("ok", false)) else "encounter_route_escalated",
		"Selected route: %s." % _display_route_label(),
		String(mechanic_id),
		{
			"reason": reason,
			"route_id": String(route_id),
			"route_label": _display_route_label(),
			"route_method": route_method,
			"route_result": route_result,
			"requirement_result": last_requirement_result,
			"effect_result": last_effect_result,
		}
	)
	activation_succeeded.emit(String(mechanic_id), last_activation_result)
	refresh_debug_label()
	return last_activation_result


func run_route(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["encounter_route_id"] = String(route_id)
	context["encounter_route_label"] = _display_route_label()
	context["route_method"] = route_method
	var controller := _controller()
	if controller != null:
		context["encounter_controller"] = controller
	return context


func _precheck(actor: Node, reason: String) -> Dictionary:
	if not enabled:
		return _result(false, "mechanic_disabled", "Mechanic is disabled.", String(mechanic_id), {"reason": reason})
	if one_shot and used:
		return _result(false, "already_used", "Mechanic already used.", String(mechanic_id), {"reason": reason})
	if actor != null and not can_actor_use(actor):
		return _result(false, "actor_not_allowed", "Actor cannot use this mechanic.", String(mechanic_id), {"reason": reason, "actor": actor})
	if Engine.is_editor_hint():
		return _result(true, "editor_preview", "Activation skipped in editor.", String(mechanic_id), {"reason": reason})
	if not _progress_gate_passes():
		return _result(false, "route_progress_locked", progress_locked_message, String(mechanic_id), {"required_completed_objective_id": String(required_completed_objective_id), "required_mission_flag": String(required_mission_flag), "required_controller_bool_property": String(required_controller_bool_property)})
	if _route_is_locked_by_other_choice():
		return _result(false, "route_already_selected", _selected_route_message(), String(mechanic_id), {"selected_route": _selected_route()})
	if not ALLOWED_ROUTE_METHODS.has(route_method):
		return _result(false, "route_method_not_allowed", "Route method is not allowlisted: %s." % route_method, String(mechanic_id), {"route_method": route_method})
	if _controller() == null:
		return _result(false, "encounter_controller_missing", "Garage route controller is missing.", String(mechanic_id), {"controller_path": str(controller_path)})
	return _result(true, "precheck_passed", "Route precheck passed.", String(mechanic_id), {"reason": reason})


func _call_route(context: Dictionary, reason: String) -> Dictionary:
	var controller := _controller()
	if controller == null:
		return _result(false, "encounter_controller_missing", "Garage route controller is missing.", String(mechanic_id))
	if not ALLOWED_ROUTE_METHODS.has(route_method) or not controller.has_method(route_method):
		return _result(false, "route_method_missing", "Garage route method is unavailable: %s." % route_method, String(mechanic_id), {"route_method": route_method})
	var payload := context.duplicate(true)
	payload["triggered_by"] = "phase18_player_route_action"
	payload["activation_reason"] = reason
	var result: Variant = controller.call(route_method, payload)
	if result is Dictionary:
		return result as Dictionary
	return _result(false, "route_result_invalid", "Garage route returned an invalid result.", String(mechanic_id), {"route_method": route_method})


func _record_route_choice(context: Dictionary, route_result: Dictionary) -> void:
	if not locks_other_routes:
		return
	MissionFactBridge.set_fact_value(&"mission_flag", String(route_choice_flag), String(route_id), context)
	var specific := String(route_specific_flag).strip_edges()
	if specific != "":
		MissionFactBridge.set_fact_value(&"mission_flag", specific, true, context)
	var result_details: Dictionary = route_result.get("details", {}) if route_result.get("details", {}) is Dictionary else {}
	var route_record: Dictionary = result_details.get("route", {}) if result_details.get("route", {}) is Dictionary else {}
	if route_record.has("route_style_label"):
		MissionFactBridge.set_fact_value(&"mission_flag", "phase18_garage_route_style", String(route_record.get("route_style_label", "")), context)


func _progress_gate_passes() -> bool:
	var context := build_context(null)
	var objective_id := String(required_completed_objective_id).strip_edges()
	if objective_id != "" and not bool(MissionFactBridge.get_fact_value(&"objective_completed", objective_id, context)):
		return false
	var flag_id := String(required_mission_flag).strip_edges()
	if flag_id != "" and not bool(MissionFactBridge.get_fact_value(&"mission_flag", flag_id, context)):
		return false
	var controller_property := String(required_controller_bool_property).strip_edges()
	if controller_property != "" and _required_controller_bool_value(controller_property) != required_controller_bool_expected:
		return false
	return true


func _required_controller_bool_value(property_name: String) -> bool:
	var controller := get_node_or_null(required_controller_bool_path) if required_controller_bool_path != NodePath() else null
	if controller == null:
		return false
	var value: Variant = controller.get(property_name)
	return bool(value) if value != null else false


func _route_is_locked_by_other_choice() -> bool:
	if not locks_other_routes:
		return false
	var selected := _selected_route()
	if selected == "":
		return false
	if allow_repeat_selected_route and selected == String(route_id):
		return false
	return true


func _selected_route() -> String:
	var selected: Variant = MissionFactBridge.get_fact_value(&"mission_flag", String(route_choice_flag), build_context(null))
	if selected == null:
		return ""
	if selected is bool and not bool(selected):
		return ""
	return str(selected).strip_edges()


func _selected_route_message() -> String:
	var selected := _selected_route()
	return "Garage route already selected: %s." % (selected if selected != "" else "another route")


func _route_call_started(result: Dictionary) -> bool:
	var code := String(result.get("code", ""))
	if code == "phase16_route_resolved" or code == "phase16_route_escalated":
		return true
	var details: Variant = result.get("details", {})
	return details is Dictionary and (details as Dictionary).get("route", {}) is Dictionary


func _display_route_label() -> String:
	var label := route_label.strip_edges()
	if label != "":
		return label
	return String(route_id).capitalize()


func _controller() -> Node:
	if controller_path != NodePath():
		var explicit := get_node_or_null(controller_path)
		if explicit != null:
			return explicit
	var tree := get_tree() if is_inside_tree() else null
	if tree != null:
		var grouped := tree.get_first_node_in_group("mission_encounter_controller")
		if grouped != null:
			return grouped
	return null
