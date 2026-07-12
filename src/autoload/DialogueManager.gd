extends Node

var is_in_dialogue := false
var current_lines: Array[Dictionary] = []
var current_index := -1
## Prevents double-advancing when both DialogueBox and Player forward the same E press.
var _next_line_debounce_ms := 0
var _dialogue_generation := 0

func _ready() -> void:
	EventBus.debug("DialogueManager ready")

func show_simple_dialogue(lines: Array) -> void:
	start_simple_dialogue(lines)

func start_simple_dialogue(lines: Array) -> void:
	_dialogue_generation += 1
	current_lines = []
	for item in lines:
		var line: Dictionary
		if item is Dictionary:
			line = (item as Dictionary).duplicate(true)
		else:
			line = {"speaker": "", "text": String(item)}
		line["auto_advance_seconds"] = maxf(0.0, float(line.get("auto_advance_seconds", 0.0)))
		line["allow_manual_advance"] = bool(line.get("allow_manual_advance", true))
		line["allow_skip"] = bool(line.get("allow_skip", true))
		current_lines.append(line)
	if current_lines.is_empty():
		return
	is_in_dialogue = true
	current_index = -1
	EventBus.dialogue_started.emit(current_lines)
	_advance_line(_dialogue_generation)

func start_character_dialogue(character_id: String) -> void:
	var line := _fallback_line(character_id)
	start_simple_dialogue([{ "speaker": _pretty(character_id), "text": line }])

func next_line() -> void:
	if not is_in_dialogue:
		return
	if current_index >= 0 and not bool(current_lines[current_index].get("allow_manual_advance", true)):
		return
	var now := Time.get_ticks_msec()
	if now - _next_line_debounce_ms < 45:
		return
	_next_line_debounce_ms = now
	_advance_line(_dialogue_generation)

func skip_dialogue() -> void:
	if not is_in_dialogue:
		return
	if current_index >= 0 and not bool(current_lines[current_index].get("allow_skip", true)):
		return
	end_dialogue()

func _advance_line(generation: int) -> void:
	if not is_in_dialogue or generation != _dialogue_generation:
		return
	current_index += 1
	if current_index >= current_lines.size():
		end_dialogue()
		return
	var line := current_lines[current_index]
	var speaker := String(line.get("speaker", ""))
	var text := String(line.get("text", ""))
	var portrait_id := String(line.get("portrait_id", ""))
	# Legacy signal stays exactly as it was (two args) so existing listeners do not break.
	EventBus.dialogue_line_changed.emit(speaker, text)
	# Phase 0M-C3 - new signal carries portrait_id + the full line dict for
	# the dialogue UI's left-side portrait support.
	EventBus.dialogue_line_changed_full.emit(speaker, text, portrait_id, line)
	var auto_advance_seconds := float(line.get("auto_advance_seconds", 0.0))
	if auto_advance_seconds > 0.0:
		_schedule_auto_advance(auto_advance_seconds, generation, current_index)

func _schedule_auto_advance(seconds: float, generation: int, line_index: int) -> void:
	# process_always=false pauses with the tree; ignore_time_scale defaults to false.
	await get_tree().create_timer(seconds, false).timeout
	if generation != _dialogue_generation or not is_in_dialogue or current_index != line_index:
		return
	_advance_line(generation)

func end_dialogue() -> void:
	_dialogue_generation += 1
	is_in_dialogue = false
	current_lines.clear()
	current_index = -1
	EventBus.dialogue_ended.emit()

func _fallback_line(character_id: String) -> String:
	match character_id:
		"louis":
			return "I deliver tacos, secrets, and occasionally fugitives. Depends on the tip."
		"jake":
			return "As your doctor, fewer rooftop fistfights. As your boyfriend, I'm unfortunately impressed."
		"mere":
			return "You are two bad decisions away from a felony and one good plan away from winning."
		"yordano":
			return "Give me one clean bass drop and I can make a whole room forget what it was guarding."
		"dom":
			return "In this city, you don't need a crew. You need family."
		_:
			return "The city is listening. Make the next move count."

func _pretty(id: String) -> String:
	return id.replace("_", " ").capitalize()
