@tool
class_name CoverStoryData
extends Resource

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var cover_story_id: StringName = &""
@export var display_name: String = "Cover Story"
@export_multiline var description: String = ""
@export var role_label: String = "staff"
@export var required_credential_ids: Array[StringName] = []
@export var supporting_protocol_ids: Array[StringName] = []
@export var professionalism_bonus: int = 0


func to_dictionary() -> Dictionary:
	return {
		"cover_story_id": String(cover_story_id),
		"display_name": display_name,
		"description": description,
		"role_label": role_label,
		"required_credential_ids": _string_array(required_credential_ids),
		"supporting_protocol_ids": _string_array(supporting_protocol_ids),
		"professionalism_bonus": professionalism_bonus,
	}


func activate(context: Dictionary = {}) -> Dictionary:
	var result: Dictionary = SocialStealthAdapterScript.set_cover_story(String(cover_story_id), to_dictionary(), context)
	if professionalism_bonus != 0 and bool(result.get("ok", false)):
		SocialStealthAdapterScript.adjust_professionalism(professionalism_bonus, context)
	return result


func _string_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out
