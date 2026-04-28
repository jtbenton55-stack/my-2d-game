extends Area2D

@export var correct_code: String = "7429"
@export var puzzle_title: String = "Garage Door Keypad"
@export var max_attempts: int = 3

signal puzzle_solved
signal puzzle_failed
signal player_entered

var attempts_remaining: int = 3
var is_solved := false
var _code_ui_open := false
var _code_ui_spawning := false

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
	if _code_ui_open or _code_ui_spawning:
		return
	_show_puzzle()

func _show_puzzle() -> void:
	if _code_ui_open or _code_ui_spawning:
		return
	_code_ui_spawning = true
	var mission := _get_mission()
	var options: Array[String] = ["1234", "0000", "7429"]
	
	if mission and mission.has_method("get_garage_code_options"):
		options = mission.get_garage_code_options()
	
	# Create choice panel for code entry
	var packed := load("res://src/dialogue/choice_panel.tscn") as PackedScene
	if packed == null:
		_code_ui_spawning = false
		# Fallback to simple dialog
		DialogueManager.show_simple_dialogue([
			{"speaker": "System", "text": "Enter garage code: " + correct_code}
		])
		_solve_puzzle()
		return
	
	var panel := packed.instantiate()
	panel.choice_made.connect(_on_code_chosen)
	var ui_host := _get_or_create_transient_ui_host()
	if ui_host == null:
		_code_ui_spawning = false
		EventBus.warn("Garage keypad: no mission scene to attach UI.")
		return
	ui_host.add_child(panel)
	panel.tree_exited.connect(func():
		_code_ui_open = false
		_code_ui_spawning = false
		if is_instance_valid(ui_host) and ui_host.get_child_count() == 0:
			ui_host.queue_free()
	)
	panel.setup("Enter garage code:", options)
	_code_ui_spawning = false
	_code_ui_open = true

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
	var n: Node = self
	while n:
		if n.has_method("get_garage_code_options") and n.has_method("is_garage_code_valid"):
			return n
		n = n.get_parent()
	var cs := get_tree().current_scene
	if cs and cs.has_method("get_garage_code_options"):
		return cs
	return null

func _get_or_create_transient_ui_host() -> CanvasLayer:
	var cs := get_tree().current_scene
	if cs == null:
		return null
	var host := cs.get_node_or_null("_TransientUI") as CanvasLayer
	if host == null:
		host = CanvasLayer.new()
		host.name = "_TransientUI"
		host.layer = 95
		cs.add_child(host)
	return host
