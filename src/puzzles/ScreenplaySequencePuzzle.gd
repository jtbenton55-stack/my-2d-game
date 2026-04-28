extends Control

# Screenplay sequence: Opening Image -> Setup -> Inciting Incident -> Debate -> 
# Break into Act II -> Midpoint -> All Is Lost -> Climax -> Final Image

const CORRECT_SEQUENCE = [
	"Opening Image",
	"Setup",
	"Inciting Incident",
	"Debate",
	"Break into Act II",
	"Midpoint",
	"All Is Lost",
	"Climax",
	"Final Image"
]

var available_beats := [
	"Opening Image",
	"Setup",
	"Inciting Incident",
	"Debate",
	"Break into Act II",
	"Midpoint",
	"All Is Lost",
	"Climax",
	"Final Image"
]

var player_sequence: Array[String] = []
var solved := false

signal puzzle_solved
signal puzzle_failed

@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var sequence_container: HBoxContainer = $Panel/VBoxContainer/SequenceContainer
@onready var beats_container: GridContainer = $Panel/VBoxContainer/BeatsContainer
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var reset_button: Button = $Panel/VBoxContainer/ButtonRow/ResetButton
@onready var submit_button: Button = $Panel/VBoxContainer/ButtonRow/SubmitButton
@onready var close_button: Button = $Panel/VBoxContainer/ButtonRow/CloseButton
@onready var help_button: Button = $Panel/VBoxContainer/ButtonRow/HelpButton

func _ready() -> void:
	prompt_label.text = "Assemble the screenplay structure in order:"
	feedback_label.text = "Select beats in order..."
	
	reset_button.pressed.connect(_on_reset_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	close_button.pressed.connect(_on_close_pressed)
	help_button.pressed.connect(_on_help_pressed)
	
	_create_sequence_slots()
	_create_beat_buttons()
	
	reset_button.grab_focus()

func _create_sequence_slots() -> void:
	for child in sequence_container.get_children():
		child.queue_free()
	
	# Create 9 slots for the sequence
	for i in range(9):
		var slot := ColorRect.new()
		slot.custom_minimum_size = Vector2(100, 50)
		slot.color = Color(0.2, 0.2, 0.25, 1.0)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var label := Label.new()
		label.name = "SlotLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(100, 50)
		label.add_theme_font_size_override("font_size", 10)
		
		slot.add_child(label)
		sequence_container.add_child(slot)

func _create_beat_buttons() -> void:
	for child in beats_container.get_children():
		child.queue_free()
	
	beats_container.columns = 3
	
	for beat in available_beats:
		var button := Button.new()
		button.text = beat
		button.custom_minimum_size = Vector2(140, 45)
		button.pressed.connect(_on_beat_pressed.bind(beat, button))
		beats_container.add_child(button)

func _on_beat_pressed(beat: String, button: Button) -> void:
	if solved:
		return
	
	if player_sequence.size() >= 9:
		feedback_label.text = "Sequence is full! Submit or reset."
		return
	
	player_sequence.append(beat)
	_update_sequence_display()
	button.disabled = true
	button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	AudioManager.play_sfx("ui_click")
	
	if player_sequence.size() == 9:
		feedback_label.text = "Sequence complete. Submit to verify."

func _update_sequence_display() -> void:
	var slots := sequence_container.get_children()
	
	for i in range(slots.size()):
		var slot := slots[i] as ColorRect
		var label := slot.get_node("SlotLabel") as Label
		
		if i < player_sequence.size():
			label.text = str(i + 1) + ". " + player_sequence[i]
			slot.color = Color(0.25, 0.35, 0.45, 1.0)
		else:
			label.text = ""
			slot.color = Color(0.2, 0.2, 0.25, 1.0)

func _on_reset_pressed() -> void:
	player_sequence.clear()
	_update_sequence_display()
	
	# Re-enable all beat buttons
	for button in beats_container.get_children():
		button.disabled = false
		button.modulate = Color(1, 1, 1, 1)
	
	feedback_label.text = "Sequence reset. Try again."
	AudioManager.play_sfx("ui_back")

func _on_submit_pressed() -> void:
	if solved:
		return
	
	if player_sequence.size() < 9:
		feedback_label.text = "Complete the sequence first!"
		return
	
	var correct_count := 0
	var wrong_positions := []
	
	for i in range(9):
		if player_sequence[i] == CORRECT_SEQUENCE[i]:
			correct_count += 1
		else:
			wrong_positions.append(i)
	
	if correct_count == 9:
		_solve_puzzle()
	else:
		_show_feedback(correct_count, wrong_positions)

func _show_feedback(correct_count: int, wrong_positions: Array) -> void:
	feedback_label.text = "Correct: %d/9. Keep trying!" % correct_count
	
	# Highlight correct slots in green, wrong in red
	var slots := sequence_container.get_children()
	for i in range(9):
		var slot := slots[i] as ColorRect
		if player_sequence[i] == CORRECT_SEQUENCE[i]:
			slot.color = Color(0.2, 0.6, 0.3, 1.0)
		else:
			slot.color = Color(0.6, 0.2, 0.2, 1.0)
	
	AudioManager.play_sfx("ui_error")

func _solve_puzzle() -> void:
	solved = true
	feedback_label.text = "Perfect! The screenplay structure is complete."
	
	# All slots green
	var slots := sequence_container.get_children()
	for slot in slots:
		slot.color = Color(0.2, 0.7, 0.3, 1.0)
	
	# Disable all buttons
	for button in beats_container.get_children():
		button.disabled = true
	
	reset_button.disabled = true
	submit_button.disabled = true
	
	AudioManager.play_sfx("puzzle_complete")
	
	puzzle_solved.emit()
	
	# Auto-close after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_close_pressed() -> void:
	if not solved:
		puzzle_failed.emit()
	queue_free()

func _on_help_pressed() -> void:
	var help_text := """Save The Cat! Beat Sheet:

1. Opening Image - First impression of hero
2. Setup - Status quo, what's missing
3. Inciting Incident - Call to adventure
4. Debate - Hero hesitates
5. Break into Act II - Crossing the threshold
6. Midpoint - False victory or false defeat
7. All Is Lost - Rock bottom moment
8. Climax - Final confrontation
9. Final Image - Changed hero, bookend to opening

Remember: A story has rhythm. Setup before conflict. Debate before action."""
	
	DialogueManager.show_dialogue(help_text)
