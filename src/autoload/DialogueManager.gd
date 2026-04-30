extends Node

var is_in_dialogue := false
var current_lines: Array[Dictionary] = []
var current_index := -1
## Prevents double-advancing when both DialogueBox and Player forward the same E press.
var _next_line_debounce_ms := 0

func _ready() -> void:
	EventBus.debug("DialogueManager ready")

func show_simple_dialogue(lines: Array) -> void:
	start_simple_dialogue(lines)

func start_simple_dialogue(lines: Array) -> void:
	current_lines = []
	for item in lines:
		if item is Dictionary:
			current_lines.append(item)
		else:
			current_lines.append({"speaker": "", "text": String(item)})
	if current_lines.is_empty():
		return
	is_in_dialogue = true
	current_index = -1
	EventBus.dialogue_started.emit(current_lines)
	next_line()

func start_character_dialogue(character_id: String) -> void:
	var line := _fallback_line(character_id)
	start_simple_dialogue([{ "speaker": _pretty(character_id), "text": line }])

func next_line() -> void:
	if not is_in_dialogue:
		return
	var now := Time.get_ticks_msec()
	if now - _next_line_debounce_ms < 45:
		return
	_next_line_debounce_ms = now
	current_index += 1
	if current_index >= current_lines.size():
		end_dialogue()
		return
	var line := current_lines[current_index]
	EventBus.dialogue_line_changed.emit(String(line.get("speaker", "")), String(line.get("text", "")))

func end_dialogue() -> void:
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
