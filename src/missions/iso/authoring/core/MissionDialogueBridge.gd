class_name MissionDialogueBridge
extends RefCounted


static func play_dialogue_key(dialogue_key: String, context: Dictionary = {}) -> Dictionary:
	var payload := _context_payload(context)
	var fallback_text := String(payload.get("fallback_text", "")).strip_edges()
	if fallback_text == "":
		return _result(false, "dialogue_key_unresolved", "Dialogue key has no Packet 2A fallback: %s." % dialogue_key, dialogue_key, {"dialogue_key": dialogue_key})
	var speaker := String(payload.get("speaker", ""))
	var line_payload := {
		"speaker": speaker,
		"text": fallback_text,
		"dialogue_key": dialogue_key,
	}
	var result := play_simple_line(line_payload, context)
	result["source_id"] = dialogue_key
	var details: Dictionary = {}
	var raw_details: Variant = result.get("details", {})
	if raw_details is Dictionary:
		details = raw_details
	details["dialogue_key"] = dialogue_key
	result["details"] = details
	return result


static func play_simple_line(payload: Dictionary, _context: Dictionary = {}) -> Dictionary:
	var manager := _autoload("DialogueManager")
	if manager == null:
		return _result(false, "dialogue_manager_missing", "DialogueManager autoload is missing.")
	if not manager.has_method("start_simple_dialogue"):
		return _result(false, "dialogue_api_missing", "DialogueManager.start_simple_dialogue is missing.")
	var lines := _normalize_lines(payload)
	if lines.is_empty():
		return _result(false, "dialogue_lines_missing", "No valid dialogue lines were supplied.")
	manager.call("start_simple_dialogue", lines)
	return _result(true, "dialogue_started", "Dialogue started with %d line(s)." % lines.size(), String(payload.get("dialogue_key", "")), {"line_count": lines.size(), "lines": lines.duplicate(true)})


static func play_bark(speaker: String, text: String, context: Dictionary = {}) -> Dictionary:
	return play_simple_line({"speaker": speaker, "text": text}, context)


static func is_dialogue_busy() -> bool:
	var manager := _autoload("DialogueManager")
	if manager == null:
		return false
	return bool(manager.get("is_in_dialogue"))


static func _normalize_lines(payload: Dictionary) -> Array:
	var lines: Array = []
	var raw_lines: Variant = payload.get("lines", null)
	if raw_lines is Array:
		for item in raw_lines:
			var line := _normalize_line(item)
			if not line.is_empty():
				lines.append(line)
		return lines
	var single := _normalize_line(payload)
	if not single.is_empty():
		lines.append(single)
	return lines


static func _normalize_line(value: Variant) -> Dictionary:
	if value is Dictionary:
		var source := value as Dictionary
		var text := String(source.get("text", "")).strip_edges()
		if text == "":
			return {}
		var out: Dictionary = source.duplicate(true)
		out["speaker"] = String(source.get("speaker", ""))
		out["text"] = text
		return out
	var text := String(value).strip_edges()
	if text == "":
		return {}
	return {"speaker": "", "text": text}


static func _context_payload(context: Dictionary) -> Dictionary:
	var raw_payload: Variant = context.get("payload", {})
	if raw_payload is Dictionary:
		return (raw_payload as Dictionary).duplicate(true)
	return {}


static func _autoload(name: String) -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null(name)


static func _result(ok: bool, code: String, message: String, source_id: String = "", details: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"code": code,
		"message": message,
		"source_id": source_id,
		"details": details,
	}
