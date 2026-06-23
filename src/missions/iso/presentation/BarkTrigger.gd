@tool
class_name BarkTrigger
extends "res://src/missions/iso/presentation/DialogueTriggerZone.gd"

@export_group("Bark")
@export var bark_id: StringName = &""
@export var bark_speaker: String = "Bentley"
@export_multiline var bark_text: String = "Bark."
@export var bark_payload: Dictionary = {}


func _play_dialogue(context: Dictionary) -> Dictionary:
	var payload := bark_payload.duplicate(true)
	var speaker := String(payload.get("speaker", bark_speaker))
	var text := String(payload.get("text", bark_text))
	var dialogue_context := context.duplicate(true)
	dialogue_context["payload"] = payload
	var result := MissionDialogueBridge.play_bark(speaker, text, dialogue_context)
	var details: Dictionary = {}
	var raw_details: Variant = result.get("details", {})
	if raw_details is Dictionary:
		details = (raw_details as Dictionary).duplicate(true)
	details["bark_id"] = String(bark_id)
	details["source"] = "bark_trigger"
	result["details"] = details
	result["source_id"] = String(bark_id)
	return result
