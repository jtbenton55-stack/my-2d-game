class_name MissionDialogueProvider
extends RefCounted
## Small per-mission dialogue seam. Taco (and other missions) extend or wrap this.
## Generic iso code must not preload Taco-specific dialogue scripts.

func get_dialogue_line(_dialogue_id: String, context: Dictionary = {}) -> Dictionary:
	var fb := String(context.get("fallback_text", ""))
	var sp := String(context.get("fallback_speaker", "Mission"))
	return {
		"ok": true,
		"speaker": sp,
		"text": fb,
		"sequence": [],
		"reason": "fallback",
	}


func get_dialogue_sequence(_sequence_id: String, _context: Dictionary = {}) -> Array:
	return []


func has_dialogue(_dialogue_id: String) -> bool:
	return false


func get_provider_id() -> String:
	return "default"
