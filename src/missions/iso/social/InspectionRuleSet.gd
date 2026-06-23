@tool
class_name InspectionRuleSet
extends Resource

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var accepted_cover_story_ids: Array[StringName] = []
@export var required_credential_ids: Array[StringName] = []
@export var required_protocol_ids: Array[StringName] = []
@export var required_task_ids: Array[StringName] = []
@export var min_professionalism: int = 0
@export var min_cleanliness: int = 0
@export var allow_any_cover_story_if_empty: bool = true
@export var allow_any_credential_if_empty: bool = true
@export var accepted_message: String = "Story checks out."
@export var rejected_message: String = "Something does not add up."


func evaluate(context: Dictionary = {}) -> Dictionary:
	var reasons: Array[String] = []
	var mission_id := MissionFactBridge.resolve_mission_id(context)
	var active_cover := String(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_COVER_STORY_ACTIVE, "", {"mission_id": mission_id}))
	if accepted_cover_story_ids.is_empty():
		if not allow_any_cover_story_if_empty and active_cover == "":
			reasons.append("No cover story is active.")
	elif not _string_array(accepted_cover_story_ids).has(active_cover):
		reasons.append("Cover story '%s' is not accepted here." % active_cover)
	if required_credential_ids.is_empty():
		if not allow_any_credential_if_empty and not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, "", {"mission_id": mission_id})):
			reasons.append("No credential is active.")
	else:
		for credential_id in required_credential_ids:
			if not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CREDENTIAL_ACTIVE, String(credential_id), {"mission_id": mission_id})):
				reasons.append("Missing credential: %s." % String(credential_id))
	for protocol_id in required_protocol_ids:
		if not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_PROTOCOL_COMPLETE, String(protocol_id), {"mission_id": mission_id})):
			reasons.append("Missing protocol: %s." % String(protocol_id))
	for task_id in required_task_ids:
		if not bool(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_BELIEVABLE_TASK_COMPLETE, String(task_id), {"mission_id": mission_id})):
			reasons.append("Missing believable task: %s." % String(task_id))
	var professionalism := int(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_PROFESSIONALISM_SCORE, "", {"mission_id": mission_id}))
	if professionalism < min_professionalism:
		reasons.append("Professionalism %d is below required %d." % [professionalism, min_professionalism])
	var cleanliness := int(SocialStealthAdapterScript.get_fact_value(SocialStealthAdapterScript.FACT_CLEANLINESS_SCORE, "", {"mission_id": mission_id}))
	if cleanliness < min_cleanliness:
		reasons.append("Cleanliness %d is below required %d." % [cleanliness, min_cleanliness])
	var ok := reasons.is_empty()
	return {
		"ok": ok,
		"code": "inspection_passed" if ok else "inspection_rejected",
		"message": accepted_message if ok else rejected_message,
		"source_id": "inspection_rule_set",
		"details": {
			"mission_id": mission_id,
			"active_cover_story_id": active_cover,
			"professionalism": professionalism,
			"cleanliness": cleanliness,
			"reasons": reasons,
		},
	}


func _string_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out
