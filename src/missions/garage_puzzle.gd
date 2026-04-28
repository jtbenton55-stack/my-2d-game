extends Area2D

@export var correct_code: String = "7429"
@export var puzzle_title: String = "Garage Door Keypad"
@export var max_attempts: int = 3

signal puzzle_solved
signal puzzle_failed
signal player_entered

var attempts_remaining: int = 3
var is_solved := false

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_entered.emit()

func interact(_player: Node) -> void:
	if is_solved:
		_show_already_open()
		return
	_show_puzzle()

func _show_puzzle() -> void:
	var mission := _get_mission()
	var options := ["1234", "0000", "7429"]
	
	if mission and mission.has_method("get_garage_code_options"):
		options = mission.get_garage_code_options()
	
	# Create choice panel for code entry
	var packed := load("res://src/dialogue/choice_panel.tscn") as PackedScene
	if packed == null:
		# Fallback to simple dialog
		DialogueManager.show_simple_dialogue([
			{"speaker": "System", "text": "Enter garage code: " + correct_code}
		])
		_solve_puzzle()
		return
	
	var panel := packed.instantiate()
	panel.setup("Enter garage code:", options)
	panel.choice_made.connect(_on_code_chosen)
	get_tree().current_scene.add_child(panel)

func _on_code_chosen(index: int) -> void:
	var mission := _get_mission()
	var chosen_code := "7429"
	
	if mission and mission.has_method("get_garage_code_options"):
		var options = mission.get_garage_code_options()
		if index >= 0 and index < options.size():
			chosen_code = options[index]
	
	if mission and mission.has_method("is_garage_code_valid"):
		if mission.is_garage_code_valid(chosen_code):
			_solve_puzzle()
		else:
			_fail_attempt()
	else:
		# Default validation
		if chosen_code == correct_code:
			_solve_puzzle()
		else:
			_fail_attempt()

func _solve_puzzle() -> void:
	is_solved = true
	DialogueManager.show_simple_dialogue([
		{"speaker": "System", "text": "Code accepted. Garage door opening."}
	])
	puzzle_solved.emit()

func _fail_attempt() -> void:
	attempts_remaining -= 1
	if attempts_remaining <= 0:
		DialogueManager.show_simple_dialogue([
			{"speaker": "System", "text": "Too many failed attempts! The alarm has triggered."}
		])
		puzzle_failed.emit()
	else:
		DialogueManager.show_simple_dialogue([
			{"speaker": "System", "text": "Incorrect code. " + str(attempts_remaining) + " attempts remaining."}
		])

func _show_already_open() -> void:
	DialogueManager.show_simple_dialogue([
		{"speaker": "System", "text": "The garage door is already open."}
	])

func _get_mission() -> Node:
	return get_tree().current_scene
