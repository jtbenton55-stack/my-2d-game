extends MissionDialogueProvider
## Taco Bell–specific provider; loads lines from TacoBellDialogue / JSON.
const _TacoBellDialogue := preload("res://src/missions/iso/runtime/TacoBellDialogue.gd")


func get_dialogue_line(dialogue_id: String, context: Dictionary = {}) -> Dictionary:
	var fb := String(context.get("fallback_text", ""))
	var sp := String(context.get("fallback_speaker", "Mission"))
	var line: Dictionary = _TacoBellDialogue.line(dialogue_id, fb, sp)
	return {
		"ok": true,
		"speaker": String(line.get("speaker", sp)),
		"text": String(line.get("text", fb)),
		"sequence": [],
		"reason": "",
	}


func has_dialogue(dialogue_id: String) -> bool:
	return dialogue_id.strip_edges() != ""


func get_provider_id() -> String:
	return "taco_bell"
