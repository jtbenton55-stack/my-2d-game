@tool
class_name CredentialData
extends Resource

const SocialStealthAdapterScript := preload("res://src/missions/iso/social/SocialStealthAdapter.gd")

@export var credential_id: StringName = &""
@export var display_name: String = "Credential"
@export_enum("badge", "uniform", "document", "delivery", "appointment", "generic") var credential_kind: String = "badge"
@export_multiline var description: String = ""
@export var valid_cover_story_ids: Array[StringName] = []
@export var valid_protocol_ids: Array[StringName] = []
@export var trust_value: int = 1


func to_dictionary() -> Dictionary:
	return {
		"credential_id": String(credential_id),
		"display_name": display_name,
		"credential_kind": credential_kind,
		"description": description,
		"valid_cover_story_ids": _string_array(valid_cover_story_ids),
		"valid_protocol_ids": _string_array(valid_protocol_ids),
		"trust_value": trust_value,
	}


func grant(context: Dictionary = {}) -> Dictionary:
	return SocialStealthAdapterScript.grant_credential(String(credential_id), to_dictionary(), context)


func _string_array(values: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out
