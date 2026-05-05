class_name TacoBellDialogue
extends RefCounted

const DIALOGUE_PATH := "res://assets/dialogue/taco_bell_dialogue.json"

static var _cache: Dictionary = {}
static var _loaded := false


static func line(dialogue_id: String, fallback_text: String, fallback_speaker: String = "Mission") -> Dictionary:
	_ensure_loaded()
	var entry: Dictionary = _cache.get(dialogue_id, {})
	return {
		"speaker": String(entry.get("speaker", fallback_speaker)),
		"text": String(entry.get("text", fallback_text)),
	}


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_cache.clear()
	if not FileAccess.file_exists(DIALOGUE_PATH):
		return
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var root: Dictionary = parsed
	var entries = root.get("entries", [])
	if not (entries is Array):
		return
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item
		var dialogue_id := String(entry.get("dialogue_id", "")).strip_edges()
		if dialogue_id == "":
			continue
		_cache[dialogue_id] = entry
