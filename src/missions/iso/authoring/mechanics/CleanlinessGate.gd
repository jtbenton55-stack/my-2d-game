@tool
class_name CleanlinessGate
extends LockedInteractionNode

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export_group("Cleanliness Gate")
@export var min_cleanliness: int = 1
@export var required_protocol_id: StringName = &""
@export var cleanliness_delta_on_success: int = 0


func _init() -> void:
	lock_kind = "scanner"
	prompt_text = "Press E: Pass cleanliness gate"
	locked_prompt_text = "Too messy to pass"
	preview_color = Color(0.3, 0.85, 0.85, 0.35)


func build_context(actor: Node = null) -> Dictionary:
	var context := super.build_context(actor)
	context["min_cleanliness"] = min_cleanliness
	context["required_protocol_id"] = String(required_protocol_id)
	return context


func unlock(actor: Node = null, reason: String = "interact") -> Dictionary:
	var context := build_context(actor)
	var gate_result := _cleanliness_requirements(context)
	if not bool(gate_result.get("ok", false)):
		last_unlock_result = _result(false, "cleanliness_gate_blocked", String(gate_result.get("message", "Cleanliness gate blocked.")), String(mechanic_id), {"reason": reason, "gate_result": gate_result})
		activation_failed.emit(String(mechanic_id), last_unlock_result)
		refresh_debug_label()
		return last_unlock_result
	var result: Dictionary = super.unlock(actor, reason)
	if bool(result.get("ok", false)) and cleanliness_delta_on_success != 0:
		SocialStealthAdapterScript.adjust_cleanliness(cleanliness_delta_on_success, context)
	return result


func _cleanliness_requirements(context: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var cleanliness := int(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CLEANLINESS_SCORE, "", context))
	if cleanliness < min_cleanliness:
		reasons.append("Cleanliness %d is below required %d." % [cleanliness, min_cleanliness])
	if required_protocol_id != &"" and not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_PROTOCOL_COMPLETE, String(required_protocol_id), context)):
		reasons.append("Missing protocol: %s." % String(required_protocol_id))
	var ok := reasons.is_empty()
	return _result(ok, "cleanliness_gate_ready" if ok else "cleanliness_gate_failed", "Cleanliness gate ready." if ok else "Cleanliness gate requirements failed.", String(mechanic_id), {"reasons": reasons, "cleanliness": cleanliness})
