@tool
class_name HideSpotNode
extends MechanicAreaBase

@export_group("Hide Spot")
@export var hidden_detection_modifier: float = 0.35
@export var exposure_decay_on_enter: float = 0.25
@export var reset_modifier_on_exit := true
@export var hidden_message: String = "Hidden. Detection reduced."

var hidden_actor: Node = null
var last_hide_result: Dictionary = {}


func _init() -> void:
	interaction_mode = InteractionMode.INTERACT_REQUIRED
	one_shot = false
	prompt_text = "Press E: Hide"
	locked_prompt_text = "Cannot hide here"
	preview_color = Color(0.2, 0.55, 0.85, 0.35)


func _ready() -> void:
	super._ready()
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result: Dictionary = super.activate(actor, reason)
	if bool(result.get("ok", false)):
		last_hide_result = _apply_hide(actor)
		var details: Dictionary = result.get("details", {}) as Dictionary
		details["hide_result"] = last_hide_result
		result["details"] = details
		last_activation_result = result
		refresh_debug_label()
	return result


func enter_hide(actor: Node = null) -> Dictionary:
	return activate(actor, "hide_enter")


func exit_hide(actor: Node = null) -> Dictionary:
	if actor != null and hidden_actor != null and actor != hidden_actor:
		return _result(false, "actor_not_hidden", "Actor is not using this hide spot.", String(mechanic_id))
	var controller := _find_alert_controller()
	if reset_modifier_on_exit and controller != null and controller.has_method("set_detection_modifier"):
		controller.call("set_detection_modifier", 1.0)
	hidden_actor = null
	last_hide_result = _result(true, "hide_exited", "Hide spot exited.", String(mechanic_id))
	refresh_debug_label()
	return last_hide_result


func is_actor_hidden(actor: Node = null) -> bool:
	if hidden_actor == null or not is_instance_valid(hidden_actor):
		return false
	return actor == null or actor == hidden_actor


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["hidden_detection_modifier"] = hidden_detection_modifier
	context["exposure_decay_on_enter"] = exposure_decay_on_enter
	context["hide_spot_id"] = String(mechanic_id)
	return context


func handle_body_exited(body: Node) -> void:
	_on_body_exited(body)


func _on_body_exited(body: Node) -> void:
	if Engine.is_editor_hint():
		return
	if hidden_actor == body:
		exit_hide(body)


func _debug_label_text() -> String:
	if is_actor_hidden():
		return "HIDDEN"
	return super._debug_label_text()


func _apply_hide(actor: Node) -> Dictionary:
	var controller := _find_alert_controller()
	if controller == null:
		return _result(false, "alert_controller_missing", "MissionAlertController is missing.", String(mechanic_id))
	hidden_actor = actor
	if controller.has_method("set_detection_modifier"):
		controller.call("set_detection_modifier", hidden_detection_modifier)
	if exposure_decay_on_enter > 0.0 and controller.has_method("decay_exposure"):
		controller.call("decay_exposure", exposure_decay_on_enter)
	return _result(true, "hide_entered", hidden_message, String(mechanic_id), {
		"hidden_detection_modifier": hidden_detection_modifier,
		"exposure_decay_on_enter": exposure_decay_on_enter,
	})


func _find_alert_controller() -> Node:
	if Engine.is_editor_hint() or get_tree() == null:
		return null
	var grouped := get_tree().get_first_node_in_group("iso_alert_controller")
	if grouped != null:
		return grouped
	if get_tree().current_scene != null:
		return get_tree().current_scene.find_child("MissionAlertController", true, false)
	return null
