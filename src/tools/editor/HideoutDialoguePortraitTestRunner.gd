extends Node

## Phase 0M-C3 - simple test runner scene that lets the human verify
## the new left-side portraits + character dialogue without entering the
## full HideoutHub scene. Click each button to drive the DialogueBox
## through the new content. Press E (the project's `interact` action) to
## advance.

const HideoutCharacterDialogueBank = preload("res://src/dialogue/HideoutCharacterDialogueBank.gd")

@onready var _jake_btn := get_node_or_null("UI/ButtonRoot/JakeButton") as Button
@onready var _parmida_btn := get_node_or_null("UI/ButtonRoot/ParmidaButton") as Button
@onready var _mere_btn := get_node_or_null("UI/ButtonRoot/MereButton") as Button
@onready var _bentley_btn := get_node_or_null("UI/ButtonRoot/BentleyButton") as Button
@onready var _louis_btn := get_node_or_null("UI/ButtonRoot/LouisButton") as Button
@onready var _fallback_btn := get_node_or_null("UI/ButtonRoot/FallbackButton") as Button
@onready var _no_portrait_btn := get_node_or_null("UI/ButtonRoot/NoPortraitButton") as Button

func _ready() -> void:
	if _jake_btn:
		_jake_btn.pressed.connect(_speak.bind("jake"))
	if _parmida_btn:
		_parmida_btn.pressed.connect(_speak.bind("parmida"))
	if _mere_btn:
		_mere_btn.pressed.connect(_speak.bind("mere"))
	if _bentley_btn:
		_bentley_btn.pressed.connect(_speak.bind("bentley"))
	if _louis_btn:
		_louis_btn.pressed.connect(_speak.bind("louis"))
	if _fallback_btn:
		_fallback_btn.pressed.connect(_speak_unknown)
	if _no_portrait_btn:
		_no_portrait_btn.pressed.connect(_speak_no_portrait)

func _speak(speaker_id: String) -> void:
	var lines: Array = HideoutCharacterDialogueBank.build_short_sequence(speaker_id, 3)
	if lines.is_empty():
		return
	DialogueManager.start_simple_dialogue(lines)

func _speak_unknown() -> void:
	DialogueManager.start_simple_dialogue([
		{"speaker": "Mystery Voice", "text": "I have no registered portrait, but I should not crash. The fallback silhouette must appear."},
		{"speaker": "Mystery Voice", "text": "Press E to advance one more time, just to confirm dialogue still flows."},
	])

func _speak_no_portrait() -> void:
	# Caller passes only speaker/text - portrait_id is intentionally missing
	# to confirm legacy callers still work.
	DialogueManager.start_simple_dialogue([
		"This line has no speaker and no portrait_id. Existing dialogue calls must keep working.",
		"Press E to end.",
	])
