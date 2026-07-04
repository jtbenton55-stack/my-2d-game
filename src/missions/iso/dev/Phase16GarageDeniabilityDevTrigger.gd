@tool
class_name Phase16GarageDeniabilityDevTrigger
extends Node

@export var enabled: bool = true
@export var controller_path: NodePath = NodePath("../Phase16GarageManagerDeniabilityController")
@export_multiline var debug_note: String = "Dev-only callable trigger for Phase 16 Taco garage-manager deniability routes."


func _ready() -> void:
	add_to_group("phase16_garage_deniability_dev_trigger")


func run_clean_social_route(details: Dictionary = {}) -> Dictionary:
	return _call_controller_route("run_clean_social_route", details)


func run_bentley_distraction_route(details: Dictionary = {}) -> Dictionary:
	return _call_controller_route("run_bentley_distraction_route", details)


func run_evidence_route(details: Dictionary = {}) -> Dictionary:
	return _call_controller_route("run_evidence_route", details)


func run_messy_authority_route(details: Dictionary = {}) -> Dictionary:
	return _call_controller_route("run_messy_authority_route", details)


func run_cleanup_redirect_trace(details: Dictionary = {}) -> Dictionary:
	return _call_controller_route("run_cleanup_redirect_trace", details)


func get_phase16_summary() -> Dictionary:
	var controller := _controller()
	if controller == null or not controller.has_method("get_phase16_summary"):
		return _result(false, "phase16_controller_missing", "Phase 16 controller is missing.", "phase16_dev_trigger").details
	return controller.call("get_phase16_summary")


func _call_controller_route(method_name: String, details: Dictionary) -> Dictionary:
	if not enabled:
		return _result(false, "phase16_dev_trigger_disabled", "Phase 16 dev trigger is disabled.", method_name)
	var controller := _controller()
	if controller == null:
		return _result(false, "phase16_controller_missing", "Phase 16 controller is missing.", method_name)
	if not controller.has_method(method_name):
		return _result(false, "phase16_route_missing", "Phase 16 controller does not expose route: %s." % method_name, method_name)
	var payload := details.duplicate(true)
	payload["triggered_by"] = "phase16_dev_trigger"
	return controller.call(method_name, payload)


func _controller() -> Node:
	var from_path := get_node_or_null(controller_path)
	if from_path != null:
		return from_path
	var sibling := get_parent().get_node_or_null("Phase16GarageManagerDeniabilityController") if get_parent() != null else null
	if sibling != null:
		return sibling
	var tree := get_tree() if is_inside_tree() else null
	return tree.get_first_node_in_group("mission_encounter_controller") if tree != null else null


func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {"ok": ok, "code": code, "message": message, "source_id": source_id, "details": details}
