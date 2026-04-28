extends Panel

signal letter_dropped(slot_index: int, letter: String)

var slot_index := 0
var current_letter := ""

@onready var label: Label = $Label

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("letter")

func _drop_data(_position: Vector2, data: Variant) -> void:
	current_letter = String(data["letter"])
	label.text = current_letter
	letter_dropped.emit(slot_index, current_letter)
