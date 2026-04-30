extends Control

@export var answer_word: String = "DOG"
@export var available_letters: PackedStringArray = PackedStringArray(["D", "O", "G", "X", "Y"])
@export var slot_count: int = 3

var slots: Array = []
var tiles: Array = []
var solved := false

signal puzzle_solved

@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var slot_container: HBoxContainer = $Panel/VBoxContainer/SlotContainer
@onready var tile_container: GridContainer = $Panel/VBoxContainer/TileContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

func _ready() -> void:
	prompt_label.text = "Decode the word:"
	close_button.pressed.connect(_on_close_pressed)
	_create_slots()
	_create_tiles()
	close_button.grab_focus()


func _on_close_pressed() -> void:
	queue_free()


func _create_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	slots.clear()
	for i in range(slot_count):
		var slot = load("res://src/puzzles/cipher/puzzle_slot.tscn").instantiate()
		slot.slot_index = i
		slot.letter_dropped.connect(_on_letter_dropped)
		slot_container.add_child(slot)
		slots.append(slot)

func _create_tiles() -> void:
	for child in tile_container.get_children():
		child.queue_free()
	tiles.clear()
	for letter in available_letters:
		var tile = load("res://src/puzzles/cipher/puzzle_tile.tscn").instantiate()
		tile.set_letter(letter)
		tile_container.add_child(tile)
		tiles.append(tile)

func _on_letter_dropped(_slot_index: int, _letter: String) -> void:
	if solved:
		return
	var current_word := ""
	for slot in slots:
		current_word += String(slot.current_letter)
	if current_word == answer_word:
		solved = true
		puzzle_solved.emit()
