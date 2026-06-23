class_name MissionDialogueBridge
extends RefCounted

static var _dialogue_registry: Dictionary = {}


static func play_dialogue_key(dialogue_key: String, context: Dictionary = {}) -> Dictionary:
	var key := dialogue_key.strip_edges()
	if key == "":
		return _result(false, "dialogue_key_missing", "Dialogue key is missing.")
	var payload := _context_payload(context)
	var registry_result := _play_registered_key(key, payload, context)
	if bool(registry_result.get("handled", false)):
		return registry_result.get("result", {}) as Dictionary
	var provider_result := _play_provider_key(key, payload, context)
	if bool(provider_result.get("handled", false)):
		return provider_result.get("result", {}) as Dictionary
	var fallback_text := String(payload.get("fallback_text", "")).strip_edges()
	if fallback_text == "":
		return _result(false, "dialogue_key_unresolved", "Dialogue key has no fallback or provider line: %s." % key, key, {"dialogue_key": key})
	var speaker := String(payload.get("speaker", payload.get("fallback_speaker", "")))
	var line_payload := {
		"speaker": speaker,
		"text": fallback_text,
		"dialogue_key": key,
	}
	var result := play_simple_line(line_payload, context)
	result["source_id"] = key
	var details: Dictionary = {}
	var raw_details: Variant = result.get("details", {})
	if raw_details is Dictionary:
		details = raw_details
	details["dialogue_key"] = key
	details["source"] = "fallback"
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


static func register_dialogue_key(dialogue_key: String, value: Variant) -> Dictionary:
	var key := dialogue_key.strip_edges()
	if key == "":
		return _result(false, "dialogue_key_missing", "Dialogue key is missing.")
	var lines := _normalize_lines_from_variant(value)
	if lines.is_empty():
		return _result(false, "dialogue_lines_missing", "No valid dialogue lines were supplied.", key)
	_dialogue_registry[key] = lines.duplicate(true)
	return _result(true, "dialogue_key_registered", "Dialogue key registered: %s." % key, key, {"line_count": lines.size()})


static func unregister_dialogue_key(dialogue_key: String) -> Dictionary:
	var key := dialogue_key.strip_edges()
	_dialogue_registry.erase(key)
	return _result(true, "dialogue_key_unregistered", "Dialogue key unregistered: %s." % key, key)


static func clear_dialogue_registry() -> void:
	_dialogue_registry.clear()


static func has_dialogue_key(dialogue_key: String, context: Dictionary = {}) -> bool:
	var key := dialogue_key.strip_edges()
	if _dialogue_registry.has(key):
		return true
	var provider := _resolve_dialogue_provider(context)
	return provider != null and provider.has_method("has_dialogue") and bool(provider.call("has_dialogue", key))


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


static func _normalize_lines_from_variant(value: Variant) -> Array:
	if value is Array:
		return _normalize_lines({"lines": value})
	if value is Dictionary:
		return _normalize_lines(value)
	return _normalize_lines({"text": String(value)})


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


static func _play_registered_key(dialogue_key: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	if not _dialogue_registry.has(dialogue_key):
		return {"handled": false}
	var lines := _normalize_lines({"lines": _dialogue_registry.get(dialogue_key, [])})
	var line_payload := payload.duplicate(true)
	line_payload["lines"] = lines
	line_payload["dialogue_key"] = dialogue_key
	var result := play_simple_line(line_payload, context)
	result["source_id"] = dialogue_key
	_result_add_details(result, {"dialogue_key": dialogue_key, "source": "registry"})
	return {"handled": true, "result": result}


static func _play_provider_key(dialogue_key: String, payload: Dictionary, context: Dictionary) -> Dictionary:
	var provider := _resolve_dialogue_provider(context)
	if provider == null:
		return {"handled": false}
	var provider_context := payload.duplicate(true)
	provider_context["fallback_text"] = String(payload.get("fallback_text", ""))
	provider_context["fallback_speaker"] = String(payload.get("fallback_speaker", payload.get("speaker", "Mission")))
	if provider.has_method("get_dialogue_sequence"):
		var sequence_value: Variant = provider.call("get_dialogue_sequence", dialogue_key, provider_context)
		if sequence_value is Array and not (sequence_value as Array).is_empty():
			var sequence_result := play_simple_line({"lines": sequence_value, "dialogue_key": dialogue_key}, context)
			sequence_result["source_id"] = dialogue_key
			_result_add_details(sequence_result, {"dialogue_key": dialogue_key, "source": "provider_sequence", "provider_id": _provider_id(provider)})
			return {"handled": true, "result": sequence_result}
	if not provider.has_method("get_dialogue_line"):
		return {"handled": false}
	var line_result: Variant = provider.call("get_dialogue_line", dialogue_key, provider_context)
	if not (line_result is Dictionary):
		return {"handled": false}
	var line := line_result as Dictionary
	var text := String(line.get("text", "")).strip_edges()
	if text == "":
		return {"handled": false}
	var line_payload := payload.duplicate(true)
	line_payload["speaker"] = String(line.get("speaker", payload.get("speaker", payload.get("fallback_speaker", ""))))
	line_payload["text"] = text
	line_payload["dialogue_key"] = dialogue_key
	if line.has("portrait_id"):
		line_payload["portrait_id"] = line.get("portrait_id")
	var result := play_simple_line(line_payload, context)
	result["source_id"] = dialogue_key
	_result_add_details(result, {"dialogue_key": dialogue_key, "source": "provider_line", "provider_id": _provider_id(provider)})
	return {"handled": true, "result": result}


static func _resolve_dialogue_provider(context: Dictionary) -> Object:
	var explicit: Variant = context.get("dialogue_provider", null)
	if explicit is Object:
		return explicit as Object
	var payload := _context_payload(context)
	var payload_provider: Variant = payload.get("dialogue_provider", null)
	if payload_provider is Object:
		return payload_provider as Object
	var mechanic: Variant = context.get("mechanic", null)
	if mechanic is Node:
		var provider := _provider_from_node(mechanic as Node)
		if provider != null:
			return provider
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var scene := (main_loop as SceneTree).current_scene
		return _provider_from_node(scene)
	return null


static func _provider_from_node(node: Node) -> Object:
	var current := node
	while current != null:
		if current.has_method("get_mission_dialogue_provider"):
			var provider: Variant = current.call("get_mission_dialogue_provider")
			if provider is Object:
				return provider as Object
		if current.has_method("_resolve_dialogue_provider"):
			var private_provider: Variant = current.call("_resolve_dialogue_provider")
			if private_provider is Object:
				return private_provider as Object
		current = current.get_parent()
	return null


static func _provider_id(provider: Object) -> String:
	if provider != null and provider.has_method("get_provider_id"):
		return String(provider.call("get_provider_id"))
	return ""


static func _result_add_details(result: Dictionary, extra: Dictionary) -> void:
	var details: Dictionary = {}
	var raw_details: Variant = result.get("details", {})
	if raw_details is Dictionary:
		details = (raw_details as Dictionary).duplicate(true)
	for key in extra.keys():
		details[key] = extra[key]
	result["details"] = details


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
