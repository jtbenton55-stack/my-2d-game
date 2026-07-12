@tool
class_name ProtocolZone
extends MechanicAreaBase

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export_group("Protocol")
@export var protocol_id: StringName = &""
@export var required_cover_story_id: StringName = &""
@export var required_credential_id: StringName = &""
@export var completed_flag: StringName = &""
@export var professionalism_delta: int = 1
@export var cleanliness_delta: int = 0
@export var require_companion_waiting: bool = false
@export var companion_group: StringName = &"bentley"
@export var required_companion_wait_marker_id: StringName = &""
@export var companion_wait_max_distance: float = 96.0
@export var completion_message: String = "Protocol complete. You look like you belong here."
@export var blocked_message: String = "Follow the posted protocol before entering."

var last_protocol_result: Dictionary = {}


func _init() -> void:
	prompt_text = "Press E: Follow protocol"
	locked_prompt_text = "Protocol unavailable"
	preview_color = Color(0.75, 0.55, 0.25, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["protocol_id"] = String(_resolved_protocol_id())
	context["required_cover_story_id"] = String(required_cover_story_id)
	context["required_credential_id"] = String(required_credential_id)
	context["protocol_result"] = last_protocol_result
	return context


func activate(actor: Node = null, reason: String = "interact") -> Dictionary:
	var context := build_context(actor)
	var social_result := _social_prerequisites(context)
	if not bool(social_result.get("ok", false)):
		last_protocol_result = social_result
		last_effect_result = apply_failure_effects(context)
		last_activation_result = _result(false, "protocol_blocked", String(social_result.get("message", "Protocol blocked.")), String(mechanic_id), {"reason": reason, "protocol_result": social_result, "effect_result": last_effect_result})
		activation_failed.emit(String(mechanic_id), last_activation_result)
		refresh_debug_label()
		return last_activation_result
	var result: Dictionary = super.activate(actor, reason)
	if not bool(result.get("ok", false)) or String(result.get("code", "")) != "activation_succeeded":
		return result
	last_protocol_result = SocialStealthAdapterScript.complete_protocol(String(_resolved_protocol_id()), {"source_id": String(mechanic_id)}, context)
	if professionalism_delta != 0:
		SocialStealthAdapterScript.adjust_professionalism(professionalism_delta, context)
	if cleanliness_delta != 0:
		SocialStealthAdapterScript.adjust_cleanliness(cleanliness_delta, context)
	if completed_flag != &"":
		MissionFactBridge.set_fact_value(&"mission_flag", String(completed_flag), true, context)
	var details: Dictionary = (result.get("details", {}) as Dictionary).duplicate(true)
	details["protocol_result"] = last_protocol_result
	result["details"] = details
	result["message"] = completion_message
	last_activation_result = result
	refresh_debug_label()
	return result


func complete_protocol(actor: Node = null, reason: String = "script") -> Dictionary:
	return activate(actor, reason)


func _social_prerequisites(context: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	if required_cover_story_id != &"" and not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, String(required_cover_story_id), context)):
		reasons.append("Missing cover story: %s." % String(required_cover_story_id))
	if required_credential_id != &"" and not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, String(required_credential_id), context)):
		reasons.append("Missing credential: %s." % String(required_credential_id))
	if require_companion_waiting and not _companion_is_waiting():
		reasons.append("Bentley must wait outside the VIP lounge.")
	var ok := reasons.is_empty()
	return _result(ok, "protocol_prerequisites_met" if ok else "protocol_prerequisites_failed", "Protocol prerequisites met." if ok else blocked_message, String(_resolved_protocol_id()), {"reasons": reasons})


func _companion_is_waiting() -> bool:
	if get_tree() == null:
		return false
	var companion := get_tree().get_first_node_in_group(String(companion_group))
	if companion == null or not companion.has_method("get_command_state"):
		return false
	var state := companion.call("get_command_state") as Dictionary
	if not bool(state.get("staying", false)):
		return false
	if required_companion_wait_marker_id != &"" and String(state.get("wait_marker_id", "")) != String(required_companion_wait_marker_id):
		return false
	if required_companion_wait_marker_id != &"" and companion is Node2D:
		var wait_position: Variant = state.get("wait_marker_position", Vector2.INF)
		if not (wait_position is Vector2) or (companion as Node2D).global_position.distance_to(wait_position) > companion_wait_max_distance:
			return false
	return true


func _resolved_protocol_id() -> StringName:
	if protocol_id != &"":
		return protocol_id
	return mechanic_id
