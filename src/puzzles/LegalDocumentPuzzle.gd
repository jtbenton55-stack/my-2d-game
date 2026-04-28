extends Control

# Chain of title puzzle - pick the correct document among fakes

const DOCUMENTS = [
	{
		"id": 0,
		"title": "Assignment Agreement (Version A)",
		"date": "March 15, 1988",
		"clauses": [
			"1. Writer assigns all rights to Sterling Pictures LLC.",
			"2. Consideration: $50,000 upon signature.",
			"3. Rights include all sequels, remakes, and adaptations.",
			"4. Writer retains no credit or residuals."
		],
		"suspicious": [3],
		"is_correct": false,
		"flaw": "Writer gave up all credit rights - highly unusual."
	},
	{
		"id": 1,
		"title": "Chain of Title Document (Certified)",
		"date": "October 3, 1987",
		"clauses": [
			"1. Original Writer's Guild registration #1987-0452 attached.",
			"2. Option agreement executed with writer consent (see signature).",
			"3. Clean assignment to Sterling Pictures with standard consideration.",
			"4. Writer retains WGA-minimum credit and residual rights."
		],
		"suspicious": [],
		"is_correct": true,
		"flaw": ""
	},
	{
		"id": 2,
		"title": "Rights Transfer Document",
		"date": "January 20, 1988",
		"clauses": [
			"1. All intellectual property rights hereby transferred.",
			"2. Prior agreements are superseded by this document.",
			"3. No WGA registration referenced.",
			"4. Transfer effective retroactive to 1986."
		],
		"suspicious": [1, 2, 3],
		"is_correct": false,
		"flaw": "No WGA registration and retroactive dating are major red flags."
	},
	{
		"id": 3,
		"title": "Property Assignment (Draft)",
		"date": "December 12, 1987",
		"clauses": [
			"1. Writer transfers screenplay 'Untitled Project' to Sterling.",
			"2. Consideration to be determined at later date.",
			"3. Writer's Guild registration number appears forged.",
			"4. Assignment witnessed by single notary."
		],
		"suspicious": [0, 2, 3],
		"is_correct": false,
		"flaw": "Consideration undefined and forged WGA number."
	}
]

var mere_eyes_active: bool = false
var selected_document: int = -1
var solved := false
var current_document_index: int = 0

signal puzzle_solved
signal puzzle_failed

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var doc_title: Label = $Panel/VBoxContainer/DocumentView/DocTitle
@onready var doc_date: Label = $Panel/VBoxContainer/DocumentView/DocDate
@onready var clauses_container: VBoxContainer = $Panel/VBoxContainer/DocumentView/ClausesContainer
@onready var mere_eyes_label: Label = $Panel/VBoxContainer/DocumentView/MereEyesLabel
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var prev_button: Button = $Panel/VBoxContainer/Navigation/PrevButton
@onready var next_button: Button = $Panel/VBoxContainer/Navigation/NextButton
@onready var select_button: Button = $Panel/VBoxContainer/Navigation/SelectButton
@onready var close_button: Button = $Panel/VBoxContainer/Navigation/CloseButton

func _ready() -> void:
	title_label.text = "Select the authentic chain-of-title document:"
	feedback_label.text = "Review all %d documents carefully." % DOCUMENTS.size()
	
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	_update_document_view()
	
	prev_button.grab_focus()

func _update_document_view() -> void:
	var doc = DOCUMENTS[current_document_index]
	
	doc_title.text = doc.title
	doc_date.text = "Date: " + doc.date
	
	# Clear and rebuild clauses
	for child in clauses_container.get_children():
		child.queue_free()
	
	for i in range(doc.clauses.size()):
		var clause_label := Label.new()
		clause_label.text = doc.clauses[i]
		clause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		clause_label.custom_minimum_size = Vector2(400, 0)
		
		# If mere_legal_eyes card active, highlight suspicious clauses
		if mere_eyes_active and doc.suspicious.has(i):
			clause_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
			clause_label.text += " [SUSPICIOUS]"
		
		clauses_container.add_child(clause_label)
	
	# Mere's eyes hint
	if mere_eyes_active:
		if doc.suspicious.is_empty():
			mere_eyes_label.text = "Mere's eyes: This document appears clean."
			mere_eyes_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4, 1.0))
		else:
			mere_eyes_label.text = "Mere's eyes: %d suspicious clauses detected!" % doc.suspicious.size()
			mere_eyes_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3, 1.0))
	else:
		mere_eyes_label.text = "Hint: Look for WGA registration and proper consideration."
		mere_eyes_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	
	# Update button states
	prev_button.disabled = current_document_index == 0
	next_button.disabled = current_document_index == DOCUMENTS.size() - 1
	
	# Highlight if selected
	if selected_document == current_document_index:
		select_button.text = "SELECTED"
		select_button.modulate = Color(0.3, 0.7, 0.9, 1.0)
	else:
		select_button.text = "Select This Document"
		select_button.modulate = Color(1, 1, 1, 1.0)

func _on_prev_pressed() -> void:
	if current_document_index > 0:
		current_document_index -= 1
		_update_document_view()
		AudioManager.play_sfx("ui_click")

func _on_next_pressed() -> void:
	if current_document_index < DOCUMENTS.size() - 1:
		current_document_index += 1
		_update_document_view()
		AudioManager.play_sfx("ui_click")

func _on_select_pressed() -> void:
	if solved:
		return
	
	selected_document = current_document_index
	_update_document_view()
	
	var doc = DOCUMENTS[selected_document]
	
	if doc.is_correct:
		_solve_puzzle()
	else:
		_show_incorrect_feedback(doc)

func _show_incorrect_feedback(doc: Dictionary) -> void:
	feedback_label.text = "Incorrect: " + doc.flaw
	feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
	
	AudioManager.play_sfx("ui_error")
	
	# Reset selection after delay
	await get_tree().create_timer(2.0).timeout
	selected_document = -1
	feedback_label.text = "Try another document. Remember: WGA registration is key."
	feedback_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_update_document_view()

func _solve_puzzle() -> void:
	solved = true
	
	feedback_label.text = "Correct! Authentic chain of title verified. Creative theft documented."
	feedback_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4, 1.0))
	
	select_button.disabled = true
	prev_button.disabled = true
	next_button.disabled = true
	
	AudioManager.play_sfx("puzzle_complete")
	
	puzzle_solved.emit()
	
	# Auto-close after delay
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_close_pressed() -> void:
	if not solved:
		puzzle_failed.emit()
	queue_free()
