@tool
class_name DisruptionActionNode
extends MechanicAreaBase

const PaperTrailAdapterScript := preload("res://src/missions/iso/runtime/paper_trail/PaperTrailAdapter.gd")
const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")
const NoiseEventHelper := preload("res://src/missions/iso/runtime/noise/NoiseEvent.gd")

@export_group("Encounter")
@export var encounter_controller_path: NodePath
@export var required_phase_id: StringName = &""
@export_enum("route_control", "security_integrity", "evidence_pressure", "bentley_support", "social_slip", "paper_trace", "noise", "blackout") var action_type: String = "route_control"
@export var event_id: StringName = &"disruption_action"
@export var route_tag: StringName = &""
@export var meter_deltas: Dictionary = {}

@export_group("Consequences")
@export var paper_trace_id: StringName = &""
@export var paper_trace_type: StringName = &"disruption"
@export var paper_trace_severity: int = 1
@export var social_professionalism_delta: int = 0
@export var social_cleanliness_delta: int = 0
@export var alert_exposure_delta: float = 0.0
@export var noise_radius: float = 0.0
@export var noise_strength: float = 1.0


func _init() -> void:
	prompt_text = "Press E: Disrupt"
	locked_prompt_text = "Disruption unavailable"
	preview_color = Color(0.95, 0.25, 0.2, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	var controller := _find_encounter_controller()
	if controller != null:
		context["encounter_controller"] = controller
		if controller.has_method("get_summary"):
			context["encounter"] = controller.call("get_summary")
	context["disruption_action_type"] = action_type
	context["encounter_event_id"] = String(event_id)
	context["route_tag"] = String(route_tag)
	return context


func is_interaction_available(actor: Node = null) -> bool:
	if not _phase_allows_use():
		return false
	return super.is_interaction_available(actor)


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	if not _phase_allows_use():
		last_activation_result = _result(false, "encounter_phase_locked", "Disruption is not available in this encounter phase.", String(mechanic_id), {"required_phase_id": String(required_phase_id)})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)):
		_apply_disruption_success(build_context(actor), reason)
	return result


func run_disruption(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _apply_disruption_success(context: Dictionary, reason: String) -> void:
	var details := {"source_id": String(mechanic_id), "reason": reason, "action_type": action_type, "route_tag": String(route_tag)}
	var controller: Variant = context.get("encounter_controller", null)
	if controller != null:
		if controller.has_method("record_event"):
			controller.call("record_event", String(event_id), details)
		for meter_id in meter_deltas.keys():
			if controller.has_method("adjust_meter"):
				controller.call("adjust_meter", String(meter_id), int(meter_deltas[meter_id]), details)
		if String(route_tag).strip_edges() != "" and controller.has_method("set_result_tag"):
			controller.call("set_result_tag", String(route_tag), true)
	_apply_paper_trace(context)
	_apply_social_deltas(context)
	_apply_noise(context, reason)
	_apply_alert_exposure()


func _apply_paper_trace(context: Dictionary) -> void:
	var trace_id := String(paper_trace_id).strip_edges()
	if trace_id == "" and action_type != "paper_trace":
		return
	if trace_id == "":
		trace_id = "%s_trace" % String(mechanic_id)
	PaperTrailAdapterScript.record_trace(trace_id, String(mechanic_id), String(paper_trace_type), maxi(0, paper_trace_severity), true, "", context, {"action_type": action_type})


func _apply_social_deltas(context: Dictionary) -> void:
	if social_professionalism_delta != 0:
		SocialStealthAdapterScript.adjust_professionalism(social_professionalism_delta, context)
	if social_cleanliness_delta != 0:
		SocialStealthAdapterScript.adjust_cleanliness(social_cleanliness_delta, context)


func _apply_alert_exposure() -> void:
	if is_zero_approx(alert_exposure_delta):
		return
	var controller := _find_alert_controller()
	if controller != null and controller.has_method("accumulate_exposure"):
		controller.call("accumulate_exposure", String(mechanic_id), alert_exposure_delta, action_type)


func _apply_noise(context: Dictionary, reason: String) -> void:
	if noise_radius <= 0.0 or action_type not in ["noise", "blackout"]:
		return
	var event := NoiseEventHelper.make_event(
		String(event_id), String(mechanic_id), global_position, noise_radius,
		noise_strength, action_type, "player", {"reason": reason}
	)
	EventBus.mission_noise_emitted.emit(event)
	var controller := _find_alert_controller()
	if controller != null and controller.has_method("register_noise_event"):
		controller.call("register_noise_event", event)
	context["noise_event"] = event


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


func _find_alert_controller() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("iso_alert_controller")
