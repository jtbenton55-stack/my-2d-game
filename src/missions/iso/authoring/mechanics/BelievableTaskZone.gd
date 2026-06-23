@tool
class_name BelievableTaskZone
extends MechanicAreaBase

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export_group("Believable Task")
@export var task_id: StringName = &""
@export var cover_story_id: StringName = &""
@export var protocol_id: StringName = &""
@export var completed_flag: StringName = &""
@export var professionalism_delta: int = 1
@export var cleanliness_delta: int = 0
@export var exposure_decay: float = 0.0

var last_task_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Do believable task"
	locked_prompt_text = "Task would look suspicious"
	preview_color = Color(0.25, 0.65, 0.45, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["believable_task_id"] = String(_resolved_task_id())
	context["cover_story_id"] = String(cover_story_id)
	context["protocol_id"] = String(protocol_id)
	context["task_result"] = last_task_result
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var result: Dictionary = super.activate(actor, reason)
	if not bool(result.get("ok", false)) or String(result.get("code", "")) != "activation_succeeded":
		return result
	var context := build_context(actor)
	var data := {"cover_story_id": String(cover_story_id), "protocol_id": String(protocol_id), "source_id": String(mechanic_id)}
	last_task_result = SocialStealthAdapterScript.complete_task(String(_resolved_task_id()), data, context)
	if professionalism_delta != 0:
		SocialStealthAdapterScript.adjust_professionalism(professionalism_delta, context)
	if cleanliness_delta != 0:
		SocialStealthAdapterScript.adjust_cleanliness(cleanliness_delta, context)
	if completed_flag != &"":
		MissionFactBridge.set_fact_value(&"mission_flag", String(completed_flag), true, context)
	_apply_alert_decay()
	var details: Dictionary = (result.get("details", {}) as Dictionary).duplicate(true)
	details["task_result"] = last_task_result
	result["details"] = details
	last_activation_result = result
	refresh_debug_label()
	return result


func complete_task(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _apply_alert_decay() -> void:
	if exposure_decay <= 0.0 or Engine.is_editor_hint() or get_tree() == null:
		return
	var controller := get_tree().get_first_node_in_group("iso_alert_controller")
	if controller == null and get_tree().current_scene != null:
		controller = get_tree().current_scene.find_child("MissionAlertController", true, false)
	if controller != null and controller.has_method("decay_exposure"):
		controller.call("decay_exposure", exposure_decay)


func _resolved_task_id() -> StringName:
	if task_id != &"":
		return task_id
	return mechanic_id
